#!perl

use Test::Most;
use Try::Tiny;
use Postfix::ContentFilter;

try {
    require MIME::Parser;
} catch {
    plan skip_all => "MIME::Parser is needed for this test";
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

plan tests => 6;

my $cf = Postfix::ContentFilter->new;
is($cf->parser('MIME::Parser') => 'MIME::Parser') or die;

$Postfix::ContentFilter::sendmail = [ $cat ];

ok($cf->process (sub {
	my ($entity) = @_;
	
	isa_ok($entity => 'MIME::Entity') or die;

	is ($entity->head->get('Subject') => "foo\n");
	is_deeply ($entity->body => ["bar\n"]);
	
	$entity->head->set(Subject => 'bar');
	$entity->bodyhandle(MIME::Body::Scalar->new(["foo\n"]));
	
	return $entity;
}, $R)) or diag($Postfix::ContentFilter::error);

is($Postfix::ContentFilter::output, "Subject: bar\n\nfoo\n");
