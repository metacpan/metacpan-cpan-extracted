
  package OpenSearch::Parameters::URL::expand_wildcards;
  use Moose::Role;
  use Moose::Util::TypeConstraints;

  enum 'ExpandWildcards' => [qw/all open closed hidden none/];

  has "expand_wildcards" => (
    is => "rw",
    isa => "ExpandWildcards",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "expand_wildcards" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
