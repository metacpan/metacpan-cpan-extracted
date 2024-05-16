
  package OpenSearch::Parameters::URL::timeout;
  use Moose::Role;
	use Moose::Util::TypeConstraints;

	subtype 'Timeout', as 'Str', where { $_ =~ /^[0-9]+[sShHmMdD]/ };

  has "timeout" => (
    is => "rw",
    isa => "Timeout",
    documentation => {
      encode_func => undef,
      required => undef,
    }
  );

  around "timeout" => sub {
    my $orig = shift;
    my $self = shift;

    if(@_) {
      $self->$orig(@_);
      return($self);
    }
    return($self->$orig);
  };

1;
