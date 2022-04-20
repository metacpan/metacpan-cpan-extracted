package TestSuite;

use warnings;
use strict;

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
sub access_token_file {
    my ($self, $tesla) = @_;
    my $token_data = $self->data->{token_data};
    $tesla->_access_token_set_expiry($token_data);
    $tesla->_access_token_update($token_data);
}

1;