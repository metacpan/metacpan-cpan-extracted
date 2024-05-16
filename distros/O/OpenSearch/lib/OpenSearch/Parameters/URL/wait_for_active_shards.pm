
  package OpenSearch::Parameters::URL::wait_for_active_shards;
  use Moose::Role;
  use Moose::Util::TypeConstraints;

  subtype 'WaitForActiveShards', as 'Str', where { $_ =~ /^[0-9]+|all$/ };

  has "wait_for_active_shards" => (
    is => "rw",
    isa => "WaitForActiveShards",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "wait_for_active_shards" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
