use lib 't/lib';
use Digest::MD5;
use SPVMImpl;
Digest::MD5::is_spvm();
die unless $INC{'Digest/MD5.pm'} =~ /\bblib\b/;

use strict;
use warnings;

use Digest::MD5 ();

print "1..2\n";
my $md5 = Digest::MD5->new;

eval {
   use vars qw(*FOO);
   $md5->addfile(*FOO);
};
print "not " unless $@ =~ /^Bad filehandle: FOO at/;
print "ok 1\n";

open(BAR, "no-existing-file.$$");
eval {
    $md5->addfile(*BAR);
};
print "not " unless $@ =~ /^No filehandle passed at/;
print "ok 2\n";
