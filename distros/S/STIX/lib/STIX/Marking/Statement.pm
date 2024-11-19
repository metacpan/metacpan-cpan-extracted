package STIX::Marking::Statement;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str);

use Moo;
use namespace::autoclean;

extends 'STIX::Object';

use constant SCHEMA =>
    'https://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/common/marking-definition.json#/definitions/statement';

use constant PROPERTIES => (qw(statement));

use constant MARKING_TYPE => 'statement';

has statement => (is => 'rw', required => 1, isa => Str);

1;

=encoding utf-8

=head1 NAME

STIX::Marking::Statement - STIX Statement marking

=head1 SYNOPSIS

    use STIX::Marking::Statement;

    my $statement = STIX::Marking::Statement->new();


=head1 DESCRIPTION

The Statement marking type defines the representation of a textual marking
statement (e.g., copyright, terms of use, etc.) in a definition


=head2 METHODS

L<STIX::Marking::Statement> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Marking::Statement->new(%properties)

Create a new instance of L<STIX::Marking::Statement>.

=item $statement->statement

A statement (e.g., copyright, terms of use) applied to the content marked
by this marking definition.

=back


=head2 HELPERS

=over

=item $statement->TO_JSON

Helper for JSON encoders.

=item $statement->to_hash

Return the object HASH.

=item $statement->to_string

Encode the object in JSON.

=item $statement->validate

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
