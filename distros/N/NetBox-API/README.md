# perl-NetBox-API
## NAME
**NetBox::API** - Perl interface to NetBox API
## DESCRIPTION
This module implements all operations (object(-s) retrievement, creation, modification and deletion) as described in NetBox API Overview.
## CAVEATS
- This module is written using `signatures` feature. As for me, it makes code clearer. However, it requires perl 5.10+.
All more or less modern OSes has much more newer perl included, so don't think it will be a problem.
## LIMITATIONS
Unlike REST, GraphQL mode has a bunch of limitations, which (in my opinion) makes it less convinient then REST. However, I have to admit, it works
faster, noticeably faster, then REST. So, about the limitations:
- GraphQL support is disabled in NetBox by default; to enable it, you have to set **GRAPHQL_ENABLED** option to `true` in NetBox configuration;
- in GraphQL mode only `retrieve()` method is implemented;
- custom fields can be used as filters only in **Netbox v4.4+**;
- custom fields can not be filtered out of response - all will be returned.
## SYNOPSIS
    use NetBox::API;

    my $netbox = NetBox::API->new(
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
## METHODS
### new(OPTIONS)
**NetBox::API** object constructor. Is used as follows:

    my $netbox = NetBox::API->new(
        'baseurl' => 'http://localhost:8001',
        'token'   => 'authorization+token',
        'mode'    => 'rest',
    );

Available options are:
- **baseurl** => STRING

NetBox instance base URL. Mandatory. Defaults to `http://localhost:8001`.
- **token** => STRING

Authorization token. Mandatory. Defaults to empty string.
- **mode** => 'rest' | 'graphql'

Can be either `rest` for REST interface (default) or `graphql` for GraphQL.
- **limit** => INTEGER

Objects count per REST API query. Affects `retrieve()` method only. Default is 250.
- **timeout** => INTEGER

Query timeout. If query is split to several subqueries (e.g. long retrieves), it affects single query
and all subqueries in total. Default value is 15 seconds.
- **sslcheck** => BOOLEAN

Perform SSL certificate check (`true`) or not. Default is to perform.
- **quiet** => BOOLEAN

Be quiet when set to `true` (which is default). Currently not implemented.
## retrieve(QUERY, { OPTIONS })
Retrieve an array of objects.

`QUERY` differs for REST and GraphQL modes: in REST mode it is a final part of URI without trailing '/'
(e.g. `tenancy/tenants` or `dcim/cables`) and in GraphQL mode is either `$OBJECT` or `$OBJECT_list`.

`OPTIONS` is a reference to a HASH of query arguments, e.g.:

    my @cables = $netbox->retrieve('dcim/cables', {
        'type'    => 'smf',
        'status'  => 'connected',
        'fields'  => [ qw(label created) ]
    });
    die $netbox->errmsg if $netbox->error;

Note a special `fields` argument, which is not a query argument, but a returned fields filter. It is mandatory
in GraphQL mode. In REST mode, if `fields` argument is omitted, all object's fields are returned. Only first
level fields can be specified.

In GraphQL mode a precrafted query can be passed to the method using `raw` argument. In this case `fields`
argument can be omitted:

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
### create(QUERY, [ OPTIONS ])
Create new object(-s). Is implemented in REST mode only. All mandatory object's properties has to be specified:

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
### update(QUERY, { OPTIONS })
Update existing object(-s). Is available only in REST mode. Expects specification of the field(-s) being modified only.
Can be called in two ways:

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

Returns either an array of updated objects on success or an empty array on error.
### replace(QUERY, [ OPTIONS ])
Similar to `update()`, but existing object is replaced with at a whole. Is implemented only in REST mode.
All mandatory properties has to be specified.
### delete(QUERY [, OPTIONS ])
Delete an existing object or several objects. Is implemented only in REST mode. Can be called in two ways, e.g. either:

    $netbox->delete('dcim/cables', [
        { 'id' => 10 },
        { 'id' => 11 },
        ...
    ]);

or

    $netbox->delete('dcim/cables/10');
    $netbox->delete('dcim/cables/11');
    ...

Always returns empty array.

First way requires `OPTIONS` - a reference to an array, containing a list of deletion arguments - to be set. It is preferred as
more universal then the second one since it allows to delete several objects in a single query.
### __call(METHOD, QUERY, OPTIONS)
Universal method making it all - all service methods barely wrappers around this one, which brings them all and binds 'em with a
different `METHOD` argument required, as described in NetBox REST API Overview:

- `retrieve()` - **GET**;
- `create()` - **POST**;
- `update()` - **PUT**;
- `replace()` - **PUT**;
- `delete()` - **DELETE**

`QUERY` and `OPTIONS` are the same, provided to a service methods.

It's unlikely you'll ever want to use this method directly - it is just inconvenient, although not forbidden.
## ERROR HANDLING
### error()
Takes no arguments. Returns `false` if **NetBox::API** object is defined and `error` flag is not set and `true` otherwise.
### errno()
Takes no arguments. Returns error code. 0 is returned for no error.
### errmsg()
Takes no arguments. Returns error message. Empty string ('') is returned for no error.
### __seterror(ERROR [, LIST])
Set or reset (when called with no arguments) error flag, error code and error message. It is called implicitly when any service
method is called and should not be called explicitly in any circumstances.
## CHANGELOG
### v0.1.3 - 2025-09-26
- minor CPAN issue fixes. Again.
### v0.1.1 - 2025-09-26
- minor CPAN issue fixes.
### v0.1.0 - 2025-09-25
- initial public release.
### TODO
- make queries in REST and GraphQL modes interchangeable;
- implement queries generation in GraphQL mode.
### LINKS
- [NetBox Documentation](https://netboxlabs.com/docs/netbox/);
- [NetBox Source](https://github.com/netbox-community/netbox/);
- [NetBox REST API Overview](https://netboxlabs.com/docs/netbox/integrations/rest-api/);
- [NetBox GraphQL API Overview](https://netboxlabs.com/docs/netbox/integrations/graphql-api/)
