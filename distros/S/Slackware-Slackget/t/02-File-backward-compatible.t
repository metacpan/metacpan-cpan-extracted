use Test::More tests => 13;

BEGIN {
	use_ok( 'Slackware::Slackget::File' );
}

my $file = Slackware::Slackget::File->new('foo.txt');
ok( ref( $file ) eq 'Slackware::Slackget::File' );
$file->Add('this is only a test');
ok( $file->Get_line(0) eq 'this is only a test' );
$file->filename('bar.txt');
ok( $file->filename eq 'bar.txt' );
$file->Write() ;
ok( -e 'bar.txt' );
my $file2 = Slackware::Slackget::File->new('bar.txt', 'load-raw' => 1);
ok( $file->Get_line(0) eq $file2->Get_line(0) );
ok( $file->Lock_file() );
ok( $file2->Unlock_file() == 0 );
ok( $file2->Close() );
ok( $file->is_locked() );
ok( $file->Unlock_file() == 1 );
ok( $file->Unlock_file() == 2 );
ok( $file->Close() );

unlink 'bar.txt';
