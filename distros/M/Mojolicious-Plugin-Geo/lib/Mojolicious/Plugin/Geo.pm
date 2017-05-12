package Mojolicious::Plugin::Geo;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::UserAgent;

our $VERSION = '0.02';

sub register {
    my ($self, $app) = @_;

    $app->helper(geo => sub {
        my ($self,$ip) = @_;

        my $ua = Mojo::UserAgent->new;      

        my $ip_info = $ua->get('http://geo.serving-sys.com/GeoTargeting/ebGetLocation.aspx?ip=' . $ip)->res->body;  
        my %data = map  { (split /=/, $_) } split(/&/, $ip_info);       

        return \%data;
    });
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::Geo - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('geo');

  # Mojolicious::Lite
  plugin 'geo';

=head1 DESCRIPTION

L<Mojolicious::Plugin::Geo> is a L<Mojolicious> plugin.
This plugin uses a geolocation server of an unknown provider. It is one of the more accurate I have found. I may add some free public ones later but have not had a chance.

=head1 METHODS

L<Mojolicious::Plugin::Geo> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<geo>

    $self->geo('8.8.8.8')

    Returns an object with basic geo data. Lat, Lon, City, Country, Postal Code etc..

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
