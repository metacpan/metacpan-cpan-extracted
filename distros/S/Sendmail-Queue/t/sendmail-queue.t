package test_queue;
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

use Sendmail::Queue;

my $USER = getpwuid($>);

sub make_tmpdir : Test(setup)
{
	my ($self) = @_;
	$self->{tmpdir} = File::Temp::tempdir( CLEANUP => 1 );
}

sub del_tmpdir : Test(teardown)
{
	my ($self) = @_;

	delete $self->{tmpdir}
}

sub test_constructor : Test(1)
{
	my ($self) = @_;

	my $q = Sendmail::Queue->new({
		queue_directory => $self->{tmpdir}
	});
	isa_ok( $q, 'Sendmail::Queue');
}

sub test_accessors : Test(6)
{
	my ($self) = @_;

	my $q = Sendmail::Queue->new({
		queue_directory => $self->{tmpdir}
	});
	is( $q->get_queue_directory(), $self->{tmpdir}, 'get_queue_directory' );
	is( $q->get_qf_directory(),    $self->{tmpdir}, 'get_qf_directory' );
	is( $q->get_df_directory(),    $self->{tmpdir}, 'get_df_directory' );

	mkdir("$self->{tmpdir}/qf");
	mkdir("$self->{tmpdir}/df");

	$q = Sendmail::Queue->new({
		queue_directory => $self->{tmpdir}
	});
	is( $q->get_queue_directory(), $self->{tmpdir},      'get_queue_directory' );
	is( $q->get_qf_directory(),    "$self->{tmpdir}/qf", 'get_qf_directory' );
	is( $q->get_df_directory(),    "$self->{tmpdir}/df", 'get_df_directory' );
}

sub queue_message : Test(4)
{
	my ($self) = @_;

	my $queue = Sendmail::Queue->new({
		queue_directory => $self->{tmpdir}
	});

	my $data = <<EOM;
From: foobar
To: someone
Date: Wed, 07 Nov 2007 19:54:33 +0000

Test message
-- 
Dave
EOM

	my $qid = $queue->queue_message({
		sender => 'dmo@dmo.ca',
		recipients => [
			'dmo@roaringpenguin.com',
			'dfs@roaringpenguin.com',
		],
		data => $data,
		timestamp => 1234567890,
		protocol => 'ESMTP',
	});

	my $qf_regex = qr/^V6
T1234567890
K0
N0
P30000
F
\${daemon_flags}
\$rESMTP
S<dmo\@dmo.ca>
rRFC822; dmo\@roaringpenguin.com
RPFD:dmo\@roaringpenguin.com
rRFC822; dfs\@roaringpenguin.com
RPFD:dfs\@roaringpenguin.com
H\?\?Received: \(from $USER\@localhost\)
	by localhost \(envelope-sender <dmo\@dmo\.ca>\) \(Sendmail::Queue\) with ESMTP id n1DNVU..\d{6}; Fri, 13 Feb 2009 23:31:30 \+0000
H\?\?From: foobar
H\?\?To: someone
H\?\?Date: Wed, 07 Nov 2007 19:54:33 \+0000
.
$/;

	my $df_expected =<<'EOM';
Test message
-- 
Dave
EOM

	like( slurp( "$self->{tmpdir}/qf$qid" ), $qf_regex, 'Wrote expected qf data');
	is( slurp( "$self->{tmpdir}/df$qid" ), $df_expected, 'Wrote expected df data');

	is( unlink(glob("$self->{tmpdir}/qf*")), 1, 'Unlinked one queue file');
	is( unlink(glob("$self->{tmpdir}/df*")), 1, 'Unlinked one data file');

}

sub queue_multiple_success : Test(11)
{
	my ($self) = @_;

	my $queue = Sendmail::Queue->new({
		queue_directory => $self->{tmpdir}
	});

	my $data = <<EOM;
From: foobar
To: someone
Date: Wed, 07 Nov 2007 19:54:33 +0000

Test message
-- 
Dave
EOM

	my $qids;
	lives_ok {
		$qids = $queue->queue_multiple({
			envelopes => {
				stream_one => {
					sender => 'dmo@dmo.ca',
					recipients => [
					'dmo@roaringpenguin.com',
					'dfs@roaringpenguin.com',
					],
				},
				stream_two => {
					sender => 'dmo@dmo.ca',
					recipients => [
						'foo@roaringpenguin.com',
						'bar@roaringpenguin.com',
					],
				},
			},
			data => $data,
			timestamp => 1234567890,
			protocol => 'ESMTP',
		});
	} '->queue_multiple() lives';

	cmp_deeply( [ keys %$qids ], bag( qw(stream_one stream_two) ), 'Got a qid for all sets');

	my $qf_one_regex = qr/^V6
T1234567890
K0
N0
P30000
F
\${daemon_flags}
\$rESMTP
S<dmo\@dmo.ca>
rRFC822; dmo\@roaringpenguin.com
RPFD:dmo\@roaringpenguin.com
rRFC822; dfs\@roaringpenguin.com
RPFD:dfs\@roaringpenguin.com
H\?\?Received: \(from $USER\@localhost\)
	by localhost \(envelope-sender <dmo\@dmo\.ca>\) \(Sendmail::Queue\) with ESMTP id n1DNVU..\d{6}; Fri, 13 Feb 2009 23:31:30 \+0000
H\?\?From: foobar
H\?\?To: someone
H\?\?Date: Wed, 07 Nov 2007 19:54:33 \+0000
.
$/;

	my $qf_two_regex = qr/^V6
T1234567890
K0
N0
P30000
F
\${daemon_flags}
\$rESMTP
S<dmo\@dmo.ca>
rRFC822; foo\@roaringpenguin.com
RPFD:foo\@roaringpenguin.com
rRFC822; bar\@roaringpenguin.com
RPFD:bar\@roaringpenguin.com
H\?\?Received: \(from $USER\@localhost\)
	by localhost \(envelope-sender <dmo\@dmo\.ca>\) \(Sendmail::Queue\) with ESMTP id n1DNVU..\d{6}; Fri, 13 Feb 2009 23:31:30 \+0000
H\?\?From: foobar
H\?\?To: someone
H\?\?Date: Wed, 07 Nov 2007 19:54:33 \+0000
.
$/;

	my $df_expected =<<'EOM';
Test message
-- 
Dave
EOM

	isnt( $qids->{stream_one}, $qids->{stream_two}, 'Got two different queue IDs');

	like( slurp( "$self->{tmpdir}/qf$qids->{stream_one}" ), $qf_one_regex, 'Wrote expected qf data');
	like( slurp( "$self->{tmpdir}/qf$qids->{stream_two}" ), $qf_two_regex, 'Wrote expected qf data');
	is( slurp( "$self->{tmpdir}/df$qids->{stream_one}" ), $df_expected, 'Wrote expected df data');
	is( slurp( "$self->{tmpdir}/df$qids->{stream_two}" ), $df_expected, 'Wrote expected df data for stream two');

	is( (stat("$self->{tmpdir}/df$qids->{stream_one}"))[1],
	    (stat("$self->{tmpdir}/df$qids->{stream_two}"))[1],
	    'Both df files have the same inode number');

	is( (stat("$self->{tmpdir}/df$qids->{stream_one}"))[3], 2, 'nlink is 2 on df file');

	is( unlink(glob("$self->{tmpdir}/qf*")), 2, 'Unlinked two queue files');
	is( unlink(glob("$self->{tmpdir}/df*")), 2, 'Unlinked two data files');
}

sub queue_message_failure : Test(4)
{
	my ($self) = @_;

	return 'Skipping test -- root ignores directory permissions' if ($> == 0);

	my $queue = Sendmail::Queue->new({
		queue_directory => $self->{tmpdir}
	});

	my $data = <<EOM;
From: foobar
To: someone
Date: Wed, 07 Nov 2007 19:54:33 +0000

Test message
-- 
Dave
EOM

	chmod 0555, $self->{tmpdir};

	dies_ok {
	my $qid = $queue->queue_message({
		sender => 'dmo@dmo.ca',
		recipients => [
			'dmo@roaringpenguin.com',
			'dfs@roaringpenguin.com',
		],
		data => $data,
		timestamp => 1234567890,
	}); } 'queue_message() dies';

	chmod 0755, $self->{tmpdir};

	like( $@, qr{Error creating qf file /tmp/[^/]+/qfn1DNVU..\d{6}: Permission denied}, 'Got expected error');

	my @qf = glob("$self->{tmpdir}/qf*");
	my @df = glob("$self->{tmpdir}/df*");

	is( scalar @qf, 0, 'No qf files');
	is( scalar @df, 0, 'No df files');

}

sub queue_multiple_failure : Test(6)
{
	my ($self) = @_;

	my $queue = Sendmail::Queue->new({
		queue_directory => $self->{tmpdir}
	});

	my $data = <<EOM;
From: foobar
To: someone
Date: Wed, 07 Nov 2007 19:54:33 +0000

Test message
-- 
Dave
EOM

	no warnings 'redefine';
	local *Sendmail::Queue::Df::hardlink_to = sub { die q{we made the second one die} };

	my $qf_unlink = \&Sendmail::Queue::Qf::unlink;
	my $qf_unlink_count=0;
	local *Sendmail::Queue::Qf::unlink = sub { $qf_unlink_count++; goto &$qf_unlink };

	my $df_unlink = \&Sendmail::Queue::Df::unlink;
	my $df_unlink_count=0;
	local *Sendmail::Queue::Df::unlink = sub { $df_unlink_count++; goto &$df_unlink };
	use warnings 'redefine';

	dies_ok {
	my $qid = $queue->queue_multiple({
		sender => 'dmo@dmo.ca',
		data => $data,
		timestamp => 1234567890,
		envelopes => {
			one => {
				recipients => [
					'dmo@roaringpenguin.com',
				],
			},
			two => {
				recipients => [
					'dfs@roaringpenguin.com',
				],
			},
		}
	}); } 'queue_multiple() dies';

	like( $@, qr{we made the second one die}, 'Got expected error');

	my @qf = glob("$self->{tmpdir}/qf*");
	my @df = glob("$self->{tmpdir}/df*");

	is( $qf_unlink_count, 2, 'Got qf_unlink_count of 2');
	is( $df_unlink_count, 2, 'Got df_unlink_count of 1');

	is( scalar @qf, 0, 'No qf files');
	is( scalar @df, 0, 'No df files');
}

sub queue_message_8bit : Test(4)
{
	my ($self) = @_;

	my $queue = Sendmail::Queue->new({
		queue_directory => $self->{tmpdir}
	});

	my $data = <<"EOM";
From: foobar
To: someone
Date: Wed, 07 Nov 2007 19:54:33 +0000

Test message with m\x{94}\x{94}se!

-- 
Dave
EOM

	my $qid = $queue->queue_message({
		sender => 'dmo@dmo.ca',
		recipients => [
			'dmo@roaringpenguin.com',
			'dfs@roaringpenguin.com',
		],
		data => $data,
		timestamp => 1234567890,
		protocol => 'ESMTP',
	});

	my $qf_regex = qr/^V6
T1234567890
K0
N0
P30000
F8
\${daemon_flags}
\$rESMTP
S<dmo\@dmo.ca>
rRFC822; dmo\@roaringpenguin.com
RPFD:dmo\@roaringpenguin.com
rRFC822; dfs\@roaringpenguin.com
RPFD:dfs\@roaringpenguin.com
H\?\?Received: \(from $USER\@localhost\)
	by localhost \(envelope-sender <dmo\@dmo\.ca>\) \(Sendmail::Queue\) with ESMTP id n1DNVU..\d{6}; Fri, 13 Feb 2009 23:31:30 \+0000
H\?\?From: foobar
H\?\?To: someone
H\?\?Date: Wed, 07 Nov 2007 19:54:33 \+0000
.
$/;

	my $df_expected =<<"EOM";
Test message with m\x{94}\x{94}se!

-- 
Dave
EOM

	like( slurp( "$self->{tmpdir}/qf$qid" ), $qf_regex, 'Wrote expected qf data');
	is( slurp( "$self->{tmpdir}/df$qid" ), $df_expected, 'Wrote expected df data');

	is( unlink(glob("$self->{tmpdir}/qf*")), 1, 'Unlinked one queue file');
	is( unlink(glob("$self->{tmpdir}/df*")), 1, 'Unlinked one data file');

}

__PACKAGE__->runtests unless caller();
