
  package OpenSearch::Parameters::Body::query;
  use Moose::Role;

  has "query" => (
    is => "rw",
    isa => "HashRef",
    documentation => {
      encode_func => undef,
      required => undef,
      merge_hash_instead => 1,
    }
  );

  around "query" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
