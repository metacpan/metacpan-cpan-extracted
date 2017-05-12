package Module::Loadable;

our $DATE = '2016-08-02'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Scalar::Util qw(blessed);

use Exporter qw(import);
our @EXPORT_OK = qw(module_loadable module_source);

our $SEPARATOR;
BEGIN {
    if ($^O =~ /^(dos|os2)/i) {
        $SEPARATOR = '\\';
    } elsif ($^O =~ /^MacOS/i) {
        $SEPARATOR = ':';
    } else {
        $SEPARATOR = '/';
    }
}

sub _module_source {
    my $name_pm = shift;

    for my $entry (@INC) {
        next unless defined $entry;
        my $ref = ref($entry);
        my ($is_hook, @hook_res);
        if ($ref eq 'ARRAY') {
            $is_hook++;
            @hook_res = $entry->[0]->($entry, $name_pm);
        } elsif (blessed $entry) {
            $is_hook++;
            @hook_res = $entry->INC($name_pm);
        } elsif ($ref eq 'CODE') {
            $is_hook++;
            @hook_res = $entry->($entry, $name_pm);
        } else {
            my $path = "$entry$SEPARATOR$name_pm";
            if (-f $path) {
                open my($fh), "<", $path
                    or die "Can't locate $name_pm: $path: $!";
                local $/;
                return scalar <$fh>;
            }
        }

        if ($is_hook) {
            next unless @hook_res;
            my $prepend_ref = shift @hook_res if ref($hook_res[0]) eq 'SCALAR';
            my $fh          = shift @hook_res if ref($hook_res[0]) eq 'GLOB';
            my $code        = shift @hook_res if ref($hook_res[0]) eq 'CODE';
            my $code_state  = shift @hook_res if @hook_res;
            if ($fh) {
                my $src = "";
                local $_;
                while (!eof($fh)) {
                    $_ = <$fh>;
                    if ($code) {
                        $code->($code, $code_state);
                    }
                    $src .= $_;
                }
                $src = $$prepend_ref . $src if $prepend_ref;
                return $src;
            } elsif ($code) {
                my $src = "";
                local $_;
                while ($code->($code, $code_state)) {
                    $src .= $_;
                }
                $src = $$prepend_ref . $src if $prepend_ref;
                return $src;
            }
        }
    }

    die "Can't locate $name_pm in \@INC (\@INC contains: ".join(" ", @INC).")";
}

sub module_source {
    my $name = shift;

    # convert Foo::Bar -> Foo/Bar.pm
    my $name_pm;
    if ($name =~ /\A\w+(?:::\w+)*\z/) {
        ($name_pm = "$name.pm") =~ s!::!$SEPARATOR!g;
    } else {
        $name_pm = $name;
    }

    _module_source $name_pm;
}

sub module_loadable {
    my $name = shift;

    # convert Foo::Bar -> Foo/Bar.pm
    my $name_pm;
    if ($name =~ /\A\w+(?:::\w+)*\z/) {
        ($name_pm = "$name.pm") =~ s!::!$SEPARATOR!g;
    } else {
        $name_pm = $name;
    }

    return 1 if exists $INC{$name_pm};

    if (eval { _module_source $name_pm; 1 }) {
        1;
    } else {
        0;
    }
}

1;
# ABSTRACT: Check if a module is loadable without actually loading it

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Loadable - Check if a module is loadable without actually loading it

=head1 VERSION

This document describes version 0.001 of Module::Loadable (from Perl distribution Module-Loadable), released on 2016-08-02.

=head1 SYNOPSIS

 use Module::Loadable qw(module_loadable module_source);

 # check if a module is available
 if (module_loadable "Foo::Bar") {
     # Foo::Bar is available
 } elsif (module_loadable "Foo/Baz.pm") {
     # Foo::Baz is available
 }

 # get a module's source code, dies on failure
 my $src = module_source("Foo/Baz.pm");

=head1 DESCRIPTION

To check if a module is loadable (available), generally the simplest way is to
try to C<require()> it:

 if (eval { require Foo::Bar; 1 }) {
     # Foo::Bar is available
 }

However, this actually loads the module. If a large number of modules need to be
checked, this can potentially consume a lot of CPU time and memory.

C<Module::Loadable> provides a routine C<module_loadable()> which works like
Perl's C<require> but does not actually load the module.

=head1 FUNCTIONS

=head2 module_loadable($name) => bool

Check that module named C<$name> is loadable, without actually loading it.
C<$name> will be converted from C<Foo::Bar> format to C<Foo/Bar.pm>.

It works by following the behavior of Perl's C<require>, except the actual
loading/executing part. First, it checks if C<$name> is already in C<%INC>,
returning true immediately if that is the case. Then it will iterate each entry
in C<@INC>. If the entry is a coderef or object or arrayref,
C<module_loadable()> will treat it like a hook and call it like Perl's
C<require()> does as described in L<perlfunc>. Otherwise, the entry will be
treated like a directory name and the module's file will be searched on the
filesystem.

=head2 module_source($name) => str

Return module's source code, without actually loading it. Die on failure.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-Loadable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-Loadable>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Loadable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Module::Path> and L<Module::Path::More>. These modules can also be used to
check if a module on the filesystem is available. It iterates directories in
C<@INC> to try to find the module's file, but will not work with fatpacked (see
L<App::FatPacker> or L<Module::FatPack>) or datapacked (see L<Module::DataPack>)
scripts or generally when there is a hook in C<@INC>. C<Module::Loadable>, on
the other hand, handles require hook like Perl's C<require()>.

Also, those two modules at the time of this writing currently does not actually
read the module file. In the case of, say, permission problem, those two will
still return the path but the module might not actually readable.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
