package Mock::HTTPClient;
 
sub new {
  my ($class, %args) = @_;

  # required validation
  die "content param is required" unless $args{content};
  die "status param is required"  unless $args{status};

  return bless \%args || {}, $class;
}
 
sub post {
  my ($self, $url, $params) = @_;

  # setting informations for testing
  $self->{url}    = $url;
  $self->{params} = $params;

  return $self;
}
 
sub is_success {
  my $self = shift;
  return $self->{status} eq '200 OK'? 1 : 0; 
}
 
sub content {
  my $self = shift;
  return $self->{content};
}

sub decoded_content { shift->content }

1;
