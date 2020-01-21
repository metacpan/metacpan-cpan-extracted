package SOAP::WSDL;
use strict;
use warnings;

use 5.008;  # require at least perl 5.8

use vars qw($AUTOLOAD);

use Carp;
use Scalar::Util qw(blessed);
use SOAP::WSDL::Client;
use SOAP::WSDL::Expat::WSDLParser;
use Class::Std::Fast constructor => 'none';
use SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType;
use LWP::UserAgent;

# perl -p -i -e 's{our \$VERSION = 3\.\d*;}{our \$VERSION = 3.003;}' `ack -l 'our \\$VERSION = '`      # in the lib/ directory, to change version numbers
our $VERSION = 3.004;

my %no_dispatch_of      :ATTR(:name<no_dispatch>);
my %wsdl_of             :ATTR(:name<wsdl>);
my %autotype_of         :ATTR(:name<autotype>);
my %outputxml_of        :ATTR(:name<outputxml> :default<0>);
my %outputtree_of       :ATTR(:name<outputtree>);
my %outputhash_of       :ATTR(:name<outputhash>);
my %servicename_of      :ATTR(:name<servicename>);
my %portname_of         :ATTR(:name<portname>);
my %class_resolver_of   :ATTR(:name<class_resolver>);

my %method_info_of      :ATTR(:default<()>);
my %port_of             :ATTR(:default<()>);
my %porttype_of         :ATTR(:default<()>);
my %binding_of          :ATTR(:default<()>);
my %service_of          :ATTR(:default<()>);
my %definitions_of      :ATTR(:get<definitions> :default<()>);
my %serialize_options_of :ATTR(:default<()>);

my %client_of           :ATTR(:name<client>     :default<()>);
my %keep_alive_of       :ATTR(:name<keep_alive> :default<0> );

my %LOOKUP = (
  no_dispatch           => \%no_dispatch_of,
  class_resolver        => \%class_resolver_of,
  wsdl                  => \%wsdl_of,
  autotype              => \%autotype_of,
  outputxml             => \%outputxml_of,
  outputtree            => \%outputtree_of,
  outputhash            => \%outputhash_of,
  portname              => \%portname_of,
  servicename           => \%servicename_of,
  keep_alive            => \%keep_alive_of,
);

sub readable { carp <<'EOT';
'readable' has no effect any more. If you want formatted XML,
copy the debug output to your favorite XML editor and run the
source format command.
EOT
    return;
}

sub set_readable; *set_readable = \&readable;

for my $method (keys %LOOKUP ) {
    no strict qw(refs); ## no critic (ProhibitNoStrict)
    *{ $method } = sub {
        my $self = shift;
        my $ident = ident $self;
        if (@_) {
            $LOOKUP{ $method }->{ $ident } = shift;
            return $self;
        }
        return $LOOKUP{ $method }->{ $ident };
    };
}

{   # just a BLOCK for scoping warnings.

    # we need to roll our own for supporting
    # SOAP::WSDL->new( key => value ) syntax,
    # like SOAP::Lite does. Class::Std enforces a single hash ref as
    # parameters to new()
    no warnings qw(redefine);   ## no critic ProhibitNoWarnings;

    sub new {
        my ($class, %args_from) = @_;
        my  $self = \do { my $foo = Class::Std::Fast::ID() };
        bless $self, $class;
        for (keys %args_from) {
            my $method = $self->can("set_$_")
                or croak "unknown parameter $_ passed to new";
            $method->($self, $args_from{$_});
        }

        my $ident = ident $self;
        $client_of{ $ident } = SOAP::WSDL::Client->new();
        $self->wsdlinit() if ($wsdl_of{ $ident });
        return $self;
    }
}

sub set_proxy {
    my $self = shift;
    return $self->get_client()->set_proxy(@_);
}

sub get_proxy {
    my $self = shift;
    return $self->get_client()->get_proxy();
}

sub proxy {
    my $self = shift;
    if (@_) {
        return $self->set_proxy(@_);
    }
    return $self->get_proxy();
}

sub wsdlinit {
    my ($self, %opt) = @_;
    my $ident = ident $self;

    my $lwp = LWP::UserAgent->new(
        $keep_alive_of{ $ident }
        ? (keep_alive => 1)
        : ()
    );
    $lwp->agent(qq[SOAP::WSDL $VERSION]);
    my $response = $lwp->get( $wsdl_of{ $ident } );
    croak $response->message() if ($response->code != 200);

    my $parser = SOAP::WSDL::Expat::WSDLParser->new();
    $parser->parse_string( $response->content() );

    my $wsdl_definitions = $parser->get_data();

    # sanity checks
    my $types = $wsdl_definitions->first_types()
        or croak "unable to extract schema from WSDL";
    my $ns = $wsdl_definitions->get_xmlns();

    # setup lookup variables
    $definitions_of{ $ident }  = $wsdl_definitions;
    $serialize_options_of{ $ident } = {
        autotype  => 0,
        typelib   => $types,
        namespace => $ns,
    };

    $servicename_of{ $ident } = $opt{servicename} if $opt{servicename};
    $portname_of{ $ident } = $opt{portname} if $opt{portname};

    $self->_wsdl_init_methods();

    # pass-through keep_alive if we need it...
    $self->get_client()->set_proxy(
        $port_of{ $ident }->first_address()->get_location(),
        $keep_alive_of{ $ident } ? (keep_alive => 1) : (),
    );

    return $self;
} ## end sub wsdlinit

sub _wsdl_get_service :PRIVATE {
    my $ident = ident shift;
    my $wsdl = $definitions_of{ $ident };
    return $service_of{ $ident } = $servicename_of{ $ident }
        ? $wsdl->find_service( $wsdl->get_targetNamespace() , $servicename_of{ $ident } ) 
        : ( $service_of{ $ident } = $wsdl->get_service()->[ 0 ] );
} ## end sub _wsdl_get_service

sub _wsdl_get_port :PRIVATE  {
    my $ident = ident shift;
    my $wsdl = $definitions_of{ $ident };
    my $ns   = $wsdl->get_targetNamespace();
    return $port_of{ $ident } = $portname_of{ $ident }
        ? $service_of{ $ident }->get_port( $ns, $portname_of{ $ident } )->[ 0 ]
        : ( $port_of{ $ident } = $service_of{ $ident }->get_port()->[ 0 ] );
}

sub _wsdl_get_binding :PRIVATE {
    my $self = shift;
    my $ident = ident $self;
    my $wsdl = $definitions_of{ $ident };
    my $port = $self->_wsdl_get_port();
    $binding_of{ $ident } = $wsdl->find_binding( $port->expand( $port->get_binding() ) )
        or croak "no binding found for ", $port->get_binding();
    return $binding_of{ $ident };
}

sub _wsdl_get_portType :PRIVATE {
    my $self    = shift;
    my $ident   = ident $self;
    my $wsdl    = $definitions_of{ $ident };
    my $binding = $self->_wsdl_get_binding();
    $porttype_of{ $ident } = $wsdl->find_portType( $binding->expand( $binding->get_type() ) )
        or croak "cannot find portType for " . $binding->get_type();
    return $porttype_of{ $ident };
}

sub _wsdl_init_methods :PRIVATE {
    my $self = shift;
    my $ident = ident $self;
    my $wsdl = $definitions_of{ $ident };
    my $ns   = $wsdl->get_targetNamespace();

    # get bindings, portType, message, part(s) - use private methods for clear separation...
    $self->_wsdl_get_service();
    $self->_wsdl_get_portType();

    $method_info_of{ $ident } = {};

    foreach my $binding_operation (@{ $binding_of{ $ident }->get_operation() })
    {
        my $method = {};

        # get SOAP Action
        # SOAP-Action is a required HTTP Header, so we need to look it up...
        # There must be a soapAction uri - or the WSDL is invalid (and
        # it's not us to prove that...)
        my $soap_binding_operation = $binding_operation->get_operation()->[0];
        $method->{ soap_action } = $soap_binding_operation->get_soapAction();

        # get parts
        # 1. get operation from port
        my $operation = $porttype_of{ $ident }->find_operation( $ns,
            $binding_operation->get_name() );

        # 2. get input message name
        my ( $prefix, $localname ) = split /:/xm,
          $operation->first_input()->get_message();

        # 3. get input message
        my $message = $wsdl->find_message( $ns, $localname )
          or croak "Message {$ns}$localname not found in WSDL definition";

        # Is body not required? So there must be one? Do we need the "if"?
        # if (
        my $body=$binding_operation->first_input()->first_body();
        # {
            if ($body->get_parts()) {
                $method->{ parts } = [];        # make sure it's empty
                my $message_part_ref = $message->get_part();
                for my $name ( split m{\s}xm , $body->get_parts() ) {
                    $name =~s{ \A [^:]+: }{}xm;  # throw away ns prefix
                    # could probably made more efficient, but our lists are
                    # usually quite short
                    push @{ $method->{ parts } },
                        grep { $_->get_name() eq $name } @{ $message_part_ref };
                }
            }
        # }
        # A body does not need to specify the parts of a messages.
        # Use all of the message's parts if it does not.
        $method->{ parts } ||= $message->get_part();

        # rpc / encoded methods may have a namespace specified.
        # look it up and set it...
        $method->{ namespace } = $binding_operation
            ? do {
                my $input = $binding_operation->first_input();
                $input ? $input->first_body()->get_namespace() : undef;
            }
            : undef;

        $method_info_of{ $ident }->{ $binding_operation->get_name() } = $method;
    }

    return $method_info_of{ $ident };
}

# on_action is a no-op and just here for compatibility reasons.
# It returns the first parameter to allow method chaining.
sub on_action { return shift }

sub call {
    my ($self, $method, @data_from) = @_;
    my $ident = ${ $self };

    my ($data, $header) = ref $data_from[0]
      ? ($data_from[0], $data_from[1] )
      : (@data_from>1)
          ? ( { @data_from }, undef )
          : ( $data_from[0], undef );

    $self->wsdlinit() if not ($definitions_of{ $ident });
    $self->_wsdl_init_methods() if not ($method_info_of{ $ident });

    my $client = $client_of{ $ident };

    $client->set_no_dispatch( $no_dispatch_of{ $ident } );
    $client->set_outputxml( $outputxml_of{ $ident } ? 1 : 0 );

    # only load ::Deserializer::SOM if we really need to deserialize to SOM.
    # maybe we should introduce something like $output{ $ident } with a fixed
    # set of values - m{^(TREE|HASH|XML|SOM)$}xms ?
    if ( ( ! $outputtree_of{ $ident } )
      && ( ! $outputhash_of{ $ident } )
      && ( ! $outputxml_of{ $ident } )
      && ( ! $no_dispatch_of{ $ident } ) ) {
        require SOAP::WSDL::Deserializer::SOM;
        $client->set_deserializer( SOAP::WSDL::Deserializer::SOM->new() );
    }

    my $method_info = $method_info_of{ $ident }->{ $method };

    # TODO serialize both header and body, not only header
    my (@response) = (blessed $data)
        ? $client->call( {
            operation => $method,
            soap_action => $method_info->{ soap_action },
          }, $data )
        : do {
            my $content = q{};
            # TODO support RPC-encoding: Top-Level element + namespace...
            foreach my $part ( @{ $method_info->{ parts } } ) {

                $content .= $part->serialize( $method, $data,
                  {
                    %{ $serialize_options_of{ $ident } }
                  }  );
            }
            $client->call(
                {
                    operation => $method,
                    soap_action => $method_info->{ soap_action }
                },
                # absolutely stupid, but we need a reference which
                # serializes to XML on stringification...
                SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType->new({
                    value => $content
                }),
                SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType->new({
                    value => $header
                })
            );
        };

    return if not @response;    # nothing to do for one-ways
    return wantarray ? @response : $response[0];
}
1;

__END__

=pod

=head1 NAME

SOAP::WSDL - SOAP with WSDL support

=head1 NOTICE

This module is B<not> recommended for new application development.
Please use L<XML::Compile::SOAP> or L<SOAP::Lite> instead if possible.

This module has a large number of known bugs and is not being actively developed.
This 3.0 release is intended to update the module to pass tests on newer Perls.
This is a service to existing applications already dependent on this module.

=head1 SYNOPSIS

 my $soap = SOAP::WSDL->new(
    wsdl => 'file://bla.wsdl',
 );

 my $result = $soap->call('MyMethod', %data);

=head1 DESCRIPTION

For creating Perl classes instrumenting a web service with a WSDL definition,
read L<SOAP::WSDL::Manual>.

For using an interpreting (thus slow and somewhat troublesome) WSDL based
SOAP client, which mimics L<SOAP::Lite|SOAP::Lite>'s API, read on.

Creating Interface classes is the recommended usage.

Did I say you should create interface classes following the steps in
L<SOAP::WSDL::Manual>?

If you're migrating from earlier versions of SOAP::WSDL, you should read the
MIGRATING documentation.

The stuff below is for users of the 1.2x SOAP::WSDL series. All others,
please refer to L<SOAP::WSDL::Manual>

SOAP::WSDL provides easy access to Web Services with WSDL descriptions.

The WSDL is parsed and stored in memory.

Your data is serialized according to the rules in the WSDL.

The only transport mechanisms currently supported are http and https.

=head1 METHODS

=head2 new

Constructor. All parameters passed are passed to the corresponding methods.

=head2 call

Performs a SOAP call. The result is either an object tree (with outputtree),
a hash reference (with outputhash), plain XML (with outputxml) or a SOAP::SOM
object (with neither of the above set).

call() can be called in different ways:

=over

=item * Old-style idiom

 my $result = $soap->call('method', %data);

Does not support SOAP header data.

=item * New-style idiom

 my $result = $soap->call('method', $body_ref, $header_ref );

Does support SOAP header data. $body_ref and $header ref may either be
hash refs or SOAP::WSDL::XSD::Typelib::* derived objects.

Result headers are accessible via the result SOAP::SOM object.

If outputtree or outputhash are set, you may also use the following to
access response header data:

 my ($body, $header) = $soap->call('method', $body_ref, $header_ref );

=back

=head2 wsdlinit

Reads the WSDL file and initializes SOAP::WSDL for working with it.

Is called automatically from call() if not called directly before.

 servicename
 portname
 call

You may set servicename and portname by passing them as attributes to
wsdlinit:

 $soap->wsdlinit(
    servicename => 'MyService',
    portname => 'MyPort',
 );

=head1 CONFIGURATION METHODS

=head2 outputtree

When outputtree is set, SOAP::WSDL will return an object tree instead of a
SOAP::SOM object.

You have to specify a class_resolver for this to work. See
L<class_resolver|class_resolver>

=head2 class_resolver

Set the class resolver class (or object).

Class resolvers must implement the method get_class which has to return the
name of the class name for deserializing a XML node at the current XPath
location.

Class resolvers are typically generated by using the generate_typemap method
of a SOAP::WSDL::Generator subclass.

Example:

XML structure (SOAP body content):

 <Person>
    <Name>Smith</Name>
    <FirstName>John</FirstName>
 </Person>

Class resolver

 package MyResolver;
 my %typemap = (
    'Person' => 'MyPersonClass',
    'Person/Name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    'Person/FirstName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
 );

 sub get_class { return $typemap{ $_[1] } };
 1;

You'll need a MyPersonClass module in your search path for this to work - see
SOAP::WSDL::XSD::ComplexType on how to build / generate one.

=head2 servicename

 $soap->servicename('Name');

Sets the service to operate on. If no service is set via servicename, the
first service found is used.

Returns the soap object, so you can chain calls like

 $soap->servicename->('Name')->portname('Port');

=head2 portname

 $soap->portname('Name');

Sets the port to operate on. If no port is set via portname, the
first port found is used.

Returns the soap object, so you can chain calls like

 $soap->portname('Port')->call('MyMethod', %data);

=head2 no_dispatch

When set, call() returns the plain request XML instead of dispatching the
SOAP call to the SOAP service. Handy for testing/debugging.

=head1 ACCESS TO SOAP::WSDL's internals

=head2 get_client / set_client

Returns the SOAP client implementation used (normally a SOAP::WSDL::Client
object).

=head1 EXAMPLES

See the examples/ directory.

=head1 Differences to previous versions

=over

=item * WSDL handling

SOAP::WSDL 2 is a complete rewrite. While SOAP::WSDL 1.x attempted to
process the WSDL file on the fly by using XPath queries, SOAP:WSDL 2 uses a
Expat handler for parsing the WSDL and building up a object tree representing
it's content.

The object tree has two main functions: It knows how to serialize data passed
as hash ref, and how to render the WSDL elements found into perl classes.

Yup you're right; there's a builtin code generation facility. Read
L<SOAP::WSDL::Manual> for using it.

=item * no_dispatch

call() with no_dispatch set to true now returns the complete SOAP request
envelope, not only the body's content.

=item * outputxml

call() with outputxml set to true now returns the complete SOAP response
envelope, not only the body's content.

=item * servicename/portname

Both servicename and portname can only be called B<after> calling wsdlinit().

You may pass the servicename and portname as attributes to wsdlinit, though.

=back

=head1 Differences to previous versions

The following functionality is no longer supported:

=head2 Operation overloading

The SOAP standard allows operation overloading - that is, you may specify
SOAP operations with more than one message. The client/server than can
choose which message to send. This SOAP feature is usually used similar
to the use of methods with different argument lists in C++.

Operation overloading is no longer supported. The WS-I Basic profile does
not operation overloading. The same functionality as operation overloading
can be obtained by using a choice declaration in the XML Schema.

=head2 readable

Readable has no effect any more. If you need readable debug output, copy the
SOAP message to your favorite XML editor and run the source format command.
Outputting readable XML requires lots of programming for little use: The
resulting XMl is still quite unreadable.

=head2 on_action

Setting on_action is not required any more, the appropriate value is
automatically taken from the WSDL. on_action is a no-op, and is just here
for compatibility issues.

=head1 Differences to SOAP::Lite

=head2 readable

readable is a no-op in SOAP::WSDL. Actually, the XML output from SOAP::Lite
is hardly readable, either with readable switched on.

If you need readable XML messages, I suggest using your favorite XML editor
for displaying and formatting.

=head2 Message style/encoding

While SOAP::Lite supports rpc/encoded style/encoding only, SOAP::WSDL currently
supports document/literal style/encoding.

=head2 autotype / type information

SOAP::Lite defaults to transmitting XML type information by default, where
SOAP::WSDL defaults to leaving it out.

autotype(1) might even be broken in SOAP::WSDL - it's not well-tested, yet.

=head2 Output formats

In contrast to SOAP::Lite, SOAP::WSDL supports the following output formats:

=over

=item * SOAP::SOM objects.

This is the default. SOAP::Lite is required for outputting SOAP::SOM objects.

=item * Object trees.

This is the recommended output format.
You need a class resolver (typemap) for outputting object trees.
See L<class_resolver|class_resolver> above.

=item * Hash refs

This is for convenience: A single hash ref containing the content of the
SOAP body.

=item * xml

See below.

=back

=head2 outputxml

SOAP::Lite returns only the content of the SOAP body when outputxml is set
to true. SOAP::WSDL returns the complete XML response.

=head2 Auto-Dispatching

SOAP::WSDL does B<does not> support auto-dispatching.

This is on purpose: You may easily create interface classes by using
SOAP::WSDL::Client and implementing something like

 sub mySoapMethod {
     my $self = shift;
     $soap_wsdl_client->call( mySoapMethod, @_);
 }

You may even do this in a class factory - see L<wsdl2perl.pl> for creating
such interfaces.

=head2 Debugging / Tracing

While SOAP::Lite features a global tracing facility, SOAP::WSDL
allows one to switch tracing on/of on a per-object base.

This has to be done in the SOAP client used by SOAP::WSDL - see
L<get_client|get_client> for an example and L<SOAP::WSDL::Client> for
details.

=head1 BUGS AND LIMITATIONS

The bug tracker is at L<< https://rt.cpan.org/Dist/Display.html?Queue=SOAP-WSDL >>.

This module is in legacy maintenance mode.
Only show stopper bugs are being fixed, until/unless someone wishes to resume active development on it.
Scott Walters, C<scott@slowass.net> has obtained co-mainter from the CPAN admins for the purpose of applying existing fixes people have submit to 
the RT tracker, and to apply other fixes as needed to get the module to install and run on newer Perls.
Non show-stopper bugs reports without fixes will be added to this list of limitations.
Of course, fixes for these and other bugs are welcome.
Scott does not get email from L<< rt.cpan.org >>, so please drop an email to him at C<< scott@slowass.net >> if you open a ticket there.

=over

=item * Breaks the idiom C<< $package->can("SUPER::method") >> in your code

If you redefine C<< UNIVERSAL::can() >>, and someone tries to do C<< $package->can("SUPER::method") >>, it'll look at your packages C<@ISA>, not theirs.
This module does precicely that, by way of its dependency on C<Class::Std::Fast>.

=item * $obj == undef does not work in perl 5.8.6 and perl 5.8.7

Due to some strange behaviour in perl 5.8.6 and perl 5.8.7, stringification
overloading is not triggered during comparison with undef.

While this is probably harmless in most cases, it's important to know that
you need to do

 defined( $obj->get_value() )

to check for undef values in simpleType objects.

=item * perl 5.8.0 or higher required

SOAP::WSDL needs perl 5.8.0 or higher. This is due to a bug in perls
before - see http://aspn.activestate.com/ASPN/Mail/Message/perl5-porters/929746 for details.

=item * Apache SOAP datatypes are not supported

You can't use SOAP::WSDL with Apache SOAP datatypes like map.

=item * Incomplete XML Schema definitions support

This section describes the limitations of SOAP::WSDL, that is the interpreting
SOAP client. For limitations of L<wsdl2perl.pl|wsdl2perl.pl> generated
SOAP clients, see L<SOAP::WSDL::Manual::XSD>.

XML Schema attribute definitions are not supported in interpreting mode.

The following XML Schema definitions varieties are not supported in
interpreting mod:

 group
 simpleContent

The following XML Schema definition content model is only partially
supported in interpreting mode:

 complexContent - only restriction variety supported

See L<SOAP::WSDL::Manual::XSD> for details.

=item * Serialization of hash refs does not work for ambiguous values

If you have list elements with multiple occurrences allowed, SOAP::WSDL
has no means of finding out which variant you meant.

Passing in item => [1,2,3] could serialize to

 <item>1 2</item><item>3</item>
 <item>1</item><item>2 3</item>

Ambiguous data can be avoided by providing data as objects.

=item * XML Schema facets

Almost no XML schema facets are implemented. The only facets
currently implemented are:

 fixed
 default

The following facets have no influence:

 minLength
 maxLength
 minInclusive
 maxInclusive
 minExclusive
 maxExclusive
 pattern
 enumeration

=back

=head1 SEE ALSO

=head2 Related projects

=over

=item * L<SOAP::Lite|SOAP::Lite>

Full featured SOAP-library, little WSDL support. Supports rpc-encoded style
only. Many protocols supported.

=item * L<XML::Compile::SOAP|XML::Compile::SOAP>

Creates parser/generator functions for SOAP messages. Includes SOAP Client
and Server implementations. Can validate XML messages.

You might want to give it a try, especially if you need to adhere very
closely to the XML Schema / WSDL specs.

=back

=head2 Sources of documentation

=over

=item * SOAP::WSDL homepage at sourceforge.net

L<http://soap-wsdl.sourceforge.net>

=item * SOAP::WSDL forum at CPAN::Forum

L<http://www.cpanforum.com/dist/SOAP-WSDL>

=back

=head1 ACKNOWLEDGMENTS

Scott Walters wrote:

This code incorporates fixes contributed by C<< NORDIC@cpan.org >>, C<< dam@cpan.org >>, C<< sven.schober@uni-ulm.de >>, myself, and others.

Martin Kutter wrote:

There are many people out there who fostered SOAP::WSDL's development.
I would like to thank them all (and apologize to all those I have forgotten).

Giovanni S. Fois wrote a improved version of SOAP::WSDL (which eventually
became v1.23)

David Bussenschutt, Damian A. Martinez Gelabert, Dennis S. Hennen, Dan Horne,
Peter Orvos, Mark Overmeer, Jon Robens, Isidro Vila Verde and Glenn Wood
(in alphabetical order) spotted bugs and/or suggested improvements in
the 1.2x releases.

JT Justman and Noah Robin provided early feedback and bug reports for
the 2.xx pre-releases.

Adam Kennedy checked and suggested improvements on metadata and dependencies
in the 2.xx pre-releases.

Andreas 'ac0v' Specht constantly asked for better performance.

Matt S. Trout encouraged me "to get a non-dev-release out."

CPAN Testers provided most valuable (automated) feedback. Thanks a lot.

Numerous people sent me their real-world WSDL files and error reports for
testing. Thank you.

Noah Robin contributed lots of documentation fixes, and the mod_perl server,
and eventually joined SOAP::WSDL's development. Thanks.

Mark Overmeer wrote XML::Compile::SOAP - competition is good for business.

Paul Kulchenko and Byrne Reese wrote and maintained SOAP::Lite and
thus provided a base (and counterpart) for SOAP::WSDL.

=head1 LICENSE AND COPYRIGHT

Copyright 2004-2008 Martin Kutter.

This file is part of SOAP-WSDL. You may distribute/modify it under
the same terms as perl itself

=head1 AUTHOR

Scott Walters E<lt>scott@slowass.net<gt> 2014

Martin Kutter E<lt>martin.kutter fen-net.deE<gt> 2004-2008

=head1 REPOSITORY INFORMATION

    https://github.com/scrottie/SOAP-WSDL

=cut
