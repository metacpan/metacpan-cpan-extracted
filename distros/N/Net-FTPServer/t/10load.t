use strict;
use Test::More tests => 17;

BEGIN {
  use_ok("Net::FTPServer") || print "Bail out!\n";
  use_ok("Net::FTPServer::DirHandle");
  use_ok("Net::FTPServer::FileHandle");
  use_ok("Net::FTPServer::Handle");
  use_ok("Net::FTPServer::Full::Server");
  use_ok("Net::FTPServer::Full::DirHandle");
  use_ok("Net::FTPServer::Full::FileHandle");
  use_ok("Net::FTPServer::RO::DirHandle");
  use_ok("Net::FTPServer::RO::FileHandle");
  use_ok("Net::FTPServer::RO::Server");
  use_ok("Net::FTPServer::InMem::DirHandle");
  use_ok("Net::FTPServer::InMem::FileHandle");
  use_ok("Net::FTPServer::InMem::Server");
  SKIP: {
    skip "DBI not installed", 4 if not eval "require DBI; 1";
    use_ok("Net::FTPServer::DBeg1::IOBlob");
    use_ok("Net::FTPServer::DBeg1::Server");
    use_ok("Net::FTPServer::DBeg1::DirHandle");
    use_ok("Net::FTPServer::DBeg1::FileHandle");
  };
}

diag( "Testing Net::FTPServer $Net::FTPServer::VERSION, Perl $], $^X" );

__END__
