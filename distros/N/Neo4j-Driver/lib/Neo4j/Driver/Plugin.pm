use 5.010;
use strict;
use warnings;

package Neo4j::Driver::Plugin;
# ABSTRACT: Plug-in interface for Neo4j::Driver
$Neo4j::Driver::Plugin::VERSION = '0.41';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Plugin - Plug-in interface for Neo4j::Driver

=head1 VERSION

version 0.41

=head1 DESCRIPTION

This is the abstract base class for L<Neo4j::Driver> plug-ins.
All plug-ins must inherit from L<Neo4j::Driver::Plugin>
(or perform the role another way). For a description of the
required behaviour for plug-ins, see L</"METHODS"> below.

Plug-ins can be used to extend and customise L<Neo4j::Driver>
to a significant degree. Upon being loaded, a plug-in will be
asked to register event handlers with the driver. Handlers
are references to custom subroutines defined by the plug-in.
They will be invoked when the event they were registered for
is triggered. Events triggered by the driver are specified in
L</"EVENTS"> below. Plug-ins can also define custom events.

I<The plug-in interface as described in this document is available
since version 0.34.>

=head1 SYNPOSIS

 package Local::MyProxyPlugin;
 use parent 'Neo4j::Driver::Plugin';
 
 sub new { bless {}, shift }
 
 sub register {
   my ($self, $events) = @_;
   $events->add_handler( http_adapter_factory => sub {
     my ($continue, $driver) = @_;
     
     # Get and modify the default adapter
     # (currently Neo4j::Driver::Net::HTTP::LWP)
     my $adapter = $continue->();
     $adapter->ua->proxy('http', 'http://192.0.2.2:3128/');
     return $adapter;
   });
 }
 
 
 package main;
 use Neo4j::Driver 0.34;
 use Local::MyProxyPlugin;
 
 $driver = Neo4j::Driver->new();
 $driver->plugin( Local::MyProxyPlugin->new );

=head1 WARNING: EXPERIMENTAL

The design of the plug-in API is not finalised.
You should probably let me know if you already are writing
plug-ins, so that I can try to accommodate your use case
and give you advance notice of changes.

B<The entire plug-in API is currently experimental.>

The driver's C<plugin()> method is
L<experimental|Neo4j::Driver/"Plug-in modules"> as well.

I'm grateful for any feedback you I<(yes, you!)> might have on
this driver's plug-in API. Please open a GitHub issue or get in
touch via email (make sure you mention Neo4j in the subject to
beat the spam filters).

=head1 EVENTS

This version of L<Neo4j::Driver> can trigger the following events.
Future versions may introduce new events or remove existing ones.

=over

=item error

I<Since version 0.36.>

 $events->add_handler(
   error => sub {
     my ($continue, $error) = @_;
     $ui->show_alert_box( $error->as_string );
     $continue->();  # die
   },
 );

This event will be triggered when the driver encounters a Neo4j
server error or a network-related error. Parameters given are
a code reference for continuing with the next handler registered
for this event and a L<Neo4j::Error> object. The driver's
default behaviour for this event basically is to
C<< die $error->as_string() >>.

The driver does not expect error event handlers to survive execution.
If you don't call C<die()>, the driver session is likely to be
in an inconsistent state and you should expect further errors.
To safely continue after errors, C<use feature 'try'>.

Note that this event will I<not> be triggered for most error
conditions caused by an internal error or a usage error. In such
cases, the driver will just die regularly with an error message
string in the usual Perl fashion.

=item http_adapter_factory

 $events->add_handler(
   http_adapter_factory => sub {
     my ($continue, $driver) = @_;
     my $adapter;
     ...
     return $adapter // $continue->();
   },
 );

This event is triggered when a new HTTP adapter instance is
needed during session creation. Parameters given are a code
reference for continuing with the next handler registered for
this event and the driver.

A handler for this event must return the blessed instance of
an HTTP adapter module (formerly known as "networking module")
to be used instead of the default adapter built into the driver.
See L</"Network adapter API for HTTP"> below.

=back

More events may be added in future versions. If you have a need
for a specific event, let me know and I'll see if I can add it
easily.

If your plug-in defines custom events of its own, it must only
use event names that beginn with C<x_>. All other event names
are reserved for use by the driver itself.

=head1 METHODS

All plug-ins must implement the following method, which is
required for the L<Neo4j::Driver::Plugin> role.

=over

=item register

 sub register {
   my ($self, $events) = @_;
   ...
 }

Called by the driver when a plug-in is loaded. Parameters given
are the plug-in and an event manager.

This method is expected to attach this plug-in's event handlers
by calling the event manager's L</"add_handler"> method.
See L</"EVENTS"> for a list of events supported by this version
of the driver.

=back

=head1 THE EVENT MANAGER

The job of the event manager (formerly known as the "plug-in
manager") is to invoke the appropriate
event handlers when events are triggered. It also allows clients
to modify the list of registered handlers. A reference to the
event manager is provided to your plug-in when it is loaded;
see L</"register">.

The event manager implements the following methods.

=over

=item add_handler

 $events->add_handler( event_name => sub {
   ...
 });

Registers the given handler for the named event. When that event
is triggered, the handler will be invoked (unless another plug-in's
handler for the same event prevents this). Handlers will be invoked
in the order they are added (but the order may be subject to change).

Certain events provide handlers with a code reference for
continuing with the next handler registered for that event. This
callback should be treated as the default driver action for that
event. Depending on what a plug-in's purpose is, it may be useful
to either invoke this callback and work with the results, or to
ignore it entirely and handle the event independently.

 $events->add_handler( get_value => sub {
   my ($continue) = @_;
   my $default = $continue->();
   return eval { maybe_value() } // $default;
 });

Note that future updates to the driver may change existing events
to provide additional arguments. Because subroutine signatures
perform strict checks of the number of arguments, they are not
recommended for event handlers.

This method used to be named C<add_event_handler()>.
There is a compatibility alias, but its use is deprecated.

=item trigger

 $events->trigger( 'event_name', @parameters );

Called by the driver to trigger an event and invoke any registered
handlers for it. May be given an arbitrary number of parameters,
all of which will be passed through to the event handler.

Most plug-ins won't need to call this method. But plug-ins may
choose to trigger and handle custom events. These must have names
that begin with C<x_>. Plug-ins should not trigger events with
other names, as these are reserved for internal use by the driver
itself and for first-party plug-ins.

You should avoid using custom event names that start with
C<x_after_> and C<x_before_>, because a future version of the
driver may give special treatment to such names. There is a
chance that certain other names may similarly be affected.

Events that are triggered, but not handled, are currently silently
ignored. This will likely change in a future version of the driver.

Calling this method in list context is discouraged, because doing
so might be treated specially by a future version of the driver.
Use C<scalar> to be safe.

This method used to be named C<trigger_event()>.
There is a compatibility alias, but its use is deprecated.

=back

=head1 EXTENDING THE DRIVER

=head2 Module namespaces

Plug-in authors are free to use the Neo4j::Driver::Plugin::
namespace for modules that perform the L<Neo4j::Driver::Plugin>
role. Plug-ins in this namespace should be uploaded to CPAN.

Supporting modules should be placed in the sub-namespace defined by
the plug-in. Network adapters may alternatively be placed in the
Neo4j::Driver::Net:: namespaces, separated by network protocol.
Adapters for generic modules should be given short names that
indicate the module distribution (L<Neo4j::Driver::Net::HTTP::LWP>
for L<LWP::UserAgent> etc.).
The following module names are reserved
for future use by the driver itself:

=over

=item * Neo4j::Driver::Net::Bolt::Base

=item * Neo4j::Driver::Net::Bolt::Role

=item * Neo4j::Driver::Net::HTTP::Base

=item * Neo4j::Driver::Net::HTTP::Role

=item * Neo4j::Driver::Net::HTTP::Tiny

=back

Result handlers that perform the L<Neo4j::Driver::Result> role
should be placed in the Neo4j::Driver::Result:: namespace.

Please don't place plug-ins or other supporting modules directly
into the Neo4j::Driver:: namespace.

=head2 Network adapter API for Bolt

At this time (2022), there is only one known implementation of the
Bolt protocol for Perl: L<Neo4j::Bolt>, created by Mark A. Jensen.

For this reason, an abstraction API for Bolt network adapters has
not yet been specified. This driver currently expects that any
module implementing Bolt behaves I<exactly> like L<Neo4j::Bolt>
itself does.

If you're writing another Perl module for Bolt, please get in
touch with me. I would like to collaborate with you on writing
the abstraction API for the driver.

=head2 Network adapter API for HTTP

HTTP network adapters (formerly known as "HTTP networking
modules") are used by the driver to delegate networking
tasks to one of the common Perl modules for HTTP, such as L<LWP>
or L<Mojo::UserAgent>. Driver plug-ins can also use this low-level
access to implement special features, for example dynamic rewriting
of Cypher queries or custom object-graph mapping.

The driver primarily uses HTTP network adapters by first calling
the C<request()> method, which initiates a request on the network,
and then calling other methods to obtain information about the
response. See L<Neo4j::Driver::Net> for more information.

 $adapter->request('GET', '/', undef, 'application/json');
 $status  = $adapter->http_header->{status};
 $type    = $adapter->http_header->{content_type};
 $content = $adapter->fetch_all;

HTTP network adapters must implement the following methods.

=over

=item date_header

 sub date_header {
   my ($self) = @_;
   ...
 }

Return the HTTP C<Date:> header from the last response as string.
If the server doesn't have a clock, the header will be missing;
in this case, the value returned must be either the empty
string or (optionally) the current time in non-obsolete
L<RFC5322:3.3|https://tools.ietf.org/html/rfc5322#section-3.3>
format.
May block until the response headers have been fully received.

=item fetch_all

 sub fetch_all {
   my ($self) = @_;
   ...
 }

Block until the response to the last network request has been fully
received, then return the entire content of the response buffer.

This method must generally be idempotent, but the behaviour of this
method if called after C<fetch_event()> has already been called for
the same request is undefined.

=item fetch_event

 sub fetch_event {
   my ($self) = @_;
   ...
 }

Return the next Jolt event from the response to the last network
request as a string. When there are no further Jolt events, this
method returns an undefined value. If the response hasn't been
fully received at the time this method is called and the internal
response buffer does not contain at least one event, this method
will block until at least one event is available.

The behaviour of this method is undefined for responses that
are not in Jolt format. The behaviour is also undefined if
C<fetch_all()> has already been called for the same request.

A future version of this driver will likely replace this method
with something that performs JSON decoding on the event before
returning it; this change may allow for better optimisation of
Jolt event parsing.

=item http_header

 sub http_header {
   my ($self) = @_;
   ...
 }

Return a hashref with the following entries, representing
headers and status of the last response.

=over

=item * C<content_type> – S<e. g.> C<"application/json">

=item * C<location> – URI reference

=item * C<status> – status code, S<e. g.> C<"404">

=item * C<success> – truthy for 2xx status codes

=back

All of these entries must exist and be defined scalars.
Unavailable values must use the empty string.
Blocks until the response headers have been fully received.

For error responses generated internally by the networking
library, for example because the connection failed, C<status>
and C<content_type> should both be the empty string, with
the C<http_reason()> method providing the error message.
Optionally, additional information may be made available in
a plain text response content; in this case, the C<status>
should preferably be C<"599">.

=item http_reason

 sub http_reason {
   my ($self) = @_;
   ...
 }

Return the HTTP reason phrase (S<e. g.> C<"Not Found"> for
status 404). If unavailable, C<""> is returned instead.
May block until the response headers have been fully received.

=item json_coder

 sub json_coder {
   my ($self) = @_;
   ...
 }

Return a L<JSON::XS>-compatible coder object (for result parsers).
It must offer a method C<decode()> that can handle the return
values of C<fetch_event()> and C<fetch_all()> (which may be
expected to be a byte sequence that is valid UTF-8) and should
produce sensible output for booleans (S<e. g.> C<$JSON::PP::true>
and C<$JSON::PP::false>, or native booleans on newer Perls).

The default adapter included with the driver uses L<JSON::MaybeXS>.

=item request

 sub request {
   my ($self, $method, $url, $json, $accept) = @_;
   ...
 }

Start an HTTP request on the network. The following positional
parameters are given:

=over

=item * C<$method> – HTTP method, S<e. g.> C<"POST">

=item * C<$url> – string with request URL

=item * C<$json> – reference to hash of JSON object

=item * C<$accept> – string with value for the C<Accept:> header

=back

The request C<$url> is to be interpreted relative to the server
base URL given in the driver config.

The C<$json> hashref must be serialised before transmission.
It may include booleans encoded as the values C<\1> and C<\0>.
For requests to be made without request content, the value
of C<$json> will be C<undef>.

C<$accept> will have different values depending on C<$method>;
this is a workaround for a known issue in the Neo4j server
(L<#12644|https://github.com/neo4j/neo4j/issues/12644>).

The C<request()> method may or may not block until the response
has been received.

=item result_handlers

 sub result_handlers {
   my ($self) = @_;
   ...
 }

Return a list of result handler modules to be used to parse
Neo4j statement results delivered through this module.
The module names returned will be used in preference to the
result handlers built into the driver.

Unlike any other method, C<result_handlers()> is optional for
a Neo4j HTTP adapter module. It may only be implemented by
network adapters that actually offer custom result handlers.
Note that the result handler API is currently internal and
expected to change, and this method will likely disappear
entirely in future; see L</"RESULT HANDLER API"> below.

=item uri

 sub uri {
   my ($self) = @_;
   ...
 }

Return the server base URL as string or L<URI> object
(for L<Neo4j::Driver::ServerInfo>).
At least scheme, host, and port must be included.

=back

=head2 Result handler API

Making a Neo4j result handler API available to plug-ins will
require significant internal changes to the driver. These
are currently being postponed, at least until most of the
L<deprecated functionality|Neo4j::Driver::Deprecations> has
been removed from the driver's code base.

Even then, the result handler API may have low priority.
However, new plug-in events are anticipated in a future version
that should enable clients to achieve some of the same goals.

In the meantime, the result handler API remains not formally
specified. It is an internal API that is evolving and may be
subject to unannounced change; see L</"USE OF INTERNAL APIS">.

A few notes on the result handler API that may or may not be
accurate by the time you read this:

 sub new ($class, $params) {}
 sub _fetch_next ($self) {}
   # ^ optional if results are always fully detached
 sub _init_record ($self, $record) {}
 
 # for HTTP additionally:
 sub _accept_header ($, $want_jolt, $method) {}
 sub _acceptable ($, $content_type) {}
 sub _info ($self) {}
 sub _json ($self) {}
   # ^ only required for handlers that accept application/json
   #   (solely used by the Discovery API to get raw JSON)
 
 # For the API, these methods should gain public names (no _).
 # Currently the driver's own result handlers access the internal
 # data structures directly. For the API, some kind of accessors
 # will be needed, and for simplicity, all results should always
 # begin as attached (JSON: $fake_attached = 1).

B<WARNING:> All of these methods are currently private APIs.
See L</"USE OF INTERNAL APIS">.

=head1 USE OF INTERNAL APIS

B<Public APIs> generally include everything that is documented
in POD, unless explicitly noted otherwise.

B<Private internals,> on the other hand, include all package-global
variables (C<our ...>), all methods with names that begin with an
underscore (C<_>) and I<all> cases of accessing the data structures
of blessed objects directly (S<e. g.> C<< $session->{net} >>). In
addition, methods without any POD documentation are to be considered
private internals (S<e. g.> C<< Neo4j::Driver::Session->new() >>).

You are of course free to use any driver internals in your own code,
but if you do so, you also bear the sole responsibility to keep it
working after updates to the driver. Changes to internals are often
not announced in the F<Changes> list, so you should consider to
watch GitHub commits. It is discouraged to try this approach if
your code is used in production.

If you have difficulties achieving your goals without the use of
driver internals or private APIs, you are most welcome to file a
GitHub issue about that (or write to my CPAN email address with
your concerns).

I can't I<promise> that I'll be able to accommodate your use case,
but I am going to try.

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

If you contact me by email, please make sure you include the word
"Perl" in your subject header to help beat the spam filters.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2023 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
