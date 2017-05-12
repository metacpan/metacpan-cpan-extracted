#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib';
use Test::More tests => 10;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions = qw/
  CGI::Fast CGI::Session Crypt::OpenSSL::Bignum Crypt::OpenSSL::RSA
  File::Basename File::Slurp File::Spec Getopt::Long JSON List::Util
  Log::Report LWP::UserAgent Mail::ExpandAliases Mail::IMAPTalk MIME::Base64
  Time::HiRes URI Test::More Apache::Htpasswd Crypt::PasswdMD5 Digest::SHA/;

foreach my $package (@show_versions)
{   eval "require $package";

    no strict 'refs';
    my $report
      = !$@    ? "version ". (${"$package\::VERSION"} || 'unknown')
      : $@ =~ m/^Can't locate/ ? "not installed"
      : "reports error";

    warn "$package $report\n";
}

require_ok('Mozilla::Persona');
require_ok('Mozilla::Persona::Check');
require_ok('Mozilla::Persona::Setup');
require_ok('Mozilla::Persona::Server');
require_ok('Mozilla::Persona::Aliases');
require_ok('Mozilla::Persona::Aliases::MailConfig');
require_ok('Mozilla::Persona::Validate');
require_ok('Mozilla::Persona::Validate::IMAPTalk');
require_ok('Mozilla::Persona::Validate::Htpasswd');
require_ok('Mozilla::Persona::Validate::Table');
