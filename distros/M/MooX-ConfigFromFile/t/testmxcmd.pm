use MooX::Cmd::Tester;

use FindBin qw($Bin);
use lib "$Bin/lib";

use MooXCmdTest;

my @tests = (
    [ [], "MooXCmdTest", "MooXCmdTest", { complicated_setting => { say => "Hello!" } } ],
    [ [qw(test)], "MooXCmdTest", "MooXCmdTest::Cmd::Test", { unintialized_attribute => sub { time - $_[0] < 1 } } ],
    [ [qw(tested)], "MooXCmdTest", "MooXCmdTest::Cmd::Tested", { confidential_setting => 42 } ],
    [ [qw(test this)], "MooXCmdTest", "MooXCmdTest::Cmd::Test::Cmd::This", { dedicated_setting => 4711 } ],
    [ [qw(test this hashmerged)], "MooXCmdTest", "MooXCmdTest::Cmd::Test::Cmd::This::Cmd::HashMerged",
       { dedicated_setting => 4711, merged_frame => { kept_value => "sane", "overwritten_value" => "dammed" } } ],
);

for (@tests)
{
  SKIP:
    {
	my ( $args, $class, $cmd_class, $attrs ) = @{$_};
	ref $args or $args = [ split( ' ', $args ) ];
	my $rv = test_cmd( $class => $args );
	#diag(explain($rv));

	my $test_ident = "$class => " . join( " ", "[", @$args, "]" );
	ok( $rv->cmd, "got cmd for $test_ident" ) or diag( explain($rv) );
	isa_ok( $rv->cmd, $class ) or skip( "Cannot do attribute testing without command", 2 );
	isa_ok( $rv->cmd->command_chain_end, $cmd_class )
	  or skip( "Cannot do attribute testing without specific command", 1 )
	  if scalar @$args;
	my $cmd = scalar @$args ? $rv->cmd->command_chain_end : $rv->cmd;
	foreach my $k ( keys %$attrs )
	{
	    my $cmd_attr = $cmd->$k;
	    ref $attrs->{$k} or is( $attrs->{$k}, $cmd_attr, "Attribute $k for $test_ident" );
	    "CODE" eq ref $attrs->{$k} and ok( $attrs->{$k}->($cmd_attr), "Attribute $k ok for $test_ident" );
	    ref $attrs->{$k}
	      and "CODE" ne ref $attrs->{$k}
	      and is_deeply( $attrs->{$k}, $cmd_attr, "Attribute $k for $test_ident" );
	}
    }
}
