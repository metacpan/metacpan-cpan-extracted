package Net::FTPTurboSync::LocalFile;

use Net::FTPTurboSync::FileLeaf;
use Net::FTPTurboSync::MixLocal;
use base qw(Net::FTPTurboSync::FileLeaf Net::FTPTurboSync::MixLocal);

sub instantiateObject {
    my ( $class, $path, $stat ) = @_;
    return $class->new( $path, 01777 & $stat->[2], $stat->[9], $stat->[7] );            
}

1;
