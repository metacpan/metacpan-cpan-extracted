package STIX::Observable::UserAccount;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::OpenVocabulary;
use Types::Standard qw(Str Bool Enum InstanceOf);

use Moo;
use namespace::autoclean;

extends 'STIX::Observable';

use constant SCHEMA =>
    'http://raw.githubusercontent.com/oasis-open/cti-stix2-json-schemas/stix2.1/schemas/observables/user-account.json';

use constant PROPERTIES => (
    qw(type id),
    qw(spec_version object_marking_refs granular_markings defanged extensions),
    qw(user_id credential account_login account_type display_name is_service_account is_privileged can_escalate_privs is_disabled account_created account_expires credential_last_changed account_first_login account_last_login),
);

use constant STIX_OBJECT      => 'SCO';
use constant STIX_OBJECT_TYPE => 'user-account';

has user_id            => (is => 'rw', isa => Str);
has credential         => (is => 'rw', isa => Str);
has account_login      => (is => 'rw', isa => Str);
has account_type       => (is => 'rw', isa => Enum [STIX::Common::OpenVocabulary->ACCOUNT_TYPE()]);
has display_name       => (is => 'rw', isa => Str);
has is_service_account => (is => 'rw', isa => Bool);
has is_privileged      => (is => 'rw', isa => Bool);
has can_escalate_privs => (is => 'rw', isa => Bool);
has is_disabled        => (is => 'rw', isa => Bool);

has account_created => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has account_expires => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has credential_last_changed => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has account_first_login => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

has account_last_login => (
    is     => 'rw',
    isa    => InstanceOf ['STIX::Common::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : STIX::Common::Timestamp->new($_[0]) },
);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::UserAccount - STIX Cyber-observable Object (SCO) - User Account

=head1 SYNOPSIS

    use STIX::Observable::UserAccount;

    my $user_account = STIX::Observable::UserAccount->new();


=head1 DESCRIPTION

The User Account Object represents an instance of any type of user account,
including but not limited to operating system, device, messaging service,
and social media platform accounts.


=head2 METHODS

L<STIX::Observable::UserAccount> inherits all methods from L<STIX::Observable>
and implements the following new ones.

=over

=item STIX::Observable::UserAccount->new(%properties)

Create a new instance of L<STIX::Observable::UserAccount>.

=item $user_account->account_created

Specifies when the account was created.

=item $user_account->account_expires

Specifies the expiration date of the account.

=item $user_account->account_first_login

Specifies when the account was first accessed.

=item $user_account->account_last_login

Specifies when the account was last accessed.

=item $user_account->account_login

Specifies the account login string, used in cases where the user_id
property specifies something other than what a user would type when they
login.

=item $user_account->account_type

Specifies the type of the account. This is an open vocabulary and values
SHOULD come from the account-type-ov vocabulary.

=item $user_account->can_escalate_privs

Specifies that the account has the ability to escalate privileges (i.e., in
the case of sudo on Unix or a Windows Domain Admin account).

=item $user_account->credential

Specifies a cleartext credential. This is only intended to be used in
capturing metadata from malware analysis (e.g., a hard-coded domain
administrator password that the malware attempts to use for lateral
movement) and SHOULD NOT be used for sharing of PII.

=item $user_account->credential_last_changed

Specifies when the account credential was last changed.

=item $user_account->display_name

Specifies the display name of the account, to be shown in user interfaces,
if applicable.

=item $user_account->extensions

The User Account Object defines the following extensions. In addition to
these, producers MAY create their own. Extensions: unix-account-ext.

=item $user_account->id

=item $user_account->is_disabled

Specifies if the account is disabled.

=item $user_account->is_privileged

Specifies that the account has elevated privileges (i.e., in the case of
root on Unix or the Windows Administrator account).

=item $user_account->is_service_account

Indicates that the account is associated with a network service or system
process (daemon), not a specific individual.

=item $user_account->type

The value of this property MUST be C<user-account>.

=item $user_account->user_id

Specifies the identifier of the account.

=back


=head2 HELPERS

=over

=item $user_account->TO_JSON

Encode the object in JSON.

=item $user_account->to_hash

Return the object HASH.

=item $user_account->to_string

Encode the object in JSON.

=item $user_account->validate

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
