
use warnings;
use strict;

use Test::More tests => 4;
use POE qw(Component::RSS);

sub DEBUG () { 0 }

my $item_count = 0;
my $tag_count = 0;
my $start_count =0;
my $stop_count = 0;

sub parser_start {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	DEBUG && print "Parser starting...\n";

	POE::Component::RSS->spawn();
  
	my $rss_string;
	{ local $/; $rss_string = <DATA>; }
  
	$kernel->post(
		'rss', 
		'parse' => {
			Item => 'item',
			Image => 'image',
			Channel => 'channel',
			Textinput => 'textinput',
			Start  => 'start',
			Stop => 'stop',
		},
		$rss_string
	);
  
	$kernel->post(
		'rss',
		'parse' => {
			Item => 'item',
			Image => 'image',
			Channel => 'channel',
			Textinput => 'textinput',
			Start  => 'start',
			Stop => 'stop',
		},
		$rss_string, 'my_rss_tag',
	);
	return;
}

sub parser_stop {
	DEBUG && print "Parser stopping...\n";
}

sub got_item {
	my ($kernel, $heap, $tag, $item) = @_[KERNEL, HEAP, ARG0, ARG1];
  
	unless (defined($item)) {
		$item = $tag;
	}
  
	DEBUG && print "Got item:\n";
  
	DEBUG && print "  Title: " . $item->{'title'} . "\n";
	DEBUG && print "  Link: " . $item->{'link'} . "\n";
	DEBUG && print "\n";

	$item_count++;
	if (defined($tag) and $tag eq 'my_rss_tag') {
		$tag_count++;
	}

	return;
}

sub got_channel {
	my ($kernel, $heap, $tag, $channel) = @_[KERNEL, HEAP, ARG0, ARG1];
	unless (defined($channel)) {
		$channel = $tag;
	}
	if (DEBUG) {
		print "Got channel\n";
		foreach (keys %{$channel}) {
			print "  Key: $_ Value: " . $channel->{$_} . "\n";
		}
		print "\n";
	}
	return;
}

sub got_image {
	my ($kernel, $heap, $tag, $image) = @_[KERNEL, HEAP, ARG0, ARG1];
	unless (defined($image)) {
		$image = $tag;
	}

	if (DEBUG) {
		print "Got image\n";
		foreach (keys %{$image}) {
			print "  Key: $_ Value: " . $image->{$_} . "\n";
		}
		print "\n";
	}
	return;
}

sub got_textinput {
	my ($kernel, $heap, $tag, $textinput) = @_[KERNEL, HEAP, ARG0, ARG1];
	unless (defined($textinput)) {
		$textinput = $tag;
	}
	if (DEBUG) {
		print "Got textinput\n";
		foreach (keys %{$textinput}) {
			print "  Key: $_ Value: " . $textinput->{$_} . "\n";
		}
		print "\n";
	}
	return;
}

sub got_start {
	DEBUG && print "Started parsing\n";
	$start_count++;
}

sub got_stop {
	DEBUG && print "Stopped parsing\n";
	$stop_count++;
}

POE::Session->create(
	inline_states => {
		_start => \&parser_start,
		_stop => \&parser_stop,
		item => \&got_item,
		channel => \&got_channel,
		image => \&got_image,
		textinput => \&got_textinput,
		start => \&got_start,
		stop => \&got_stop,
	},
);

$poe_kernel->run();

DEBUG && print "Got $item_count items(s)\n";

is($item_count, 20, "item count");
is($tag_count, 10, "tag count correct");
is($start_count, 2, "start count correct");
is($stop_count, 2, "stop count correct");

exit;

__DATA__
<?xml version="1.0"?><rdf:RDF
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns="http://my.netscape.com/rdf/simple/0.9/">

  <channel>
    <title>Slashdot:News for Nerds. Stuff that Matters.</title>
    <link>http://slashdot.org/</link>
    <description>News for Nerds.  Stuff that Matters</description>
  </channel>

  <image>
    <title>Slashdot</title>
    <url>http://slashdot.org/images/slashdotlg.gif</url>
    <link>http://slashdot.org</link>
  </image>
  
  <item>
    <title>Red Hat Tightening Trademarks?</title>
    <link>http://slashdot.org/articles/99/09/01/0943219.shtml</link>
  </item>
  
  <item>
    <title>Scientists map schematic of brain's fibers</title>
    <link>http://slashdot.org/articles/99/09/01/1429226.shtml</link>
  </item>
  
  <item>
    <title>More Mission-Critical Linux</title>
    <link>http://slashdot.org/articles/99/09/01/1827215.shtml</link>
  </item>
  
  <item>
    <title>Amiga's president unexpectedly resigns</title>
    <link>http://slashdot.org/articles/99/09/01/1856251.shtml</link>
  </item>
  
  <item>
    <title>XFree86 3.3.5 released</title>
    <link>http://slashdot.org/articles/99/09/01/0716233.shtml</link>
  </item>
  
  <item>
    <title>GT Interactive Sued for piracy</title>
    <link>http://slashdot.org/articles/99/09/01/1347204.shtml</link>
  </item>
  
  <item>
    <title>ProjectUDI spec goes 1.0</title>
    <link>http://slashdot.org/articles/99/09/01/1430242.shtml</link>
  </item>
  
  <item>
    <title>Chad Davis May Be the Next Kevin Mitnick</title>
    <link>http://slashdot.org/articles/99/09/01/1547226.shtml</link>
  </item>
  
  <item>
    <title>Clearing up FreeBSD confusion</title>
    <link>http://slashdot.org/articles/99/09/01/141247.shtml</link>
  </item>
  
  <item>
    <title>Linuxcare and Sun partner on StarOffice for Linux</title>
    <link>http://slashdot.org/articles/99/09/01/1333220.shtml</link>
  </item>
</rdf:RDF>

