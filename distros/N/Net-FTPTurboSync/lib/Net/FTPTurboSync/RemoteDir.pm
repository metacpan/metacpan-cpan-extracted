package Net::FTPTurboSync::RemoteDir;

use Net::FTPTurboSync::FileNode;
use Net::FTPTurboSync::MixRemote;
use base qw(Net::FTPTurboSync::FileNode Net::FTPTurboSync::MixRemote);
# return true if object doesn't already exist
sub deleteRemoteObjAndCheck {
    my ( $self, $path, $ftp ) = @_;
    my $res = $ftp->rmdir ( $path );       
    return  defined( $res ) and ( $res eq 1 )
        or ( ! $ftp->ls ( $path ) );
}

sub instantiateObject {
    my ( $class, $path, $info ) = @_;
    return $class->new ( $path, $info->{perms} );        
}
sub set {
    my ( $self, $locald ) = @_;
    if ( $self->isNew ){
        my $x = $locald->getPath;
        my $res = $self->{ftp}->mkdir( $x );
        if ( !defined($res) and !$self->{ftp}->ls($x) ){
            NetWorkEx->throw ( "Cannot create '" . $locald->getPath() . "' directory" );
        }
    }
    $self->{ftp}->setPerms ( $locald->getPath, $locald->getPerms );
    if ( $self->isNew ){
        $self->{dbh}->createDir ( $locald->getPath, $locald->getPerms );
    }else {
        $self->{dbh}->setPerms ( $locald->getPath, $locald->getPerms );
    }                        
}

1;
