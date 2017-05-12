package Net::FTP::Common;

use strict;

use Carp qw(cluck confess);
use Data::Dumper;
use Net::FTP;


use vars qw(@ISA $VERSION);

@ISA     = qw(Net::FTP);

$VERSION = '7.0.d';

# Preloaded methods go here.

sub new {
  my $pkg  = shift;
  my $common_cfg_in = shift;
  my %netftp_cfg_in = @_;

  my %common_cfg_default = 
    (
     Host => 'ftp.microsoft.com',
     RemoteDir  => '/pub',
#     LocalDir  => '.',   # setup something for $ez->get
     Type => 'I'
    );

  my %netftp_cfg_default = ( Debug => 1, Timeout => 240, Passive => 1 );

  # overwrite defaults with values supplied by constructor input
  @common_cfg_default{keys %$common_cfg_in} = values %$common_cfg_in;
  @netftp_cfg_default{keys  %netftp_cfg_in} = values  %netftp_cfg_in;
    
  my $self = {};

  @{$self->{Common}}{keys %common_cfg_default} = values %common_cfg_default;
  @{$self          }{keys %netftp_cfg_default} = values %netftp_cfg_default;

  my $new_self = { %$self, Common => $self->{Common} } ;

  if (my $file = $self->{Common}{STDERR}) {
      open DUP, ">$file" or die "cannot dup STDERR to $file: $!";
      lstat DUP; # kill used only once error
      open STDERR, ">&DUP";
  }

  warn "Net::FTP::Common::VERSION = ", $Net::FTP::Common::VERSION  
      if $self->{Debug} ;


  bless $new_self, $pkg;
}

sub config_dump {
  my $self = shift;
  
  sprintf '
Here are the configuration parameters:
-------------------------------------
%s
', Dumper($self);

}


sub Common {
    my $self = shift;

    not (@_ % 2) or die 
"
Odd number of elements in assignment hash in call to Common().
Common() is a 'setter' subroutine. You cannot call it with an
odd number of arguments (e.g. $self->Common('Type') ) and 
expect it to get a value. use GetCommon() for that.

Here is what you passed in.
", Dumper(\@_);

    my %tmp = @_;

#    warn "HA: ", Dumper(\%tmp,\@_);

    @{$self->{Common}}{keys %tmp} = values %tmp;
}

sub GetCommon {
    my ($self,$key) = @_;

    if ($key) {
	if (defined($self->{Common}{$key})) {
	    return ($self->{Common}{$key});
	} else {
	    return undef;
	}
    } else {
	$self->{Common};
    }
}

sub Host { 
    $_[0]->{Common}->{Host}

      or die "Host must be defined when creating a __PACKAGE__ object"
}

sub NetFTP { 

    my ($self, %config) = @_;

    @{$self}{keys %config} = values %config;

}

sub login {
  my ($self, %config) = @_;

  shift;

  if (@_ % 2) {
    die sprintf "Do not confuse Net::FTP::Common's login() with Net::FTP's login()
Net::FTP::Common's login() expects to be supplied a hash. 
E.g. \$ez->login(Host => \$Host)

It was called incorrectly (%s). Program terminating
%s
", (join ':', @_), $self->config_dump;
  }

#  my $ftp_session = Net::FTP->new($self->Host, %{$self->{NetFTP}});
  my $ftp_session = Net::FTP->new($self->Host, %$self);

#  $ftp_session or return undef;
  $ftp_session or 
      die sprintf 'FATAL: attempt to create Net::FTP session on host %s failed.
If you cannot figure out why, supply the configuration parameters when
emailing the support email list.
  %s', $self->Host, $self->config_dump;


  my $session;
  my $account = $self->GetCommon('Account');
  if ($self->GetCommon('User') and $self->GetCommon('Pass')) {
      $session = 
	  $ftp_session->login($self->GetCommon('User') , 
			      $self->GetCommon('Pass'),
			      $account);
  } else {
      warn "either User or Pass was not defined. Attempting .netrc for login";
      $session = 
	  $ftp_session->login;
  }

  $session and ($self->Common('FTPSession', $ftp_session)) 
    and return $ftp_session 
      or 
	warn "error logging in: $!" and return undef;

}

sub ls {
  my ($self, @config) = @_;
  my %config=@config;

  my $ftp = $self->prep(%config);

  my $ls = $ftp->ls;
  if (!defined($ls)) {
    return ();
  } else {
    return @{$ls};
  }
}

# contributed by kevin evans
# this returns a hash of hashes keyed by filename with attributes for each
sub dir {       
  my ($self, @config) = @_;
  my %config=@config;


  my $ftp = $self->prep(%config);

  my $dir = $ftp->dir;
  if (!defined($dir)) {
    return ();
  } else
  {
    my %HoH;

    # Comments were made on this code in this thread:
    # http://perlmonks.org/index.pl?node_id=287552

    foreach (@{$dir})
        {
	    # $_ =~ m#([a-z-]*)\s*([0-9]*)\s*([0-9a-zA-Z]*)\s*([0-9a-zA-Z]*)\s*([0-9]*)\s*([A-Za-z]*)\s*([0-9]*)\s*([0-9A-Za-z:]*)\s*([A-Za-z0-9.-]*)#;
	  #$_ = m#([a-z-]*)\s*([0-9]*)\s*([0-9a-zA-Z]*)\s*([0-9a-zA-Z]*)\s*([0-9]*)\s*([A-Za-z]*)\s*([0-9]*)\s*([0-9A-Za-z:]*)\s*([\w*\W*\s*\S*]*)#;

=for comment

drwxr-xr-x    8 0        0            4096 Sep 27  2003 .
drwxr-xr-x    8 0        0            4096 Sep 27  2003 ..
drwxr-xr-x    3 0        0            4096 Sep 11  2003 .afs
-rw-r--r--    1 0        0             809 Sep 26  2003 .banner
----r-xr-x    1 0        0               0 Mar  4  2002 .notar
-rw-r--r--    1 0        0             796 Sep 27  2003 README

=cut

	  warn "input-line: $_" if $self->{Debug} ;

	  $_ =~ m!^
	    ([\-FlrwxsStTdD]{10})  # directory and permissions
	    \s+
	    (\d+)                  # inode
	    \s+
	    (\w+)                  # 2nd number
	    \s+
	    (\w+)                  # 3rd number
	    \s+
	    (\d+)                  # file/dir size
	    \s+
	    (\w{3,4})         # month
	    \s+
	    (\d{1,2})         # day
	    \s+
	    (\d{1,2}:\d{2}|\d{4})           # year
	    \s+
		(.+) # filename
		  $!x;


        my $perm = $1;
        my $inode = $2;
        my $owner = $3;
        my $group = $4;
        my $size = $5;
        my $month = $6;
        my $day = $7;
        my $yearOrTime = $8;
        my $name = $9;
        my $linkTarget;

	  warn "
        my $perm = $1;
        my $inode = $2;
        my $owner = $3;
        my $group = $4;
        my $size = $5;
        my $month = $6;
        my $day = $7;
        my $yearOrTime = $8;
        my $name = $9;
        my $linkTarget;
" if $self->{Debug} ;

        if ( $' =~ m#\s*->\s*([A-Za-z0-9.-/]*)# )       # it's a symlink
                { $linkTarget = $1; }

        $HoH{$name}{perm} = $perm;
        $HoH{$name}{inode} = $inode;
        $HoH{$name}{owner} = $owner;
        $HoH{$name}{group} = $group;
        $HoH{$name}{size} = $size;
        $HoH{$name}{month} = $month;
        $HoH{$name}{day} = $day;
        $HoH{$name}{yearOrTime} =  $yearOrTime;
        $HoH{$name}{linkTarget} = $linkTarget;

	  warn "regexp-matches for ($name): ", Dumper(\$HoH{$name}) if $self->{Debug} ;

        }
  return(%HoH);
  }
}



sub mkdir {
    my ($self,%config) = @_;

    my $ftp = $self->prep(%config);
    my $rd =  $self->GetCommon('RemoteDir');
    my $r  =  $self->GetCommon('Recurse');
    $ftp->mkdir($rd, $r);
}


sub exists {
    my ($self,%cfg) = @_;

    my @listing = $self->ls(%cfg);

    my $rf = $self->GetCommon('RemoteFile');

   warn sprintf "[checking @listing for [%s]]", $rf if $self->{Debug} ;

    scalar grep { $_ eq $self->GetCommon('RemoteFile') } @listing;
}

sub delete {
    my ($self,%cfg) = @_;

    my $ftp = $self->prep(%cfg);
    my $rf  = $self->GetCommon('RemoteFile');

    
    warn Dumper \%cfg if $self->{Debug} ;

    $ftp->delete($rf);

}

sub grep {

    my ($self,%cfg) = @_;

#    warn sprintf "self: %s host: %s cfg: %s", $self, $host, Data::Dumper::Dumper(\%cfg);

    my @listing = $self->ls(%cfg);

    grep { $_ =~ /$cfg{Grep}/ } @listing;
}

sub connected {
    my $self = shift;

#    warn "CONNECTED SELF ", Dumper($self);

    my $session = $self->GetCommon('FTPSession') or return 0;

    local $@;
    my $pwd;
    my $connected = $session->pwd ? 1 : 0;
#    warn "connected: $connected RESP: $connected";
    $connected;
}

sub quit {
    my $self = shift; 

    $self->connected and $self->GetCommon('FTPSession')->quit;

}


sub prepped {
    my $self = shift; 
    my $prepped = $self->GetCommon('FTPSession') and $self->connected;
    #    warn "prepped: $prepped";
    $prepped;
}

sub prep {
  my $self = shift;
  my %cfg  = @_;

  $self->Common(%cfg);

# This will not work if the Host changes and you are still connected 
# to the prior host. It might be wise to simply drop connection 
# if the Host key changes, but I don't think I will go there right now.
#  my $ftp = $self->connected 
#                  ? $self->GetCommon('FTPSession') 
#                  : $self->login ;
# So instead:
  my $ftp = $self->login ;

  
  $self->Common(LocalDir => '.') unless
      $self->GetCommon('LocalDir') ;

  if ($self->{Common}->{RemoteDir}) {
      $ftp->cwd($self->GetCommon('RemoteDir'))
  } else {
      warn "RemoteDir not configured. ftp->cwd will not work. certain Net::FTP usages will failed.";
  }
  $ftp->type($self->GetCommon('Type'));

  $ftp;
}

sub binary {
    my $self = shift;

    $self->{Common}{Type} = 'I';
}

sub ascii {
    my $self = shift;

    $self->{Common}{Type} = 'A';
}

sub get {

  my ($self,%cfg) = @_;

  my $ftp = $self->prep(%cfg);

  my $r;

  my $file;

  if ($self->GetCommon('LocalFile')) {
    $file= $self->GetCommon('LocalFile');
  } else {
    $file=$self->GetCommon('RemoteFile');
  }
	
  my $local_file = join '/', ($self->GetCommon('LocalDir'), $file);
		
  #  warn "LF: $local_file ", "D: ", Dumper($self);


  if ($r = $ftp->get($self->GetCommon('RemoteFile'), $local_file)) {
    return $r;
  } else { 
    warn sprintf 'download of %s to %s failed',
	$self->GetCommon('RemoteFile'), $self->GetCommon('LocalFile');
    warn 
	'here are the settings in your Net::FTP::Common object: %s',
	    Dumper($self);
    return undef;
  }
  

}

sub file_attr {
    my $self = shift;
    my %hash;
    my @key = qw(LocalFile LocalDir RemoteFile RemoteDir);
    @hash{@key} = @{$self->{Common}}{@key};
    %hash;
}

sub bad_filename {
    shift =~ /[\r\n]/s;
}

sub send {
  my ($self,%cfg) = @_;

  my $ftp = $self->prep(%cfg);

  #  warn "send_self", Dumper($self);

  my %fa = $self->file_attr;

  if (bad_filename($fa{LocalFile})) {
      warn "filenames may not have CRLF in them. skipping $fa{LocalFile}";
      return;
  }

  warn "send_fa: ", Dumper(\%fa) if $self->{Debug} ;


  my $lf = sprintf "%s/%s", $fa{LocalDir}, $fa{LocalFile};
  my $RF = $fa{RemoteFile} ? $fa{RemoteFile} : $fa{LocalFile};
  my $rf = sprintf "%s/%s", $fa{RemoteDir}, $RF;

  warn "[upload $lf as $rf]" if $self->{Debug} ;

  $ftp->put($lf, $RF) or 
      confess sprintf "upload of %s to %s failed", $lf, $rf;
}

sub put { goto &send }

sub DESTROY {


}


1;
__END__

