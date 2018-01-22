package Module::Load::In::INIT;

our $DATE = '2018-01-15'; # DATE
our $VERSION = '0.004'; # VERSION

use strict;
#use warnings; # warns: Too late to run INIT block

my @mods;

sub import {
    my $pkg = shift;

    push @mods, @_;
}

INIT {
    my %opts;
    for my $mod (@mods) {
        if ($mod =~ /^-(.+?)(?:=(.*))?\z/) {
            $opts{$1} = defined $2 ? $2 : 1;
            next;
        }
        my @import_args;
        if ($mod =~ s!=(.*)!!) {
            @import_args = split /;/, $1;
        }
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        eval { require $mod_pm; 1 };
        if ($@) {
            if ($opts{ignore_load_error}) {
                next;
            } else {
                die;
            }
            $mod->import(@import_args);
        }
    }
}

1;

# ABSTRACT: Load modules in INIT phase

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Load::In::INIT - Load modules in INIT phase

=head1 VERSION

This document describes version 0.004 of Module::Load::In::INIT (from Perl distribution Module-Load-In-INIT), released on 2018-01-15.

=head1 SYNOPSIS

In the command-line:

 % perl -MModule::Load::In::INIT=Mod::One,Mod::Two='Some;Import;Args' somescript.pl

C<Mod::One> and C<Mod::Two> will be loaded in the INIT phase instead of BEGIN
phase.

Specify options for Module::Load::In::INIT itself:

 % perl -MModule::Load::In::INIT=-ignore_load_error,Mod::One,Mod::Two

=head1 DESCRIPTION

This module can load (or perhaps defer loading) modules in the INIT phase
instead of the BEGIN phase. One use-case where it is useful: monkey-patching a
module (using a L<Module::Patch>-based module) in a fatpacked script (see
L<Module::FatPack> or L<App::FatPacker>), e.g.:

 % perl -MSome::Module::Patch::Foo fatpacked-script.pl

C<Some::Module::Patch::Foo> will try to load C<Some::Module> then patch it. This
might fail when module is loaded by the fatpack handler (which is a require
hook) as by the time C<Some::Module::Patch::Foo> is loaded, the fatpack handler
has not been setup yet, and C<Some::Module> is not available elsewhere (on the
filesystem). This, however, works:

 % perl -MModule::Load::In::INIT=Some::Module::Patch::Foo fatpacked-script.pl

Loading of C<Some::Module::Patch::Foo> (and by extension, C<Some::Module>) is
deferred to the INIT phase. By that time, the fatpack require hook has been
setup and C<Some::Module> can be (or might already be) loaded by it.

Caveat: Module::Load::In::INIT itself must be loaded in the BEGIN phase, or INIT
phase at the latest.

=head1 OPTIONS

You can specify options for Module::Load::In::INIT itself via import argument
that starts with dash ("-"). Known options:

=over

=item -ignore_load_error

If set, then require() error will be ignored.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-Load-In-INIT>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-Load-In-INIT>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Load-In-INIT>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
