
package OpenSearch::Parameters::URL::nodes;
use Moose::Role;
use OpenSearch::Filter::Nodes;

has "nodes" => (
  is => "rw",
  isa => "OpenSearch::Filter::Nodes",
  documentation => {
    encode_func => undef,
    required => undef,
  }
);

around "nodes" => sub {
  my $orig = shift;
  my $self = shift;

  if(@_) {
    $self->$orig(OpenSearch::Filter::Nodes->new(@_));
    return($self);
  }
  return($self->$orig);
};

1;
