package Net::FTPTurboSync::FactoryOfRemoteObjects;


use Net::FTPTurboSync::RemoteFile;
use Net::FTPTurboSync::RemoteDir;

sub new {
    my ( $class, $ftp, $dbh ) = @_;
    my $self = { ftp => $ftp, dbh => $dbh };
    bless $self, $class;
    return $self;
}
# return object RemoteFile
sub createFile {
    my ( $self, $path ) = @_;
    return Net::FTPTurboSync::RemoteFile->newFileObject ( $self->{ftp}, $self->{dbh}, $path );
}
# retur object RemoteDir
sub createDir {
    my ( $self, $path ) = @_;
    return Net::FTPTurboSync::RemoteDir->newFileObject ( $self->{ftp}, $self->{dbh}, $path );        
}

1;
