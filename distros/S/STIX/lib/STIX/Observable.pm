package STIX::Observable;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::Binary;
use STIX::Common::Enum;

use Moo;
extends 'STIX::Common::Properties';

use constant STIX_OBJECT => 'SCO';

1;

=encoding utf-8

=head1 NAME

STIX::Observable - Base class for STIX Cyber-observable Object (SCO)

=head2 METHODS

L<STIX::Observable> inherits all methods from L<STIX::Common::Properties>.


=head2 HELPERS

=over

=item $object->TO_JSON

Encode the object in JSON.

=item $object->to_hash

Return the object HASH.

=item $object->to_string

Encode the object in JSON.

=item $object->validate

Validate the object using JSON Schema
(see L<STIX::Schema>).

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
