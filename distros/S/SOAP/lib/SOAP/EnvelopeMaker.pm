package SOAP::EnvelopeMaker;

use strict;
use vars qw($VERSION);
use SOAP::Defs;
use SOAP::TypeMapper;
use SOAP::Envelope;

$VERSION = '0.28';

sub new {
    my ($class, $print_fcn, $type_mapper) = @_;
    
    # v0.25 - added support for passing a string reference
    if ('SCALAR' eq ref $print_fcn) {
	my $string_ref = $print_fcn;
	$print_fcn = sub {
	    $$string_ref .= shift;
	}
    }

    $type_mapper ||= SOAP::TypeMapper->defaultMapper();

    my $self = {
        envelope    => undef,
        print_fcn   => $print_fcn,
        type_mapper => $type_mapper,
    };
    bless $self, $class;
}

sub add_header {
    my ($self, $accessor_uri, $accessor_name,
               $must_understand, $is_package,
               $object) = @_;

    unless (defined $object) {
	die "add_header was passed a null object reference";
    }

    my $serializer = $self->{type_mapper}->get_serializer($object);
    my ($typeuri, $typename) = $serializer->get_typeinfo();

    my @namespaces_to_preload;
    push @namespaces_to_preload, $accessor_uri if $accessor_uri;
    push @namespaces_to_preload, $typeuri      if $typeuri;

    my $env = $self->_get_envelope(\@namespaces_to_preload);

    my $stream = $env->header($accessor_uri, $accessor_name,
                              $typeuri, $typename,
                              $must_understand, $is_package,
			      ref $object ? $object : undef);
    $self->_serialize_and_term($serializer, $stream);
}

sub set_body {
    my ($self, $accessor_uri, $accessor_name,
               $is_package, $object) = @_;

    unless (defined $object) {
	die "set_body was passed a null object reference";
    }
    my $serializer = $self->{type_mapper}->get_serializer($object);
    my ($typeuri, $typename) = $serializer->get_typeinfo();

    my @namespaces_to_preload;
    push @namespaces_to_preload, $accessor_uri if $accessor_uri;
    push @namespaces_to_preload, $typeuri      if $typeuri;

    my $env = $self->_get_envelope(\@namespaces_to_preload);

    my $stream = $env->body($accessor_uri, $accessor_name,
                            $typeuri, $typename,
                            $is_package,
			    $serializer->is_multiref() ? $object : undef);
    $self->_serialize_and_term($serializer, $stream);
    $env->term();
    $self->{envelope} = undef;
}

sub _serialize_and_term {
    my ($self, $serializer, $stream) = @_;

    if ($stream) {
	if ($serializer->is_compound()) {
	    $serializer->serialize($stream, $self->{envelope});
	}
	else {
	    $self->{print_fcn}->($serializer->serialize_as_string())
	}
	$stream->term();
    }
}

sub _get_envelope {
    my ($self, $namespaces_to_preload) = @_;

    if (my $env = $self->{envelope}) {
        return $env;
    }
    my $env = $self->{envelope} = SOAP::Envelope->new($self->{print_fcn},
                                                      $namespaces_to_preload,
                                                      $self->{type_mapper});
}

1;
__END__

=head1 NAME

SOAP::EnvelopeMaker - Creates SOAP envelopes

=head1 SYNOPSIS

use SOAP::EnvelopeMaker;

my $soap_request = '';
my $output_fcn = sub {
    $soap_request .= shift;
};
my $em = SOAP::EnvelopeMaker->new($output_fcn);

my $body = SOAP::Struct->new(
    origin => { x => 10,  y => 20  },
    corner => { x => 100, y => 200 },
);

$em->set_body("urn:com-develop-geometry", "calculateArea", 0, $body);

my $host        = "soapl.develop.com";
my $port        = 80;
my $endpoint    = "/soap?class=Geometry";
my $method_uri  = "urn:com-develop-geometry";
my $method_name = "calculateArea";

use SOAP::Transport::HTTP::Client;

my $soap_on_http = SOAP::Transport::HTTP::Client->new();

my $soap_response = $soap_on_http->send_receive($host, $port, $endpoint,
                                                $method_uri,
                                                $method_name,
                                                $soap_request);
use SOAP::Parser;
my $soap_parser = SOAP::Parser->new();
$soap_parser->parsestring($soap_response);

my $area = $soap_parser->get_body()->{result};

print "The area is: $area\n";

=head1 DESCRIPTION

The overall usage pattern of SOAP::EnvelopeMaker is as follows:

1) Determine what you want to do with the resulting SOAP packet
   and create an output function that implements this policy.

2) Create an instance of SOAP::EnvelopeMaker, passing a reference
   to your output function, or to a string if you were just planning
   on buffering the output anyway (in this case, you'll get an output
   function that looks like this: sub {$$r .= shift}

(note that somebody may already have done these first two steps
 on your behalf and simply passed you a reference to a pre-initialized
 EnvelopeMaker - see SOAP::Transport::HTTP::Server for an example)

3) (optional) Call add_header one or more times to specify headers.

4) (required) Call set_body to specify the body.

5) Throw away the EnvelopeMaker and do something with the envelope
   that you've collected via your output function (assuming you've
   not simply been piping the output somewhere as it's given to you).

EnvelopeMaker expects that you'll add *all* your headers *before*
setting the body - if you mess this up, the results are undefined.

By the time set_body returns, a complete SOAP envelope will have been
sent to your output function (in one or more chunks). You can 

=head2 new(OutputFcn)

OutputFcn should accept a single scalar parameter, and will be called
multiple times with chunks of the SOAP envelope as it is constructed.
You can either append these chunks into a big string, waiting until
the entire envelope is constructed before you do something with it
(like calculate the content-length, for instance), or you can simply
pipe each chunk directly to somebody else.

As of version 0.25, you can now pass a string reference for OutputFcn
and the EnvelopeMaker will provide a very simple buffering output
function (one that we all ended up writing anyway during testing):
sub {$$r .= shift}

=head2 add_header(AccessorUri, AccessorName, MustUnderstand, IsPackage, Object)

The first two parameters allow you to specify a QName (qualified name)
for your header. Note that in SOAP, all headers MUST be namespace
qualified. MustUnderstand and IsPackage turn on SOAP features that are
explained in the SOAP spec; if you haven't yet grok'd SOAP packages,
just pass 0 for IsPackage. Finally, Object is whatever you'd like to
serialize into the header (see set_body for notes on what can go here;
headers can contain the same stuff as the body).

=head2 set_body(AccessorUri, AccessorName, IsPackage, Object)

The first two parameters allow you to specify a QName (qualified name)
for the body. The name of the accessor is the name of the SOAP method
call you're making. IsPackage says that the body will be a SOAP package;
just pass 0 if you're not sure what this means. Object is whatever you'd
like to serialize. This can be one of the following things:

1) a scalar - the body will contain the scalar content.

2) a hash reference - the body will contain a SOAP serialized version
                      of the contents of the hash.

3) a SOAP::Struct reference - the body will contain a SOAP serialized
                              version of the struct, where the serialized
                              contents of the struct will be in the same
                              order in the SOAP bar as they appeared
                              in the SOAP::Struct constructor.

Note that the SOAP/Perl serialization architecture deals with references
very carefully, so it is possible to pass arbitrary object graphs (although
each "object reference" must currently be a non-blessed scalar or hash reference).

In the future, expect to see support for passing blessed object references
(if you want to do this today, see the experimental SOAP::TypeMapper).
SOAP::Struct is an example of this.

One interesting thing SOAP (and SOAP/Perl) support is that the headers
and body can share references. They can point to the same stuff. Also,
cycle detection is a natural part of SOAP/Perl's serialization architecture,
so you can pass linked lists, circular queues, etc. and they will be
rehydrated correctly.

=head1 DEPENDENCIES

SOAP::Envelope

=head1 AUTHOR

Keith Brown

=head1 SEE ALSO

SOAP::Envelope

=cut
