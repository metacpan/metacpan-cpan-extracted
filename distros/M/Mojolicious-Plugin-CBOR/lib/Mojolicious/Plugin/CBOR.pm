package Mojolicious::Plugin::CBOR;

use Mojo::Base 'Mojolicious::Plugin';
use CBOR::XS;

our $VERSION = '0.04';

sub register
{
	my ($self, $app, $args) = @_;

	$app->types->type(cbor => 'application/cbor; charset=UTF-8');
	
	$app->renderer->add_handler(cbor => sub {
		my ($renderer, $c, $output, $options) = @_;
		
		# force disabling Mojo encoding
		delete $options->{'encoding'};

		$options->{'format'} = 'cbor';         

		my $cbor = CBOR::XS->new();
		
		$$output = $cbor->encode($c->stash->{'cbor'});
	});
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::CBOR - render a CBOR response with Mojolicious

=head1 SYNOPSIS

	# Mojolicious
	$self->plugin('CBOR');

	# Mojolicious::Lite
	plugin 'CBOR';

	# In controller
	$self->render(cbor => $data, handler => 'cbor');

=head1 DESCRIPTION

L<Mojolicious::Plugin::CBOR> is a L<Mojolicious> plugin that packs any data you send to the 'cbor' parameter with L<CBOR::XS> and renders it.

The "Content-Type" header sent in the response will be set to "application/cbor; charset=UTF-8".

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
