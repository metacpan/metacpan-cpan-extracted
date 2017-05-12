# ABSTRACT: Markapl template plugin for Mojolicious

package Mojolicious::Plugin::MarkaplRenderer;
BEGIN {
  $Mojolicious::Plugin::MarkaplRenderer::VERSION = '0.2.0';
}
use strict;
use warnings;

=head1 NAME

Mojolicious::Plugin::MarkaplRenderer - Markapl template plugin for Mojolicious

=head1 VERSION

version 0.2.0

=head1 DESCRIPTION

This is L<Markapl> for L<Mojolicious>.

=head1 SYNOPSIS

    # In app
    sub startup {
	my $self = shift;

	$self->plugins->register_plugin('Mojolicious::Plugin::MarkaplRenderer', $self, view_class => 'MyProject::View');
	$self->renderer->default_handler('markapl');
    }

    # Then in MyProject::View
    package MyProject::View;
    use Markapl;

    template 'index/index' => sub {
	html {
	    head {
		meta(charset => 'UTF-8');
		title { 'I am title' };
	    }

	    body {
		p { 'testing paragraph...' };

		# ...
	    }
	};
    };

    1;

=cut

use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($self, $app, $conf) = @_;

    $conf ||= {};
    my $name = $conf->{name} || 'markapl';

    my $view_class = $conf->{view_class};
    eval "require $view_class;";

    $app->renderer->add_handler(
	$name => sub {
	    my ($r, $c, $output, $options) = @_;

	    $$output = $view_class->render($options->{template}, $c->{stash});

	    return 1;
	}
    );
}

=head1 AUTHOR

Gea-Suan Lin, C<< <gslin at gslin.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Gea-Suan Lin.

This software is released under 3-clause BSD license. See
L<http://www.opensource.org/licenses/bsd-license.php> for more
information.

=cut

1;