package Net::FTPTurboSync::MixRemote;

use Exception::Class::Base;
use Exception::Class::TryCatch;
# something wrong with server or netlink
use Exception::Class ('NetWorkEx');

sub isRemote { return 1; }
# delete a file or a dir from remote host and local db
sub delete {
    my ( $self ) = @_;
    my $path = $self->getPath();
    my $ftp = $self->{ftp};
    if ( ! $self->deleteRemoteObjAndCheck( $path, $ftp ) ){
        NetWorkEx->throw( "Cannot to remote file '"
                          . $self->getPath() . "'"  );
    }
    $self->{dbh}->deleteFile ( $path );
}

# remote file doesn't exist yet.
sub newFileObject {
    my ( $class, $ftp, $dbh, $path ) = @_ ;
    my $self =  $class->load ( $ftp,
                               $dbh,
                               { size => 0, perms => 0,
                                 date => 0, fullname => $path }
        );
    $self->{_new} = 1;
    return $self;
}
# load from db
sub load { 
    my ( $class, $ftp, $dbh, $info ) = @_ ;
    my $self = $class->instantiateObject ( $info->{fullname}, $info );       
    $self->{ftp} = $ftp;
    $self->{dbh} = $dbh;
    $self->{_new} = 0;
    return $self;        
}    

1;
