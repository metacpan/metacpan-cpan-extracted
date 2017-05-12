package test_queue_df;
use strict;
use warnings;

use base qw( Test::Class );

use Test::Most;
use File::Temp;
# Set time zone to UTC for consistent test results
$ENV{TZ} = 'UTC';

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


# fake rand() to always return 0 for testing purposes.
# Because rand() is a builtin, it's hard to clobber...
BEGIN {
	*Sendmail::Queue::Qf::rand = sub { 0 };
	eval 'require Sendmail::Queue::Qf' or die $@;
};

my $USER = getpwuid($>);

sub make_tmpdir : Test(setup)
{
	my ($self) = @_;
	$self->{tmpdir} = File::Temp::tempdir( CLEANUP => 1 );
}

sub del_tmpdir : Test(teardown)
{
	my ($self) = @_;

	delete $self->{tmpdir};
}

sub test_constructor : Test(1)
{
	my $qf = Sendmail::Queue::Qf->new();
	isa_ok( $qf, 'Sendmail::Queue::Qf');
}

sub set_queue_id_manually : Test(1)
{
	my $qf = Sendmail::Queue::Qf->new();
	$qf->set_queue_id( 'wookie' );
	is( $qf->get_queue_id(), 'wookie', 'Got the queue ID we set');
}

sub generate_queue_id : Test(3)
{
	my ($self) = @_;

	my $qf = Sendmail::Queue::Qf->new({
		queue_directory => $self->{tmpdir},
		timestamp => 1234567890,
	});

	ok( $qf->create_and_lock, 'Created a qf file with a unique ID');

	my $pid = sprintf("%06d", $$);
	is( $qf->get_queue_id(), "n1DNVU00$pid", 'Queue ID is correct and has sequence number of 0');
	ok( -r "$self->{tmpdir}/qf" . $qf->get_queue_id, 'Queue file exists');
}

sub generate_qf_file : Test(2)
{
	my ($self) = @_;

	my $qf = Sendmail::Queue::Qf->new({
		timestamp       => 1234567890,
		queue_directory => $self->{tmpdir},
	});

	# All of this evil is to force file collisions so that we can see that
	# the sequence number is 3 higher than the value given by rand().
	my $count = 0;
	my $existing_file = "$self->{tmpdir}/foo";
	open(FH,">$existing_file") or die $!;
	close FH;
	no warnings 'once';
	local *File::Spec::catfile = sub {
		my $class = shift;
		if( $count++ < 3 ) {
			note("Forcing collision for $_[1]");
			return $existing_file;
		}
		return join('/', @_);
	};

	ok( $qf->create_and_lock, 'Created a qf file with a unique ID');

	my $pid = sprintf("%06d", $$);
	is( $qf->get_queue_id(), "n1DNVU03$pid", 'Queue ID is correct and has sequence number of 3');
}


sub write_qf : Test(4)
{
	my ($self) = @_;

	my $qf = Sendmail::Queue::Qf->new({
		timestamp       => 1234567890,
		queue_directory => $self->{tmpdir},
		protocol    => 'ESMTP',
		sender      => 'dmo@dmo.ca',
		recipients  => [ 'dmo@roaringpenguin.com' ],
	});

	ok( $qf->create_and_lock, 'Created a qf file with a unique ID');
	$qf->set_headers("From: foobar\nTo: someone\nDate: Wed, 07 Nov 2007 14:54:33 -0500\n");

	$qf->write();

	ok( $qf->sync, 'sync() succeeded');

	ok( $qf->close, 'close() succeeded' );

	my $expected = <<'END';
V6
T1234567890
K0
N0
P30000
F
${daemon_flags}
$rESMTP
S<dmo@dmo.ca>
rRFC822; dmo@roaringpenguin.com
RPFD:dmo@roaringpenguin.com
H??From: foobar
H??To: someone
H??Date: Wed, 07 Nov 2007 14:54:33 -0500
.
END

	is( slurp( $qf->get_queue_filename ), $expected, 'Wrote expected data');

}

sub write_qf_with_flags : Test(4)
{
	my ($self) = @_;

	my $qf = Sendmail::Queue::Qf->new({
		timestamp       => 1234567890,
		queue_directory => $self->{tmpdir},
		protocol    => 'ESMTP',
		sender      => 'dmo@dmo.ca',
		recipients  => [ 'dmo@roaringpenguin.com' ],
	});

	ok( $qf->create_and_lock, 'Created a qf file with a unique ID');
	$qf->set_headers("From: foobar\nTo: someone\nDate: Wed, 07 Nov 2007 14:54:33 -0500\n");
	$qf->set_data_is_8bit(1);

	$qf->write();

	ok( $qf->sync, 'sync() succeeded');

	ok( $qf->close, 'close() succeeded' );

	my $expected = <<'END';
V6
T1234567890
K0
N0
P30000
F8
${daemon_flags}
$rESMTP
S<dmo@dmo.ca>
rRFC822; dmo@roaringpenguin.com
RPFD:dmo@roaringpenguin.com
H??From: foobar
H??To: someone
H??Date: Wed, 07 Nov 2007 14:54:33 -0500
.
END

	is( slurp( $qf->get_queue_filename ), $expected, 'Wrote expected data');

}

sub generate_received : Test(3)
{
	my ($self) = @_;

	my $qf = Sendmail::Queue::Qf->new({
		timestamp       => 1195000000,
		queue_directory => $self->{tmpdir},
	});

	ok( $qf->create_and_lock, 'Created a qf file with a unique ID');

	# First, try it with no values set.
	$qf->synthesize_received_header();
	my $r_hdr = qr/^Received: \(from $USER\@localhost\)\n\tby localhost \(Sendmail::Queue\) id lAE0Qe..\d{6}; Wed, 14 Nov 2007 00:26:40 \+0000$/;
	like( $qf->get_received_header(), $r_hdr, 'Got expected Received header');

	# Wipe and try again
	$qf->set_headers('');

	$qf->set_sender('dmo@dmo.ca');
	$qf->set_helo('loser');
	$qf->set_protocol('ESMTP');
	$qf->set_relay_address('999.888.777.666');
	$qf->set_relay_hostname('broken.dynamic.server.example.com');
	$qf->set_local_hostname('mail.roaringpenguin.com');
	$qf->add_recipient('dmo@roaringpenguin.com');


	$qf->synthesize_received_header();
	$r_hdr = qr/^Received: from loser \Q(broken.dynamic.server.example.com [999.888.777.666])
	by mail.roaringpenguin.com (envelope-sender <dmo\E\@dmo.ca>\Q) (Sendmail::Queue)\E with ESMTP id lAE0Qe..\d{6}\n\tfor <dmo\@roaringpenguin\.com>; Wed, 14 Nov 2007 00:26:40 \+0000$/;

	like( $qf->get_received_header(), $r_hdr, 'Got expected Received header');
}

sub clone_qf_file : Test(10)
{
	my ($self) = @_;

	my $qf = Sendmail::Queue::Qf->new({
		timestamp       => 1195000000,
		queue_directory => $self->{tmpdir},
	});

	$qf->set_sender('dmo@dmo.ca');
	$qf->set_helo('loser');
	$qf->set_protocol('ESMTP');
	$qf->set_relay_address('999.888.777.666');
	$qf->set_relay_hostname('broken.dynamic.server.example.com');
	$qf->set_local_hostname('mail.roaringpenguin.com');
	$qf->add_recipient('dmo@roaringpenguin.com');
	$qf->set_macros({ r => 'ESMTP', auth_authen => 'foobar', auth_author => 'foobar@example.com', auth_type => 'DIGEST-MD5' });
	ok( $qf->create_and_lock, 'Created a qf file with a unique ID');

	$qf->synthesize_received_header();
	my $r_hdr = qr/^Received: from loser \Q(broken.dynamic.server.example.com [999.888.777.666])
	by mail.roaringpenguin.com (envelope-sender <dmo\E\@dmo.ca>\Q) (Sendmail::Queue)\E with ESMTP id lAE0Qe..\d{6}\n\tfor <dmo\@roaringpenguin\.com>; Wed, 14 Nov 2007 00:26:40 \+0000$/;

	like( $qf->get_received_header(), $r_hdr, 'Got expected Received header');

	my $clone;
	lives_ok { $clone = $qf->clone() } 'clone() lives';
	isa_ok($clone, 'Sendmail::Queue::Qf');

	my %expected = %{$qf};
	delete $expected{$_} for qw(queue_id sender queue_fh received_header);
	$expected{recipients} = [];
	cmp_deeply(
		$clone,
		noclass(\%expected),
		'Clone has correct data');

	isnt( $clone->get_macros(), $qf->get_macros(), 'get_macros() on clone returns a different hashref');

	is( $clone->get_sender, undef, 'clone has no sender');
	cmp_deeply( $clone->get_recipients, [], 'clone has empty recipients');
	is( $clone->get_queue_id, undef, 'clone has no queue id');
	is( $clone->get_queue_fh, undef, 'clone has no queue fh');
}

sub unlink_qf_file : Test(9)
{
	my ($self) = @_;

	my $qf = Sendmail::Queue::Qf->new({
		timestamp       => 1195000000,
		queue_directory => $self->{tmpdir},
	});

	ok( ! $qf->get_queue_filename, 'Object has no filename');
	ok( ! $qf->unlink, 'Unlink fails when no filename');

	ok( $qf->create_and_lock, 'Created a file');
	ok( -e $qf->get_queue_filename, 'File exists');
	ok( $qf->unlink, 'Unlink succeeds when file exists');
	ok( ! -e $qf->get_queue_filename, 'File now deleted');

	ok( ! $qf->unlink, 'Unlink fails because file now does not exist');

	dies_ok { $qf->write() } 'Write dies because queue file closed and deleted';
	like($@, qr/write\(\) cannot write without an open filehandle/, '... with expected error');
}

sub write_qf_gigantic_header : Test(4)
{
	my ($self) = @_;

	my $qf = Sendmail::Queue::Qf->new({
		timestamp       => 1234567890,
		queue_directory => $self->{tmpdir},
		protocol    => 'ESMTP',
		sender      => 'dmo@dmo.ca',
		recipients  => [ 'dmo@roaringpenguin.com' ],
	});

	ok( $qf->create_and_lock, 'Created a qf file with a unique ID');

	my @headers = (
		'From: foobar',
		'To: someone',
		'Date: Wed, 07 Nov 2007 14:54:33 -0500',
		"X-Already-Split: This is the song that doesn't end.  It just goes on and on, my friends.\n\tSome people started singing it not knowing what it was\n\tand they'll continue singing it forever just because...",
		'X-Bottles-Of-Beer: ' . join(', ', map { $_ = 100 - $_; "$_ bottles of beer on the wall" } 1..99 ),
	);

	$qf->set_headers(join("\n", @headers));


	$qf->write();

	ok( $qf->sync, 'sync() succeeded');

	ok( $qf->close, 'close() succeeded' );

	my $expected = <<'END';
V6
T1234567890
K0
N0
P30000
F
${daemon_flags}
$rESMTP
S<dmo@dmo.ca>
rRFC822; dmo@roaringpenguin.com
RPFD:dmo@roaringpenguin.com
H??From: foobar
H??To: someone
H??Date: Wed, 07 Nov 2007 14:54:33 -0500
H??X-Already-Split: This is the song that doesn't end.  It just goes on and on, my friends.
	Some people started singing it not knowing what it was
	and they'll continue singing it forever just because...
H??X-Bottles-Of-Beer: 99 bottles of beer on the wall, 98 bottles of beer on the wall, 97 bottles of beer on the wall, 96 bottles of beer on the wall, 95 bottles of beer on the wall, 94 bottles of beer on the wall, 93 bottles of beer on the wall, 92 bottles of beer on the wall, 91 bottles of beer on the wall, 90 bottles of beer on the wall, 89 bottles of beer on the wall, 88 bottles of beer on the wall, 87 bottles of beer on the wall, 86 bottles of beer on the wall, 85 bottles of beer on the wall, 84 bottles of beer on the wall, 83 bottles of beer on the wall, 82 bottles of beer on the wall, 81 bottles of beer on the wall, 80 bottles of beer on the wall, 79 bottles of beer on the wall, 78 bottles of beer on the wall, 77 bottles of beer on the wall, 76 bottles of beer on the wall, 75 bottles of beer on the wall, 74 bottles of beer on the wall, 73 bottles of beer on the wall, 72 bottles of beer on the wall, 71 bottles of beer on the wall, 70 bottles of beer on the wall, 69 bottles of beer
	on the wall, 68 bottles of beer on the wall, 67 bottles of beer on the wall, 66 bottles of beer on the wall, 65 bottles of beer on the wall, 64 bottles of beer on the wall, 63 bottles of beer on the wall, 62 bottles of beer on the wall, 61 bottles of beer on the wall, 60 bottles of beer on the wall, 59 bottles of beer on the wall, 58 bottles of beer on the wall, 57 bottles of beer on the wall, 56 bottles of beer on the wall, 55 bottles of beer on the wall, 54 bottles of beer on the wall, 53 bottles of beer on the wall, 52 bottles of beer on the wall, 51 bottles of beer on the wall, 50 bottles of beer on the wall, 49 bottles of beer on the wall, 48 bottles of beer on the wall, 47 bottles of beer on the wall, 46 bottles of beer on the wall, 45 bottles of beer on the wall, 44 bottles of beer on the wall, 43 bottles of beer on the wall, 42 bottles of beer on the wall, 41 bottles of beer on the wall, 40 bottles of beer on the wall, 39 bottles of beer on the wall, 38 bottles of beer on
	the wall, 37 bottles of beer on the wall, 36 bottles of beer on the wall, 35 bottles of beer on the wall, 34 bottles of beer on the wall, 33 bottles of beer on the wall, 32 bottles of beer on the wall, 31 bottles of beer on the wall, 30 bottles of beer on the wall, 29 bottles of beer on the wall, 28 bottles of beer on the wall, 27 bottles of beer on the wall, 26 bottles of beer on the wall, 25 bottles of beer on the wall, 24 bottles of beer on the wall, 23 bottles of beer on the wall, 22 bottles of beer on the wall, 21 bottles of beer on the wall, 20 bottles of beer on the wall, 19 bottles of beer on the wall, 18 bottles of beer on the wall, 17 bottles of beer on the wall, 16 bottles of beer on the wall, 15 bottles of beer on the wall, 14 bottles of beer on the wall, 13 bottles of beer on the wall, 12 bottles of beer on the wall, 11 bottles of beer on the wall, 10 bottles of beer on the wall, 9 bottles of beer on the wall, 8 bottles of beer on the wall, 7 bottles of beer on the
	wall, 6 bottles of beer on the wall, 5 bottles of beer on the wall, 4 bottles of beer on the wall, 3 bottles of beer on the wall, 2 bottles of beer on the wall, 1 bottles of beer on the wall
.
END

	is( slurp( $qf->get_queue_filename ), $expected, 'Wrote expected data');

}

sub write_qf_exceptions : Test(5)
{
	my ($self) = @_;

	my $qf = Sendmail::Queue::Qf->new({
		timestamp       => 1234567890,
		queue_directory => $self->{tmpdir},
		protocol    => 'ESMTP',
		recipients  => [ 'dmo@roaringpenguin.com' ],
	});

	ok( $qf->create_and_lock, 'Created a qf file with a unique ID');

	my @headers = (
		'From: foobar',
		'To: someone',
		'Date: Wed, 07 Nov 2007 14:54:33 -0500',
	);

	$qf->set_headers(join("\n", @headers));

	throws_ok { $qf->write() } qr/Cannot queue a message with no sender address/, 'Dies as expected when no sender provided';

	ok( $qf->unlink(), 'Unlinked previous attempt to write');
	ok( $qf->create_and_lock, 'Created a qf file with a unique ID');
	$qf->set_sender('dmo@roaringpenguin.com');
	$qf->set_recipients([]);
	throws_ok { $qf->write() } qr/Cannot queue a message with no recipient addresses/, 'Dies as expected when no recipients provided';
}

__PACKAGE__->runtests unless caller();
