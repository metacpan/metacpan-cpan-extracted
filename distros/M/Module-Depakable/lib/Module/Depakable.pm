package Module::Depakable;

our $DATE = '2016-08-11'; # DATE
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter::Rinci qw(import);

our %SPEC;

$SPEC{module_depakable} = {
    v => 1.1,
    summary => 'Check whether a module (or modules) is (are) depakable',
    description => <<'_',

This routine tries to determine whether the module(s) you specify, when use-d by
a script, won't impair the ability to depak the script so that the script can
run with requiring only core perl modules installed. The word "depak-able"
(depak) comes from the name of the application that can pack a script using
fatpack/datapack technique.

Let's start with the aforementioned goal: making a script run with only
requiring core perl modules installed. This is a pretty reasonable goal for a
common use-case: deploying a Perl application to a fresh perl installation. All
the non-core modules that the script might use are packed along inside the
script using fatpack (put inside a hash variable) or datapack (put in the DATA
section) technique. But XS modules cannot be packed using this technique. And
therefore, a module that requires non-core XS modules (either directly or
indirectly) also cannot be used.

So in other words, this routine checks that a module is PP (pure-perl) *and* all
of its (direct and indirect) dependencies are PP or core.

To check whether a module is PP/XS, `Module::XSOrPP` is used and this requires
that the module is installed because `Module::XSOrPP` guesses by analyzing the
module's source code.

To list all direct and indirect dependencies of a module, `lcpan` is used, so
that application must be installed and run first to download and index a local
CPAN/CPAN-like repository.

_
    args => {
        modules => {
            schema => ['array*', of => 'str*', min_len=>1],
            req => 1,
            pos => 0,
            greedy => 1,
            'x.schema.element_entity' => 'modulename',
        },
    },
    examples => [
        {
            args => { modules=>[qw/Data::Sah WWW::PAUSE::Simple/] },
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub module_depakable {
    require App::lcpan::Call;
    require Module::CoreList::More;
    require Module::XSOrPP;

    my %args = @_;

    my $mods = $args{modules};

    for my $mod (@$mods) {
        my $xs_or_pp;
        unless ($xs_or_pp = Module::XSOrPP::xs_or_pp($mod)) {
            return [500, "Can't determine whether '$mod' is XS/PP ".
                        "(probably not installed?)"];
        }
        if ($args{_is_prereqs}) {
            unless ($xs_or_pp =~ /pp/ ||
                        Module::CoreList::More->is_still_core($mod)) {
            return [500, "Prerequisite '$mod' is not PP nor core"];
            }
        } else {
            unless ($xs_or_pp =~ /pp/) {
                return [500, "Module '$mod' is XS"];
            }
        }
    }

    my $res = App::lcpan::Call::call_lcpan_script(argv=>[
        "deps",
        #"--phase", "runtime", "--rel", "requires", # the default
        "-R", "--with-xs-or-pp",
        @$mods]);
    return $res unless $res->[0] == 200;

    my %errors; # key = module name, val = reason
    for my $entry (@{$res->[2]}) {
        my $mod = $entry->{module};
        $mod =~ s/^\s+//;
        next if $mod eq 'perl';
        if (!$entry->{xs_or_pp}) {
            $errors{$mod} = 'not installed or cannot guess XS/PP';
        }
        if (!$entry->{is_core} && $entry->{xs_or_pp} !~ /pp/) {
            $errors{$mod} = 'not PP nor core';
        }
    }

    if (keys %errors) {
        return [
            500,
            "Prerequisite(s) not depakable: ".
                join(", ", map {"$_ ($errors{$_})"} sort keys %errors),
            undef,
            {'func.raw' => \%errors}];
    } else {
        return [200, "OK (all modules are depakable)"];
    }
}

$SPEC{prereq_depakable} = {
    v => 1.1,
    summary => 'Check whether prereq (and their recursive prereqs) '.
        'are depakable',
    description => <<'_',

This routine is exactly like `module_depakable` except it allows the prereq(s)
themselves to be core XS, while `module_depakable` requires the modules
themselves be pure-perl.

_
    args => {
        prereqs => {
            schema => ['array*', of => 'str*', min_len=>1],
            req => 1,
            pos => 0,
            greedy => 1,
            'x.schema.element_entity' => 'modulename',
        },
    },
};
sub prereq_depakable {
    my %args = @_;
    module_depakable(modules => $args{prereqs}, _is_prereqs=>1);
}

1;
# ABSTRACT: Check whether a module (or modules) is (are) depakable

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Depakable - Check whether a module (or modules) is (are) depakable

=head1 VERSION

This document describes version 0.007 of Module::Depakable (from Perl distribution Module-Depakable), released on 2016-08-11.

=head1 FUNCTIONS


=head2 module_depakable(%args) -> [status, msg, result, meta]

Check whether a module (or modules) is (are) depakable.

Examples:

=over

=item * Example #1:

 module_depakable(modules => ["Data::Sah", "WWW::PAUSE::Simple"]);

=back

This routine tries to determine whether the module(s) you specify, when use-d by
a script, won't impair the ability to depak the script so that the script can
run with requiring only core perl modules installed. The word "depak-able"
(depak) comes from the name of the application that can pack a script using
fatpack/datapack technique.

Let's start with the aforementioned goal: making a script run with only
requiring core perl modules installed. This is a pretty reasonable goal for a
common use-case: deploying a Perl application to a fresh perl installation. All
the non-core modules that the script might use are packed along inside the
script using fatpack (put inside a hash variable) or datapack (put in the DATA
section) technique. But XS modules cannot be packed using this technique. And
therefore, a module that requires non-core XS modules (either directly or
indirectly) also cannot be used.

So in other words, this routine checks that a module is PP (pure-perl) I<and> all
of its (direct and indirect) dependencies are PP or core.

To check whether a module is PP/XS, C<Module::XSOrPP> is used and this requires
that the module is installed because C<Module::XSOrPP> guesses by analyzing the
module's source code.

To list all direct and indirect dependencies of a module, C<lcpan> is used, so
that application must be installed and run first to download and index a local
CPAN/CPAN-like repository.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<modules>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 prereq_depakable(%args) -> [status, msg, result, meta]

Check whether prereq (and their recursive prereqs) are depakable.

This routine is exactly like C<module_depakable> except it allows the prereq(s)
themselves to be core XS, while C<module_depakable> requires the modules
themselves be pure-perl.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<prereqs>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-Depakable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-Depakable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Depakable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::depak>

L<depakable>, CLI for this module.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
