package STIX::Report;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::List;
use STIX::Common::OpenVocabulary;
use Types::Standard qw(Int Str Enum InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Common::Properties';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/sdos/report.json';

use constant PROPERTIES => (
    qw(type spec_version id created modified),
    qw(created_by_ref revoked labels confidence lang external_references object_marking_refs granular_markings extensions),
    qw(name description report_types published object_refs)
);

use constant STIX_OBJECT      => 'SDO';
use constant STIX_OBJECT_TYPE => 'report';

has name => (is => 'rw', isa => Str, required => 1);
has description => (is => 'rw', isa => Str);

has report_types => (
    is      => 'rw',
    isa     => ArrayLike [Enum [STIX::Common::OpenVocabulary->REPORT_TYPE()]],
    default => sub { STIX::Common::List->new }
);

has published => (
    is       => 'rw',
    required => 1,
    isa      => InstanceOf ['STIX::Common::Timestamp'],
    coerce   => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has object_refs => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Object', 'STIX::Common::Identifier']],
    default => sub { STIX::Common::List->new }
);

1;

=encoding utf-8

=head1 NAME

STIX::Report - STIX Domain Object (SDO) - Report

=head1 SYNOPSIS

    use STIX::Report;

    my $report = STIX::Report->new();


=head1 DESCRIPTION

Reports are collections of threat intelligence focused on one or more
topics, such as a description of a threat actor, malware, or attack
technique, including context and related details.


=head2 METHODS

L<STIX::Report> inherits all methods from L<STIX::Common::Properties>
and implements the following new ones.

=over

=item STIX::Report->new(%properties)

Create a new instance of L<STIX::Report>.

=item $report->description

A description that provides more details and context about Report.

=item $report->id

=item $report->name

The name used to identify the Report.

=item $report->object_refs

Specifies the STIX Objects that are referred to by this Report.

=item $report->published

The date that this report object was officially published by the creator of
this report.

=item $report->report_types

This field is a C<REPORT_TYPE> (L<STIX::Common::OpenVocabulary>) that
specifies the primary subject of this report. The suggested values for this
field are in report-type-ov.

=item $report->type

The type of this object, which MUST be the literal C<report>.

=back


=head2 HELPERS

=over

=item $report->TO_JSON

Encode the object in JSON.

=item $report->to_hash

Return the object HASH.

=item $report->to_string

Encode the object in JSON.

=item $report->validate

Validate the object using JSON Schema (see L<STIX::Schema>).

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-STIX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-STIX>

    git clone https://github.com/giterlizzi/perl-STIX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
