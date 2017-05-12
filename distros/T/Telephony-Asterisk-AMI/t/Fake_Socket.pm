#---------------------------------------------------------------------
package t::Fake_Socket;
#
# Copyright 2015 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 26 Dec 2015
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Fake socket class for testing Telephony::Asterisk::AMI
#---------------------------------------------------------------------

our $VERSION = '0.006'; # VERSION
# This file is part of Telephony-Asterisk-AMI 0.006 (December 26, 2015)

use 5.008;
use strict;
use warnings;

use IO::Socket::IP ();
use Tie::Handle ();

use Exporter 5.57 'import';     # exported import method
our @EXPORT = qw(set_input socket_args socket_output);

our @ISA = qw(Tie::Handle);

#=====================================================================
# Socket implementation
#---------------------------------------------------------------------
my (@input, $output, $socket_args);

sub TIEHANDLE {
  $output = '';
  bless {}, shift;
}

sub READLINE { shift @input }

sub WRITE {
  my ($self, $data, $length, $offset) = @_;

  $output .= substr($data, $offset, $length);
  1;
}

sub CLOSE { 1 }

#=====================================================================
# Monkey-patch IO::Socket::IP to return a t::Fake_Socket instead
#---------------------------------------------------------------------
{
  no warnings 'redefine';

  sub IO::Socket::IP::new {
    my ($class, %args) = @_;

    $socket_args = \%args;

    tie *t::Fake_Socket::SOCKET_FH, 't::Fake_Socket';

    *t::Fake_Socket::SOCKET_FH;
  } # end IO::Socket::IP::new
}

#=====================================================================
# Exported subroutines
#---------------------------------------------------------------------

# Set up the @input array from a string
sub set_input {
  @input = split(/\r?\n/, shift, -1);
  $_ .= "\r\n" for @input;
} # end set_input

# Return the current $socket_args
sub socket_args {
  $socket_args;
}

# Return the current $output and clear it
sub socket_output {
  substr($output, 0, length($output), '');
}

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

t::Fake_Socket - Fake socket class for testing Telephony::Asterisk::AMI

=head1 VERSION

This document describes version 0.006 of
t::Fake_Socket, released December 26, 2015.

=head1 CONFIGURATION AND ENVIRONMENT

t::Fake_Socket requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Telephony-Asterisk-AMI AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Telephony-Asterisk-AMI >>.

You can follow or contribute to Telephony-Asterisk-AMI's development at
L<< https://github.com/madsen/Telephony-Asterisk-AMI >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
