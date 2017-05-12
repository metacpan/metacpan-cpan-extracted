use strict;
use warnings;

use Test::More;
use Parse::WBXML;
use Dir::Self;
use File::Slurp qw(read_file);
use File::Basename qw(basename);
use Try::Tiny;

my @src = glob __DIR__ . '/samples/xml/*.xml';
my @dst = glob __DIR__ . '/samples/wbxml/*.wbxml';

plan tests => scalar @dst;

foreach my $wbxml (@dst) {
	my $base = basename $wbxml;
	note $base;
	subtest $wbxml => sub {
		plan tests => 2;

		my $wbdata = read_file $wbxml;
		my $parser = Parse::WBXML->new;
		$parser->add_handler_for_event(
			version	=> sub {
				my ($self, $version) = @_;
				ok($self->version, 'have a version');
				$self;
			},
			publicid => sub {
				my ($self, $publicid) = @_;
				ok($self->publicid, 'have a public ID');
				$self;
			},
		);

		my $data = $wbdata;
		try { $parser->parse(\$data); } catch { note $_ };
	};
}
done_testing();

