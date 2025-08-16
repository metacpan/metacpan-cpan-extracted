# NAME

Net::Respite::Base - base class for Respite related modules that can be used from a server or commandline

# SYNOPSIS

    package Foo;
    use base qw(Net::Respite::Base);
    my $meta = {lib_dirs => 1, dispatch_type => 'cache'};
    sub api_meta { $meta }

    package Foo::Bar;
    sub somecall__meta { {desc => 'A method'} }
    sub somecall {
        my ($self, $args) = @_;
        return {foo => 1};
    }

    my $f = Foo->new;
    my $data = $f->bar_somecall;


    #-----------------#

    package Foo;

    use strict;
    use warnings;
    use base qw(Net::Respite::Base);

    # sub api_meta { {} }  # optional configuration
    sub api_meta {
        return shift->{'api_meta'} ||= { # vtable cached here
            methods => {
                foo => 'bar', # alias a method
                baz => sub { }, # custom
            },
            namespaces => {
                foo_child => 1,
                bar_child => 1,
            },
            lib_dirs => {
                $dir => 1, # load all .pm files as namespaces
            },
        };
    }

    sub foo__meta { {} }
    sub foo {
        my ($self, $args) = @_;
        $self->validate_args($args);

        return {...};
    }

    my $obj = Foo->new;
    $obj->run_method("foo", $args);
    # will do logging and utf8 munging - used by Net::Respite::Server or Net::Respite::CommandLine

    $obj->foo($args); # no logging or utf8 munging


    ###----------------------------------------------------------------###

    use Net::Respite::Base;
    my $obj = Net::Respite::Base->new({
        api_meta => {
            methods => {
                foo => 'bar',
            },
            namespaces => {
                Foo => {},
            },
        },
    });

# Respite\_META

The module can specify a api\_meta override, or a api\_meta hashref
can be passed to Net::Respite::Base->new.  The following keys are honored
from api\_meta.

- methods

    Can be a hard coded list of supported methods.

        methods => {
            foo => 'bar',
            fii => sub { return {data => 'some data'} },
        },

- namespaces

    Hard coded list of method namespaces that will be used to map methods
    to packages spaces.

        namespaces => {
            customer    => '__',
            package     => '__',
        },

    A module name will be generated from the namespace.  The the methods
    reside in a different location, it is possible to pass along the package.

        namespaces => {
            customer => {
                match => '__',
                package => 'SomeSpace::Customer',
            },
        },

    Methods are looked for in this namespace package space.  Method names
    used in the api must either begin with a \_\_ (\_\_foo\_method), and/or
    they must have a corresponding \_\_meta entry (foo\_method\_\_meta).  This
    allows for non-Respite methods to remain non-Respite easily.  Additionally you
    can use the restrict method call to narrow this down even farther.

- lib\_dirs

    Dynamic directory of method namespaces.  Items in lib\_dirs will be used
    for a path search that will populate a namespace entry.

        lib_dirs => {
            "$config::config{'rootdir_server'}/api_lib" => 1,
        },

    Depending upon the path chosen, it may be necessary to supply a pkg\_prefix.

        lib_dirs => {
            "$config::config{'rootdir_server'}/lib/YAR" => {
                 pkg_prefix => 'YAR',
            },
        },

    Alternately, it is possible to set lib\_dirs equal to "1" which will
    make it automatically follow the previous behavior.  Note though that
    additional looked up modules must be found relative to the location of
    the parent module (@INC is not used).

- utf8\_encoded

    Default false.  When false, data passed should be properly utf8
    decoded (or have no utf8 data at all).  When true, data passed is
    assumed to be utf8 encoded meaning that it will need to be decoded
    before calling json->encode.

    Additionally, the true value can be a hashref of methods that need
    this treatment.  This is useful if you know some of your methods have
    utf8 data, while others do not.

    (Note: Conversely when the non-json transport is finalized, it will
    need to call decode\_utf8 to make sure data is ready for the
    transport.)

- dispatch\_type

    Can be one of new, cache, or morph.  Default is new.  When "new"
    is selected, a new object will be created with each dispatch call and
    it will contain a reference to the parent in the key named "base".  When
    "cache" is selected, a cached object will be used - the object is cached
    inside of the base object.  When "morph is
    selected, rather than creating a new object, the base object is temporarily
    blessed into the new object class.

- enforce\_requires\_admin

    Default false.  If true, then validate\_args will honor the requires\_admin
    by calling require\_admin if it appears in the \_\_meta for the method.

- allow\_nested

    Allow for nested package inheritance.  The nested namespace package
    must provide its own api\_meta.

# METHOD NAME RESOLUTION

TODO - document how we go from an Respite method name to its
corresponding location.

Talk about builtins, methods overrides, namespaces, lib\_dirs, and
the \_\_ prefix and \_\_meta suffix.

# METHODS

This is an outdated list from the \_Respite.pm import.

- base

    When dispatch\_type is set to `new` or `cache`, this method will
    provide access to the parent dispatching to the sub namespace.

- base\_class

    If a child namespace is used directly, base\_class will be looked
    at when the `base` method is called to create a parent base object.

- validate\_args

    See [Net::Respite::Validate](https://metacpan.org/pod/Net%3A%3ARespite%3A%3AValidate)

- verify\_admin

    Uses Net::Respite::Client to call the emp\_auth service and verify a passed
    in token.

- api\_preload

    Called from Net::Respite::Server when a server is being started.  This
    method can be used to pre load all necessary modules to avoid
    a penalty later on.  Note that any overrides should likely
    call ->SUPER::api\_preload as well.

The following methods are normally set when called from Net::Respite::Server
or Net::Respite::CommandLine.  If Net::Respite::Base is used outside of these
mediums, then the corresponding $self->{'propertyname'} values must be set
during initialization in order to use these methods.  If namespaces
are used, the child class will typically fail back and look at the
\->base->method value if necessary.

- remote\_ip

    The IP on the client machine calling this service.  This is advisory.
    Net::Respite::Client will use cmdline for this value when called through
    Net::Respite::CommandLine on the remote box.

- remote\_user

    The user on the client machine calling this service.  This is advisory.

- transport

    Defaults to ''.  From Net::Respite::Server it defaults to `json` (Respite),
    `form` (Post variables), and `form-doc` (autodoc interface).  From
    Net::Respite::CommandLine it defaults to `cmdline`.  It is normal in web
    interfaces that this value should be set to `gui`.

- api\_ip

    The IP used to talk to the service when used as an Respite server.  It will
    be cmdline when called from Net::Respite::CommandLine.

- api\_brand

    The brand used during api communication.  As a special case, if `is_local`
    is true, the $ENV{'PROV'} value can be used to specify the brand.

- admin\_user

    The authenticated administrative username.  Will only be set if
    require\_admin has been called.  Dies is not set.

- is\_server

    Set by Net::Respite::CommandLine and Net::Respite::Server.

- is\_local

    Only true if transport is cmdline or gui.  Essentially this is a "non-api"
    check.

- is\_authed

    True if admin\_user is set.  False if not (does not die).

- employee

    Will return an Employee object based on admin\_user.

# RESPONSE

Responses from called methods should typically be hashrefs of
data.  These responses will be encoded by the appropriate system.
Typically the encoding will be json (during Net::Respite::Server), but possibly
other forms (Perl, JSON, YAML, CSV) such as during Net::Respite::CommandLine.

Methods can also return psgi style responses though this is typically more
rare.  (It allows for other encodings or page displays).

When a hashref is returned the following keys may also be returned to
give additional information to the transport layer:

- \_utf8\_encoded

    This flag signals that the data is already utf8 encoded meaning that if
    a JSON transport layer is used, the data will need to be first decoded before
    being passed to JSON->encode to avoid double encoding.  Typically, this
    should be done by setting utf8\_encoded in api\_meta - though the \_utf8\_encoded
    flag allows for one-off operations.

- \_extra\_headers

    This should be an arrayref of arrayrefs containing key/val pairs.  When used
    under Net::Respite::Server, these will be sent as additional http headers.  When using
    Net::Respite::Client, the headers can be seen in the 'headers' property of a response
    object (non-flat).

        sub __some_method {
            return {
                _extra_headers => [
                    ['Set-Cookie' => 'foo=bar'],
                    ['X-Some-Header' => 'someval'],
                ],
                normal_data_key => 'val',
            };
        }
