package Net::FTPTurboSync::TurboPutCommand;

use Net::FTPTurboSync::PrgOpts;
use Exception::Class::Base;
use Exception::Class::TryCatch;

my $theOpts = $Net::FTPTurboSync::PrgOpts::theOpts;

sub new {
    my ( $class, $factory, $localFiles, $localDirs, $remoteFiles,  $remoteDirs ) = @_;
    my $self = {
        lfiles => $localFiles, rfiles => $remoteFiles,
        rdirs => $remoteDirs, ldirs => $localDirs,
        encounteredErrors => 0,
        remoteObjectFactory => $factory,
        # list of folder names which cannot be created on a remote host
        ignorePrefix => []
    };
    bless $self, $class;
    return $self;
}
sub getRemoteFile {
    my ( $self, $path ) = @_;
    if( exists $self->{rfiles}->{$path} ) {
        return $self->{rfiles}->{$path};
    }
    return $self->{remoteObjectFactory}->createFile( $path );
}
sub getRemoteDir {
    my ( $self, $path ) = @_;
    if ( exists $self->{rdirs}->{$path} ){
        return $self->{rdirs}->{$path};
    }
    my $d = $self->{remoteObjectFactory}->createDir( $path );
    return $d;
}
sub errorHappend {
    my ( $self ) = @_;
    $theOpts = $Net::FTPTurboSync::PrgOpts::theOpts;
    if ( $theOpts->{maxerrors} == 0 ) { return; }
    $self->{encounteredErrors} += 1;
    if ( $self->{encounteredErrors} >= $theOpts->{maxerrors} ){
        print STDERR "There was " . $self->{encounteredErrors} . " errors\n";
        print STDERR "Process was self terminated\n";
        exit 1;
    }
}
sub syncFiles {
    my ( $self ) = @_;
    my $lfiles = $self->{lfiles};
    foreach my $curlocalfile ( sort { return length($b) <=> length($a); }
                               keys(%$lfiles) )
    {
        my $lfile = $lfiles->{$curlocalfile};
        my $rfile = $self->getRemoteFile ( $lfile->getPath() );
        if ( ! $lfile->equal( $rfile ) ){
            eval {
                $rfile->set( $lfile );
                if ( !$theOpts->{doquiet} ) { print "File '$curlocalfile' was uploaded.\n";  }
            };
            if ( my $ex = Exception::Class::Base->caught() ) {
                print STDERR "$ex->{message}\n";
                $self->errorHappend();
            }
        }
    }
}
sub syncDirectories {
    my ( $self ) = @_;
    my $curlocaldir;
    my $toBeIgnored = $self->{ignorePrefix};
    my $ldirs = $self->{ldirs};
  UploadFileObject:
    foreach $curlocaldir ( sort { return length($a) <=> length($b); }
                           keys( %$ldirs ) )
    {
        foreach my $badFolder ( @$toBeIgnored ){
            if ( $badFolder eq substr( $curlocaldir, length( $badFolder ) ) ){
                next UploadFileObject;
            }
        }
        my $ldir = $ldirs->{$curlocaldir};
        my $rdir = $self->getRemoteDir ( $ldir->getPath() );
        if ( ! $ldir->equal( $rdir ) ){
            eval {
                $rdir->set($ldir );
                if ( !$theOpts->{doquiet} ) { print "Folder '$curlocaldir' was uploaded.\n";  }
            };
            if ( my $ex = Exception::Class::Base->caught() ) {
                $toBeIgnored->[ ++$#$toBeIgnored ] = $curlocaldir;
                $self->errorHappend();
            }
        }
    }
}
sub deleteRemoteFiles {
    my ( $self ) = @_;
    my $rfiles = $self->{rfiles};
    my $lfiles = $self->{lfiles};
    my $ftp = $self->{ftp};
    my $dbh = $self->{dbh};
    foreach my $rfilename ( keys  %$rfiles  ) {
        if ( ! exists $lfiles->{$rfilename} ){
            eval {
                $rfiles->{$rfilename}->delete();
                if ( !$theOpts->{doquiet} ) {
                    print "Delete file '$rfilename'.\n";
                }
            };
            if ( my $ex = Exception::Class::Base->caught() ){
                print STDERR "Could not remove remote file '$rfilename'\n";
                $self->errorHappend();                    
            }
        }
    }                
}
sub deleteRemoteDirectories {
    my ( $self ) = @_;
    my $rdirs = $self->{rdirs};
    my $ldirs = $self->{ldirs};
    my $ftp = $self->{ftp};
    my $dbh = $self->{dbh};
    foreach my $rdirname ( sort  { return length($b) <=> length($a); }
                           keys  %$rdirs  ) {

        if ( ! exists $ldirs->{$rdirname} ){
            eval {
                $rdirs->{$rdirname}->delete();
                if ( !$theOpts->{doquiet} ) { print "Delete folder '$rdirname'.\n";  }                    
            };
            if ( Exception::Class::Base->caught() ){
                print STDERR "Could not remove remote subdirectory '$rdirname'\n";
                $self->errorHappend();                    
            }
        }
    }        
}
sub dosync {
    my ( $self ) = @_;
    if ( !$theOpts->{doquiet} ) { print "Sync folders.\n";  }        
    $self->syncDirectories();
    if ( !$theOpts->{doquiet} ) { print "Sync files.\n";  }                
    $self->syncFiles();
    if (! $theOpts->{nodelete} )
    {
        if ( !$theOpts->{doquiet} ) { print "Delete unexisted files.\n";  }                    
        $self->deleteRemoteFiles();
        if ( !$theOpts->{doquiet} ) { print "Delete unexisted folders.\n";  }                                
        $self->deleteRemoteDirectories();
    }        
}
1;
