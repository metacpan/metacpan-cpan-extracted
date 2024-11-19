package STIX::Observable::Extension::UnixAccount;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'STIX::Object';

use constant PROPERTIES => (qw[
    gid
    groups
    home_dir
    shell
]);

use constant EXTENSION_TYPE => 'unix-account-ext';

has gid      => (is => 'rw', isa => Str);
has groups   => (is => 'rw', isa => ArrayLike [Str], default => sub { STIX::Common::List->new });
has home_dir => (is => 'rw', isa => Str);
has shell    => (is => 'rw', isa => Str);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Extension::UnixAccount - STIX Cyber-observable Object (SCO) - UNIX Account Extension

=head1 SYNOPSIS

    use STIX::Observable::Extension::UnixAccount;

    my $unix_account_ext = STIX::Observable::Extension::UnixAccount->new();


=head1 DESCRIPTION

The User Account Object defines the following extensions. In addition to these,
producers MAY create their own.


=head2 METHODS

L<STIX::Observable::Extension::UnixAccount> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Observable::Extension::UnixAccount->new(%properties)

Create a new instance of L<STIX::Observable::Extension::UnixAccount>.

=item $unix_account_ext->gid

Specifies the primary group ID of the account.

=item $unix_account_ext->groups

Specifies a list of names of groups that the account is a member of.

=item $unix_account_ext->home_dir

Specifies the home directory of the account.

=item $unix_account_ext->shell

Specifies the account’s command shell.

=back


=head2 HELPERS

=over

=item $unix_account_ext->TO_JSON

Helper for JSON encoders.

=item $unix_account_ext->to_hash

Return the object HASH.

=item $unix_account_ext->to_string

Encode the object in JSON.

=item $unix_account_ext->validate

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
