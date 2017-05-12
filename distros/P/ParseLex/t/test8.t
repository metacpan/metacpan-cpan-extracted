#!/usr/bin/perl

# From RT #1861

use strict;
use Symbol;
use Test::More tests => 4;

my $file = "showbugtest.dat";
my @input_lines = <DATA>;

open F, ">$file" || die "Can't open test data file '$file' $!";
print F @input_lines;
close F;

my $fh = gensym;

is my_parser::parse(@input_lines), 3, "GOT: 3 lines"; 
is my_parser::parse($file), 3, "GOT: 3 lines";
is my_parser::parse($fh), undef, "No output because of bad file handle";
is my_parser::parse($file), 3, "GOT: 3 lines"; 

unlink $file;

package my_parser;

use strict;
use Parse::Lex;
use Symbol;

my $lexer;
BEGIN { 
	$lexer = Parse::Lex->new( EOR => '\n', LINE => '.*' );

	# Avoid Name "my_parser::EOR" used only once
	my @dummy = ($my_parser::EOR, $my_parser::LINE);
};

sub parse {
  my $file = shift;
  my $fh;
  my $should_close = 0;
  if ( @_ ) { 					# more than one argument -> list of strings
	$lexer->from($file, @_);	# had shifted first string to $file
  }
  elsif ( ref $file eq "GLOB" ) {
    $fh = $file;
    fileno( $fh ) or return undef;
	$lexer->from($fh);
  }
  else {
    $fh = gensym;
    open $fh, $file or die "Can't open file '$file' for import. Error: $!";
    $should_close = 1;
	$lexer->from($fh);
  }

  my $token;
  my $line_cnt = 0;
  
  while ( $lexer->nextis(\$token) ) {
    ++ $line_cnt if $token->name eq "EOR";
  }
  close $fh if $should_close; # take this out and it MAY work
#  print "GOT: $line_cnt lines\n";
  return $line_cnt;
}


__END__
1,one
2,two
3,three
