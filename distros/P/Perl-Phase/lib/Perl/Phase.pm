package Perl::Phase;

use strict;
use warnings;

use 5.14.0;    # for ${^GLOBAL_PHASE}

our $VERSION = '0.01';

sub is_compile_time {

    # why not just `return !is_run_time();`? more explicit/accurate && save a `pp_entersub` op
    return ${^GLOBAL_PHASE}
      if ${^GLOBAL_PHASE} eq "CONSTRUCT"
      || ${^GLOBAL_PHASE} eq "START"
      || ${^GLOBAL_PHASE} eq "CHECK";
    return;
}

sub is_run_time {
    return ${^GLOBAL_PHASE}
      if ${^GLOBAL_PHASE} eq "INIT"
      || ${^GLOBAL_PHASE} eq "RUN"
      || ${^GLOBAL_PHASE} eq "END"
      || ${^GLOBAL_PHASE} eq "DESTRUCT";
    return;
}

sub assert_is_run_time {
    return ${^GLOBAL_PHASE} if is_run_time();

    my @caller = caller(1);
    if (@caller) {
        die "$caller[3]() called at compile time at $caller[1] line $caller[2]\n";
    }
    else {
        die "This code should not be executed at compile time";
    }

    return ${^GLOBAL_PHASE};
}

sub assert_is_compile_time {
    return ${^GLOBAL_PHASE} if is_compile_time();

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

=head1 NAME

Perl::Phase - Check if you are currently in compile time or run time

=head1 VERSION

This document describes Perl::Phase version 0.01

=head1 SYNOPSIS

    use Perl::Phase;

    sub foo {
        Perl::Phase::assert_is_run_time();

        …
    }

=head1 DESCRIPTION

Some code should only run at runtime some only at compile time.

This functions let you check (boolean) or assert (die) either.


=head1 INTERFACE

None of these functions take any arguments.

Any true value returned is also the current phase name.

=head2 Perl::Phase::is_compile_time()

Returns true if executed at compile time, false if executed at run time.

=head2 Perl::Phase::assert_is_compile_time()

Dies if executed at run time, otherwise returns true.

=head2 Perl::Phase::is_run_time()

Returns true if executed at run time, false if executed at compile time.

=head2 Perl::Phase::assert_is_run_time()

Dies if executed at compile time, otherwise returns true.

=head1 DIAGNOSTICS

Assert can have two types of die message depending on the caller information.

=over

=item C<< "%s() called at (run|compile) time at %s line %n\n">>

=item C<< This code should not be executed at (run|compile) time" >>

=back

=head1 CONFIGURATION AND ENVIRONMENT

C<${^GLOBAL_PHASE}>

=head1 DEPENDENCIES

Perl 5.14 for C<${^GLOBAL_PHASE}>.


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
