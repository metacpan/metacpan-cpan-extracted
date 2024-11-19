package STIX::Observable::Extension::WindowsProcess;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::Enum;
use Types::Standard qw(Str Bool Enum HashRef);

use Moo;
use namespace::autoclean;

extends 'STIX::Object';

use constant PROPERTIES => (qw[
    aslr_enabled
    dep_enabled
    priority
    owner_sid
    window_title
    startup_info
    integrity_level
]);

use constant EXTENSION_TYPE => 'windows-process-ext';

has aslr_enabled    => (is => 'rw', isa => Bool);
has dep_enabled     => (is => 'rw', isa => Bool);
has priority        => (is => 'rw', isa => Str);
has owner_sid       => (is => 'rw', isa => Str);
has window_title    => (is => 'rw', isa => Str);
has startup_info    => (is => 'rw', isa => HashRef);
has integrity_level => (is => 'rw', isa => Enum [STIX::Common::Enum->WINDOWS_INTEGRITY_LEVEL()]);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Extension::WindowsProcess - STIX Cyber-observable Object (SCO) - Windows Process Extension

=head1 SYNOPSIS

    use STIX::Observable::Extension::WindowsProcess;

    my $windows_process_ext = STIX::Observable::Extension::WindowsProcess->new();


=head1 DESCRIPTION

The Windows Process extension specifies a default extension for capturing
properties specific to Windows processes.


=head2 METHODS

L<STIX::Observable::Extension::WindowsProcess> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Observable::Extension::WindowsProcess->new(%properties)

Create a new instance of L<STIX::Observable::Extension::WindowsProcess>.

=item $windows_process_ext->aslr_enabled

Specifies whether Address Space Layout Randomization (ASLR) is enabled for the process.

=item $windows_process_ext->dep_enabled

Specifies whether Data Execution Prevention (DEP) is enabled for the process.

=item $windows_process_ext->priority

Specifies the current priority class of the process in Windows.

=item $windows_process_ext->owner_sid

Specifies the Security ID (SID) value of the owner of the process.

=item $windows_process_ext->window_title

Specifies the title of the main window of the process.

=item $windows_process_ext->startup_info

Specifies the STARTUP_INFO struct used by the process, as a dictionary.

=item $windows_process_ext->integrity_level

Specifies the Windows integrity level, or trustworthiness, of the process
(see C<WINDOWS_INTEGRITY_LEVEL> in L<STIX::Common::Enum>).

=back


=head2 HELPERS

=over

=item $windows_process_ext->TO_JSON

Helper for JSON encoders.

=item $windows_process_ext->to_hash

Return the object HASH.

=item $windows_process_ext->to_string

Encode the object in JSON.

=item $windows_process_ext->validate

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
