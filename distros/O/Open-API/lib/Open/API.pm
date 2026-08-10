package Open::API;

use 5.008003;
use strict;
use warnings;
use Carp ();

our $VERSION = '0.08';

require XSLoader;
XSLoader::load('Open::API', $VERSION);

Carp::croak(
	"Open::API requires JSON::Schema::Fast built with its C ABI "
	. "(JSON::Schema::Fast 0.04 or later); please upgrade or reinstall it"
) unless _abi_ok();

1;

__END__

=head1 NAME

Open::API - OpenAPI 3.1 server and client

=head1 VERSION

Version 0.08

=head1 SYNOPSIS

    use Open::API;

    # a spec: hashref, JSON text, YAML text, or a filename
    my $api = Open::API->new(spec => 'openapi.json');

    # the compiled spec drives a PSGI app (see Open::API::Plack) ...
    my $app = Open::API::Plack->new(
        api      => $api,
        handlers => {
            listPets => 'MyApp::Pets::list',
            getPet   => sub { ... },
        },
    )->to_app;

    # ... and an HTTP client (see Open::API::Client)
    my $client = Open::API::Client->new(
        api => $api,
        base_url => 'http://127.0.0.1:5000'
    );
    my $res = $client->getPet(petId => 42)->get;

=head1 DESCRIPTION

C<Open::API> loads an OpenAPI 3.1 document once and compiles every parameter,
header, cookie and body schema through L<JSON::Schema::Fast> at
startup. Each request is then routed and validated on a C hot path.

The compiled object is the shared core of two consumers: L<Open::API::Plack>
serves it as a PSGI app (routing, validation, security, CSRF, CORS - all in
C before a handler runs), and L<Open::API::Client> is a spec-driven HTTP
client on L<Fetch>'s C ABI, so one document defines both sides of the wire.
The L</match> and L</validate_request> methods below expose the router and
validator directly for any other framework adapter.

OpenAPI B<3.1 only>: 3.1 schemas are native JSON Schema 2020-12, which is what
JSON::Schema::Fast validates. A document with any other C<openapi> version
croaks at load.

=head1 CONSTRUCTOR

=head2 new

    my $api = Open::API->new(spec => $spec);

C<spec> is required and may be:

=over 4

=item * a hashref (an already-decoded document),

=item * a string of JSON text,

=item * a string of YAML text (decoded with L<YAML::XS>, loaded lazily -
only YAML specs need it), or

=item * a filename (C<.json>, C<.yaml> or C<.yml>; anything else is sniffed by
content).

=back

Compilation walks C<paths> once: every operation needs a unique
C<operationId> (it is the dispatch key), path templates are pre-split,
path-item and operation C<parameters> are merged (operation wins), and every
schema is compiled through the JSF ABI - parameters with coercion enabled
(string sources satisfy typed schemas, exactly what OpenAPI parameters need)
and C<default>-filling on. C<$ref>s to C<#/components/schemas/...> are
resolved at compile time. A malformed document, a missing or duplicate
operationId, or an unresolvable reference croaks here, at startup.

=head1 METHODS

=head2 spec

The decoded OpenAPI document.

=head2 operations

    my $ops = $api->operations;   # [ { operationId, method, path }, ... ]

=head2 operation

    my $info = $api->operation('getPet');

A description of one operation: C<params> by location (name + required),
C<body> (required flag + content types) and C<responses> (statuses with
compiled schemas). C<undef> for an unknown id.

=head2 match

    my ($opId, $captures) = $api->match($method => $path);

The router alone: C<($operationId, \%raw_path_captures)> on a match; an empty
list for a 404; C<(undef, \@allow)> when the path exists but the method does
not (a 405 and its Allow list). For framework adapters.

=head2 validate_request

    my ($ok, $result) = $api->validate_request($opId, {
        path   => \%raw_captures,
        query  => $query_string_or_hashref,
        header => \%lowercased_headers,
        body   => $raw_body_or_decoded_ref,
    });

The validator alone: C<(1, \%params)> or C<(0, \@errors)>. Header names must
be lowercased by the caller; cookies are parsed from the C<cookie> header when
the operation declares cookie parameters. For framework adapters - together
with L</match> this is the complete integration surface, everything heavy
stays in C.

=head2 check_response

    my $errors = $api->check_response($opId, $triplet, \%opts);

Weigh a PSGI response against the schema the document declares for its
status. Returns the error list for a mismatch and C<undef> for everything
else - a conforming response, an unsampled one, or one skipped by a rule
below. B<The triplet is never modified>, whatever the verdict: a gateway
that edits what the upstream sent is not a gateway.

Options: C<sample> validates one response in N for this operation, and
C<max_body> skips bodies over that many bytes.

A response is checked only if it passes the sampling gate and then every
skip rule, in this order:

=over 4

=item * B<content type> - the C<Content-Type> is not one the document
declares a JSON schema under (C<skip_ctype>).

=item * B<size> - with C<max_body> set, C<Content-Length> is absent or
over it (C<skip_size>). An unmeasured body is not buffered to find out.

=item * B<body shape> - the body is not a plain scalar: a filehandle, a
streaming coderef, an SSE writer (C<skip_body>). Never read.

=item * B<schema> - the status declares no schema, so there is nothing to
weigh it against (C<skip_schema>).

=item * B<decode> - the body does not decode as JSON (C<skip_decode>).

=back

The gate comes first so an unsampled response costs one increment and one
comparison. It is a per-operation counter rather than a random draw:
cheaper, and a stable denominator.

=head2 response_coverage

    my $cov = $api->response_coverage('getPet');
    my $all = $api->response_coverage;

The counters behind that, for one operation or for every operation that
has seen a response: C<total>, C<sampled>, C<unsampled>, C<checked>,
C<violations>, and C<skip_ctype>, C<skip_size>, C<skip_body>,
C<skip_schema>, C<skip_decode>.

Every response is either checked or skipped for exactly one named reason,
which is the point: what was not looked at is a number you can report, not
a gap you have to assume away.

=head2 synthesize

    my $trip = $api->synthesize('getPet');
    my $trip = $api->synthesize('getPet', { code => 404 });
    my $trip = $api->synthesize('getPet', { prefer => $env->{HTTP_PREFER} });

A response for an operation, from the document alone, as a PSGI triplet -
this is what serves a mock. The body is, in order of precedence: the
media type's C<example>; a named C<examples> entry when
C<< example => 'name' >> (or a C<Prefer: example=name> token) asked for
one, the lexicographically first entry otherwise; the schema's
C<default>; a value generated from the schema (types, C<enum> first
member, C<const>, C<format>-aware strings, objects with C<required>
members only, C<allOf>/C<oneOf>/C<anyOf>).

B<Deterministic.> The same arguments give byte-identical bodies: nothing
below draws a random value, and the body is encoded canonically (sorted
keys), so not even hash order leaks in - the property holds across
processes, not merely within one.

=head3 Arrays

An array is generated with five elements. Not zero, which is what an
absent C<minItems> literally means and which is a correct answer to the
wrong question - a list endpoint that mocks as C<[]> validates perfectly
and shows the caller nothing about the shape of what they will get. Not
one either: a single-element list is a shape nobody can build a table, a
pagination control or an empty state against.

C<minItems> raises that and C<maxItems> caps it, C<maxItems: 0>
included - there the document has said it means empty and it is
believed.

Integer members whose names identify a thing - C<id>, C<petId>,
C<order_id> - get the element's index added, so five rows are five rows
rather than the same row five times. It stays deterministic, because the
index is a position and not a counter, and it stays valid, because a
value that would pass C<maximum> is left alone.

=head3 The request

    $api->synthesize('showPet', { path => { petId => 42 } });
    # { "id": 42, "name": "string" }

Given the request's path captures, a response property the request has
already answered is answered with what the request said. C<GET /pets/42>
replying with C<id> 0 is a mock nobody can develop a client against.

A capture matches a property by the same name, the same name in any
case, and then the convention every REST document uses - a path
templated C<{petId}> naming the resource whose schema calls the field
C<id>. That last rule applies only when exactly one capture ends in
C<id>: C</pets/{petId}/toys/{toyId}> has two and there is no honest way
to say which one a nested C<id> means, so it generates rather than
guesses.

B<The guarantee outranks the convenience.> A captured value is used only
when it fits the property's schema - the declared type (numeric strings
are coerced), C<enum>, C<const>, the numeric bounds and the length
bounds. Anything that does not fit falls back to generation, and a
schema carrying a C<pattern> falls back too, because a regex this does
not evaluate is a rule it cannot honour. The mock still cannot produce
something its own validator would reject.

Status selection: C<< code => N >> (or a C<Prefer: code=N> token) picks a
declared status; without one the lowest declared 2xx wins, then
C<default> (answered as 200), then the lowest declared status. A
preferred status the document does not declare is still answered - with
the C<default> response's body when one is declared, empty otherwise -
because C<Prefer> exists to exercise error handling. A response that
declares no JSON content (a C<204>, a bare error) answers with an empty
body and no content type.

Explicit C<code>/C<example> keys win over the C<prefer> string. Croaks on
an unknown operationId.

=head2 operation_info

    my $info = $api->operation_info('getPet');

The compiled contract for an operation - what will actually be checked,
after C<$ref> resolution: C<operationId>, C<method>, C<path>,
C<parameters> (each with C<name>, C<in>, C<required>, C<schema>), C<body>
and C<body_required>, C<responses> (each with C<status>, C<content_type>
and whether it is C<validated>), and C<secured>.

This is the compiled table, not the document: a status the document
declares without a schema does not appear, because nothing will be
checked for it.

=head1 ERRORS

Validation errors are hashrefs: the L<JSON::Schema::Fast> output fields
(C<instanceLocation>, C<keyword>, C<schemaLocation>, C<message>) augmented
with C<in> (path / query / header / cookie / body / response) and C<name>
(the parameter name). Missing required inputs use C<< keyword => 'required' >>;
an undecodable JSON body uses C<< keyword => 'json' >>.

=head1 ARCHITECTURE

Open::API is a consumer of two runtime-resolved C ABIs, the same DBI-style
versioned function-pointer tables used across the Semantic stack:

=over 4

=item * L<JSON::Schema::Fast> (required) - schemas are compiled once through
C<jsf_abi.h> and every validation on the request path is a direct C call.
Resolved and version-checked at load; absence is a hard error.

=item * L<Fetch> (optional) - L<Open::API::Client> fires requests through
C<fetch_abi.h>. Resolved lazily on first client construction; the server side
never loads it.

=back

It is also a B<provider> of one: C<include/oa_abi.h> exposes the router and
validator to another XS module's own C dispatcher, so an operation is routed
and validated with no Perl frame between the socket and the controller. See
L</C ABI> below.

There is no link-time coupling: each distribution builds and upgrades
independently, and a version skew fails cleanly at boot (t/12-abi-guard.t on
the consumer side, t/25-abi.t for the provider table).

=head1 C ABI

C<include/oa_abi.h> is the C form of L</match> and L</validate_request>: a
versioned function-pointer table resolved at B<runtime>, in the DBI style used
across the Semantic stack. There is no link-time symbol coupling, so provider
and consumer build and upgrade independently. L<Punk> is the first consumer -
its C dispatcher routes, validates and hands the typed parameters to a
controller without unwinding into Perl.

=head2 Getting the header

Open::API installs C<oa_abi.h> through L<ExtUtils::Depends>, so a consumer's
F<Makefile.PL> picks up the include path with no vendoring:

    use ExtUtils::Depends;
    my $pkg = ExtUtils::Depends->new('My::Consumer', 'Open::API');
    WriteMakefile(
        ...
        $pkg->get_makefile_vars,   # INC reaches oa_abi.h
        PREREQ_PM => { 'Open::API' => '0.04' },
    );

The alternative is to vendor a copy of the header pinned at a known
C<OA_ABI_VERSION>. Either way the header only declares the table; nothing is
linked.

Perl's own headers (F<EXTERN.h>, F<perl.h>, F<XSUB.h>) must be included before
C<oa_abi.h>, which needs C<SV>, C<AV>, C<HV>, C<STRLEN> and C<pTHX>.

=head2 Resolving the table

C<Open::API::_abi_ptr> returns the address of the process-wide table as an IV.
It is not a Perl-level API - it is the ABI entry point, and the only supported
thing to do with it is C<INT2PTR> it back to a C<< const oa_abi * >> and check
C<abi_version> before the first call:

    #include "oa_abi.h"

    static const oa_abi *OA = NULL;

    static const oa_abi *my_oa(pTHX) {
        if (!OA) {
            IV p = 0;
            dSP;
            eval_pv("require Open::API;", FALSE);
            SPAGAIN;                    /* the require may have moved the stack */
            if (!SvTRUE(ERRSV)) {
                ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
                if (call_pv("Open::API::_abi_ptr", G_SCALAR | G_EVAL) > 0) {
                    SPAGAIN;
                    p = POPi;
                }
                PUTBACK; FREETMPS; LEAVE;
            }
            if (p) {
                const oa_abi *a = INT2PTR(const oa_abi *, p);
                if (a && a->abi_version == OA_ABI_VERSION) OA = a;
            }
        }
        return OA;   /* NULL means: use the Perl-visible methods instead */
    }

The address is static for the life of the process, so resolve it once at boot
and cache it. The IV may legitimately be negative on platforms that map shared
objects high in the address space; C<INT2PTR> round-trips the bits either way,
so test for non-zero, not for positive.

A NULL result means Open::API is absent, too old, or built without the table.
That is not an error in itself - the documented answer is to fall back to
L</match> and L</validate_request>, which do the same work with Perl frames.
A consumer that hard-requires the ABI should croak at boot, not per request.

=head2 The table

    typedef struct oa_abi {
        int abi_version;
        void *(*api_of)   (pTHX_ SV *api_sv);
        void *(*route)    (pTHX_ void *api, const char *method, STRLEN mlen,
                           const char *path, STRLEN plen, HV *caps, AV *allow);
        void *(*op_by_id) (pTHX_ void *api, SV *op_id);
        int   (*validate) (pTHX_ void *api, void *op, HV *raw, HV *typed,
                           AV *errors);
        SV   *(*op_id)    (pTHX_ void *op);
    } oa_abi;

=over 4

=item * C<abi_version> - equals C<OA_ABI_VERSION> in the header the provider
was built with. Compare it before calling anything else.

=item * C<api_of> - the opaque API handle behind a blessed Open::API SV (what
L</new> returns). Returns NULL when the SV is not a reference; it never
croaks, so it is safe on the fall-back path. The handle lives as long as the
SV does and is not freed by the caller.

=item * C<route> - the C form of L</match>. C<method> and C<path> are given
with explicit lengths, and C<path> is the request path only, already
prefix-stripped by the caller (a mount strips its own prefix). On a match it
returns the opaque operation handle and fills C<caps> with the raw captured
path segments (name =E<gt> borrowed value SV). On a 405 - the path exists but
not for this method - it returns NULL and fills C<allow> with the upper-case
method names, an AV of SVs. On a 404 it returns NULL and leaves C<allow>
empty. C<caps> and C<allow> are caller-owned and must be empty on entry;
either may be NULL to discard that output.

=item * C<op_by_id> - the opaque operation handle for an operationId, for a
consumer that dispatches by name rather than by path. NULL when the id is
unknown.

=item * C<validate> - the C form of L</validate_request>. C<raw> is the same
hash that method documents:

    { path   => \%captures,           # e.g. the caps from route()
      query  => $query_string | \%hash,
      header => \%lowercased_headers, # cookies ride the "cookie" header
      body   => $raw_bytes | $decoded_ref }

On success it fills C<typed> with the validated, coerced, percent-decoded
parameters (the path/query/header/cookie hashes and the body, exactly the
shape L</validate_request> returns) and returns 1. On failure it pushes error
hashrefs - the L</ERRORS> shape - into C<errors> and returns 0. Both
containers are caller-owned and should be empty on entry; either may be NULL
to discard it, and a NULL C<typed> validates without materialising the
parameters.

=item * C<op_id> - the operationId SV of a routed operation. It is borrowed:
do not free it, and copy it if it must outlive the API object.

=back

Every call takes C<pTHX_> and must be made on the interpreter that owns the
API SV. The table itself is C<const> and shared; the handles it hands back are
owned by the Open::API object, so keep that object alive for as long as the
dispatcher uses them.

=head2 Versioning

The table only ever grows at the end. C<OA_ABI_VERSION> bumps on any append,
and a consumer requires C<abi_version> to equal the version it was written
against, or to be greater than it if it treats a later table as a superset and
uses only the prefix it knows. Fields are never reordered, retyped or removed
within a major line, so a consumer built against version I<N> keeps working
against any provider that still reports I<N>.

The provider table is exercised end to end by F<t/25-abi.t>, which drives
C<api_of>, C<route>, C<op_id> and C<validate> through the pointers and asserts
the results match the Perl-visible L</match> and L</validate_request> - the
ABI is the same behaviour with the Perl frames removed.

=head1 SEE ALSO

L<Open::API::Plack>, L<Open::API::Client>, L<JSON::Schema::Fast>, L<Fetch>,
L<Hyperman>, L<Punk>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-open-api at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Open-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Open::API

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Open-API>

=item * Search CPAN

L<https://metacpan.org/release/Open-API>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
