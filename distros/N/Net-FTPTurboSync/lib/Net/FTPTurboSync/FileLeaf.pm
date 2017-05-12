package Net::FTPTurboSync::FileLeaf;

use Net::FTPTurboSync::FileObject;
use base qw(Net::FTPTurboSync::FileObject);
sub new {
    my ($class, $path, $perms, $moddate, $size) = @_;
    my $self = $class->SUPER::new( $path, $perms );
    $self->setModDate ( $moddate );
    $self->setSize ( $size );
    return $self;
}
# return date of last modification in the epoch format ( integer )
sub getModDate {
    my ( $self ) = @_;
    return $self->{_moddate};
}
sub setModDate {
    my ( $self, $newmoddate ) = @_;
    return $self->{_moddate} = $newmoddate ;
}    
# return size of the file
sub getSize {
    my ( $self ) = @_;
    return $self->{_size};
}
sub setSize {
    my ( $self, $newsize ) = @_;        
    return $self->{_size} = $newsize ;
}
# return true if objects are coincidence
sub equal {
    # one of these is remote
    my ( $remotef,  $localf ) = Net::FTPTurboSync::FileObject->sortByLocation( @_ );
    return !(  $remotef->isNew() or
               $remotef->getModDate() < $localf->getModDate() or
               $remotef->getSize() != $localf->getSize() or
               $remotef->getPerms() != $localf->getPerms()
        );
}

1;
