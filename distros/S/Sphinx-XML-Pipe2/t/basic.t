#perl -w
use strict;
use Sphinx::XML::Pipe2;
use Test::More tests => 1;

my $p = Sphinx::XML::Pipe2->new;

$p->attr('type', 'int');
$p->attr('type', 'str2ordianal');
map $p->field($_), qw(name content);
$p->add(1, 1, 'test', 'hi', 'there');
my $s = $p->process->toString(0);
$s =~ s/[\r\n]//sg;
ok(length($s) == 335, 'simple');
