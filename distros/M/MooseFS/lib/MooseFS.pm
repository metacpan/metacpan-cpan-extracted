package MooseFS;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Moo;
use IO::Socket::INET;

=head1 NAME

MooseFS - The MooseFS Info API!

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

The large portions of the code in my library have been taken directly from the Web UI that ships with MooseFS. 

Just use different objects to get different informations of the MooseFS cluster.


    use MooseFS::Server;
    my $mfs = MooseFS::Server->new(
        masterhost => '127.0.0.1'
    );
    say Dumper $mfs->info;
    say for $mfs->list;
    say $mfs->masterversion;
    ...

=head1 LIMIT

Don't support version below 1.6.13 by now.

=cut

has masterhost => (
    is => 'ro',
    default => sub { '127.0.0.1' }
);

has masterport => (
    is => 'ro',
    default => sub { 9421 }
);

has masterversion => (
    is => 'ro',
    lazy => 1,
    builder => '_check_version',
);

has sock => (
    is => 'rw',
    lazy => 1,
    builder => '_create_sock',
);

has info => (
    is => 'rw',
);

sub _create_sock {
    my $self = shift;
    IO::Socket::INET->new(
        PeerAddr => $self->masterhost,
        PeerPort => $self->masterport,
        Proto    => 'tcp',
    );
};

sub _check_version {
    my $self = shift;
    my $s = $self->sock;
    print $s pack('(LL)>', 510, 0);
    my $header = $self->myrecv($s, 8);
    my ($cmd, $length) = unpack('(LL)>', $header);
    my $data = $self->myrecv($s, $length);
    if ( $cmd == 511 ) {
        if ( $length == 52 ) {
            return 1400;
        } elsif ( $length == 60 ) {
            return 1500;
        } elsif ( $length == 68 or $length == 76) {
            return sprintf "%d%d%02d", unpack("(SCC)>", substr($data, 0, 4));
        };
    };
};

sub myrecv {
    my ($self, $socket, $len) = @_;
    my $msg = '';
    while ( length($msg) < $len ) {
        my $chunk;
        sysread $socket, $chunk, $len-length($msg);
        die "Socket Close." if $chunk eq '';
        $msg .= $chunk;
    }
    return $msg;
};

=head1 SEE ALSO

=over 4
 
=item L<http://www.moosefs.org>

=item L<https://github.com/techhat/python-moosefs>

=item L<https://github.com/chenryn/perl-moosefs>

=back

=head1 AUTHOR

chenryn, C<< <rao.chenlin at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosefs at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseFS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseFS


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 chenryn.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of MooseFS
