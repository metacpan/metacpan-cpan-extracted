package Net::FTPTurboSync::LocalDir;

use Net::FTPTurboSync::MixLocal;
use Net::FTPTurboSync::FileNode;
use base qw(Net::FTPTurboSync::FileNode Net::FTPTurboSync::MixLocal);

sub instantiateObject {
    my ( $class, $path, $stat ) = @_;
    return $class->new( $path, 01777 & $stat->[2] );            
}

1;
