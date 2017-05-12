package TM::CTM::CParser;
use Parse::RecDescent;

{ my $ERRORS;


package Parse::RecDescent::TM::CTM::CParser;
use strict;
use vars qw($skip $AUTOLOAD  );
@Parse::RecDescent::TM::CTM::CParser::ISA = ();
$skip = '\s*';

			  my $store;
			  my $log;
			  my $implicits;
			  use Data::Dumper;
			  use TM;
			  use TM::Literal;
			  my %prefixes;
			  my %prefixes_backup;
			  my %wildcards;
			  my %wildcards_backup;
			  my %templates;

			  my $lid; 
		      ;


{
local $SIG{__WARN__} = sub {0};
# PRETEND TO BE IN Parse::RecDescent NAMESPACE
*Parse::RecDescent::TM::CTM::CParser::AUTOLOAD	= sub
{
	no strict 'refs';
	$AUTOLOAD =~ s/^Parse::RecDescent::TM::CTM::CParser/Parse::RecDescent/;
	goto &{$AUTOLOAD};
}
}

push @Parse::RecDescent::TM::CTM::CParser::ISA, 'Parse::RecDescent';
# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::string
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"string"};
	
	Parse::RecDescent::_trace(q{Trying rule: [string]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{string},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{/\\"\{3\}(.*?)\\"\{3\}/s, or /\\"([^\\n]*?)\\"/});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/\\"\{3\}(.*?)\\"\{3\}/s '^^']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{string});
		%item = (__RULE__ => q{string});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/\\"\{3\}(.*?)\\"\{3\}/s]}, Parse::RecDescent::_tracefirst($text),
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:\"{3}(.*?)\"{3})//s)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: ['^^']},
				  Parse::RecDescent::_tracefirst($text),
				  q{string},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{'^^'})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::_alternation_1_of_production_1_of_rule_string, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: ['^^']>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{string},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [_alternation_1_of_production_1_of_rule_string]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{_alternation_1_of_production_1_of_rule_string(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = new TM::Literal  ($1,       $item[2]->[0] || TM::Literal->STRING); };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [/\\"\{3\}(.*?)\\"\{3\}/s '^^']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/\\"([^\\n]*?)\\"/ '^^']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{string});
		%item = (__RULE__ => q{string});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/\\"([^\\n]*?)\\"/]}, Parse::RecDescent::_tracefirst($text),
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:\"([^\n]*?)\")//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: ['^^']},
				  Parse::RecDescent::_tracefirst($text),
				  q{string},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{'^^'})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::_alternation_1_of_production_2_of_rule_string, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: ['^^']>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{string},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [_alternation_1_of_production_2_of_rule_string]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{_alternation_1_of_production_2_of_rule_string(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = new TM::Literal  ($1,       $item[2]->[0] || TM::Literal->STRING); };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [/\\"([^\\n]*?)\\"/ '^^']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{string},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{string},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{string},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::tm_format
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"tm_format"};
	
	Parse::RecDescent::_trace(q{Trying rule: [tm_format]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{tm_format},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{string});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [string]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{tm_format},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{tm_format});
		%item = (__RULE__ => q{tm_format});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [string]},
				  Parse::RecDescent::_tracefirst($text),
				  q{tm_format},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::string($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [string]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{tm_format},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [string]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{tm_format},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{string}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [string]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{tm_format},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{tm_format},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{tm_format},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{tm_format},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{tm_format},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::topicmapid_directive
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"topicmapid_directive"};
	
	Parse::RecDescent::_trace(q{Trying rule: [topicmapid_directive]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{topicmapid_directive},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'#TOPICMAP'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['#TOPICMAP' name, or reify]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{topicmapid_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{topicmapid_directive});
		%item = (__RULE__ => q{topicmapid_directive});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['#TOPICMAP']},
					  Parse::RecDescent::_tracefirst($text),
					  q{topicmapid_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\#TOPICMAP//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_1_of_rule_topicmapid_directive]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topicmapid_directive},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{name, or reify})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::_alternation_1_of_production_1_of_rule_topicmapid_directive($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_1_of_rule_topicmapid_directive]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topicmapid_directive},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_1_of_rule_topicmapid_directive]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{topicmapid_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{_alternation_1_of_production_1_of_rule_topicmapid_directive}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{topicmapid_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
			  $log->logdie (__PACKAGE__ . ": TOPICMAP directive ignored (use proper means)");
		      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['#TOPICMAP' name, or reify]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{topicmapid_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{topicmapid_directive},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{topicmapid_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{topicmapid_directive},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{topicmapid_directive},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::xname
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"xname"};
	
	Parse::RecDescent::_trace(q{Trying rule: [xname]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{xname},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{/^\\w[:\\-\\w]*/, or /^\\w[-\\w]*/});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/^\\w[:\\-\\w]*/ <reject: ! $return>]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{xname},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{xname});
		%item = (__RULE__ => q{xname});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/^\\w[:\\-\\w]*/]}, Parse::RecDescent::_tracefirst($text),
					  q{xname},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:^\w[:\-\w]*)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{xname},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
			  my $name = $item[1];
			  if ($name =~ /^(\w+):/) {
			      my $prefix = $1;
			      if ($prefixes{$prefix}) {
				  $name =~ s/^$prefix:/$prefixes{$prefix}/;
				  $return = $name;
			      } else {
				  $return = undef;
			      }
			  } else {
			      $return = $name;
			  }
		      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		

		

		Parse::RecDescent::_trace(q{Trying directive: [<reject: ! $return>]},
					Parse::RecDescent::_tracefirst($text),
					  q{xname},
					  $tracelevel)
						if defined $::RD_TRACE; 
		$_tok = do { ( ! $return) ? undef : 1 };
		if (defined($_tok))
		{
			Parse::RecDescent::_trace(q{>>Matched directive<< (return value: [}
						. $_tok . q{])},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		else
		{
			Parse::RecDescent::_trace(q{<<Didn't match directive>>},
						Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		}
		
		last unless defined $_tok;
		push @item, $item{__DIRECTIVE1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/^\\w[:\\-\\w]*/ <reject: ! $return>]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{xname},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/^\\w[-\\w]*/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{xname},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{xname});
		%item = (__RULE__ => q{xname});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/^\\w[-\\w]*/]}, Parse::RecDescent::_tracefirst($text),
					  q{xname},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:^\w[-\w]*)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{xname},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
			  $return = $item[1];
		      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [/^\\w[-\\w]*/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{xname},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{xname},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{xname},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{xname},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{xname},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::occ_topic
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"occ_topic"};
	
	Parse::RecDescent::_trace(q{Trying rule: [occ_topic]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{occ_topic},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{name});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [name]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{occ_topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{occ_topic});
		%item = (__RULE__ => q{occ_topic});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [name]},
				  Parse::RecDescent::_tracefirst($text),
				  q{occ_topic},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::name($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [name]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{occ_topic},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [name]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{occ_topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{name}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [name]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{occ_topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{occ_topic},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{occ_topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{occ_topic},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{occ_topic},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::reifier
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"reifier"};
	
	Parse::RecDescent::_trace(q{Trying rule: [reifier]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{reifier},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'~'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['~' topic_ref]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{reifier},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{reifier});
		%item = (__RULE__ => q{reifier});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['~']},
					  Parse::RecDescent::_tracefirst($text),
					  q{reifier},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\~//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [topic_ref]},
				  Parse::RecDescent::_tracefirst($text),
				  q{reifier},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{topic_ref})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::topic_ref($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [topic_ref]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{reifier},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [topic_ref]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{reifier},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{topic_ref}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{reifier},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = $item[2]; };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['~' topic_ref]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{reifier},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{reifier},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{reifier},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{reifier},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{reifier},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::wildcard
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"wildcard"};
	
	Parse::RecDescent::_trace(q{Trying rule: [wildcard]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{wildcard},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{named_wildcard, or anonymous_wildcard});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [named_wildcard]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{wildcard},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{wildcard});
		%item = (__RULE__ => q{wildcard});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [named_wildcard]},
				  Parse::RecDescent::_tracefirst($text),
				  q{wildcard},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::named_wildcard($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [named_wildcard]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{wildcard},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [named_wildcard]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{wildcard},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{named_wildcard}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [named_wildcard]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{wildcard},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [anonymous_wildcard]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{wildcard},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{wildcard});
		%item = (__RULE__ => q{wildcard});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [anonymous_wildcard]},
				  Parse::RecDescent::_tracefirst($text),
				  q{wildcard},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::anonymous_wildcard($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [anonymous_wildcard]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{wildcard},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [anonymous_wildcard]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{wildcard},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{anonymous_wildcard}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [anonymous_wildcard]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{wildcard},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{wildcard},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{wildcard},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{wildcard},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{wildcard},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::iri
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"iri"};
	
	Parse::RecDescent::_trace(q{Trying rule: [iri]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{iri},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{/\\w[\\w\\d\\+\\-\\.]+:\\/([^\\.\\s:;]|\\.(?!\\s)|:(?!\\s)|;(?!\\s))+/, or qname});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/\\w[\\w\\d\\+\\-\\.]+:\\/([^\\.\\s:;]|\\.(?!\\s)|:(?!\\s)|;(?!\\s))+/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{iri},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{iri});
		%item = (__RULE__ => q{iri});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/\\w[\\w\\d\\+\\-\\.]+:\\/([^\\.\\s:;]|\\.(?!\\s)|:(?!\\s)|;(?!\\s))+/]}, Parse::RecDescent::_tracefirst($text),
					  q{iri},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:\w[\w\d\+\-\.]+:\/([^\.\s:;]|\.(?!\s)|:(?!\s)|;(?!\s))+)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/\\w[\\w\\d\\+\\-\\.]+:\\/([^\\.\\s:;]|\\.(?!\\s)|:(?!\\s)|;(?!\\s))+/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{iri},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [qname]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{iri},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{iri});
		%item = (__RULE__ => q{iri});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [qname]},
				  Parse::RecDescent::_tracefirst($text),
				  q{iri},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::qname($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [qname]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{iri},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [qname]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{iri},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{qname}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [qname]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{iri},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{iri},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{iri},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{iri},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{iri},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::scope
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"scope"};
	
	Parse::RecDescent::_trace(q{Trying rule: [scope]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{scope},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'@'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['@' topic_ref]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{scope},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{scope});
		%item = (__RULE__ => q{scope});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['@']},
					  Parse::RecDescent::_tracefirst($text),
					  q{scope},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\@//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [topic_ref]},
				  Parse::RecDescent::_tracefirst($text),
				  q{scope},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{topic_ref})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::topic_ref($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [topic_ref]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{scope},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [topic_ref]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{scope},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{topic_ref}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{scope},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = $item[2]; };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['@' topic_ref]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{scope},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{scope},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{scope},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{scope},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{scope},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::encoding
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"encoding"};
	
	Parse::RecDescent::_trace(q{Trying rule: [encoding]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{encoding},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'TODO'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['TODO' '@' string]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{encoding},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{encoding});
		%item = (__RULE__ => q{encoding});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['TODO']},
					  Parse::RecDescent::_tracefirst($text),
					  q{encoding},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\ATODO//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying terminal: ['@']},
					  Parse::RecDescent::_tracefirst($text),
					  q{encoding},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'@'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\@//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [string]},
				  Parse::RecDescent::_tracefirst($text),
				  q{encoding},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{string})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::string($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [string]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{encoding},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [string]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{encoding},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{string}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: ['TODO' '@' string]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{encoding},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{encoding},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{encoding},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{encoding},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{encoding},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::topicmap
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"topicmap"};
	
	Parse::RecDescent::_trace(q{Trying rule: [topicmap]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{topicmap},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{prolog});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [prolog directive directive, or template, or template_invocation, or topic, or association]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{topicmap});
		%item = (__RULE__ => q{topicmap});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [prolog]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topicmap},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::prolog($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [prolog]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topicmap},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [prolog]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{prolog}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying repeated subrule: [directive]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topicmap},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{directive})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::directive, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [directive]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topicmap},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [directive]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{directive(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying repeated subrule: [directive, or template, or template_invocation, or topic, or association]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topicmap},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{directive, or template, or template_invocation, or topic, or association})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::_alternation_1_of_production_1_of_rule_topicmap, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [directive, or template, or template_invocation, or topic, or association]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topicmap},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [_alternation_1_of_production_1_of_rule_topicmap]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{_alternation_1_of_production_1_of_rule_topicmap(s?)}} = $_tok;
		push @item, $_tok;
		



		Parse::RecDescent::_trace(q{>>Matched production: [prolog directive directive, or template, or template_invocation, or topic, or association]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{topicmap},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{topicmap},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{topicmap},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::topic
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"topic"};
	
	Parse::RecDescent::_trace(q{Trying rule: [topic]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{topic},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{topic_identity});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [topic_identity topic_tail '.']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{topic});
		%item = (__RULE__ => q{topic});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [topic_identity]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topic},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::topic_identity($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [topic_identity]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topic},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [topic_identity]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{topic_identity}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $lid = $item[1]; };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: [topic_tail]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topic},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{topic_tail})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::topic_tail, 0, 100000000, $_noactions,$expectation,sub { return [$lid] }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [topic_tail]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topic},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [topic_tail]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{topic_tail(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying terminal: ['.']},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'.'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\.//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: [topic_identity topic_tail '.']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{topic},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{topic},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{topic},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::subject
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"subject"};
	
	Parse::RecDescent::_trace(q{Trying rule: [subject]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{subject},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'%'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['%' uri]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{subject},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{subject});
		%item = (__RULE__ => q{subject});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['%']},
					  Parse::RecDescent::_tracefirst($text),
					  q{subject},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\%//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [uri]},
				  Parse::RecDescent::_tracefirst($text),
				  q{subject},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{uri})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::uri($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [uri]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{subject},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [uri]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{subject},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{uri}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{subject},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = $item[2]; };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['%' uri]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{subject},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{subject},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{subject},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{subject},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{subject},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::name
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"name"};
	
	Parse::RecDescent::_trace(q{Trying rule: [name]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{name},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'-'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['-' typing string scope reifier]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{name},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{name});
		%item = (__RULE__ => q{name});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['-']},
					  Parse::RecDescent::_tracefirst($text),
					  q{name},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\-//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: [typing]},
				  Parse::RecDescent::_tracefirst($text),
				  q{name},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{typing})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::typing, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [typing]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{name},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [typing]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{name},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{typing(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying subrule: [string]},
				  Parse::RecDescent::_tracefirst($text),
				  q{name},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{string})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::string($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [string]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{name},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [string]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{name},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{string}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying repeated subrule: [scope]},
				  Parse::RecDescent::_tracefirst($text),
				  q{name},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{scope})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::scope, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [scope]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{name},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [scope]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{name},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{scope(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying repeated subrule: [reifier]},
				  Parse::RecDescent::_tracefirst($text),
				  q{name},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{reifier})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::reifier, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [reifier]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{name},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [reifier]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{name},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{reifier(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{name},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
									  my $type  = $item[2]->[0] ? $item[2]->[0] : 'name';
									  my $scope = $item[4]->[0] ? $item[4]->[0] : 'us';

									  my ($a) = $store->assert ( bless [ undef,         # LID
												       $scope,               # SCOPE
												       $type,                # TYPE
												       TM->NAME,             # KIND
												       [ 'thing', 'value' ], # ROLES
												       [ $arg[0], $item[3] ],# PLAYERS
												       undef ], 'Assertion' );
									  $store->assert(Assertion->new(kind    => TM->ASSOC,
													type    => 'is-subclass-of',
													roles   => [ qw(subclass superclass) ],
													players => [ $type, 'name' ],
													scope   => undef)) if $type ne 'name';
									  $store->assert(Assertion->new(kind    => TM->ASSOC,
													type    => 'isa',
													roles   => [ qw(instance class) ],
													players => [ $scope, 'scope' ],
													scope   => undef)) if $scope ne 'us';
									  $store->internalize ($item[5]->[0], $a->[TM->LID]) if $item[5]->[0];
									  $return = $a;
								      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['-' typing string scope reifier]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{name},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{name},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{name},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{name},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{name},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::template_invocation
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"template_invocation"};
	
	Parse::RecDescent::_trace(q{Trying rule: [template_invocation]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{template_invocation},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{identifier});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [identifier '(' <leftop: argument /,/ argument> ')']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{template_invocation});
		%item = (__RULE__ => q{template_invocation});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [identifier]},
				  Parse::RecDescent::_tracefirst($text),
				  q{template_invocation},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::identifier($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [identifier]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{template_invocation},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [identifier]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{identifier}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $templates{$item[1]} };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		

		Parse::RecDescent::_trace(q{Trying terminal: ['(']},
					  Parse::RecDescent::_tracefirst($text),
					  q{template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'('})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\(//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying operator: [<leftop: argument /,/ argument>]},
				  Parse::RecDescent::_tracefirst($text),
				  q{template_invocation},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{<leftop: argument /,/ argument>})->at($text);

		$_tok = undef;
		OPLOOP: while (1)
		{
		  $repcount = 0;
		  my  @item;
		  
		  # MATCH LEFTARG
		  
		Parse::RecDescent::_trace(q{Trying subrule: [argument]},
				  Parse::RecDescent::_tracefirst($text),
				  q{template_invocation},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{argument})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::argument($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [argument]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{template_invocation},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [argument]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{argument}} = $_tok;
		push @item, $_tok;
		
		}


		  $repcount++;

		  my $savetext = $text;
		  my $backtrack;

		  # MATCH (OP RIGHTARG)(s)
		  while ($repcount < 100000000)
		  {
			$backtrack = 0;
			
		Parse::RecDescent::_trace(q{Trying terminal: [/,/]}, Parse::RecDescent::_tracefirst($text),
					  q{template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{/,/})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:,)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

			pop @item;
			if (defined $1) {push @item, $item{'argument(s?)'}=$1; $backtrack=1;}
			
		Parse::RecDescent::_trace(q{Trying subrule: [argument]},
				  Parse::RecDescent::_tracefirst($text),
				  q{template_invocation},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{argument})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::argument($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [argument]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{template_invocation},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [argument]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{argument}} = $_tok;
		push @item, $_tok;
		
		}

			$savetext = $text;
			$repcount++;
		  }
		  $text = $savetext;
		  pop @item if $backtrack;

		  
		  $_tok = [ @item ];
		  last;
		} 

		unless ($repcount>=0)
		{
			Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: argument /,/ argument>]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{template_invocation},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: argument /,/ argument>]<< (return value: [}
					  . qq{@{$_tok||[]}} . q{]},
					  Parse::RecDescent::_tracefirst($text),
					  q{template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;

		push @item, $item{'argument(s?)'}=$_tok||[];


		Parse::RecDescent::_trace(q{Trying terminal: [')']},
					  Parse::RecDescent::_tracefirst($text),
					  q{template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{')'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
									my $tmpl = $templates{$item[1]};  # we know we have something
									$text .= "\n\n%backup\n\n" . _expand_tmpl ($tmpl, $item[4]) . "\n\n%restore\n\n";
									$return = 1;
								      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [identifier '(' <leftop: argument /,/ argument> ')']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{template_invocation},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{template_invocation},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{template_invocation},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::uri
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"uri"};
	
	Parse::RecDescent::_trace(q{Trying rule: [uri]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{uri},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{string, or /(\\w+:[^\\"\\s)\\]\\>]+)/});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [string]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{uri},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{uri});
		%item = (__RULE__ => q{uri});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [string]},
				  Parse::RecDescent::_tracefirst($text),
				  q{uri},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::string($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [string]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{uri},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [string]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{uri},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{string}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [string]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{uri},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/(\\w+:[^\\"\\s)\\]\\>]+)/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{uri},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{uri});
		%item = (__RULE__ => q{uri});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/(\\w+:[^\\"\\s)\\]\\>]+)/]}, Parse::RecDescent::_tracefirst($text),
					  q{uri},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:(\w+:[^\"\s)\]\>]+))//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/(\\w+:[^\\"\\s)\\]\\>]+)/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{uri},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{uri},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{uri},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{uri},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{uri},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::backup_directive
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"backup_directive"};
	
	Parse::RecDescent::_trace(q{Trying rule: [backup_directive]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{backup_directive},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'%backup'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['%backup']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{backup_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{backup_directive});
		%item = (__RULE__ => q{backup_directive});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['%backup']},
					  Parse::RecDescent::_tracefirst($text),
					  q{backup_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\%backup//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{backup_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
									%prefixes_backup  = %prefixes;
									%wildcards_backup = %wildcards;
                                                                        %wildcards = ();
							  	      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['%backup']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{backup_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{backup_directive},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{backup_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{backup_directive},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{backup_directive},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::reify
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"reify"};
	
	Parse::RecDescent::_trace(q{Trying rule: [reify]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{reify},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'~'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['~' name]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{reify},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{reify});
		%item = (__RULE__ => q{reify});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['~']},
					  Parse::RecDescent::_tracefirst($text),
					  q{reify},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\~//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [name]},
				  Parse::RecDescent::_tracefirst($text),
				  q{reify},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{name})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::name($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [name]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{reify},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [name]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{reify},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{name}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: ['~' name]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{reify},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{reify},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{reify},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{reify},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{reify},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::baseuri_directive
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"baseuri_directive"};
	
	Parse::RecDescent::_trace(q{Trying rule: [baseuri_directive]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{baseuri_directive},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'#BASEURI'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['#BASEURI' uri]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{baseuri_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{baseuri_directive});
		%item = (__RULE__ => q{baseuri_directive});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['#BASEURI']},
					  Parse::RecDescent::_tracefirst($text),
					  q{baseuri_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\#BASEURI//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [uri]},
				  Parse::RecDescent::_tracefirst($text),
				  q{baseuri_directive},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{uri})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::uri($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [uri]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{baseuri_directive},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [uri]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{baseuri_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{uri}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: ['#BASEURI' uri]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{baseuri_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{baseuri_directive},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{baseuri_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{baseuri_directive},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{baseuri_directive},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::role
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"role"};
	
	Parse::RecDescent::_trace(q{Trying rule: [role]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{role},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{typing});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [typing player]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{role},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{role});
		%item = (__RULE__ => q{role});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [typing]},
				  Parse::RecDescent::_tracefirst($text),
				  q{role},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::typing($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [typing]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{role},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [typing]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{role},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{typing}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [player]},
				  Parse::RecDescent::_tracefirst($text),
				  q{role},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{player})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::player($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [player]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{role},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [player]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{role},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{player}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{role},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = [ $item[1], $item[2] ];  };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [typing player]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{role},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{role},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{role},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{role},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{role},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::xtopic
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"xtopic"};
	
	Parse::RecDescent::_trace(q{Trying rule: [xtopic]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{xtopic},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'['});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['[' name types topname reify subject indicator ']']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{xtopic},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{xtopic});
		%item = (__RULE__ => q{xtopic});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['[']},
					  Parse::RecDescent::_tracefirst($text),
					  q{xtopic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\[//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [name]},
				  Parse::RecDescent::_tracefirst($text),
				  q{xtopic},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{name})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::name($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [name]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{xtopic},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [name]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{xtopic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{name}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying repeated subrule: [types]},
				  Parse::RecDescent::_tracefirst($text),
				  q{xtopic},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{types})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::types, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [types]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{xtopic},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [types]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{xtopic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{types(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying repeated subrule: [topname]},
				  Parse::RecDescent::_tracefirst($text),
				  q{xtopic},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{topname})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::topname, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [topname]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{xtopic},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [topname]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{xtopic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{topname(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying repeated subrule: [reify]},
				  Parse::RecDescent::_tracefirst($text),
				  q{xtopic},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{reify})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::reify, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [reify]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{xtopic},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [reify]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{xtopic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{reify(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying repeated subrule: [subject]},
				  Parse::RecDescent::_tracefirst($text),
				  q{xtopic},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{subject})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::subject, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [subject]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{xtopic},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [subject]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{xtopic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{subject(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying repeated subrule: [indicator]},
				  Parse::RecDescent::_tracefirst($text),
				  q{xtopic},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{indicator})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::indicator, 0, 100000000, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [indicator]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{xtopic},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [indicator]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{xtopic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{indicator(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying terminal: [']']},
					  Parse::RecDescent::_tracefirst($text),
					  q{xtopic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{']'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\]//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{xtopic},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
#warn "topic ".Dumper \@item;
			  my $id = $store->internalize ($item[2] => $item[6]->[0]); # maybe there is a subject addr, maybe not

			  # add the subject indicators
			  map { $store->internalize ($id => $_ ) } @{$item[7]};


			  if ($item[3] and $item[3]->[0]) {
			      $store->assert ( map {
                                                       [ undef, 
							 undef, 
							 'isa', 
							 undef,
							 [ 'class', 'instance' ], 
							 [ $_,       $id ],
							 ] }  
						         @{$item[3]->[0]} );
			      map { $implicits->{'isa-thing'}->{$_}++ } @{$item[3]->[0]};   # the types and the ID are declared implicitely
			  }
#warn "item 4".Dumper $item[4];
			  if ($item[4] and @{$item[4]}) {
			      my $topnames = $item[4]->[0];
#warn "topnames ".Dumper $topnames;
			      my ($a) = $store->assert ( map {[ undef,                                            # LID
								   $topnames->{scope}->[0],                       # SCOPE
								   'name',                                        # TYPE
								   TM->NAME,                                      # KIND
								   [ 'thing', 'value' ],                          # ROLES
								   [ $id,     $_ ],                               # PLAYERS
								   undef ] }
							    @{$topnames->{names}}[0] );       # use the first for a name
			      $return = $a;
# TODO (2..3) for the variants

#warn "basename reify ".Dumper $item[5];
			      # reification of the basename
			      $store->internalize ($item[5]->[0], $a->[TM->LID]) if $item[5]->[0];

			      {
				  map { $implicits->{'isa-scope'}->{ $_ }++ } @{$topnames->{scope}};
			      }
			  }

			  $return = $id;
		      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['[' name types topname reify subject indicator ']']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{xtopic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{xtopic},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{xtopic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{xtopic},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{xtopic},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::variable
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"variable"};
	
	Parse::RecDescent::_trace(q{Trying rule: [variable]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{variable},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{/\\$\\w[\\w-]*/});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/\\$\\w[\\w-]*/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{variable},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{variable});
		%item = (__RULE__ => q{variable});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/\\$\\w[\\w-]*/]}, Parse::RecDescent::_tracefirst($text),
					  q{variable},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:\$\w[\w-]*)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/\\$\\w[\\w-]*/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{variable},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{variable},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{variable},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{variable},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{variable},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::boolean
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"boolean"};
	
	Parse::RecDescent::_trace(q{Trying rule: [boolean]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{boolean},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'true', or 'false'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['true']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{boolean},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{boolean});
		%item = (__RULE__ => q{boolean});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['true']},
					  Parse::RecDescent::_tracefirst($text),
					  q{boolean},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Atrue//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['true']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{boolean},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['false']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{boolean},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{boolean});
		%item = (__RULE__ => q{boolean});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['false']},
					  Parse::RecDescent::_tracefirst($text),
					  q{boolean},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Afalse//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['false']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{boolean},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{boolean},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{boolean},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{boolean},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{boolean},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::argument
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"argument"};
	
	Parse::RecDescent::_trace(q{Trying rule: [argument]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{argument},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{literal, or topic_ref});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [literal]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{argument},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{argument});
		%item = (__RULE__ => q{argument});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [literal]},
				  Parse::RecDescent::_tracefirst($text),
				  q{argument},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::literal($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [literal]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{argument},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [literal]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{argument},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{literal}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{argument},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {  $return = $item[1]->[0]; # get only the string value
								      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [literal]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{argument},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [topic_ref]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{argument},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{argument});
		%item = (__RULE__ => q{argument});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [topic_ref]},
				  Parse::RecDescent::_tracefirst($text),
				  q{argument},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::topic_ref($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [topic_ref]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{argument},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [topic_ref]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{argument},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{topic_ref}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{argument},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                                                                         my $bu = $store->baseuri;
									 ($return = $item[1]) =~ s/^$bu//;  # pretend internal identifier
								      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [topic_ref]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{argument},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{argument},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{argument},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{argument},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{argument},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::occur
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"occur"};
	
	Parse::RecDescent::_trace(q{Trying rule: [occur]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{occur},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'\{'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['\{' occ_topic ',' occ_type ',' resource '\}' scope reify]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{occur},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{occur});
		%item = (__RULE__ => q{occur});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
					  Parse::RecDescent::_tracefirst($text),
					  q{occur},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\{//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [occ_topic]},
				  Parse::RecDescent::_tracefirst($text),
				  q{occur},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{occ_topic})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::occ_topic($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [occ_topic]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{occur},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [occ_topic]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{occur},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{occ_topic}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: [',']},
					  Parse::RecDescent::_tracefirst($text),
					  q{occur},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{','})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\,//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [occ_type]},
				  Parse::RecDescent::_tracefirst($text),
				  q{occur},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{occ_type})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::occ_type($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [occ_type]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{occur},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [occ_type]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{occur},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{occ_type}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: [',']},
					  Parse::RecDescent::_tracefirst($text),
					  q{occur},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{','})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\,//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING3__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [resource]},
				  Parse::RecDescent::_tracefirst($text),
				  q{occur},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{resource})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::resource($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [resource]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{occur},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [resource]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{occur},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{resource}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
					  Parse::RecDescent::_tracefirst($text),
					  q{occur},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'\}'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\}//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING4__}=$&;
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: [scope]},
				  Parse::RecDescent::_tracefirst($text),
				  q{occur},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{scope})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::scope, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [scope]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{occur},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [scope]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{occur},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{scope(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying repeated subrule: [reify]},
				  Parse::RecDescent::_tracefirst($text),
				  q{occur},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{reify})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::reify, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [reify]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{occur},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [reify]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{occur},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{reify(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{occur},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
			  my $id = $store->internalize ($item[2]);
			  my ($a) = $store->assert ([ undef,                                         # LID
						      $item[8]->[0],                                 # SCOPE
						      $item[4],                                      # TYPE (MUST BE DEFINED!)
						      TM->OCC,                                       # KIND
						      [ 'thing', 'value' ],                          # ROLES
						      [ $id,     $item[6] ],                         # PLAYERS
						      undef ]);

			 { # memorize basename types and scopes as implicitely defined
			     $implicits->{'isa-scope'}-> { $item[8]->[0] }++ if $item[8]->[0];       # get the bloody scopes and tuck them away
			     $implicits->{'subclasses'}->{ 'occurrence' }->{ $item[4] }++;
			 }

#warn "reify ".Dumper $item[9];
			  $store->internalize ($item[9]->[0], $a->[TM->LID]) if $item[9]->[0];

			  $return = $a;
		      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['\{' occ_topic ',' occ_type ',' resource '\}' scope reify]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{occur},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{occur},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{occur},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{occur},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{occur},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::DATA
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"DATA"};
	
	Parse::RecDescent::_trace(q{Trying rule: [DATA]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{DATA},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'[['});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['[[' /.*(?=\\]\\])/sx ']]']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{DATA},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{DATA});
		%item = (__RULE__ => q{DATA});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['[[']},
					  Parse::RecDescent::_tracefirst($text),
					  q{DATA},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\[\[//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying terminal: [/.*(?=\\]\\])/sx]}, Parse::RecDescent::_tracefirst($text),
					  q{DATA},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{/.*(?=\\]\\])/sx})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:.*(?=\]\]))//sx)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying terminal: [']]']},
					  Parse::RecDescent::_tracefirst($text),
					  q{DATA},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{']]'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\]\]//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{DATA},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = $item[2]; };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['[[' /.*(?=\\]\\])/sx ']]']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{DATA},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{DATA},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{DATA},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{DATA},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{DATA},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::association
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"association"};
	
	Parse::RecDescent::_trace(q{Trying rule: [association]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{association},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{topic_identity});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [topic_identity '(' roles ')' scope reifier]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{association},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{association});
		%item = (__RULE__ => q{association});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [topic_identity]},
				  Parse::RecDescent::_tracefirst($text),
				  q{association},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::topic_identity($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [topic_identity]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{association},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [topic_identity]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{association},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{topic_identity}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['(']},
					  Parse::RecDescent::_tracefirst($text),
					  q{association},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'('})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\(//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [roles]},
				  Parse::RecDescent::_tracefirst($text),
				  q{association},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{roles})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::roles($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [roles]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{association},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [roles]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{association},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{roles}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: [')']},
					  Parse::RecDescent::_tracefirst($text),
					  q{association},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{')'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: [scope]},
				  Parse::RecDescent::_tracefirst($text),
				  q{association},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{scope})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::scope, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [scope]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{association},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [scope]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{association},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{scope(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying repeated subrule: [reifier]},
				  Parse::RecDescent::_tracefirst($text),
				  q{association},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{reifier})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::reifier, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [reifier]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{association},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [reifier]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{association},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{reifier(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{association},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
									  my $scope = $item[5]->[0] ? $item[5]->[0] : 'us';
									  my ($a) = $store->assert (bless [ undef,     # LID
												      $scope,          # SCOPE
												      $item[1],        # TYPE
												      TM->ASSOC,       # KIND
												      [ map { $_->[0] } @{$item[3]} ], # ROLES
												      [ map { $_->[1] } @{$item[3]} ], # PLAYERS
												      undef ], 'Assertion');
									  $return = $a;
									  $store->assert(Assertion->new(kind    => TM->ASSOC,
													type    => 'isa',
													roles   => [ qw(instance class) ],
													players => [ $scope, 'scope' ],
													scope   => undef)) if $scope ne 'us';
									  $store->internalize ($item[6]->[0], $a->[TM->LID]) if $item[6]->[0];
									  $return;
								      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [topic_identity '(' roles ')' scope reifier]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{association},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{association},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{association},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{association},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{association},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::version
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"version"};
	
	Parse::RecDescent::_trace(q{Trying rule: [version]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{version},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'TODO'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['TODO']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{version},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{version});
		%item = (__RULE__ => q{version});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['TODO']},
					  Parse::RecDescent::_tracefirst($text),
					  q{version},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\ATODO//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['TODO']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{version},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{version},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{version},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{version},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{version},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::wuri
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"wuri"};
	
	Parse::RecDescent::_trace(q{Trying rule: [wuri]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{wuri},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'<'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['<' iri '>']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{wuri},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{wuri});
		%item = (__RULE__ => q{wuri});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['<']},
					  Parse::RecDescent::_tracefirst($text),
					  q{wuri},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\<//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [iri]},
				  Parse::RecDescent::_tracefirst($text),
				  q{wuri},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{iri})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::iri($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [iri]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{wuri},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [iri]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{wuri},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{iri}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['>']},
					  Parse::RecDescent::_tracefirst($text),
					  q{wuri},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'>'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\>//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{wuri},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $item[2] };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['<' iri '>']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{wuri},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{wuri},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{wuri},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{wuri},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{wuri},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::occ_type
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"occ_type"};
	
	Parse::RecDescent::_trace(q{Trying rule: [occ_type]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{occ_type},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{name});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [name]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{occ_type},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{occ_type});
		%item = (__RULE__ => q{occ_type});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [name]},
				  Parse::RecDescent::_tracefirst($text),
				  q{occ_type},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::name($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [name]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{occ_type},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [name]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{occ_type},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{name}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [name]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{occ_type},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{occ_type},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{occ_type},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{occ_type},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{occ_type},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::resource
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"resource"};
	
	Parse::RecDescent::_trace(q{Trying rule: [resource]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{resource},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{uri, or DATA});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [uri]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{resource},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{resource});
		%item = (__RULE__ => q{resource});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [uri]},
				  Parse::RecDescent::_tracefirst($text),
				  q{resource},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::uri($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [uri]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{resource},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [uri]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{resource},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{uri}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{resource},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = new TM::Literal ($item[1], 'xsd:uri') };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [uri]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{resource},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [DATA]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{resource},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{resource});
		%item = (__RULE__ => q{resource});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [DATA]},
				  Parse::RecDescent::_tracefirst($text),
				  q{resource},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::DATA($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [DATA]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{resource},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [DATA]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{resource},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{DATA}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{resource},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = new TM::Literal ($item[1], 'xsd:string') };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [DATA]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{resource},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{resource},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{resource},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{resource},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{resource},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::occurrence
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"occurrence"};
	
	Parse::RecDescent::_trace(q{Trying rule: [occurrence]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{occurrence},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{type});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [type ':' iri_literal scope reifier]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{occurrence},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{occurrence});
		%item = (__RULE__ => q{occurrence});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [type]},
				  Parse::RecDescent::_tracefirst($text),
				  q{occurrence},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::type($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [type]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{occurrence},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [type]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{occurrence},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{type}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: [':']},
					  Parse::RecDescent::_tracefirst($text),
					  q{occurrence},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{':'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\://)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [iri_literal]},
				  Parse::RecDescent::_tracefirst($text),
				  q{occurrence},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{iri_literal})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::iri_literal($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [iri_literal]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{occurrence},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [iri_literal]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{occurrence},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{iri_literal}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying repeated subrule: [scope]},
				  Parse::RecDescent::_tracefirst($text),
				  q{occurrence},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{scope})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::scope, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [scope]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{occurrence},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [scope]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{occurrence},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{scope(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying repeated subrule: [reifier]},
				  Parse::RecDescent::_tracefirst($text),
				  q{occurrence},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{reifier})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::reifier, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [reifier]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{occurrence},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [reifier]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{occurrence},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{reifier(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{occurrence},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
									  my $type  = $item[1];
									  my $scope = $item[4]->[0] ? $item[4]->[0] : 'us';

									  my ($a) = $store->assert ( bless [ undef,          # LID
												       $scope,               # SCOPE
												       $type,                # TYPE
												       TM->OCC,              # KIND
												       [ 'thing', 'value' ], # ROLES
												       [ $arg[0], $item[3] ],# PLAYERS
												       undef ], 'Assertion' );
									  $store->assert(Assertion->new(kind    => TM->ASSOC,
													type    => 'is-subclass-of',
													roles   => [ qw(subclass superclass) ],
													players => [ $type, 'occurrence' ],
													scope   => undef)) if $type ne 'occurrence';
									  $store->assert(Assertion->new(kind    => TM->ASSOC,
													type    => 'isa',
													roles   => [ qw(instance class) ],
													players => [ $scope, 'scope' ],
													scope   => undef)) if $scope ne 'us';
									  $store->internalize ($item[5]->[0], $a->[TM->LID]) if $item[5]->[0];
									  $return = $a;
								      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [type ':' iri_literal scope reifier]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{occurrence},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{occurrence},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{occurrence},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{occurrence},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{occurrence},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::_alternation_1_of_production_1_of_rule_string
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_string"};
	
	Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_string]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{_alternation_1_of_production_1_of_rule_string},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'^^'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['^^' iri]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_string},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_string});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_string});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['^^']},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\^\^//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [iri]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_1_of_rule_string},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{iri})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::iri($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [iri]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_1_of_rule_string},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [iri]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{iri}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: ['^^' iri]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{_alternation_1_of_production_1_of_rule_string},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{_alternation_1_of_production_1_of_rule_string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{_alternation_1_of_production_1_of_rule_string},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{_alternation_1_of_production_1_of_rule_string},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::version_directive
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"version_directive"};
	
	Parse::RecDescent::_trace(q{Trying rule: [version_directive]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{version_directive},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'#VERSION'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['#VERSION' string]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{version_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{version_directive});
		%item = (__RULE__ => q{version_directive});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['#VERSION']},
					  Parse::RecDescent::_tracefirst($text),
					  q{version_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\#VERSION//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [string]},
				  Parse::RecDescent::_tracefirst($text),
				  q{version_directive},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{string})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::string($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [string]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{version_directive},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [string]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{version_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{string}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{version_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
			  my $version = $item[2];
			  $log->logdie (__PACKAGE__ . ": VERSION not supported '$version'") unless $version =~ /^1\.[23]$/;
		      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['#VERSION' string]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{version_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{version_directive},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{version_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{version_directive},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{version_directive},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::indicator
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"indicator"};
	
	Parse::RecDescent::_trace(q{Trying rule: [indicator]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{indicator},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'@'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['@' uri]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{indicator},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{indicator});
		%item = (__RULE__ => q{indicator});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['@']},
					  Parse::RecDescent::_tracefirst($text),
					  q{indicator},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\@//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [uri]},
				  Parse::RecDescent::_tracefirst($text),
				  q{indicator},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{uri})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::uri($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [uri]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{indicator},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [uri]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{indicator},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{uri}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{indicator},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = \ $item[2]; };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['@' uri]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{indicator},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{indicator},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{indicator},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{indicator},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{indicator},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::qname
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"qname"};
	
	Parse::RecDescent::_trace(q{Trying rule: [qname]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{qname},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{/(\\w[\\w-]+):(\\w[\\w-]+)/});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/(\\w[\\w-]+):(\\w[\\w-]+)/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{qname},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{qname});
		%item = (__RULE__ => q{qname});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/(\\w[\\w-]+):(\\w[\\w-]+)/]}, Parse::RecDescent::_tracefirst($text),
					  q{qname},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:(\w[\w-]+):(\w[\w-]+))//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{qname},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
  #                               ^^^^^^^^^^ ^^^^^^^^^^
  #                               identifier:identifier , but wo blanks
                                                                         die "undefined prefix '$item[1]'" unless $prefixes{$1};
									 $return = $prefixes{$1}.$2;
								       };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [/(\\w[\\w-]+):(\\w[\\w-]+)/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{qname},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{qname},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{qname},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{qname},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{qname},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::decimal
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"decimal"};
	
	Parse::RecDescent::_trace(q{Trying rule: [decimal]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{decimal},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{/-?\\d+\\.\\d+/});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/-?\\d+\\.\\d+/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{decimal},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{decimal});
		%item = (__RULE__ => q{decimal});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/-?\\d+\\.\\d+/]}, Parse::RecDescent::_tracefirst($text),
					  q{decimal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:-?\d+\.\d+)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/-?\\d+\\.\\d+/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{decimal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{decimal},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{decimal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{decimal},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{decimal},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::basesortdispname
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"basesortdispname"};
	
	Parse::RecDescent::_trace(q{Trying rule: [basesortdispname]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{basesortdispname},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{<leftop: basename ';' basename>});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [<leftop: basename ';' basename>]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{basesortdispname},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{basesortdispname});
		%item = (__RULE__ => q{basesortdispname});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying operator: [<leftop: basename ';' basename>]},
				  Parse::RecDescent::_tracefirst($text),
				  q{basesortdispname},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{})->at($text);

		$_tok = undef;
		OPLOOP: while (1)
		{
		  $repcount = 0;
		  my  @item;
		  
		  # MATCH LEFTARG
		  
		Parse::RecDescent::_trace(q{Trying subrule: [basename]},
				  Parse::RecDescent::_tracefirst($text),
				  q{basesortdispname},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{basename})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::basename($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [basename]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{basesortdispname},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [basename]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{basesortdispname},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{basename}} = $_tok;
		push @item, $_tok;
		
		}


		  $repcount++;

		  my $savetext = $text;
		  my $backtrack;

		  # MATCH (OP RIGHTARG)(s)
		  while ($repcount < 100000000)
		  {
			$backtrack = 0;
			
		Parse::RecDescent::_trace(q{Trying terminal: [';']},
					  Parse::RecDescent::_tracefirst($text),
					  q{basesortdispname},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{';'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\;//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

			pop @item;
			
			
		Parse::RecDescent::_trace(q{Trying subrule: [basename]},
				  Parse::RecDescent::_tracefirst($text),
				  q{basesortdispname},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{basename})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::basename($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [basename]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{basesortdispname},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [basename]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{basesortdispname},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{basename}} = $_tok;
		push @item, $_tok;
		
		}

			$savetext = $text;
			$repcount++;
		  }
		  $text = $savetext;
		  pop @item if $backtrack;

		  unless (@item) { undef $_tok; last }
		  $_tok = [ @item ];
		  last;
		} 

		unless ($repcount>=1)
		{
			Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: basename ';' basename>]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{basesortdispname},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: basename ';' basename>]<< (return value: [}
					  . qq{@{$_tok||[]}} . q{]},
					  Parse::RecDescent::_tracefirst($text),
					  q{basesortdispname},
					  $tracelevel)
						if defined $::RD_TRACE;

		push @item, $item{__DIRECTIVE1__}=$_tok||[];



		Parse::RecDescent::_trace(q{>>Matched production: [<leftop: basename ';' basename>]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{basesortdispname},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{basesortdispname},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{basesortdispname},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{basesortdispname},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{basesortdispname},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::_alternation_1_of_production_1_of_rule_include_directive
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_include_directive"};
	
	Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_include_directive]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{_alternation_1_of_production_1_of_rule_include_directive},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{/^inline:.*?\\n/, or iri});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/^inline:.*?\\n/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_include_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_include_directive});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_include_directive});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/^inline:.*?\\n/]}, Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_include_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:^inline:.*?\n)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/^inline:.*?\\n/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_include_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [iri]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_include_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_include_directive});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_include_directive});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [iri]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_1_of_rule_include_directive},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::iri($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [iri]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_1_of_rule_include_directive},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [iri]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_include_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{iri}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [iri]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_include_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{_alternation_1_of_production_1_of_rule_include_directive},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{_alternation_1_of_production_1_of_rule_include_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{_alternation_1_of_production_1_of_rule_include_directive},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{_alternation_1_of_production_1_of_rule_include_directive},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::anonymous_wildcard
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"anonymous_wildcard"};
	
	Parse::RecDescent::_trace(q{Trying rule: [anonymous_wildcard]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{anonymous_wildcard},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'?'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['?']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{anonymous_wildcard},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{anonymous_wildcard});
		%item = (__RULE__ => q{anonymous_wildcard});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['?']},
					  Parse::RecDescent::_tracefirst($text),
					  q{anonymous_wildcard},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\?//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{anonymous_wildcard},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = $store->internalize (sprintf "uuid-%010d", $TM::toplet_ctr++); };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['?']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{anonymous_wildcard},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{anonymous_wildcard},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{anonymous_wildcard},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{anonymous_wildcard},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{anonymous_wildcard},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::_alternation_1_of_production_1_of_rule_topic_tail
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_topic_tail"};
	
	Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_topic_tail]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{_alternation_1_of_production_1_of_rule_topic_tail},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{instance_of, or kind_of, or topic_template_invocation, or subject_identifier, or subject_locator, or assignment});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [instance_of]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_topic_tail});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_topic_tail});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [instance_of]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_1_of_rule_topic_tail},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::instance_of($thisparser,$text,$repeating,$_noactions,sub { return [$arg[0]] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [instance_of]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_1_of_rule_topic_tail},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [instance_of]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{instance_of}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [instance_of]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [kind_of]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_topic_tail});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_topic_tail});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [kind_of]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_1_of_rule_topic_tail},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::kind_of($thisparser,$text,$repeating,$_noactions,sub { return [$arg[0]] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [kind_of]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_1_of_rule_topic_tail},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [kind_of]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{kind_of}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [kind_of]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [topic_template_invocation]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[2];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_topic_tail});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_topic_tail});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [topic_template_invocation]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_1_of_rule_topic_tail},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::topic_template_invocation($thisparser,$text,$repeating,$_noactions,sub { return [$arg[0]] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [topic_template_invocation]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_1_of_rule_topic_tail},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [topic_template_invocation]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{topic_template_invocation}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [topic_template_invocation]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [subject_identifier]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[3];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_topic_tail});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_topic_tail});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [subject_identifier]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_1_of_rule_topic_tail},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::subject_identifier($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [subject_identifier]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_1_of_rule_topic_tail},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [subject_identifier]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{subject_identifier}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = undef if $text =~ /^\s*:/s };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $store->internalize ($arg[0], $item[1]); };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION2__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [subject_identifier]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [subject_locator]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[4];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_topic_tail});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_topic_tail});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [subject_locator]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_1_of_rule_topic_tail},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::subject_locator($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [subject_locator]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_1_of_rule_topic_tail},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [subject_locator]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{subject_locator}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = undef if $text =~ /^\s*:/s };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $store->internalize ($arg[0], $item[1]); };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION2__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [subject_locator]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [assignment]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[5];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_topic_tail});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_topic_tail});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [assignment]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_1_of_rule_topic_tail},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::assignment($thisparser,$text,$repeating,$_noactions,sub { return [$arg[0]] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [assignment]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_1_of_rule_topic_tail},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [assignment]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{assignment}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [assignment]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{_alternation_1_of_production_1_of_rule_topic_tail},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{_alternation_1_of_production_1_of_rule_topic_tail},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::literal
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"literal"};
	
	Parse::RecDescent::_trace(q{Trying rule: [literal]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{literal},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{decimal, or integer, or boolean, or wuri, or string});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [decimal]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{literal});
		%item = (__RULE__ => q{literal});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [decimal]},
				  Parse::RecDescent::_tracefirst($text),
				  q{literal},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::decimal($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [decimal]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{literal},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [decimal]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{decimal}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = new TM::Literal  ($item[1], TM::Literal->DECIMAL); };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [decimal]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [integer]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{literal});
		%item = (__RULE__ => q{literal});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [integer]},
				  Parse::RecDescent::_tracefirst($text),
				  q{literal},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::integer($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [integer]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{literal},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [integer]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{integer}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = new TM::Literal  ($item[1], TM::Literal->INTEGER); };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [integer]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [boolean]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[2];
		$text = $_[1];
		my $_savetext;
		@item = (q{literal});
		%item = (__RULE__ => q{literal});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [boolean]},
				  Parse::RecDescent::_tracefirst($text),
				  q{literal},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::boolean($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [boolean]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{literal},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [boolean]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{boolean}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = new TM::Literal  ($item[1], TM::Literal->BOOLEAN); };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [boolean]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [wuri]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[3];
		$text = $_[1];
		my $_savetext;
		@item = (q{literal});
		%item = (__RULE__ => q{literal});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [wuri]},
				  Parse::RecDescent::_tracefirst($text),
				  q{literal},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::wuri($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [wuri]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{literal},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [wuri]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{wuri}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = new TM::Literal  ($item[1], TM::Literal->URI); };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [wuri]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [string]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[4];
		$text = $_[1];
		my $_savetext;
		@item = (q{literal});
		%item = (__RULE__ => q{literal});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [string]},
				  Parse::RecDescent::_tracefirst($text),
				  q{literal},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::string($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [string]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{literal},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [string]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{string}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [string]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{literal},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{literal},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{literal},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::prefix_directive
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"prefix_directive"};
	
	Parse::RecDescent::_trace(q{Trying rule: [prefix_directive]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{prefix_directive},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'%prefix'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['%prefix' identifier reference]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{prefix_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{prefix_directive});
		%item = (__RULE__ => q{prefix_directive});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['%prefix']},
					  Parse::RecDescent::_tracefirst($text),
					  q{prefix_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\%prefix//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [identifier]},
				  Parse::RecDescent::_tracefirst($text),
				  q{prefix_directive},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{identifier})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::identifier($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [identifier]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{prefix_directive},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [identifier]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{prefix_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{identifier}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [reference]},
				  Parse::RecDescent::_tracefirst($text),
				  q{prefix_directive},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{reference})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::reference($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [reference]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{prefix_directive},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [reference]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{prefix_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{reference}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{prefix_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                                                                         my $uri = $item[3];
									 $prefixes{$item[2]} = $uri;
								      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['%prefix' identifier reference]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{prefix_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{prefix_directive},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{prefix_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{prefix_directive},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{prefix_directive},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::_alternation_1_of_production_1_of_rule_topicmapid_directive
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_topicmapid_directive"};
	
	Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_topicmapid_directive]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{_alternation_1_of_production_1_of_rule_topicmapid_directive},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{name, or reify});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [name]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_topicmapid_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_topicmapid_directive});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_topicmapid_directive});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [name]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_1_of_rule_topicmapid_directive},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::name($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [name]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_1_of_rule_topicmapid_directive},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [name]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topicmapid_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{name}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [name]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topicmapid_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [reify]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_topicmapid_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_topicmapid_directive});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_topicmapid_directive});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [reify]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_1_of_rule_topicmapid_directive},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::reify($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [reify]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_1_of_rule_topicmapid_directive},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [reify]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topicmapid_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{reify}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [reify]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topicmapid_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{_alternation_1_of_production_1_of_rule_topicmapid_directive},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{_alternation_1_of_production_1_of_rule_topicmapid_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{_alternation_1_of_production_1_of_rule_topicmapid_directive},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{_alternation_1_of_production_1_of_rule_topicmapid_directive},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::identifier
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"identifier"};
	
	Parse::RecDescent::_trace(q{Trying rule: [identifier]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{identifier},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{/\\w[\\w-]*/});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/\\w[\\w-]*/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{identifier},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{identifier});
		%item = (__RULE__ => q{identifier});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/\\w[\\w-]*/]}, Parse::RecDescent::_tracefirst($text),
					  q{identifier},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:\w[\w-]*)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/\\w[\\w-]*/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{identifier},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{identifier},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{identifier},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{identifier},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{identifier},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::kind_of
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"kind_of"};
	
	Parse::RecDescent::_trace(q{Trying rule: [kind_of]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{kind_of},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'ako'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['ako' topic_ref]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{kind_of},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{kind_of});
		%item = (__RULE__ => q{kind_of});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['ako']},
					  Parse::RecDescent::_tracefirst($text),
					  q{kind_of},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Aako//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [topic_ref]},
				  Parse::RecDescent::_tracefirst($text),
				  q{kind_of},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{topic_ref})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::topic_ref($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [topic_ref]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{kind_of},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [topic_ref]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{kind_of},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{topic_ref}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{kind_of},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {  $store->assert ( [ undef, 
											   undef, 
											   'is-subclass-of', 
											   undef,
											   [ qw(subclass superclass) ], 
											   [ $arg[0], $item[2] ],
											   ] ); };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['ako' topic_ref]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{kind_of},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{kind_of},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{kind_of},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{kind_of},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{kind_of},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::integer
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"integer"};
	
	Parse::RecDescent::_trace(q{Trying rule: [integer]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{integer},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{/-?\\d+/});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/-?\\d+/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{integer},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{integer});
		%item = (__RULE__ => q{integer});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/-?\\d+/]}, Parse::RecDescent::_tracefirst($text),
					  q{integer},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:-?\d+)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/-?\\d+/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{integer},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{integer},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{integer},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{integer},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{integer},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::topic_template_invocation
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"topic_template_invocation"};
	
	Parse::RecDescent::_trace(q{Trying rule: [topic_template_invocation]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{topic_template_invocation},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{identifier});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [identifier '(' <leftop: argument /,/ argument> ')']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{topic_template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{topic_template_invocation});
		%item = (__RULE__ => q{topic_template_invocation});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [identifier]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topic_template_invocation},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::identifier($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [identifier]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topic_template_invocation},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [identifier]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{identifier}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $templates{$item[1]} };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		

		Parse::RecDescent::_trace(q{Trying terminal: ['(']},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'('})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\(//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying operator: [<leftop: argument /,/ argument>]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topic_template_invocation},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{<leftop: argument /,/ argument>})->at($text);

		$_tok = undef;
		OPLOOP: while (1)
		{
		  $repcount = 0;
		  my  @item;
		  
		  # MATCH LEFTARG
		  
		Parse::RecDescent::_trace(q{Trying subrule: [argument]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topic_template_invocation},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{argument})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::argument($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [argument]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topic_template_invocation},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [argument]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{argument}} = $_tok;
		push @item, $_tok;
		
		}


		  $repcount++;

		  my $savetext = $text;
		  my $backtrack;

		  # MATCH (OP RIGHTARG)(s)
		  while ($repcount < 100000000)
		  {
			$backtrack = 0;
			
		Parse::RecDescent::_trace(q{Trying terminal: [/,/]}, Parse::RecDescent::_tracefirst($text),
					  q{topic_template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{/,/})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:,)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

			pop @item;
			if (defined $1) {push @item, $item{'argument(s)'}=$1; $backtrack=1;}
			
		Parse::RecDescent::_trace(q{Trying subrule: [argument]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topic_template_invocation},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{argument})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::argument($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [argument]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topic_template_invocation},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [argument]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{argument}} = $_tok;
		push @item, $_tok;
		
		}

			$savetext = $text;
			$repcount++;
		  }
		  $text = $savetext;
		  pop @item if $backtrack;

		  unless (@item) { undef $_tok; last }
		  $_tok = [ @item ];
		  last;
		} 

		unless ($repcount>=1)
		{
			Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: argument /,/ argument>]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topic_template_invocation},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: argument /,/ argument>]<< (return value: [}
					  . qq{@{$_tok||[]}} . q{]},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;

		push @item, $item{'argument(s)'}=$_tok||[];


		Parse::RecDescent::_trace(q{Trying terminal: [')']},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{')'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
									my $tmpl = $templates{$item[1]};
#		                                                        warn Dumper $templates{$item[1]};
#									warn Dumper $item[4];

									my $bu = $store->baseuri;
									$arg[0] =~ s/^$bu//;                   # pretend internal identifier
									unshift @{ $item[4] }, $arg[0];        # add topic as first param

									$text .= "\n\n%backup\n\n" . _expand_tmpl ($tmpl, $item[4]) . "\n\n%restore\n\n";
									$return = 1;

									sub _expand_tmpl {
									    my $tmpl   = shift;
									    my $name   = $tmpl->{name};
									    my $body   = $tmpl->{body};
									    my $params = $tmpl->{params};
									    my $args   = shift;
									    my %P;                             # formal -> actual 
									    foreach my $fp (@$params) {
										$P{$fp} = shift @$args  
										          or die "too few arguments for '$name'";
									    }
									    die "too many arguments for '$name'" if @$args;

									    foreach my $p (keys %P) {
										$p =~ s/\$//;                 # remove $, so that regexp below works
										$body =~ s/\$$p/$P{'$'.$p}/g;
									    }
									    return "\n" . $body . "\n";     # extend the text at the end;
									}
	                                                              };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [identifier '(' <leftop: argument /,/ argument> ')']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{topic_template_invocation},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{topic_template_invocation},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{topic_template_invocation},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{topic_template_invocation},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::startrule
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"startrule"};
	
	Parse::RecDescent::_trace(q{Trying rule: [startrule]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{startrule},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [topicmap]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{startrule},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{startrule});
		%item = (__RULE__ => q{startrule});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{startrule},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {  $store     = $arg[0]; 
									 $log       = $arg[1];
									 $implicits = $arg[2];
									 %prefixes  = ('xsd' => TM::Literal->XSD);
									 %templates = ();
									 %wildcards = ();
 								       };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		

		Parse::RecDescent::_trace(q{Trying subrule: [topicmap]},
				  Parse::RecDescent::_tracefirst($text),
				  q{startrule},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{topicmap})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::topicmap($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [topicmap]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{startrule},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [topicmap]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{startrule},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{topicmap}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [topicmap]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{startrule},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{startrule},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{startrule},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{startrule},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{startrule},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::_alternation_1_of_production_2_of_rule_string
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_2_of_rule_string"};
	
	Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_2_of_rule_string]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{_alternation_1_of_production_2_of_rule_string},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'^^'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['^^' iri]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_2_of_rule_string},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_2_of_rule_string});
		%item = (__RULE__ => q{_alternation_1_of_production_2_of_rule_string});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['^^']},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_2_of_rule_string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\^\^//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [iri]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_2_of_rule_string},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{iri})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::iri($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [iri]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_2_of_rule_string},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [iri]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_2_of_rule_string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{iri}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: ['^^' iri]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_2_of_rule_string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{_alternation_1_of_production_2_of_rule_string},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{_alternation_1_of_production_2_of_rule_string},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{_alternation_1_of_production_2_of_rule_string},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{_alternation_1_of_production_2_of_rule_string},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::roles
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"roles"};
	
	Parse::RecDescent::_trace(q{Trying rule: [roles]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{roles},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{<leftop: role /,/ role>});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [<leftop: role /,/ role>]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{roles},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{roles});
		%item = (__RULE__ => q{roles});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying operator: [<leftop: role /,/ role>]},
				  Parse::RecDescent::_tracefirst($text),
				  q{roles},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{})->at($text);

		$_tok = undef;
		OPLOOP: while (1)
		{
		  $repcount = 0;
		  my  @item;
		  
		  # MATCH LEFTARG
		  
		Parse::RecDescent::_trace(q{Trying subrule: [role]},
				  Parse::RecDescent::_tracefirst($text),
				  q{roles},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{role})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::role($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [role]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{roles},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [role]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{roles},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{role}} = $_tok;
		push @item, $_tok;
		
		}


		  $repcount++;

		  my $savetext = $text;
		  my $backtrack;

		  # MATCH (OP RIGHTARG)(s)
		  while ($repcount < 100000000)
		  {
			$backtrack = 0;
			
		Parse::RecDescent::_trace(q{Trying terminal: [/,/]}, Parse::RecDescent::_tracefirst($text),
					  q{roles},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{/,/})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:,)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

			pop @item;
			if (defined $1) {push @item, $item{'role(s)'}=$1; $backtrack=1;}
			
		Parse::RecDescent::_trace(q{Trying subrule: [role]},
				  Parse::RecDescent::_tracefirst($text),
				  q{roles},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{role})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::role($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [role]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{roles},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [role]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{roles},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{role}} = $_tok;
		push @item, $_tok;
		
		}

			$savetext = $text;
			$repcount++;
		  }
		  $text = $savetext;
		  pop @item if $backtrack;

		  unless (@item) { undef $_tok; last }
		  $_tok = [ @item ];
		  last;
		} 

		unless ($repcount>=1)
		{
			Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: role /,/ role>]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{roles},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: role /,/ role>]<< (return value: [}
					  . qq{@{$_tok||[]}} . q{]},
					  Parse::RecDescent::_tracefirst($text),
					  q{roles},
					  $tracelevel)
						if defined $::RD_TRACE;

		push @item, $item{'role(s)'}=$_tok||[];



		Parse::RecDescent::_trace(q{>>Matched production: [<leftop: role /,/ role>]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{roles},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{roles},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{roles},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{roles},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{roles},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::template
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"template"};
	
	Parse::RecDescent::_trace(q{Trying rule: [template]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{template},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'def'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['def' identifier parameters /(.*?)(?=\\bend\\n)/s 'end']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{template},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{template});
		%item = (__RULE__ => q{template});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['def']},
					  Parse::RecDescent::_tracefirst($text),
					  q{template},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Adef//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [identifier]},
				  Parse::RecDescent::_tracefirst($text),
				  q{template},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{identifier})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::identifier($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [identifier]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{template},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [identifier]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{template},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{identifier}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [parameters]},
				  Parse::RecDescent::_tracefirst($text),
				  q{template},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{parameters})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::parameters($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [parameters]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{template},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [parameters]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{template},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{parameters}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: [/(.*?)(?=\\bend\\n)/s]}, Parse::RecDescent::_tracefirst($text),
					  q{template},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{/(.*?)(?=\\bend\\n)/s})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:(.*?)(?=\bend\n))//s)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying terminal: ['end']},
					  Parse::RecDescent::_tracefirst($text),
					  q{template},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'end'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Aend//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{template},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                                                                       my $return = {
									   name   => $item[2],
									   params => $item[3],
									   body   => $item[4],
								       };
								       $templates{$return->{name}} 
								          and die "template '".$return->{name}."' already defined";
								       $templates{$return->{name}} = $return;
								      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['def' identifier parameters /(.*?)(?=\\bend\\n)/s 'end']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{template},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{template},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{template},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{template},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{template},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::assignment
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"assignment"};
	
	Parse::RecDescent::_trace(q{Trying rule: [assignment]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{assignment},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{name, or occurrence});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [name]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{assignment},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{assignment});
		%item = (__RULE__ => q{assignment});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [name]},
				  Parse::RecDescent::_tracefirst($text),
				  q{assignment},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::name($thisparser,$text,$repeating,$_noactions,sub { return [$arg[0]] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [name]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{assignment},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [name]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{assignment},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{name}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [name]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{assignment},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [occurrence]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{assignment},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{assignment});
		%item = (__RULE__ => q{assignment});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [occurrence]},
				  Parse::RecDescent::_tracefirst($text),
				  q{assignment},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::occurrence($thisparser,$text,$repeating,$_noactions,sub { return [$arg[0]] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [occurrence]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{assignment},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [occurrence]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{assignment},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{occurrence}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [occurrence]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{assignment},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{assignment},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{assignment},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{assignment},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{assignment},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::iri_literal
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"iri_literal"};
	
	Parse::RecDescent::_trace(q{Trying rule: [iri_literal]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{iri_literal},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{literal, or iri});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [literal]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{iri_literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{iri_literal});
		%item = (__RULE__ => q{iri_literal});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [literal]},
				  Parse::RecDescent::_tracefirst($text),
				  q{iri_literal},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::literal($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [literal]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{iri_literal},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [literal]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{iri_literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{literal}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [literal]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{iri_literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [iri]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{iri_literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{iri_literal});
		%item = (__RULE__ => q{iri_literal});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [iri]},
				  Parse::RecDescent::_tracefirst($text),
				  q{iri_literal},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::iri($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [iri]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{iri_literal},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [iri]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{iri_literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{iri}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{iri_literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = new TM::Literal ($item[1], TM::Literal->URI); };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [iri]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{iri_literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{iri_literal},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{iri_literal},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{iri_literal},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{iri_literal},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::subject_identifier
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"subject_identifier"};
	
	Parse::RecDescent::_trace(q{Trying rule: [subject_identifier]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{subject_identifier},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{iri});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [iri]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{subject_identifier},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{subject_identifier});
		%item = (__RULE__ => q{subject_identifier});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [iri]},
				  Parse::RecDescent::_tracefirst($text),
				  q{subject_identifier},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::iri($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [iri]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{subject_identifier},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [iri]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{subject_identifier},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{iri}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{subject_identifier},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = \ $item[1]; };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [iri]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{subject_identifier},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{subject_identifier},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{subject_identifier},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{subject_identifier},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{subject_identifier},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::parameters
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"parameters"};
	
	Parse::RecDescent::_trace(q{Trying rule: [parameters]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{parameters},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'('});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['(' <leftop: variable /,/ variable> ')']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{parameters},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{parameters});
		%item = (__RULE__ => q{parameters});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['(']},
					  Parse::RecDescent::_tracefirst($text),
					  q{parameters},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\(//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying operator: [<leftop: variable /,/ variable>]},
				  Parse::RecDescent::_tracefirst($text),
				  q{parameters},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{<leftop: variable /,/ variable>})->at($text);

		$_tok = undef;
		OPLOOP: while (1)
		{
		  $repcount = 0;
		  my  @item;
		  
		  # MATCH LEFTARG
		  
		Parse::RecDescent::_trace(q{Trying subrule: [variable]},
				  Parse::RecDescent::_tracefirst($text),
				  q{parameters},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{variable})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::variable($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [variable]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{parameters},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [variable]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{parameters},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{variable}} = $_tok;
		push @item, $_tok;
		
		}


		  $repcount++;

		  my $savetext = $text;
		  my $backtrack;

		  # MATCH (OP RIGHTARG)(s)
		  while ($repcount < 100000000)
		  {
			$backtrack = 0;
			
		Parse::RecDescent::_trace(q{Trying terminal: [/,/]}, Parse::RecDescent::_tracefirst($text),
					  q{parameters},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{/,/})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:,)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

			pop @item;
			if (defined $1) {push @item, $item{'variable(s?)'}=$1; $backtrack=1;}
			
		Parse::RecDescent::_trace(q{Trying subrule: [variable]},
				  Parse::RecDescent::_tracefirst($text),
				  q{parameters},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{variable})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::variable($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [variable]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{parameters},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [variable]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{parameters},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{variable}} = $_tok;
		push @item, $_tok;
		
		}

			$savetext = $text;
			$repcount++;
		  }
		  $text = $savetext;
		  pop @item if $backtrack;

		  
		  $_tok = [ @item ];
		  last;
		} 

		unless ($repcount>=0)
		{
			Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: variable /,/ variable>]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{parameters},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: variable /,/ variable>]<< (return value: [}
					  . qq{@{$_tok||[]}} . q{]},
					  Parse::RecDescent::_tracefirst($text),
					  q{parameters},
					  $tracelevel)
						if defined $::RD_TRACE;

		push @item, $item{'variable(s?)'}=$_tok||[];


		Parse::RecDescent::_trace(q{Trying terminal: [')']},
					  Parse::RecDescent::_tracefirst($text),
					  q{parameters},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{')'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{parameters},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = $item[2]; };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['(' <leftop: variable /,/ variable> ')']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{parameters},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{parameters},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{parameters},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{parameters},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{parameters},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::typing
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"typing"};
	
	Parse::RecDescent::_trace(q{Trying rule: [typing]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{typing},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{type});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [type ':']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{typing},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{typing});
		%item = (__RULE__ => q{typing});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [type]},
				  Parse::RecDescent::_tracefirst($text),
				  q{typing},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::type($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [type]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{typing},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [type]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{typing},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{type}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: [':']},
					  Parse::RecDescent::_tracefirst($text),
					  q{typing},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{':'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\://)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{typing},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = $item[1]; };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [type ':']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{typing},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{typing},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{typing},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{typing},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{typing},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::type
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"type"};
	
	Parse::RecDescent::_trace(q{Trying rule: [type]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{type},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{topic_ref});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [topic_ref]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{type},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{type});
		%item = (__RULE__ => q{type});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [topic_ref]},
				  Parse::RecDescent::_tracefirst($text),
				  q{type},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::topic_ref($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [topic_ref]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{type},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [topic_ref]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{type},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{topic_ref}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [topic_ref]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{type},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{type},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{type},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{type},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{type},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::prolog
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"prolog"};
	
	Parse::RecDescent::_trace(q{Trying rule: [prolog]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{prolog},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{encoding});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [encoding version]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{prolog},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{prolog});
		%item = (__RULE__ => q{prolog});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying repeated subrule: [encoding]},
				  Parse::RecDescent::_tracefirst($text),
				  q{prolog},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::encoding, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [encoding]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{prolog},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [encoding]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{prolog},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{encoding(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying repeated subrule: [version]},
				  Parse::RecDescent::_tracefirst($text),
				  q{prolog},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{version})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::version, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [version]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{prolog},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [version]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{prolog},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{version(?)}} = $_tok;
		push @item, $_tok;
		



		Parse::RecDescent::_trace(q{>>Matched production: [encoding version]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{prolog},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{prolog},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{prolog},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{prolog},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{prolog},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::types
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"types"};
	
	Parse::RecDescent::_trace(q{Trying rule: [types]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{types},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{':'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [':' name]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{types},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{types});
		%item = (__RULE__ => q{types});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [':']},
					  Parse::RecDescent::_tracefirst($text),
					  q{types},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\://)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: [name]},
				  Parse::RecDescent::_tracefirst($text),
				  q{types},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{name})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::name, 1, 100000000, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [name]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{types},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [name]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{types},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{name(s)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{types},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = $item[2]; };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [':' name]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{types},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{types},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{types},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{types},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{types},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::include_directive
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"include_directive"};
	
	Parse::RecDescent::_trace(q{Trying rule: [include_directive]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{include_directive},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'%include'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['%include' /^inline:.*?\\n/, or iri]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{include_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{include_directive});
		%item = (__RULE__ => q{include_directive});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['%include']},
					  Parse::RecDescent::_tracefirst($text),
					  q{include_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\%include//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_1_of_rule_include_directive]},
				  Parse::RecDescent::_tracefirst($text),
				  q{include_directive},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{/^inline:.*?\\n/, or iri})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::_alternation_1_of_production_1_of_rule_include_directive($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_1_of_rule_include_directive]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{include_directive},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_1_of_rule_include_directive]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{include_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{_alternation_1_of_production_1_of_rule_include_directive}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{include_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                                                                         my $src = $item[2];
									 my $include;                      # we are trying to figure that one out
									 if ($src =~ /^inline:(.*)/s) {
									     $include = $1;
									 } else {                          # we try our luck with LWP
									     use LWP::Simple;
									     $include = get($1) or
										 $TM::log->logdie (__PACKAGE__ .": unable to load '$1'\n");
									 }
									 $text = $include . $text;
								      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['%include' /^inline:.*?\\n/, or iri]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{include_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{include_directive},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{include_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{include_directive},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{include_directive},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::topic_ref
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"topic_ref"};
	
	Parse::RecDescent::_trace(q{Trying rule: [topic_ref]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{topic_ref},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{topic_identity, or embedded_topic});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [topic_identity]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{topic_ref},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{topic_ref});
		%item = (__RULE__ => q{topic_ref});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [topic_identity]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topic_ref},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::topic_identity($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [topic_identity]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topic_ref},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [topic_identity]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_ref},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{topic_identity}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_ref},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = ref ($item[1]) ? $store->internalize (undef, $item[1]) : $item[1]; };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [topic_identity]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_ref},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [embedded_topic]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{topic_ref},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{topic_ref});
		%item = (__RULE__ => q{topic_ref});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [embedded_topic]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topic_ref},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::embedded_topic($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [embedded_topic]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topic_ref},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [embedded_topic]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_ref},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{embedded_topic}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [embedded_topic]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_ref},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{topic_ref},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{topic_ref},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{topic_ref},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{topic_ref},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::topname
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"topname"};
	
	Parse::RecDescent::_trace(q{Trying rule: [topname]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{topname},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'='});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['=' basesortdispname scope]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{topname},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{topname});
		%item = (__RULE__ => q{topname});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['=']},
					  Parse::RecDescent::_tracefirst($text),
					  q{topname},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\=//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [basesortdispname]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topname},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{basesortdispname})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::basesortdispname($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [basesortdispname]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topname},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [basesortdispname]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{topname},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{basesortdispname}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying repeated subrule: [scope]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topname},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{scope})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::scope, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [scope]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topname},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [scope]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{topname},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{scope(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{topname},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
#warn "basenames".Dumper \@item;
			  $return = {
			      scope    => $item[3],
			      names    => $item[2],
			  };
		      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['=' basesortdispname scope]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{topname},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{topname},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{topname},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{topname},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{topname},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::topic_tail
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"topic_tail"};
	
	Parse::RecDescent::_trace(q{Trying rule: [topic_tail]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{topic_tail},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{instance_of, or kind_of, or topic_template_invocation, or subject_identifier, or subject_locator, or assignment});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [instance_of, or kind_of, or topic_template_invocation, or subject_identifier, or subject_locator, or assignment /;?/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{topic_tail});
		%item = (__RULE__ => q{topic_tail});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_1_of_rule_topic_tail]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topic_tail},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::_alternation_1_of_production_1_of_rule_topic_tail($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_1_of_rule_topic_tail]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topic_tail},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_1_of_rule_topic_tail]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{_alternation_1_of_production_1_of_rule_topic_tail}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: [/;?/]}, Parse::RecDescent::_tracefirst($text),
					  q{topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{/;?/})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:;?)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: [instance_of, or kind_of, or topic_template_invocation, or subject_identifier, or subject_locator, or assignment /;?/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{topic_tail},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{topic_tail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{topic_tail},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{topic_tail},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::reference
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"reference"};
	
	Parse::RecDescent::_trace(q{Trying rule: [reference]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{reference},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{iri, or /\\S+/});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [iri]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{reference},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{reference});
		%item = (__RULE__ => q{reference});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [iri]},
				  Parse::RecDescent::_tracefirst($text),
				  q{reference},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::iri($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [iri]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{reference},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [iri]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{reference},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{iri}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [iri]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{reference},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/\\S+/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{reference},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{reference});
		%item = (__RULE__ => q{reference});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/\\S+/]}, Parse::RecDescent::_tracefirst($text),
					  q{reference},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:\S+)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/\\S+/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{reference},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{reference},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{reference},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{reference},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{reference},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::instance_of
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"instance_of"};
	
	Parse::RecDescent::_trace(q{Trying rule: [instance_of]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{instance_of},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'isa'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['isa' topic_ref]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{instance_of},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{instance_of});
		%item = (__RULE__ => q{instance_of});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['isa']},
					  Parse::RecDescent::_tracefirst($text),
					  q{instance_of},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Aisa//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [topic_ref]},
				  Parse::RecDescent::_tracefirst($text),
				  q{instance_of},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{topic_ref})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::topic_ref($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [topic_ref]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{instance_of},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [topic_ref]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{instance_of},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{topic_ref}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{instance_of},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $store->assert ( [ undef, 
											   undef, 
											   'isa', 
											   undef,
											   [ 'class', 'instance' ], 
											   [ $item[2], $arg[0] ],
											   ] ); };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['isa' topic_ref]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{instance_of},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{instance_of},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{instance_of},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{instance_of},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{instance_of},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::named_wildcard
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"named_wildcard"};
	
	Parse::RecDescent::_trace(q{Trying rule: [named_wildcard]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{named_wildcard},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{/\\?(\\w[\\w-]*)/});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/\\?(\\w[\\w-]*)/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{named_wildcard},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{named_wildcard});
		%item = (__RULE__ => q{named_wildcard});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/\\?(\\w[\\w-]*)/]}, Parse::RecDescent::_tracefirst($text),
					  q{named_wildcard},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:\?(\w[\w-]*))//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{named_wildcard},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                                                                        my $id = $1;
									$wildcards{$id} ||=
									    $store->internalize (sprintf "uuid-%010d", $TM::toplet_ctr++);
									$return = $wildcards{$id};
								      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [/\\?(\\w[\\w-]*)/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{named_wildcard},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{named_wildcard},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{named_wildcard},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{named_wildcard},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{named_wildcard},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::topic_identity
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"topic_identity"};
	
	Parse::RecDescent::_trace(q{Trying rule: [topic_identity]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{topic_identity},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{subject_identifier, or identifier, or subject_locator, or wildcard});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [subject_identifier]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{topic_identity},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{topic_identity});
		%item = (__RULE__ => q{topic_identity});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [subject_identifier]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topic_identity},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::subject_identifier($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [subject_identifier]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topic_identity},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [subject_identifier]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_identity},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{subject_identifier}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_identity},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = $store->internalize (undef, $item[1]); };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [subject_identifier]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_identity},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [identifier]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{topic_identity},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{topic_identity});
		%item = (__RULE__ => q{topic_identity});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [identifier]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topic_identity},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::identifier($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [identifier]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topic_identity},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [identifier]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_identity},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{identifier}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_identity},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = $store->internalize ($item[1]); };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [identifier]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_identity},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [subject_locator]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{topic_identity},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[2];
		$text = $_[1];
		my $_savetext;
		@item = (q{topic_identity});
		%item = (__RULE__ => q{topic_identity});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [subject_locator]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topic_identity},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::subject_locator($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [subject_locator]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topic_identity},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [subject_locator]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_identity},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{subject_locator}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_identity},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = $store->internalize (undef, $item[1]); };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [subject_locator]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_identity},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [wildcard]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{topic_identity},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[3];
		$text = $_[1];
		my $_savetext;
		@item = (q{topic_identity});
		%item = (__RULE__ => q{topic_identity});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [wildcard]},
				  Parse::RecDescent::_tracefirst($text),
				  q{topic_identity},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::wildcard($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [wildcard]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{topic_identity},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [wildcard]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_identity},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{wildcard}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [wildcard]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{topic_identity},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{topic_identity},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{topic_identity},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{topic_identity},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{topic_identity},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::mergemap_directive
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"mergemap_directive"};
	
	Parse::RecDescent::_trace(q{Trying rule: [mergemap_directive]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{mergemap_directive},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'#MERGEMAP'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['#MERGEMAP' uri tm_format]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{mergemap_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{mergemap_directive});
		%item = (__RULE__ => q{mergemap_directive});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['#MERGEMAP']},
					  Parse::RecDescent::_tracefirst($text),
					  q{mergemap_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\#MERGEMAP//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [uri]},
				  Parse::RecDescent::_tracefirst($text),
				  q{mergemap_directive},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{uri})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::uri($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [uri]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{mergemap_directive},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [uri]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{mergemap_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{uri}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying repeated subrule: [tm_format]},
				  Parse::RecDescent::_tracefirst($text),
				  q{mergemap_directive},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{tm_format})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::TM::CTM::CParser::tm_format, 0, 1, $_noactions,$expectation,sub { \@arg }))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [tm_format]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{mergemap_directive},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [tm_format]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{mergemap_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{tm_format(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{mergemap_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
			  my $uri = $item[2];
#warn "uri is $uri";
			  my $format = $item[3]->[0] ? $item[3]->[0] : 'ltm';
			  my $tm;
			  if ($format =~ /^ltm$/i) {
			      $tm = new TM::Materialized::LTM (url => $uri);
			  } elsif ($format =~ /^xtm$/i) {
			      $tm = new TM::Materialized::XTM (url => $uri);
			  } elsif ($format =~ /^astma$/i) {
			      $tm = new TM::Materialized::AsTMa (url => $uri);
			  } else {
			      $log->logdie (__PACKAGE__ . ": unsupported TM format '$format'");
			  }
			  $tm->sync_in;
			  $store->add ($tm);
#warn "after merged in".Dumper $store;
			  $return = $uri;
		      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['#MERGEMAP' uri tm_format]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{mergemap_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{mergemap_directive},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{mergemap_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{mergemap_directive},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{mergemap_directive},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::embedded_topic
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"embedded_topic"};
	
	Parse::RecDescent::_trace(q{Trying rule: [embedded_topic]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{embedded_topic},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'['});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	my  $llid;


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [<rulevar: $llid>]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{embedded_topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{embedded_topic});
		%item = (__RULE__ => q{embedded_topic});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{>>Rejecting production<< (found <rulevar: $llid>)},
					 Parse::RecDescent::_tracefirst($text),
					  q{embedded_topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		undef $return;
		

		$_tok = undef;
		
		last unless defined $_tok;


		Parse::RecDescent::_trace(q{>>Matched production: [<rulevar: $llid>]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{embedded_topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['[' topic_tail ']']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{embedded_topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{embedded_topic});
		%item = (__RULE__ => q{embedded_topic});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['[']},
					  Parse::RecDescent::_tracefirst($text),
					  q{embedded_topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\[//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{embedded_topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $llid = sprintf "uuid-%010d", $TM::toplet_ctr++; };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		

		Parse::RecDescent::_trace(q{Trying subrule: [topic_tail]},
				  Parse::RecDescent::_tracefirst($text),
				  q{embedded_topic},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{topic_tail})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::topic_tail($thisparser,$text,$repeating,$_noactions,sub { return [$llid] })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [topic_tail]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{embedded_topic},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [topic_tail]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{embedded_topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{topic_tail}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: [']']},
					  Parse::RecDescent::_tracefirst($text),
					  q{embedded_topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{']'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\]//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{embedded_topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = $llid; };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['[' topic_tail ']']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{embedded_topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{embedded_topic},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{embedded_topic},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{embedded_topic},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{embedded_topic},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::player
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"player"};
	
	Parse::RecDescent::_trace(q{Trying rule: [player]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{player},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{topic_ref});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [topic_ref]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{player},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{player});
		%item = (__RULE__ => q{player});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [topic_ref]},
				  Parse::RecDescent::_tracefirst($text),
				  q{player},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::topic_ref($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [topic_ref]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{player},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [topic_ref]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{player},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{topic_ref}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [topic_ref]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{player},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{player},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{player},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{player},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{player},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::subject_locator
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"subject_locator"};
	
	Parse::RecDescent::_trace(q{Trying rule: [subject_locator]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{subject_locator},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'='});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['=' iri]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{subject_locator},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{subject_locator});
		%item = (__RULE__ => q{subject_locator});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['=']},
					  Parse::RecDescent::_tracefirst($text),
					  q{subject_locator},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\=//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [iri]},
				  Parse::RecDescent::_tracefirst($text),
				  q{subject_locator},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{iri})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::iri($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [iri]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{subject_locator},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [iri]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{subject_locator},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{iri}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{subject_locator},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = $item[2]; };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['=' iri]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{subject_locator},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{subject_locator},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{subject_locator},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{subject_locator},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{subject_locator},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::restore_directive
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"restore_directive"};
	
	Parse::RecDescent::_trace(q{Trying rule: [restore_directive]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{restore_directive},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'%restore'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['%restore']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{restore_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{restore_directive});
		%item = (__RULE__ => q{restore_directive});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['%restore']},
					  Parse::RecDescent::_tracefirst($text),
					  q{restore_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\%restore//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{restore_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
                                                                        %prefixes  = %prefixes_backup;
									%wildcards = %wildcards_backup;
							  	      };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: ['%restore']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{restore_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{restore_directive},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{restore_directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{restore_directive},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{restore_directive},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::_alternation_1_of_production_1_of_rule_topicmap
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_topicmap"};
	
	Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_topicmap]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{_alternation_1_of_production_1_of_rule_topicmap},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{directive, or template, or template_invocation, or topic, or association});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [directive]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_topicmap});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_topicmap});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [directive]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_1_of_rule_topicmap},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::directive($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [directive]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_1_of_rule_topicmap},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [directive]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{directive}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [directive]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [template]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_topicmap});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_topicmap});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [template]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_1_of_rule_topicmap},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::template($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [template]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_1_of_rule_topicmap},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [template]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{template}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [template]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [template_invocation]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[2];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_topicmap});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_topicmap});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [template_invocation]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_1_of_rule_topicmap},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::template_invocation($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [template_invocation]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_1_of_rule_topicmap},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [template_invocation]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{template_invocation}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [template_invocation]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [topic]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[3];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_topicmap});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_topicmap});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [topic]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_1_of_rule_topicmap},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::topic($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [topic]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_1_of_rule_topicmap},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [topic]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{topic}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [topic]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [association]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[4];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_topicmap});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_topicmap});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [association]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_1_of_rule_topicmap},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::association($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [association]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_1_of_rule_topicmap},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [association]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{association}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [association]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{_alternation_1_of_production_1_of_rule_topicmap},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{_alternation_1_of_production_1_of_rule_topicmap},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{_alternation_1_of_production_1_of_rule_topicmap},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{_alternation_1_of_production_1_of_rule_topicmap},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::basename
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"basename"};
	
	Parse::RecDescent::_trace(q{Trying rule: [basename]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{basename},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{string});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [string]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{basename},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{basename});
		%item = (__RULE__ => q{basename});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [string]},
				  Parse::RecDescent::_tracefirst($text),
				  q{basename},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::string($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [string]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{basename},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [string]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{basename},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{string}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{basename},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $return = new TM::Literal ($item[1], 'xsd:string'); };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		
		


		Parse::RecDescent::_trace(q{>>Matched production: [string]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{basename},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{basename},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{basename},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{basename},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{basename},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::comment
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"comment"};
	
	Parse::RecDescent::_trace(q{Trying rule: [comment]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{comment},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{'/*'});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['/*' /.+?/s '*/']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{comment},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{comment});
		%item = (__RULE__ => q{comment});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['/*']},
					  Parse::RecDescent::_tracefirst($text),
					  q{comment},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\/\*//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying terminal: [/.+?/s]}, Parse::RecDescent::_tracefirst($text),
					  q{comment},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{/.+?/s})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:.+?)//s)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying terminal: ['*/']},
					  Parse::RecDescent::_tracefirst($text),
					  q{comment},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{'*/'})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\*\///)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING2__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['/*' /.+?/s '*/']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{comment},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{comment},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{comment},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{comment},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{comment},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::TM::CTM::CParser::directive
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"directive"};
	
	Parse::RecDescent::_trace(q{Trying rule: [directive]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{directive},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
    my $expectation = new Parse::RecDescent::Expectation(q{prefix_directive, or restore_directive, or backup_directive, or include_directive});
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [prefix_directive]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{directive});
		%item = (__RULE__ => q{directive});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [prefix_directive]},
				  Parse::RecDescent::_tracefirst($text),
				  q{directive},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::prefix_directive($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [prefix_directive]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{directive},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [prefix_directive]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{prefix_directive}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [prefix_directive]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [restore_directive]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{directive});
		%item = (__RULE__ => q{directive});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [restore_directive]},
				  Parse::RecDescent::_tracefirst($text),
				  q{directive},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::restore_directive($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [restore_directive]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{directive},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [restore_directive]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{restore_directive}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [restore_directive]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [backup_directive]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[2];
		$text = $_[1];
		my $_savetext;
		@item = (q{directive});
		%item = (__RULE__ => q{directive});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [backup_directive]},
				  Parse::RecDescent::_tracefirst($text),
				  q{directive},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::backup_directive($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [backup_directive]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{directive},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [backup_directive]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{backup_directive}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [backup_directive]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [include_directive]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[3];
		$text = $_[1];
		my $_savetext;
		@item = (q{directive});
		%item = (__RULE__ => q{directive});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [include_directive]},
				  Parse::RecDescent::_tracefirst($text),
				  q{directive},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::TM::CTM::CParser::include_directive($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [include_directive]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{directive},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [include_directive]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{include_directive}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [include_directive]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{directive},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{directive},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{directive},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{directive},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}
}
package TM::CTM::CParser; sub new { my $self = bless( {
                 '_AUTOTREE' => undef,
                 'localvars' => '',
                 'startcode' => '',
                 '_check' => {
                               'thisoffset' => '',
                               'itempos' => '',
                               'prevoffset' => '',
                               'prevline' => '',
                               'prevcolumn' => '',
                               'thiscolumn' => ''
                             },
                 'namespace' => 'Parse::RecDescent::TM::CTM::CParser',
                 '_AUTOACTION' => undef,
                 'rules' => {
                              'string' => bless( {
                                                   'impcount' => 1,
                                                   'calls' => [
                                                                '_alternation_1_of_production_1_of_rule_string',
                                                                '_alternation_1_of_production_2_of_rule_string'
                                                              ],
                                                   'changed' => 0,
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => '0',
                                                                         'strcount' => 0,
                                                                         'dircount' => 0,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 1,
                                                                         'actcount' => 1,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'pattern' => '\\"{3}(.*?)\\"{3}',
                                                                                               'hashname' => '__PATTERN1__',
                                                                                               'description' => '/\\\\"\\{3\\}(.*?)\\\\"\\{3\\}/s',
                                                                                               'lookahead' => 0,
                                                                                               'rdelim' => '/',
                                                                                               'line' => -24,
                                                                                               'mod' => 's',
                                                                                               'ldelim' => '/'
                                                                                             }, 'Parse::RecDescent::Token' ),
                                                                                      bless( {
                                                                                               'subrule' => '_alternation_1_of_production_1_of_rule_string',
                                                                                               'expected' => '\'^^\'',
                                                                                               'min' => 0,
                                                                                               'argcode' => undef,
                                                                                               'max' => 1,
                                                                                               'matchrule' => 0,
                                                                                               'repspec' => '?',
                                                                                               'lookahead' => 0,
                                                                                               'line' => -24
                                                                                             }, 'Parse::RecDescent::Repetition' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => -24,
                                                                                               'code' => '{ $return = new TM::Literal  ($1,       $item[2]->[0] || TM::Literal->STRING); }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' ),
                                                                bless( {
                                                                         'number' => '1',
                                                                         'strcount' => 0,
                                                                         'dircount' => 0,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 1,
                                                                         'actcount' => 1,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'pattern' => '\\"([^\\n]*?)\\"',
                                                                                               'hashname' => '__PATTERN1__',
                                                                                               'description' => '/\\\\"([^\\\\n]*?)\\\\"/',
                                                                                               'lookahead' => 0,
                                                                                               'rdelim' => '/',
                                                                                               'line' => -23,
                                                                                               'mod' => '',
                                                                                               'ldelim' => '/'
                                                                                             }, 'Parse::RecDescent::Token' ),
                                                                                      bless( {
                                                                                               'subrule' => '_alternation_1_of_production_2_of_rule_string',
                                                                                               'expected' => '\'^^\'',
                                                                                               'min' => 0,
                                                                                               'argcode' => undef,
                                                                                               'max' => 1,
                                                                                               'matchrule' => 0,
                                                                                               'repspec' => '?',
                                                                                               'lookahead' => 0,
                                                                                               'line' => -23
                                                                                             }, 'Parse::RecDescent::Repetition' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => -23,
                                                                                               'code' => '{ $return = new TM::Literal  ($1,       $item[2]->[0] || TM::Literal->STRING); }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => -23
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'string',
                                                   'vars' => '',
                                                   'line' => -26
                                                 }, 'Parse::RecDescent::Rule' ),
                              'tm_format' => bless( {
                                                      'impcount' => 0,
                                                      'calls' => [
                                                                   'string'
                                                                 ],
                                                      'changed' => 0,
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'number' => '0',
                                                                            'strcount' => 0,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 0,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'subrule' => 'string',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => -171
                                                                                                }, 'Parse::RecDescent::Subrule' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'tm_format',
                                                      'vars' => '',
                                                      'line' => -171
                                                    }, 'Parse::RecDescent::Rule' ),
                              'topicmapid_directive' => bless( {
                                                                 'impcount' => 1,
                                                                 'calls' => [
                                                                              '_alternation_1_of_production_1_of_rule_topicmapid_directive'
                                                                            ],
                                                                 'changed' => 0,
                                                                 'opcount' => 0,
                                                                 'prods' => [
                                                                              bless( {
                                                                                       'number' => '0',
                                                                                       'strcount' => 1,
                                                                                       'dircount' => 0,
                                                                                       'uncommit' => undef,
                                                                                       'error' => undef,
                                                                                       'patcount' => 0,
                                                                                       'actcount' => 1,
                                                                                       'items' => [
                                                                                                    bless( {
                                                                                                             'pattern' => '#TOPICMAP',
                                                                                                             'hashname' => '__STRING1__',
                                                                                                             'description' => '\'#TOPICMAP\'',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => -197
                                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                                    bless( {
                                                                                                             'subrule' => '_alternation_1_of_production_1_of_rule_topicmapid_directive',
                                                                                                             'matchrule' => 0,
                                                                                                             'implicit' => 'name, or reify',
                                                                                                             'argcode' => undef,
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => -197
                                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                                    bless( {
                                                                                                             'hashname' => '__ACTION1__',
                                                                                                             'lookahead' => 0,
                                                                                                             'line' => -196,
                                                                                                             'code' => '{
			  $log->logdie (__PACKAGE__ . ": TOPICMAP directive ignored (use proper means)");
		      }'
                                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                                  ],
                                                                                       'line' => undef
                                                                                     }, 'Parse::RecDescent::Production' )
                                                                            ],
                                                                 'name' => 'topicmapid_directive',
                                                                 'vars' => '',
                                                                 'line' => -197
                                                               }, 'Parse::RecDescent::Rule' ),
                              'xname' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => '0',
                                                                        'strcount' => 0,
                                                                        'dircount' => 1,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 1,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'pattern' => '^\\w[:\\-\\w]*',
                                                                                              'hashname' => '__PATTERN1__',
                                                                                              'description' => '/^\\\\w[:\\\\-\\\\w]*/',
                                                                                              'lookahead' => 0,
                                                                                              'rdelim' => '/',
                                                                                              'line' => -59,
                                                                                              'mod' => '',
                                                                                              'ldelim' => '/'
                                                                                            }, 'Parse::RecDescent::Token' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -58,
                                                                                              'code' => '{
			  my $name = $item[1];
			  if ($name =~ /^(\\w+):/) {
			      my $prefix = $1;
			      if ($prefixes{$prefix}) {
				  $name =~ s/^$prefix:/$prefixes{$prefix}/;
				  $return = $name;
			      } else {
				  $return = undef;
			      }
			  } else {
			      $return = $name;
			  }
		      }'
                                                                                            }, 'Parse::RecDescent::Action' ),
                                                                                     bless( {
                                                                                              'hashname' => '__DIRECTIVE1__',
                                                                                              'name' => '<reject: ! $return>',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -44,
                                                                                              'code' => '( ! $return) ? undef : 1'
                                                                                            }, 'Parse::RecDescent::Directive' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' ),
                                                               bless( {
                                                                        'number' => '1',
                                                                        'strcount' => 0,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 1,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'pattern' => '^\\w[-\\w]*',
                                                                                              'hashname' => '__PATTERN1__',
                                                                                              'description' => '/^\\\\w[-\\\\w]*/',
                                                                                              'lookahead' => 0,
                                                                                              'rdelim' => '/',
                                                                                              'line' => -43,
                                                                                              'mod' => '',
                                                                                              'ldelim' => '/'
                                                                                            }, 'Parse::RecDescent::Token' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -42,
                                                                                              'code' => '{
			  $return = $item[1];
		      }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => -43
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'xname',
                                                  'vars' => '',
                                                  'line' => -59
                                                }, 'Parse::RecDescent::Rule' ),
                              'occ_topic' => bless( {
                                                      'impcount' => 0,
                                                      'calls' => [
                                                                   'name'
                                                                 ],
                                                      'changed' => 0,
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'number' => '0',
                                                                            'strcount' => 0,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 0,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'subrule' => 'name',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => -76
                                                                                                }, 'Parse::RecDescent::Subrule' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'occ_topic',
                                                      'vars' => '',
                                                      'line' => -76
                                                    }, 'Parse::RecDescent::Rule' ),
                              'reifier' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [
                                                                 'topic_ref'
                                                               ],
                                                    'changed' => 0,
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => '0',
                                                                          'strcount' => 1,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'pattern' => '~',
                                                                                                'hashname' => '__STRING1__',
                                                                                                'description' => '\'~\'',
                                                                                                'lookahead' => 0,
                                                                                                'line' => -229
                                                                                              }, 'Parse::RecDescent::Literal' ),
                                                                                       bless( {
                                                                                                'subrule' => 'topic_ref',
                                                                                                'matchrule' => 0,
                                                                                                'implicit' => undef,
                                                                                                'argcode' => undef,
                                                                                                'lookahead' => 0,
                                                                                                'line' => -229
                                                                                              }, 'Parse::RecDescent::Subrule' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => -229,
                                                                                                'code' => '{ $return = $item[2]; }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'reifier',
                                                    'vars' => '',
                                                    'line' => -229
                                                  }, 'Parse::RecDescent::Rule' ),
                              'wildcard' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [
                                                                  'named_wildcard',
                                                                  'anonymous_wildcard'
                                                                ],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => '0',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 0,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'named_wildcard',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -342
                                                                                               }, 'Parse::RecDescent::Subrule' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' ),
                                                                  bless( {
                                                                           'number' => '1',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 0,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'anonymous_wildcard',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -341
                                                                                               }, 'Parse::RecDescent::Subrule' )
                                                                                      ],
                                                                           'line' => -341
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'wildcard',
                                                     'vars' => '',
                                                     'line' => -344
                                                   }, 'Parse::RecDescent::Rule' ),
                              'iri' => bless( {
                                                'impcount' => 0,
                                                'calls' => [
                                                             'qname'
                                                           ],
                                                'changed' => 0,
                                                'opcount' => 0,
                                                'prods' => [
                                                             bless( {
                                                                      'number' => '0',
                                                                      'strcount' => 0,
                                                                      'dircount' => 0,
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => 1,
                                                                      'actcount' => 0,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'pattern' => '\\w[\\w\\d\\+\\-\\.]+:\\/([^\\.\\s:;]|\\.(?!\\s)|:(?!\\s)|;(?!\\s))+',
                                                                                            'hashname' => '__PATTERN1__',
                                                                                            'description' => '/\\\\w[\\\\w\\\\d\\\\+\\\\-\\\\.]+:\\\\/([^\\\\.\\\\s:;]|\\\\.(?!\\\\s)|:(?!\\\\s)|;(?!\\\\s))+/',
                                                                                            'lookahead' => 0,
                                                                                            'rdelim' => '/',
                                                                                            'line' => -7,
                                                                                            'mod' => '',
                                                                                            'ldelim' => '/'
                                                                                          }, 'Parse::RecDescent::Token' )
                                                                                 ],
                                                                      'line' => undef
                                                                    }, 'Parse::RecDescent::Production' ),
                                                             bless( {
                                                                      'number' => '1',
                                                                      'strcount' => 0,
                                                                      'dircount' => 0,
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => 0,
                                                                      'actcount' => 0,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'subrule' => 'qname',
                                                                                            'matchrule' => 0,
                                                                                            'implicit' => undef,
                                                                                            'argcode' => undef,
                                                                                            'lookahead' => 0,
                                                                                            'line' => -5
                                                                                          }, 'Parse::RecDescent::Subrule' )
                                                                                 ],
                                                                      'line' => -6
                                                                    }, 'Parse::RecDescent::Production' )
                                                           ],
                                                'name' => 'iri',
                                                'vars' => '',
                                                'line' => -7
                                              }, 'Parse::RecDescent::Rule' ),
                              'scope' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [
                                                               'topic_ref'
                                                             ],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => '0',
                                                                        'strcount' => 1,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'pattern' => '@',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\'@\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -231
                                                                                            }, 'Parse::RecDescent::Literal' ),
                                                                                     bless( {
                                                                                              'subrule' => 'topic_ref',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => -231
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -231,
                                                                                              'code' => '{ $return = $item[2]; }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'scope',
                                                  'vars' => '',
                                                  'line' => -231
                                                }, 'Parse::RecDescent::Rule' ),
                              'encoding' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [
                                                                  'string'
                                                                ],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => '0',
                                                                           'strcount' => 2,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 0,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => 'TODO',
                                                                                                 'hashname' => '__STRING1__',
                                                                                                 'description' => '\'TODO\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -454
                                                                                               }, 'Parse::RecDescent::Literal' ),
                                                                                        bless( {
                                                                                                 'pattern' => '@',
                                                                                                 'hashname' => '__STRING2__',
                                                                                                 'description' => '\'@\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -454
                                                                                               }, 'Parse::RecDescent::Literal' ),
                                                                                        bless( {
                                                                                                 'subrule' => 'string',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -454
                                                                                               }, 'Parse::RecDescent::Subrule' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'encoding',
                                                     'vars' => '',
                                                     'line' => -454
                                                   }, 'Parse::RecDescent::Rule' ),
                              'topicmap' => bless( {
                                                     'impcount' => 1,
                                                     'calls' => [
                                                                  'prolog',
                                                                  'directive',
                                                                  '_alternation_1_of_production_1_of_rule_topicmap'
                                                                ],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => '0',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 0,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'prolog',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 29
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'subrule' => 'directive',
                                                                                                 'expected' => undef,
                                                                                                 'min' => 0,
                                                                                                 'argcode' => undef,
                                                                                                 'max' => 100000000,
                                                                                                 'matchrule' => 0,
                                                                                                 'repspec' => 's?',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => 29
                                                                                               }, 'Parse::RecDescent::Repetition' ),
                                                                                        bless( {
                                                                                                 'subrule' => '_alternation_1_of_production_1_of_rule_topicmap',
                                                                                                 'expected' => 'directive, or template, or template_invocation, or topic, or association',
                                                                                                 'min' => 0,
                                                                                                 'argcode' => undef,
                                                                                                 'max' => 100000000,
                                                                                                 'matchrule' => 0,
                                                                                                 'repspec' => 's?',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -500
                                                                                               }, 'Parse::RecDescent::Repetition' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'topicmap',
                                                     'vars' => '',
                                                     'line' => 29
                                                   }, 'Parse::RecDescent::Rule' ),
                              'topic' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [
                                                               'topic_identity',
                                                               'topic_tail'
                                                             ],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => '0',
                                                                        'strcount' => 1,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'subrule' => 'topic_identity',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => -353
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -353,
                                                                                              'code' => '{ $lid = $item[1]; }'
                                                                                            }, 'Parse::RecDescent::Action' ),
                                                                                     bless( {
                                                                                              'subrule' => 'topic_tail',
                                                                                              'expected' => undef,
                                                                                              'min' => 0,
                                                                                              'argcode' => '[$lid]',
                                                                                              'max' => 100000000,
                                                                                              'matchrule' => 0,
                                                                                              'repspec' => 's?',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -352
                                                                                            }, 'Parse::RecDescent::Repetition' ),
                                                                                     bless( {
                                                                                              'pattern' => '.',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\'.\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -351
                                                                                            }, 'Parse::RecDescent::Literal' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'topic',
                                                  'vars' => '',
                                                  'line' => -355
                                                }, 'Parse::RecDescent::Rule' ),
                              'subject' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [
                                                                 'uri'
                                                               ],
                                                    'changed' => 0,
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => '0',
                                                                          'strcount' => 1,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'pattern' => '%',
                                                                                                'hashname' => '__STRING1__',
                                                                                                'description' => '\'%\'',
                                                                                                'lookahead' => 0,
                                                                                                'line' => -117
                                                                                              }, 'Parse::RecDescent::Literal' ),
                                                                                       bless( {
                                                                                                'subrule' => 'uri',
                                                                                                'matchrule' => 0,
                                                                                                'implicit' => undef,
                                                                                                'argcode' => undef,
                                                                                                'lookahead' => 0,
                                                                                                'line' => -117
                                                                                              }, 'Parse::RecDescent::Subrule' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => -117,
                                                                                                'code' => '{ $return = $item[2]; }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'subject',
                                                    'vars' => '',
                                                    'line' => -117
                                                  }, 'Parse::RecDescent::Rule' ),
                              'name' => bless( {
                                                 'impcount' => 0,
                                                 'calls' => [
                                                              'typing',
                                                              'string',
                                                              'scope',
                                                              'reifier'
                                                            ],
                                                 'changed' => 0,
                                                 'opcount' => 0,
                                                 'prods' => [
                                                              bless( {
                                                                       'number' => '0',
                                                                       'strcount' => 1,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 0,
                                                                       'actcount' => 1,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'pattern' => '-',
                                                                                             'hashname' => '__STRING1__',
                                                                                             'description' => '\'-\'',
                                                                                             'lookahead' => 0,
                                                                                             'line' => -290
                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                    bless( {
                                                                                             'subrule' => 'typing',
                                                                                             'expected' => undef,
                                                                                             'min' => 0,
                                                                                             'argcode' => undef,
                                                                                             'max' => 1,
                                                                                             'matchrule' => 0,
                                                                                             'repspec' => '?',
                                                                                             'lookahead' => 0,
                                                                                             'line' => -290
                                                                                           }, 'Parse::RecDescent::Repetition' ),
                                                                                    bless( {
                                                                                             'subrule' => 'string',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => -290
                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                    bless( {
                                                                                             'subrule' => 'scope',
                                                                                             'expected' => undef,
                                                                                             'min' => 0,
                                                                                             'argcode' => undef,
                                                                                             'max' => 1,
                                                                                             'matchrule' => 0,
                                                                                             'repspec' => '?',
                                                                                             'lookahead' => 0,
                                                                                             'line' => -290
                                                                                           }, 'Parse::RecDescent::Repetition' ),
                                                                                    bless( {
                                                                                             'subrule' => 'reifier',
                                                                                             'expected' => undef,
                                                                                             'min' => 0,
                                                                                             'argcode' => undef,
                                                                                             'max' => 1,
                                                                                             'matchrule' => 0,
                                                                                             'repspec' => '?',
                                                                                             'lookahead' => 0,
                                                                                             'line' => -290
                                                                                           }, 'Parse::RecDescent::Repetition' ),
                                                                                    bless( {
                                                                                             'hashname' => '__ACTION1__',
                                                                                             'lookahead' => 0,
                                                                                             'line' => -290,
                                                                                             'code' => '{
									  my $type  = $item[2]->[0] ? $item[2]->[0] : \'name\';
									  my $scope = $item[4]->[0] ? $item[4]->[0] : \'us\';

									  my ($a) = $store->assert ( bless [ undef,         # LID
												       $scope,               # SCOPE
												       $type,                # TYPE
												       TM->NAME,             # KIND
												       [ \'thing\', \'value\' ], # ROLES
												       [ $arg[0], $item[3] ],# PLAYERS
												       undef ], \'Assertion\' );
									  $store->assert(Assertion->new(kind    => TM->ASSOC,
													type    => \'is-subclass-of\',
													roles   => [ qw(subclass superclass) ],
													players => [ $type, \'name\' ],
													scope   => undef)) if $type ne \'name\';
									  $store->assert(Assertion->new(kind    => TM->ASSOC,
													type    => \'isa\',
													roles   => [ qw(instance class) ],
													players => [ $scope, \'scope\' ],
													scope   => undef)) if $scope ne \'us\';
									  $store->internalize ($item[5]->[0], $a->[TM->LID]) if $item[5]->[0];
									  $return = $a;
								      }'
                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'name',
                                                 'vars' => '',
                                                 'line' => -292
                                               }, 'Parse::RecDescent::Rule' ),
                              'template_invocation' => bless( {
                                                                'impcount' => 0,
                                                                'calls' => [
                                                                             'identifier',
                                                                             'argument'
                                                                           ],
                                                                'changed' => 0,
                                                                'opcount' => 0,
                                                                'prods' => [
                                                                             bless( {
                                                                                      'number' => '0',
                                                                                      'strcount' => 2,
                                                                                      'dircount' => 1,
                                                                                      'uncommit' => undef,
                                                                                      'error' => undef,
                                                                                      'patcount' => 1,
                                                                                      'actcount' => 2,
                                                                                      'op' => [],
                                                                                      'items' => [
                                                                                                   bless( {
                                                                                                            'subrule' => 'identifier',
                                                                                                            'matchrule' => 0,
                                                                                                            'implicit' => undef,
                                                                                                            'argcode' => undef,
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => -396
                                                                                                          }, 'Parse::RecDescent::Subrule' ),
                                                                                                   bless( {
                                                                                                            'hashname' => '__ACTION1__',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => -396,
                                                                                                            'code' => '{ $templates{$item[1]} }'
                                                                                                          }, 'Parse::RecDescent::Action' ),
                                                                                                   bless( {
                                                                                                            'pattern' => '(',
                                                                                                            'hashname' => '__STRING1__',
                                                                                                            'description' => '\'(\'',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => -395
                                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                                   bless( {
                                                                                                            'expected' => '<leftop: argument /,/ argument>',
                                                                                                            'min' => 0,
                                                                                                            'name' => '\'argument(s?)\'',
                                                                                                            'max' => 100000000,
                                                                                                            'leftarg' => bless( {
                                                                                                                                  'subrule' => 'argument',
                                                                                                                                  'matchrule' => 0,
                                                                                                                                  'implicit' => undef,
                                                                                                                                  'argcode' => undef,
                                                                                                                                  'lookahead' => 0,
                                                                                                                                  'line' => -395
                                                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                                            'rightarg' => bless( {
                                                                                                                                   'subrule' => 'argument',
                                                                                                                                   'matchrule' => 0,
                                                                                                                                   'implicit' => undef,
                                                                                                                                   'argcode' => undef,
                                                                                                                                   'lookahead' => 0,
                                                                                                                                   'line' => -395
                                                                                                                                 }, 'Parse::RecDescent::Subrule' ),
                                                                                                            'hashname' => '__DIRECTIVE1__',
                                                                                                            'type' => 'leftop',
                                                                                                            'op' => bless( {
                                                                                                                             'pattern' => ',',
                                                                                                                             'hashname' => '__PATTERN1__',
                                                                                                                             'description' => '/,/',
                                                                                                                             'lookahead' => 0,
                                                                                                                             'rdelim' => '/',
                                                                                                                             'line' => -395,
                                                                                                                             'mod' => '',
                                                                                                                             'ldelim' => '/'
                                                                                                                           }, 'Parse::RecDescent::Token' )
                                                                                                          }, 'Parse::RecDescent::Operator' ),
                                                                                                   bless( {
                                                                                                            'pattern' => ')',
                                                                                                            'hashname' => '__STRING2__',
                                                                                                            'description' => '\')\'',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => -395
                                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                                   bless( {
                                                                                                            'hashname' => '__ACTION2__',
                                                                                                            'lookahead' => 0,
                                                                                                            'line' => -395,
                                                                                                            'code' => '{
									my $tmpl = $templates{$item[1]};  # we know we have something
									$text .= "\\n\\n%backup\\n\\n" . _expand_tmpl ($tmpl, $item[4]) . "\\n\\n%restore\\n\\n";
									$return = 1;
								      }'
                                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                                 ],
                                                                                      'line' => undef
                                                                                    }, 'Parse::RecDescent::Production' )
                                                                           ],
                                                                'name' => 'template_invocation',
                                                                'vars' => '',
                                                                'line' => -397
                                                              }, 'Parse::RecDescent::Rule' ),
                              'uri' => bless( {
                                                'impcount' => 0,
                                                'calls' => [
                                                             'string'
                                                           ],
                                                'changed' => 0,
                                                'opcount' => 0,
                                                'prods' => [
                                                             bless( {
                                                                      'number' => '0',
                                                                      'strcount' => 0,
                                                                      'dircount' => 0,
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => 0,
                                                                      'actcount' => 0,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'subrule' => 'string',
                                                                                            'matchrule' => 0,
                                                                                            'implicit' => undef,
                                                                                            'argcode' => undef,
                                                                                            'lookahead' => 0,
                                                                                            'line' => -64
                                                                                          }, 'Parse::RecDescent::Subrule' )
                                                                                 ],
                                                                      'line' => undef
                                                                    }, 'Parse::RecDescent::Production' ),
                                                             bless( {
                                                                      'number' => '1',
                                                                      'strcount' => 0,
                                                                      'dircount' => 0,
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => 1,
                                                                      'actcount' => 0,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'pattern' => '(\\w+:[^\\"\\s)\\]\\>]+)',
                                                                                            'hashname' => '__PATTERN1__',
                                                                                            'description' => '/(\\\\w+:[^\\\\"\\\\s)\\\\]\\\\>]+)/',
                                                                                            'lookahead' => 0,
                                                                                            'rdelim' => '/',
                                                                                            'line' => -9,
                                                                                            'mod' => '',
                                                                                            'ldelim' => '/'
                                                                                          }, 'Parse::RecDescent::Token' )
                                                                                 ],
                                                                      'line' => undef
                                                                    }, 'Parse::RecDescent::Production' )
                                                           ],
                                                'name' => 'uri',
                                                'vars' => '',
                                                'line' => -64
                                              }, 'Parse::RecDescent::Rule' ),
                              'backup_directive' => bless( {
                                                             'impcount' => 0,
                                                             'calls' => [],
                                                             'changed' => 0,
                                                             'opcount' => 0,
                                                             'prods' => [
                                                                          bless( {
                                                                                   'number' => '0',
                                                                                   'strcount' => 1,
                                                                                   'dircount' => 0,
                                                                                   'uncommit' => undef,
                                                                                   'error' => undef,
                                                                                   'patcount' => 0,
                                                                                   'actcount' => 1,
                                                                                   'items' => [
                                                                                                bless( {
                                                                                                         'pattern' => '%backup',
                                                                                                         'hashname' => '__STRING1__',
                                                                                                         'description' => '\'%backup\'',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => -485
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'hashname' => '__ACTION1__',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => -485,
                                                                                                         'code' => '{
									%prefixes_backup  = %prefixes;
									%wildcards_backup = %wildcards;
                                                                        %wildcards = ();
							  	      }'
                                                                                                       }, 'Parse::RecDescent::Action' )
                                                                                              ],
                                                                                   'line' => undef
                                                                                 }, 'Parse::RecDescent::Production' )
                                                                        ],
                                                             'name' => 'backup_directive',
                                                             'vars' => '',
                                                             'line' => -486
                                                           }, 'Parse::RecDescent::Rule' ),
                              'reify' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [
                                                               'name'
                                                             ],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => '0',
                                                                        'strcount' => 1,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 0,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'pattern' => '~',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\'~\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -72
                                                                                            }, 'Parse::RecDescent::Literal' ),
                                                                                     bless( {
                                                                                              'subrule' => 'name',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => -72
                                                                                            }, 'Parse::RecDescent::Subrule' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'reify',
                                                  'vars' => '',
                                                  'line' => -72
                                                }, 'Parse::RecDescent::Rule' ),
                              'baseuri_directive' => bless( {
                                                              'impcount' => 0,
                                                              'calls' => [
                                                                           'uri'
                                                                         ],
                                                              'changed' => 0,
                                                              'opcount' => 0,
                                                              'prods' => [
                                                                           bless( {
                                                                                    'number' => '0',
                                                                                    'strcount' => 1,
                                                                                    'dircount' => 0,
                                                                                    'uncommit' => undef,
                                                                                    'error' => undef,
                                                                                    'patcount' => 0,
                                                                                    'actcount' => 0,
                                                                                    'items' => [
                                                                                                 bless( {
                                                                                                          'pattern' => '#BASEURI',
                                                                                                          'hashname' => '__STRING1__',
                                                                                                          'description' => '\'#BASEURI\'',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => -169
                                                                                                        }, 'Parse::RecDescent::Literal' ),
                                                                                                 bless( {
                                                                                                          'subrule' => 'uri',
                                                                                                          'matchrule' => 0,
                                                                                                          'implicit' => undef,
                                                                                                          'argcode' => undef,
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => -169
                                                                                                        }, 'Parse::RecDescent::Subrule' )
                                                                                               ],
                                                                                    'line' => undef
                                                                                  }, 'Parse::RecDescent::Production' )
                                                                         ],
                                                              'name' => 'baseuri_directive',
                                                              'vars' => '',
                                                              'line' => -169
                                                            }, 'Parse::RecDescent::Rule' ),
                              'role' => bless( {
                                                 'impcount' => 0,
                                                 'calls' => [
                                                              'typing',
                                                              'player'
                                                            ],
                                                 'changed' => 0,
                                                 'opcount' => 0,
                                                 'prods' => [
                                                              bless( {
                                                                       'number' => '0',
                                                                       'strcount' => 0,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 0,
                                                                       'actcount' => 1,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'subrule' => 'typing',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => -359
                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                    bless( {
                                                                                             'subrule' => 'player',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => -359
                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                    bless( {
                                                                                             'hashname' => '__ACTION1__',
                                                                                             'lookahead' => 0,
                                                                                             'line' => -359,
                                                                                             'code' => '{ $return = [ $item[1], $item[2] ];  }'
                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'role',
                                                 'vars' => '',
                                                 'line' => -359
                                               }, 'Parse::RecDescent::Rule' ),
                              'xtopic' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'name',
                                                                'types',
                                                                'topname',
                                                                'reify',
                                                                'subject',
                                                                'indicator'
                                                              ],
                                                   'changed' => 0,
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => '0',
                                                                         'strcount' => 2,
                                                                         'dircount' => 0,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 1,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'pattern' => '[',
                                                                                               'hashname' => '__STRING1__',
                                                                                               'description' => '\'[\'',
                                                                                               'lookahead' => 0,
                                                                                               'line' => -167
                                                                                             }, 'Parse::RecDescent::Literal' ),
                                                                                      bless( {
                                                                                               'subrule' => 'name',
                                                                                               'matchrule' => 0,
                                                                                               'implicit' => undef,
                                                                                               'argcode' => undef,
                                                                                               'lookahead' => 0,
                                                                                               'line' => -167
                                                                                             }, 'Parse::RecDescent::Subrule' ),
                                                                                      bless( {
                                                                                               'subrule' => 'types',
                                                                                               'expected' => undef,
                                                                                               'min' => 0,
                                                                                               'argcode' => undef,
                                                                                               'max' => 1,
                                                                                               'matchrule' => 0,
                                                                                               'repspec' => '?',
                                                                                               'lookahead' => 0,
                                                                                               'line' => -167
                                                                                             }, 'Parse::RecDescent::Repetition' ),
                                                                                      bless( {
                                                                                               'subrule' => 'topname',
                                                                                               'expected' => undef,
                                                                                               'min' => 0,
                                                                                               'argcode' => undef,
                                                                                               'max' => 1,
                                                                                               'matchrule' => 0,
                                                                                               'repspec' => '?',
                                                                                               'lookahead' => 0,
                                                                                               'line' => -167
                                                                                             }, 'Parse::RecDescent::Repetition' ),
                                                                                      bless( {
                                                                                               'subrule' => 'reify',
                                                                                               'expected' => undef,
                                                                                               'min' => 0,
                                                                                               'argcode' => undef,
                                                                                               'max' => 1,
                                                                                               'matchrule' => 0,
                                                                                               'repspec' => '?',
                                                                                               'lookahead' => 0,
                                                                                               'line' => -167
                                                                                             }, 'Parse::RecDescent::Repetition' ),
                                                                                      bless( {
                                                                                               'subrule' => 'subject',
                                                                                               'expected' => undef,
                                                                                               'min' => 0,
                                                                                               'argcode' => undef,
                                                                                               'max' => 1,
                                                                                               'matchrule' => 0,
                                                                                               'repspec' => '?',
                                                                                               'lookahead' => 0,
                                                                                               'line' => -167
                                                                                             }, 'Parse::RecDescent::Repetition' ),
                                                                                      bless( {
                                                                                               'subrule' => 'indicator',
                                                                                               'expected' => undef,
                                                                                               'min' => 0,
                                                                                               'argcode' => undef,
                                                                                               'max' => 100000000,
                                                                                               'matchrule' => 0,
                                                                                               'repspec' => 's?',
                                                                                               'lookahead' => 0,
                                                                                               'line' => -167
                                                                                             }, 'Parse::RecDescent::Repetition' ),
                                                                                      bless( {
                                                                                               'pattern' => ']',
                                                                                               'hashname' => '__STRING2__',
                                                                                               'description' => '\']\'',
                                                                                               'lookahead' => 0,
                                                                                               'line' => -167
                                                                                             }, 'Parse::RecDescent::Literal' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => -166,
                                                                                               'code' => '{
#warn "topic ".Dumper \\@item;
			  my $id = $store->internalize ($item[2] => $item[6]->[0]); # maybe there is a subject addr, maybe not

			  # add the subject indicators
			  map { $store->internalize ($id => $_ ) } @{$item[7]};


			  if ($item[3] and $item[3]->[0]) {
			      $store->assert ( map {
                                                       [ undef, 
							 undef, 
							 \'isa\', 
							 undef,
							 [ \'class\', \'instance\' ], 
							 [ $_,       $id ],
							 ] }  
						         @{$item[3]->[0]} );
			      map { $implicits->{\'isa-thing\'}->{$_}++ } @{$item[3]->[0]};   # the types and the ID are declared implicitely
			  }
#warn "item 4".Dumper $item[4];
			  if ($item[4] and @{$item[4]}) {
			      my $topnames = $item[4]->[0];
#warn "topnames ".Dumper $topnames;
			      my ($a) = $store->assert ( map {[ undef,                                            # LID
								   $topnames->{scope}->[0],                       # SCOPE
								   \'name\',                                        # TYPE
								   TM->NAME,                                      # KIND
								   [ \'thing\', \'value\' ],                          # ROLES
								   [ $id,     $_ ],                               # PLAYERS
								   undef ] }
							    @{$topnames->{names}}[0] );       # use the first for a name
			      $return = $a;
# TODO (2..3) for the variants

#warn "basename reify ".Dumper $item[5];
			      # reification of the basename
			      $store->internalize ($item[5]->[0], $a->[TM->LID]) if $item[5]->[0];

			      {
				  map { $implicits->{\'isa-scope\'}->{ $_ }++ } @{$topnames->{scope}};
			      }
			  }

			  $return = $id;
		      }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'xtopic',
                                                   'vars' => '',
                                                   'line' => -167
                                                 }, 'Parse::RecDescent::Rule' ),
                              'variable' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => '0',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 1,
                                                                           'actcount' => 0,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => '\\$\\w[\\w-]*',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/\\\\$\\\\w[\\\\w-]*/',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => -434,
                                                                                                 'mod' => '',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'variable',
                                                     'vars' => '',
                                                     'line' => -434
                                                   }, 'Parse::RecDescent::Rule' ),
                              'boolean' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [],
                                                    'changed' => 0,
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => '0',
                                                                          'strcount' => 1,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 0,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'pattern' => 'true',
                                                                                                'hashname' => '__STRING1__',
                                                                                                'description' => '\'true\'',
                                                                                                'lookahead' => 0,
                                                                                                'line' => -13
                                                                                              }, 'Parse::RecDescent::Literal' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' ),
                                                                 bless( {
                                                                          'number' => '1',
                                                                          'strcount' => 1,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 0,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'pattern' => 'false',
                                                                                                'hashname' => '__STRING1__',
                                                                                                'description' => '\'false\'',
                                                                                                'lookahead' => 0,
                                                                                                'line' => -13
                                                                                              }, 'Parse::RecDescent::Literal' )
                                                                                     ],
                                                                          'line' => -13
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'boolean',
                                                    'vars' => '',
                                                    'line' => -16
                                                  }, 'Parse::RecDescent::Rule' ),
                              'argument' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [
                                                                  'literal',
                                                                  'topic_ref'
                                                                ],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => '0',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'literal',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -389
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -389,
                                                                                                 'code' => '{  $return = $item[1]->[0]; # get only the string value
								      }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' ),
                                                                  bless( {
                                                                           'number' => '1',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'topic_ref',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -387
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -387,
                                                                                                 'code' => '{
                                                                         my $bu = $store->baseuri;
									 ($return = $item[1]) =~ s/^$bu//;  # pretend internal identifier
								      }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => -387
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'argument',
                                                     'vars' => '',
                                                     'line' => -389
                                                   }, 'Parse::RecDescent::Rule' ),
                              'occur' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [
                                                               'occ_topic',
                                                               'occ_type',
                                                               'resource',
                                                               'scope',
                                                               'reify'
                                                             ],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => '0',
                                                                        'strcount' => 4,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'pattern' => '{',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\'\\{\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -98
                                                                                            }, 'Parse::RecDescent::Literal' ),
                                                                                     bless( {
                                                                                              'subrule' => 'occ_topic',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => -98
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'pattern' => ',',
                                                                                              'hashname' => '__STRING2__',
                                                                                              'description' => '\',\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -98
                                                                                            }, 'Parse::RecDescent::Literal' ),
                                                                                     bless( {
                                                                                              'subrule' => 'occ_type',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => -98
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'pattern' => ',',
                                                                                              'hashname' => '__STRING3__',
                                                                                              'description' => '\',\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -98
                                                                                            }, 'Parse::RecDescent::Literal' ),
                                                                                     bless( {
                                                                                              'subrule' => 'resource',
                                                                                              'matchrule' => 0,
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => 0,
                                                                                              'line' => -98
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'pattern' => '}',
                                                                                              'hashname' => '__STRING4__',
                                                                                              'description' => '\'\\}\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -98
                                                                                            }, 'Parse::RecDescent::Literal' ),
                                                                                     bless( {
                                                                                              'subrule' => 'scope',
                                                                                              'expected' => undef,
                                                                                              'min' => 0,
                                                                                              'argcode' => undef,
                                                                                              'max' => 1,
                                                                                              'matchrule' => 0,
                                                                                              'repspec' => '?',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -98
                                                                                            }, 'Parse::RecDescent::Repetition' ),
                                                                                     bless( {
                                                                                              'subrule' => 'reify',
                                                                                              'expected' => undef,
                                                                                              'min' => 0,
                                                                                              'argcode' => undef,
                                                                                              'max' => 1,
                                                                                              'matchrule' => 0,
                                                                                              'repspec' => '?',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -98
                                                                                            }, 'Parse::RecDescent::Repetition' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -97,
                                                                                              'code' => '{
			  my $id = $store->internalize ($item[2]);
			  my ($a) = $store->assert ([ undef,                                         # LID
						      $item[8]->[0],                                 # SCOPE
						      $item[4],                                      # TYPE (MUST BE DEFINED!)
						      TM->OCC,                                       # KIND
						      [ \'thing\', \'value\' ],                          # ROLES
						      [ $id,     $item[6] ],                         # PLAYERS
						      undef ]);

			 { # memorize basename types and scopes as implicitely defined
			     $implicits->{\'isa-scope\'}-> { $item[8]->[0] }++ if $item[8]->[0];       # get the bloody scopes and tuck them away
			     $implicits->{\'subclasses\'}->{ \'occurrence\' }->{ $item[4] }++;
			 }

#warn "reify ".Dumper $item[9];
			  $store->internalize ($item[9]->[0], $a->[TM->LID]) if $item[9]->[0];

			  $return = $a;
		      }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'occur',
                                                  'vars' => '',
                                                  'line' => -98
                                                }, 'Parse::RecDescent::Rule' ),
                              'DATA' => bless( {
                                                 'impcount' => 0,
                                                 'calls' => [],
                                                 'changed' => 0,
                                                 'opcount' => 0,
                                                 'prods' => [
                                                              bless( {
                                                                       'number' => '0',
                                                                       'strcount' => 2,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 1,
                                                                       'actcount' => 1,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'pattern' => '[[',
                                                                                             'hashname' => '__STRING1__',
                                                                                             'description' => '\'[[\'',
                                                                                             'lookahead' => 0,
                                                                                             'line' => -66
                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                    bless( {
                                                                                             'pattern' => '.*(?=\\]\\])',
                                                                                             'hashname' => '__PATTERN1__',
                                                                                             'description' => '/.*(?=\\\\]\\\\])/sx',
                                                                                             'lookahead' => 0,
                                                                                             'rdelim' => '/',
                                                                                             'line' => -66,
                                                                                             'mod' => 'sx',
                                                                                             'ldelim' => '/'
                                                                                           }, 'Parse::RecDescent::Token' ),
                                                                                    bless( {
                                                                                             'pattern' => ']]',
                                                                                             'hashname' => '__STRING2__',
                                                                                             'description' => '\']]\'',
                                                                                             'lookahead' => 0,
                                                                                             'line' => -66
                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                    bless( {
                                                                                             'hashname' => '__ACTION1__',
                                                                                             'lookahead' => 0,
                                                                                             'line' => -66,
                                                                                             'code' => '{ $return = $item[2]; }'
                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'DATA',
                                                 'vars' => '',
                                                 'line' => -66
                                               }, 'Parse::RecDescent::Rule' ),
                              'association' => bless( {
                                                        'impcount' => 0,
                                                        'calls' => [
                                                                     'topic_identity',
                                                                     'roles',
                                                                     'scope',
                                                                     'reifier'
                                                                   ],
                                                        'changed' => 0,
                                                        'opcount' => 0,
                                                        'prods' => [
                                                                     bless( {
                                                                              'number' => '0',
                                                                              'strcount' => 2,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'subrule' => 'topic_identity',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => -380
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'pattern' => '(',
                                                                                                    'hashname' => '__STRING1__',
                                                                                                    'description' => '\'(\'',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => -380
                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'roles',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => -380
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'pattern' => ')',
                                                                                                    'hashname' => '__STRING2__',
                                                                                                    'description' => '\')\'',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => -380
                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'scope',
                                                                                                    'expected' => undef,
                                                                                                    'min' => 0,
                                                                                                    'argcode' => undef,
                                                                                                    'max' => 1,
                                                                                                    'matchrule' => 0,
                                                                                                    'repspec' => '?',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => -380
                                                                                                  }, 'Parse::RecDescent::Repetition' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'reifier',
                                                                                                    'expected' => undef,
                                                                                                    'min' => 0,
                                                                                                    'argcode' => undef,
                                                                                                    'max' => 1,
                                                                                                    'matchrule' => 0,
                                                                                                    'repspec' => '?',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => -380
                                                                                                  }, 'Parse::RecDescent::Repetition' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => -379,
                                                                                                    'code' => '{
									  my $scope = $item[5]->[0] ? $item[5]->[0] : \'us\';
									  my ($a) = $store->assert (bless [ undef,     # LID
												      $scope,          # SCOPE
												      $item[1],        # TYPE
												      TM->ASSOC,       # KIND
												      [ map { $_->[0] } @{$item[3]} ], # ROLES
												      [ map { $_->[1] } @{$item[3]} ], # PLAYERS
												      undef ], \'Assertion\');
									  $return = $a;
									  $store->assert(Assertion->new(kind    => TM->ASSOC,
													type    => \'isa\',
													roles   => [ qw(instance class) ],
													players => [ $scope, \'scope\' ],
													scope   => undef)) if $scope ne \'us\';
									  $store->internalize ($item[6]->[0], $a->[TM->LID]) if $item[6]->[0];
									  $return;
								      }'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'name' => 'association',
                                                        'vars' => '',
                                                        'line' => -382
                                                      }, 'Parse::RecDescent::Rule' ),
                              'version' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [],
                                                    'changed' => 0,
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => '0',
                                                                          'strcount' => 1,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 0,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'pattern' => 'TODO',
                                                                                                'hashname' => '__STRING1__',
                                                                                                'description' => '\'TODO\'',
                                                                                                'lookahead' => 0,
                                                                                                'line' => -451
                                                                                              }, 'Parse::RecDescent::Literal' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'version',
                                                    'vars' => '',
                                                    'line' => -453
                                                  }, 'Parse::RecDescent::Rule' ),
                              'wuri' => bless( {
                                                 'impcount' => 0,
                                                 'calls' => [
                                                              'iri'
                                                            ],
                                                 'changed' => 0,
                                                 'opcount' => 0,
                                                 'prods' => [
                                                              bless( {
                                                                       'number' => '0',
                                                                       'strcount' => 2,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 0,
                                                                       'actcount' => 1,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'pattern' => '<',
                                                                                             'hashname' => '__STRING1__',
                                                                                             'description' => '\'<\'',
                                                                                             'lookahead' => 0,
                                                                                             'line' => -11
                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                    bless( {
                                                                                             'subrule' => 'iri',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => -11
                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                    bless( {
                                                                                             'pattern' => '>',
                                                                                             'hashname' => '__STRING2__',
                                                                                             'description' => '\'>\'',
                                                                                             'lookahead' => 0,
                                                                                             'line' => -11
                                                                                           }, 'Parse::RecDescent::Literal' ),
                                                                                    bless( {
                                                                                             'hashname' => '__ACTION1__',
                                                                                             'lookahead' => 0,
                                                                                             'line' => -11,
                                                                                             'code' => '{ $item[2] }'
                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'wuri',
                                                 'vars' => '',
                                                 'line' => -11
                                               }, 'Parse::RecDescent::Rule' ),
                              'occ_type' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [
                                                                  'name'
                                                                ],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => '0',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 0,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'name',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -74
                                                                                               }, 'Parse::RecDescent::Subrule' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'occ_type',
                                                     'vars' => '',
                                                     'line' => -74
                                                   }, 'Parse::RecDescent::Rule' ),
                              'resource' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [
                                                                  'uri',
                                                                  'DATA'
                                                                ],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => '0',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'uri',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -70
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -70,
                                                                                                 'code' => '{ $return = new TM::Literal ($item[1], \'xsd:uri\') }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' ),
                                                                  bless( {
                                                                           'number' => '1',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'DATA',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -68
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -68,
                                                                                                 'code' => '{ $return = new TM::Literal ($item[1], \'xsd:string\') }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => -69
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'resource',
                                                     'vars' => '',
                                                     'line' => -70
                                                   }, 'Parse::RecDescent::Rule' ),
                              'occurrence' => bless( {
                                                       'impcount' => 0,
                                                       'calls' => [
                                                                    'type',
                                                                    'iri_literal',
                                                                    'scope',
                                                                    'reifier'
                                                                  ],
                                                       'changed' => 0,
                                                       'opcount' => 0,
                                                       'prods' => [
                                                                    bless( {
                                                                             'number' => '0',
                                                                             'strcount' => 1,
                                                                             'dircount' => 0,
                                                                             'uncommit' => undef,
                                                                             'error' => undef,
                                                                             'patcount' => 0,
                                                                             'actcount' => 1,
                                                                             'items' => [
                                                                                          bless( {
                                                                                                   'subrule' => 'type',
                                                                                                   'matchrule' => 0,
                                                                                                   'implicit' => undef,
                                                                                                   'argcode' => undef,
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => -264
                                                                                                 }, 'Parse::RecDescent::Subrule' ),
                                                                                          bless( {
                                                                                                   'pattern' => ':',
                                                                                                   'hashname' => '__STRING1__',
                                                                                                   'description' => '\':\'',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => -264
                                                                                                 }, 'Parse::RecDescent::Literal' ),
                                                                                          bless( {
                                                                                                   'subrule' => 'iri_literal',
                                                                                                   'matchrule' => 0,
                                                                                                   'implicit' => undef,
                                                                                                   'argcode' => undef,
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => -264
                                                                                                 }, 'Parse::RecDescent::Subrule' ),
                                                                                          bless( {
                                                                                                   'subrule' => 'scope',
                                                                                                   'expected' => undef,
                                                                                                   'min' => 0,
                                                                                                   'argcode' => undef,
                                                                                                   'max' => 1,
                                                                                                   'matchrule' => 0,
                                                                                                   'repspec' => '?',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => -264
                                                                                                 }, 'Parse::RecDescent::Repetition' ),
                                                                                          bless( {
                                                                                                   'subrule' => 'reifier',
                                                                                                   'expected' => undef,
                                                                                                   'min' => 0,
                                                                                                   'argcode' => undef,
                                                                                                   'max' => 1,
                                                                                                   'matchrule' => 0,
                                                                                                   'repspec' => '?',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => -264
                                                                                                 }, 'Parse::RecDescent::Repetition' ),
                                                                                          bless( {
                                                                                                   'hashname' => '__ACTION1__',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => -263,
                                                                                                   'code' => '{
									  my $type  = $item[1];
									  my $scope = $item[4]->[0] ? $item[4]->[0] : \'us\';

									  my ($a) = $store->assert ( bless [ undef,          # LID
												       $scope,               # SCOPE
												       $type,                # TYPE
												       TM->OCC,              # KIND
												       [ \'thing\', \'value\' ], # ROLES
												       [ $arg[0], $item[3] ],# PLAYERS
												       undef ], \'Assertion\' );
									  $store->assert(Assertion->new(kind    => TM->ASSOC,
													type    => \'is-subclass-of\',
													roles   => [ qw(subclass superclass) ],
													players => [ $type, \'occurrence\' ],
													scope   => undef)) if $type ne \'occurrence\';
									  $store->assert(Assertion->new(kind    => TM->ASSOC,
													type    => \'isa\',
													roles   => [ qw(instance class) ],
													players => [ $scope, \'scope\' ],
													scope   => undef)) if $scope ne \'us\';
									  $store->internalize ($item[5]->[0], $a->[TM->LID]) if $item[5]->[0];
									  $return = $a;
								      }'
                                                                                                 }, 'Parse::RecDescent::Action' )
                                                                                        ],
                                                                             'line' => undef
                                                                           }, 'Parse::RecDescent::Production' )
                                                                  ],
                                                       'name' => 'occurrence',
                                                       'vars' => '',
                                                       'line' => -264
                                                     }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_string' => bless( {
                                                                                          'impcount' => 0,
                                                                                          'calls' => [
                                                                                                       'iri'
                                                                                                     ],
                                                                                          'changed' => 0,
                                                                                          'opcount' => 0,
                                                                                          'prods' => [
                                                                                                       bless( {
                                                                                                                'number' => '0',
                                                                                                                'strcount' => 1,
                                                                                                                'dircount' => 0,
                                                                                                                'uncommit' => undef,
                                                                                                                'error' => undef,
                                                                                                                'patcount' => 0,
                                                                                                                'actcount' => 0,
                                                                                                                'items' => [
                                                                                                                             bless( {
                                                                                                                                      'pattern' => '^^',
                                                                                                                                      'hashname' => '__STRING1__',
                                                                                                                                      'description' => '\'^^\'',
                                                                                                                                      'lookahead' => 0,
                                                                                                                                      'line' => 1
                                                                                                                                    }, 'Parse::RecDescent::Literal' ),
                                                                                                                             bless( {
                                                                                                                                      'subrule' => 'iri',
                                                                                                                                      'matchrule' => 0,
                                                                                                                                      'implicit' => undef,
                                                                                                                                      'argcode' => undef,
                                                                                                                                      'lookahead' => 0,
                                                                                                                                      'line' => 1
                                                                                                                                    }, 'Parse::RecDescent::Subrule' )
                                                                                                                           ],
                                                                                                                'line' => undef
                                                                                                              }, 'Parse::RecDescent::Production' )
                                                                                                     ],
                                                                                          'name' => '_alternation_1_of_production_1_of_rule_string',
                                                                                          'vars' => '',
                                                                                          'line' => 1
                                                                                        }, 'Parse::RecDescent::Rule' ),
                              'version_directive' => bless( {
                                                              'impcount' => 0,
                                                              'calls' => [
                                                                           'string'
                                                                         ],
                                                              'changed' => 0,
                                                              'opcount' => 0,
                                                              'prods' => [
                                                                           bless( {
                                                                                    'number' => '0',
                                                                                    'strcount' => 1,
                                                                                    'dircount' => 0,
                                                                                    'uncommit' => undef,
                                                                                    'error' => undef,
                                                                                    'patcount' => 0,
                                                                                    'actcount' => 1,
                                                                                    'items' => [
                                                                                                 bless( {
                                                                                                          'pattern' => '#VERSION',
                                                                                                          'hashname' => '__STRING1__',
                                                                                                          'description' => '\'#VERSION\'',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => -203
                                                                                                        }, 'Parse::RecDescent::Literal' ),
                                                                                                 bless( {
                                                                                                          'subrule' => 'string',
                                                                                                          'matchrule' => 0,
                                                                                                          'implicit' => undef,
                                                                                                          'argcode' => undef,
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => -203
                                                                                                        }, 'Parse::RecDescent::Subrule' ),
                                                                                                 bless( {
                                                                                                          'hashname' => '__ACTION1__',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => -202,
                                                                                                          'code' => '{
			  my $version = $item[2];
			  $log->logdie (__PACKAGE__ . ": VERSION not supported \'$version\'") unless $version =~ /^1\\.[23]$/;
		      }'
                                                                                                        }, 'Parse::RecDescent::Action' )
                                                                                               ],
                                                                                    'line' => undef
                                                                                  }, 'Parse::RecDescent::Production' )
                                                                         ],
                                                              'name' => 'version_directive',
                                                              'vars' => '',
                                                              'line' => -205
                                                            }, 'Parse::RecDescent::Rule' ),
                              'indicator' => bless( {
                                                      'impcount' => 0,
                                                      'calls' => [
                                                                   'uri'
                                                                 ],
                                                      'changed' => 0,
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'number' => '0',
                                                                            'strcount' => 1,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'pattern' => '@',
                                                                                                  'hashname' => '__STRING1__',
                                                                                                  'description' => '\'@\'',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => -115
                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'uri',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => -115
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => -115,
                                                                                                  'code' => '{ $return = \\ $item[2]; }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'indicator',
                                                      'vars' => '',
                                                      'line' => -117
                                                    }, 'Parse::RecDescent::Rule' ),
                              'qname' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => '0',
                                                                        'strcount' => 0,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 1,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'pattern' => '(\\w[\\w-]+):(\\w[\\w-]+)',
                                                                                              'hashname' => '__PATTERN1__',
                                                                                              'description' => '/(\\\\w[\\\\w-]+):(\\\\w[\\\\w-]+)/',
                                                                                              'lookahead' => 0,
                                                                                              'rdelim' => '/',
                                                                                              'line' => -315,
                                                                                              'mod' => '',
                                                                                              'ldelim' => '/'
                                                                                            }, 'Parse::RecDescent::Token' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -315,
                                                                                              'code' => '{
  #                               ^^^^^^^^^^ ^^^^^^^^^^
  #                               identifier:identifier , but wo blanks
                                                                         die "undefined prefix \'$item[1]\'" unless $prefixes{$1};
									 $return = $prefixes{$1}.$2;
								       }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'qname',
                                                  'vars' => '',
                                                  'line' => -315
                                                }, 'Parse::RecDescent::Rule' ),
                              'decimal' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [],
                                                    'changed' => 0,
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => '0',
                                                                          'strcount' => 0,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 1,
                                                                          'actcount' => 0,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'pattern' => '-?\\d+\\.\\d+',
                                                                                                'hashname' => '__PATTERN1__',
                                                                                                'description' => '/-?\\\\d+\\\\.\\\\d+/',
                                                                                                'lookahead' => 0,
                                                                                                'rdelim' => '/',
                                                                                                'line' => -27,
                                                                                                'mod' => '',
                                                                                                'ldelim' => '/'
                                                                                              }, 'Parse::RecDescent::Token' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'decimal',
                                                    'vars' => '',
                                                    'line' => -27
                                                  }, 'Parse::RecDescent::Rule' ),
                              'basesortdispname' => bless( {
                                                             'impcount' => 0,
                                                             'calls' => [
                                                                          'basename'
                                                                        ],
                                                             'changed' => 0,
                                                             'opcount' => 0,
                                                             'prods' => [
                                                                          bless( {
                                                                                   'number' => '0',
                                                                                   'strcount' => 1,
                                                                                   'dircount' => 1,
                                                                                   'uncommit' => undef,
                                                                                   'error' => undef,
                                                                                   'patcount' => 0,
                                                                                   'actcount' => 0,
                                                                                   'op' => [],
                                                                                   'items' => [
                                                                                                bless( {
                                                                                                         'expected' => '<leftop: basename \';\' basename>',
                                                                                                         'min' => 1,
                                                                                                         'name' => '',
                                                                                                         'max' => 100000000,
                                                                                                         'leftarg' => bless( {
                                                                                                                               'subrule' => 'basename',
                                                                                                                               'matchrule' => 0,
                                                                                                                               'implicit' => undef,
                                                                                                                               'argcode' => undef,
                                                                                                                               'lookahead' => 0,
                                                                                                                               'line' => -104
                                                                                                                             }, 'Parse::RecDescent::Subrule' ),
                                                                                                         'rightarg' => bless( {
                                                                                                                                'subrule' => 'basename',
                                                                                                                                'matchrule' => 0,
                                                                                                                                'implicit' => undef,
                                                                                                                                'argcode' => undef,
                                                                                                                                'lookahead' => 0,
                                                                                                                                'line' => -104
                                                                                                                              }, 'Parse::RecDescent::Subrule' ),
                                                                                                         'hashname' => '__DIRECTIVE1__',
                                                                                                         'type' => 'leftop',
                                                                                                         'op' => bless( {
                                                                                                                          'pattern' => ';',
                                                                                                                          'hashname' => '__STRING1__',
                                                                                                                          'description' => '\';\'',
                                                                                                                          'lookahead' => 0,
                                                                                                                          'line' => -104
                                                                                                                        }, 'Parse::RecDescent::Literal' )
                                                                                                       }, 'Parse::RecDescent::Operator' )
                                                                                              ],
                                                                                   'line' => undef
                                                                                 }, 'Parse::RecDescent::Production' )
                                                                        ],
                                                             'name' => 'basesortdispname',
                                                             'vars' => '',
                                                             'line' => -104
                                                           }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_include_directive' => bless( {
                                                                                                     'impcount' => 0,
                                                                                                     'calls' => [
                                                                                                                  'iri'
                                                                                                                ],
                                                                                                     'changed' => 0,
                                                                                                     'opcount' => 0,
                                                                                                     'prods' => [
                                                                                                                  bless( {
                                                                                                                           'number' => '0',
                                                                                                                           'strcount' => 0,
                                                                                                                           'dircount' => 0,
                                                                                                                           'uncommit' => undef,
                                                                                                                           'error' => undef,
                                                                                                                           'patcount' => 1,
                                                                                                                           'actcount' => 0,
                                                                                                                           'items' => [
                                                                                                                                        bless( {
                                                                                                                                                 'pattern' => '^inline:.*?\\n',
                                                                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                                                                 'description' => '/^inline:.*?\\\\n/',
                                                                                                                                                 'lookahead' => 0,
                                                                                                                                                 'rdelim' => '/',
                                                                                                                                                 'line' => 1,
                                                                                                                                                 'mod' => '',
                                                                                                                                                 'ldelim' => '/'
                                                                                                                                               }, 'Parse::RecDescent::Token' )
                                                                                                                                      ],
                                                                                                                           'line' => undef
                                                                                                                         }, 'Parse::RecDescent::Production' ),
                                                                                                                  bless( {
                                                                                                                           'number' => '1',
                                                                                                                           'strcount' => 0,
                                                                                                                           'dircount' => 0,
                                                                                                                           'uncommit' => undef,
                                                                                                                           'error' => undef,
                                                                                                                           'patcount' => 0,
                                                                                                                           'actcount' => 0,
                                                                                                                           'items' => [
                                                                                                                                        bless( {
                                                                                                                                                 'subrule' => 'iri',
                                                                                                                                                 'matchrule' => 0,
                                                                                                                                                 'implicit' => undef,
                                                                                                                                                 'argcode' => undef,
                                                                                                                                                 'lookahead' => 0,
                                                                                                                                                 'line' => 1
                                                                                                                                               }, 'Parse::RecDescent::Subrule' )
                                                                                                                                      ],
                                                                                                                           'line' => 1
                                                                                                                         }, 'Parse::RecDescent::Production' )
                                                                                                                ],
                                                                                                     'name' => '_alternation_1_of_production_1_of_rule_include_directive',
                                                                                                     'vars' => '',
                                                                                                     'line' => 1
                                                                                                   }, 'Parse::RecDescent::Rule' ),
                              'anonymous_wildcard' => bless( {
                                                               'impcount' => 0,
                                                               'calls' => [],
                                                               'changed' => 0,
                                                               'opcount' => 0,
                                                               'prods' => [
                                                                            bless( {
                                                                                     'number' => '0',
                                                                                     'strcount' => 1,
                                                                                     'dircount' => 0,
                                                                                     'uncommit' => undef,
                                                                                     'error' => undef,
                                                                                     'patcount' => 0,
                                                                                     'actcount' => 1,
                                                                                     'items' => [
                                                                                                  bless( {
                                                                                                           'pattern' => '?',
                                                                                                           'hashname' => '__STRING1__',
                                                                                                           'description' => '\'?\'',
                                                                                                           'lookahead' => 0,
                                                                                                           'line' => -339
                                                                                                         }, 'Parse::RecDescent::Literal' ),
                                                                                                  bless( {
                                                                                                           'hashname' => '__ACTION1__',
                                                                                                           'lookahead' => 0,
                                                                                                           'line' => -339,
                                                                                                           'code' => '{ $return = $store->internalize (sprintf "uuid-%010d", $TM::toplet_ctr++); }'
                                                                                                         }, 'Parse::RecDescent::Action' )
                                                                                                ],
                                                                                     'line' => undef
                                                                                   }, 'Parse::RecDescent::Production' )
                                                                          ],
                                                               'name' => 'anonymous_wildcard',
                                                               'vars' => '',
                                                               'line' => -339
                                                             }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_topic_tail' => bless( {
                                                                                              'impcount' => 0,
                                                                                              'calls' => [
                                                                                                           'instance_of',
                                                                                                           'kind_of',
                                                                                                           'topic_template_invocation',
                                                                                                           'subject_identifier',
                                                                                                           'subject_locator',
                                                                                                           'assignment'
                                                                                                         ],
                                                                                              'changed' => 0,
                                                                                              'opcount' => 0,
                                                                                              'prods' => [
                                                                                                           bless( {
                                                                                                                    'number' => '0',
                                                                                                                    'strcount' => 0,
                                                                                                                    'dircount' => 0,
                                                                                                                    'uncommit' => undef,
                                                                                                                    'error' => undef,
                                                                                                                    'patcount' => 0,
                                                                                                                    'actcount' => 0,
                                                                                                                    'items' => [
                                                                                                                                 bless( {
                                                                                                                                          'subrule' => 'instance_of',
                                                                                                                                          'matchrule' => 0,
                                                                                                                                          'implicit' => undef,
                                                                                                                                          'argcode' => '[$arg[0]]',
                                                                                                                                          'lookahead' => 0,
                                                                                                                                          'line' => 1
                                                                                                                                        }, 'Parse::RecDescent::Subrule' )
                                                                                                                               ],
                                                                                                                    'line' => undef
                                                                                                                  }, 'Parse::RecDescent::Production' ),
                                                                                                           bless( {
                                                                                                                    'number' => '1',
                                                                                                                    'strcount' => 0,
                                                                                                                    'dircount' => 0,
                                                                                                                    'uncommit' => undef,
                                                                                                                    'error' => undef,
                                                                                                                    'patcount' => 0,
                                                                                                                    'actcount' => 0,
                                                                                                                    'items' => [
                                                                                                                                 bless( {
                                                                                                                                          'subrule' => 'kind_of',
                                                                                                                                          'matchrule' => 0,
                                                                                                                                          'implicit' => undef,
                                                                                                                                          'argcode' => '[$arg[0]]',
                                                                                                                                          'lookahead' => 0,
                                                                                                                                          'line' => 2
                                                                                                                                        }, 'Parse::RecDescent::Subrule' )
                                                                                                                               ],
                                                                                                                    'line' => 2
                                                                                                                  }, 'Parse::RecDescent::Production' ),
                                                                                                           bless( {
                                                                                                                    'number' => '2',
                                                                                                                    'strcount' => 0,
                                                                                                                    'dircount' => 0,
                                                                                                                    'uncommit' => undef,
                                                                                                                    'error' => undef,
                                                                                                                    'patcount' => 0,
                                                                                                                    'actcount' => 0,
                                                                                                                    'items' => [
                                                                                                                                 bless( {
                                                                                                                                          'subrule' => 'topic_template_invocation',
                                                                                                                                          'matchrule' => 0,
                                                                                                                                          'implicit' => undef,
                                                                                                                                          'argcode' => '[$arg[0]]',
                                                                                                                                          'lookahead' => 0,
                                                                                                                                          'line' => 3
                                                                                                                                        }, 'Parse::RecDescent::Subrule' )
                                                                                                                               ],
                                                                                                                    'line' => 3
                                                                                                                  }, 'Parse::RecDescent::Production' ),
                                                                                                           bless( {
                                                                                                                    'number' => '3',
                                                                                                                    'strcount' => 0,
                                                                                                                    'dircount' => 0,
                                                                                                                    'uncommit' => undef,
                                                                                                                    'error' => undef,
                                                                                                                    'patcount' => 0,
                                                                                                                    'actcount' => 2,
                                                                                                                    'items' => [
                                                                                                                                 bless( {
                                                                                                                                          'subrule' => 'subject_identifier',
                                                                                                                                          'matchrule' => 0,
                                                                                                                                          'implicit' => undef,
                                                                                                                                          'argcode' => undef,
                                                                                                                                          'lookahead' => 0,
                                                                                                                                          'line' => 5
                                                                                                                                        }, 'Parse::RecDescent::Subrule' ),
                                                                                                                                 bless( {
                                                                                                                                          'hashname' => '__ACTION1__',
                                                                                                                                          'lookahead' => 0,
                                                                                                                                          'line' => 5,
                                                                                                                                          'code' => '{ $return = undef if $text =~ /^\\s*:/s }'
                                                                                                                                        }, 'Parse::RecDescent::Action' ),
                                                                                                                                 bless( {
                                                                                                                                          'hashname' => '__ACTION2__',
                                                                                                                                          'lookahead' => 0,
                                                                                                                                          'line' => 5,
                                                                                                                                          'code' => '{ $store->internalize ($arg[0], $item[1]); }'
                                                                                                                                        }, 'Parse::RecDescent::Action' )
                                                                                                                               ],
                                                                                                                    'line' => 4
                                                                                                                  }, 'Parse::RecDescent::Production' ),
                                                                                                           bless( {
                                                                                                                    'number' => '4',
                                                                                                                    'strcount' => 0,
                                                                                                                    'dircount' => 0,
                                                                                                                    'uncommit' => undef,
                                                                                                                    'error' => undef,
                                                                                                                    'patcount' => 0,
                                                                                                                    'actcount' => 2,
                                                                                                                    'items' => [
                                                                                                                                 bless( {
                                                                                                                                          'subrule' => 'subject_locator',
                                                                                                                                          'matchrule' => 0,
                                                                                                                                          'implicit' => undef,
                                                                                                                                          'argcode' => undef,
                                                                                                                                          'lookahead' => 0,
                                                                                                                                          'line' => 7
                                                                                                                                        }, 'Parse::RecDescent::Subrule' ),
                                                                                                                                 bless( {
                                                                                                                                          'hashname' => '__ACTION1__',
                                                                                                                                          'lookahead' => 0,
                                                                                                                                          'line' => 7,
                                                                                                                                          'code' => '{ $return = undef if $text =~ /^\\s*:/s }'
                                                                                                                                        }, 'Parse::RecDescent::Action' ),
                                                                                                                                 bless( {
                                                                                                                                          'hashname' => '__ACTION2__',
                                                                                                                                          'lookahead' => 0,
                                                                                                                                          'line' => 8,
                                                                                                                                          'code' => '{ $store->internalize ($arg[0], $item[1]); }'
                                                                                                                                        }, 'Parse::RecDescent::Action' )
                                                                                                                               ],
                                                                                                                    'line' => 7
                                                                                                                  }, 'Parse::RecDescent::Production' ),
                                                                                                           bless( {
                                                                                                                    'number' => '5',
                                                                                                                    'strcount' => 0,
                                                                                                                    'dircount' => 0,
                                                                                                                    'uncommit' => undef,
                                                                                                                    'error' => undef,
                                                                                                                    'patcount' => 0,
                                                                                                                    'actcount' => 0,
                                                                                                                    'items' => [
                                                                                                                                 bless( {
                                                                                                                                          'subrule' => 'assignment',
                                                                                                                                          'matchrule' => 0,
                                                                                                                                          'implicit' => undef,
                                                                                                                                          'argcode' => '[$arg[0]]',
                                                                                                                                          'lookahead' => 0,
                                                                                                                                          'line' => 10
                                                                                                                                        }, 'Parse::RecDescent::Subrule' )
                                                                                                                               ],
                                                                                                                    'line' => 9
                                                                                                                  }, 'Parse::RecDescent::Production' )
                                                                                                         ],
                                                                                              'name' => '_alternation_1_of_production_1_of_rule_topic_tail',
                                                                                              'vars' => '',
                                                                                              'line' => 1
                                                                                            }, 'Parse::RecDescent::Rule' ),
                              'literal' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [
                                                                 'decimal',
                                                                 'integer',
                                                                 'boolean',
                                                                 'wuri',
                                                                 'string'
                                                               ],
                                                    'changed' => 0,
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => '0',
                                                                          'strcount' => 0,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'subrule' => 'decimal',
                                                                                                'matchrule' => 0,
                                                                                                'implicit' => undef,
                                                                                                'argcode' => undef,
                                                                                                'lookahead' => 0,
                                                                                                'line' => -36
                                                                                              }, 'Parse::RecDescent::Subrule' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => -36,
                                                                                                'code' => '{ $return = new TM::Literal  ($item[1], TM::Literal->DECIMAL); }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' ),
                                                                 bless( {
                                                                          'number' => '1',
                                                                          'strcount' => 0,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'subrule' => 'integer',
                                                                                                'matchrule' => 0,
                                                                                                'implicit' => undef,
                                                                                                'argcode' => undef,
                                                                                                'lookahead' => 0,
                                                                                                'line' => -35
                                                                                              }, 'Parse::RecDescent::Subrule' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => -35,
                                                                                                'code' => '{ $return = new TM::Literal  ($item[1], TM::Literal->INTEGER); }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => -35
                                                                        }, 'Parse::RecDescent::Production' ),
                                                                 bless( {
                                                                          'number' => '2',
                                                                          'strcount' => 0,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'subrule' => 'boolean',
                                                                                                'matchrule' => 0,
                                                                                                'implicit' => undef,
                                                                                                'argcode' => undef,
                                                                                                'lookahead' => 0,
                                                                                                'line' => -34
                                                                                              }, 'Parse::RecDescent::Subrule' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => -34,
                                                                                                'code' => '{ $return = new TM::Literal  ($item[1], TM::Literal->BOOLEAN); }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => -34
                                                                        }, 'Parse::RecDescent::Production' ),
                                                                 bless( {
                                                                          'number' => '3',
                                                                          'strcount' => 0,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'subrule' => 'wuri',
                                                                                                'matchrule' => 0,
                                                                                                'implicit' => undef,
                                                                                                'argcode' => undef,
                                                                                                'lookahead' => 0,
                                                                                                'line' => -33
                                                                                              }, 'Parse::RecDescent::Subrule' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => -33,
                                                                                                'code' => '{ $return = new TM::Literal  ($item[1], TM::Literal->URI); }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => -33
                                                                        }, 'Parse::RecDescent::Production' ),
                                                                 bless( {
                                                                          'number' => '4',
                                                                          'strcount' => 0,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 0,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'subrule' => 'string',
                                                                                                'matchrule' => 0,
                                                                                                'implicit' => undef,
                                                                                                'argcode' => undef,
                                                                                                'lookahead' => 0,
                                                                                                'line' => -32
                                                                                              }, 'Parse::RecDescent::Subrule' )
                                                                                     ],
                                                                          'line' => -32
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'literal',
                                                    'vars' => '',
                                                    'line' => -36
                                                  }, 'Parse::RecDescent::Rule' ),
                              'prefix_directive' => bless( {
                                                             'impcount' => 0,
                                                             'calls' => [
                                                                          'identifier',
                                                                          'reference'
                                                                        ],
                                                             'changed' => 0,
                                                             'opcount' => 0,
                                                             'prods' => [
                                                                          bless( {
                                                                                   'number' => '0',
                                                                                   'strcount' => 1,
                                                                                   'dircount' => 0,
                                                                                   'uncommit' => undef,
                                                                                   'error' => undef,
                                                                                   'patcount' => 0,
                                                                                   'actcount' => 1,
                                                                                   'items' => [
                                                                                                bless( {
                                                                                                         'pattern' => '%prefix',
                                                                                                         'hashname' => '__STRING1__',
                                                                                                         'description' => '\'%prefix\'',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => -475
                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                bless( {
                                                                                                         'subrule' => 'identifier',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => undef,
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => -475
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'subrule' => 'reference',
                                                                                                         'matchrule' => 0,
                                                                                                         'implicit' => undef,
                                                                                                         'argcode' => undef,
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => -475
                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                bless( {
                                                                                                         'hashname' => '__ACTION1__',
                                                                                                         'lookahead' => 0,
                                                                                                         'line' => -475,
                                                                                                         'code' => '{
                                                                         my $uri = $item[3];
									 $prefixes{$item[2]} = $uri;
								      }'
                                                                                                       }, 'Parse::RecDescent::Action' )
                                                                                              ],
                                                                                   'line' => undef
                                                                                 }, 'Parse::RecDescent::Production' )
                                                                        ],
                                                             'name' => 'prefix_directive',
                                                             'vars' => '',
                                                             'line' => -475
                                                           }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_topicmapid_directive' => bless( {
                                                                                                        'impcount' => 0,
                                                                                                        'calls' => [
                                                                                                                     'name',
                                                                                                                     'reify'
                                                                                                                   ],
                                                                                                        'changed' => 0,
                                                                                                        'opcount' => 0,
                                                                                                        'prods' => [
                                                                                                                     bless( {
                                                                                                                              'number' => '0',
                                                                                                                              'strcount' => 0,
                                                                                                                              'dircount' => 0,
                                                                                                                              'uncommit' => undef,
                                                                                                                              'error' => undef,
                                                                                                                              'patcount' => 0,
                                                                                                                              'actcount' => 0,
                                                                                                                              'items' => [
                                                                                                                                           bless( {
                                                                                                                                                    'subrule' => 'name',
                                                                                                                                                    'matchrule' => 0,
                                                                                                                                                    'implicit' => undef,
                                                                                                                                                    'argcode' => undef,
                                                                                                                                                    'lookahead' => 0,
                                                                                                                                                    'line' => 1
                                                                                                                                                  }, 'Parse::RecDescent::Subrule' )
                                                                                                                                         ],
                                                                                                                              'line' => undef
                                                                                                                            }, 'Parse::RecDescent::Production' ),
                                                                                                                     bless( {
                                                                                                                              'number' => '1',
                                                                                                                              'strcount' => 0,
                                                                                                                              'dircount' => 0,
                                                                                                                              'uncommit' => undef,
                                                                                                                              'error' => undef,
                                                                                                                              'patcount' => 0,
                                                                                                                              'actcount' => 0,
                                                                                                                              'items' => [
                                                                                                                                           bless( {
                                                                                                                                                    'subrule' => 'reify',
                                                                                                                                                    'matchrule' => 0,
                                                                                                                                                    'implicit' => undef,
                                                                                                                                                    'argcode' => undef,
                                                                                                                                                    'lookahead' => 0,
                                                                                                                                                    'line' => 1
                                                                                                                                                  }, 'Parse::RecDescent::Subrule' )
                                                                                                                                         ],
                                                                                                                              'line' => 1
                                                                                                                            }, 'Parse::RecDescent::Production' )
                                                                                                                   ],
                                                                                                        'name' => '_alternation_1_of_production_1_of_rule_topicmapid_directive',
                                                                                                        'vars' => '',
                                                                                                        'line' => 1
                                                                                                      }, 'Parse::RecDescent::Rule' ),
                              'identifier' => bless( {
                                                       'impcount' => 0,
                                                       'calls' => [],
                                                       'changed' => 0,
                                                       'opcount' => 0,
                                                       'prods' => [
                                                                    bless( {
                                                                             'number' => '0',
                                                                             'strcount' => 0,
                                                                             'dircount' => 0,
                                                                             'uncommit' => undef,
                                                                             'error' => undef,
                                                                             'patcount' => 1,
                                                                             'actcount' => 0,
                                                                             'items' => [
                                                                                          bless( {
                                                                                                   'pattern' => '\\w[\\w-]*',
                                                                                                   'hashname' => '__PATTERN1__',
                                                                                                   'description' => '/\\\\w[\\\\w-]*/',
                                                                                                   'lookahead' => 0,
                                                                                                   'rdelim' => '/',
                                                                                                   'line' => -330,
                                                                                                   'mod' => '',
                                                                                                   'ldelim' => '/'
                                                                                                 }, 'Parse::RecDescent::Token' )
                                                                                        ],
                                                                             'line' => undef
                                                                           }, 'Parse::RecDescent::Production' )
                                                                  ],
                                                       'name' => 'identifier',
                                                       'vars' => '',
                                                       'line' => -330
                                                     }, 'Parse::RecDescent::Rule' ),
                              'kind_of' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [
                                                                 'topic_ref'
                                                               ],
                                                    'changed' => 0,
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => '0',
                                                                          'strcount' => 1,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'pattern' => 'ako',
                                                                                                'hashname' => '__STRING1__',
                                                                                                'description' => '\'ako\'',
                                                                                                'lookahead' => 0,
                                                                                                'line' => -218
                                                                                              }, 'Parse::RecDescent::Literal' ),
                                                                                       bless( {
                                                                                                'subrule' => 'topic_ref',
                                                                                                'matchrule' => 0,
                                                                                                'implicit' => undef,
                                                                                                'argcode' => undef,
                                                                                                'lookahead' => 0,
                                                                                                'line' => -218
                                                                                              }, 'Parse::RecDescent::Subrule' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => -218,
                                                                                                'code' => '{  $store->assert ( [ undef, 
											   undef, 
											   \'is-subclass-of\', 
											   undef,
											   [ qw(subclass superclass) ], 
											   [ $arg[0], $item[2] ],
											   ] ); }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'kind_of',
                                                    'vars' => '',
                                                    'line' => -218
                                                  }, 'Parse::RecDescent::Rule' ),
                              'integer' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [],
                                                    'changed' => 0,
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => '0',
                                                                          'strcount' => 0,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 1,
                                                                          'actcount' => 0,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'pattern' => '-?\\d+',
                                                                                                'hashname' => '__PATTERN1__',
                                                                                                'description' => '/-?\\\\d+/',
                                                                                                'lookahead' => 0,
                                                                                                'rdelim' => '/',
                                                                                                'line' => -29,
                                                                                                'mod' => '',
                                                                                                'ldelim' => '/'
                                                                                              }, 'Parse::RecDescent::Token' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'integer',
                                                    'vars' => '',
                                                    'line' => -31
                                                  }, 'Parse::RecDescent::Rule' ),
                              'topic_template_invocation' => bless( {
                                                                      'impcount' => 0,
                                                                      'calls' => [
                                                                                   'identifier',
                                                                                   'argument'
                                                                                 ],
                                                                      'changed' => 0,
                                                                      'opcount' => 0,
                                                                      'prods' => [
                                                                                   bless( {
                                                                                            'number' => '0',
                                                                                            'strcount' => 2,
                                                                                            'dircount' => 1,
                                                                                            'uncommit' => undef,
                                                                                            'error' => undef,
                                                                                            'patcount' => 1,
                                                                                            'actcount' => 2,
                                                                                            'op' => [],
                                                                                            'items' => [
                                                                                                         bless( {
                                                                                                                  'subrule' => 'identifier',
                                                                                                                  'matchrule' => 0,
                                                                                                                  'implicit' => undef,
                                                                                                                  'argcode' => undef,
                                                                                                                  'lookahead' => 0,
                                                                                                                  'line' => -431
                                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                                         bless( {
                                                                                                                  'hashname' => '__ACTION1__',
                                                                                                                  'lookahead' => 0,
                                                                                                                  'line' => -431,
                                                                                                                  'code' => '{ $templates{$item[1]} }'
                                                                                                                }, 'Parse::RecDescent::Action' ),
                                                                                                         bless( {
                                                                                                                  'pattern' => '(',
                                                                                                                  'hashname' => '__STRING1__',
                                                                                                                  'description' => '\'(\'',
                                                                                                                  'lookahead' => 0,
                                                                                                                  'line' => -430
                                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                                         bless( {
                                                                                                                  'expected' => '<leftop: argument /,/ argument>',
                                                                                                                  'min' => 1,
                                                                                                                  'name' => '\'argument(s)\'',
                                                                                                                  'max' => 100000000,
                                                                                                                  'leftarg' => bless( {
                                                                                                                                        'subrule' => 'argument',
                                                                                                                                        'matchrule' => 0,
                                                                                                                                        'implicit' => undef,
                                                                                                                                        'argcode' => undef,
                                                                                                                                        'lookahead' => 0,
                                                                                                                                        'line' => -430
                                                                                                                                      }, 'Parse::RecDescent::Subrule' ),
                                                                                                                  'rightarg' => bless( {
                                                                                                                                         'subrule' => 'argument',
                                                                                                                                         'matchrule' => 0,
                                                                                                                                         'implicit' => undef,
                                                                                                                                         'argcode' => undef,
                                                                                                                                         'lookahead' => 0,
                                                                                                                                         'line' => -430
                                                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                                  'hashname' => '__DIRECTIVE1__',
                                                                                                                  'type' => 'leftop',
                                                                                                                  'op' => bless( {
                                                                                                                                   'pattern' => ',',
                                                                                                                                   'hashname' => '__PATTERN1__',
                                                                                                                                   'description' => '/,/',
                                                                                                                                   'lookahead' => 0,
                                                                                                                                   'rdelim' => '/',
                                                                                                                                   'line' => -430,
                                                                                                                                   'mod' => '',
                                                                                                                                   'ldelim' => '/'
                                                                                                                                 }, 'Parse::RecDescent::Token' )
                                                                                                                }, 'Parse::RecDescent::Operator' ),
                                                                                                         bless( {
                                                                                                                  'pattern' => ')',
                                                                                                                  'hashname' => '__STRING2__',
                                                                                                                  'description' => '\')\'',
                                                                                                                  'lookahead' => 0,
                                                                                                                  'line' => -430
                                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                                         bless( {
                                                                                                                  'hashname' => '__ACTION2__',
                                                                                                                  'lookahead' => 0,
                                                                                                                  'line' => -430,
                                                                                                                  'code' => '{
									my $tmpl = $templates{$item[1]};
#		                                                        warn Dumper $templates{$item[1]};
#									warn Dumper $item[4];

									my $bu = $store->baseuri;
									$arg[0] =~ s/^$bu//;                   # pretend internal identifier
									unshift @{ $item[4] }, $arg[0];        # add topic as first param

									$text .= "\\n\\n%backup\\n\\n" . _expand_tmpl ($tmpl, $item[4]) . "\\n\\n%restore\\n\\n";
									$return = 1;

									sub _expand_tmpl {
									    my $tmpl   = shift;
									    my $name   = $tmpl->{name};
									    my $body   = $tmpl->{body};
									    my $params = $tmpl->{params};
									    my $args   = shift;
									    my %P;                             # formal -> actual 
									    foreach my $fp (@$params) {
										$P{$fp} = shift @$args  
										          or die "too few arguments for \'$name\'";
									    }
									    die "too many arguments for \'$name\'" if @$args;

									    foreach my $p (keys %P) {
										$p =~ s/\\$//;                 # remove $, so that regexp below works
										$body =~ s/\\$$p/$P{\'$\'.$p}/g;
									    }
									    return "\\n" . $body . "\\n";     # extend the text at the end;
									}
	                                                              }'
                                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                                       ],
                                                                                            'line' => undef
                                                                                          }, 'Parse::RecDescent::Production' )
                                                                                 ],
                                                                      'name' => 'topic_template_invocation',
                                                                      'vars' => '',
                                                                      'line' => -432
                                                                    }, 'Parse::RecDescent::Rule' ),
                              'startrule' => bless( {
                                                      'impcount' => 0,
                                                      'calls' => [
                                                                   'topicmap'
                                                                 ],
                                                      'changed' => 0,
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'number' => '0',
                                                                            'strcount' => 0,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 20,
                                                                                                  'code' => '{  $store     = $arg[0]; 
									 $log       = $arg[1];
									 $implicits = $arg[2];
									 %prefixes  = (\'xsd\' => TM::Literal->XSD);
									 %templates = ();
									 %wildcards = ();
 								       }'
                                                                                                }, 'Parse::RecDescent::Action' ),
                                                                                         bless( {
                                                                                                  'subrule' => 'topicmap',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => 27
                                                                                                }, 'Parse::RecDescent::Subrule' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'startrule',
                                                      'vars' => '',
                                                      'line' => 18
                                                    }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_2_of_rule_string' => bless( {
                                                                                          'impcount' => 0,
                                                                                          'calls' => [
                                                                                                       'iri'
                                                                                                     ],
                                                                                          'changed' => 0,
                                                                                          'opcount' => 0,
                                                                                          'prods' => [
                                                                                                       bless( {
                                                                                                                'number' => '0',
                                                                                                                'strcount' => 1,
                                                                                                                'dircount' => 0,
                                                                                                                'uncommit' => undef,
                                                                                                                'error' => undef,
                                                                                                                'patcount' => 0,
                                                                                                                'actcount' => 0,
                                                                                                                'items' => [
                                                                                                                             bless( {
                                                                                                                                      'pattern' => '^^',
                                                                                                                                      'hashname' => '__STRING1__',
                                                                                                                                      'description' => '\'^^\'',
                                                                                                                                      'lookahead' => 0,
                                                                                                                                      'line' => 1
                                                                                                                                    }, 'Parse::RecDescent::Literal' ),
                                                                                                                             bless( {
                                                                                                                                      'subrule' => 'iri',
                                                                                                                                      'matchrule' => 0,
                                                                                                                                      'implicit' => undef,
                                                                                                                                      'argcode' => undef,
                                                                                                                                      'lookahead' => 0,
                                                                                                                                      'line' => 1
                                                                                                                                    }, 'Parse::RecDescent::Subrule' )
                                                                                                                           ],
                                                                                                                'line' => undef
                                                                                                              }, 'Parse::RecDescent::Production' )
                                                                                                     ],
                                                                                          'name' => '_alternation_1_of_production_2_of_rule_string',
                                                                                          'vars' => '',
                                                                                          'line' => 1
                                                                                        }, 'Parse::RecDescent::Rule' ),
                              'roles' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [
                                                               'role'
                                                             ],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => '0',
                                                                        'strcount' => 0,
                                                                        'dircount' => 1,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 1,
                                                                        'actcount' => 0,
                                                                        'op' => [],
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'expected' => '<leftop: role /,/ role>',
                                                                                              'min' => 1,
                                                                                              'name' => '\'role(s)\'',
                                                                                              'max' => 100000000,
                                                                                              'leftarg' => bless( {
                                                                                                                    'subrule' => 'role',
                                                                                                                    'matchrule' => 0,
                                                                                                                    'implicit' => undef,
                                                                                                                    'argcode' => undef,
                                                                                                                    'lookahead' => 0,
                                                                                                                    'line' => -361
                                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                              'rightarg' => bless( {
                                                                                                                     'subrule' => 'role',
                                                                                                                     'matchrule' => 0,
                                                                                                                     'implicit' => undef,
                                                                                                                     'argcode' => undef,
                                                                                                                     'lookahead' => 0,
                                                                                                                     'line' => -361
                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                              'hashname' => '__DIRECTIVE1__',
                                                                                              'type' => 'leftop',
                                                                                              'op' => bless( {
                                                                                                               'pattern' => ',',
                                                                                                               'hashname' => '__PATTERN1__',
                                                                                                               'description' => '/,/',
                                                                                                               'lookahead' => 0,
                                                                                                               'rdelim' => '/',
                                                                                                               'line' => -361,
                                                                                                               'mod' => '',
                                                                                                               'ldelim' => '/'
                                                                                                             }, 'Parse::RecDescent::Token' )
                                                                                            }, 'Parse::RecDescent::Operator' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'roles',
                                                  'vars' => '',
                                                  'line' => -361
                                                }, 'Parse::RecDescent::Rule' ),
                              'template' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [
                                                                  'identifier',
                                                                  'parameters'
                                                                ],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => '0',
                                                                           'strcount' => 2,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 1,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'pattern' => 'def',
                                                                                                 'hashname' => '__STRING1__',
                                                                                                 'description' => '\'def\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -447
                                                                                               }, 'Parse::RecDescent::Literal' ),
                                                                                        bless( {
                                                                                                 'subrule' => 'identifier',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -447
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'subrule' => 'parameters',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -447
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'pattern' => '(.*?)(?=\\bend\\n)',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/(.*?)(?=\\\\bend\\\\n)/s',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => -447,
                                                                                                 'mod' => 's',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' ),
                                                                                        bless( {
                                                                                                 'pattern' => 'end',
                                                                                                 'hashname' => '__STRING2__',
                                                                                                 'description' => '\'end\'',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -447
                                                                                               }, 'Parse::RecDescent::Literal' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -447,
                                                                                                 'code' => '{
                                                                       my $return = {
									   name   => $item[2],
									   params => $item[3],
									   body   => $item[4],
								       };
								       $templates{$return->{name}} 
								          and die "template \'".$return->{name}."\' already defined";
								       $templates{$return->{name}} = $return;
								      }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'template',
                                                     'vars' => '',
                                                     'line' => -449
                                                   }, 'Parse::RecDescent::Rule' ),
                              'assignment' => bless( {
                                                       'impcount' => 0,
                                                       'calls' => [
                                                                    'name',
                                                                    'occurrence'
                                                                  ],
                                                       'changed' => 0,
                                                       'opcount' => 0,
                                                       'prods' => [
                                                                    bless( {
                                                                             'number' => '0',
                                                                             'strcount' => 0,
                                                                             'dircount' => 0,
                                                                             'uncommit' => undef,
                                                                             'error' => undef,
                                                                             'patcount' => 0,
                                                                             'actcount' => 0,
                                                                             'items' => [
                                                                                          bless( {
                                                                                                   'subrule' => 'name',
                                                                                                   'matchrule' => 0,
                                                                                                   'implicit' => undef,
                                                                                                   'argcode' => '[$arg[0]]',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => -295
                                                                                                 }, 'Parse::RecDescent::Subrule' )
                                                                                        ],
                                                                             'line' => undef
                                                                           }, 'Parse::RecDescent::Production' ),
                                                                    bless( {
                                                                             'number' => '1',
                                                                             'strcount' => 0,
                                                                             'dircount' => 0,
                                                                             'uncommit' => undef,
                                                                             'error' => undef,
                                                                             'patcount' => 0,
                                                                             'actcount' => 0,
                                                                             'items' => [
                                                                                          bless( {
                                                                                                   'subrule' => 'occurrence',
                                                                                                   'matchrule' => 0,
                                                                                                   'implicit' => undef,
                                                                                                   'argcode' => '[$arg[0]]',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => -294
                                                                                                 }, 'Parse::RecDescent::Subrule' )
                                                                                        ],
                                                                             'line' => -294
                                                                           }, 'Parse::RecDescent::Production' )
                                                                  ],
                                                       'name' => 'assignment',
                                                       'vars' => '',
                                                       'line' => -295
                                                     }, 'Parse::RecDescent::Rule' ),
                              'iri_literal' => bless( {
                                                        'impcount' => 0,
                                                        'calls' => [
                                                                     'literal',
                                                                     'iri'
                                                                   ],
                                                        'changed' => 0,
                                                        'opcount' => 0,
                                                        'prods' => [
                                                                     bless( {
                                                                              'number' => '0',
                                                                              'strcount' => 0,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 0,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'subrule' => 'literal',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => -236
                                                                                                  }, 'Parse::RecDescent::Subrule' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' ),
                                                                     bless( {
                                                                              'number' => '1',
                                                                              'strcount' => 0,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'subrule' => 'iri',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => -235
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => -235,
                                                                                                    'code' => '{ $return = new TM::Literal ($item[1], TM::Literal->URI); }'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => -235
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'name' => 'iri_literal',
                                                        'vars' => '',
                                                        'line' => -236
                                                      }, 'Parse::RecDescent::Rule' ),
                              'subject_identifier' => bless( {
                                                               'impcount' => 0,
                                                               'calls' => [
                                                                            'iri'
                                                                          ],
                                                               'changed' => 0,
                                                               'opcount' => 0,
                                                               'prods' => [
                                                                            bless( {
                                                                                     'number' => '0',
                                                                                     'strcount' => 0,
                                                                                     'dircount' => 0,
                                                                                     'uncommit' => undef,
                                                                                     'error' => undef,
                                                                                     'patcount' => 0,
                                                                                     'actcount' => 1,
                                                                                     'items' => [
                                                                                                  bless( {
                                                                                                           'subrule' => 'iri',
                                                                                                           'matchrule' => 0,
                                                                                                           'implicit' => undef,
                                                                                                           'argcode' => undef,
                                                                                                           'lookahead' => 0,
                                                                                                           'line' => -319
                                                                                                         }, 'Parse::RecDescent::Subrule' ),
                                                                                                  bless( {
                                                                                                           'hashname' => '__ACTION1__',
                                                                                                           'lookahead' => 0,
                                                                                                           'line' => -319,
                                                                                                           'code' => '{ $return = \\ $item[1]; }'
                                                                                                         }, 'Parse::RecDescent::Action' )
                                                                                                ],
                                                                                     'line' => undef
                                                                                   }, 'Parse::RecDescent::Production' )
                                                                          ],
                                                               'name' => 'subject_identifier',
                                                               'vars' => '',
                                                               'line' => -319
                                                             }, 'Parse::RecDescent::Rule' ),
                              'parameters' => bless( {
                                                       'impcount' => 0,
                                                       'calls' => [
                                                                    'variable'
                                                                  ],
                                                       'changed' => 0,
                                                       'opcount' => 0,
                                                       'prods' => [
                                                                    bless( {
                                                                             'number' => '0',
                                                                             'strcount' => 2,
                                                                             'dircount' => 1,
                                                                             'uncommit' => undef,
                                                                             'error' => undef,
                                                                             'patcount' => 1,
                                                                             'actcount' => 1,
                                                                             'op' => [],
                                                                             'items' => [
                                                                                          bless( {
                                                                                                   'pattern' => '(',
                                                                                                   'hashname' => '__STRING1__',
                                                                                                   'description' => '\'(\'',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => -436
                                                                                                 }, 'Parse::RecDescent::Literal' ),
                                                                                          bless( {
                                                                                                   'expected' => '<leftop: variable /,/ variable>',
                                                                                                   'min' => 0,
                                                                                                   'name' => '\'variable(s?)\'',
                                                                                                   'max' => 100000000,
                                                                                                   'leftarg' => bless( {
                                                                                                                         'subrule' => 'variable',
                                                                                                                         'matchrule' => 0,
                                                                                                                         'implicit' => undef,
                                                                                                                         'argcode' => undef,
                                                                                                                         'lookahead' => 0,
                                                                                                                         'line' => -436
                                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                   'rightarg' => bless( {
                                                                                                                          'subrule' => 'variable',
                                                                                                                          'matchrule' => 0,
                                                                                                                          'implicit' => undef,
                                                                                                                          'argcode' => undef,
                                                                                                                          'lookahead' => 0,
                                                                                                                          'line' => -436
                                                                                                                        }, 'Parse::RecDescent::Subrule' ),
                                                                                                   'hashname' => '__DIRECTIVE1__',
                                                                                                   'type' => 'leftop',
                                                                                                   'op' => bless( {
                                                                                                                    'pattern' => ',',
                                                                                                                    'hashname' => '__PATTERN1__',
                                                                                                                    'description' => '/,/',
                                                                                                                    'lookahead' => 0,
                                                                                                                    'rdelim' => '/',
                                                                                                                    'line' => -436,
                                                                                                                    'mod' => '',
                                                                                                                    'ldelim' => '/'
                                                                                                                  }, 'Parse::RecDescent::Token' )
                                                                                                 }, 'Parse::RecDescent::Operator' ),
                                                                                          bless( {
                                                                                                   'pattern' => ')',
                                                                                                   'hashname' => '__STRING2__',
                                                                                                   'description' => '\')\'',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => -436
                                                                                                 }, 'Parse::RecDescent::Literal' ),
                                                                                          bless( {
                                                                                                   'hashname' => '__ACTION1__',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => -436,
                                                                                                   'code' => '{ $return = $item[2]; }'
                                                                                                 }, 'Parse::RecDescent::Action' )
                                                                                        ],
                                                                             'line' => undef
                                                                           }, 'Parse::RecDescent::Production' )
                                                                  ],
                                                       'name' => 'parameters',
                                                       'vars' => '',
                                                       'line' => -436
                                                     }, 'Parse::RecDescent::Rule' ),
                              'typing' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'type'
                                                              ],
                                                   'changed' => 0,
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => '0',
                                                                         'strcount' => 1,
                                                                         'dircount' => 0,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 1,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'subrule' => 'type',
                                                                                               'matchrule' => 0,
                                                                                               'implicit' => undef,
                                                                                               'argcode' => undef,
                                                                                               'lookahead' => 0,
                                                                                               'line' => -238
                                                                                             }, 'Parse::RecDescent::Subrule' ),
                                                                                      bless( {
                                                                                               'pattern' => ':',
                                                                                               'hashname' => '__STRING1__',
                                                                                               'description' => '\':\'',
                                                                                               'lookahead' => 0,
                                                                                               'line' => -238
                                                                                             }, 'Parse::RecDescent::Literal' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => -238,
                                                                                               'code' => '{ $return = $item[1]; }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'typing',
                                                   'vars' => '',
                                                   'line' => -238
                                                 }, 'Parse::RecDescent::Rule' ),
                              'type' => bless( {
                                                 'impcount' => 0,
                                                 'calls' => [
                                                              'topic_ref'
                                                            ],
                                                 'changed' => 0,
                                                 'opcount' => 0,
                                                 'prods' => [
                                                              bless( {
                                                                       'number' => '0',
                                                                       'strcount' => 0,
                                                                       'dircount' => 0,
                                                                       'uncommit' => undef,
                                                                       'error' => undef,
                                                                       'patcount' => 0,
                                                                       'actcount' => 0,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'subrule' => 'topic_ref',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => -233
                                                                                           }, 'Parse::RecDescent::Subrule' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'type',
                                                 'vars' => '',
                                                 'line' => -233
                                               }, 'Parse::RecDescent::Rule' ),
                              'prolog' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'encoding',
                                                                'version'
                                                              ],
                                                   'changed' => 0,
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => '0',
                                                                         'strcount' => 0,
                                                                         'dircount' => 0,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 0,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'subrule' => 'encoding',
                                                                                               'expected' => undef,
                                                                                               'min' => 0,
                                                                                               'argcode' => undef,
                                                                                               'max' => 1,
                                                                                               'matchrule' => 0,
                                                                                               'repspec' => '?',
                                                                                               'lookahead' => 0,
                                                                                               'line' => -498
                                                                                             }, 'Parse::RecDescent::Repetition' ),
                                                                                      bless( {
                                                                                               'subrule' => 'version',
                                                                                               'expected' => undef,
                                                                                               'min' => 0,
                                                                                               'argcode' => undef,
                                                                                               'max' => 1,
                                                                                               'matchrule' => 0,
                                                                                               'repspec' => '?',
                                                                                               'lookahead' => 0,
                                                                                               'line' => -498
                                                                                             }, 'Parse::RecDescent::Repetition' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'prolog',
                                                   'vars' => '',
                                                   'line' => -498
                                                 }, 'Parse::RecDescent::Rule' ),
                              'types' => bless( {
                                                  'impcount' => 0,
                                                  'calls' => [
                                                               'name'
                                                             ],
                                                  'changed' => 0,
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => '0',
                                                                        'strcount' => 1,
                                                                        'dircount' => 0,
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => 0,
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'pattern' => ':',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\':\'',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -119
                                                                                            }, 'Parse::RecDescent::Literal' ),
                                                                                     bless( {
                                                                                              'subrule' => 'name',
                                                                                              'expected' => undef,
                                                                                              'min' => 1,
                                                                                              'argcode' => undef,
                                                                                              'max' => 100000000,
                                                                                              'matchrule' => 0,
                                                                                              'repspec' => 's',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -119
                                                                                            }, 'Parse::RecDescent::Repetition' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => 0,
                                                                                              'line' => -119,
                                                                                              'code' => '{ $return = $item[2]; }'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'types',
                                                  'vars' => '',
                                                  'line' => -119
                                                }, 'Parse::RecDescent::Rule' ),
                              'include_directive' => bless( {
                                                              'impcount' => 1,
                                                              'calls' => [
                                                                           '_alternation_1_of_production_1_of_rule_include_directive'
                                                                         ],
                                                              'changed' => 0,
                                                              'opcount' => 0,
                                                              'prods' => [
                                                                           bless( {
                                                                                    'number' => '0',
                                                                                    'strcount' => 1,
                                                                                    'dircount' => 0,
                                                                                    'uncommit' => undef,
                                                                                    'error' => undef,
                                                                                    'patcount' => 0,
                                                                                    'actcount' => 1,
                                                                                    'items' => [
                                                                                                 bless( {
                                                                                                          'pattern' => '%include',
                                                                                                          'hashname' => '__STRING1__',
                                                                                                          'description' => '\'%include\'',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => -468
                                                                                                        }, 'Parse::RecDescent::Literal' ),
                                                                                                 bless( {
                                                                                                          'subrule' => '_alternation_1_of_production_1_of_rule_include_directive',
                                                                                                          'matchrule' => 0,
                                                                                                          'implicit' => '/^inline:.*?\\\\n/, or iri',
                                                                                                          'argcode' => undef,
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => -468
                                                                                                        }, 'Parse::RecDescent::Subrule' ),
                                                                                                 bless( {
                                                                                                          'hashname' => '__ACTION1__',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => -468,
                                                                                                          'code' => '{
                                                                         my $src = $item[2];
									 my $include;                      # we are trying to figure that one out
									 if ($src =~ /^inline:(.*)/s) {
									     $include = $1;
									 } else {                          # we try our luck with LWP
									     use LWP::Simple;
									     $include = get($1) or
										 $TM::log->logdie (__PACKAGE__ .": unable to load \'$1\'\\n");
									 }
									 $text = $include . $text;
								      }'
                                                                                                        }, 'Parse::RecDescent::Action' )
                                                                                               ],
                                                                                    'line' => undef
                                                                                  }, 'Parse::RecDescent::Production' )
                                                                         ],
                                                              'name' => 'include_directive',
                                                              'vars' => '',
                                                              'line' => -468
                                                            }, 'Parse::RecDescent::Rule' ),
                              'topic_ref' => bless( {
                                                      'impcount' => 0,
                                                      'calls' => [
                                                                   'topic_identity',
                                                                   'embedded_topic'
                                                                 ],
                                                      'changed' => 0,
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'number' => '0',
                                                                            'strcount' => 0,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'subrule' => 'topic_identity',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => -328
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => -328,
                                                                                                  'code' => '{ $return = ref ($item[1]) ? $store->internalize (undef, $item[1]) : $item[1]; }'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => '1',
                                                                            'strcount' => 0,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 0,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'subrule' => 'embedded_topic',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => -327
                                                                                                }, 'Parse::RecDescent::Subrule' )
                                                                                       ],
                                                                            'line' => -327
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'topic_ref',
                                                      'vars' => '',
                                                      'line' => -328
                                                    }, 'Parse::RecDescent::Rule' ),
                              'topname' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [
                                                                 'basesortdispname',
                                                                 'scope'
                                                               ],
                                                    'changed' => 0,
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => '0',
                                                                          'strcount' => 1,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 0,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'pattern' => '=',
                                                                                                'hashname' => '__STRING1__',
                                                                                                'description' => '\'=\'',
                                                                                                'lookahead' => 0,
                                                                                                'line' => -113
                                                                                              }, 'Parse::RecDescent::Literal' ),
                                                                                       bless( {
                                                                                                'subrule' => 'basesortdispname',
                                                                                                'matchrule' => 0,
                                                                                                'implicit' => undef,
                                                                                                'argcode' => undef,
                                                                                                'lookahead' => 0,
                                                                                                'line' => -113
                                                                                              }, 'Parse::RecDescent::Subrule' ),
                                                                                       bless( {
                                                                                                'subrule' => 'scope',
                                                                                                'expected' => undef,
                                                                                                'min' => 0,
                                                                                                'argcode' => undef,
                                                                                                'max' => 1,
                                                                                                'matchrule' => 0,
                                                                                                'repspec' => '?',
                                                                                                'lookahead' => 0,
                                                                                                'line' => -113
                                                                                              }, 'Parse::RecDescent::Repetition' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => -112,
                                                                                                'code' => '{
#warn "basenames".Dumper \\@item;
			  $return = {
			      scope    => $item[3],
			      names    => $item[2],
			  };
		      }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'topname',
                                                    'vars' => '',
                                                    'line' => -115
                                                  }, 'Parse::RecDescent::Rule' ),
                              'topic_tail' => bless( {
                                                       'impcount' => 1,
                                                       'calls' => [
                                                                    '_alternation_1_of_production_1_of_rule_topic_tail'
                                                                  ],
                                                       'changed' => 0,
                                                       'opcount' => 0,
                                                       'prods' => [
                                                                    bless( {
                                                                             'number' => '0',
                                                                             'strcount' => 0,
                                                                             'dircount' => 0,
                                                                             'uncommit' => undef,
                                                                             'error' => undef,
                                                                             'patcount' => 1,
                                                                             'actcount' => 0,
                                                                             'items' => [
                                                                                          bless( {
                                                                                                   'subrule' => '_alternation_1_of_production_1_of_rule_topic_tail',
                                                                                                   'matchrule' => 0,
                                                                                                   'implicit' => 'instance_of, or kind_of, or topic_template_invocation, or subject_identifier, or subject_locator, or assignment',
                                                                                                   'argcode' => undef,
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => -298
                                                                                                 }, 'Parse::RecDescent::Subrule' ),
                                                                                          bless( {
                                                                                                   'pattern' => ';?',
                                                                                                   'hashname' => '__PATTERN1__',
                                                                                                   'description' => '/;?/',
                                                                                                   'lookahead' => 0,
                                                                                                   'rdelim' => '/',
                                                                                                   'line' => -298,
                                                                                                   'mod' => '',
                                                                                                   'ldelim' => '/'
                                                                                                 }, 'Parse::RecDescent::Token' )
                                                                                        ],
                                                                             'line' => undef
                                                                           }, 'Parse::RecDescent::Production' )
                                                                  ],
                                                       'name' => 'topic_tail',
                                                       'vars' => '',
                                                       'line' => -309
                                                     }, 'Parse::RecDescent::Rule' ),
                              'reference' => bless( {
                                                      'impcount' => 0,
                                                      'calls' => [
                                                                   'iri'
                                                                 ],
                                                      'changed' => 0,
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'number' => '0',
                                                                            'strcount' => 0,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 0,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'subrule' => 'iri',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => -471
                                                                                                }, 'Parse::RecDescent::Subrule' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => '1',
                                                                            'strcount' => 0,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 1,
                                                                            'actcount' => 0,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'pattern' => '\\S+',
                                                                                                  'hashname' => '__PATTERN1__',
                                                                                                  'description' => '/\\\\S+/',
                                                                                                  'lookahead' => 0,
                                                                                                  'rdelim' => '/',
                                                                                                  'line' => -470,
                                                                                                  'mod' => '',
                                                                                                  'ldelim' => '/'
                                                                                                }, 'Parse::RecDescent::Token' )
                                                                                       ],
                                                                            'line' => -470
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'reference',
                                                      'vars' => '',
                                                      'line' => -471
                                                    }, 'Parse::RecDescent::Rule' ),
                              'instance_of' => bless( {
                                                        'impcount' => 0,
                                                        'calls' => [
                                                                     'topic_ref'
                                                                   ],
                                                        'changed' => 0,
                                                        'opcount' => 0,
                                                        'prods' => [
                                                                     bless( {
                                                                              'number' => '0',
                                                                              'strcount' => 1,
                                                                              'dircount' => 0,
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 0,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'pattern' => 'isa',
                                                                                                    'hashname' => '__STRING1__',
                                                                                                    'description' => '\'isa\'',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => -225
                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'topic_ref',
                                                                                                    'matchrule' => 0,
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => -225
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => 0,
                                                                                                    'line' => -225,
                                                                                                    'code' => '{ $store->assert ( [ undef, 
											   undef, 
											   \'isa\', 
											   undef,
											   [ \'class\', \'instance\' ], 
											   [ $item[2], $arg[0] ],
											   ] ); }'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'name' => 'instance_of',
                                                        'vars' => '',
                                                        'line' => -227
                                                      }, 'Parse::RecDescent::Rule' ),
                              'named_wildcard' => bless( {
                                                           'impcount' => 0,
                                                           'calls' => [],
                                                           'changed' => 0,
                                                           'opcount' => 0,
                                                           'prods' => [
                                                                        bless( {
                                                                                 'number' => '0',
                                                                                 'strcount' => 0,
                                                                                 'dircount' => 0,
                                                                                 'uncommit' => undef,
                                                                                 'error' => undef,
                                                                                 'patcount' => 1,
                                                                                 'actcount' => 1,
                                                                                 'items' => [
                                                                                              bless( {
                                                                                                       'pattern' => '\\?(\\w[\\w-]*)',
                                                                                                       'hashname' => '__PATTERN1__',
                                                                                                       'description' => '/\\\\?(\\\\w[\\\\w-]*)/',
                                                                                                       'lookahead' => 0,
                                                                                                       'rdelim' => '/',
                                                                                                       'line' => -337,
                                                                                                       'mod' => '',
                                                                                                       'ldelim' => '/'
                                                                                                     }, 'Parse::RecDescent::Token' ),
                                                                                              bless( {
                                                                                                       'hashname' => '__ACTION1__',
                                                                                                       'lookahead' => 0,
                                                                                                       'line' => -337,
                                                                                                       'code' => '{
                                                                        my $id = $1;
									$wildcards{$id} ||=
									    $store->internalize (sprintf "uuid-%010d", $TM::toplet_ctr++);
									$return = $wildcards{$id};
								      }'
                                                                                                     }, 'Parse::RecDescent::Action' )
                                                                                            ],
                                                                                 'line' => undef
                                                                               }, 'Parse::RecDescent::Production' )
                                                                      ],
                                                           'name' => 'named_wildcard',
                                                           'vars' => '',
                                                           'line' => -337
                                                         }, 'Parse::RecDescent::Rule' ),
                              'topic_identity' => bless( {
                                                           'impcount' => 0,
                                                           'calls' => [
                                                                        'subject_identifier',
                                                                        'identifier',
                                                                        'subject_locator',
                                                                        'wildcard'
                                                                      ],
                                                           'changed' => 0,
                                                           'opcount' => 0,
                                                           'prods' => [
                                                                        bless( {
                                                                                 'number' => '0',
                                                                                 'strcount' => 0,
                                                                                 'dircount' => 0,
                                                                                 'uncommit' => undef,
                                                                                 'error' => undef,
                                                                                 'patcount' => 0,
                                                                                 'actcount' => 1,
                                                                                 'items' => [
                                                                                              bless( {
                                                                                                       'subrule' => 'subject_identifier',
                                                                                                       'matchrule' => 0,
                                                                                                       'implicit' => undef,
                                                                                                       'argcode' => undef,
                                                                                                       'lookahead' => 0,
                                                                                                       'line' => -349
                                                                                                     }, 'Parse::RecDescent::Subrule' ),
                                                                                              bless( {
                                                                                                       'hashname' => '__ACTION1__',
                                                                                                       'lookahead' => 0,
                                                                                                       'line' => -349,
                                                                                                       'code' => '{ $return = $store->internalize (undef, $item[1]); }'
                                                                                                     }, 'Parse::RecDescent::Action' )
                                                                                            ],
                                                                                 'line' => undef
                                                                               }, 'Parse::RecDescent::Production' ),
                                                                        bless( {
                                                                                 'number' => '1',
                                                                                 'strcount' => 0,
                                                                                 'dircount' => 0,
                                                                                 'uncommit' => undef,
                                                                                 'error' => undef,
                                                                                 'patcount' => 0,
                                                                                 'actcount' => 1,
                                                                                 'items' => [
                                                                                              bless( {
                                                                                                       'subrule' => 'identifier',
                                                                                                       'matchrule' => 0,
                                                                                                       'implicit' => undef,
                                                                                                       'argcode' => undef,
                                                                                                       'lookahead' => 0,
                                                                                                       'line' => -348
                                                                                                     }, 'Parse::RecDescent::Subrule' ),
                                                                                              bless( {
                                                                                                       'hashname' => '__ACTION1__',
                                                                                                       'lookahead' => 0,
                                                                                                       'line' => -348,
                                                                                                       'code' => '{ $return = $store->internalize ($item[1]); }'
                                                                                                     }, 'Parse::RecDescent::Action' )
                                                                                            ],
                                                                                 'line' => -348
                                                                               }, 'Parse::RecDescent::Production' ),
                                                                        bless( {
                                                                                 'number' => '2',
                                                                                 'strcount' => 0,
                                                                                 'dircount' => 0,
                                                                                 'uncommit' => undef,
                                                                                 'error' => undef,
                                                                                 'patcount' => 0,
                                                                                 'actcount' => 1,
                                                                                 'items' => [
                                                                                              bless( {
                                                                                                       'subrule' => 'subject_locator',
                                                                                                       'matchrule' => 0,
                                                                                                       'implicit' => undef,
                                                                                                       'argcode' => undef,
                                                                                                       'lookahead' => 0,
                                                                                                       'line' => -347
                                                                                                     }, 'Parse::RecDescent::Subrule' ),
                                                                                              bless( {
                                                                                                       'hashname' => '__ACTION1__',
                                                                                                       'lookahead' => 0,
                                                                                                       'line' => -347,
                                                                                                       'code' => '{ $return = $store->internalize (undef, $item[1]); }'
                                                                                                     }, 'Parse::RecDescent::Action' )
                                                                                            ],
                                                                                 'line' => -347
                                                                               }, 'Parse::RecDescent::Production' ),
                                                                        bless( {
                                                                                 'number' => '3',
                                                                                 'strcount' => 0,
                                                                                 'dircount' => 0,
                                                                                 'uncommit' => undef,
                                                                                 'error' => undef,
                                                                                 'patcount' => 0,
                                                                                 'actcount' => 0,
                                                                                 'items' => [
                                                                                              bless( {
                                                                                                       'subrule' => 'wildcard',
                                                                                                       'matchrule' => 0,
                                                                                                       'implicit' => undef,
                                                                                                       'argcode' => undef,
                                                                                                       'lookahead' => 0,
                                                                                                       'line' => -345
                                                                                                     }, 'Parse::RecDescent::Subrule' )
                                                                                            ],
                                                                                 'line' => -346
                                                                               }, 'Parse::RecDescent::Production' )
                                                                      ],
                                                           'name' => 'topic_identity',
                                                           'vars' => '',
                                                           'line' => -349
                                                         }, 'Parse::RecDescent::Rule' ),
                              'mergemap_directive' => bless( {
                                                               'impcount' => 0,
                                                               'calls' => [
                                                                            'uri',
                                                                            'tm_format'
                                                                          ],
                                                               'changed' => 0,
                                                               'opcount' => 0,
                                                               'prods' => [
                                                                            bless( {
                                                                                     'number' => '0',
                                                                                     'strcount' => 1,
                                                                                     'dircount' => 0,
                                                                                     'uncommit' => undef,
                                                                                     'error' => undef,
                                                                                     'patcount' => 0,
                                                                                     'actcount' => 1,
                                                                                     'items' => [
                                                                                                  bless( {
                                                                                                           'pattern' => '#MERGEMAP',
                                                                                                           'hashname' => '__STRING1__',
                                                                                                           'description' => '\'#MERGEMAP\'',
                                                                                                           'lookahead' => 0,
                                                                                                           'line' => -192
                                                                                                         }, 'Parse::RecDescent::Literal' ),
                                                                                                  bless( {
                                                                                                           'subrule' => 'uri',
                                                                                                           'matchrule' => 0,
                                                                                                           'implicit' => undef,
                                                                                                           'argcode' => undef,
                                                                                                           'lookahead' => 0,
                                                                                                           'line' => -192
                                                                                                         }, 'Parse::RecDescent::Subrule' ),
                                                                                                  bless( {
                                                                                                           'subrule' => 'tm_format',
                                                                                                           'expected' => undef,
                                                                                                           'min' => 0,
                                                                                                           'argcode' => undef,
                                                                                                           'max' => 1,
                                                                                                           'matchrule' => 0,
                                                                                                           'repspec' => '?',
                                                                                                           'lookahead' => 0,
                                                                                                           'line' => -192
                                                                                                         }, 'Parse::RecDescent::Repetition' ),
                                                                                                  bless( {
                                                                                                           'hashname' => '__ACTION1__',
                                                                                                           'lookahead' => 0,
                                                                                                           'line' => -191,
                                                                                                           'code' => '{
			  my $uri = $item[2];
#warn "uri is $uri";
			  my $format = $item[3]->[0] ? $item[3]->[0] : \'ltm\';
			  my $tm;
			  if ($format =~ /^ltm$/i) {
			      $tm = new TM::Materialized::LTM (url => $uri);
			  } elsif ($format =~ /^xtm$/i) {
			      $tm = new TM::Materialized::XTM (url => $uri);
			  } elsif ($format =~ /^astma$/i) {
			      $tm = new TM::Materialized::AsTMa (url => $uri);
			  } else {
			      $log->logdie (__PACKAGE__ . ": unsupported TM format \'$format\'");
			  }
			  $tm->sync_in;
			  $store->add ($tm);
#warn "after merged in".Dumper $store;
			  $return = $uri;
		      }'
                                                                                                         }, 'Parse::RecDescent::Action' )
                                                                                                ],
                                                                                     'line' => undef
                                                                                   }, 'Parse::RecDescent::Production' )
                                                                          ],
                                                               'name' => 'mergemap_directive',
                                                               'vars' => '',
                                                               'line' => -192
                                                             }, 'Parse::RecDescent::Rule' ),
                              'embedded_topic' => bless( {
                                                           'impcount' => 0,
                                                           'calls' => [
                                                                        'topic_tail'
                                                                      ],
                                                           'changed' => 0,
                                                           'opcount' => 0,
                                                           'prods' => [
                                                                        bless( {
                                                                                 'number' => '0',
                                                                                 'strcount' => 0,
                                                                                 'dircount' => 1,
                                                                                 'uncommit' => undef,
                                                                                 'error' => undef,
                                                                                 'patcount' => 0,
                                                                                 'actcount' => 0,
                                                                                 'items' => [
                                                                                              bless( {
                                                                                                       'hashname' => '__DIRECTIVE1__',
                                                                                                       'name' => '<rulevar: $llid>',
                                                                                                       'lookahead' => 0,
                                                                                                       'line' => -325
                                                                                                     }, 'Parse::RecDescent::UncondReject' )
                                                                                            ],
                                                                                 'line' => undef
                                                                               }, 'Parse::RecDescent::Production' ),
                                                                        bless( {
                                                                                 'number' => '1',
                                                                                 'strcount' => 2,
                                                                                 'dircount' => 0,
                                                                                 'uncommit' => undef,
                                                                                 'error' => undef,
                                                                                 'patcount' => 0,
                                                                                 'actcount' => 2,
                                                                                 'items' => [
                                                                                              bless( {
                                                                                                       'pattern' => '[',
                                                                                                       'hashname' => '__STRING1__',
                                                                                                       'description' => '\'[\'',
                                                                                                       'lookahead' => 0,
                                                                                                       'line' => -323
                                                                                                     }, 'Parse::RecDescent::Literal' ),
                                                                                              bless( {
                                                                                                       'hashname' => '__ACTION1__',
                                                                                                       'lookahead' => 0,
                                                                                                       'line' => -323,
                                                                                                       'code' => '{ $llid = sprintf "uuid-%010d", $TM::toplet_ctr++; }'
                                                                                                     }, 'Parse::RecDescent::Action' ),
                                                                                              bless( {
                                                                                                       'subrule' => 'topic_tail',
                                                                                                       'matchrule' => 0,
                                                                                                       'implicit' => undef,
                                                                                                       'argcode' => '[$llid]',
                                                                                                       'lookahead' => 0,
                                                                                                       'line' => -322
                                                                                                     }, 'Parse::RecDescent::Subrule' ),
                                                                                              bless( {
                                                                                                       'pattern' => ']',
                                                                                                       'hashname' => '__STRING2__',
                                                                                                       'description' => '\']\'',
                                                                                                       'lookahead' => 0,
                                                                                                       'line' => -321
                                                                                                     }, 'Parse::RecDescent::Literal' ),
                                                                                              bless( {
                                                                                                       'hashname' => '__ACTION2__',
                                                                                                       'lookahead' => 0,
                                                                                                       'line' => -321,
                                                                                                       'code' => '{ $return = $llid; }'
                                                                                                     }, 'Parse::RecDescent::Action' )
                                                                                            ],
                                                                                 'line' => undef
                                                                               }, 'Parse::RecDescent::Production' )
                                                                      ],
                                                           'name' => 'embedded_topic',
                                                           'vars' => 'my  $llid;
',
                                                           'line' => -325
                                                         }, 'Parse::RecDescent::Rule' ),
                              'player' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'topic_ref'
                                                              ],
                                                   'changed' => 0,
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => '0',
                                                                         'strcount' => 0,
                                                                         'dircount' => 0,
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 0,
                                                                         'actcount' => 0,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'subrule' => 'topic_ref',
                                                                                               'matchrule' => 0,
                                                                                               'implicit' => undef,
                                                                                               'argcode' => undef,
                                                                                               'lookahead' => 0,
                                                                                               'line' => -357
                                                                                             }, 'Parse::RecDescent::Subrule' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'player',
                                                   'vars' => '',
                                                   'line' => -359
                                                 }, 'Parse::RecDescent::Rule' ),
                              'subject_locator' => bless( {
                                                            'impcount' => 0,
                                                            'calls' => [
                                                                         'iri'
                                                                       ],
                                                            'changed' => 0,
                                                            'opcount' => 0,
                                                            'prods' => [
                                                                         bless( {
                                                                                  'number' => '0',
                                                                                  'strcount' => 1,
                                                                                  'dircount' => 0,
                                                                                  'uncommit' => undef,
                                                                                  'error' => undef,
                                                                                  'patcount' => 0,
                                                                                  'actcount' => 1,
                                                                                  'items' => [
                                                                                               bless( {
                                                                                                        'pattern' => '=',
                                                                                                        'hashname' => '__STRING1__',
                                                                                                        'description' => '\'=\'',
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => -317
                                                                                                      }, 'Parse::RecDescent::Literal' ),
                                                                                               bless( {
                                                                                                        'subrule' => 'iri',
                                                                                                        'matchrule' => 0,
                                                                                                        'implicit' => undef,
                                                                                                        'argcode' => undef,
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => -317
                                                                                                      }, 'Parse::RecDescent::Subrule' ),
                                                                                               bless( {
                                                                                                        'hashname' => '__ACTION1__',
                                                                                                        'lookahead' => 0,
                                                                                                        'line' => -317,
                                                                                                        'code' => '{ $return = $item[2]; }'
                                                                                                      }, 'Parse::RecDescent::Action' )
                                                                                             ],
                                                                                  'line' => undef
                                                                                }, 'Parse::RecDescent::Production' )
                                                                       ],
                                                            'name' => 'subject_locator',
                                                            'vars' => '',
                                                            'line' => -317
                                                          }, 'Parse::RecDescent::Rule' ),
                              'restore_directive' => bless( {
                                                              'impcount' => 0,
                                                              'calls' => [],
                                                              'changed' => 0,
                                                              'opcount' => 0,
                                                              'prods' => [
                                                                           bless( {
                                                                                    'number' => '0',
                                                                                    'strcount' => 1,
                                                                                    'dircount' => 0,
                                                                                    'uncommit' => undef,
                                                                                    'error' => undef,
                                                                                    'patcount' => 0,
                                                                                    'actcount' => 1,
                                                                                    'items' => [
                                                                                                 bless( {
                                                                                                          'pattern' => '%restore',
                                                                                                          'hashname' => '__STRING1__',
                                                                                                          'description' => '\'%restore\'',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => -480
                                                                                                        }, 'Parse::RecDescent::Literal' ),
                                                                                                 bless( {
                                                                                                          'hashname' => '__ACTION1__',
                                                                                                          'lookahead' => 0,
                                                                                                          'line' => -480,
                                                                                                          'code' => '{
                                                                        %prefixes  = %prefixes_backup;
									%wildcards = %wildcards_backup;
							  	      }'
                                                                                                        }, 'Parse::RecDescent::Action' )
                                                                                               ],
                                                                                    'line' => undef
                                                                                  }, 'Parse::RecDescent::Production' )
                                                                         ],
                                                              'name' => 'restore_directive',
                                                              'vars' => '',
                                                              'line' => -480
                                                            }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_topicmap' => bless( {
                                                                                            'impcount' => 0,
                                                                                            'calls' => [
                                                                                                         'directive',
                                                                                                         'template',
                                                                                                         'template_invocation',
                                                                                                         'topic',
                                                                                                         'association'
                                                                                                       ],
                                                                                            'changed' => 0,
                                                                                            'opcount' => 0,
                                                                                            'prods' => [
                                                                                                         bless( {
                                                                                                                  'number' => '0',
                                                                                                                  'strcount' => 0,
                                                                                                                  'dircount' => 0,
                                                                                                                  'uncommit' => undef,
                                                                                                                  'error' => undef,
                                                                                                                  'patcount' => 0,
                                                                                                                  'actcount' => 0,
                                                                                                                  'items' => [
                                                                                                                               bless( {
                                                                                                                                        'subrule' => 'directive',
                                                                                                                                        'matchrule' => 0,
                                                                                                                                        'implicit' => undef,
                                                                                                                                        'argcode' => undef,
                                                                                                                                        'lookahead' => 0,
                                                                                                                                        'line' => 531
                                                                                                                                      }, 'Parse::RecDescent::Subrule' )
                                                                                                                             ],
                                                                                                                  'line' => undef
                                                                                                                }, 'Parse::RecDescent::Production' ),
                                                                                                         bless( {
                                                                                                                  'number' => '1',
                                                                                                                  'strcount' => 0,
                                                                                                                  'dircount' => 0,
                                                                                                                  'uncommit' => undef,
                                                                                                                  'error' => undef,
                                                                                                                  'patcount' => 0,
                                                                                                                  'actcount' => 0,
                                                                                                                  'items' => [
                                                                                                                               bless( {
                                                                                                                                        'subrule' => 'template',
                                                                                                                                        'matchrule' => 0,
                                                                                                                                        'implicit' => undef,
                                                                                                                                        'argcode' => undef,
                                                                                                                                        'lookahead' => 0,
                                                                                                                                        'line' => 532
                                                                                                                                      }, 'Parse::RecDescent::Subrule' )
                                                                                                                             ],
                                                                                                                  'line' => 532
                                                                                                                }, 'Parse::RecDescent::Production' ),
                                                                                                         bless( {
                                                                                                                  'number' => '2',
                                                                                                                  'strcount' => 0,
                                                                                                                  'dircount' => 0,
                                                                                                                  'uncommit' => undef,
                                                                                                                  'error' => undef,
                                                                                                                  'patcount' => 0,
                                                                                                                  'actcount' => 0,
                                                                                                                  'items' => [
                                                                                                                               bless( {
                                                                                                                                        'subrule' => 'template_invocation',
                                                                                                                                        'matchrule' => 0,
                                                                                                                                        'implicit' => undef,
                                                                                                                                        'argcode' => undef,
                                                                                                                                        'lookahead' => 0,
                                                                                                                                        'line' => 533
                                                                                                                                      }, 'Parse::RecDescent::Subrule' )
                                                                                                                             ],
                                                                                                                  'line' => 533
                                                                                                                }, 'Parse::RecDescent::Production' ),
                                                                                                         bless( {
                                                                                                                  'number' => '3',
                                                                                                                  'strcount' => 0,
                                                                                                                  'dircount' => 0,
                                                                                                                  'uncommit' => undef,
                                                                                                                  'error' => undef,
                                                                                                                  'patcount' => 0,
                                                                                                                  'actcount' => 0,
                                                                                                                  'items' => [
                                                                                                                               bless( {
                                                                                                                                        'subrule' => 'topic',
                                                                                                                                        'matchrule' => 0,
                                                                                                                                        'implicit' => undef,
                                                                                                                                        'argcode' => undef,
                                                                                                                                        'lookahead' => 0,
                                                                                                                                        'line' => 534
                                                                                                                                      }, 'Parse::RecDescent::Subrule' )
                                                                                                                             ],
                                                                                                                  'line' => 534
                                                                                                                }, 'Parse::RecDescent::Production' ),
                                                                                                         bless( {
                                                                                                                  'number' => '4',
                                                                                                                  'strcount' => 0,
                                                                                                                  'dircount' => 0,
                                                                                                                  'uncommit' => undef,
                                                                                                                  'error' => undef,
                                                                                                                  'patcount' => 0,
                                                                                                                  'actcount' => 0,
                                                                                                                  'items' => [
                                                                                                                               bless( {
                                                                                                                                        'subrule' => 'association',
                                                                                                                                        'matchrule' => 0,
                                                                                                                                        'implicit' => undef,
                                                                                                                                        'argcode' => undef,
                                                                                                                                        'lookahead' => 0,
                                                                                                                                        'line' => 535
                                                                                                                                      }, 'Parse::RecDescent::Subrule' )
                                                                                                                             ],
                                                                                                                  'line' => 535
                                                                                                                }, 'Parse::RecDescent::Production' )
                                                                                                       ],
                                                                                            'name' => '_alternation_1_of_production_1_of_rule_topicmap',
                                                                                            'vars' => '',
                                                                                            'line' => 531
                                                                                          }, 'Parse::RecDescent::Rule' ),
                              'basename' => bless( {
                                                     'impcount' => 0,
                                                     'calls' => [
                                                                  'string'
                                                                ],
                                                     'changed' => 0,
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'number' => '0',
                                                                           'strcount' => 0,
                                                                           'dircount' => 0,
                                                                           'uncommit' => undef,
                                                                           'error' => undef,
                                                                           'patcount' => 0,
                                                                           'actcount' => 1,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'subrule' => 'string',
                                                                                                 'matchrule' => 0,
                                                                                                 'implicit' => undef,
                                                                                                 'argcode' => undef,
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -102
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'lookahead' => 0,
                                                                                                 'line' => -102,
                                                                                                 'code' => '{ $return = new TM::Literal ($item[1], \'xsd:string\'); }'
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'basename',
                                                     'vars' => '',
                                                     'line' => -102
                                                   }, 'Parse::RecDescent::Rule' ),
                              'comment' => bless( {
                                                    'impcount' => 0,
                                                    'calls' => [],
                                                    'changed' => 0,
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => '0',
                                                                          'strcount' => 2,
                                                                          'dircount' => 0,
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 1,
                                                                          'actcount' => 0,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'pattern' => '/*',
                                                                                                'hashname' => '__STRING1__',
                                                                                                'description' => '\'/*\'',
                                                                                                'lookahead' => 0,
                                                                                                'line' => -62
                                                                                              }, 'Parse::RecDescent::Literal' ),
                                                                                       bless( {
                                                                                                'pattern' => '.+?',
                                                                                                'hashname' => '__PATTERN1__',
                                                                                                'description' => '/.+?/s',
                                                                                                'lookahead' => 0,
                                                                                                'rdelim' => '/',
                                                                                                'line' => -62,
                                                                                                'mod' => 's',
                                                                                                'ldelim' => '/'
                                                                                              }, 'Parse::RecDescent::Token' ),
                                                                                       bless( {
                                                                                                'pattern' => '*/',
                                                                                                'hashname' => '__STRING2__',
                                                                                                'description' => '\'*/\'',
                                                                                                'lookahead' => 0,
                                                                                                'line' => -62
                                                                                              }, 'Parse::RecDescent::Literal' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'comment',
                                                    'vars' => '',
                                                    'line' => -62
                                                  }, 'Parse::RecDescent::Rule' ),
                              'directive' => bless( {
                                                      'impcount' => 0,
                                                      'calls' => [
                                                                   'prefix_directive',
                                                                   'restore_directive',
                                                                   'backup_directive',
                                                                   'include_directive'
                                                                 ],
                                                      'changed' => 0,
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'number' => '0',
                                                                            'strcount' => 0,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 0,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'subrule' => 'prefix_directive',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => -496
                                                                                                }, 'Parse::RecDescent::Subrule' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => '1',
                                                                            'strcount' => 0,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 0,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'subrule' => 'restore_directive',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => -495
                                                                                                }, 'Parse::RecDescent::Subrule' )
                                                                                       ],
                                                                            'line' => -495
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => '2',
                                                                            'strcount' => 0,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 0,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'subrule' => 'backup_directive',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => -494
                                                                                                }, 'Parse::RecDescent::Subrule' )
                                                                                       ],
                                                                            'line' => -494
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => '3',
                                                                            'strcount' => 0,
                                                                            'dircount' => 0,
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 0,
                                                                            'actcount' => 0,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'subrule' => 'include_directive',
                                                                                                  'matchrule' => 0,
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => 0,
                                                                                                  'line' => -493
                                                                                                }, 'Parse::RecDescent::Subrule' )
                                                                                       ],
                                                                            'line' => -493
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'directive',
                                                      'vars' => '',
                                                      'line' => -496
                                                    }, 'Parse::RecDescent::Rule' )
                            }
               }, 'Parse::RecDescent' );
}