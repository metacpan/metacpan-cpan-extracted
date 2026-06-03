#!/bin/false
# ABSTRACT: User Class option (code 15) -- list of opaque user class data
# PODNAME: Net::DHCPv6::Option::UserClass
use strictures 2;

package Net::DHCPv6::Option::UserClass;
$Net::DHCPv6::Option::UserClass::VERSION = '0.003';
use Net::DHCPv6::OptionList ();
use Net::DHCPv6::Constants  qw(
    $OPTION_USER_CLASS
);
use Net::DHCPv6::X::Truncated ();
use parent 'Net::DHCPv6::Option';
use Ref::Util qw( is_plain_arrayref );
use namespace::clean;
my $EMPTY = q();

sub new {
    my ( $class, %args ) = @_;
    $args{code} = $OPTION_USER_CLASS;
    my $data_list = $args{user_class_data} // [];
    $data_list = [$data_list] unless is_plain_arrayref( $data_list );
    $args{data} = join( $EMPTY, map { pack( 'n', CORE::length ) . $_ } @{$data_list} );
    my $self = $class->SUPER::new( %args );
    $self->{user_class_data} = $data_list;
    return bless $self, $class;
}

sub user_class_data { return shift->{user_class_data} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    my @items;
    my $offset = 0;
    my $len    = CORE::length( $payload );
    while ( $offset + 2 <= $len ) {
        my $ilen = unpack( 'n', substr( $payload, $offset, 2 ) );
        $offset += 2;
        Net::DHCPv6::X::Truncated->throw( message => 'Truncated UserClass data item' )
            if $offset + $ilen > $len;
        push @items, substr( $payload, $offset, $ilen );
        $offset += $ilen;
    }
    return $class->new( user_class_data => \@items );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_USER_CLASS} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::UserClass - User Class option (code 15) -- list of opaque user class data

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Net::DHCPv6::Option::UserClass;
  my $opt = Net::DHCPv6::Option::UserClass->new(
      user_class_data => [ 'foo', 'bar' ],
  );

=head1 DESCRIPTION

Carries a list of opaque user class data items.  Each item is
preceded by a 16-bit length field.  See RFC 8415 E<167>21.15.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Optional C<user_class_data> (arrayref of opaque strings,
defaults to empty list).

=head2 user_class_data

Returns an arrayref of opaque user class data items.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
