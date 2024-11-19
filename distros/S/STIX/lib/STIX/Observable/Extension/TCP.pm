package STIX::Observable::Extension::TCP;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::Hex;
use Types::Standard qw(Str InstanceOf);

use Moo;
use namespace::autoclean;

extends 'STIX::Object';

use constant PROPERTIES => (qw[
    src_flags_hex
    dst_flags_hex
]);

use constant EXTENSION_TYPE => 'tcp-ext';

has src_flags_hex => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Hex'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Hex->new($_[0]) }
);

has dst_flags_hex => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Hex'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Hex->new($_[0]) }
);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Extension::TCP - STIX Cyber-observable Object (SCO) - TCP Extension 

=head1 SYNOPSIS

    use STIX::Observable::Extension::TCP;

    my $tcp_ext = STIX::Observable::Extension::TCP->new();


=head1 DESCRIPTION

The TCP extension specifies a default extension for capturing network traffic
properties specific to TCP.


=head2 METHODS

L<STIX::Observable::Extension::TCP> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Observable::Extension::TCP->new(%properties)

Create a new instance of L<STIX::Observable::Extension::TCP>.

=item $tcp_ext->src_flags_hex

Specifies the source TCP flags, as the union of all TCP flags observed between
the start of the traffic (as defined by the start property) and the end of the
traffic (as defined by the end property).

=item $tcp_ext->dst_flags_hex

Specifies the destination TCP flags, as the union of all TCP flags observed
between the start of the traffic (as defined by the start property) and the end
of the traffic (as defined by the end property).

=back


=head2 HELPERS

=over

=item $tcp_ext->TO_JSON

Helper for JSON encoders.

=item $tcp_ext->to_hash

Return the object HASH.

=item $tcp_ext->to_string

Encode the object in JSON.

=item $tcp_ext->validate

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
