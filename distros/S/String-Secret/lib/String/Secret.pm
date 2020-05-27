package String::Secret;
use 5.008001;
use strict;
use warnings;

use Scalar::Util qw/refaddr/;

our $VERSION = "0.01";

use overload
    '""' => 'to_string',
    fallback => 1;

our $DISABLE_MASK = 0;
our $MASKED_STRING = '*' x 8;

my %SECRETS;

sub new {
    my ($class, $secret) = @_;
    my $masked = $MASKED_STRING;
    my $self = bless \$masked, $class;
    $SECRETS{refaddr($self)} = $secret;
    return $self;
}

sub from_serializable { $_[0]->new($_[1]->unwrap) }

sub unwrap { $SECRETS{refaddr($_[0])} }

sub to_serializable {
    require String::Secret::Serializable;
    String::Secret::Serializable->new(shift->unwrap);
}

sub to_string {
    return shift->unwrap if $DISABLE_MASK;
    return $MASKED_STRING;
}

# for Storable
sub STORABLE_freeze {
    my ($self, $cloning) = @_;
    return $self->unwrap if $cloning;
    return $self->to_string;
}
sub STORABLE_thaw {
    my ($self, $cloning, $masked) = @_;
    if ($cloning) {
        $SECRETS{refaddr($self)} = $masked; # $masked is unwrapped value
        return $self;
    }

    die "cannot deserialize it, should convert it as serializable by \$secret->to_serializable";
}

# for JSON modules
sub TO_JSON { shift->to_string }

# for CBOR
sub TO_CBOR { shift->to_string }

# for JSON, CBOR, Sereal, ...
sub FREEZE { shift->to_string }
sub THAW {
    die "cannot deserialize it, should convert it as serializable by \$secret->to_serializable";
}

# for Data::Clone
sub clone { shift } # immutable

sub DESTROY { delete $SECRETS{refaddr($_[0])} }

1;
__END__

=encoding utf-8

=for stopwords serializable

=head1 NAME

String::Secret - secret string wrapper to mask secret from logger

=head1 SYNOPSIS

    use String::Secret;
    use String::Compare::ConstantTime;
    use JSON::PP ();

    my $secret = String::Secret->new('mysecret');

    # safe secret for logging
    MyLogger->warn("invalid secret: $secret"); # oops! but the secret is hidden: "invalid secret: ********"

    # and safe secret for serialization
    # MyLogger->warn("invalid secret: ".JSON::PP->new->allow_tags->encode({ secret => $secret })); # oops! but the secret is hidden: invalid secret: {"secret":"********"}

    unless (String::Compare::ConstantTime::equals($secret->unwrap, SECRET)) {
        die "secret mis-match";
    }

    # and can it convert to serializable
    MyDB->credentials->new(
        id     => 'some id',
        secret => $secret->to_serializable, # or $secret->unwrap
    )->save();


=head1 DESCRIPTION

String::Secret is a secret string wrapper to mask secret from logger.

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

