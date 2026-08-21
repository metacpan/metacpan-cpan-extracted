package Punk::OpenTelemetry::Schema;

use 5.010;
use strict;
use warnings;
use Punk::OpenTelemetry ();

our $VERSION = '0.04';

# All of it is C (include/otel_schema.h + xs/schema.xs). The one call back out
# is the YAML parse: the format needs a parser, which parser is a runtime
# question, and there is no C one to reach for.

1;

__END__


=head1 NAME

Punk::OpenTelemetry::Schema - schema URLs and the version converter

=head1 SYNOPSIS

    my $schema = Punk::OpenTelemetry::Schema->load(path => $file);

    $schema->convert($payload,
        from => '1.29.0', to => '1.30.0', signal => 'spans');

=head1 DESCRIPTION

Two halves: emitting the schema URL, and converting telemetry between the
convention versions two schema URLs name.

=head1 EMITTING

C<Resource> and each scope carry a C<schema_url>, which travels as
C<ResourceSpans.schema_url> and C<ScopeSpans.schema_url> - and the metrics and
logs equivalents. The URL names the semantic convention version the telemetry
was produced against.

The version this distribution emits is pinned in one header
(C<OTEL_SCHEMA_URL> in F<otel_semconv.h>) and reachable as
C<Punk::OpenTelemetry::Instrument::schema_url>, so "which conventions does
this speak" has an answer that cannot drift from the code.

A resource and a scope may legitimately carry B<different> schema URLs, and
telemetry with different URLs must not be merged into one C<ResourceSpans> -
the grouping key is the resource B<plus> the schema URL. That is what makes
this more than a string field.

=head1 CONVERTING

=head2 Order matters, and so does direction

Versions are applied B<one at a time, in order>. A single merged rename map
computed in one pass gives the wrong answer whenever an attribute was renamed
twice: C<a> becomes C<b> in one version and C<b> becomes C<c> in the next, so
the right answer for C<a> is C<c> - but a flattened map holds C<< a => b >>
and C<< b => c >> as independent entries and stops at C<b>.

Applying versions forward is the reverse of applying them backward. A schema
file records the changes made B<going up> to each version, so forward renames
old to new and backward renames new to old.

C<all> applies to every signal and is merged before the signal's own section.

=head2 Where the files come from

Schema files live at their schema URL. B<Nothing here fetches over the
network, under any configuration.> A runtime dependency on a third party, in
the request path, is not something a telemetry layer gets to introduce
quietly.

So the file for the version this dist emits B<ships with it>, at
F<Punk/OpenTelemetry/Schema/1.30.0.yaml> - unmodified, as published. That is
the version this SDK's own telemetry is produced against, which makes it the
one a caller almost always wants, and C<load()> with no arguments finds it
with no configuration.

Anything else is looked for on a search path, in this order:

=over 4

=item 1. a C<dir> the caller passes

=item 2. C<$ENV{OTEL_SCHEMA_DIR}>

=item 3. the directory shipped beside this module

=back

The path exists for the operator who needs a version this release predates:
drop the file in a directory, point C<OTEL_SCHEMA_DIR> at it, and no code
changes. Files are named C<I<version>.yaml>, and a version that is not a
version (anything outside digits and dots) is refused rather than concatenated
into a path.

An unknown schema URL is not an error. C<for_url> returns C<undef>, and the
telemetry passes through unchanged - which is the correct outcome and the only
one that does not involve reaching out to a third party mid-request.

=head2 Why bother

Honestly: most operators will never use the converter. It matters for one
situation, which is common enough to be worth it - a fleet mid-upgrade, where
half the services emit C<http.method> and half emit C<http.request.method>,
and the dashboards break in a way that looks like an outage. Normalising at
the edge makes that a config change rather than a coordinated redeploy.

=head1 METHODS

=head2 load(path => $file) / load(text => $yaml)

A schema file read from disk, or parsed from a string already in hand. The
string form is what a test uses; the path form is for a schema this
distribution does not ship.

=head2 load() / load(version => $v, dir => $d)

With no source, the shipped file for the version this dist emits. With a
C<version>, that version off the search path above. Dies when there is no such
file, because a caller who named a version meant it.

=head2 for_url($schema_url)

The schema for a URL, or C<undef> when nothing local describes it. This is the
form to use when converting telemetry that arrived carrying its own schema
URL: C<undef> means leave it alone.

=head2 file_for($version)

The path the search would use, or C<undef>.

=head2 shipped_version

The semantic convention version this distribution emits, derived from the C
pin (C<OTEL_SCHEMA_URL> in F<otel_semconv.h>) so the two cannot drift.

=head2 convert($payload, from => $v, to => $v, signal => $s)

C<$signal> is C<spans>, C<metrics> or C<logs>. The payload is modified in
place and returned.

=head2 schema_url / versions / knows($version)

C<schema_url> is the URL this loaded schema describes. C<versions> is the
version list in file order, and in scalar context their B<count> rather than
the last of them. C<knows> is whether a given version appears in it, which is
what to ask before handing C<convert> below a version a caller supplied.

=head1 SEE ALSO

L<Punk::OpenTelemetry::Instrument> - where the emitted schema URL is pinned.

L<Punk::OpenTelemetry::Encode> - the six schema_url fields on the wire.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
