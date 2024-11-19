package STIX::Common::Enum;

use 5.010001;
use strict;
use warnings;
use utf8;

use constant ENCRYPTION_ALGORITHM => ('AES-256-GCM', 'ChaCha20-Poly1305', 'mime-type-indicated');

use constant EXTENSION_TYPE => ('new-sdo', 'new-sco', 'new-sro', 'property-extension', 'toplevel-property-extension');

use constant NETWORK_SOCKET_ADDRESS_FAMILY =>
    ('AF_UNSPEC', 'AF_INET', 'AF_IPX', 'AF_APPLETALK', 'AF_NETBIOS', 'AF_INET6', 'AF_IRDA', 'AF_BTH');

use constant NETWORK_SOCKET_TYPE => ('SOCK_STREAM', 'AF_ISOCK_DGRAMNET', 'SOCK_RAW', 'SOCK_RDM', 'SOCK_SEQPACKET');

use constant OPINION => ('strongly-disagree', 'disagree', 'neutral', 'agree', 'strongly-agree');

use constant WINDOWS_INTEGRITY_LEVEL => ('low', 'medium', 'high', 'system');

use constant WINDOWS_REGISTRY_DATATYPE => (
    'REG_NONE',                      'REG_SZ',
    'REG_EXPAND_SZ',                 'REG_BINARY',
    'REG_DWORD',                     'REG_DWORD_BIG_ENDIAN',
    'REG_DWORD_LITTLE_ENDIAN',       'REG_LINK',
    'REG_MULTI_SZ',                  'REG_RESOURCE_LIST',
    'REG_FULL_RESOURCE_DESCRIPTION', 'REG_RESOURCE_REQUIREMENTS_LIST',
    'REG_QWORD',                     'REG_INVALID_TYPE'
);

use constant WINDOWS_SERVICE_TYPE => (
    'SERVICE_KERNEL_DRIVER',     'SERVICE_FILE_SYSTEM_DRIVER',
    'SERVICE_WIN32_OWN_PROCESS', 'SERVICE_WIN32_SHARE_PROCESS'
);

use constant WINDOWS_SERVICE_START_TYPE =>
    ('SERVICE_AUTO_START', 'SERVICE_BOOT_START', 'SERVICE_DEMAND_START', 'SERVICE_DISABLED', 'SERVICE_SYSTEM_ALERT');

use constant WINDOWS_SERVICE_STATUS => (
    'SERVICE_CONTINUE_PENDING', 'SERVICE_PAUSE_PENDING', 'SERVICE_PAUSED', 'SERVICE_RUNNING',
    'SERVICE_START_PENDING',    'SERVICE_STOP_PENDING',  'SERVICE_STOPPED'
);

1;

=encoding utf-8

=head1 NAME

STIX::Common::Enum - ENUM for STIX Objects

=head1 DESCRIPTION

L<STIX::Common::Enum> provide a listing of common and industry accepted
terms as a guide to the user. 

=head2 CONSTANTS

=over

=item ENCRYPTION_ALGORITHM

=item EXTENSION_TYPE

=item NETWORK_SOCKET_ADDRESS_FAMILY

=item NETWORK_SOCKET_TYPE

=item OPINION

=item WINDOWS_INTEGRITY_LEVEL

=item WINDOWS_REGISTRY_DATATYPE

=item WINDOWS_SERVICE_START_TYPE

=item WINDOWS_SERVICE_STATUS

=item WINDOWS_SERVICE_TYPE

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
