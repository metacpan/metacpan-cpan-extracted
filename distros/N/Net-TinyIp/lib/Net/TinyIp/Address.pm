package Net::TinyIp::Address;
use strict;
use warnings;
use base "Math::BigInt";
use Carp qw( croak );
use Net::TinyIp::Address::v4;
use Net::TinyIp::Address::v6;

use overload q{""} => \&human_readable;

sub from_bin {
    my $class   = shift;
    my $big_int = $class->SUPER::new( @_ );

    return bless $big_int, $class;
}

sub from_hex {
    my $class   = shift;
    my $big_int = $class->SUPER::new( @_ );

    return bless $big_int, $class;
}

sub from_cidr {
    my $class  = shift;
    my $prefix = shift;
    my $length = $class->get( "bits_length" );
    my $self   = $class->from_bin( "0b1" );

    $self = ( $self << $prefix ) - 1;
    $self = $self << ( $length - $prefix );

    return $self;
}

sub get {
    my $class = shift;
    my $what  = uc shift;

    $class = ref $class
        if ref $class;

    my $ret = do {
        no strict "refs";
        ${ "${class}::$what" };
    }
        or croak "No $what exists.";

    return $ret;
}

sub version { shift->get( "version" ) }

sub cidr {
    my $self = shift;
    ( my $bin_str = $self->as_bin ) =~ s{\A 0b }{}msx;

    return 0 if length( $bin_str ) < $self->get( "bits_length" );
    return length sprintf "%s", $bin_str =~ m{\A (1+) }msx;
}

sub human_readable {
    my $self   = shift;
    my $format = shift || $self->get( "block_format" );

    ( my $bin_str = $self->as_bin ) =~ s{\A 0b }{}msx;
    $bin_str = "0" x ( $self->get( "bits_length" ) - length $bin_str ) . $bin_str;

    my $bits_per_block = $self->get( "bits_per_block" );

    return join $self->get( "separator" ), map { sprintf $format, eval "0b$_" } ( $bin_str =~ m{ (\d{$bits_per_block}) }gmsx );
}

1;
__END__

=head1 NAME

Net::TinyIp::Address - IP Address object

=head1 SYNOPSIS

  use Net::TinyIp::Address;
  my $ip = Net::TinyIp::Address::v4->from_string( "192.168.1.1" );
  say $ip;

=head1 DESCRIPTION

Blah blha blha.

=head1 AUTHOR

kuniyoshi E<lt>kuniyoshi@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

