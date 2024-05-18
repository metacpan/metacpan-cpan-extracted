
  package OpenSearch::Parameters::URL::version;
  use Moose::Role;

  # Documents version number. Not the same as the Body version number which
  # determins weather the response should contain the document version number and is bool
  has "version" => (
    is            => "rw",
    isa           => "Int",
    documentation => {
      encode_func => undef,
      required    => undef,
    }
  );

  around "version" => sub {
    my $orig = shift;
    my $self = shift;

    if (@_) {
      $self->$orig(@_);
      return ($self);
    }
    return ( $self->$orig );
  };

  1;
