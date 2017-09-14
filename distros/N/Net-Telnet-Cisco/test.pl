# $Id: test.pl,v 1.19 2002/04/02 18:59:30 jkeroes Exp $
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Test::More tests => 32;
#use Test::More qw/no_plan/;
use ExtUtils::MakeMaker qw/prompt/;
use Carp;
use Cwd;
my $HAVE_Term_ReadKey = 0;
eval "use Term::ReadKey";
if(!$@) {
    $HAVE_Term_ReadKey = 1
}

use vars qw/$ROUTER $PASSWD $LOGIN $S $EN_PASS $PASSCODE/;

my $input_log = "input.log";
my $dump_log  = "dump.log";

#------------------------------------------------------------
# tests
#------------------------------------------------------------

get_login();

BEGIN { use_ok("Net::Telnet::Cisco") }

ok($Net::Telnet::Cisco::VERSION, 	"\$VERSION set");

SKIP: {
    skip("Won't login to router without a login and password.", 27)
	unless $LOGIN && $PASSWD;

    ok( $S = Net::Telnet::Cisco->new( Errmode	 => \&fail,
				      Host	 => $ROUTER,
				      Input_log  => $input_log,
				      Dump_log   => $dump_log,
				    ),  "new() object" );

    $S->errmode(sub {&confess});

    # So we pass an even number of args to login()
    $LOGIN	   ||= '';
    $PASSWD	   ||= '';
    $PASSCODE      ||= '';

    ok( $S->login(-Name     => $LOGIN,
		  -Password => $PASSWD,
		  -Passcode => $PASSCODE), "login()"		);

    # Autopaging tests
    ok( $S->autopage,			"autopage() on"		);
    my @out = $S->cmd('show ver');
    ok( $out[-1] !~ /--More--/, 	"autopage() last line"	);
    ok( $S->last_prompt !~ /--More--/,	"autopage() last prompt" );

    open LOG, "< $input_log" or die "Can't open log: $!";
    my $log = join "", <LOG>;
    close LOG;

    # Remove last prompt, which isn't present in @out
    $log =~ s/\cJ\cJ.*\Z//m;

    # get rid of "show ver" line
    shift @out;

    # Strip ^Hs from log
    $log = Net::Telnet::Cisco::_normalize($log);

    my $out = join "", @out;
    $out =~ s/\cJ\cJ.*\Z//m;

    my $i = index $log, $out;
    ok( $i + length $out == length $log, "autopage() 1.09 bugfix" );

    # Turn off autopaging. We should timeout with a More prompt
    # on the last line.
    ok( $S->autopage(0) == 0,		"autopage() off"	);

    $S->errmode('return');	# Turn off error handling.
    $S->errmsg('');		# We *want* this to timeout.

    $S->cmd(-String => 'show run', -Timeout => 5);
    ok( $S->errmsg =~ /timed-out/,	"autopage() not called" );

    $S->errmode(\&fail);	# Restore error handling.
    $S->cmd("\cZ");		# Cancel out of the "show run"

    # Print variants
    ok( $S->print('terminal length 0'),	"print() (unset paging)");
    ok( $S->waitfor($S->prompt),	"waitfor() prompt"	);
    ok( $S->cmd('show clock'),		"cmd() short"		);
    ok( $S->cmd('show ver'),		"cmd() medium"		);
    ok( @confg = $S->cmd('show run'),	"cmd() long"		);

    # breaks
SKIP: {
    skip("ios_break test unreliable", 1);
    $old_timeout = $S->timeout;
    $S->timeout(1);
    $S->errmode(sub { $S->ios_break });
    @break_confg = $S->cmd('show run');
    $S->timeout($old_timeout);
    ok( @break_confg < @confg,		"ios_break()"		);
}

    # Error handling
    my $seen;
    ok( $S->errmode(sub {$seen++}), 	"set errmode(CODEREF)"	);
    $S->cmd(  "Small_Change_got_rained_on_with_his_own_thirty_eight"
	    . "_And_nobody_flinched_down_by_the_arcade");

    # $seen should be incrememnted to 1.
    ok( $seen,				"error() called"	);

    # $seen should not be incremented (it should remain 1)
    ok( $S->errmode('return'),		"no errmode()"		);
    $S->cmd(  "Brother_my_cup_is_empty_"
	    . "And_I_havent_got_a_penny_"
	    . "For_to_buy_no_more_whiskey_"
	    . "I_have_to_go_home");
    ok( $seen == 1,			"don't call error()" );

    ok( $S->always_waitfor_prompt(1),	"always_waitfor_prompt()" );
    ok( $S->print("show clock")
	&& $S->waitfor("/not_a_real_prompt/"),
					"waitfor() autochecks for prompt()" );
    ok( $S->always_waitfor_prompt(0) == 0, "don't always_waitfor_prompt()" );
    ok( $S->timeout(5),			"set timeout to 5 seconds" );
    ok( $S->print("show clock")
	&& $S->waitfor("/not_a_real_prompt/")
	&& $S->timed_out,		"waitfor() timeout" 	);

    # restore errmode to test default.
    $S->errmode(sub {&fail});
    ok( $S->cmd("show clock"),		"cmd() after waitfor()" );

    # log checks
    ok( -e $input_log, 			"input_log() created"	);
    ok( -e $dump_log, 			"dump_log() created"	);

    $S = Net::Telnet::Cisco->new( Prompt => "/broken_pre1.08/" 	);
    ok( $S->prompt eq "/broken_pre1.08/", "new(args) 1.08 bugfix" );
}

SKIP: {
    skip("Won't enter enabled mode without an enable password", 3)
	unless $LOGIN && $PASSWD && $EN_PASS;
    ok( $S->disable,			"disable()"		);
    ok( $S->enable($EN_PASS),		"enable()"		);
    ok( $S->is_enabled,			"is_enabled()"		);
}

END { cleanup() };

#------------------------------------------------------------
# subs
#------------------------------------------------------------

sub cleanup {
    return unless -f "input.log" || -f "dump.log";

    print <<EOB;

Would you like to delete the test logs? They will contain
security info like your login and passwords. If you ran
into problems and wish to investigate, you can save them
and manually delete them later.
EOB

    my $dir = cwd();

    my $ans = prompt("Delete logs", "y");
    if ($ans eq "y") {
	print "Deleting logs in $dir...";
	unlink "input.log" or warn "Can't delete input.log! $!";
	unlink "dump.log"  or warn "Can't delete dump.log! $!";
	print "done.\n";
    } else {
	warn "Not deleting logs in $dir.\n";
    }
}

sub get_login {
    print <<EOB;

Net::Telnet::Cisco needs to log into a router to
perform it\'s full suite of tests. To log in, we
need a test router, a login, a password, an
optional enable password, and an optional
SecurID/TACACS PASSCODE.

To skip these tests, hit "return".

EOB

    $ROUTER   = prompt("Router:", $ROUTER) or return;
    $LOGIN    = prompt("Login:", $LOGIN) or return;
    $PASSWD   = passprompt("Password:", $PASSWD) or return;
    $EN_PASS  = passprompt("Enable password [optional]:", $EN_PASS);
    $PASSCODE = passprompt("SecurID/TACACS PASSCODE [optional]:", $PASSCODE);
}


# Lifted from ExtUtils::MakeMaker.
#
# If the user has Term::ReadKey, we can hide any passwords
# they type from shoulder-surfing attacks.
#
# Args: "Question for user", "optional default answer"
sub passprompt ($;$) {
    my($mess,$def)=@_;
    $ISA_TTY = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ;   # Pipe?
    Carp::confess("prompt function called without an argument") unless defined $mess;
    my $dispdef = defined $def ? "[$def] " : " ";
    $def = defined $def ? $def : "";
    my $ans;
    local $|=1;
    print "$mess $dispdef";
    if ($ISA_TTY) {
	if ( $Term::ReadKey::VERSION ) {
	    ReadMode( 'noecho' );
	    chomp($ans = ReadLine(0));
	    ReadMode( 'normal' );
	    print "\n";
	} else {
	    chomp($ans = <STDIN>);
	}
    } else {
        print "$def\n";
    }
    return ($ans ne '') ? $ans : $def;
}
