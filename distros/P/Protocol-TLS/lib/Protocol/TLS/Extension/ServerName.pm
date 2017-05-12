package Protocol::TLS::Extension::ServerName;
use strict;
use warnings;
use Carp;
use Protocol::TLS::Trace qw(tracer);

# RFC 6066 - server_name extension

my %name_types = (
    0 => {
        decode => \&host_name_decode,
        encode => \&host_name_encode,
    },
);

sub new {
    bless {}, shift;
}

sub type {
    0x0;
}

sub name {
    'server_name';
}

sub decode {
    my ( $self, $ctx, $result_ref, $buf_ref, $buf_offset, $length ) = @_;
    return undef if $length < 2;

    my $l = unpack 'n', substr $$buf_ref, $buf_offset, 2;
    my $offset = 2;

    while ( $offset - 2 + 1 < $l ) {
        my $name_type = unpack 'C', substr $$buf_ref, $buf_offset + $offset, 1;
        $offset += 1;

        if ( exists $name_types{$name_type} ) {
            my $len = $name_types{$name_type}{decode}->(
                $ctx, \$$result_ref->{$name_type},
                $buf_ref,
                $buf_offset + $offset,
                $l - $offset
            );
            return undef unless defined $len;
            $offset += $len;
        }
    }
    return $offset;
}

sub host_name_decode {
    my ( $ctx, $result_ref, $buf_ref, $buf_offset, $length ) = @_;
    my $l = unpack 'n', substr $$buf_ref, $buf_offset, 2;
    return undef if $l > $length;
    $$result_ref = substr $$buf_ref, $buf_offset + 2, $l;
    return $l + 2;
}

sub host_name_encode {
    croak "not implemented";
}

sub encode {
    croak "not implemented";
}

1
