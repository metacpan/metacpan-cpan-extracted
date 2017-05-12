package POE::Component::Client::REST::Test::HTTP;
use Moose;
use Sub::Exporter -setup => {exports => [qw(json_responder)]};
use Carp qw(croak);
use HTTP::Response;
use JSON;
use POE;

sub json_responder {
  my $content = encode_json(shift);
  my $res = HTTP::Response->new(200);
  $res->header('Content-Type' => 'application/json');
  $res->header('Content-Encoding' => 'UTF-8');
  $res->content_length(bytes::length($content));
  $res->content($content);
  return sub { $res };
}

has responses => (
  is      => 'ro', 
  isa     => 'ArrayRef',
  default => sub { {} },
);

has Alias => (
  is      => 'ro',
  isa     => 'Str',
  default => "TESTYBlAH"
);

sub BUILD {
  my ($self, $args) = @_;
  POE::Session->create(object_states => [$self => {
    map  { substr($_,1) => $_ }
    grep {  /^_.*/ }
    $self->meta->get_method_list()
  }]);
}

sub __start {
  $poe_kernel->alias_set($_[OBJECT]->Alias);
}

sub _request {
  my ($self, $sender, $state, $request) = @_[OBJECT, SENDER, ARG0, ARG1];
  my $path = $request->uri->path;
  my $r = $self->responses;
  while (@$r) {
    my $regex = shift(@$r);
    my $sub = shift(@$r);
    if ($path =~ $regex) {
      $poe_kernel->post($sender, $state, [$request], [$sub->($request)]);
      return;
    }
  }
  croak "No handler for $path";
}

sub _shutdown {
  $poe_kernel->alias_remove($_[OBJECT]->Alias);
}

sub replace {
  my ($self, $rest) = @_;
  $poe_kernel->post($rest->http, 'shutdown');
  $rest->meta->find_attribute_by_name('http')->set_value($rest, $self->Alias);
}

1;
