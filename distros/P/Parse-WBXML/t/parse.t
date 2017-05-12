use strict;
use warnings;
use Test::More tests => 7;
use Parse::WBXML;
use List::Util qw(sum);

=pod

Converted from:

 <?xml version="1.0"?>
 <!DOCTYPE sl PUBLIC "-//WAPFORUM//DTD SL 1.0//EN" "http://www.wapforum.org/DTD/sl.dtd">
 <sl href="http://www.yahoo.edu/"></sl>

=cut

my $wbdata = join '', map pack('H*', $_), qw(03 06 6a 00 85 0a 03 79 61 68 6f 6f 00 86 01);
my $parser = new_ok('Parse::WBXML');
$parser->add_handler_for_event(
	version	=> sub {
		my ($self, $version) = @_;
		is($self->version, '1.3', 'have correct version');
		$self;
	},
	publicid => sub {
		my ($self, $publicid) = @_;
		is($self->publicid, "-//WAPFORUM//DTD SL 1.0//EN", 'public ID is correct');
		$self;
	},
	element => sub {
		my ($self, $name) = @_;
		is($name, 'sl', 'have correct element name');
		$self;
	},
	attribute => sub {
		my ($self, $k, $v) = @_;
		is($k, 'href', 'have href');
		is($v, 'http://www.yahoo.edu/', 'is correct URL');
		$self;
	},
	end_attributes => sub {
		my ($self, $attr) = @_;
		pass('have end of attributes');
		$self;
	},
);

# run it a byte at a time
my $data = '';
foreach (split //, $wbdata) {
	$data .= $_;
	$parser->parse(\$data);
}
done_testing();

