package Net::P0f::Backend::Socket;
use strict;
use Carp;
use Socket;

{ no strict;
  $VERSION = 0.02;
  @ISA = qw(Net::P0f);
}

=head1 NAME

Net::P0f::Backend::Socket - Back-end for C<Net::P0f> that links to the P0f library

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Net::P0f;

    my $p0f = Net::P0f->new(backend => 'socket', socket_path => '/var/run/p0f.sock');
    ...

=head1 DESCRIPTION

This module is a back-end helper for B<Net::P0f>. 
It provides an interface to pilot the C<p0f(1)> utility using its 
local-socket. 

See L<Net::P0f> for more general information and examples. 

=head1 METHODS

=over 4

=item init()

This method initialize the backend-specific part of the object. 
It is automatically called by C<Net::P0f> during the object creation.

B<Options>

=over 4

=item *

C<socket_path> - indicates the path to the socket which can be used 
to query a P0f process.

=back

=cut

sub init {
    my $self = shift;
    my %opts = @_;

    # declare my specific options
    #$self->{options}{XXX} = '';
    
    # initialize my options
    for my $opt (keys %opts) {
        exists $self->{options}{$opt} ?
        ( $self->{options}{$opt} = $opts{$opt} and delete $opts{$opt} )
        : carp "warning: Unknown option '$opt'";
    }
}

=item run()

=cut

sub run {
    my $self = shift;
    die "*** ",(caller(0))[3]," not implemented ***\n";
    croak "fatal: Please set the path to the socket with the 'socket_path' option" 
      unless $self->{options}{socket_path};
}


# 
# P0f types <-> pack() 
# ====================
#   _u8     C    unsigned char
#   _u16    S    unsigned short
#   _u32    I    unsigned int
#   _u64    Q    unsigned quad
#
#   _s8     c    signed char
#   _s16    s    signed short
#   _s32    i    signed int
#   _s64    q    signed quad
# 

=item encode_p0f_query()

=cut

sub encode_p0f_query {
    my $magic = 0x0defaced;
    my($id,$src_addr,$dest_addr,$src_port,$dest_port) = @_;
    $src_addr = inet_aton($src_addr);
    $dest_addr = inet_aton($dest_addr);
    return pack('IIIISS', $magic,$id,$src_addr,$dest_addr,$src_port,$dest_port)
}

=item decode_p0f_response()

=cut

sub decode_p0f_response {
    my $packet = shift;
    my($magic,$id,$type,$genre,$detail,$dist,$link,$tos,$fw,$nat,$real,$score,
        $mflags,$uptime) = unpack('IICA20A40cA30A30CCCsSi', $packet);
    return ($id,$type,$genre,$detail,$dist,$link,$tos,$fw,$nat,
        $real,$score,$mflags,$uptime)
}

=back

=head1 DIAGNOSTICS

These messages are classified as follows (listed in increasing order of 
desperatin): 

=over 4

=item *

B<(W)> A warning, usually caused by bad user data. 

=item *

B<(E)> An error caused by external code. 

=item *

B<(F)> A fatal error caused by the code of this module. 

=back

=over 4

=item Please set the path to the socket with the 'socket_path' option

B<(F)> You must set the C<socket_path> option with the path to the socket. 

=item Unknown option '%s'

B<(W)> You called an accesor which does not correspond to a known option.

=back

=head1 SEE ALSO

L<Net::P0f>

=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni E<lt>sebastien@aperghis.netE<gt>

=head1 BUGS

Please report any bugs or feature requests to
L<bug-net-p0f-xs@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-P0f>. 
I will be notified, and then you'll automatically be notified 
of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2004 SE<eacute>bastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Net::P0f::Backend::Socket
