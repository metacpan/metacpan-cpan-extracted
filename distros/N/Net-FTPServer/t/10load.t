#!/usr/bin/perl -w

# $Id: 10load.t,v 1.1 2003/09/28 11:50:45 rwmj Exp $

use strict;
use Test;

BEGIN {
  plan tests => 1;
}

use Net::FTPServer;
use Net::FTPServer::DirHandle;
use Net::FTPServer::FileHandle;
use Net::FTPServer::Handle;
use Net::FTPServer::DBeg1::IOBlob;
use Net::FTPServer::DBeg1::Server;
use Net::FTPServer::DBeg1::DirHandle;
use Net::FTPServer::DBeg1::FileHandle;
use Net::FTPServer::Full::Server;
use Net::FTPServer::Full::DirHandle;
use Net::FTPServer::Full::FileHandle;
use Net::FTPServer::RO::DirHandle;
use Net::FTPServer::RO::FileHandle;
use Net::FTPServer::RO::Server;
use Net::FTPServer::InMem::DirHandle;
use Net::FTPServer::InMem::FileHandle;
use Net::FTPServer::InMem::Server;

ok (1);
