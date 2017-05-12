# ABSTRACT: Off-the-Record contact's Fingerprint
package Protocol::OTR::Fingerprint;
BEGIN {
  $Protocol::OTR::Fingerprint::AUTHORITY = 'cpan:AJGB';
}
$Protocol::OTR::Fingerprint::VERSION = '0.05';
use strict;
use warnings;

sub _new {
    my ($class, $cnt, $args) = @_;

    my $self = bless $args, $class;
    $self->{cnt} = $cnt;

    return $self;
}

sub contact {
    return $_[0]->{cnt};
}

sub status {
    return $_[0]->{status};
}

sub is_verified {
    return $_[0]->{is_verified};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Protocol::OTR::Fingerprint - Off-the-Record contact's Fingerprint

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
    for my $fingerprint ( $bob->fingerprints() ) {
        print "Fingerprint:\n";
        print " * hash: ",        $fingerprint->hash,        "\n";
        print " * status: ",      $fingerprint->status,      "\n";
        print " * is_verified: ", $fingerprint->is_verified, "\n";
    }

=head1 DESCRIPTION

L<Protocol::OTR::Fingerprint> represents the fingerprint for OTR contact.

=head1 METHODS

=head2 contact

    my $contact = $fingerprint->contact();

Returns fingerprint's L<Protocol::OTR::Contact> object.

=head2 hash

    my $hash = $fingerprint->hash();

Returns fingerprint's hash in human readable format
C<12345678 90ABCDEF 12345678 90ABCDEF 12345678>.

=head2 status

    my $status = $fingerprint->status;

Returns current status of fingerprint used in communication, which is one of:

=over 4

=item * Unused

=item * Not private

=item * Unverified

=item * Private

=item * Finished

=back

=head2 is_verified

    my $is_verified = $fingerprint->is_verified;

Returns true if current fingerprint is verified, false otherwise.

=head2 set_verified

    $fingerprint->set_verified( $true_or_false );

Sets fingerprint as verified or not.

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
