#!/usr/bin/perl

require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'Net::OpenID::Server::Standalone',
   VERSION_FROM => 'Standalone.pm',   # finds $VERSION
   DISTNAME     => 'Net-OpenID-Server-Standalone',
   ($] >= 5.005 ?
    (	ABSTRACT  => 'personal standalone OpenID server ready-to-use out-of-the-box',
     	AUTHOR    => 'Peter V. Vereshagin (peter@vereshagin.org)') : (),
		),
   	dist        => { COMPRESS => 'gzip', SUFFIX => 'gz', },
		PREREQ_PRINT	=>	1,
		PREREQ_PM		=> {	map { $_ => 0, } qw/Net::OpenID::Server Data::UUID MIME::Base64 HTML::Entities Digest::MD5 CGI CGI::Session/  },
  );
