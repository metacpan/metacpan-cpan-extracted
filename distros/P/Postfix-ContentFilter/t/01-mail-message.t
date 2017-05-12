#!perl

use Test::Most;
use Try::Tiny;
use Postfix::ContentFilter;

try {
    require Mail::Message;
} catch {
    plan skip_all => "Mail::Message is needed for this test";
};

pipe (my $R, my $W) or die "pipe: $!";

print $W "Subject: foo\n\nbar\n";
close $W;

@ARGV = ();

delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV', 'PATH'};

my $cat = '/bin/cat';

unless (-x $cat) {
	plan skip_all => "$cat not available";
	exit;
}

plan tests => 5;

my $cf = Postfix::ContentFilter->new;
is($cf->parser('Mail::Message') => 'Mail::Message') or die;

$Postfix::ContentFilter::sendmail = [ $cat ];

ok($cf->process (sub {
	my ($entity) = @_;
	
	isa_ok($entity => 'Mail::Message') or die;
	
	is ($entity->subject => "foo");
	
	# TODO: change subject.
	
	return $entity;
}, $R)) or diag($Postfix::ContentFilter::error);

# TODO: test against 
like($Postfix::ContentFilter::output, qr{Subject: foo\n}m);

done_testing;
