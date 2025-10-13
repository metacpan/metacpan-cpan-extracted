package NetBox::Client;

=pod #{{{ main documentation section

=head1 NAME

B<NetBox::Client> - perl5 interface to NetBox API

=head1 DESCRIPTION

This module implements all operations (object(-s) retrievement, creation,
modification and deletion) as described in NetBox API Overview.

=head1 CAVEATS

=over 4                                                                                                                             
                                                                                                                                    
=item This module is written using `signatures` feature. As for me,
it makes code clearer. However, it requires perl 5.10+. All
more or less modern OSes has much more newer perl included, so
don't think it will be a problem.

=back

=head1 LIMITATIONS

Unlike REST, GraphQL mode has a bunch of limitations, which (in my opinion)
makes it less convinient then REST. However, I have to admit, it works faster,
noticeably faster, then REST. So, about the limitations:

=over 4

=item GraphQL support is disabled in NetBox by default; to enable it, you have to
set `GRAPHQL_ENABLED` option to `true` in NetBox configuration file; E<10> E<8>

=item GraphQL is intended for data retrievement only; E<10> E<8>

=item Custom fields can be used as filters in NetBox **v4.4+** only! E<10> E<8>

=item It is possible either not to retrieve custom fields at all or to retrieve all
of them - there is no way to retrieve only part of them. At least in current
NetBox version. E<10> E<8>

=back

=head1 B<SYNOPSIS>

    use NetBox::Client;
    
    my $netbox = NetBox::Client->new(
        'baseurl' => 'https://localhost:8001',
        'token'   => 'authorization+token',
        'method'  => 'rest'
    );

    my @cables = $netbox->retrieve('dcim/cables', {
        'type'    => 'smf',
        'status'  => 'connected',
        'fields'  => [ qw(label created) ]
    });
    unless ($netbox->error) {
        foreach my $cable (@cables) {
            printf "Cable %s installed %s\n",
                $cable->{'label'},
                $cable->{'created'};
        }
    }

    $netbox->delete('dcim/cables', [
        { 'id' => 10 },
        { 'id' => 11 }
    ]);
    die $netbox->errmsg if $netbox->error;

=cut #}}}

use strict;
use warnings 'FATAL' => 'all';
no warnings qw(experimental::signatures);
use feature qw(signatures);
use utf8;
use boolean qw(:all);
use parent qw(NetBox::Client::Common);

use Class::Load qw(:all);
use Class::XSAccessor {
    'accessors' => [ qw(errno errmsg) ],
    'getters' =>   [ qw(baseurl headers limit mode sslcheck timeout token ua) ],
};
use Data::Dumper;
use JSON;
use Encode;
use HTTP::Request;
use LWP::UserAgent;
use URI::Escape;

use constant {
    #{{{
    DEFAULTS => {
        'baseurl'  => 'http://localhost:8001',
        'mode'     => 'rest',
        'token'    => '',
        'limit'    => 250,
        'timeout'  => 15,
        'sslcheck' => 1,
        'quiet'    => 1
    },
    MODULES        => { 'rest' => 'REST', 'graphql' => 'GraphQL' },
}; #}}}

BEGIN {
    #{{{
    require Exporter;
    our $CHECKED = {};
    our @ISA = qw(Exporter);
    our @EXPORT = qw();
    our @EXPORT_OK = qw();
    $Data::Dumper::Sortkeys = 1;
#   our %EXPORT_TAGS = (TAG1 => [ qw(1 2) ], TAG2 => [ qw(3 4) ], 'all' => [ qw(1 2 3 4) ] );
} #}}}

our $VERSION = $NetBox::Client::Common::VERSION;

=pod

=head1 B<METHODS>

=cut

sub new :prototype($%) ($class, %options) {
    #{{{

=pod #{{{ new() method description

=over 4                                                                                                                             
                                                                                                                                    
=item B<new(OPTIONS)>                                                                                                 
                                                                                                                                    
NetBox::Client object constructor. Is used as follows:
                                                                                                                                    
    my $netbox = NetBox::Client->new(
        'baseurl' => 'http://localhost:8001',
        'token'   => 'authorization+token',
        'mode'    => 'rest',
    );

Available options are:

=over 4

=item B<baseurl> => STRING

NetBox instance base URL. Mandatory. Defaults to 'http://localhost:8001'.

=item B<token> => STRING

Authorization token. Mandatory. Defaults to empty string.

=item B<mode> => 'rest' | 'graphql'

Can be either `rest` for REST interface (default) or `graphql` for GraphQL.

=item B<limit> => INTEGER

Objects count returned per single REST API query. Affects `retrieve()` method
in REST mode only.

=item B<timeout> => INTEGER

Query timeout. If query is split to several subqueries (e.g. long retrieves),
it affects single query and all subqueries in total. Default value is 15 seconds;

=item B<sslcheck> => BOOLEAN

Perform SSL certificate check (`true`) or not. Default is to perform.

=item B<quiet> => BOOLEAN

Be quiet when set to `true` (which is default). Currently not implemented.

=back

=cut #}}}

    my $self = bless {
        'errno'  => NetBox::Client::Common::E_OK->[0],
        'errmsg' => NetBox::Client::Common::E_OK->[1],
        'error'  => boolean::false,
    }, __PACKAGE__;
    foreach  my $key (keys %{(DEFAULTS)}) {
        $self->{$key} = defined($options{$key})
            ? $options{$key}
            : DEFAULTS->{$key};
    }
    $self->{'baseurl'} .= ($self->{'mode'} eq 'graphql')
        ? '/graphql/'
        : '/api';
    $self->{'headers'} = {
        'Accept'        => 'application/json',
        'Authorization' => sprintf('Token %s', $self->{'token'}),
        'Content-Type'  => 'application/json',
    };
    $self->{'ua'} = LWP::UserAgent->new(
        'protocols_allowed' => [ qw(http https) ],
        'ssl_opts'          => { 'verify_hostname' => $self->{'sslcheck'} },
        'timeout'           => $self->{'timeout'},
        'default_headers'   => HTTP::Headers->new(%{($self->{'headers'})}),
    );
    return $self;
} #}}}

sub retrieve :prototype($$$) ($self, $query, $vars = {}) {
    #{{{

=pod #{{{ retrieve() method description

=item B<retrieve(QUERY, { OPTIONS })>

Retrieve an array of objects.

`QUERY` differs for REST and GraphQL modes: in REST mode it is a final
part of URI without trailing '/' (e.g. 'tenancy/tenants' or 'dcim/cables')
and in GraphQL mode is either `$OBJECT` or `$OBJECT_list` as described in
NetBox GraphQL API Overview.

`OPTIONS` is a reference to a HASH of query arguments, e.g.:

    my @cables = $netbox->retrieve('dcim/cables', {
        'type'    => 'smf',
        'status'  => 'connected',
        'fields'  => [ qw(label created) ]
    });
    die $netbox->errmsg if $netbox->error;

Note a special `fields` argument, which is not a query argument, but a
returned fields filter. It is mandatory in GraphQL mode. In REST mode,
if `fields` argument is omitted, all object's fields are returned. Only
first level fields can be specified.

In GraphQL mode a precrafted query can be passed to the method using
`raw` argument. In this case `fields` argument can be omitted:

    my @cables = $netbox->retrieve('cable_list', { 'raw' => q[
        query cable_list {
            cable_list (filters: {
                type: TYPE_SMF_OS2,
                tenant: {
                    slug: { i_exact: "tenant_slug" }
                }
            }) {
                id
                tenant { name }
                description
                custom_fields
            }
        }
    ] });

=cut #}}}

    return $self->__call('GET', $query, $vars);
} #}}}

sub create :prototype($$$) ($self, $query, $vars = {}) {
    #{{{

=pod

=item B<create(QUERY, [ OPTIONS ])>

Create new object(-s). Is available in REST mode only. All mandatory
fields has to be specified:

    my @cables = $self->create('dcim/cables', [ {
        'status'          => 'connected',
        'type'            => 'cat5e',
        'a_terminations'  => [ {
            'object_type' => 'dcim.interface',
            'object_id'   => 10,
        } ],
        'b_terminations'  => [ {
            'object_type' => 'dcim.interface',
            'object_id'   => 11,
        } ],
    } ]);
    die $netbox->errmsg if $netbox->error;

Returns a list of created object(-s) on success.

=cut

    return $self->__call('POST', $query, $vars);
} #}}}

sub update :prototype($$$) ($self, $query, $vars = {}) {
    #{{{

=pod #{{{ update() method description

=item B<update(QUERY, { OPTIONS })>

Update existing object(-s). Is available in REST mode only. Expects
specification of the field(-s) being modified only. Can be called in
two ways:

    # Update single object per query
    my @cables = $netbox->update('dcim/cables/10', {
        'type'   => 'cat5e',
        'status' => 'connected'
    });
    die $netbox->errmsg if $netbox->error;

or

    # Update multiple objects per query
    my @cables = $netbox->update('dcim/cables', [
        { 'id' => 10, 'type' => 'cat5e', 'status' => 'connected' },
        { 'id' => 11, 'type' => 'cat5e', 'status' => 'connected' },
        ...
    ]);
    die $netbox->errmsg if $netbox->error;

Returns either an array of updated objects on success or an empty array
on error.

=cut #}}}

    return $self->__call('PATCH', $query, $vars);
} #}}}

sub replace :prototype($$$) ($self, $query, $vars = {}) {
    #{{{

=pod #{{{ replace() method description

=item B<replace(QUERY, [ OPTIONS ])>

Similar to `update()`, but existing object is replaced with at a whole.
Is available in REST mode only. All mandatory fields has to be specified.

=cut #}}}

    return $self->__call('PUT', $query, $vars);
} #}}}

sub delete :prototype($$$) ($self, $query, $vars = {}) {
    #{{{

=pod #{{{ delete() method description

=item B<delete(QUERY [, OPTIONS ])>

Delete an existing object or several objects. Is available in REST mode only.
Can be called in two ways, e.g. either:

    $netbox->delete('dcim/cables', [
        { 'id' => 10 },
        { 'id' => 11 },
        ...
    ]);

or

    $netbox->delete('dcim/cables/10');
    $netbox->delete('dcim/cables/11');
    ...

Always returns an empty array.

First way requires `OPTIONS` - a reference to an array, containing a list of
deletion arguments - to be set. It is preferred as more universal then the
second one since it allows to delete several objects in a single query.

=cut #}}}

    return $self->__call('DELETE', $query, $vars);
} #}}}

sub __call :prototype($$$$) ($self, $method, $query, $vars = {}) {
    #{{{

=pod #{{{ __call() method description

=item B<__call(METHOD, QUERY, OPTIONS)>

Universal method making it all - all service methods are barely wrappers around
this one, which brings them all and binds 'em with a different `METHOD`
argument required, as described in NetBox REST API Overview:

=over 4

=item retrieve() - `GET`;

=item create() - `POST`;

=item replace() - `PUT`;

=item update() - `PATCH`;

=item delete() - `DELETE`;

=back

`QUERY` and `OPTIONS` are the same, provided to a service methods.

It's unlikely you'll ever want to use this method directly - it is just
inconvenient, although not forbidden.

=back

=cut #}}}

    $self->__seterror();
    my $class = sprintf '%s::%s', __PACKAGE__, MODULES->{$self->mode};
    unless (is_class_loaded $class) {
        unless (load_class $class) {
            $self->__seterror(NetBox::Client::Common::E_NOCLASS, $class);
            return qw();
        }
    }
    unless ($class->can($method)) {
        $self->__seterror(NetBox::Client::Common::E_NOMETHOD, $class, $method);
        return qw();
    }
    return $class->__call($self, $method, $query, $vars);
} #}}}

sub error :prototype($) ($self) {
    #{{{

=pod #{{{ error() method description

=head1 ERROR HANDLING

=over 4

=item B<error()>

Takes no arguments. Returns `false` if NetBox::Client object is
defined and `error` flag is not set and `true` otherwise.

=item B<errno()>

Takes no arguments. Returns error code. `0` is returned for no error.

=item B<errmsg()>

Takes no arguments. Returns error message. Empty string (`''`) is
returned for no error.

=cut #}}}

    return (defined $self and isFalse $self->{'error'})
        ? boolean::false
        : boolean::true;
} #}}}

sub __seterror :prototype($$@) ($self, $error = NetBox::Client::Common::E_OK, @list) {
    #{{{

=pod

=item B<__seterror(ERROR [, LIST])>

Set or reset (when called with no arguments) error flag, error code and error
message. It is called implicitly when any service method is called and should
not be called explicitly in any circumstances. 

=back

=cut

    $self->{'error'} = ($error->[0] == NetBox::Client::Common::E_OK->[0])
        ? boolean::false
        : boolean::true;
    $self->errno($error->[0]);
    $self->errmsg(@list ? sprintf($error->[1], @list) : $error->[1]);
} #}}}

sub DESTROY {}

1;

=pod

=head1 B<AUTHORS>

=over 4

=item Volodymyr Pidgornyi, vpE<lt>atE<gt>dtel-ix.net;

=back

=head1 B<CHANGELOG>

=head3 v0.1.5 - 2025-10-08

=over 4

=item renamed module to NetBox::Client to match CPAN naming conventions.

=back

=head3 v0.1.4

=over 4

=item LICENSE added;

=item automation issues fixes;

=item README.md is now generated from module POD;

=item RPM spec-file fixes.

=back

=head3 v0.1.3

=over 4

=item CPAN compatibility fixes. Again.

=back

=head3 v0.1.1

=over 4

=item CPAN compatibility fixes.

=back

=head3 v0.1.0

=over 4

=item Initial public release.

=back

=head1 B<TODO>

=over 4                                                                                                                             

=item *

Make queries in REST and GraphQL modes interchangeable.

=back

=head1 B<LINKS>

=over 4

=item L<NetBox Documentation|https://netboxlabs.com/docs/netbox/>;

=item L<NetBox Source|https://github.com/netbox-community/netbox>;

=item L<NetBox REST API Overview|https://netboxlabs.com/docs/netbox/integrations/rest-api/>;

=item L<NetBox GraphQL API Overview|https://netboxlabs.com/docs/netbox/integrations/graphql-api/>;

=back

=cut
