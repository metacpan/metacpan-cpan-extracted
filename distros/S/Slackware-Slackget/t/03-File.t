use Test::More tests => 13;

BEGIN {
	use_ok( 'Slackware::Slackget::File' );
}

my $file = Slackware::Slackget::File->new('foo.txt');
ok( ref( $file ) eq 'Slackware::Slackget::File' );
$file->add('this is only a test');
ok( $file->get_line(0) eq 'this is only a test' );
$file->filename('bar.txt');
ok( $file->filename eq 'bar.txt' );
$file->Write() ;
ok( -e 'bar.txt' );
my $file2 = Slackware::Slackget::File->new('bar.txt', 'load-raw' => 1);
ok( $file->get_line(0) eq $file2->get_line(0) );
ok( $file->lock_file() );
ok( $file2->unlock_file() == 0 );
ok( $file2->Close() );
ok( $file->is_locked() );
ok( $file->unlock_file() == 1 );
ok( $file->unlock_file() == 2 );
ok( $file->Close() );

unlink 'bar.txt';
