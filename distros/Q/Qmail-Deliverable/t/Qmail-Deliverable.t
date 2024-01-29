
use Config;
use Test::More;

use lib 'lib';
$Qmail::Deliverable::qmail_dir = 't/fixtures';


BEGIN {
    use_ok( 'Qmail::Deliverable', ':all' );
}

Qmail::Deliverable::reread_config();
test_qmail_user();

done_testing();
exit;


sub test_qmail_user {
	my $r = Qmail::Deliverable::qmail_user('matt@example.com');
	is($r, 'matt@example.com', "qmail_user: $r");

	my $r = Qmail::Deliverable::qmail_user('matt-ext@example.com');
	is($r, 'matt-ext@example.com', "qmail_user: $r");

	my @r = Qmail::Deliverable::qmail_user('luser-ext@example.com');
	is_deeply(
		\@r,
		[ 'vpopmail', '89', '89', 't/fixtures/domains/example.com', '-', 'luser-ext@example.com' ],
		"qmail_user: $r[5]"
	);
}
