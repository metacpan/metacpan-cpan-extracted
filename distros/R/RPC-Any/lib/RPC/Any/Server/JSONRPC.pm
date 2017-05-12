package RPC::Any::Server::JSONRPC;
use Moose;
use Class::MOP;
use JSON::RPC::Common::Marshal::Text;
use RPC::XML qw(smart_encode);

extends 'RPC::Any::Server';

has parser    => (is => 'rw', isa => 'JSON::RPC::Common::Marshal::Text',
                  lazy_build => 1);
has _last_call => (is => 'rw', isa => 'JSON::RPC::Common::Procedure::Call',
                   clearer => '_clear_last_call');
has default_version => (is => 'rw', isa => 'Str', default => '2.0');
has '+package_base' => (default => 'RPC::Any::Package::JSONRPC');

before 'get_input' => sub {
    my $self = shift;
    $self->_clear_last_call();
};

sub decode_input_to_object {
    my ($self, $input) = @_;
    if (!defined $input or $input eq '') {
        $self->exception("ParseError", "You did not supply any JSON to parse.");
    }
    $self->parser->json->utf8(utf8::is_utf8($input) ? 0 : 1);
    my $request = eval { $self->parser->json_to_call($input) };
    if ($@) {
        $self->exception('ParseError', "Error while parsing JSON request: $@");
    }
    return $request;
}

sub input_object_to_data {
    my ($self, $input_object) = @_;
    $self->_last_call($input_object);
    my $params = $input_object->params;
    if (ref $params ne 'ARRAY') {
        $params = [$params];
    }
    return { method    => $input_object->method,
             arguments => $params };
}

sub output_data_to_object {
    my ($self, $method_result) = @_;
    my $json_return = $self->_last_call->return_result($method_result);
    return $json_return;
}

sub encode_output_from_object {
    my ($self, $output_object) = @_;
    return $self->parser->return_to_json($output_object);
}

sub encode_output_from_exception {
    my ($self, $exception) = @_;
    my %error_params = (
        message => $exception->message,
        code    => $exception->code,
    );
    my $json_error;
    if ($self->_last_call) {
        $json_error = $self->_last_call->return_error(%error_params);
    }
    # Default to default_version. This happens when we throw an exception
    # before inbound parsing is complete.
    else {
        $json_error = $self->_default_error(%error_params);
    }
    return $self->encode_output_from_object($json_error);
}

sub _default_error {
    my ($self, %params) = @_;
    my $version = $self->default_version;
    $version =~ s/\./_/g;
    my $error_class = "JSON::RPC::Common::Procedure::Return::Version_${version}::Error";
    Class::MOP::load_class($error_class);
    my $error = $error_class->new(%params);
    my $return_class = "JSON::RPC::Common::Procedure::Return::Version_$version";
    Class::MOP::load_class($return_class);
    return $return_class->new(error => $error);
}

sub _build_parser {
    return JSON::RPC::Common::Marshal::Text->new();
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

RPC::Any::Server::JSONRPC - A basic JSON-RPC server

=head1 SYNOPSIS

 use RPC::Any::Server::JSONRPC;
 # Create a server where calling Foo.bar will call My::Module->bar.
 my $server = RPC::Any::Server::JSONRPC->new(
    dispatch => { 'Foo' => 'My::Module' },
    default_version => '2.0',
 );

 # Read JSON from STDIN and print JSON to STDOUT.
 print $server->handle_input();

=head1 DESCRIPTION

This is a server that implements the various
L<JSON-RPC|http://groups.google.com/group/json-rpc/web> specifications.
It supports JSON-RPC 1.0, 1.1, and 2.0. It uses L<JSON::RPC::Common>
as its backend for parsing input and producing output, and so
it supports everything that that module supports.

This is a basic server that just takes JSON as input to C<handle_input>,
and produces JSON as the output from C<handle_input>. It doesn't understand
HTTP headers or anything like that, and it doesn't produce HTTP headers. For
that, see L<RPC::Any::Server::JSONRPC::HTTP> or
L<RPC::Any::Server::JSONRPC::CGI>.

See L<RPC::Any::Server> for a basic description of how servers
work in RPC::Any.

=head1 JSONRPC SERVER ATTRIBUTES

These are additional attributes beyond what is specified in
L<RPC::Any::Server> that are available for a JSON-RPC server.
These can all be specified during C<new> or set like
C<< $server->method($value) >>. They are all optional.

=over

=item C<default_version>

This is a string specifying the version to use for error messages
in situations where the server doesn't know the JSON-RPC version
of the incoming message. (This happens when there is an error
parsing the JSON-RPC input--we haven't parsed the input, so we
don't know what JSON-RPC version is in use.) This defaults to
C<2.0> if not specified.

=item C<parser>

This is a L<JSON::RPC::Common::Marshal::Text> instance that is
used to parse incoming JSON and produce output JSON.

=back