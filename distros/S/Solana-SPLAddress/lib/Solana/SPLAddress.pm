package Solana::SPLAddress;

use 5.034000;
use strict;
use warnings;

our $VERSION = '0.06';
use Carp qw(croak);
use constant PDA_MAKER => "ProgramDerivedAddress";
use Digest::SHA;

require XSLoader;
XSLoader::load('Solana::SPLAddress', $VERSION);

sub find_address {
    my ($seeds, $program_id) = @_;

    for my $bump ( reverse(0..255) ) {
        my $address = create_address($seeds, $bump, $program_id);
        if (defined $address) {
            return ($address, $bump);
        }
    }
    croak "Failed to generate SPL address";
}

sub create_address {
    my ($seeds, $bump, $program_id) = @_;
    my $sha = Digest::SHA->new(256);
    for my $seed (@$seeds) {
        $sha->add($seed);
    }
    $sha->add(pack("C", $bump));
    $sha->add($program_id);
    $sha->add(PDA_MAKER);

    my $hash = $sha->digest;
    if (!check_pub_address_is_ok($hash)) {
        return unpack('H*', $hash);
    }
    return undef;
}

1;
__END__

=head1 NAME

Solana::SPLAddress - Perl extension for creating deterministic Solana token addresses

=head1 SYNOPSIS

  use Solana::SPLAddress;

=head1 METHODS

=over 4

=item create_address($seed, $program_id, $bump)

    create address from seed, program_id and bump
    used to recover already generated address

=item find_address($seeds, $program_id)

    find address from seeds and program_id
    returns address and bump

=cut

=back

=head1 AUTHOR

Denys Fisher, E<lt>shmakins at gmail dot comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Denys Fisher

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.38.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
