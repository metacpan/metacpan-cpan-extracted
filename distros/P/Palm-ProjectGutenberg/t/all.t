use strict;
use warnings;

use Test::More tests => 4;

use Palm::ProjectGutenberg qw(pg2pdb);
use Palm::Doc;
use File::Spec::Functions;
use Config;

pg2pdb("Artistic Licence", "ARTISTIC.txt", catfile("t", "ARTISTIC-test.pdb"));
my $knowngood = Palm::Doc->new();
$knowngood->Load(catfile("t", "ARTISTIC.pdb"));
my $generated = Palm::Doc->new();
$generated->Load(catfile("t", "ARTISTIC-test.pdb"));

ok($knowngood->{name} eq $generated->{name}, "title is good when using module");
ok($knowngood->text() eq $generated->text(), "text is good when using module");

unlink catfile("t", "ARTISTIC-test.pdb");

local $ENV{PERL5OPT} = '-Mblib';
system($Config{perlpath}, catfile("blib", "script", "pg2pdb"), "Artistic Licence", "ARTISTIC.txt", catfile("t", "ARTISTIC-test.pdb"));
$generated = Palm::Doc->new();
$generated->Load(catfile("t", "ARTISTIC-test.pdb"));
ok($knowngood->{name} eq $generated->{name}, "title is good when using script");
ok($knowngood->text() eq $generated->text(), "text is good when using script");
