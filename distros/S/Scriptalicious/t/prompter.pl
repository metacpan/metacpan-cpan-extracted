#!/usr/bin/perl -w

use Scriptalicious;

my $what = "string";
my $prompt = "enter value:";
my $default = undef;
my $for;

getopt( "int|i" => sub { $what = "int" },
	"string|s" => sub { $what = "string" },
	"yn|y" => sub { $what = "yn" },
	"yes|Y" => sub { $what = "Yn" },
	"no|N" => sub { $what = "yN" },
	"prompt|p=s" => \$prompt,
	"for|f=s" => \$for,
	"default|D=s" => \$default,
      );

my $val;
if ( $for ) {
    mutter "prompting for $for ($what)";
    $val = prompt_for
	( "-$what" => $for, (defined($default) ? ($default) : ()) );

} else {

    mutter "prompt_$what";
    $val = &{"prompt_$what"}
	( $prompt, (defined($default) ? ($default) : ()) );

}

say "response: `$val'";
