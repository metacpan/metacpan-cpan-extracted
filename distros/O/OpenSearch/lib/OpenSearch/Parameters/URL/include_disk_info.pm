
  package OpenSearch::Parameters::URL::include_disk_info;
  use Moose::Role;

  has "include_disk_info" => (
    is => "rw",
    isa => "Bool",
    documentation => {
      encode_func => "encode_bool",
      required => undef,
    }
  );

  around "include_disk_info" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
