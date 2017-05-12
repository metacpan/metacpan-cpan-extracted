package Mojolicious::Plugin::HandlebarsRenderer;

use strict;
use warnings;
use parent qw(Mojolicious::Plugin);

our $VERSION = '0.01';

use MojoX::Renderer::Handlebars;

sub register {
	my ($self, $app, $args) = @_;

	$args ||= {};

	my $handlebars = MojoX::Renderer::Handlebars->build(app => $app, %$args);
	$app->renderer->add_handler(hbs => $handlebars);
}


1;

__END__

=head1 NAME

Mojolicious::Plugin::Handlebars - Text::Handlebars plugin

=head1 SYNOPSIS

	# Mojolicious
	$self->plugin('handlebars_renderer');
	$self->plugin(handlebarse_renderer => {
			template_options => { helpers => { add => sub { my($context,$arg1,$arg2) = @_; return $arg1 + $arg2 } } }
			});

	# Mojolicious::Lite
	plugin 'handlebars_renderer';
	plugin handlebars_renderer => {
		template_options => { helpers => { add => sub { my($context,$arg1,$arg2) = @_; return $arg1 + $arg2 } } }
	};

=head1 DESCRIPTION

L<Mojolicous::Plugin::HandlebarsRenderer> is a simple loader for
L<MojoX::Renderer::Handlebars>.

=head1 METHODS

L<Mojolicious::Plugin::HandlebarsRenderer> inherits all methods from
L<Mojolicious::Plugin> and overrides the following ones:

=head2 register

$plugin->register

Registers renderer in L<Mojolicious> application.

=head1 SEE ALSO

L<MojoX::Renderer::Handlebars>, L<Mojolicious>

=head1 AUTHOR

Robert Grimes, C<< <rmzgrimes at gmail.com> >>

This code is heavily based on the module L<Mojolicious::Plugin::XslateRenderer> by "gray <gray at cpan.org>"

=cut


