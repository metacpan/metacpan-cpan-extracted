#!/usr/bin/perl 
use warnings;
use Noactions;

sub Calc::NUM::action {
  return $_[1];
}

sub Calc::PLUS::action {
  $_[1]+$_[3];
}

sub Calc::TIMES::action {
  $_[1]*$_[3];
}

sub Post::NUM::action {
  return $_[1];
}

sub Post::PLUS::action {
  "$_[1] $_[3] +";
}

sub Post::TIMES::action {
  "$_[1] $_[3] *";
}

my $debug = shift || 0;
my $pparser = Noactions->new( yyprefix => 'Post::');

print "Write an expression: "; 
my $x = <STDIN>;

my $t = $pparser->Run($debug, $x);

unless ($pparser->YYNberr) {
  print "$t\n";

  my $cparser = Noactions->new(yyprefix => 'Calc::');
  my $e = $cparser->Run($debug, $x);

  print "$e\n";
}
