package Net::FTPTurboSync::FileObject;

use Exception::Class::Base;
use Exception::Class::TryCatch;
# the exception is purposed to indicate the program encountered with a bug
use Exception::Class('PrgBug');

# base class for remote dirs and files and local dirs and files
sub new {
    my ( $class, $path, $perms ) = @_;
    my $self = { _path => $path, _perms => $perms } ;
    bless $self, $class;
    return $self;
}
# return string
sub getPath {
    my ( $self ) = @_;
    return $self->{_path}; 
}
sub setPath {
    my ( $self, $newPath ) = @_;
    $self->{_path} = $newPath;
}
# return integer
sub getPerms {
    my ( $self ) = @_;
    return $self->{_perms}; 
}
sub setPerms {
    my ( $self, $newPerms ) = @_;
    $self->{_perms} = $newPerms;
}
# return ( $remote, $local )
sub sortByLocation {
    my ($class, $x, $y ) = @_;
    if ( $x->isRemote() ){
        if ( $y->isRemote() ){
            PrgBug->throw ( "Both objects are remote" );
        }
        return ($x,$y);
    }
    return ($y,$x);
}
# return true if object is remote
sub isRemote {
    return 0;
}
# return true if object is remote and new
sub isNew {
    my ( $self ) = @_;
    if ( exists ($self->{_new} ) ){
        return $self->{_new};            
    }        
    return 0;
}
sub set {
    my ( $self, $other ) = @_;
    if ( $other->isRemote() ){
        $other->set ( $self );
    }else{
        PrbBug->throw ( "Both objects are local" );
    }        
}    

1;
