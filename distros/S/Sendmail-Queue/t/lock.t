package test_lock;
use strict;
use warnings;

use base qw(Test::Class);

use Test::Most;
use File::Temp;


use Sendmail::Queue;

my $USER = getpwuid($>);

sub locate_sendmail
{
	my @dirs;
	@dirs = split(/:/, ($ENV{'PATH'} || ''));
	push(@dirs, '/sbin');
	push(@dirs, '/usr/sbin');
	push(@dirs, '/bin');
	push(@dirs, '/usr/bin');

	foreach my $d (@dirs) {
		if (-x "$d/sendmail") {
			# make sure it's the REAL sendmail
			# but don't open anything bigger than 100MB to
			# avoid DoS
			if ((-s "$d/sendmail" < 100*1024*1024) && open(SM, "<$d/sendmail")) {
				local $/;
				my $massive_slurp = <SM>;
				close(SM);
				if ($massive_slurp =~ /DontBlameSendmail/) {
					return "$d/sendmail";
				}
			}
		}
	}
	return undef;
}

my $SENDMAIL = locate_sendmail();

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

sub test_locking : Test(1)
{
	my ($self) = @_;
	if (!defined($SENDMAIL)) {
		return "Skipping lock test: Could not locate Sendmail executable";
	}
	my $q = Sendmail::Queue->new({queue_directory => $self->{tmpdir}});
	my $qf = Sendmail::Queue::Qf->new({
		queue_directory => $self->{tmpdir}
	});
	$qf->set_headers("From: foo\nTo: bar\nSubject: Blech\n");
	$qf->set_sender('devnull@roaringpenguin.com');
	$qf->add_recipient('devnull@roaringpenguin.com');
	$qf->create_and_lock($q->{lock_both});
	$qf->write();
	$qf->sync();
	my $df = Sendmail::Queue::Df->new({
		queue_directory => $self->{tmpdir},
		queue_id        => $qf->get_queue_id()});
	$df->set_data("Wookie!\n");
	$df->write();

	# Now try running sendmail
	$ENV{'PATH'} .= ":/sbin:/usr/sbin";
	my $qid = $qf->get_queue_id();
	my $tmp = $self->{tmpdir};
	my $output = `$SENDMAIL -v -qI$qid -OQueueDirectory=$tmp 2>&1`;
	like($output, qr/$qid: locked/, 'Queue file was successfully locked according to sendmail');
}

__PACKAGE__->runtests unless caller();
