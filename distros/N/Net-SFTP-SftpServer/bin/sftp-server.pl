#!/usr/local/bin/perl

use strict;
use warnings;
use Net::SFTP::SftpServer ( { log => 'local5' }, qw ( :LOG :ACTIONS ) );
use BSD::Resource;        # for setrlimit

use constant DEBUG_USER => {
  SFTPTEST => 1,
};


# Security - make sure we have started this as sftp not ssh
unless ( scalar @ARGV == 2 and
         $ARGV[0] eq '-c'  and
         ($ARGV[1] eq '/usr/local/bin/sftp-server.pl') ){

       logError "SFTP connection attempted for application $ARGV[0] - exiting";
       print "\n\rYou do not have permission to login interactively to this host.\n\r\n\rPlease contact the system administrator if you believe this to be a configuration error.\n\r";
       exit 1;
}

my $MEMLIMIT = 100 * 1024 * 1024; # 100 Mb

# hard limits on process memory usage;
setrlimit( RLIMIT_RSS,  $MEMLIMIT, $MEMLIMIT );
setrlimit( RLIMIT_VMEM, $MEMLIMIT, $MEMLIMIT );

my $debug = (defined DEBUG_USER->{uc(getpwuid($>))} and DEBUG_USER->{uc(getpwuid($>))}) ? 1 : 0;

my $sftp = Net::SFTP::SftpServer->new(
  debug               => $debug,
  home                => '/var/upload/sftp',
  file_perms          => 0660,
  on_file_sent        => \&ActionOnSent,
  on_file_received    => \&ActionOnReceived,
  use_tmp_upload      => 1,
  max_file_size       => 200 * 1024 * 1024,
  valid_filename_char => [ 'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_', '.', '-' ],
  deny                => ALL,
  allow               => [ (
                              SSH2_FXP_OPEN,
                              SSH2_FXP_CLOSE,
                              SSH2_FXP_READ,
                              SSH2_FXP_WRITE,
                              SSH2_FXP_LSTAT,
                              SSH2_FXP_STAT_VERSION_0,
                              SSH2_FXP_FSTAT,
                              SSH2_FXP_OPENDIR,
                              SSH2_FXP_READDIR,
                              SSH2_FXP_REMOVE,
                              SSH2_FXP_STAT,
                              SSH2_FXP_RENAME,
                           )],
  fake_ok             => [ (
                              SSH2_FXP_SETSTAT,
                              SSH2_FXP_FSETSTAT,
                           )],
);

$sftp->run();

sub ActionOnSent {
  my $fileObject = shift;
   ## Do Stuff
}

sub ActionOnReceived {
  my $fileObject = shift;
   ## Do Stuff
}


