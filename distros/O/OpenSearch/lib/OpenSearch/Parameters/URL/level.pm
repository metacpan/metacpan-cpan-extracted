
  package OpenSearch::Parameters::URL::level;
  use Moose::Role;
  use Moose::Util::TypeConstraints;

  enum 'Level' => [qw/cluster indicies shards awareness_attributes/];

  has "level" => (
    is => "rw",
    isa => "Level",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "level" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
