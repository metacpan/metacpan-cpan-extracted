# -*- mode: cperl; cperl-indent-level: 4; cperl-continued-statement-offset: 4; indent-tabs-mode: nil -*-
use strict;
use warnings FATAL => 'all';

use Apache::Test qw{-withtestmore};
use Apache::TestUtil;
use Apache::TestUtil qw/t_write_perl_script t_mkdir t_catfile/;
use Apache::TestRequest qw{GET_BODY GET};

plan tests=>16;
#plan 'no_plan';

Apache::TestRequest::user_agent(reset => 1,
				requests_redirectable => 0);

my $resp;

my $droot=Apache::Test::vars('documentroot');
t_mkdir t_catfile $droot, 'perl';
t_write_perl_script t_catfile($droot, 'perl', 'die1.pl'), <<'SCRIPT';
my $r=shift;
$r->status_line("404 Not Found");
$r->safe_die(403);
print "Status: 200\n\nhuhu\n";
SCRIPT

t_write_perl_script t_catfile($droot, 'perl', 'die2.pl'), <<'SCRIPT';
$|=1;
print "Status: 200\n\nhuhu\n";
my $r=shift;
$r->safe_die(403);
print "haha";
SCRIPT

t_write_perl_script t_catfile($droot, 'perl', 'die3.pl'), <<'SCRIPT';
ModPerl2::Tools::safe_die(403);
print "Status: 200\n\nhuhu\n";
SCRIPT

t_write_perl_script t_catfile($droot, 'perl', 'die4.pl'), <<'SCRIPT';
$|=1;
print "Status: 200\n\nhuhu\n";
ModPerl2::Tools::safe_die(403);
SCRIPT

t_write_perl_script t_catfile($droot, 'perl', 'fetch1.pl'), <<'SCRIPT';
print "Status: 200\n\nbefore\n".ModPerl2::Tools::fetch_url('/data?10')."after\n";
SCRIPT

####################################################################
# $r->safe_die
####################################################################

$resp=GET '/perl/die1.pl';
ok $resp, '/perl/die1.pl: response object';
ok t_cmp $resp->code, 403, '/perl/die1.pl: code';
ok t_cmp $resp->content, qr!<title>403 Forbidden</title>!i,
         '/perl/die1.pl: content';
ok t_cmp $resp->content, qr/^(?!.*404)/s,
         '/perl/die1.pl: content does not contain 404';

$resp=GET '/perl/die2.pl';
ok $resp, '/perl/die2.pl: response object';
ok t_cmp $resp->code, 200, '/perl/die2.pl: code';
ok t_cmp $resp->content, "huhu\n", '/perl/die2.pl: content';

####################################################################
# ModPerl2::Tools::safe_die
####################################################################

$resp=GET '/perl/die3.pl';
ok $resp, '/perl/die3.pl: response object';
ok t_cmp $resp->code, 403, '/perl/die3.pl: code';
ok t_cmp $resp->content, qr!<title>403 Forbidden</title>!i,
         '/perl/die3.pl: content';

$resp=GET '/perl/die4.pl';
ok $resp, '/perl/die4.pl: response object';
ok t_cmp $resp->code, 200, '/perl/die4.pl: code';
ok t_cmp $resp->content, "huhu\n", '/perl/die4.pl: content';

$resp=GET '/perl/fetch1.pl';
ok $resp, '/perl/fetch1.pl: response object';
ok t_cmp $resp->code, 200, '/perl/fetch1.pl: code';
ok t_cmp $resp->content, "before\n".((("x"x79)."\n")x10)."after\n",
         '/perl/fetch1.pl: content';
