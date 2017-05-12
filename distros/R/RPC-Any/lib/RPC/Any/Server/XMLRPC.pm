package RPC::Any::Server::XMLRPC;
use Moose;
use RPC::XML::ParserFactory;
use RPC::XML qw(smart_encode);

extends 'RPC::Any::Server';

has parser => (is => 'rw', isa => 'RPC::XML::Parser', lazy_build => 1);
has send_nil => (is => 'rw', isa => 'Bool', default => 0);
has '+package_base' => (default => 'RPC::Any::Package::XMLRPC');

sub decode_input_to_object {
    my ($self, $input) = @_;
    if (!defined $input or $input eq '') {
        $self->exception("ParseError", "You did not supply any XML to parse.");
    }
    local $RPC::XML::ALLOW_NIL = 1;
    $self->escape_xml($input);
    my $xml_object = $self->parser->parse($input);
    if (!blessed $xml_object) {
        $self->exception('ParseError',
                         "Error while parsing XML-RPC request: $xml_object");
    }
    return $xml_object;
}

sub escape_xml {
    # High-ASCII characters need to be escaped, or parse() dies.
    $_[1] =~ s/([\x80-\xFF])/sprintf('&#x%02x;',ord($1))/eg;
}

sub input_object_to_data {
    my ($self, $input_object) = @_;
    my %result = ( method => $input_object->name );
    my @args;
    foreach my $arg (@{ $input_object->args }) {
        push(@args, $arg->value);
    }
    $result{arguments} = \@args;
    return \%result;
}

sub output_data_to_object {
    my ($self, $method_result) = @_;
    local $RPC::XML::ALLOW_NIL = $self->send_nil;
    $self->handle_undefs($method_result) if !$self->send_nil;
    my $encoded = smart_encode($method_result);
    return RPC::XML::response->new($encoded);
}

sub handle_undefs {
    my $self = shift;
    $self->walk_data($_[0], \&_undef_to_string);
}

sub _undef_to_string {
    my ($value) = @_;
    if (!defined $value or eval { $value->isa('RPC::XML::nil') }) {
        $_[0] = RPC::XML::string->new('');
    }
}

sub encode_output_from_object {
    my ($self, $output_object) = @_;
    # XXX For some reason, RPC::XML is always returning character strings
    #     instead of byte strings, even when there is no Unicode in the
    #     output.
    local $RPC::XML::ENCODING = 'UTF-8';
    return $output_object->as_string;
}

sub encode_output_from_exception {
    my ($self, $exception) = @_;
    my $xmlrpc_error = RPC::XML::fault->new($exception->code,
                                            $exception->message);
    my $return_object = $self->output_data_to_object($xmlrpc_error);
    return $self->encode_output_from_object($return_object);
}

sub _build_parser {
    return RPC::XML::ParserFactory->new();
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

RPC::Any::Server::XMLRPC - A basic XML-RPC server

=head1 SYNOPSIS

 use RPC::Any::Server::XMLRPC;
 # Create a server where calling Foo.bar will call My::Module->bar.
 my $server = RPC::Any::Server::XMLRPC->new(
    dispatch => { 'Foo' => 'My::Module' },
    send_nil => 0,
 );
 # Read XML from STDIN and print XML result to STDOUT.
 print $server->handle_input();

=head1 DESCRIPTION

This is a server that takes I<just> XML-RPC as input, and produces
I<just> XML-RPC as output. It doesn't understand HTTP headers or anything
like that, and it doesn't produce HTTP headers. For that, see
L<RPC::Any::Server::XMLRPC::HTTP> or L<RPC::Any::Server::XMLRPC::CGI>.

See L<RPC::Any::Server> for a basic description of how servers
work in RPC::Any.

Currently, RPC::Any::Server::XMLRPC uses L<RPC::XML> in its backend
to parse incoming XML-RPC, and to produce outbound XML-RPC. We
do not use the server components of RPC::XML, just the parser.

=head1 XMLRPC SERVER ATTRIBUTES

These are additional attributes beyond what is specified in
L<RPC::Any::Server> that are available for an XML-RPC server.
These can all be specified during C<new> or set like
C<< $server->method($value) >>. They are all optional.

=over

=item C<send_nil>

There is an extension to the XML-RPC protocol that specifies an
additional type of tag, called C<< <nil> >>. The extension is
specified at L<http://ontosys.com/xml-rpc/extensions.php>.

RPC::Any XMLRPC Servers I<always> understand C<nil> if you
send it to them. However, your clients may not understand C<nil>,
so this is a boolean that lets you control whether or not
RPC::Any::Server::XMLRPC will produce output with C<nil> in it.

When C<send_nil> is true, any instance of C<undef> or L<RPC::XML::nil>
in a method's return value will be converted to C<< <nil> >>.
When C<send_nil> is false, any instance of C<undef> or L<RPC::XML::nil>
in a method's return value will be converted to an empty
C<< <string> >>.

=item C<parser>

This is the L<RPC::XML::Parser> instance that RPC::Any::Server:XMLRPC
is using internally. Usually you will not have to modify this.

=back