package OpenTracing::Implementation::DataDog::SpanContext;

=head1 NAME

OpenTracing::Implementation::DataDog::SpanContext - A DataDog Implementation

=cut

our $VERSION = 'v0.47.0';


=head1 SYNOPSIS

    use aliased OpenTracing::Implementation::DataDog::SpanContext;
    
    my $span_context = SpanContext->new(
        service_name  => "MyFancyService",
        service_type  => "web",
        resource_name => "/clients/{client_id}/contactdetails",
        environment   => 'staging',
        hostname      => 'web.01.host',
    );
    #
    # please do not add parameter values in the resource,
    # use tags instead, like:
    # $span->set_tag( client_id => $request->query_params('client_id') )

=cut

use Moo;
use MooX::Enumeration; # do needs to be the first eXtension
use MooX::Attribute::ENV;
use MooX::Should;

with 'OpenTracing::Role::SpanContext';

use OpenTracing::Implementation::DataDog::Utils qw/random_bigint/;

use Sub::Trigger::Lock;
use Types::Common::String qw/NonEmptyStr/;
use Types::Standard qw/InstanceOf Maybe/;



=head1 DESCRIPTION

This is a L<OpenTracing SpanContext|OpenTracing::Interface::SpanContext>
compliant implementation with DataDog specific extentions

=cut



=head1 EXTENDED ATTRIBUTES

=cut



=head2 C<trace_id>

DataDog requires this to be a unsigned 64-bit integer

=cut

has '+trace_id' => (
    is =>'ro',
    should => InstanceOf['Math::BigInt'],
    default => sub{ random_bigint() }
);



=head2 C<span_id>

DataDog requires this to be a unsigned 64-bit integer

=cut

has '+span_id' => (
    is =>'ro',
    should => InstanceOf['Math::BigInt'],
    default => sub{ random_bigint() }
);



=head1 DATADOG SPECIFIC ATTRIBUTES

=cut



=head2 C<service_name>

A required C<NonEmptyString> where C<length <= 100>.

Defaults to the value of the C<DD_SERVICE_NAME> environment variable if set.

The service-name will usually be the name of the application and could easilly
be set by a intergration solution.

=cut

has service_name => (
    is              => 'ro',
    env_key         => [ 'DD_SERVICE', 'DD_SERVICE_NAME' ], # only DD_SERVICE!!
    required        => 1,
    should          => NonEmptyStr->where( 'length($_) <= 100' ),
    reader          => 'get_service_name',
    trigger         => Lock,
);



=head2 C<service_type>

An enumeration on C<web>, C<db>, C<cache>, and C<custom>, which is the default.

DataDog has four different service types to make it more easy to visualize the
data. See L<Service List at DataDog HQ|
https://docs.datadoghq.com/tracing/visualization/services_list/#services-types>

=cut

has service_type => (
    is              => 'ro',
    default         => 'custom',
    enum            => [qw/web db cache custom/],
    handles         => 2, # such that we have `service_type_is_...`
    reader          => 'get_service_type',
    trigger         => Lock,
);



=head2 C<resource_name>

A required C<NonEmptyString> where C<length <= 5000>.

Good candidates for resource names are URL paths or databasenames and or tables.

=cut

has resource_name => (
    is              => 'ro',
    should          => NonEmptyStr->where( 'length($_) <= 5000' ),
    required        => 1,
    reader          => 'get_resource_name',
    trigger         => Lock,
);



=head2 C<environment>

An optional C<NonEmptyString> where C<length <= 5000>.

=cut

has environment => (
    is              => 'ro',
    should          => Maybe[NonEmptyStr->where( 'length($_) <= 5000' )],
    required        => 0,
    env_key         => 'DD_ENV',
    reader          => 'get_environment',
    trigger         => Lock,
);



=head2 C<hostname>

An optional C<NonEmptyString> where C<length <= 5000>.

=cut

has hostname => (
    is              => 'ro',
    should          => Maybe[NonEmptyStr->where( 'length($_) <= 5000' )],
    required        => 0,
    env_key         => 'DD_HOSTNAME',
    reader          => 'get_hostname',
    trigger         => Lock,
);



=head2 C<version>

An optional C<NonEmptyString> where C<length <= 5000>.

=cut

has version => (
    is              => 'ro',
    should          => Maybe[NonEmptyStr->where( 'length($_) <= 5000' )],
    required        => 0,
    env_key         => 'DD_VERSION',
    reader          => 'get_version',
    trigger         => Lock,
);



=head1 CONSTRUCTORS

=head2 Warning:

Constructors are not to be used outside an implementation, they are not part of
the L<OpenTracing API|OpenTracing::Interface>.

Only an integration solution should be bothered creating a 'root context'.

=head2 new

    my $span_context = SpanContext->new(
        service_name  => "MyFancyService",
        resource_name => "/clients/{client_id}/contactdetails",
        baggage_items => { $key => $value, .. },
    );

Creates a new SpanContext object;



=head1 INSTANCE METHODS

Besides all methods available from the L<OpenTracing::Roles::SpanContext>, the
following are DataDog specific added methods.

=cut



=head2 C<service_type_is_web>

Returns a C<Bool> wether or not the L<service_type> is set to C<web>.

=head2 C<service_type_is_db>

Returns a C<Bool> wether or not the L<service_type> is set to C<db>.

=head2 C<service_type_is_cache>

Returns a C<Bool> wether or not the L<service_type> is set to C<cache>.

=head2 C<service_type_is_ciustom>

Returns a C<Bool> wether or not the L<service_type> is set to C<custom>.

=cut



=head1 CLONE METHODS

Since C<SpanContext> is supposed to be an in-mutable object, and there are some
occasions that DataDog settings need to added (i.e. a root span), there are a
few cloning methods provided:

=cut



=head2 C<with_service_name>

Creates a cloned object, with a new value for C<service_name>.

    $span_context_new = $root_span->with_service_name( 'MyAwesomeApp' );

=head3 Required Positional Parameter(s)

=over

=item C<service_name>

A C<NonEmptyString> where C<length <= 100>.

=back

=head3 Returns

A cloned C<DataDog::SpanContext>

=cut

sub with_service_name { $_[0]->clone_with( service_name => $_[1] ) }



=head2 C<with_service_type>

Creates a cloned object, with a new value for C<service_type>.

    $span_context_new = $root_span->with_service_type( 'cache' );

=head3 Required Positional Parameter(s)

=over

=item C<service_type>

An enumeration on C<web>, C<db>, C<cache>, and C<custom>

=back

=head3 Returns

A cloned C<DataDog::SpanContext>

=cut

sub with_service_type { $_[0]->clone_with( service_type => $_[1] ) }



=head2 C<with_resource_name>

Creates a cloned object, with a new value for C<resource_name>.

    $span_context_new = $root_span->with_resource_name( 'clients/?/index.cgi' );

=head3 Required Positional Parameter(s)

=over

=item C<resource_name>

A C<NonEmptyString> where C<length <= 5000>.

=back

=head3 Returns

A cloned C<DataDog::SpanContext>

=cut

sub with_resource_name { $_[0]->clone_with( resource_name => $_[1] ) }



=head2 C<with_environment>

Creates a cloned object, with a new value for C<environment>.

    $span_context_new = $root_span->with_environment( 'development' );

=head3 Required Positional Parameter(s)

=over

=item C<environment>

A C<NonEmptyString> where C<length <= 5000>.

=back

=head3 Returns

A cloned C<DataDog::SpanContext>

=cut

sub with_environment { $_[0]->clone_with( environment => $_[1] ) }



=head2 C<with_hostname>

Creates a cloned object, with a new value for C<hostname>.

    $span_context_new = $root_span->with_hostname( 'web.01.host' );

=head3 Required Positional Parameter(s)

=over

=item C<hostname>

A C<NonEmptyString> where C<length <= 5000>.

=back

=head3 Returns

A cloned C<DataDog::SpanContext>

=cut

sub with_hostname { $_[0]->clone_with( hostname => $_[1] ) }



=head2 C<with_version>

Creates a cloned object, with a new value for C<hostname>.

    $span_context_new = $root_span->with_version( 'v0.123.456' );

=head3 Required Positional Parameter(s)

=over

=item C<version>

A C<NonEmptyString> where C<length <= 5000>.

=back

=head3 Returns

A cloned C<DataDog::SpanContext>

=cut

sub with_version { $_[0]->clone_with( version => $_[1] ) }



=head1 ENVIRONMENT VARIABLES

For configuring DataDog Tracing there is support for the folllowing environment
variables:



=head2 C<DD_SERVICE_NAME>

The name of a set of processes that do the same job. Used for grouping stats for
your application.

B<default:> I<none>



=head2 C<DD_ENV>

Your application environment (for example, production, staging).

B<default:> I<none>



=head2 C<DD_HOSTNAME>

Manually set the hostname to use for metrics if autodetection fails, or when
running the Datadog Cluster Agent.



=head2 C<DD_VERSION>

Your application version (for example, 2.5, 202003181415, 1.3-alpha).

B<default:> I<none>



=head1 SEE ALSO

=over

=item L<OpenTracing::Implementation::DataDog>

Sending traces to DataDog using Agent.

=item L<OpenTracing::Role::SpanContext>

Role for OpenTracing Implementations.

=back



=head1 AUTHOR

Theo van Hoesel <tvanhoesel@perceptyx.com>



=head1 COPYRIGHT AND LICENSE

'OpenTracing::Implementation::DataDog'
is Copyright (C) 2019 .. 2021, Perceptyx Inc

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.


=cut

1;
