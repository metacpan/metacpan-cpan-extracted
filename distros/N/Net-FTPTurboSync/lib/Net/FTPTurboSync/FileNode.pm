package Net::FTPTurboSync::FileNode;

use Net::FTPTurboSync::FileObject;

use base qw(Net::FTPTurboSync::FileObject);
# parent of folder classes
sub equal {
    # one of these is remote
    my ($remotef, $localf) = Net::FTPTurboSync::FileObject->sortByLocation(@_);
    return !($remotef->isNew()
               or $remotef->getPerms() != $localf->getPerms());
} 
   
1;
