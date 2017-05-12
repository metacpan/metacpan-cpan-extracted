#!/usr/bin/perl


use lib "../lib/";
use strict;

use Config::General;
use Digest::SHA;
use Env;
use FileHandle;
use Log::Log4perl;
use parent;
use POSIX;
use Sys::Syslog;
use Term::ReadKey;
use Term::ReadLine;
use Test::More;
use Test::Output;
use Text::Shellwords::Cursor;

print "Config::General ($Config::General::VERSION)\n";
print "Digest::SHA ($Digest::SHA::VERSION)\n";
print "Env ($Env::VERSION)\n";
print "FileHandle ($FileHandle::VERSION)\n";
print "Log::Log4perl ($Log::Log4perl::VERSION)\n";
print "parent ($parent::VERSION)\n";
print "POSIX ($POSIX::VERSION)\n";
print "Sys::Syslog ($Sys::Syslog::VERSION)\n";
print "Term::ReadKey ($Term::ReadKey::VERSION)\n";
print "Term::ReadLine::Gnu ($Term::ReadLine::Gnu::VERSION)\n";
print "Test::More ($Test::More::VERSION)\n";
print "Test::Output ($Test::Output::VERSION)\n";
print "Text::Shellwords::Cursor ($Text::Shellwords::Cursor::VERSION)\n";

