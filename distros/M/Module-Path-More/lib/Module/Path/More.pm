package Module::Path::More;

our $DATE = '2017-02-01'; # DATE
our $VERSION = '0.33'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(module_path pod_path);

our $SEPARATOR;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Get path to locally installed Perl module',
};

BEGIN {
    if ($^O =~ /^(dos|os2)/i) {
        $SEPARATOR = '\\';
    } elsif ($^O =~ /^MacOS/i) {
        $SEPARATOR = ':';
    } else {
        $SEPARATOR = '/';
    }
}

$SPEC{module_path} = {
    v => 1.1,
    summary => 'Get path to locally installed Perl module',
    description => <<'_',

Search `@INC` (reference entries are skipped) and return path(s) to Perl module
files with the requested name.

This function is like the one from <pm:Module::Path>, except with a different
interface and more options (finding all matches instead of the first, the option
of not absolutizing paths, finding `.pmc` & `.pod` files, finding module
prefixes).

_
    args => {
        module => {
            summary => 'Module name to search',
            schema  => 'str*',
            req     => 1,
            pos     => 0,
        },
        find_pm => {
            summary => 'Whether to find .pm files',
            schema  => ['int*', min=>0],
            default => 1,
            description => <<'_',

The value of this option is an integer number from 0. 0 means to not search for
.pm files, while number larger than 0 means to search for .pm files. The larger
the number, the lower the priority. If more than one type is found (prefix, .pm,
.pmc, .pod) then the type with the lowest number is returned first.

_
        },
        find_pmc => {
            summary => 'Whether to find .pmc files',
            schema  => ['int*', min=>0],
            default => 2,
            description => <<'_',

The value of this option is an integer number from 0. 0 means to not search for
.pmc files, while number larger than 0 means to search for .pmc files. The
larger the number, the lower the priority. If more than one type is found
(prefix, .pm, .pmc, .pod) then the type with the lowest number is returned
first.

_
        },
        find_pod => {
            summary => 'Whether to find .pod files',
            schema  => ['int*', min=>0],
            default => 0,
            description => <<'_',

The value of this option is an integer number from 0. 0 means to not search for
.pod files, while number larger than 0 means to search for .pod files. The
larger the number, the lower the priority. If more than one type is found
(prefix, .pm, .pmc, .pod) then the type with the lowest number is returned
first.

_
        },
        find_prefix => {
            summary => 'Whether to find module prefixes',
            schema  => ['int*', min=>0],
            default => 0,
            description => <<'_',

The value of this option is an integer number from 0. 0 means to not search for
module prefix, while number larger than 0 means to search for module prefix. The
larger the number, the lower the priority. If more than one type is found
(prefix, .pm, .pmc, .pod) then the type with the lowest number is returned
first.

_
        },
        all => {
            summary => 'Return all results instead of just the first',
            schema  => 'bool',
            default => 0,
        },
        abs => {
            summary => 'Whether to return absolute paths',
            schema  => 'bool',
            default => 0,
        },
    },
    result => {
        schema => ['any' => of => ['str*', ['array*' => of => 'str*']]],
    },
    result_naked => 1,
    examples => [
        {
            summary => 'Find the first Foo::Bar (.pm or .pmc) in @INC',
            args => {module => 'Foo::Bar'},
        },
        {
            summary => 'Find all Foo::Bar (.pm or .pmc) in @INC, return absolute paths',
            args => {module => 'Foo::Bar', all => 1, abs => 1},
        },
        {
            summary => 'Find the Rinci (.pod first, then .pm) in @INC',
            args => {module => 'Rinci', find_pod => 1, find_pm => 2, find_pmc => 0},
        },
    ],
};
sub module_path {
    my %args = @_;

    my $module = $args{module} or die "Please specify module";

    $args{abs}         //= 0;
    $args{all}         //= 0;
    $args{find_pm}     //= 1;
    $args{find_pmc}    //= 2;
    $args{find_pod}    //= 0;
    $args{find_prefix} //= 0;

    require Cwd if $args{abs};

    my @res;
    my %unfound = (
        ("pm" => 1)     x !!$args{find_pm},
        ("pmc" => 1)    x !!$args{find_pmc},
        ("pod" => 1)    x !!$args{find_pod},
        ("prefix" => 1) x !!$args{find_prefix},
    );
    my $add = sub {
        my ($path, $prio) = @_;
        push @res, [$args{abs} ? Cwd::abs_path($path) : $path, $prio];
    };

    my $relpath;

    ($relpath = $module) =~ s/::/$SEPARATOR/g;
    $relpath =~ s/\.(pm|pmc|pod)\z//i;

    foreach my $dir (@INC) {
        next if not defined($dir);
        next if ref($dir);

        my $prefix = $dir . $SEPARATOR . $relpath;
        if ($args{find_pm}) {
            my $file = $prefix . ".pm";
            if (-f $file) {
                $add->($file, $args{find_pm});
                delete $unfound{pm};
                last if !keys(%unfound) && !$args{all};
            }
        }
        if ($args{find_pmc}) {
            my $file = $prefix . ".pmc";
            if (-f $file) {
                $add->($file, $args{find_pmc});
                delete $unfound{pmc};
                last if !keys(%unfound) && !$args{all};
            }
        }
        if ($args{find_pod}) {
            my $file = $prefix . ".pod";
            if (-f $file) {
                $add->($file, $args{find_pod});
                delete $unfound{pod};
                last if !keys(%unfound) && !$args{all};
            }
        }
        if ($args{find_prefix}) {
            if (-d $prefix) {
                $add->($prefix, $args{find_prefix});
                delete $unfound{prefix};
                last if !keys(%unfound) && !$args{all};
            }
        }
    }

    @res = map { $_->[0] } sort { $a->[1] <=> $b->[1] } @res;

    if ($args{all}) {
        return \@res;
    } else {
        return @res ? $res[0] : undef;
    }
}

$SPEC{pod_path} = {
    v => 1.1,
    summary => 'Get path to locally installed POD',
    description => <<'_',

This is a shortcut for:

    module_path(%args, find_pm=>0, find_pmc=>0, find_pod=>1, find_prefix=>0)

_
    args => {
        module => {
            summary => 'Module name to search',
            schema  => 'str*',
            req     => 1,
            pos     => 0,
        },
        all => {
            summary => 'Return all results instead of just the first',
            schema  => 'bool',
            default => 0,
        },
        abs => {
            summary => 'Whether to return absolute paths',
            schema  => 'bool',
            default => 0,
        },
    },
    result => {
        schema => ['any' => of => ['str*', ['array*' => of => 'str*']]],
    },
    result_naked => 1,
};
sub pod_path {
    module_path(@_, find_pm=>0, find_pmc=>0, find_pod=>1, find_prefix=>0);
}

1;
# ABSTRACT: Get path to locally installed Perl module

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Path::More - Get path to locally installed Perl module

=head1 VERSION

This document describes version 0.33 of Module::Path::More (from Perl distribution Module-Path-More), released on 2017-02-01.

=head1 SYNOPSIS

 use Module::Path::More qw(module_path pod_path);

 $path = module_path(module=>'Test::More');
 if (defined($path)) {
   print "Test::More found at $path\n";
 } else {
   print "Danger Will Robinson!\n";
 }

 # find all found modules, as well as .pmc and .pod files
 $paths = module_path(module=>'Foo::Bar', all=>1, find_pmc=>1, find_pod=>1);

 # just a shortcut for module_path(module=>'Foo',
 #                                 find_pm=>0, find_pmc=>0, find_pod=>1);
 $path = pod_path(module=>'Foo');

=head1 DESCRIPTION

Module::Path::More provides a function, C<module_path()>, which will find where
a module (or module prefix, or .pod file) is installed locally. (There is also
another function C<pod_path()> which is just a convenience wrapper.)

It works by looking in all the directories in @INC for an appropriately named
file. If module is C<Foo::Bar>, will search for C<Foo/Bar.pm>, C<Foo/Bar.pmc>
(if C<find_pmc> argument is true), C<Foo/Bar> directory (if C<find_prefix>
argument is true), or C<Foo/Bar.pod> (if C<find_pod> argument is true).

Caveats: Obviously this only works where the module you're after has its own
C<.pm> file. If a file defines multiple packages, this won't work. This also
won't find any modules that are being loaded in some special way, for example
using a code reference in C<@INC>, as described in C<require> in L<perlfunc>.

To check whether a module is available/loadable, it's generally better to use
something like:

 if (eval { require Some::Module; 1 }) {
     # module is available
 }

because this works with fatpacking or any other C<@INC> hook that might be
installed. If you use:

 if (module_path(module => "Some::Module")) {
     # module is available
 }

then it only works if the module is locatable in the filesystem. But on the
other hand this method can avoid actual loading of the module.

=head1 FUNCTIONS


=head2 module_path(%args) -> str|array[str]

Get path to locally installed Perl module.

Examples:

=over

=item * Find the first Foo::Bar (.pm or .pmc) in @INC:

 module_path(module => "Foo::Bar"); # -> undef

=item * Find all Foo::Bar (.pm or .pmc) in @INC, return absolute paths:

 module_path(module => "Foo::Bar", abs => 1, all => 1); # -> []

=item * Find the Rinci (.pod first, then .pm) in @INC:

 module_path(module => "Rinci", find_pm => 2, find_pmc => 0, find_pod => 1);

Result:

 "/home/u1/perl5/perlbrew/perls/perl-5.24.0/lib/site_perl/5.24.0/Rinci.pod"

=back

Search C<@INC> (reference entries are skipped) and return path(s) to Perl module
files with the requested name.

This function is like the one from L<Module::Path>, except with a different
interface and more options (finding all matches instead of the first, the option
of not absolutizing paths, finding C<.pmc> & C<.pod> files, finding module
prefixes).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<abs> => I<bool> (default: 0)

Whether to return absolute paths.

=item * B<all> => I<bool> (default: 0)

Return all results instead of just the first.

=item * B<find_pm> => I<int> (default: 1)

Whether to find .pm files.

The value of this option is an integer number from 0. 0 means to not search for
.pm files, while number larger than 0 means to search for .pm files. The larger
the number, the lower the priority. If more than one type is found (prefix, .pm,
.pmc, .pod) then the type with the lowest number is returned first.

=item * B<find_pmc> => I<int> (default: 2)

Whether to find .pmc files.

The value of this option is an integer number from 0. 0 means to not search for
.pmc files, while number larger than 0 means to search for .pmc files. The
larger the number, the lower the priority. If more than one type is found
(prefix, .pm, .pmc, .pod) then the type with the lowest number is returned
first.

=item * B<find_pod> => I<int> (default: 0)

Whether to find .pod files.

The value of this option is an integer number from 0. 0 means to not search for
.pod files, while number larger than 0 means to search for .pod files. The
larger the number, the lower the priority. If more than one type is found
(prefix, .pm, .pmc, .pod) then the type with the lowest number is returned
first.

=item * B<find_prefix> => I<int> (default: 0)

Whether to find module prefixes.

The value of this option is an integer number from 0. 0 means to not search for
module prefix, while number larger than 0 means to search for module prefix. The
larger the number, the lower the priority. If more than one type is found
(prefix, .pm, .pmc, .pod) then the type with the lowest number is returned
first.

=item * B<module>* => I<str>

Module name to search.

=back

Return value:  (str|array[str])


=head2 pod_path(%args) -> str|array[str]

Get path to locally installed POD.

This is a shortcut for:

 module_path(%args, find_pm=>0, find_pmc=>0, find_pod=>1, find_prefix=>0)

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<abs> => I<bool> (default: 0)

Whether to return absolute paths.

=item * B<all> => I<bool> (default: 0)

Return all results instead of just the first.

=item * B<module>* => I<str>

Module name to search.

=back

Return value:  (str|array[str])

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-Path-More>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-Path-More>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Path-More>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Module::Path>. Module::Path::More is actually a fork of Module::Path.
Module::Path::More contains features that are not (or have not been accepted) in
the original module, namely: finding all matches instead of the first found
match, and finding C<.pmc/.pod> in addition to .pm files. B<Note that the
interface is different> (Module::Path::More accepts hash/named arguments) so the
two modules are not drop-in replacements for each other. Also, note that by
default Module::Path::More does B<not> do an C<abs_path()> to each file it
finds. I think this module's choice (not doing abs_path) is a more sensible
default, because usually there is no actual need to do so and doing abs_path()
or resolving symlinks will sometimes fail or expose filesystem quirks that we
might not want to deal with at all. However, if you want to do abs_path, you can
do so by setting C<abs> option to true.

Command-line utility is not included in this distribution, unlike L<mpath> in
C<Module-Path>. However, you can use L<pmpath|https://metacpan.org/pod/distribution/App-PMUtils/bin/pmpath> from L<App::PMUtils> distribution
which uses this module.

References:

=over

=item * L<https://github.com/neilbowers/Module-Path/issues/6>

=item * L<https://github.com/neilbowers/Module-Path/issues/7>

=item * L<https://github.com/neilbowers/Module-Path/issues/10>

=item * L<https://rt.cpan.org/Public/Bug/Display.html?id=100979>

=back

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
