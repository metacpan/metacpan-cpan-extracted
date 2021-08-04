
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use 5.012;
use Test::More;
use FindBin qw($RealBin);
use_ok('Proch::N50');
my $last_ver = $Proch::N50::VERSION;
my $changes_file = "$RealBin/../Changes";
open my $out, '>', "$RealBin/Changes.clean";
my $text = "";

if (-e "$changes_file") {
	my $version_found = 0;
	open my $F, '<:encoding(UTF-8)', $changes_file || die $!;
	my $c = 0;
	while (my $line = readline($F) ) {
		$text .= $line;
		chomp($line);
         
		$c++;

		$version_found++ if ($line=~/${last_ver}\t/);

		my $clean_line = $line;
		$clean_line =~s/[^'"~;\@A-Za-z0-9\*,\.\!\?\-_ \t()\[\]{}\\\/:]+//g;
		say {$out} $clean_line;
		print STDERR "Stripping unexpected characters in Changes:\nORIGINAL: [$line]\nCLEAN: [$clean_line]\n" if (length($line)!=length($clean_line));
		ok(length($line) == length($clean_line),
			"Line #$c has not weird chars: " . length($line) . ' == ' . length($clean_line)
		);
	}
	ok($version_found == 1, "Last version ${last_ver} was found only once: $version_found in $changes_file:\n$text");
	done_testing();

} else {
	print STDERR "<$changes_file> not found\n";
}
