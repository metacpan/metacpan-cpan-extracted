
  package OpenSearch::Parameters::URL::cluster_manager_timeout;
  use Moose::Role;
	use Moose::Util::TypeConstraints;

	subtype 'ClusterManagerTimeout', as 'Str', where { $_ =~ /^[0-9]+[sShHmMdD]/ };

  has "cluster_manager_timeout" => (
    is => "rw",
    isa => "ClusterManagerTimeout",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "cluster_manager_timeout" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
