package SOAP::GenericHashSerializer;

use strict;
use vars qw($VERSION);
use SOAP::Defs;
use SOAP::Serializer;

$VERSION = '0.28';

sub new {
    my ($class, $hash) = @_;
    
    my $self = {
        hash => $hash,
    };
    bless $self, $class;
}

my $g_intrusive_hash_keys = {
    $soapperl_intrusive_hash_key_typeuri  => undef,
    $soapperl_intrusive_hash_key_typename => undef,
};

sub serialize {
    my ($self, $stream, $envelope) = @_;

    my $hash = $self->{hash};

    while (my ($k, $v) = each %$hash) {
        next if exists $g_intrusive_hash_keys->{$k};
	_serialize_object($stream, $envelope, undef, $k, $v);
    }
}

sub is_compound {
    1;
}

sub is_multiref {
    1;
}

sub is_package {
    0;
}

sub get_typeinfo {
    my $self = shift;
    my $hash = $self->{hash};

    my $typeuri  = exists $hash->{$soapperl_intrusive_hash_key_typeuri} ?
                          $hash->{$soapperl_intrusive_hash_key_typeuri} : undef;

    my $typename = exists $hash->{$soapperl_intrusive_hash_key_typename} ?
                          $hash->{$soapperl_intrusive_hash_key_typename} : undef;

    ($typeuri, $typename);
}

1;
__END__


=head1 NAME

SOAP::GenericHashSerializer - Generic serializer for Perl hashes

=head1 SYNOPSIS

=head1 DESCRIPTION

Serializes a vanilla Perl hash to a SOAP::OutputStream.
Note that Perl hashes are unordered, so the serialization order
is not guaranteed. Use SOAP::Struct as opposed to a hash if you
need to preserve order (this is actually a requirement of the
SOAP spec).

=head1 DEPENDENCIES

SOAP::Serializer

=head1 AUTHOR

Keith Brown

=cut
