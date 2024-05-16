
  package OpenSearch::Parameters::URL::wait_for_nodes;
  use Moose::Role;
  use Moose::Util::TypeConstraints;

	subtype 'WaitForNodes', as 'Str', where { $_ =~ /^[<>]?[0-9]+$/ };


  has "wait_for_nodes" => (
    is => "rw",
    isa => "WaitForNodes",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "wait_for_nodes" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
