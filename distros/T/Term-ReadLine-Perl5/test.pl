#! /usr/bin/perl -w
# Give an argument to use stdin, stdout instead of console
# If argument starts with /dev, use it as console
# If argument is '--no-print', do not print the result.

use warnings; use strict;
use Test::More;
use lib './lib';

{ package Term::ReadLine::Stub; }

BEGIN{
    # Do not test TR::Gnu !
    $ENV{PERL_RL} = 'Perl5';
    $ENV{'INPUTRC'} = '/dev/null';
    $ENV{'COLUMNS'} = '80';
    $ENV{'LINES'}   = '25';
};

# FIXME:
# Until Term::ReadLine has Perl5 defined use
#       Term::ReadLine::Perl5 ?

use Term::ReadLine::Perl5;


use Carp;
$SIG{__WARN__} = sub { warn Carp::longmess(@_) };

my $non_interactive =
    (defined($ENV{PERL_MM_NONINTERACTIVE}))
    ? $ENV{PERL_MM_NONINTERACTIVE} :
     ($ENV{PERL_MM_USE_DEFAULT} || $ENV{AUTOMATED_TESTING});
if ($non_interactive) {
    no strict; no warnings;
    plan skip_all => "Not interactive: " .
	"\$ENV{PERL_MM_NONINTERACTIVE}='$ENV{PERL_MM_NONINTERACTIVE}' \$ENV{AUTOMATED_TESTING}='$ENV{AUTOMATED_TESTING}'\n";
} else {
    plan;
}

my ($term, $no_print);
if (!@ARGV) {
  $term = Term::ReadLine::Perl5->new('Simple Perl calc');
} elsif (@ARGV == 2) {
  open(IN,"<$ARGV[0]");
  open(OUT,">$ARGV[1]");
  $term = Term::ReadLine::Perl5->new('Simple Perl calc', \*IN, \*OUT);
} elsif ($ARGV[0] =~ m|^/dev|) {
  open(IN,"<$ARGV[0]");
  open(OUT,">$ARGV[0]");
  $term = Term::ReadLine::Perl5->new('Simple Perl calc', \*IN, \*OUT);
} else {
  $term = Term::ReadLine::Perl5->new('Simple Perl calc', \*STDIN, \*STDOUT);
  $no_print = $ARGV[0] eq '--no-print';
}

# use Enbugger 'trepan'; Enbugger->stop;
my $prompt = "Enter arithmetic or Perl expression: ";
if ((my $l = $ENV{PERL_RL_TEST_PROMPT_MINLEN} || 0) > length $prompt) {
  $prompt =~ s/(?=:)/ ' ' x ($l - length $prompt)/e;
}
no strict;
my $OUT = $term->{OUT} || \*STDOUT;
use strict;
my %features = %{ $term->Features };
if (%features) {
  my @f = %features;
  print $OUT "Features present: @f\n";
  $term->ornaments(1) if $features{ornaments};
} else {
  print $OUT "No additional features present.\n";
}
print $OUT "\n  Flipping rl_default_selected each line.\n";
print $OUT <<EOP;

	Hint: Entering the word
		exit
	would exit the test. ;-)  (If feature 'preput' is present,
	this word should be already entered.)

EOP

while ( defined (my $line = $term->readline($prompt, 'exit')) )
{
    last if $line eq 'exit';
    my $res = eval($line);
    warn $@ if $@;
    if (!defined $res) {
	print $OUT "undef\n";
	next;
    }
    print $OUT $res, "\n" unless $@ or $no_print;
    $term->add_history($line) if $line =~ /\S/;
    $readline::rl_default_selected = !$readline::rl_default_selected;
}
if (@ARGV) {
    my $term2 = Term::ReadLine::Perl5->new('caroline test');
    while ( defined (my $line = $term2->readline($prompt, 'exit2')) )
    {
	last if $line eq 'exit2';
	my $res = eval($line) || '';
	print $OUT "$res\n" unless $@ or $no_print;
	$term2->add_history($line) if $line =~ /\S/;
	$readline::rl_default_selected = !$readline::rl_default_selected;
    };
};
ok(1);
done_testing();
