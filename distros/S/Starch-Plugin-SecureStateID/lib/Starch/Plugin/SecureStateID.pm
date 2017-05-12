package Starch::Plugin::SecureStateID;
$Starch::Plugin::SecureStateID::VERSION = '0.001';
# ABSTRACT: use cryptographically secure random when making state IDs

use Math::Random::Secure ();
use Digest::SHA ();
use Scalar::Util qw( refaddr );
use Types::Standard -types;

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Plugin::ForManager
);

has secure_state_id_sha => (
    is          => 'ro',
    isa         => Enum[1, 224, 256, 384, 512, 512224, 512256],
    default     => 256,
);

sub _secure_state_id_sha {
    my $self = shift;
    Digest::SHA->new($self->secure_state_id_sha);
}

my $counter = 0;
around state_id_seed => sub {
    shift; # we never call the original
    my ($self) = @_;
    return join( '', ++$counter, time, Math::Random::Secure::rand(), $$, {}, refaddr($self) )
};

around generate_state_id => sub {
    shift; # we never call the original
    my ($self) = @_;
    my $sha = $self->_secure_state_id_sha;
    $sha->add( $self->state_id_seed() );
    return $sha->hexdigest();
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Starch::Plugin::SecureStateID - use cryptographically secure random when making state IDs

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $starch = Starch->new(
        plugins             => ['::SecureStateID'],
        secure_state_id_sha => 256,
    );

=head1 DESCRIPTION

For each state stored in Starch, the generated ID is virtually guaranteed to be unique. It is not generated to be unguessable. By using this plugin, the state will include a random number generated using L<Math::Random::Secure> to assure that is both unique and includes a cryptographically secure random number in the calculated ID.

This plugin also upgrades the state ID so that it is calculated using SHA-256 instead of SHA-1. SHA-1 hashed values are potentially guessable for attackers with a large enough budget. A possible downside is that SHA-256 creates a key that is 256 bits long, which results in an ID string that is 64 bytes long, rather than the 40 byte long string provided by SHA-1. The version of SHA used may be chosen with the L</secure_state_id_sha> option.

=head1 OPTIONAL MANAGER ARGUMENTS

These arguments are added to the L<Starch::Manager> class.

=head2 secure_state_id_sha

This names the SHA algorithm to use. It may be set to one of: 1, 224, 256, 284, 512224, and 512256. The default is 256 (though, if you do not use this plugin, SHA-1 will be used).

=head1 AUTHORS AND LICENSE

Copyright 2016 Sterling Hanenkamp C<< hanenkamp@cpan.org >>.

This is free software distributed under the same terms as Perl itself.

Special thanks to ZipRecruiter, Inc. without whom this software would not exist
and would not be available to the Open Source community.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Andrew Sterling Hanenkamp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
