
  package OpenSearch::Parameters::Body::_source;
  use Moose::Role;

  has "_source" => (
    is            => "rw",
    isa           => "OpenSearch::Filter::Source",
    documentation => {
      encode_func => undef,
      required    => undef,
    }
  );

  around "_source" => sub {
    my $orig = shift;
    my $self = shift;

    if (@_) {

      if ( ref( $_[0] ) eq "OpenSearch::Filter::Source" ) {
        $self->$orig( $_[0] );
      } else {
        $self->$orig( OpenSearch::Filter::Source->new(@_) );
      }

      return ($self);

    }
    return ( $self->$orig );
  };

  1;
