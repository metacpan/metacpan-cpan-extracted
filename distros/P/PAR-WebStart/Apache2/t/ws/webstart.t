#!/usr/bin/perl
use strict;
use warnings;
use Apache::Test;
use Apache::TestUtil qw(t_cmp);
use Apache::TestRequest qw(GET);
use File::Temp qw(tempfile);
use PAR::WebStart;

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';

plan tests => 29;

my $uri = "http://$hostport/webstart?arg1=arg;arg2=3";

my $result = GET $uri;
ok t_cmp($result->code, 200, "Get $uri");

my $content = $result->content;
ok t_cmp(defined $content, 1, "Checking content");

my ($fh, $file) = tempfile();
print $fh $content;
close $fh;
ok t_cmp(-e $file, 1, "$file exists");

my $obj = PAR::WebStart->new(file => $file);
ok t_cmp(ref($obj), 'PAR::WebStart');
my $cfg = $obj->{cfg};
ok t_cmp(defined $cfg, 1);

ok t_cmp($cfg->{pnlp}->{spec}, '0.1', 'spec');
ok t_cmp($cfg->{pnlp}->{codebase}, "http://$hostport/lib/apps", 'codebase');
ok t_cmp($cfg->{pnlp}->{href}, $uri, 'href');
ok t_cmp($cfg->{information}->{seen}, 1, 'information');
ok t_cmp($cfg->{title}->{value}, 'My App', 'title');
ok t_cmp($cfg->{vendor}->{value}, 'me.com', 'vendor');
ok t_cmp($cfg->{homepage}->{href}, "http://$hostport/docs/hello.html",
        'homepage');
ok t_cmp($cfg->{description}->[0]->{value}, 'A Perl WebStart Application',
        'description');
ok t_cmp($cfg->{perlws}->{version}, '0.1', 'perlws');

ok t_cmp($cfg->{resources}->{os}, 'MSWin32', 'os');
ok t_cmp($cfg->{resources}->{arch}, 'MSWin32-x86-multi-thread', 'arch');

ok t_cmp($cfg->{'allow-unsigned-pars'}->{seen}, 1, 'allow unsigned pars');

my $par_ref = $cfg->{par};
ok t_cmp(scalar(@$par_ref), 2, 'par files');
ok t_cmp($par_ref->[0]->{href}, 'A.par', 'A.par');
ok t_cmp($par_ref->[1]->{href}, 'C.par', 'C.par');

ok t_cmp($cfg->{'application-desc'}->{'main-par'}, 'A', 'main-par');
my $arg_ref = $cfg->{argument};
ok t_cmp(scalar(@$arg_ref), 4, 'args');
ok t_cmp($arg_ref->[0]->{value}, '--verbose', 'arg 1');
ok t_cmp($arg_ref->[1]->{value}, '--debug', 'arg 2');
ok t_cmp($arg_ref->[2]->{value}, '--arg1=arg', 'arg 3');
ok t_cmp($arg_ref->[3]->{value}, '--arg2=3', 'arg 4');

my $mod_ref = $cfg->{module};
ok t_cmp(scalar(@$mod_ref), 2, 'modules');
ok t_cmp($mod_ref->[0]->{value}, 'Tk', 'Tk');
ok t_cmp($mod_ref->[1]->{value}, 'LWP', 'LWP');

unlink($file);
