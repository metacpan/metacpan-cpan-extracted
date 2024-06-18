# -*- cperl -*-
# ABSTRACT: LaTeX file parser


use strict;
use warnings;
package SpeL::Parser::Chunk;

use parent 'Exporter';
use Carp;

use IO::File;
use File::Basename;

use SpeL::Object::Document;
use SpeL::Object::ElementList;
#use Data::Dumper;

our $prepmacrolist = [];
our $prepenvlist = [];

our $gobblematcher = qr/verbatim|listing/i;

our $elements = do {
  use Regexp::Grammars;
  qr{
#      <logfile: ->

      <grammar: elements>

      <nocontext:>

#      <debug: on>


      #                           & not \&   \,\quad\qquad  whitespace   comment
      #      <token: ws>             (?: (?<!\\)\& | \\, | \\quad | \\qquad | ~ | \\\s | [\s\n] | (\%[^\n]*\n) )*
      <token: ws>          (?: \\, | \\quad | \\qquad | ~ | \\\s | [\s\n] | (\%[^\n]*\n) )*

      <objrule: SpeL::Object::ElementList = ElementList>
                <[Element]>*

      

      <objrule: SpeL::Object::Element = Element>
                <!egroup> <!stray_etag>
                ( <MATCH=VerbatimEnv> |
                  <MATCH=Env>  |
                  <MATCH=Group>  |
                  <MATCH=MathInl> |
                  <MATCH=MathEnvSimple> |
                  <MATCH=MathEnv> |
                  <percent> |
                  <MATCH=Item> |
                  <MATCH=Command> |
                  <Parameter> |
                  <sup> |
                  <sub> |
                  <sep> |
                  <smallspace> |
                  <eol> |
		  \| <Docstrip=(?:[^|]+)> \| |
		  <MATCH=TokenSequence> )
	       

      <objrule: SpeL::Object::Element = BareElement>
                <!egroup> <!stray_etag>
                ( <MATCH=VerbatimEnv> |
                  <MATCH=Env>  |
                  <MATCH=Group>  |
                  <percent> |
                  <MATCH=Item> |
                  <MATCH=Command> |
                  <sep> |
                  <eol> |
                  <MATCH=BareTokenSequence> )

      <objrule: SpeL::Object::MathUnit = MathUnit>
                <!stray_etag> 
                <MATCH=Relation> |
                <MATCH=Expression> # never triggerd, 
		                   # had to hide this in Relation


      <objrule: SpeL::Object::Relation>
                <[RelationChain]>* |
                <Left=Expression> <[RelationChain]>*

      <rule: RelationChain>
                <RelOperator> <Right=Expression>?


      <objtoken: SpeL::Object::RelOperator = RelOperator>
                = |
                \\ne\b |
                \> |
		\< |
                \\gt\b |
                \\lt\b |
                \\ge\b |
                \\le\b |
	        \\in\b |
		\\[Ll]eftarrow |
		\\[Rr]ightarrow |
		\\[Ll]eftrightarrow |
		\\[Ll]ongleftarrow |
		\\[Rr]ongrightarrow |
		\\[Ll]ongleftrightarrow |
		\\[Uu]parrow |
		\\[Dd]ownarrow |
		\\[Uu]pdownarrow |
		\\(?:long)?mapsto |
		\\(?:leads)?to |
		(?<!\\)\&

      <objrule: SpeL::Object::Expression = Expression>
                <!egroup> <!stray_etag>
                <!RelOperator>
                ( ( <Begintext=Textinmathcommand> <Rest=Expression>? ) |
		  ( <Component=Number> <Rest=Expressionrest> ) |
		  ( <Sign> <Component=Number> <Rest=Expressionrest> ) |
		  ( <Sign>? <obracket> <Component=MathUnit> <cbracket> <Rest=Expressionrest> ) |
		  ( <Sign>? <Component=Function> <Rest=Expressionrest> ) |
		  ( <Sign>? <Component=Fraction> <Rest=Expressionrest> ) |
		  ( <Sign>? <Component=Variable> <Rest=Expressionrest> ) |
		  ( <Sign>? <Component=Limitsexpression> <Rest=Expression> ) |
		  ( <Sign>? <Component=Unop> <Rest=Expressionrest> ) |
		  <Interval> |
		  ( (?:\\left)? \| <Absval=Expression> (?:\\right)? \| ) |
		  ( <Ellipsis=(\\[lvcd]dots)> <Rest=Expressionrest> ) |
		  ( <Component=MathEnvInner> <Rest=Expressionrest> ) |
		  ( <Component=Matrix> <Rest=Expressionrest> ) |
		  ( <Sign>? <Component=Mathcommand> <Rest=Expressionrest> ) )

      <token: obracket>
                ( (?:\\left)? <.ws> (?:\(|\[|\\\{) ) |
                ( \\left <.ws> \. )

      <token: cbracket>
                ( (?:\\right)? <.ws> (?:\)|\]|\\\}) ) |
                ( \\right <.ws> \. )

      <objrule: SpeL::Object::Fraction = Fraction>
                \\frac \{ (?: <num=Number> | <num=Expression> ) \}
                       \{ (?: <den=Number> | <den=Expression> ) \}

      <objrule: SpeL::Object::Expressionrest = Expressionrest>
                ( <Endtext=Textinmathcommand> ) |
                ( <Op=Subscript> <Remainder=Expressionrest> ) |
                ( <Op=Power> <Remainder=Expressionrest> ) |
		( <Op=Unop> <Remainder=Expressionrest> ) |
                ( <Op=Binop> <Remainder=Expression> ) |
		( <Op=Arrow> <Remainder=Expression> ) |
                <ws>

      <objtoken: SpeL::Object::Power = Power>
                ( <sup> <Lit=(\w)> ) |
		( <sup> <Group=MathGroup> )

      <objtoken: SpeL::Object::Subscript = Subscript>
                ( <sub> <Lit=(\w)> ) |
		( <sub> <Group=MathGroup> )

      <objrule: SpeL::Object::Unop = Unop>
                ( <Op=(?:\\overline)> \{ <Arg=Expression> \} ) |
                ( <Op=(?:\\overline)> <Arg=Variable> )

      <objrule: SpeL::Object::Binop = Binop>
                <Op=(?:[+-/])> |
                <Op=(?:\\pm)> |
                <Op=(?:\\times)> |
                <Op=(?:\\cdot)> |
                <Op=(?:\\mid)> |
		<Op=Komma> |
		<Op=Semicolon> |
		<Com=Textinmathcommand> |
                <Op=ws>

      <objrule: SpeL::Object::Arrow = Arrow>
                <Op=(?:\\Rightarrow)> |
                <Op=(?:\\Leftarrow)> |
                <Op=(?:\\Leftrightarrow)> 

      <objtoken: SpeL::Object::Squareroot = Sqrt>
                ( \\sqrt <.ws> \[ <N=Expression> \] <.ws> \{ <Argument=Expression> \} ) |
                ( \\sqrt <.ws> \{ <Argument=Expression> \} )

      <objtoken: SpeL::Object::Command = Command>
                <!RelOperator> 
                \\ ( (?!\\)(?!end)(?!begin)(?!par)(?!item)(?!left)(?!right) <Name=ComName> ) <Options>? <[Args]>* <trailingws=ws>

      <objtoken: SpeL::Object::Command = Mathcommand> 
	        ( <!RelOperator>	
  		  \\ <Name=(?:mbox)> <[Args]>* <trailingws=ws> ) |
		( <!RelOperator>
                \\ ( (?!\\)(?!end)(?!begin)(?!par)(?!item)(?!left)(?!right) <Name=ComName> ) <Options>? <[Args=Mathargs]>* <trailingws=ws> )
 
      <objtoken: SpeL::Object::Command = Textinmathcommand>
	        <!RelOperator>	
		\\ <Name=(?:text)> <[Args]>* <trailingws=ws>


      <objtoken: SpeL::Object::VerbatimEnvironment = VerbatimEnv>
                \\ begin <.ws> \{ <verbatimtag> \}
 		  <verbatimcontent>
                \\ end \{ <.everbatimtag( :verbatimtag )> \} <trailingws=ws>

      <objtoken: SpeL::Object::Environment = Env>
                <!math_envtag> \\ begin <.ws> \{ <tag> \} <Options>? <[Args]>* <trailingws=ws>
                  <ElementList> <.ws>
                \\ end \{ <.etag( :tag )> \}
                |
                <!math_envtag> \\ begin <.ws> \{ <tag> \} <Options>? <[Args]>* <trailingws=ws>
                  <ElementList> <.ws>
                <matchline> <matchpos> <fatal: (?{"Missing \\end{$MATCH{tag}} at @{[ SpeL::Parser::Chunk::_report( \%MATCH ) ]}"})>

      <objtoken: SpeL::Object::MathEnvironmentSimple = MathEnvSimple>
                \\\[
                <MathUnit>
                \\\]

      <objtoken: SpeL::Object::MathEnvironment = MathEnv>
#		<debug: step>
                \\ begin \{ <mathtag> \} <Options>? <[Args]>* <trailingws=ws>
		<[MathUnit]>+ % <.eol> <.ws>
                \\ end \{ <.mathetag( :mathtag )> \}
                |
                \\ begin \{ <mathtag> \} <Options>? <[Args]>* <trailingws=ws>
                  <[MathUnit]>+ % <.eol> <.ws>
		  <matchline> <matchpos> <fatal: (?{"Missing \\end{$MATCH{mathtag}} at @{[ SpeL::Parser::Chunk::_report( \%MATCH ) ]}"})>
#		<debug: off>
		
      <objtoken: SpeL::Object::MathEnvironmentInner = MathEnvInner>
                \\ begin \{ <mathtaginner> \} <Options>? <[Args]>* <trailingws=ws>
                  <[MathUnit]>+ % <.eol> <.ws>
                \\ end \{ <.mathetaginner( :mathtaginner )> \}
                |
                \\ begin \{ <mathtaginner> \} <Options>? <[Args]>* <trailingws=ws>
                  <[MathUnit]>+ % <.eol> <.ws>
                <matchline> <matchpos> <fatal: (?{"Missing \\end{$MATCH{mathtaginner}} at @{[ SpeL::Parser::Chunk::_report( \%MATCH ) ]}"})>

     <objtoken: SpeL::Object::Matrix = Matrix>
                \\ begin \{ <matrixtag> \} <Options>? <[Args]>* <trailingws=ws>
                  <[MathUnit]>+ % <.eol> <.ws>
                \\ end \{ <.matrixetag( :matrixtag )> \}
                |
                \\ begin \{ <matrixtag> \} <Options>? <[Args]>* <trailingws=ws>
                  <[MathUnit]>+ % <.eol> <.ws>
                <matchline> <matchpos> <fatal: (?{"Missing \\end{$MATCH{matrixtag}} at @{[ SpeL::Parser::Chunk::_report( \%MATCH ) ]}"})>

		
      <objtoken: SpeL::Object::Group = Group>
                \{ <ElementList> \} <trailingws=ws>

      <objtoken: SpeL::Object::MathGroup = MathGroup>
                \{ <MathUnit> \} <trailingws=ws>

      <objrule: SpeL::Object::MathInline = MathInl>
                [\$] <MathUnit> [\$] \s* |
                \\[\(] <MathUnit> \\[\)] \s*
      
      <objrule: SpeL::Object::Item = Item>
                \\ item <Options>? <[Args]>* ( <!Item> <[Element]> )*

      <rule: Komma>           , 

      <rule: Semicolon>       ;

      <objrule: SpeL::Object::Interval>    <Intervalstart=(?:\[|\]|\()> <left=Expression> , <right=Expression> <Intervalend=(?:\[|\]|\))>

      
      <token: BeginEnvLit>    \\ begin \{ <\:env> \}

      <token: EndEnvLit>      \\ end \{ <\:env> \}

      <token: bgroup>         \{

      <token: egroup>         \}

      <token: percent>        \\ \%

      <token: equals>         = <ws>

      <token: stray_etag>     \\ end \{

      <rule: math_envtag>     \\ begin \{ <mathtag> \}

      <token: tag>            [^][\$&%#_{}~^\s]++

      <token: verbatimtag>    <MATCH=tag> <require: (?{ $^N =~ $gobblematcher }) >

      <rule: mathtaginner>    ( array\*? | aligned*? )

      <rule: mathetaginner>   (??{quotemeta $ARG{mathtaginner}})

      <rule: matrixtag>       (?:[bBpvV]|small)matrix\*?

      <rule: matrixetag>      (??{quotemeta $ARG{matrixtag}})

      <rule: mathtag>         ( equation\*? | eqnarray\*? | align\*? | alignat\*? | gather\*? )

      <rule: mathetag>        (??{quotemeta $ARG{mathtag}})

      <token: mathdelim>      \\\{ | \\\} | \\\[ | \\\]

      <token: sup>            \^ 

      <token: sub>            \_

      <token: sep>            \& <ws>

      <token: smallspace>     \\,

      <token: eol>            \\\\(?:\[[^]]+\])? <ws>

      <token: etag>           (??{quotemeta $ARG{tag}})

      <token: everbatimtag>   (??{quotemeta $ARG{verbatimtag}})

      <token: Options>         <.ws> \[ <[MATCH=Option]>+ % (,) \]
                
      <token: Args>            <.ws> \{ <MATCH=ElementList> \}

      <token: Mathargs>            <.ws> \{ <MATCH=MathUnit> \}

      <objrule: SpeL::Object::Option = Option>
                (<Name=OptName> =)? <Value=BareElement>

      <rule: OptName>            [^][|\$%#_{}~^,=\s\\-]++

      <rule: ComName>            [a-zA-Z@]++

      <token: Parameter>       [#]+ \d+

      <objrule: SpeL::Object::Limitsexpression = Limitsexpression>
                <Limitscommand> <.sub> <LBound=Bound> <.sup> <UBound=Bound>
                |
                <Limitscommand> <.sup> <UBound=Bound> <.sub> <LBound=Bound>
  	        |
                <Limitscommand> <.sup> <UBound=Bound>
                |
                <Limitscommand> <.sub> <LBound=Bound>
                |
                <Limitscommand>

      <token: Bound>
                <MATCH=MathGroup>
                |
                <MATCH=Number>
                |
                <MATCH=Command>
                |
                <MATCH=Variable>
                |
                <MATCH=Singletoken>

      <objtoken: SpeL::Object::Limitscommand = Limitscommand>
                \\ int
                |
                \\ sum
                |
                \\ lim

      <objtoken: SpeL::Object::TokenSequence = BareTokenSequence>
                [^][|\$%&#_{}^\\]++

      <objtoken: SpeL::Object::TokenSequence = TokenSequence>
                ( (?: [^\$%&#_{}|^\\] |
		    \\ \& |
		    \\ \" |
		    \\ \' |
		    \\ \` |
		    \\ \, |
		    \\ \{ |
                    \\ \} )+ )


      <objrule: SpeL::Object::Function = Function>
                <Sqrt> |
                <Trig> <Power>? <obracket> <Argument=Expression> <cbracket> |
                <Trig> <Power>? \{ <Argument=Expression> \} |
                <Trig> <Power>? (?<!\{) <Argument=Expression> |
                <Name=Variable> <Power>? <obracket> <Argument=Expression> <cbracket>


      <token: Trig>
                \\ (sin | cos | tan | cot | sec | csc |
                    arcsin | arccos | arctan | arccot |
                    sinh | cosh | tanh | coth)

      <objtoken: SpeL::Object::Variable = Variable>
                ( <Alphabet> | <Greek> ) <trailingws=ws>

      <token: Alphabet>
                [a-zA-Z]

      <token: Greek>
 		\\alpha |
		\\beta |
		\\[gG]amma |
		\\[dD]elta
                \\(?:var)?epsilon |
                \\zeta |
                \\eta |
                \\[tT]heta |
                \\vartheta |
                \\iota |
                \\kappa
                \\[lL]ambda |
                \\mu |
                \\nu |
                \\[xX]i |
                \\[pP]i |
                \\(?:var)?rho |
                \\[sS]igma |
                \\tau |
                \\[uU]psilon |
                \\[pP]hi |
                \\varphi |
                \\chi |
                \\[pP]si |
                \\[oO]mega

      <token: Sign>
                ([+-]) |
                \\pm

      <objrule: SpeL::Object::Number = Number>
                <Realnumber> <imag>? |
                <imag> <Realnumber>

      <token: imag>  j | i

      <objtoken: SpeL::Object::Realnumber = Realnumber>
                <Sign=([+-]?)> ( <Value=( (\d+)(?:(?:\.|,)\d+)?
                                 | ((?:\.|,)\d+)
                                 | \\ pi ({})?
                                 | \\ infty ({})? )> ) <trailingws=ws>

      <objtoken: SpeL::Object::TokenSequence = Singletoken>
                \w | \\_

      <token: verbatimcontent> .*?

  }xs
};


our $chunk = do {
  use Regexp::Grammars;
  qr{
      #      <logfile: - >
      # <debug: on>
      
      <Document> <.ws>? <Endinput>

      <nocontext:>

      <extends: elements>

      <objrule: SpeL::Object::Document = Document>
                <ElementList>

      <token: Endinput>       \\ endinput
  }xs
};

# to debug:
#      <logfile: - >
#      <debug: on>



sub new {
  my $class = shift;

  my $self = {};
  $class = (ref $class ? ref $class : $class );
  bless $self, $class;

  $self->{lines} = [];
  $self->{lineinfo} = [];
  return $self;
}


sub parseDocumentString {
  my $self = shift;
  my ( $document, $filename ) = @_;

  # preprocess macros and environments that are in the list
  # say STDERR "Before cleansing:\n" . $document;
  # Final prep to accomdate for docstrip '{Change History}'
 
  foreach my $arr (@$prepmacrolist) {
    # say STDERR "REGEXP = " . $regexp;
    if ( $arr->[1] eq 'keep' ) {
      $document =~ s/$arr->[0]/$2/g;
    }
    else {
      $document =~ s/$arr->[0]//g;
    }
  }
  foreach my $arr (@$prepenvlist) {
    # say STDERR "REGEXP = " . $arr->[0];
    if ( $arr->[1] eq 'keep' ) {
      $document =~ s/$arr->[0]/$+/g;
    }
    else {
      $document =~ s/$arr->[0]//g;
    }
  }
  # say STDERR "After cleansing:\n" . $document;
  
  # Parse the document
  my $doc = SpeL::Object::Document->new();
  $doc->{ElementList} = SpeL::Object::ElementList->new();
  $doc->{ElementList}->{Element} = [];

  my $result;
  if ( $result = ( $document . "\n\\endinput" ) =~ $SpeL::Parser::Chunk::chunk ) {
    if( exists $/{Document}->{ElementList}->{Element} ) {
      push @{$doc->{ElementList}->{Element}},
	@{$/{Document}->{ElementList}->{Element}};
    }
  }
  else {
    $![0] =~ /^(.*)__(\d+),(\d+)__(.*)$/;
    $![0] = $1 . $self->_errloc( $3 ) . $4;
    die( "Error: failed to parse $filename\n" .
	 "=> " . join( "\n   ", @! ) . "\n" );
  }
  return $doc;
}



sub parseDocument {
  my $self = shift;
  my ( $filename ) = @_;

  $self->{path} = dirname( $filename );

  my $file = IO::File->new();
  $file->open( "<$filename" )
    or croak( "Error: canot open '$filename' for reading\n" );
  @{$self->{lines}} = <$file>;

  # setup lineposition bookkeeping
  my $firstlineindex = 0;
  @{$self->{lineinfo}} =
    map{ my $retval = $firstlineindex;
         $firstlineindex += length( $_ );
         $retval
       } @{$self->{lines}};
  push @{$self->{lineinfo}}, $self->{lineinfo}->[-1] + 1;

  # parse
  my $document = join( '', @{$self->{lines}} );
  $document =~ s/^\{(.*)\}$/$1/s; # solve docstrip's problem of {Change History}
  $self->{tree} = $self->parseDocumentString( $document, $filename, 1 );

  delete $self->{lines};
  delete $self->{lineinfo};
}


sub object {
  my $self = shift;
  return $self;
}


sub _report {
  my ( $match ) = @_;
  return "__$match->{matchpos},$match->{matchline}__";
}


sub _errloc {
  my $self = shift;
  my ( $matchline ) = @_;
  return "line $matchline";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SpeL::Parser::Chunk - LaTeX file parser

=head1 VERSION

version 20240617.1739

=head1 METHODS

=head2 new()

creates a new Chunk parser

=head2 parseDocumentString( document, filename )

parses a document string

=over 4

=item document: the string containing the document to parse

=item filename of that document (used for error reporting)

=back

=head2 parseDocument( filename )

parses a document

=over 4

=item filename: name of the file containing the document to parse

=back

=head2 object()

accessor

=head2 _report( matchinfo )

auxiliary (private) routine to do the error reporting; warning: this is not a member function!

=head2 _errorloc( matchinfo )

auxiliary (private) routine to format the error locatoin.

=head1 SYNOPSYS

Parses LaTeX files for further processing by skimmer and reader

=head1 AUTHOR

Walter Daems <wdaems@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Walter Daems.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=head1 CONTRIBUTOR

=for stopwords Paul Levrie

Paul Levrie

=cut
