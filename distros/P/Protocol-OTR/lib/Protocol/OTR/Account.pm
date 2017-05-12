# ABSTRACT: Off-the-Record Account (private key)
package Protocol::OTR::Account;
BEGIN {
  $Protocol::OTR::Account::AUTHORITY = 'cpan:AJGB';
}
$Protocol::OTR::Account::VERSION = '0.05';
use strict;
use warnings;
use Protocol::OTR::Contact ();
use Params::Validate qw(validate validate_pos SCALAR BOOLEAN);

sub _new {
    my ($class, $otr, $args, $find_only) = @_;

    my $m = $find_only ? "_find_account" : "_account";

    $args->{fingerprint} = $otr->$m( $args->{name}, $args->{protocol} );

    return unless $args->{fingerprint};

    my $self = bless $args, $class;
    $self->{otr} = $otr;

    return $self;
}

sub ctx {
    return $_[0]->{otr};
}

sub name {
    return $_[0]->{name};
}

sub protocol {
    return $_[0]->{protocol};
}

sub fingerprint {
    return $_[0]->{fingerprint};
}

sub contact {
    my $self = shift;

    my ($name, $fingerprint, $is_verified) = validate_pos(
        @_,
        {
            type => SCALAR,
        },
        {
            type => SCALAR,
            optional => 1,
        },
        {
            type => BOOLEAN,
            optional => 1,
        }
    );

    return Protocol::OTR::Contact->_new(
        $self,
        {
            name => $name,
            fingerprint => $fingerprint,
            is_verified => $is_verified,
        }
    );
}

sub contacts {
    my ($self) = @_;

    return map {
        Protocol::OTR::Contact->_new($self, { name => $_ } )
    } @{ $self->_contacts() }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Protocol::OTR::Account - Off-the-Record Account (private key)

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

    print "Account:\n";
    print " * name: ",        $alice->name,        "\n";
    print " * protocol: ",    $alice->protocol,    "\n";
    print " * fingerprint: ", $alice->fingerprint, "\n";

    # find or create contact known by $alice
    my $bob = $alice->contact('bob@domain');

    # return all known by $alice contacts
    my @contacts = $alice->contacts();

=head1 DESCRIPTION

L<Protocol::OTR::Account> represents the OTR account (private key).

=head1 METHODS

=head2 ctx

    my $otr = $account->ctx();

Returns account's context.

=head2 name

    my $name = $account->name();

Returns account's name.

=head2 protocol

    my $protocol = $account->protocol();

Returns account's protocol.

=head2 fingerprint

    my $fingerprint = $account->fingerprint();

Returns account's fingerprint in human readable format
C<12345678 90ABCDEF 12345678 90ABCDEF 12345678>.

=head2 contact

    my $contact = $account->contact( $name, [ $fingerprint, [ $is_verified ]]);

Returns existing or creates new L<Protocol::OTR::Contact> object.

If C<$fingeprint> is set for contact, it will be set as C<verified> if
C<$is_verified> is true.

Note: it is allowed to use a string of 40 chars or human readable format (44 chars).

=head2 contacts

    my @contacts = $account->contacts();

Returns a list of known contact objects L<Protocol::OTR::Contact>.

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
