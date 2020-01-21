package Term::Clear;

use strict;
use warnings;

our $VERSION = '0.01';
our $POSIX   = 0;        # off by default since some folks like to avoid loading POSIX
our $_clear_str;         # our for testing; _ for don’t use this directly

sub import {
    $POSIX = 1 if grep { $_ eq "POSIX" } @_;
    return 1;
}

sub clear {
    $_clear_str //= _get_clear_str();
    print $_clear_str;
}

sub _get_clear_str {
    local $@;

    eval { require Term::Cap };
    return _get_from_system_call() if $@;    # kind of gross but works a lot of places; patches welcome :)

    # blatently stolen and slightly modified from PerlPowerTools v1.016 bin/clear
    my $OSPEED = 9600;
    if ( $POSIX || $INC{"POSIX.pm"} ) {      # only do this if they want it or have already loaded POSIX
        eval {
            require POSIX;
            my $termios = POSIX::Termios->new();
            $termios->getattr;
            $OSPEED = $termios->getospeed;
        };
    }

    my $cl = "";
    eval {
        my $terminal = Term::Cap->Tgetent( { OSPEED => $OSPEED } );
        $terminal->Trequire("cl");
        $cl = $terminal->Tputs( 'cl', 1 );
    };

    return _get_from_system_call() if $cl eq "";    # kind of gross but works a lot of places; patches welcome :)

    return $cl;
}

sub _get_from_system_call {
    if ( $^O eq 'MSWin32' ) {
        return scalar(`cls`);
    }

    return scalar(`/usr/bin/clear`);
}

1;

__END__

=encoding utf-8

=head1 NAME

Term::Clear - `clear` the terminal via a perl function

=head1 VERSION

This document describes Term::Clear version 0.01

=head1 SYNOPSIS

    use Term::Clear ();

    Term::Clear::clear();

=head1 DESCRIPTION

Perl function to replace C<system("clear")>.

=head1 INTERFACE

=head2 clear()

Takes no arguments and clears the terminal screen in as portable way as possible.

Once it does all the work to determine the characters for the system the value is cached in memory so subsequent calls will be faster.

=head2 POSIX

By default it does not try to determine C<OSPEED> from POSIX.

This is because some prefer to avoid loading POSIX for various reasons.

If you want it to try to do that you have two options:

=over 4

=item load POSIX.pm before your first call to C<clear()>.

=item set C<$Term::Clear::POSIX> to true before your first call to C<clear()>.

=item set C<$Term::Clear::POSIX> to true via C<import()>:

    use Term::Clear 'POSIX';

=back

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

=head1 CONFIGURATION AND ENVIRONMENT

Term::Clear requires no configuration files or environment variables.

=head1 DEPENDENCIES

It will use L<Term::Cap> and L<POSIX::Termios> if available.

=head1 INCOMPATIBILITIES AND LIMITATIONS

None reported.

=head1 BUGS AND FEATURES

Please report any bugs or feature requests (and a pull request for bonus points)
 through the issue tracker at L<https://github.com/drmuey/p5-Term-Clear/issues>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2020, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

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
