use strict;
use warnings;

use File::Spec;
use FindBin ();
use Test::More;
use Net::Akismet::Protocol;

if ( ! $ENV{ANTISPAM_KEY} || ! $ENV{ANTISPAM_URL} ) {
    plan skip_all => 'Set ANTISPAM_KEY and ANTISPAM_URL in env to enable live testing';
}
else {
    plan tests=> 3;
}
my $akismet;
isa_ok($akismet=Net::Akismet::Protocol->new(key=>$ENV{ANTISPAM_KEY},url=>$ENV{ANTISPAM_URL}),'Net::Akismet::Protocol');
is($akismet->check(
        user_ip 		=> '10.10.10.11',
		user_agent 		=> 'Mozilla/5.0',
		comment_content		=> 'Run, Lola, Run, the spam will catch you!',
		comment_author		=> 'dosser',
		coment_author_email	=> 'dosser@subway.de',
		referrer		=> 'http://lola.home/',
    ),0,'Check spam:negative');
is($akismet->check(
        user_ip 		=> '192.168.1.1',
		user_agent 		=> 'Mozilla/6.0',
		comment_content		=> '<a href="http://premiumdiscountdrugs.com">buy now Viagra 60mg x 30 pills</a>',
		comment_author		=> 'dosser',
		coment_author_email	=> 'dosser@subway.de',
		referrer		=> 'http://spamking.net/',
    ),1,'Check spam');