#!/usr/bin/perl -w
use strict;
use Test::More tests=>4;
use_ok qw(Parse::Eyapp) or exit;
use_ok('Parse::Eyapp::Base', 'slurp_file') or exit;

my $test_pod_installed = 0;

eval {
  require Test::Pod;
  $test_pod_installed = !$@;
  Test::Pod->import() if $test_pod_installed;
};

SKIP: {

skip "Developer test: Test::Pod is installed?", 2 unless $test_pod_installed && $ENV{DEVELOPER};

my $grammar =<< 'EYAPP_GRAMMAR';
%right  '='
%left   '-' '+'
%left   '*' '/'
%left   NEG
%tree bypass alias

%%
line: $exp  { $_[1] } 
;

exp:      
    %name NUM   
          $NUM 
	| %name VAR  
          $VAR 
	| %name ASSIGN        
          $VAR '=' $exp 
	| %name PLUS 
          exp.left '+' exp.right 
	| %name MINUS       
          exp.left '-' exp.right 
	| %name TIMES   
          exp.left '*' exp.right 
	| %name DIV     
          exp.left '/' exp.right 
	| %no bypass UMINUS
          '-' $exp %prec NEG 
  |   '(' exp ')'  { $_[2] } /* Let us simplify a bit the tree */
;

%%

sub _Error {
        exists $_[0]->YYData->{ERRMSG}
    and do {
        print $_[0]->YYData->{ERRMSG};
        delete $_[0]->YYData->{ERRMSG};
        return;
    };
    print "Syntax error.\n";
}

sub _Lexer {
    my($parser)=shift;

        $parser->YYData->{INPUT}
    or  $parser->YYData->{INPUT} = <STDIN>
    or  return('',undef);

    $parser->YYData->{INPUT}=~s/^\s+//;

    for ($parser->YYData->{INPUT}) {
        s/^([0-9]+(?:\.[0-9]+)?)//
                and return('NUM',$1);
        s/^([A-Za-z][A-Za-z0-9_]*)//
                and return('VAR',$1);
        s/^(.)//s
                and return($1,$1);
    }
}

sub Run {
    my($self)=shift;
    $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error, 
		    #yydebug =>0xFF
		  );
}

=head1 NAME
 
Parse::Eyapp::Node - The nodes of the Syntax Trees
 
=head1 SYNOPSIS
 
  use Parse::Eyapp;
  use Parse::Eyapp::Treeregexp;


=head1 METHODS

The C<Parse::Eyapp::Node> objects represent the nodes of the syntax
tree. 
All the node classes build by C<%tree> and C<%metatree> directives
inherit from C<Parse::Eyapp::Node> and consequently have
acces to the methods provided in such module. 

=head1 Parse::Eyapp:YATW  Methods

C<Parse::Eyapp:YATW> objects represent tree transformations.
They carry the information of what nodes match and how to modify
them.


=head1 TREE MATCHING AND TREE SUBSTITUTION

See the documentation in L<Parse::Eyapp::MatchingTrees>


=head1 SEE ALSO

=over

=item * L<Parse::Eyapp::Base>,

=item * ocamlyacc tutorial at 
L<http://plus.kaist.ac.kr/~shoh/ocaml/ocamllex-ocamlyacc/ocamlyacc-tutorial/ocamlyacc-tutorial.html>

=back

=head1 REFERENCES

=over

=item *
The classic Dragon's book I<Compilers: Principles, Techniques, and Tools> 
by Alfred V. Aho, Ravi Sethi and
Jeffrey D. Ullman (Addison-Wesley 1986)

=back



=head1 AUTHOR
 
Casiano Rodriguez-Leon (casiano@ull.es)

=head1 ACKNOWLEDGMENTS

This work has been supported by CEE (FEDER) and the Spanish Ministry of
I<Educacion y Ciencia> through I<Plan Nacional I+D+I> number TIN2005-08818-C04-04
(ULL::OPLINK project L<http://www.oplink.ull.es/>). 
Support from Gobierno de Canarias was through GC02210601
(I<Grupos Consolidados>).
The University of La Laguna has also supported my work in many ways
and for many years.

A large percentage of  code is verbatim taken from L<Parse::Yapp> 1.05.
The author of L<Parse::Yapp> is Francois Desarmenien.
 
I wish to thank Francois Desarmenien for his L<Parse::Yapp> module, 
to my students at La Laguna and to the Perl Community. Special thanks to 
my family and Larry Wall.

=head1 LICENCE AND COPYRIGHT
 
Copyright (c) 2006-2008 Casiano Rodriguez-Leon (casiano@ull.es). All rights reserved.

Parse::Yapp copyright is of Francois Desarmenien, all rights reserved. 1998-2001
 
These modules are free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 

EYAPP_GRAMMAR

unlink('main.pm', 't/main.pm', 'main.output', 't/main.output');

Parse::Eyapp->new_grammar(
  input=>$grammar, 
  classname=>'Alias', 
  firstline =>7,
  outputfile => 'main',
);

#my $file = -d 't' ? 't/main.pm' : 'main.pm';
# Please, investigate the 'ouputfile' parameter of new_grammar!!!!!!!!!!!!!!!
my $file = 'main.pm';
pod_file_ok( $file, "valid POD file from .yp" );

my $generated = slurp_file($file);
like($generated, 
    qr{MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE\.\s+=for None\s+=cut\s+#line.*\s+1;}, 
   'documentation inside eyapp ends ok');
}

unlink('main.pm', 't/main.pm', 'main.output', 't/main.output');
