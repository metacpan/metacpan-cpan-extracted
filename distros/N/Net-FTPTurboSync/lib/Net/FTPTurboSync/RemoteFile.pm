package Net::FTPTurboSync::RemoteFile;

use Net::FTPTurboSync::FileLeaf;
use Net::FTPTurboSync::MixRemote;

use base qw(Net::FTPTurboSync::FileLeaf Net::FTPTurboSync::MixRemote);

sub deleteRemoteObjAndCheck {
    my ( $self, $path, $ftp ) = @_;
    return $ftp->delete ( $path ) or ! $ftp->size( $path );
}
#load info about remote file from db
# remote file already exists
sub instantiateObject {
    my ( $class, $path, $info ) = @_ ;
    return $class->new ( $path,
                         $info->{perms},
                         $info->{date},
                         $info->{size} );       
}

sub writeToDb {
    my ( $self, $localf ) = @_;
    if ( $self->isNew ){
        $self->{_new}=0;
        $self->setPath ( $localf->getPath );
        #insert db
        $self->{dbh}->uploadFile ( $self->getPath,
                                   $self->getPerms,
                                   $self->getModDate,
                                   $self->getSize );
    }else {
        # update db
        $self->{dbh}->reuploadFile ( $self->getPath,
                                     $self->getPerms,
                                     $self->getModDate,
                                     $self->getSize );            
    }                
}
sub set {
    my ( $self, $localf ) = @_;
    if ( $self->isNew
         or $self->getSize != $localf->getSize
         or $self->getModDate < $localf->getModDate ) {
        my $p = $localf->getPath;
        my $res = $self->{ftp}->put( $p, $p );
        if ( !defined( $res ) or ($res ne $p) ){
            NetWorkEx->throw ( "Could not put '" . $localf->getPath . "' file" );
        }
        $self->setSize ( $localf->getSize );
        $self->setModDate ( $localf->getModDate()  );            
    }
    
    if ( $self->getPerms != $localf->getPerms ){
        $self->{ftp}->setPerms ( $localf->getPath, $localf->getPerms );
        $self->setPerms ( $localf->getPerms );            
    }
    $self->writeToDb ( $localf );
}

1;
