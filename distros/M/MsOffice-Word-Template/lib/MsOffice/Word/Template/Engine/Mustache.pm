package MsOffice::Word::Template::Engine::Mustache;
use 5.024;
use Moose;
use Template::Mustache;

extends 'MsOffice::Word::Template::Engine';


use namespace::clean -except => 'meta';

our $VERSION = '2.04';

#======================================================================
# ATTRIBUTES
#======================================================================

has       'start_tag'         => (is => 'ro',   isa => 'Str',  default  => "{{");
has       'end_tag'           => (is => 'ro',   isa => 'Str',  default  => "}}");

#======================================================================
# METHODS
#======================================================================

sub compile_template {
  my ($self, $template_text) = @_;

  return Template::Mustache->new(
    template => $template_text,
    $self->{_constructor_args}->%*,
   );
}


sub process_part {
  my ($self, $part_name, $package_part, $vars) = @_;

  # currently a no-op; but here is a chance to do some processing with $part_name and $vars

  return $self->process($part_name, $vars);
}

sub process {
  my ($self, $template_name, $vars) = @_;

  my $tmpl         = $self->compiled_template->{$template_name}
    or die "don't have a compiled template for '$template_name'";

  my $new_contents = $tmpl->render($vars);

  return $new_contents;
}


1;

__END__

=encoding ISO-8859-1

=head1 NAME

MsOffice::Word::Template::Engine::Mustache -- Word::Template engine based on Mustache

=head1 DESCRIPTION

Implements a templating engine for L<MsOffice::Word::Template>, based on
L<Template::Mustache>.


