package Mojolicious::Plugin::HTMLTemplateRenderer;

use Mojo::Base 'Mojolicious::Plugin';

use HTML::Template;

our $VERSION = '0.04';

sub register {
  my ($self, $app, $conf) = @_;

  $app->renderer->add_handler(
     tmpl => sub {
        my ($r, $c, $output, $options) = @_;

        my $path = $r->template_path($options);
	my $controller = $c->stash('controller');

	my @template_dirs;

	push @template_dirs, $c->app->home->rel_dir('templates');

	if($controller) {
            push @template_dirs, $c->app->home->rel_dir("templates/$controller");
	}

        my %t_options;

        $t_options{die_on_bad_params} = 0;
        $t_options{global_vars} = 1;
        $t_options{loop_context_vars} = 1;
        $t_options{path} = \@template_dirs;
        $t_options{search_path_on_include} = 1;

        if(defined($options->{inline})) {
            $t_options{scalarref} = \$options->{inline};
        } elsif(defined($options->{template})) {
            $t_options{filename} = $path;
            $t_options{cache} = 1;
        }

        my %tmpl_params = %{$c->stash};

        my $t = HTML::Template->new(%t_options,
                                    %{$conf->{tmpl_new_opts}             || {}},
                                    %{delete $tmpl_params{tmpl_new_opts} || {}});

        unless($t) { $r->render_exception("ERROR: No template created"); }

        $t->param(%tmpl_params);

        $$output = $t->output();
     }
  );
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::HTMLTemplateRenderer - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('HTMLTemplateRenderer');


  # Mojolicious::Lite
  plugin 'HTMLTemplateRenderer';

  # Render HTML::Template handler and post 'utf8 => 1' option for next HTML::Template->new call
  get '/' => sub{
    my $self = shift;
    $self->render('bender', handler => 'tmpl', tmpl_new_opts => {utf8 => 1});
  }


  # Set default options for all HTML::Template->new calls
  plugin 'HTMLTemplateRenderer', tmpl_new_opts => {blind_cache => 1, open_mode => '<:encoding(UTF-16)'};

=head1 DESCRIPTION

L<Mojolicious::Plugin::HTMLTemplateRenderer> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::HTMLTemplateRenderer> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register;

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 COPYRIGHT & LICENSE
 
Copyright 2011 Bob Faist, all rights reserved.
 
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
 
=cut
