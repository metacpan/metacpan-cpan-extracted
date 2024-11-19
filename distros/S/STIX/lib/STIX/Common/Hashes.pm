package STIX::Common::Hashes;

use 5.010001;
use strict;
use warnings;
use utf8;

use Cpanel::JSON::XS;
use Types::Standard qw(Str);

use Moo;
use namespace::autoclean;

extends 'STIX::Object';

use constant PROPERTIES => (qw[
    md5
    sha_1
    sha_256
    sha_512
    sha3_256
    sha3_512
    ssdeep
    tlsh
]);

around BUILDARGS => sub {

    my ($orig, $class, %params) = @_;
    my %hashes = map { _normalize_hash_type($_) => $params{$_} } keys %params;

    return \%hashes;

};

sub _normalize_hash_type {
    my $type = shift;
    $type =~ s/-/_/g;
    return lc $type;
}

has md5      => (is => 'rw', isa => Str);
has sha_1    => (is => 'rw', isa => Str);
has sha_256  => (is => 'rw', isa => Str);
has sha_512  => (is => 'rw', isa => Str);
has sha3_256 => (is => 'rw', isa => Str);
has sha3_512 => (is => 'rw', isa => Str);
has ssdeep   => (is => 'rw', isa => Str);
has tlsh     => (is => 'rw', isa => Str);

sub TO_JSON {

    my $self   = shift;
    my $hashes = {};

    $hashes->{'md5'}      = $self->md5      if ($self->md5);
    $hashes->{'sha-1'}    = $self->sha_1    if ($self->sha_1);
    $hashes->{'sha-256'}  = $self->sha_256  if ($self->sha_256);
    $hashes->{'sha-512'}  = $self->sha_512  if ($self->sha_512);
    $hashes->{'sha3-256'} = $self->sha3_256 if ($self->sha3_256);
    $hashes->{'sha3-512'} = $self->sha3_512 if ($self->sha3_512);
    $hashes->{'ssdeep'}   = $self->ssdeep   if ($self->ssdeep);
    $hashes->{'tlsh'}     = $self->tlsh     if ($self->tlsh);

    return $hashes;

}

sub to_hash { shift->TO_JSON }

sub to_string {

    my $self = shift;

    my $json = Cpanel::JSON::XS->new->utf8->canonical->allow_nonref->allow_unknown->allow_blessed->convert_blessed
        ->stringify_infnan->escape_slash(0)->allow_dupkeys->pretty;

    return $json->encode($self->TO_JSON);

}

1;

=encoding utf-8

=head1 NAME

STIX::Common::Hashes - Hashes type

=head1 SYNOPSIS

    use STIX::Common::Hashes;

    my $hashes = STIX::Common::Hashes->new(md5 => '...', sha_1 => '...');


=head1 DESCRIPTION

The Hashes type represents one or more cryptographic hashes, as a special set of
key/value pairs. Accordingly, the name of each hashing algorithm MUST be specified
as a key in the dictionary and MUST identify the name of the hashing algorithm
used to generate the corresponding value.

=head2 PROPERTIES

=over

=item md5

=item sha_1

=item sha_256

=item sha_512

=item sha3_256

=item sha3_512

=item ssdeep

=item tlsh


=back

=head2 HELPERS

=over

=item $hashes->TO_JSON

Encode the object in JSON.

=item $hashes->to_hash

Return the object HASH.

=item $hashes->to_string

Encode the object in JSON.

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
