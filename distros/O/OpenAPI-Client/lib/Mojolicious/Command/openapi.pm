package Mojolicious::Command::openapi;
use Mojo::Base 'Mojolicious::Command';

use OpenAPI::Client;
use Mojo::JSON qw(encode_json decode_json j);
use Mojo::Util qw(encode getopt);

use constant YAML    => eval 'require YAML::XS;1';
use constant REPLACE => $ENV{JSON_VALIDATOR_REPLACE} // 1;

sub _say  { length && say encode('UTF-8', $_) for @_ }
sub _warn { warn @_ }

has description => 'Perform Open API requests';
has usage       => sub { shift->extract_usage . "\n" };

has _client => undef;

sub run {
  my ($self, @args) = @_;
  my %ua;

  getopt \@args,
    'i|inactivity-timeout=i' => sub { $ua{inactivity_timeout} = $_[1] },
    'I|information'          => \my $info,
    'o|connect-timeout=i'    => sub { $ua{connect_timeout} = $_[1] },
    'p|parameter=s'          => \my %parameters,
    'c|content=s'            => \my $content,
    'S|response-size=i'      => sub { $ua{max_response_size} = $_[1] },
    'v|verbose'              => \my $verbose;

  # Read body from STDIN
  vec(my $r, fileno(STDIN), 1) = 1;
  $content //= !-t STDIN && select($r, undef, undef, 0) ? join '', <STDIN> : undef;

  my @client_args = (shift @args);
  my $op          = shift @args;
  my $selector    = shift @args // '';

  die $self->usage unless $client_args[0];

  if ($client_args[0] =~ m!^/! and !-e $client_args[0]) {
    $client_args[0] = Mojo::URL->new($client_args[0]);
    push @client_args, app => $self->app;
  }

  $self->_client(OpenAPI::Client->new(@client_args));
  return $self->_info($op) if $info;
  return $self->_list                  unless $op;
  die qq(Unknown operationId "$op".\n) unless $self->_client->can($op);

  $self->_client->ua->proxy->detect unless $ENV{OPENAPI_NO_PROXY};
  $self->_client->ua->$_($ua{$_}) for keys %ua;
  $self->_client->ua->on(
    start => sub {
      my ($ua, $tx) = @_;
      weaken $tx;
      $tx->res->content->on(body => sub { _warn _header($tx->req), _header($tx->res) }) if $verbose;
    }
  );

  my $tx = $self->_client->call($op => \%parameters, $content ? (json => decode_json $content) : ());
  if ($tx->error and $tx->error->{message} eq 'Invalid input') {
    _warn _header($tx->req), _header($tx->res) if $verbose;
  }

  return _json($tx->res->json, $selector) if !length $selector || $selector =~ m!^/!;
  return _say $tx->res->dom->find($selector)->each;
}

sub _header { $_[0]->build_start_line, $_[0]->headers->to_string, "\n\n" }

sub _info {
  my ($self, $op) = @_;
  local $YAML::XS::Boolean = 'JSON::PP';

  unless ($op) {
    my $op_spec = $self->_client->validator->bundle->data;
    return _say YAML ? YAML::XS::Dump($op_spec) : Mojo::Util::dumper($op_spec);
  }

  my ($schema, $op_spec) = ($self->_client->validator);
  for my $route ($schema->routes->each) {
    next if !$route->{operation_id} or $route->{operation_id} ne $op;
    $op_spec = $schema->get(['paths', @$route{qw(path method)}]);
  }

  return _warn qq(Could not find the given operationId "$op".\n) unless $op_spec;
  local $YAML::XS::Boolean = 'JSON::PP';
  return _say YAML ? YAML::XS::Dump($op_spec) : Mojo::Util::dumper($op_spec);
}

sub _json {
  return            unless defined(my $data = Mojo::JSON::Pointer->new(shift)->get(shift));
  return _say $data unless ref $data eq 'HASH' || ref $data eq 'ARRAY';
  _say Mojo::Util::decode('UTF-8', encode_json $data);
}

sub _list {
  my $self = shift;
  _warn "--- Operations for @{[$self->_client->base_url]}\n";
  $_->{operation_id} && _say $_->{operation_id} for $self->_client->validator->routes->each;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::openapi - Perform Open API requests

=head1 SYNOPSIS

  Usage: APPLICATION openapi SPECIFICATION OPERATION "{ARGUMENTS}" [SELECTOR|JSON-POINTER]

    # Fetch /api from myapp.pl and list available operationId
    ./myapp.pl openapi /api

    # Dump the whole specification or for an operationId
    ./myapp.pl openapi /api -I
    ./myapp.pl openapi /api -I addPet

    # Run an operation against a local application
    ./myapp.pl openapi /api listPets /pets/0

    # Run an operation against a local application, with body parameter
    ./myapp.pl openapi /api addPet -c '{"name":"pluto"}'
    echo '{"name":"pluto"} | ./myapp.pl openapi /api addPet

    # Run an operation with parameters
    mojo openapi spec.json listPets -p limit=10 -p type=dog

    # Run against local or online specifications
    mojo openapi /path/to/spec.json listPets
    mojo openapi http://service.example.com/api.json listPets

  Options:
    -h, --help                           Show this summary of available options
    -c, --content <content>              JSON content, with body parameter data
    -i, --inactivity-timeout <seconds>   Inactivity timeout, defaults to the
                                         value of MOJO_INACTIVITY_TIMEOUT or 20
    -I, --information [operationId]      Dump the specification about a given
                                         operationId or the whole spec.
                                         YAML::XS is preferred if available.
    -o, --connect-timeout <seconds>      Connect timeout, defaults to the value
                                         of MOJO_CONNECT_TIMEOUT or 10
    -p, --parameter <name=value>         Specify multiple header, path, or
                                         query parameter
    -S, --response-size <size>           Maximum response size in bytes,
                                         defaults to 2147483648 (2GB)
    -v, --verbose                        Print request and response headers to
                                         STDERR

=head1 DESCRIPTION

L<Mojolicious::Command::openapi> is a command line interface for
L<OpenAPI::Client>.

Not that this implementation is currently EXPERIMENTAL! Feedback is
appreciated.

=head1 ATTRIBUTES

=head2 description

  $str = $command->description;

=head2 usage

  $str = $command->usage;

=head1 METHODS

=head2 run

  $command->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<OpenAPI::Client>.

=cut
