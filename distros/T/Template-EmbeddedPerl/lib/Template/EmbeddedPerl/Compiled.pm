package Template::EmbeddedPerl::Compiled;

use warnings;
use strict;
use Template::EmbeddedPerl::Utils 'generate_error_message';

sub render {
  my ($self, @args) = @_;
  my $output;
  eval { $output = $self->{code}->(@args); 1 } or do {
    die generate_error_message($@, $self->{template});
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


