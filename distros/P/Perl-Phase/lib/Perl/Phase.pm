package Perl::Phase;

use strict;
use warnings;

our $VERSION = '0.03';

use XSLoader;
XSLoader::load(__PACKAGE__);

sub is_compile_time {
    my $current_phase = current_phase();
    return 1 if $current_phase == PERL_PHASE_CONSTRUCT();
    return 1 if $current_phase == PERL_PHASE_START();
    return 1 if $current_phase == PERL_PHASE_CHECK();
    return;
}

sub is_run_time {
    my $current_phase = current_phase();
    return 1 if $current_phase == PERL_PHASE_INIT();
    return 1 if $current_phase == PERL_PHASE_RUN();
    return 1 if $current_phase == PERL_PHASE_END();
    return 1 if $current_phase == PERL_PHASE_DESTRUCT();
    return;
}

sub assert_is_run_time {
    return 1 if is_run_time();

    my @caller = caller(1);
    if (@caller) {
        die "$caller[3]() called at compile time at $caller[1] line $caller[2]\n";
    }
    else {
        die "This code should not be executed at compile time";
    }

    return;
}

sub assert_is_compile_time {
    return 1 if is_compile_time();

    my @caller = caller(1);
    if (@caller) {
        die "$caller[3]() called at run time at $caller[1] line $caller[2]\n";
    }
    else {
        die "This code should not be executed at run time";
    }

    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Perl::Phase - Check if you are currently in compile time or run time

=head1 VERSION

This document describes Perl::Phase version 0.03

=head1 SYNOPSIS

    use Perl::Phase ();

    sub init_data {
        Perl::Phase::assert_is_run_time(); # so we don’t forever bake the data in if this is perlcc’d

        …
    }

=head1 DESCRIPTION

Some code should only run at runtime some only at compile time.

This functions let you check (boolean) or assert (die) either.

=head1 INTERFACE

None of these functions take any arguments.

=head2 Perl::Phase::is_compile_time()

Returns true if executed at compile time, false if executed at run time.

=head2 Perl::Phase::assert_is_compile_time()

Dies if executed at run time, otherwise returns true.

=head2 Perl::Phase::is_run_time()

Returns true if executed at run time, false if executed at compile time.

=head2 Perl::Phase::assert_is_run_time()

Dies if executed at compile time, otherwise returns true.

=head2 Perl::Phase::current_phase()

Returns perl’s internal numeric id of the phase perl is currently in.

Much faster than string comparing C<${^GLOBAL_PHASE}> in a string comparison.

=head3 CONSTANTS

These are perl’s internal numeric id of the C<${^GLOBAL_PHASE}> in the name.

=head4 PERL_PHASE_CONSTRUCT

=head4 PERL_PHASE_START

=head4 PERL_PHASE_CHECK

=head4 PERL_PHASE_INIT

=head4 PERL_PHASE_RUN

=head4 PERL_PHASE_END

=head4 PERL_PHASE_DESTRUCT

=head2 If you care about the exact stage you are in …

This module aims to give you the fastest and smallest way to determine if you are in run time or compile time.

If you care about the exact stage you are in you have some options:

=head3 Look at C<${^GLOBAL_PHASE}>

This module, as well as L<Check::GlobalPhase>, use XS to do this logic via perl’s internal numeric id which is much faster.

Note that C<${^GLOBAL_PHASE}> only works on perl 5.14 and newer or unless you use a module that sets it on earlier versions like L<Devel::GlobalPhase>.

=head3 use L<Check::GlobalPhase>’s C<is_global_phase_<lc phase name>()> functions

Most of the time we really only care if we are in compile time or run time so this module does not implement these.

=head3 Use current_phase() and constants

    if (Perl::Phase::current_phase() == Perl::Phase::PERL_PHASE_INIT ) { … we are in INIT … }

    if (Perl::Phase::current_phase() & (Perl::Phase::PERL_PHASE_INIT | Perl::Phase::PERL_PHASE_RUN) ) { … we are either in INIT or RUN … }

=head1 DIAGNOSTICS

Assert can have two types of die messages depending on the caller information:

=over

=item C<< %s() called at (run|compile) time at %s line %n >>

=item C<< This code should not be executed at (run|compile) time >>

=back

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

L<XSLoader>

=head1 INCOMPATIBILITIES AND LIMITATIONS

None reported.

=head1 BUGS AND FEATURES

Please report any bugs or feature requests (and a pull request for bonus points)
 through the issue tracker at L<https://github.com/drmuey/p5-Perl-Phase/issues>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2019, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
