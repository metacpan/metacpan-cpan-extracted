package Template::EmbeddedPerl::Compiled;

use warnings;
use strict;
use Template::EmbeddedPerl::Utils 'generate_error_message';

sub render {
  my ($self, @args) = @_;
  my $context = $self->{yat}->_new_render_context(source => $self->{source});
  my $entry = {
    kind => 'root',
    identifier => $self->{identifier} || $self->{source} || '<string>',
    source => $self->{source},
  };
  return $self->_render_with_context($context, $entry, @args);
}

sub _render_with_context {
  my ($self, $context, $entry, @args) = @_;
  return $context->execute_render($entry, sub {
    return $self->_execute_with_context($context, @args);
  });
}

sub _execute_with_context {
  my ($self, $context, @args) = @_;
  my $frame = $context->frame;
  my $output;
  my $ok;
  my $error;
  {
    no warnings 'once';
    local $Template::EmbeddedPerl::ACTIVE_RENDERER = $context;
    $ok = eval {
      $output = $self->{code}->($context, @args);
      my $layouts = $frame->take_layouts;
      for my $layout (reverse @$layouts) {
        my ($identifier, $layout_args) = @$layout;
        $output = $frame->with_body($output, sub {
          return $context->render_file('layout', $identifier, @$layout_args);
        });
      }
      1;
    };
    $error = $@ unless $ok;
  }
  $ok or do {
    die generate_error_message($error, $self->{template}, $self->{source});
  };
  return $output;
}

1;

=head1 NAME

Template::EmbeddedPerl::Compiled - Compiled template

=head1 DESCRIPTION

This module is used internally by L<Template::EmbeddedPerl> to represent a compiled template. It is not intended to be used directly.

=head1 METHODS

=head2 render

  my $output = $compiled->render(@args);

Render the template with the given arguments.

=head1 SEE ALSO
  
L<Template::EmbeddedPerl>

=head1 AUTHOR
  
See L<Template::EmbeddedPerl>
 
=head1 COPYRIGHT & LICENSE
  
See L<Template::EmbeddedPerl>
 
=cut
