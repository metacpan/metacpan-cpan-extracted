package Novel::Robot::Packer::raw;
use strict;
use warnings;
#use utf8;

use base 'Novel::Robot::Packer';
use Data::MessagePack;
use File::Slurp;

sub suffix {
    'raw';
}

sub main {
    my ($self, $bk, %opt) = @_;

    my $mp = Data::MessagePack->new();
    $mp = $mp->utf8(1);
    my $pk = $mp->pack($bk);
    write_file( $opt{output}, {binmode => ':raw'}, $pk ) ;

    return $opt{output};
}


1;
