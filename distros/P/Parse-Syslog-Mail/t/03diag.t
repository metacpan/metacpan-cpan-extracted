#!perl -T
use strict;
use Test::More;
BEGIN {
  eval "use Test::Exception";
  plan skip_all => "Test::Exception required for testing exceptions" if $@;
  eval "use Test::Warn";
  plan skip_all => "Test::Warn required for testing warnings" if $@;
  plan tests => 3;
}
use Parse::Syslog::Mail;

my $maillog = undef;
my $fake_file = 'Arba';
my $fake_object = bless {}, 'Fake::Object';

throws_ok {
    $maillog = new Parse::Syslog::Mail
} '/^fatal: Expected an argument/', 
  "calling new() with no argument";

throws_ok {
    $maillog = new Parse::Syslog::Mail $fake_file
} "/^fatal: Can't create new Parse::Syslog object: can't open $fake_file\: /", 
  "calling new() with an argument that looks like a file";

throws_ok {
    $maillog = new Parse::Syslog::Mail $fake_object
} "/^fatal: Can't create new Parse::Syslog object: argument must be either a file-name or an IO::Handle object/", 
  "calling new() with an argument that looks like an object";

