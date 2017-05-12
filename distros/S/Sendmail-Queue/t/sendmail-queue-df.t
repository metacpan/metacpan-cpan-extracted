package test_queue_df;
use strict;
use warnings;
use base qw( Test::Class );

use Test::Most;
use File::Temp;

sub slurp
{
	my ($fname) = @_;
	my $data;
	local $/;
	if (open(SLURP, "<$fname")) {
		$data = <SLURP>;
		close(SLURP);
	}
	return $data;
}


use Sendmail::Queue::Df;

sub test_constructor : Test(1)
{
	my $df = Sendmail::Queue::Df->new();
	isa_ok( $df, 'Sendmail::Queue::Df');
}

sub set_queue_id_manually : Test(1)
{
	my $df = Sendmail::Queue::Df->new();
	$df->set_queue_id( 'wookie' );
	is( $df->get_queue_id(), 'wookie', 'Got the queue ID we set');
}

sub write_df_file : Test(1)
{
	my $df = Sendmail::Queue::Df->new();
	$df->set_queue_id( 'wookie' );

	my $dir = File::Temp::tempdir( CLEANUP => 1 );

	$df->set_queue_directory( $dir );

	my $expected = <<'END';
This is the message body

-- 
Dave
END

	$df->set_data( $expected );
	$df->write();

	is( slurp( $df->get_data_filename ), $expected, 'Wrote expected data');
}

sub hardlink_df_file : Test(3)
{
	my $df = Sendmail::Queue::Df->new();
	$df->set_queue_id( 'DoubleWookie' );

	my $dir = File::Temp::tempdir( CLEANUP => 1 );

	$df->set_queue_directory( $dir );

	my $expected = <<'END';
This is another message body

-- 
Dave
END

	my $file = $df->get_queue_directory() . "/testfile";

	open(FH, ">$file") or die $!;
	print FH $expected or die $!;
	close FH or die $!;

	$df->hardlink_to( $file );

	is( (stat($df->get_data_filename))[1],
	    (stat($file))[1],
	    'Both files have the same inode number');

	$df->write();

	is( slurp( $df->get_data_filename ), $expected, 'Linked to expected data');

	unlink $file or die $!;

	is( slurp( $df->get_data_filename ), $expected, 'Unlinking original causes no problems');


}

sub unlink_df_file : Test(7)
{
	my $df = Sendmail::Queue::Df->new();
	my $dir = File::Temp::tempdir( CLEANUP => 1 );
	$df->set_queue_directory( $dir );

	ok( ! $df->get_data_filename, 'Object has no filename');
	ok( ! $df->unlink, 'Unlink fails when no filename');

	$df->set_data('foo');
	$df->set_queue_id( 'chewbacca' );
	ok( $df->write, 'Created a file');
	ok( -e $df->get_data_filename, 'File exists');
	ok( $df->unlink, 'Unlink succeeds when file exists');
	ok( ! -e $df->get_data_filename, 'File now deleted');

	ok( ! $df->unlink, 'Unlink fails because file now does not exist');
}

__PACKAGE__->runtests unless caller();
