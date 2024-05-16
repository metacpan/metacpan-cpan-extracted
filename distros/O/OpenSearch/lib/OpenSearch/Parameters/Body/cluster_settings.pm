
  package OpenSearch::Parameters::Body::cluster_settings;
  use Moose::Role;

  has "cluster_settings" => (
    is => "rw",
    isa => "HashRef",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "cluster_settings" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      #$self->$orig(OpenSearch::Filter::Source->new(@_));
      return($self);
    }
    return($self->$orig);
  };

1;
