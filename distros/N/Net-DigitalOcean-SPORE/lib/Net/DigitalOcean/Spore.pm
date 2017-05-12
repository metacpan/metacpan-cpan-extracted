package Net::DigitalOcean::Spore;
BEGIN {
  $Net::DigitalOcean::Spore::AUTHORITY = 'cpan:FFFINKEL';
}
{
  $Net::DigitalOcean::Spore::VERSION = '0.002';
}

#ABSTRACT: DigitalOcean SPORE REST Client

use Moose;
use namespace::autoclean;

use Dir::Self;
use Net::HTTP::Spore 0.06;


has client_id => qw/ is ro isa Str required 1 /;


has api_key => qw/ is ro isa Str required 1 /;


has _client => (
	is      => 'ro',
	isa     => 'Net::HTTP::Spore',
	lazy    => 1,
	builder => '_build__client',
	handles => qr/.*/,
);

sub _build__client {
	my $self   = shift;
	my $path = __DIR__ . '../../../digital_ocean.json';
	my $client = Net::HTTP::Spore->new_from_spec( $path );
	$client->enable('Format::JSON');
	return $client;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Net::DigitalOcean::Spore - DigitalOcean SPORE REST Client

=head1 VERSION

version 0.002

=head1 NAME

Net::DigitalOcean::Spore - DigitalOcean SPORE REST Client

=head1 ATTRIBUTES

=head2 client_id

=head2 api_key

=head2 _client

REST client

=head1 SEE ALSO

L<Net::HTTP::Spore>

=head1 AUTHOR

Matt Finkel <fffinkel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Matt Finkel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
