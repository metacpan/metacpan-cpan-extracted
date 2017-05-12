package Net::FTPTurboSync::UploadedFiles;


# a wrapper around a db
use DBI;
sub new {
    my ($class, $dbh ) = @_;
    my $self = { dbh => $dbh };
    bless $self, $class;    
    return $self;
}
sub selectAllFiles(){
    my ( $self ) = @_;
    return $self->{dbh}->selectall_arrayref(
        'select perms, uploaded as "date", fullname, objsize as "size"'
        . ' from files where objtype = \'f\' order by length(fullname)',
        { Slice => {} }
        );
}
sub selectAllDirs(){
    my ( $self ) = @_;
    return $self->{dbh}->selectall_arrayref(
        'select fullname, perms from files where objtype = \'d\' order by length(fullname)',
        { Slice => {} }
        );
}
#delete a file or a directory
sub deleteFile {
    my ($self, $fileName) = @_;
    my $sth = $self->{dbh}->prepare("delete from files where fullname = ?");
    $sth->bind_param( 1, $fileName, DBI::SQL_VARCHAR );
    $sth->execute();        
}
sub createDir () {
    my ($self, $dirname, $perms ) = @_;
    my $sth = $self->{dbh}->prepare("insert into files ( objtype, fullname, perms ) values ('d',?,?)" );
    $sth->bind_param ( 1, $dirname, DBI::SQL_VARCHAR );
    $sth->bind_param ( 2, $perms, DBI::SQL_INTEGER );    
    $sth->execute() ;
}
sub setPerms() {
    my ( $self, $fileName, $perms ) = @_;
    my $sth = $self->{dbh}->prepare("update files set perms = ? where fullname = ?" );
    $sth->bind_param ( 1, $perms, DBI::SQL_INTEGER );
    $sth->bind_param ( 2, $fileName, DBI::SQL_VARCHAR );        
    $sth->execute();            
}
sub uploadFile() {
    my ($self, $fileName, $perms, $date, $size ) = @_ ;
    my $sth = $self->{dbh}->prepare("insert into files ( objtype, fullname, perms, uploaded, objsize ) 
                               values ('f',?,?,?,?)" );    
    $sth->bind_param ( 1, $fileName, DBI::SQL_VARCHAR );
    $sth->bind_param ( 2, $perms, DBI::SQL_INTEGER );
    $sth->bind_param ( 3, $date,  DBI::SQL_INTEGER );
    $sth->bind_param ( 4, $size,  DBI::SQL_INTEGER );    
    $sth->execute();    
}
sub getInfo() {
    my ( $self, $fileName ) = @_;
    my $fileinfo = $self->{dbh}->selectrow_arrayref(
        'select uploaded as "date", objsize as "size", perms from files where fullname = ?',
        { Slice => {} },
        $fileName
        );
    return $fileinfo;
}
sub reuploadFile (){
    my ($self, $fileName, $perms, $date, $size ) = @_ ;
    my $sth = $self->{dbh}->prepare("update files set perms=?, uploaded=?, objsize=? 
                             where objtype='f' and fullname=?") ;
    $sth->bind_param ( 4, $fileName, DBI::SQL_VARCHAR );    
    $sth->bind_param ( 1, $perms, DBI::SQL_INTEGER );
    $sth->bind_param ( 2, $date,  DBI::SQL_INTEGER );
    $sth->bind_param ( 3, $size,  DBI::SQL_INTEGER );    
    $sth->execute();    
}
sub deployScheme () {
    my ($self) = @_;
    $self->{dbh}->do("create table files (fullname text primary key, 
                                          uploaded integer, objtype char, 
                                          objsize integer, perms integer)")
        or die "cannot deploy db scheme";        
}

1;
