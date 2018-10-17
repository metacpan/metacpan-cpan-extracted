package Template::Provider::Mojo;

use strict;
use warnings;
use parent 'Template::Provider';

use Class::Method::Modifiers ();
use Mojo::Util;
use Mojolicious::Renderer;
use Scalar::Util;
use Template::Constants;

our $VERSION = '0.004';

Class::Method::Modifiers::after '_init' => sub {
	my ($self, $params) = @_;
	Scalar::Util::weaken($self->{MOJO_RENDERER} = delete $params->{MOJO_RENDERER});
	$self->{ENCODING} //= $self->_mojo_renderer->encoding;
};

sub fetch {
	my ($self, $name) = @_;
	my ($data, $error);
	
	if (ref $name) {
		# $name can be a reference to a scalar, GLOB or file handle
		($data, $error) = $self->_load($name);
		($data, $error) = $self->_compile($data) unless $error;
		$data = $data->{data} unless $error;
	} else {
		# Use renderer to find template
		my $renderer = $self->_mojo_renderer;
		my $options = _template_options($renderer, $name);
		
		# Try template
		if (defined(my $path = $renderer->template_path($options))) {
			($data, $error) = $self->_fetch($path);
		}
		
		# Try DATA section
		elsif (defined(my $d = $renderer->get_data_template($options))) {
			($data, $error) = $self->_load(\$d);
			($data, $error) = $self->_compile($data) unless $error;
			$data = $data->{data} unless $error;
		}
		
		# No template
		else { ($data, $error) = (undef, Template::Constants::STATUS_DECLINED) }
	}
	
	return ($data, $error);
}

sub load {
	my ($self, $name) = @_;
	my ($data, $error);
	
	# Use renderer to find template
	my $renderer = $self->_mojo_renderer;
	my $options = _template_options($renderer, $name);
	
	# Try template
	if (defined(my $path = $renderer->template_path($options))) {
		($data, $error) = $self->_template_content($path);
	}
	
	# Try DATA section
	elsif (defined(my $d = $renderer->get_data_template($options))) {
		# Content is expected to be encoded
		$d = Mojo::Util::encode $self->{ENCODING}, $d if $self->{UNICODE} and $self->{ENCODING};
		($data, $error) = ($d, undef);
	}
	
	# No template
	else { return (undef, Template::Constants::STATUS_DECLINED) }
	
	if ($error) {
		return $self->{TOLERANT} ? (undef, Template::Constants::STATUS_DECLINED)
			: ($error, Template::Constants::STATUS_ERROR);
	} else {
		return ($data, Template::Constants::STATUS_OK);
	}
}

sub _mojo_renderer { shift->{MOJO_RENDERER} //= Mojolicious::Renderer->new }

# Split template name back into options
sub _template_options {
	my ($renderer, $name) = @_;
	my $options = {};
	if ($name =~ m/^(.+)\.(.+)\.(.+)\z/) {
		$options->{template} = $1;
		$options->{format} = $2;
		$options->{handler} = $3;
	} elsif ($name =~ m/^(.+)\.(.+)\z/) {
		$options->{template} = $1;
		$options->{format} = $2;
	} else {
		$options->{template} = $name;
		$options->{format} = $renderer->default_format;
		$options->{handler} = $renderer->default_handler;
	}
	return $options;
}

1;

=head1 NAME

Template::Provider::Mojo - Use Mojolicious to provide templates

=head1 SYNOPSIS

 my $app = Mojolicious->new;
 $provider = Template::Provider::Mojo->new({MOJO_RENDERER => $app->renderer});
 
 ($template, $error) = $provider->fetch($name);

=head1 DESCRIPTION

L<Template::Provider::Mojo> is a L<Template::Provider> subclass that uses a
L<Mojolicious::Renderer> instance to resolve template names. This means that
L<Mojolicious::Renderer/"paths"> will be searched for file-based templates, and
L<Mojolicious::Renderer/"classes"> will be searched for DATA templates. The
C<ENCODING> configuration setting will be initialized to
L<Mojolicious::Renderer/"encoding"> if unset.

=head1 METHODS

L<Template::Provider::Mojo> inherits all methods from L<Template::Provider> and
implements the following new ones.

=head2 fetch

Returns a compiled template for the name specified. See L<Template::Provider/"fetch($name)">
for usage details.

=head2 load

Loads a template without parsing or compiling it. This is used by the
L<INSERT|Template::Manual::Directives/"INSERT"> directive.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Template>, L<Mojolicious::Renderer>, L<Mojolicious::Plugin::TemplateToolkit>
