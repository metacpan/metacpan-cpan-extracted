package STIX::Observable::Extension::WindowsService;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::Enum;
use Types::Standard qw(Str InstanceOf Enum);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Object';

use constant PROPERTIES => (qw[
    service_name
    descriptions
    display_name
    group_name
    start_type
    service_dll_refs
    service_type
    service_status
]);

use constant EXTENSION_TYPE => 'windows-service-ext';

has service_name => (is => 'rw', isa => Str);
has descriptions => (is => 'rw', isa => ArrayLike [Str], default => sub { STIX::Common::List->new });
has display_name => (is => 'rw', isa => Str);
has group_name   => (is => 'rw', isa => Str);
has start_type   => (is => 'rw', isa => Enum [STIX::Common::Enum->WINDOWS_SERVICE_START_TYPE()]);
has service_dll_refs => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['STIX::Observable::File']],
    default => sub { STIX::Common::List->new }
);
has service_type   => (is => 'rw', isa => Enum [STIX::Common::Enum->WINDOWS_SERVICE_TYPE()]);
has service_status => (is => 'rw', isa => Enum [STIX::Common::Enum->WINDOWS_SERVICE_STATUS()]);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Extension::WindowsService - STIX Cyber-observable Object (SCO) - Windows Service Extension

=head1 SYNOPSIS

    use STIX::Observable::Extension::WindowsService;

    my $windows_service_ext = STIX::Observable::Extension::WindowsService->new();


=head1 DESCRIPTION

The Windows Service extension specifies a default extension for capturing
properties specific to Windows services.


=head2 METHODS

L<STIX::Observable::Extension::WindowsService> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Observable::Extension::WindowsService->new(%properties)

Create a new instance of L<STIX::Observable::Extension::WindowsService>.

=item $windows_service_ext->service_name

Specifies the name of the service.

=item $windows_service_ext->descriptions

Specifies the descriptions defined for the service.

=item $windows_service_ext->display_name

Specifies the displayed name of the service in Windows GUI controls.

=item $windows_service_ext->group_name

Specifies the name of the load ordering group of which the service is a member.

=item $windows_service_ext->start_type

Specifies the start options defined for the service
(see C<WINDOWS_SERVICE_START_TYPE> in L<STIX::Common::Enum>).

=item $windows_service_ext->service_dll_refs

Specifies the DLLs loaded by the service, as a reference to one or more L<STIX::Observable::File> Objects.

=item $windows_service_ext->service_type

Specifies the type of the service (see C<WINDOWS_SERVICE_TYPE> in L<STIX::Common::Enum>).

=item $windows_service_ext->service_status

Specifies the current status of the service (see C<WINDOWS_SERVICE_STATUS> in L<STIX::Common::Enum>).

=back


=head2 HELPERS

=over

=item $windows_service_ext->TO_JSON

Helper for JSON encoders.

=item $windows_service_ext->to_hash

Return the object HASH.

=item $windows_service_ext->to_string

Encode the object in JSON.

=item $windows_service_ext->validate

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
