#!/usr/bin/perl

use Net::FTP::Common;

my $file = shift or die 'must supply file';

our %netftp_cfg =
  (Debug => 1, Timeout => 120);

our %common_cfg =
  (
   User => 'anonymous',
   Pass => 'tbone@cpan.org',

   LocalFile => $file,
   Host => 'pause.perl.org',    # overwrite ftp.microsoft.com default
   RemoteDir  => '/incoming',   # automatic CD on remote machine to RemoteDir
  );

$ez = Net::FTP::Common->new(\%common_cfg, %netftp_config);

$ez->send;
