
use Scriptalicious;

my $ifd = fileno(STDIN);
my $ofd = fileno(STDOUT);

getopt("ifd|i=i" => sub {
	   close STDIN;
	   open STDIN, "<&$_[1]" or do {
	       moan "failed to open input fd $_[1]; $!";
	       sleep 60;
	   };
       },
       "ofd|o=i" => sub {
	   close STDOUT;
	   open STDOUT, ">&$_[1]" or do {
	       moan "failed to open output fd $_[1]; $!";
	       sleep 60;
	   };
       },
      );

my $lines = 0;
while ( <STDIN> ) {
    $lines++;
    chomp;
    say "got `$_'";
}

say "saw $lines line(s) on input";

close STDIN;
