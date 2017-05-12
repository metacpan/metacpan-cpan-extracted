package Net::LDAP::SID;
use strict;
use warnings;
use Carp;

# for reference
# https://lists.samba.org/archive/linux/2005-September/014301.html
# https://froosh.wordpress.com/2005/10/21/hex-sid-to-decimal-sid-translation/
# https://blogs.msdn.microsoft.com/oldnewthing/20040315-00/?p=40253
# http://www.selfadsi.org/ads-attributes/user-objectSid.htm

=head1 NAME

Net::LDAP::SID - Active Directory Security Identifier manipulation

=cut

our $VERSION = '0.001';

=head1 SYNOPSIS

 my $sid = Net::LDAP::SID->new( $binary );
 # or
 my $sid = Net::LDAP::SID->new( $string );

 print $sid->as_string;
 print $sid->as_binary;

=head1 METHODS

=head2 new

Constructor. Can pass either the binary or string representation of the SID.

=cut

sub new {
    my $class      = shift;
    my $bin_or_str = shift or confess "binary or string required";
    my $self       = bless {}, $class;
    $self->_build($bin_or_str);
    $self->_debug() if $ENV{'LDAP_DEBUG'};
    return $self;
}

sub _debug {
    my $self = shift;

    warn "SID binary = " . join( '\\', unpack '(H2)*', $self->{binary} );
    warn "SID string = $self->{string}";
}

sub _build {
    my ( $self, $bin_or_string ) = @_;
    if ( substr( $bin_or_string, 0, 1 ) eq 'S' ) {
        $self->_build_from_string($bin_or_string);
    }
    else {
        $self->_build_from_binary($bin_or_string);
    }
}

# SID binary format
#  byte[0] - revision level
#  byte[1] - count of sub authorities
#  byte[2-8] - 48 bit authority (big-endian)
#  and then count x 32 bit sub authorities (little-endian)

my $THIRTY_TWO_BITS = 4294967296;
my $PACK_TEMPLATE   = 'C C n N V*';

sub _build_from_string {
    my ( $self, $string ) = @_;

    my ( undef, $revision_level, $authority, @sub_authorities ) = split /-/,
        $string;
    my $sub_authority_count = scalar @sub_authorities;

    my $auth_id_16 = int( $authority / $THIRTY_TWO_BITS );
    my $auth_id_32 = $authority - ( $auth_id_16 * $THIRTY_TWO_BITS );

    $self->{binary} = pack $PACK_TEMPLATE, $revision_level,
        $sub_authority_count, $auth_id_16, $auth_id_32,
        @sub_authorities;
    $self->{string} = $string;
}

sub _build_from_binary {
    my ( $self, $binary ) = @_;
    my ( $revision_level, $sub_authority_count,
        $auth_id_16, $auth_id_32, @sub_authorities )
        = unpack $PACK_TEMPLATE, $binary;

    confess "Invalid SID binary: $binary"
        if $sub_authority_count != scalar @sub_authorities;

    my $authority = ( $auth_id_16 * $THIRTY_TWO_BITS ) + $auth_id_32;

    $self->{string} = join '-', 'S', $revision_level, $authority,
        @sub_authorities;
    $self->{binary} = $binary;
}

=head2 as_string

Returns string representation of SID.

=head2 as_binary

Returns binary representation of SID.

=cut

sub as_string { shift->{string} }
sub as_binary { shift->{binary} }

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-ldap-sid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-LDAP-SID>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::LDAP::SID


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-LDAP-SID>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-LDAP-SID>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-LDAP-SID>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-LDAP-SID/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Peter Karman.

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

1;    # End of Net::LDAP::SID
