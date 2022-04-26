package TestSuite;

use warnings;
use strict;

use Carp qw(croak);
use Data::Dumper;
use JSON;

my $file = 't/test_data/test_data.json';

sub new {
    return bless {}, shift;
}
sub data {
    my $perl;

    {
        local $/;
        open my $fh, '<', $file or die $!;
        my $json = <$fh>;
        $perl = decode_json($json);
    }

    return $perl;
}
sub file_data {
    my ($self, $filename) = @_;

    croak "Need filename as param" if ! defined $filename;

    my $perl;

    {
        local $/;
        open my $fh, '<', $filename or die $!;
        my $json = <$fh>;
        $perl = decode_json($json);
    }

    return $perl;
}
sub json {
    my ($self, $want) = @_;

    my $data = data();

    if (! $want) {
        return encode_json($data);
    }
    else {
        return encode_json($data->{$want});
    }
}
sub access_token_file {
    my ($self, $tesla) = @_;
    my $token_data = $self->data->{token_data};
    $tesla->_access_token_set_expiry($token_data);
    $tesla->_access_token_update($token_data);
}

1;