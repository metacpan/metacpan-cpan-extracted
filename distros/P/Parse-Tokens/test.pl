# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN
{
	$| = 1;
	print "1..13\n";
}

END
{
	print "not ok 1\n" unless $loaded;
}

use Parse::Tokens;

$got_pre = 0;
$got_post = 0;
$got_token = 0;
$got_ether = 0;

@labels = (
	"Loading module",
	"Initializing module",
	"Setting delimiters",
	"Setting event callback for 'pre_parse'",
	"Setting event callback for 'token'",
	"Setting event callback for 'ether'",
	"Setting event callback for 'post_parse'",
	"Setting text",
	"Parsing text",
	"Received pre event",
	"Received token event",
	"Received ether event",
	"Received post event",
);

$loaded = 1;
$testno = 1;
&report( $loaded );

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $parser = new Parse::Tokens ({});
&report( $parser );
&report( $parser->delimiters( [['<?','?>']] ) );
&report( $parser->pre_callback( \&pre ) );
&report( $parser->token_callback( \&token ) );
&report( $parser->ether_callback( \&ether ) );
&report( $parser->post_callback( \&post ) );
&report( $parser->text(q{ Mi llamo <? __PACKAGE__ ?>.  }) );
&report( $parser->parse() );
&report( $got_pre );
&report( $got_token );
&report( $got_ether );
&report( $got_post );

sub token
{
	my( $token ) = @_;
	$got_token++ if ref($token) eq 'ARRAY';
}

sub ether
{
	my( $text ) = @_;
	$got_ether++ if $text;
}

sub pre { $got_pre++; }
sub post { $got_post++; }

sub report
{
	my( $result ) = @_;
	my $status = $result ? 'ok' : 'not ok';
	#print "(", $testno, ") ", $labels[($testno-1)], "...$status\n";
	#printf( "%02d. %-40s%5s\n", $testno, $labels[($testno-1)], $status );
	printf( "%02d. %s...%s\n", $testno, $labels[($testno-1)], $status );
	$testno++;
	return 1;
}

