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
      <token: ws>
                (?: \\, | \\quad | \\qquad | ~ | \\\s | [\s\n] | (\%[^\n]*\n) )* |
                \\hskip \s* (:?\d+)?(?:\.\d+)? \s* <texunit> |
		\\relax

      <token: texunit>
                pt | mm | cm | in | ex | em | mu | sp

      <objrule: SpeL::Object::ElementList = ElementList>
                <[Element]>*

      

      <objrule: SpeL::Object::Element = Element>
                <!egroup> <!stray_etag>
                (?: <MATCH=VerbatimEnv> |
                    <MATCH=Env>  |
                    <MATCH=Group>  |
		    <MATCH=Qty> |
		    <MATCH=Num> |
		    <MATCH=Unit> |
                    <MATCH=MathInl> |
                    <MATCH=MathEnvSimple> |
                    <MATCH=MathEnv> |
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
                (?: <MATCH=VerbatimEnv> |
                    <MATCH=Env>  |
                    <MATCH=Group>  |
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
                \\approx |
                \\equiv |
                \\ne\b |
                \> |
		\< |
                \\gt\b |
		\\gg\b |
                \\lt\b |
		\\ll\b |
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
                ( <Begintext=Textinmathcommand> <Rest=Expression>? |
		  <Component=Number> <Rest=Expressionrest> |
		  <Sign> <Component=Number> <Rest=Expressionrest> |
		  <Component=Num> <Rest=Expressionrest> |
		  <Component=Qty> <Rest=Expressionrest> |
		  <Component=Unit> <Rest=Expressionrest> |
		  <Sign>? <Component=Function> <Rest=Expressionrest> |
		  <Sign>? <Component=Variable> <Rest=Expressionrest> |
		  <Sign>? <Component=Bracketconstruction> <Rest=Expressionrest> |
		  <Sign>? <Component=Fraction> <Rest=Expressionrest> |
		  <Sign>? <Component=Limitsexpression> <Rest=Expression> |
		  <Sign>? <Component=Unop> <Rest=Expressionrest> |
		  <Interval> |
		  <Component=Underbrace> <Rest=Expressionrest> |
		  <Component=Overbrace> <Rest=Expressionrest> |
		  <Ellipsis=(\\[lvcd]dots)> <Rest=Expressionrest> |
		  <Component=MathEnvInner> <Rest=Expressionrest> |
		  <Component=Matrix> <Rest=Expressionrest> |
		  <Sign>? <Component=Mathcommand> <Rest=Expressionrest> )

      <objrule: SpeL::Object::Bracketconstruction = Bracketconstruction>
                  <obracket> <Component=MathUnit> <cbracket> |
                  <obracket=(?:\()> <Component=MathUnit> <cbracket=(?:\))> |
                  <obracket=(?:\[)> <Component=MathUnit> <cbracket=(?:\])> |
		  <obracket=(?:\|)> <Component=MathUnit> <cbracket=(?:\|)> |
		  <obracket=(?:\\\|)> <Component=MathUnit> <cbracket=(?:\\\|)> |
                  <obracket=(?:\\\{)> <Component=MathUnit> <cbracket=(?:\\\})>

      <objrule: SpeL::Object::Bracketconstruction = Mathargconstruction>
                  <obracket=(?:\()> <Component=MathUnit> <cbracket=(?:\))> |
                  <obracket=(?:\[)> <Component=MathUnit> <cbracket=(?:\])> |
                  <obracket=(?:\{)> <Component=MathUnit> <cbracket=(?:\})>
		  
      <token: obracket>
                \\left <.ws> (?:\(|\[|\\\{|\||\\\|) |
                \\left <.ws> \.

      <token: cbracket>
                (?:\\right) <.ws> (?:\)|\]|\\\}|\||\\\|) |
                \\right <.ws> \. 

      <objrule: SpeL::Object::Fraction = Fraction>
                \\frac \{ (?: <num=Number> | <num=Expression> ) \}
                       \{ (?: <den=Number> | <den=Expression> ) \}

      <objrule: SpeL::Object::Expressionrest = Expressionrest>
                <Endtext=Textinmathcommand> |
                <Op=Subscript> <Remainder=Expressionrest> |
                <Op=Power> <Remainder=Expressionrest> |
		<Op=Faculty> <Remainder=Expressionrest> |
		<Op=Unop> <Remainder=Expressionrest> |
                <Op=Binop> <Remainder=Expression> |
		<Op=Arrow> <Remainder=Expression> |
                <ws>?

      <objtoken: SpeL::Object::Power = Power>
		<sup> <.ws> \{ <.ws> <Transpose=transpose> <.ws> \} |
                <sup> <Lit=(\w|[+-])> |
                <sup> <Group=Variable> |
		<sup> <Group=MathGroup>

      <objtoken: SpeL::Object::Subscript = Subscript>
                <sub> <Lit=(\w|[+-])> |
                <sub> <Group=Variable> |
		<sub> <Group=MathGroup>

      <objrule: SpeL::Object::Unop = Unop>
                <Op=(?:\\overline)> \{ <Arg=Expression> \} |
                <Op=(?:\\overline)> <Arg=Variable>

      <objrule: SpeL::Object::Binop = Binop>
                <Op=(?:[+-/])> |
                <Op=(?:\\pm)> |
                <Op=(?:\\times)> |
                <Op=(?:\\cdots)> |
                <Op=(?:\\cdot)> |
                <Op=(?:\\mid)> |
		<Op=(?:\\sim)> |
		<Op=Komma> |
		<Op=Semicolon> |
		<Com=Textinmathcommand> |
                <Op=ws>
		
      <objrule: SpeL::Object::Num = Num>
                \\ num <.ws> \{ <Value=Scientificnumber> \}

      <objrule: SpeL::Object::Qty = Qty>
                \\ qty <.ws> \{ <Value=Scientificnumber> \} <.ws> <Units=SIUnits>

      <objrule: SpeL::Object::Unit = Unit>
                \\ unit <.ws> <Units=SIUnits>

      <objrule: SpeL::Object::SIUnits = SIUnits>
                (?<braceunit>
	          \{
		    (?: (?> [^{}]+ ) | (?&braceunit))*
		  \}
	        )
                
      <objrule: SpeL::Object::Arrow = Arrow>
                <Op=(?:\\Rightarrow)> |
                <Op=(?:\\Leftarrow)> |
                <Op=(?:\\Leftrightarrow)> 

      <objtoken: SpeL::Object::Faculty = Faculty>
		\!
		
      <objtoken: SpeL::Object::Squareroot = Sqrt>
                \\sqrt <.ws> \[ <N=Expression> \] <.ws> \{ <Argument=Expression> \} |
                \\sqrt <.ws> \{ <Argument=Expression> \} 

      <objtoken: SpeL::Object::Command = Command>
                <!RelOperator>
                \\ ( (?!\\)(?!end)(?!begin)(?!par)(?!item)(?!left)(?!right)(?!hskip) <Name=ComName> ) <Options>? <[Args]>* <trailingws=ws>

      <objtoken: SpeL::Object::Command = Mathcommand> 
	        <!RelOperator>	
                \\ <Name=(?:mbox)> <[Args]>* <trailingws=ws> |
		<!RelOperator>
                \\ ( (?!\\)(?!end)(?!begin)(?!par)(?!item)(?!left)(?!right)(?!hskip)(?!underbrace)(?!overbrace) <Name=ComName> ) <Options>? <[Args=Mathargs]>* <trailingws=ws>
 
      <objtoken: SpeL::Object::Command = Textinmathcommand>
	        <!RelOperator>	
		\\ <Name=(?:text)> <[Args]> <trailingws=ws>


      <objtoken: SpeL::Object::VerbatimEnvironment = VerbatimEnv>
                \\ begin <.ws> \{ <verbatimtag> \}
 		  <verbatimcontent>
                \\ end <.ws> \{ <.everbatimtag( :verbatimtag )> \} <trailingws=ws>

      <objtoken: SpeL::Object::Environment = Env>
                <!math_envtag> \\ begin <.ws> \{ <tag> \} <Options>? <[Args]>* <trailingws=ws>
                  <ElementList> <.ws>
                \\ end <.ws> \{ <.etag( :tag )> \}
                |
                <!math_envtag> \\ begin <.ws> \{ <tag> \} <Options>? <[Args]>* <trailingws=ws>
                  <ElementList> <.ws>
                <matchline> <matchpos> <fatal: (?{"Missing \\end{$MATCH{tag}} at @{[ SpeL::Parser::Chunk::_report( \%MATCH ) ]}"})>

      <objtoken: SpeL::Object::MathEnvironmentSimple = MathEnvSimple>
                \\\[
                <MathUnit>
                \\\]

      <objtoken: SpeL::Object::MathEnvironment = MathEnv>
                \\ begin <.ws> \{ <mathtag> \} <Args>? <Options>? <[Args]>* <trailingws=ws>
		<[MathUnit]>+ % <.eol> <.ws>
                \\ end <.ws> \{ <.mathetag( :mathtag )> \}
                |
                \\ begin <.ws> \{ <mathtag> \} <Args>? <Options>? <[Args]>* <trailingws=ws>
                  <[MathUnit]>+ % <.eol> <.ws>
		  <matchline> <matchpos> <fatal: (?{"Missing \\end{$MATCH{mathtag}} at @{[ SpeL::Parser::Chunk::_report( \%MATCH ) ]}"})>
		
      <objtoken: SpeL::Object::MathEnvironmentInner = MathEnvInner>
                \\ begin <.ws> \{ <mathtaginner> \} <Options>? <[Args]>* <trailingws=ws>
                  <[MathUnit]>+ % <.eol> <.ws>
                \\ end <.ws> \{ <.mathetaginner( :mathtaginner )> \}
                |
                \\ begin <.ws> \{ <mathtaginner> \} <Options>? <[Args]>* <trailingws=ws>
                  <[MathUnit]>+ % <.eol> <.ws>
                <matchline> <matchpos> <fatal: (?{"Missing \\end{$MATCH{mathtaginner}} at @{[ SpeL::Parser::Chunk::_report( \%MATCH ) ]}"})>

     <objtoken: SpeL::Object::Matrix = Matrix>
                \\ begin <.ws> \{ <matrixtag> \} <Options>? <[Args]>* <trailingws=ws>
                  <[MathUnit]>+ % <.eol> <.ws>
                \\ end <.ws> \{ <.matrixetag( :matrixtag )> \}
                |
                \\ begin <.ws> \{ <matrixtag> \} <Options>? <[Args]>* <trailingws=ws>
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

      
      <token: BeginEnvLit>    \\ begin <.ws> \{ <\:env> \}

      <token: EndEnvLit>      \\ end <.ws> \{ <\:env> \}

      <token: bgroup>         \{

      <token: egroup>         \}

      <token: equals>         = <ws>

      <token: transpose>      \\ transpose
      
      <token: stray_etag>     \\ end \{

      <rule: math_envtag>     \\ begin <.ws> \{ <mathtag> \}

      <token: tag>            [^][\$&%#_{}~^\s]++

      <token: verbatimtag>    <MATCH=tag> <require: (?{ $^N =~ $gobblematcher }) >

      <rule: mathtaginner>    array\*? | aligned\*?

      <rule: mathetaginner>   (??{quotemeta $ARG{mathtaginner}})

      <rule: matrixtag>       (?:[bBpvV]|small)?matrix\*?

      <rule: matrixetag>      (??{quotemeta $ARG{matrixtag}})

      <rule: mathtag>         equation\*? | eqnarray\*? | alignat\*? | align\*? | gather\*?

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
                (<Name=OptName> =)? <Value=BareElement>?

      <rule: OptName>            [^][|\$%#_{}~^,=\s\\-]++

      <rule: ComName>            [a-zA-Z@]++

      <token: Parameter>       [#]+ \d+

      <objrule: SpeL::Object::Limitsexpression = Limitsexpression>
                <Limitscommand> <.sub> <LBound=Bound> <.sup> <UBound=Bound> |
                <Limitscommand> <.sup> <UBound=Bound> <.sub> <LBound=Bound> |
                <Limitscommand> <.sup> <UBound=Bound> |
                <Limitscommand> <.sub> <LBound=Bound> |
                <Limitscommand>

      <token: Bound>
                <MATCH=MathGroup> |
                <MATCH=Number> |
                <MATCH=Variable> |
                <MATCH=Command> |
                <MATCH=Singletoken>

      <objtoken: SpeL::Object::Limitscommand = Limitscommand>
                \\ int |
                \\ sum |
                \\ lim |
		\\ max |
		\\ min 

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
                    \\ \} |
		    \\ \$ |
		    \\ %  |
		    \\ _  )+ )


      <objrule: SpeL::Object::Function = Function>
                <Sqrt> |
                <Name=Trig> <Power>? <.ws> <Argument=Mathargconstruction> |
                <Name=Trig> <Power>? (?<!\{) <Argument=Expression> |
		<Name=Log> <Power>? <.ws> <Argument=Mathargconstruction> |
                <Name=Log> <Power>? (?<!\{) <Argument=Expression> |
                <Name=Variable> <Power>? <.ws> <Argument=Mathargconstruction>


      <objtoken: SpeL::Object::Trig = Trig>
                \\ <Op=(?: sin | cos | tan | cot | sec | csc |
                    arcsin | asin | arccos | acos | arctan | atan | arccot | acot |
                    sinh | cosh | tanh | coth)>

      <objrule: SpeL::Object::Log = Log>
                \\ <Op=(?:log|ln)> (?: <.sub> <base=Bound>)?

      <objrule: SpeL::Object::Underbrace = Underbrace>
                \\ underbrace <group=Mathargs> <sub> <under=Mathargs>

      <objrule: SpeL::Object::Overbrace = Overbrace>
                \\ overbrace <group=Mathargs> <sup> <over=Mathargs>
		  
      <objtoken: SpeL::Object::Variable = Variable>
                ( <Alphabet> | <Greek> ) <Subscript>?  <trailingws=ws>

      <token: Alphabet>
                [a-zA-Z]

      <token: Greek>
 		\\(?:mit|mup)?[aA]lpha |
		\\(?:mit|mup)?[bB]eta |
		\\(?:mit|mup)?[gG]amma |
		\\(?:mit|mup)?[dD]elta |
                \\(?:mit|mup)?(?:var)?epsilon |
                \\(?:mit|mup)?[zZ]eta |
                \\(?:mit|mup)?[eE]ta |
                \\(?:mit|mup)?[tT]heta |
                \\(?:mit|mup)?vartheta |
                \\(?:mit|mup)?iota |
                \\(?:mit|mup)?[kK]appa
                \\(?:mit|mup)?[lL]ambda |
                \\(?:mit|mup)?[mM]u |
                \\(?:mit|mup)?[nN]u |
                \\(?:mit|mup)?[xX]i |
                \\(?:mit|mup)?[pP]i |
                \\(?:var)?rho |
                \\(?:mit|mup)?[sS]igma |
                \\(?:mit|mup)?[tT]au |
                \\(?:mit|mup)?[uU]psilon |
                \\(?:mit|mup)?[pP]hi |
                \\(?:mit|mup)?varphi |
                \\(?:mit|mup)?[cC]hi |
                \\(?:mit|mup)?[pP]si |
                \\(?:mit|mup)?[oO]mega

      <token: Sign>
                ([+-]) |
                \\pm

      <objrule: SpeL::Object::Number = Number>
                <Realnumber> <imag>? |
                <imag> <Realnumber>

      <token: imag>  j | i

      <objtoken: SpeL::Object::Integernumber = Integernumber>
                <Sign=([+-]?)> <Value=(\d+)> <trailingws=ws>

      <objtoken: SpeL::Object::Realnumber = Realnumber>
                <Sign=([+-]?)> <Value=( (\d+)(?:(?:\.|,)\d+)?
		                 | ((?:\.|,)\d+)
                                 | \\ pi ({})?
                                 | \\ infty ({})? )> <trailingws=ws>

      <objtoken: SpeL::Object::Scientificnumber = Scientificnumber>
                <Sign=([+-]?)> (?: <Value=( (\d+)(?:(?:\.|,)\d+)?
                         		  | ((?:\.|,)\d+) )> )?
		               (?: [eE] <Exponent=Integernumber>)? <trailingws=ws>

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
  my ( $document, $filename, $debug ) = @_;

  # preprocess macros and environments that are in the list
  # say STDERR "Before cleansing:\n" . $document;
  # Final prep to accomdate for docstrip '{Change History}'

  $debug = 0 unless( defined( $debug ) );
  
  if ( $debug ) {
    say STDERR "=== Original ======================================================";
    say STDERR $document;
  }
  
  foreach my $entry (@$prepmacrolist) {
    
    my $mac_regexp = qr/ ( \\ $entry->{macro} ) /x;
    my $optarg_regexp = qr/ (
			      \[
			      [^]]*
			      \]
			    )? /x;
    my $mandarg_regexp = qr/ (?<braceunit>
			     \{
			       (?:
				 (?> [^{}]+ )
			       |
				 (?&braceunit)
			       )*
			     \}
			   )
			 /x;

    my $regexp = $mac_regexp;
    my $i = 1;
    my $optargcount = 0;
    if ( $entry->{argc}
	 ne '-NoValue-'
	 and
	 $entry->{argc} > 0 ) {
      if ( $entry->{optarg} ne '-NoValue-' ) {
	$regexp .= qr/ \s* /x . $optarg_regexp;
	$optargcount = 1;
	++$i;
      }
      for( ; $i <= $entry->{argc}; ++$i ) {
	$regexp .= qr/ \s* /x . $mandarg_regexp;
      }
    }

    while( 1 ) {
      my @matches = $document =~ /$regexp/;
      last unless( scalar @matches );
      
      my $replacement = $entry->{replacement};
      my $m = 1;
      foreach( $m = 1; $m < @matches; ++$m ) {
	if ( defined $matches[$m] ) {
	  my $r = $matches[$m];
	  $r = substr( $r, 1, length( $r ) -2 );
	  $replacement =~ s/##$m/$r/;
	}
	else {
	  # this only occurs for $m = 1, i.e. when the optional
	  # argument was not specified in the text, therefore,
	  # we replace it by the default
	  $replacement =~ s/##$m/$entry->{optarg}/;
	}
      }
      $document =~ s/$regexp/$replacement/;
    }
    #     $document =~ s/$arr->[0]/$2/g;
    #   }
    #   else {
    #     $document =~ s/$arr->[0]//g;
    #   }
  }

  
  foreach my $entry (@$prepenvlist) {
    
    my $envbegin_regexp  = qr/ \\ begin \{ $entry->{env} \} /x;
    my $envend_regexp  = qr/ \\ end \{ $entry->{env} \} /x;
    my $optarg_regexp = qr/ (
			      \[
			      [^]]*
			      \]
			    )?
			  /x;
    my $mandarg_regexp = qr/ (?<braceunit>
			      \{
			      (?:
				(?> [^{}]+ )
			      |
				(?&braceunit)
			      )*
			      \}
			    )
			  /x;
    my $envcontent_regexp = qr/ ( .* ) /sx;
    
    my $regexp = $envbegin_regexp;
    my $i = 1;
    my $optargcount = 0;
    if ( $entry->{argc}
	 ne '-NoValue-'
	 and
	 $entry->{argc} > 0 ) {
      if ( $entry->{optarg} ne '-NoValue-' ) {
	$regexp .= qr/ \s* /x . $optarg_regexp;
	$optargcount = 1;
	++$i;
      }
      for( ; $i <= $entry->{argc}; ++$i ) {
	$regexp .= qr/ \s* /x . $mandarg_regexp;
      }
    }
    $regexp .= $envcontent_regexp;
    $regexp .= $envend_regexp;
    
    while( 1 ) {
      my @matches = $document =~ /$regexp/;
      last unless( scalar @matches );
      
      my $replacement = $entry->{replacement};
      my $m = 1;
      foreach( $m = 1; $m < @matches; ++$m ) {
	if ( defined $matches[$m] ) {
	  my $r = $matches[$m];
	  $r = substr( $r, 1, length( $r ) -2 );
	  $replacement =~ s/##$m/$r/;
	}
	else {
	  # this only occurs for $m = 1, i.e. when the optional
	  # argument was not specified in the text, therefore,
	  # we replace it by the default
	  $replacement =~ s/##$m/$entry->{optarg}/;
	}
      }
      $document =~ s/$regexp/$replacement/;
    }
  }
  if ( $debug ) {
    say STDERR "=== Prepped  ======================================================";
    say STDERR $document;
  }

  
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
  
  if ( $debug ) {
    say STDERR "=== Parsed   ======================================================";
    say STDERR Data::Dumper->Dump( [ $doc ], [ 'tree' ] );
  }

  return $doc;
}



sub parseDocument {
  my $self = shift;
  my ( $filename, $debug ) = @_;

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
  $self->{tree} = $self->parseDocumentString( $document, $filename, $debug );

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

version 20241023.0918

=head1 METHODS

=head2 new()

creates a new Chunk parser

=head2 parseDocumentString( document, filename, debug )

parses a document string

=over 4

=item document: the string containing the document to parse

=item filename of that document (used for error reporting)

=item filename of the chunk to debug (only relevant in debugging mode)

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
