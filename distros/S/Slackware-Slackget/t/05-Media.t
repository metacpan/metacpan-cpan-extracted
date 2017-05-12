use Test::More tests => 8;

BEGIN {
	use_ok( 'Slackware::Slackget::Media' );
}

my $media = Slackware::Slackget::Media->new('slackware',
		'description'=>'The official Slackware web site',
		'web-link' => 'http://www.slackware.com/',
		'update-repository' => {faster => 'http://ftp.belnet.be/packages/slackware/slackware-12.0/'},
		'files' => {
			'filelist' => 'FILELIST.TXT',
			'checksums' => 'CHECKSUMS.md5',
			'packages' => 'PACKAGES.TXT.gz'
		}
	);

ok( $media );
ok( $media->get_value('description') eq 'The official Slackware web site' );
ok($media->set_value('description','This is only a test') eq 'This is only a test' );
ok( $media->get_value('description') eq 'This is only a test' );
ok( $media->url eq 'http://www.slackware.com/' );
ok( $media->shortname eq 'slackware' );
ok( $media->host eq 'http://ftp.belnet.be/packages/slackware/slackware-12.0/' );
