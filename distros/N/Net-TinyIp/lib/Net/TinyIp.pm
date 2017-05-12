package Net::TinyIp;
use strict;
use warnings;
use Net::TinyIp::Address;

use overload q{""} => \&human_readable;

our $VERSION = "0.08";

sub import {
    my $class = shift;
    my @tags  = @_;

    foreach my $tag ( @tags ) {
        my $module = join q{::}, $class, "Util", join q{}, map { ucfirst } split m{_}, $tag;
        eval "require $module"
            or die;
        $module->import;
    }
}

sub new {
    my $class   = shift;
    my $address = shift;
    my %self;

    my( $host, $cidr ) = split m{/}, $address;

    my $version = $host =~ m{[.]} ? 4 : $host =~ m{[:]} ? 6 : undef;
    my $module  = join q{::}, $class, "Address", "v$version";

    unless ( defined $cidr ) {
        $cidr = $module->get( "bits_length" );
    }

    $self{host} = $module->from_string( $host );
    $self{mask} = $module->from_cidr( $cidr );

    return bless \%self, $class;
}

sub network {
    my $self    = shift;
    my $network = $self->host & $self->mask;

    return $network;
}

sub broadcast {
    my $self = shift;
    my $neg  = ( ref $self->mask )
        ->from_bin( "0b1" )
        ->blsft( $self->mask->get( "bits_length" ) )
        ->bsub( 1 )
        ->bxor( $self->mask );

    return $self->network | $neg;
}

sub host {
    my $self = shift;

    if ( @_ ) {
        $self->{host} = shift;
    }

    return $self->{host};
}

sub mask {
    my $self = shift;

    if ( @_ ) {
        $self->{mask} = shift;
    }

    return $self->{mask};
}

sub human_readable {
    my $self = shift;

    return join q{/}, $self->host, $self->mask->cidr;
}

1;
__END__

=head1 NAME

Net::TinyIp - IP object

=head1 SYNOPSIS

  use Net::TinyIp;
  my $ip = Net::TinyIp->new( "192.168.1.1/24" );
  say $ip;

=head1 DESCRIPTION

Net::TinyIp represents host IP address, and network IP address.

=head1 METHODS

=over

=item network

=item broadcast

=back

=head1 AUTHOR

kuniyoshi E<lt>kuniyoshi@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

