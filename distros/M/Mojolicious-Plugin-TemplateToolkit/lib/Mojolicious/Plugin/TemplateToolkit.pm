package Mojolicious::Plugin::TemplateToolkit;
use Mojo::Base 'Mojolicious::Plugin';

use Carp;
use Mojo::Util qw(encode md5_sum);
use Template;
use Template::Provider::Mojo;

our $VERSION = '0.005';

sub register {
	my ($self, $app, $conf) = @_;
	
	my $tt_config = $conf->{template} || {};
	$tt_config->{MOJO_RENDERER} = $app->renderer;
	push @{$tt_config->{LOAD_TEMPLATES}}, Template::Provider::Mojo->new($tt_config);
	my $tt = Template->new($tt_config);
	
	$app->renderer->add_handler($conf->{name} || 'tt2' => sub {
		my ($renderer, $c, $output, $options) = @_;
		
		my $inline = $options->{inline};
		my $name = defined $inline ? md5_sum encode('UTF-8', $inline) : undef;
		return unless defined($name //= $renderer->template_name($options));
		
		my %params;
		
		# Helpers
		foreach my $method (grep { m/^\w+\z/ } keys %{$renderer->helpers}) {
			my $sub = $renderer->helpers->{$method};
			$params{$method} = sub { carp "Calling helpers directly in templates is deprecated. Use c.$method or h.$method"; $c->$sub(@_) };
		}
		
		# Stash values
		$params{$_} = $c->stash->{$_} for grep { m/^\w+\z/ } keys %{$c->stash};
		$params{self} = $params{c} = $c;
		$params{h} = $c->helpers;
		
		# Inline
		if (defined $inline) {
			$c->app->log->debug(qq{Rendering inline template "$name"});
			$tt->process(\$inline, \%params, $output) or die $tt->error, "\n";
		}
		
		# File
		else {
			# Try template
			if (defined(my $path = $renderer->template_path($options))) {
				$c->app->log->debug(qq{Rendering template "$name"});
				$tt->process($name, \%params, $output) or die $tt->error, "\n";
			}
			
			# Try DATA section
			elsif (defined(my $d = $renderer->get_data_template($options))) {
				$c->app->log->debug(qq{Rendering template "$name" from DATA section});
				$tt->process(\$d, \%params, $output) or die $tt->error, "\n";
			}
			
			# No template
			else { $c->app->log->debug(qq{Template "$name" not found}) }
		}
	});
}

1;

=head1 NAME

Mojolicious::Plugin::TemplateToolkit - Template Toolkit renderer plugin for
Mojolicious

=head1 SYNOPSIS

 # Mojolicious
 $app->plugin('TemplateToolkit');
 $app->plugin(TemplateToolkit => {name => 'foo'});
 $app->plugin(TemplateToolkit => {template => {INTERPOLATE => 1}});
 
 # Mojolicious::Lite
 plugin 'TemplateToolkit';
 plugin TemplateToolkit => {name => 'foo'};
 plugin TemplateToolkit => {template => {INTERPOLATE => 1}});
 
 # Set as default handler
 $app->renderer->default_handler('tt2');
 
 # Render without setting as default handler
 $c->render(template => 'bar', handler => 'tt2');

=head1 DESCRIPTION

L<Mojolicious::Plugin::TemplateToolkit> is a renderer for C<tt2> or
C<Template Toolkit> templates. See L<Template> and L<Template::Manual> for
details on the C<Template Toolkit> format, and L<Mojolicious::Guides::Rendering>
for general information on rendering in L<Mojolicious>.

Along with template files, inline and data section templates can be rendered in
the standard Mojolicious fashion. Template files and data sections will be
retrieved using L<Mojolicious::Renderer> via L<Template::Provider::Mojo> for
both direct rendering and directives such as C<INCLUDE>. This means that
instead of specifying L<INCLUDE_PATH|Template::Manual::Config/"INCLUDE_PATH">,
you should set L<Mojolicious::Renderer/"paths"> to the appropriate paths.

 $app->renderer->paths(['/path/to/templates']);
 push @{$app->renderer->paths}, '/path/to/more/templates';

L<Mojolicious> stash values will be exposed directly as
L<variables|Template::Manual::Variables> in the templates, and the current
controller object will be available as C<c> or C<self>, similar to
L<Mojolicious::Plugin::EPRenderer>. Helper methods can be called on the
L<controller object|Mojolicious::Controller/"AUTOLOAD"> or a more efficient
L<proxy object|Mojolicious::Controller/"helpers"> available as C<h>. See
L<Mojolicious::Plugin::DefaultHelpers> and L<Mojolicious::Plugin::TagHelpers>
for a list of all built-in helpers.

Accessing helper methods directly as variables, rather than via the controller
or proxy object, is deprecated and may be removed in a future release.

 $c->stash(description => 'template engine');
 $c->stash(engines => [qw(Template::Toolkit Text::Template)]);
 
 [% FOREACH engine IN engines %]
   [% engine %] is a [% description %].
 [% END %]
 
 [% h.link_to('Template Toolkit', 'http://www.template-toolkit.org') %]
 
 [% c.param('foo') %]


=head1 OPTIONS

L<Mojolicious::Plugin::TemplateToolkit> supports the following options.

=head2 name

 # Mojolicious::Lite
 plugin TemplateToolkit => {name => 'foo'};

Handler name, defaults to C<tt2>.

=head2 template

 # Mojolicious::Lite
 plugin TemplateToolkit => {template => {INTERPOLATE => 1}};

Configuration values passed to L<Template> object used to render templates.
Note that L<Template::Provider::Mojo> will use L<Mojolicious::Renderer/"paths">
to find templates, not L<INCLUDE_PATH|Template::Manual::Config/"INCLUDE_PATH">
specified here.

=head1 METHODS

L<Mojolicious::Plugin::TemplateToolkit> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

 $plugin->register(Mojolicious->new);
 $plugin->register(Mojolicious->new, {name => 'foo'});

Register renderer in L<Mojolicious> application.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojolicious::Renderer>, L<Template>, L<Template::Provider::Mojo>
