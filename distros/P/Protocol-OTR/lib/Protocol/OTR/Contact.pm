# ABSTRACT: Off-the-Record Contact
package Protocol::OTR::Contact;
BEGIN {
  $Protocol::OTR::Contact::AUTHORITY = 'cpan:AJGB';
}
$Protocol::OTR::Contact::VERSION = '0.05';
use strict;
use warnings;
use Protocol::OTR ();
use Protocol::OTR::Fingerprint ();
use Protocol::OTR::Channel ();
use Params::Validate qw(validate CODEREF);

sub _new {
    my ($class, $act, $args) = @_;

    $act->_contact( @$args{qw( name fingerprint is_verified )} );

    my $self = bless $args, $class;
    $self->{act} = $act;

    return $self;
}

sub account {
    return $_[0]->{act};
}

sub name {
    return $_[0]->{name};
}

sub fingerprints {
    my ($self) = @_;

    return map {
        Protocol::OTR::Fingerprint->_new($self, $_)
    } @{ $self->_fingerprints() }
}

sub active_fingerprint {
    my ($self) = @_;

    if ( my $fprint = $self->_active_fingerprint() ) {
        return Protocol::OTR::Fingerprint->_new($self, $fprint);
    };

    return;
}

sub channel {
    my $self = shift;

    my %args = validate(
        @_,
        {
            policy => {
                optional => 1,
                default => Protocol::OTR::POLICY_OPPORTUNISTIC(),
            },
            max_message_size => {
                optional => 1,
                default => 0,
            },
            on_read => {
                type => CODEREF,
            },
            on_write => {
                type => CODEREF,
            },
            on_gone_secure => {
                optional => 1,
                type => CODEREF,
            },
            on_gone_insecure => {
                optional => 1,
                type => CODEREF,
            },
            on_still_secure => {
                optional => 1,
                type => CODEREF,
            },
            on_unverified_fingerprint => {
                optional => 1,
                type => CODEREF,
            },
            on_symkey => {
                optional => 1,
                type => CODEREF,
            },
            on_timer => {
                optional => 1,
                type => CODEREF,
            },
            on_smp => {
                optional => 1,
                type => CODEREF,
            },
            on_error => {
                optional => 1,
                type => CODEREF,
            },
            on_event => {
                optional => 1,
                type => CODEREF,
            },
            on_smp_event => {
                optional => 1,
                type => CODEREF,
            },
            on_before_encrypt => {
                optional => 1,
                type => CODEREF,
            },
            on_after_decrypt => {
                optional => 1,
                type => CODEREF,
            },
            on_is_contact_logged_in => {
                optional => 1,
                type => CODEREF,
            },
        }
    );

    return Protocol::OTR::Channel->_new($self, \%args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Protocol::OTR::Contact - Off-the-Record Contact

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use Protocol::OTR qw( :constants );

    my $otr = Protocol::OTR->new(
        {
            privkeys_file => "otr.private_key",
            contacts_file => "otr.fingerprints",
            instance_tags_file => "otr.instance_tags",
        }
    );

    # find or create account
    my $alice = $otr->account('alice@domain', 'prpl-jabber');

    # find or create contact known by $alice
    my $bob = $alice->contact('bob@domain');

    # return all $bob's fingerprints
    my @fingerprints = $bob->fingerprints();

    # current active fingerprint
    my $active_fingerprint = $bob->active_fingerprint();

    # create secure channel to Bob
    my $channel = $bob->channel(
        {
            policy => ...,
            max_message_size => ...,
            on_write => sub { ... },
            on_read => sub { ... },
            on_gone_secure => sub { ... },
            on_gone_insecure => sub { ... },
            on_still_secure => sub { ... },
            on_unverified_fingerprint => sub { ... },
            on_symkey => sub { ... },
            on_timer => sub { ... },
            on_smp => sub { ... },
            on_error => sub { ... },
            on_event => sub { ... },
            on_smp_event => sub { ... },
            on_before_encrypt => sub { ... },
            on_after_decrypt => sub { ... },
            on_is_contact_logged_in => sub { ... },
        }
    );

=head1 DESCRIPTION

L<Protocol::OTR::Contact> represents the OTR contact.

=head1 METHODS

=head2 account

    my $account = $contact->account();

Returns contact's L<Protocol::OTR::Account> object.

=head2 name

    my $name = $contact->name();

Returns contact's name.

=head2 fingerprints

    my @fingerprints = $contact->fingerprints();

Returns a list of fingerprint objects L<Protocol::OTR::Fingerprint>
for given contact.

=head2 active_fingerprint

    my $active_fingerprint = $contact->active_fingerprint();

Returns currently used fingerprint objects L<Protocol::OTR::Fingerprint> for that contact.

=head2 channel

    my $channel = $contact->channel(
        {
            policy => ...,
            max_message_size => ...,
            on_write => sub { ... },
            on_read => sub { ... },
            on_gone_secure => sub { ... },
            on_gone_insecure => sub { ... },
            on_still_secure => sub { ... },
            on_unverified_fingerprint => sub { ... },
            on_symkey => sub { ... },
            on_timer => sub { ... },
            on_smp => sub { ... },
            on_error => sub { ... },
            on_event => sub { ... },
            on_smp_event => sub { ... },
            on_before_encrypt => sub { ... },
            on_after_decrypt => sub { ... },
            on_is_contact_logged_in => sub { ... },
        }
    );

Create secure channel with that contact.

Please see L<Protocol::OTR::Channel> for callbacks description.

=head1 SEE ALSO

=over 4

=item * L<Protocol::OTR>

=item * L<Protocol::OTR::Account>

=item * L<Protocol::OTR::Contact>

=item * L<Protocol::OTR::Fingerprint>

=item * L<Protocol::OTR::Channel>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
