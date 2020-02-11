use Test::Most;

use File::Basename;
use lib dirname($0);
use Test::Pb::Bin;

use File::Temp;


# This is pretty much how Path::Tiny::tempfile does it.
my $logfile = File::Temp->new( TMPDIR => 1 ); close $logfile;

my $test_cmd = <<'END';
	use Pb;

	command itest =>
	flow
	{
		verify { SH echo => "xx: verify line"; 1 } "can't fail";
		SH echo => "sh: first line";
		SH echo => "sh: second line";
		CODE "interactive test" => sub { say "cd: third line" };
		say "xx: end";
	};

	command nested => flow
	{
		RUN 'itest';
		RUN 'itest';
	};

	Pb->go;
END
$test_cmd =~ s/%%/$logfile/g;
pb_basecmd(test_pb => $test_cmd);
my @lines = ( "xx: verify line", "sh: first line", "sh: second line", "cd: third line", "xx: end", );

# first, run in standard mode
check_output pb_run('itest'), @lines, "sanity check: normal output";

# now run in interactive mode, all "yes"es
my $answers = 'y' x 3;
my @interactive_lines = calculate_interactive_output( N => $answers => @lines);
check_output pb_run_interactive('itest', $answers), @interactive_lines, "basic interactive mode: good output";

# throw in a few "no"s
$answers = 'yny';
@interactive_lines = calculate_interactive_output( N => $answers => @lines);
check_output pb_run_interactive('itest', $answers), @interactive_lines, "interactive mode: yes and no";

# mix it up a bit
$answers = 'ynn';
@interactive_lines = calculate_interactive_output( N => $answers => @lines);
check_output pb_run_interactive('itest', $answers), @interactive_lines, "interactive mode: yes and no";

# how about all "no"s?
$answers = 'n' x 3;
@interactive_lines = calculate_interactive_output( N => $answers => @lines);
check_output pb_run_interactive('itest', $answers), @interactive_lines, "interactive mode: yes and no";

# nested flows should inherit the context, including the runmode
$answers = 'y' x 6;
@interactive_lines = calculate_interactive_output( N => $answers => @lines, @lines);
check_output pb_run_interactive('nested', $answers), @interactive_lines, "interactive mode for nested: good output";


done_testing;


sub calculate_interactive_output
{
	my ($default, $answers, @lines) = @_;
	my @answers = split(//, $answers);
	my $choices = $default eq 'Y' ? 'Y/n' : $default eq 'N' ? 'y/N' : die("unknown default");

	my @output;
	my $line = '';
	my $line_is_done = sub { $line .= $_; push @output, $line; $line = ''; };
	foreach (@lines)
	{
		my ($marker) = /^(..):/ or die("line has no marker [$_]");
		if ($marker eq 'xx')
		{
			&$line_is_done;
		}
		elsif ($marker eq 'sh')
		{
			my $answer = shift @answers // die("not enough answers!");
			$line .= "run shell command? echo $_  [$choices] ";
			&$line_is_done if $answer eq 'y';
		}
		elsif ($marker eq 'cd')
		{
			my $answer = shift @answers // die("not enough answers!");
			$line .= "run code block? [interactive test]  [$choices] ";
			&$line_is_done if $answer eq 'y';
		}
		else
		{
			die("unknown line marker [$marker]");
		}
	}
	return @output;
}
