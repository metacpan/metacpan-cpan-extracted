package STIX::Observable::Process;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::List;
use Types::Standard qw(Str Bool HashRef Int InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Observable';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/process.json';

use constant PROPERTIES => (
    qw(type id),
    qw(spec_version object_marking_refs granular_markings defanged extensions),
    qw(is_hidden pid created_time cwd command_line environment_variables opened_connection_refs creator_user_ref image_ref parent_ref child_refs),
);

use constant STIX_OBJECT      => 'SCO';
use constant STIX_OBJECT_TYPE => 'process';

has is_hidden => (is => 'rw', isa => Bool);
has pid       => (is => 'rw', isa => Int);

has created_time => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has cwd                   => (is => 'rw', isa => Str);
has command_line          => (is => 'rw', isa => Str);
has environment_variables => (is => 'rw', isa => HashRef);

has opened_connection_refs => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Observable::NetworkTraffic', 'STIX::Common::Identifier']],
    default => sub { STIX::Common::List->new }
);

has creator_user_ref => (is => 'rw', isa => InstanceOf ['STIX::Observable::UserAccount', 'STIX::Common::Identifier']);
has image_ref        => (is => 'rw', isa => InstanceOf ['STIX::Observable::File',        'STIX::Common::Identifier']);
has parent_ref       => (is => 'rw', isa => InstanceOf ['STIX::Observable::Process',     'STIX::Common::Identifier']);

has child_refs => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Observable::Process', 'STIX::Common::Identifier']],
    default => sub { STIX::Common::List->new }
);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Process - STIX Cyber-observable Object (SCO) - Process

=head1 SYNOPSIS

    use STIX::Observable::Process;

    my $process = STIX::Observable::Process->new();


=head1 DESCRIPTION

The Process Object represents common properties of an instance of a
computer program as executed on an operating system.


=head2 METHODS

L<STIX::Observable::Process> inherits all methods from L<STIX::Observable>
and implements the following new ones.

=over

=item STIX::Observable::Process->new(%properties)

Create a new instance of L<STIX::Observable::Process>.

=item $process->child_refs

Specifies the other processes that were spawned by (i.e. children of) this
process, as a reference to one or more other Process Objects.

=item $process->command_line

Specifies the full command line used in executing the process, including
the process name (which may be specified individually via the
binary_ref.name property) and any arguments.

=item $process->created_time

Specifies the date/time at which the process was created.

=item $process->creator_user_ref

Specifies the user that created the process, as a reference to a User
Account Object.

=item $process->cwd

Specifies the current working directory of the process.

=item $process->environment_variables

Specifies the list of environment variables associated with the process as
a dictionary.

=item $process->extensions

The Process Object defines the following extensions. In addition to these,
producers MAY create their own. Extensions: windows-process-ext,
windows-service-ext.

=item $process->id

=item $process->image_ref

Specifies the executable binary that was executed as the process image, as
a reference to a File Object.

=item $process->is_hidden

Specifies whether the process is hidden.

=item $process->opened_connection_refs

Specifies the list of network connections opened by the process, as a
reference to one or more Network Traffic Objects.

=item $process->parent_ref

Specifies the other process that spawned (i.e. is the parent of) this one,
as represented by a Process Object.

=item $process->pid

Specifies the Process ID, or PID, of the process.

=item $process->type

The value of this property MUST be C<process>.

=back


=head2 HELPERS

=over

=item $process->TO_JSON

Encode the object in JSON.

=item $process->to_hash

Return the object HASH.

=item $process->to_string

Encode the object in JSON.

=item $process->validate

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
