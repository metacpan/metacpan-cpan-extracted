package MsOffice::Word::Template::Engine::Mustache;
use 5.024;
use Moose;
use Template::Mustache;

extends 'MsOffice::Word::Template::Engine';


use namespace::clean -except => 'meta';

our $VERSION = '2.0';

#======================================================================
# ATTRIBUTES
#======================================================================

has       'start_tag'         => (is => 'ro',   isa => 'Str',  default  => "{{");
has       'end_tag'           => (is => 'ro',   isa => 'Str',  default  => "}}");

#======================================================================
# METHODS
#======================================================================

sub compile_template {
  my ($self, $part_name, $template_text) = @_;

  $self->{compiled_template}{$part_name} = Template::Mustache->new(
    template => $template_text,
    $self->{_constructor_args}->%*,
   );
}


sub process {
  my ($self, $part_name, $package_part, $vars) = @_;

  my $tmpl         = $self->{compiled_template}{$part_name}
    or die "don't have a compiled template for '$part_name'";

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


