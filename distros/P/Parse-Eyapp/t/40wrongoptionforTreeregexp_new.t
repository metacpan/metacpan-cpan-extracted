#!/usr/bin/perl -w
use strict;
#use Test::More qw(no_plan);
use Test::More tests => 3;

#use Test::Exception;
our $test_exception_installed;
BEGIN { 
$test_exception_installed = 1;
eval { require Test::Exception };
$test_exception_installed = 0 if $@;
}

use_ok qw(Parse::Eyapp) or exit;
#use Data::Dumper;
use_ok qw(Parse::Eyapp::Treeregexp);

my $grammar = q{

%semantic token 'a' 'b' 'c'
%tree

%%

S: %name ABC
     A B C
 | %name BC
     B C
;

A: %name A
     'a' 
;

B: %name B
     'b'
;

C: %name C
    'c'
;
%%

sub _Error {
  die "Syntax error.\n";
}

my $in;

sub _Lexer {
    my($parser)=shift;

    {
      $in  or  return('',undef);

      $in =~ s/^\s+//;

      $in =~ s/^([AaBbCc])// and return($1,$1);
      $in =~ s/^(.)//s and print "<$1>\n";
      redo;
    }
}

sub Run {
    my($self)=shift;
    $in = shift;
    #$in = <>;
    $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error, );
}
}; # end grammar

#$Data::Dumper::Indent = 1;
Parse::Eyapp->new_grammar(input=>$grammar, classname=>'AB', firstline => 9); #, outputfile => 'AB.pm');
my $parser = AB->new();
my $t = $parser->Run("abc");
#print "\n***** Before ******\n";
#print Dumper($t);


SKIP: {
  skip "Test::Exception not installed", 1 unless $test_exception_installed;
  my $expected_result 
    = qr{Parse::Eyapp::Treeregexp::new Error!: unknown argument OUTFILE. Valid arguments are:};
  Test::Exception::throws_ok {
      my $p = Parse::Eyapp::Treeregexp->new( STRING => q{
         delete_b_in_abc : /ABC|BC/(@a, B, @c)
           => { @{$_[0]->{children}} = (@a, @c) }
        },
        SEVERITY => 0,
        OUTFILE => 'main.pm', # This is a deliberated error
      );
    } 
    $expected_result, 
    "invalid argument in Parse::Eyapp::Treeregexp->new";
} # end SKIP
