package Net::FTPTurboSync::MyFtp;

use Net::FTP;
use Net::FTPTurboSync::PrgOpts;
use base qw (Net::FTP);

sub new () {
    my ( $class, $ftpserver, $doftpdebug, $ftptimeout) = @_;

    my $self = $class->SUPER::new( $ftpserver,
                                   Debug=>$doftpdebug,
                                   Timeout=>$ftptimeout,
                                   Passive=>1 ) ;
    return $self;
}
sub setPerms {
    my ( $self, $path, $perms ) = @_;
    $self->quot('SITE', sprintf('CHMOD %04o %s', $perms, $path));
}
sub connection() {
    my ($class) = @_;
    my $theOpts = $Net::FTPTurboSync::PrgOpts::theOpts;
    if ($theOpts->{dodebug}) {
        print "\nFind out if ftp server is online & accessible.\n";
    }
    my $doftpdebug=($theOpts->{doverbose} > 2);
    my $ftpc = Net::FTPTurboSync::MyFtp->new (
        $theOpts->{ftpserver},
        $doftpdebug,
        $theOpts->{ftptimeout}
        ) || die "Could not connect to $theOpts->{ftpserver}\n";
    if ($theOpts->{dodebug}) {
        print "Logging in as $theOpts->{ftpuser} with password $theOpts->{ftppasswd}.\n"
    }
    
    $ftpc->login( $theOpts->{ftpuser},
                  $theOpts->{ftppasswd}
        ) || die "Could not login to $theOpts->{ftpserver} as $theOpts->{ftpuser}\n";
    my $ftpdefdir = $ftpc->pwd();
    if ( $theOpts->{dodebug}) {
        print "Remote directory is now ".$ftpdefdir."\n";
    }
    # insert remote login directory into relative ftpdir specification
    if ( $theOpts->{ftpdir} !~ /^\//) 
    {
        if ($ftpdefdir eq "/")
        {
            $theOpts->{ftpdir} = $ftpdefdir . $theOpts->{ftpdir};
        }else{
            $theOpts->{ftpdir} = $ftpdefdir . "/" . $theOpts->{ftpdir};
        }
        if (!$theOpts->{doquiet}){
            print "Absolute remote directory is $theOpts->{ftpdir}\n";
        }
    }
    if ( $theOpts->{dodebug} ) {
        print "Changing to remote directory $theOpts->{ftpdir}.\n"
    }

    $ftpc->binary()
        or die "Cannot set binary mode ", $ftpc->message;
    $ftpc->cwd($theOpts->{ftpdir})
        or die "Cannot cwd to $theOpts->{ftpdir} ", $ftpc->message;
    if ($ftpc->pwd() ne $theOpts->{ftpdir}) {
        die "Could not change to remote base directory $theOpts->{ftpdir}\n";
    }
    if ($theOpts->{dodebug}) {
        print "Remote directory is now " . $ftpc->pwd() . "\n";
    }
    return $ftpc;
}
sub isConnected {
    my ( $self ) = @_;
    # Prepend connection time out while file reading takes
    # longer than the remote ftp time out
    # - 421 Connection timed out.
    # - code=421 or CMD_REJECT=4
    if (!$self->pwd()) {
        # or $self->status == Net::Cmd::CMD_REJECT;
        return $self->code == 421;                
    }
    return 1;
}

1;

__END__

# {
#     package MyFtp;
#     use File::Copy;
#     sub new () {
#         my ( $class) = @_;
#         my $self = { rempass => "/tmp/xxx" } ;
#         bless $self, $class;
#         return $self;
#     }
#     sub size {
#         my ( $self, $path ) = @_;
#         my @stat = lstat ( $self->{rempass} . "/$path" );
#         return $stat[7];
#     }
#     sub setPerms {
#         my ( $self, $path, $perms ) = @_;
#         chmod ($perms, $self->{rempass} . "/$path") ;
#     }
#     sub message {
#         return "Message";
#     }
#     sub binary {
#         return 1;
#     }
#     sub connection() {
#         my ( $class ) = @_;
#         return $class->new () ;
#     }
#     sub delete {
#         my ( $self, $path );
#         return unlink ( $path  );
#     }
#     sub mkdir {
#         my ( $self, $path ) = @_;
#         if ( mkdir ( $self->{rempass} . "/$path" ) ){
#             return $path;
#         }
#         return "";
#     }
#     sub put {
#         my ($self, $src, $dst ) = @_;
#         if ( copy ( $src, $self->{rempass} . "/$dst" ) ){
#             return $src;
#         }
#         return "";
#     }
    
#     sub rmdir {
#         my ($self, $path ) = @_;
#         return rmdir( $self->{rempass} . "/$path" );
#     }
        
#     sub ls {
#         my ( $self, $path ) = @_;
#         return $self->dir( $path );
#     }
#     sub dir {
#         my ( $self, $path ) = @_;
#         if ( -d ( $self->{rempass} . "/$path" ) ){
#             return ( wantarray  ? ( ".", ".." )  :   [ ".", ".." ] );
#         }
#         return  ( wantarray  ? @{ [] }  :  [] );        
#     }
#     sub quit {
#         return 1;
#     }
#     sub cwd {
#         return 1;
#     }
#     sub pwd {
#         return shift()->{rempass};        
#     }
#     sub isConnected {
#         return 1;
#     }
# }
