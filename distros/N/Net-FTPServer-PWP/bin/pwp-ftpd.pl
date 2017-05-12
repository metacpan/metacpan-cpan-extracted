#!/bin/sh
# -*- perl -*-
exec perl -x -wT $0 "$@";
exit 1;
#!perl

# Net::FTPServer::PWP - A Perl FTP Server
# Copyright (C) 2002 Luis E. Munoz <luismunoz@cpan.org>

# $Id: pwp-ftpd.pl,v 1.2 2002/10/17 03:17:32 lem Exp $

use strict;
use Net::FTPServer::PWP::Server;

my $ftps = Net::FTPServer::PWP::Server->run;
