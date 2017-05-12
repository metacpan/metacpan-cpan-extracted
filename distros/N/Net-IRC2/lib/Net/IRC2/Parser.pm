package Net::IRC2::Parser;
use Parse::RecDescent;

{ my $ERRORS;


package Parse::RecDescent::Net::IRC2::Parser;
use strict;
use vars qw($skip $AUTOLOAD  );
$skip = '\s*';

    use Net::IRC2::Event    ;
    my $Event = undef       ;
    use vars qw( $VERSION ) ;
    $VERSION =              '0.23' ;
;


{
local $SIG{__WARN__} = sub {0};
# PRETEND TO BE IN Parse::RecDescent NAMESPACE
*Parse::RecDescent::Net::IRC2::Parser::AUTOLOAD	= sub
{
	no strict 'refs';
	$AUTOLOAD =~ s/^Parse::RecDescent::Net::IRC2::Parser/Parse::RecDescent/;
	goto &{$AUTOLOAD};
}
}

push @Parse::RecDescent::Net::IRC2::Parser::ISA, 'Parse::RecDescent';
# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::nick
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"nick"};
	
	Parse::RecDescent::_trace(q{Trying rule: [nick]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{nick},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/[\\w\\-\\\\\\[\\]\\`\\\{\\\}\\^\\|]+/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{nick},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{nick});
		%item = (__RULE__ => q{nick});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/[\\w\\-\\\\\\[\\]\\`\\\{\\\}\\^\\|]+/]}, Parse::RecDescent::_tracefirst($text),
					  q{nick},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:[\w\-\\\[\]\`\{\}\^\|]+)//)
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
		


		Parse::RecDescent::_trace(q{>>Matched production: [/[\\w\\-\\\\\\[\\]\\`\\\{\\\}\\^\\|]+/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{nick},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{nick},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{nick},
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
					  q{nick},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{nick},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::channel
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"channel"};
	
	Parse::RecDescent::_trace(q{Trying rule: [channel]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{channel},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['#', or '&' chstring]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{channel},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{channel});
		%item = (__RULE__ => q{channel});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_1_of_rule_channel]},
				  Parse::RecDescent::_tracefirst($text),
				  q{channel},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Net::IRC2::Parser::_alternation_1_of_production_1_of_rule_channel($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_1_of_rule_channel]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{channel},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_1_of_rule_channel]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{channel},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{_alternation_1_of_production_1_of_rule_channel}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [chstring]},
				  Parse::RecDescent::_tracefirst($text),
				  q{channel},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{chstring})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Net::IRC2::Parser::chstring($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [chstring]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{channel},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [chstring]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{channel},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{chstring}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: ['#', or '&' chstring]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{channel},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{channel},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{channel},
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
					  q{channel},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{channel},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::_alternation_1_of_production_2_of_rule_from
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_2_of_rule_from"};
	
	Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_2_of_rule_from]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{_alternation_1_of_production_2_of_rule_from},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['!' user]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_2_of_rule_from},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_2_of_rule_from});
		%item = (__RULE__ => q{_alternation_1_of_production_2_of_rule_from});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['!']},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_2_of_rule_from},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\!//)
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
		

		Parse::RecDescent::_trace(q{Trying subrule: [user]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_2_of_rule_from},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{user})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Net::IRC2::Parser::user($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [user]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_2_of_rule_from},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [user]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_2_of_rule_from},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{user}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: ['!' user]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_2_of_rule_from},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{_alternation_1_of_production_2_of_rule_from},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{_alternation_1_of_production_2_of_rule_from},
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
					  q{_alternation_1_of_production_2_of_rule_from},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{_alternation_1_of_production_2_of_rule_from},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::_alternation_1_of_production_2_of_rule_to
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_2_of_rule_to"};
	
	Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_2_of_rule_to]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{_alternation_1_of_production_2_of_rule_to},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [user '@' servername]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_2_of_rule_to},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_2_of_rule_to});
		%item = (__RULE__ => q{_alternation_1_of_production_2_of_rule_to});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [user]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_2_of_rule_to},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Net::IRC2::Parser::user($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [user]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_2_of_rule_to},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [user]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_2_of_rule_to},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{user}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: ['@']},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_2_of_rule_to},
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
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying subrule: [servername]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_1_of_production_2_of_rule_to},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{servername})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Net::IRC2::Parser::servername($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [servername]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_1_of_production_2_of_rule_to},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [servername]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_2_of_rule_to},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{servername}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [user '@' servername]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_2_of_rule_to},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{_alternation_1_of_production_2_of_rule_to},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{_alternation_1_of_production_2_of_rule_to},
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
					  q{_alternation_1_of_production_2_of_rule_to},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{_alternation_1_of_production_2_of_rule_to},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::special
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"special"};
	
	Parse::RecDescent::_trace(q{Trying rule: [special]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{special},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/^[\\\\\\-\\[\\]\\`\\^\\\{\\\}]/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{special},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{special});
		%item = (__RULE__ => q{special});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/^[\\\\\\-\\[\\]\\`\\^\\\{\\\}]/]}, Parse::RecDescent::_tracefirst($text),
					  q{special},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:^[\\\-\[\]\`\^\{\}])//)
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
		


		Parse::RecDescent::_trace(q{>>Matched production: [/^[\\\\\\-\\[\\]\\`\\^\\\{\\\}]/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{special},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{special},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{special},
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
					  q{special},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{special},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::to
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"to"};
	
	Parse::RecDescent::_trace(q{Trying rule: [to]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{to},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [channel]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{to},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{to});
		%item = (__RULE__ => q{to});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [channel]},
				  Parse::RecDescent::_tracefirst($text),
				  q{to},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Net::IRC2::Parser::channel($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [channel]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{to},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [channel]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{to},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{channel}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [channel]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{to},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [user]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{to},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{to});
		%item = (__RULE__ => q{to});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_2_of_rule_to]},
				  Parse::RecDescent::_tracefirst($text),
				  q{to},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Net::IRC2::Parser::_alternation_1_of_production_2_of_rule_to($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_2_of_rule_to]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{to},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_2_of_rule_to]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{to},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{_alternation_1_of_production_2_of_rule_to}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [user]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{to},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [nick]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{to},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[2];
		$text = $_[1];
		my $_savetext;
		@item = (q{to});
		%item = (__RULE__ => q{to});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [nick]},
				  Parse::RecDescent::_tracefirst($text),
				  q{to},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Net::IRC2::Parser::nick($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [nick]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{to},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [nick]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{to},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{nick}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [nick]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{to},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [mask]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{to},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[3];
		$text = $_[1];
		my $_savetext;
		@item = (q{to});
		%item = (__RULE__ => q{to});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [mask]},
				  Parse::RecDescent::_tracefirst($text),
				  q{to},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Net::IRC2::Parser::mask($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [mask]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{to},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [mask]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{to},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{mask}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [mask]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{to},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{to},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{to},
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
					  q{to},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{to},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::target
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"target"};
	
	Parse::RecDescent::_trace(q{Trying rule: [target]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{target},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [<leftop: to /,/ to>]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{target},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{target});
		%item = (__RULE__ => q{target});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying operator: [<leftop: to /,/ to>]},
				  Parse::RecDescent::_tracefirst($text),
				  q{target},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{})->at($text);

		$_tok = undef;
		OPLOOP: while (1)
		{
		  $repcount = 0;
		  my  @item;
		  
		  # MATCH LEFTARG
		  
		Parse::RecDescent::_trace(q{Trying subrule: [to]},
				  Parse::RecDescent::_tracefirst($text),
				  q{target},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{to})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Net::IRC2::Parser::to($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [to]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{target},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [to]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{target},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{to}} = $_tok;
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
					  q{target},
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
			if (defined $1) {push @item, $item{'to(s)'}=$1; $backtrack=1;}
			
		Parse::RecDescent::_trace(q{Trying subrule: [to]},
				  Parse::RecDescent::_tracefirst($text),
				  q{target},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{to})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Net::IRC2::Parser::to($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [to]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{target},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [to]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{target},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{to}} = $_tok;
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
			Parse::RecDescent::_trace(q{<<Didn't match operator: [<leftop: to /,/ to>]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{target},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched operator: [<leftop: to /,/ to>]<< (return value: [}
					  . qq{@{$_tok||[]}} . q{]},
					  Parse::RecDescent::_tracefirst($text),
					  q{target},
					  $tracelevel)
						if defined $::RD_TRACE;

		push @item, $item{'to(s)'}=$_tok||[];



		Parse::RecDescent::_trace(q{>>Matched production: [<leftop: to /,/ to>]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{target},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{target},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{target},
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
					  q{target},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{target},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::trailing
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"trailing"};
	
	Parse::RecDescent::_trace(q{Trying rule: [trailing]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{trailing},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/[^\\x00\\x0A\\x0D]+/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{trailing},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{trailing});
		%item = (__RULE__ => q{trailing});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/[^\\x00\\x0A\\x0D]+/]}, Parse::RecDescent::_tracefirst($text),
					  q{trailing},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:[^\x00\x0A\x0D]+)//)
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
		


		Parse::RecDescent::_trace(q{>>Matched production: [/[^\\x00\\x0A\\x0D]+/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{trailing},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{trailing},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{trailing},
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
					  q{trailing},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{trailing},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::from
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"from"};
	
	Parse::RecDescent::_trace(q{Trying rule: [from]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{from},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [servername]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{from},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{from});
		%item = (__RULE__ => q{from});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [servername]},
				  Parse::RecDescent::_tracefirst($text),
				  q{from},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Net::IRC2::Parser::servername($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [servername]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{from},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [servername]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{from},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{servername}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{from},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { 
	    $return = $Event->servername( $item[1] ) };
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
		


		Parse::RecDescent::_trace(q{>>Matched production: [servername]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{from},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [nick '!' '@']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{from},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{from});
		%item = (__RULE__ => q{from});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [nick]},
				  Parse::RecDescent::_tracefirst($text),
				  q{from},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Net::IRC2::Parser::nick($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [nick]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{from},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [nick]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{from},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{nick}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying repeated subrule: ['!']},
				  Parse::RecDescent::_tracefirst($text),
				  q{from},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{'!'})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Net::IRC2::Parser::_alternation_1_of_production_2_of_rule_from, 0, 1, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: ['!']>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{from},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [_alternation_1_of_production_2_of_rule_from]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{from},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{_alternation_1_of_production_2_of_rule_from(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying repeated subrule: ['@']},
				  Parse::RecDescent::_tracefirst($text),
				  q{from},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{'@'})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Net::IRC2::Parser::_alternation_2_of_production_2_of_rule_from, 0, 1, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: ['@']>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{from},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [_alternation_2_of_production_2_of_rule_from]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{from},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{_alternation_2_of_production_2_of_rule_from(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{from},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { 
	    $Event->nick( $item[1]    );
	    $Event->user( $item[2][0] );
	    $Event->host( $item[3][0] );
	    $return =     $item[1]                                 .
		      ( ( $item[2][0] ) ? '!' . $item[2][0] : '' ) .
		      ( ( $item[3][0] ) ? '@' . $item[3][0] : '' ) ;
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
		


		Parse::RecDescent::_trace(q{>>Matched production: [nick '!' '@']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{from},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{from},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{from},
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
					  q{from},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{from},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::user
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"user"};
	
	Parse::RecDescent::_trace(q{Trying rule: [user]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{user},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/^~?[\\.\\w\\-]+/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{user},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{user});
		%item = (__RULE__ => q{user});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/^~?[\\.\\w\\-]+/]}, Parse::RecDescent::_tracefirst($text),
					  q{user},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:^~?[\.\w\-]+)//)
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
		


		Parse::RecDescent::_trace(q{>>Matched production: [/^~?[\\.\\w\\-]+/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{user},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{user},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{user},
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
					  q{user},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{user},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::mask
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"mask"};
	
	Parse::RecDescent::_trace(q{Trying rule: [mask]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{mask},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['#', or '$' chstring]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{mask},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{mask});
		%item = (__RULE__ => q{mask});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_1_of_rule_mask]},
				  Parse::RecDescent::_tracefirst($text),
				  q{mask},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Net::IRC2::Parser::_alternation_1_of_production_1_of_rule_mask($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_1_of_rule_mask]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{mask},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_1_of_rule_mask]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{mask},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{_alternation_1_of_production_1_of_rule_mask}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [chstring]},
				  Parse::RecDescent::_tracefirst($text),
				  q{mask},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{chstring})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Net::IRC2::Parser::chstring($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [chstring]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{mask},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [chstring]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{mask},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{chstring}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: ['#', or '$' chstring]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{mask},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{mask},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{mask},
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
					  q{mask},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{mask},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::command
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"command"};
	
	Parse::RecDescent::_trace(q{Trying rule: [command]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{command},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/\\d\{3\}/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{command},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{command});
		%item = (__RULE__ => q{command});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/\\d\{3\}/]}, Parse::RecDescent::_tracefirst($text),
					  q{command},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:\d{3})//)
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
		


		Parse::RecDescent::_trace(q{>>Matched production: [/\\d\{3\}/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{command},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/[a-z]+/i]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{command},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{command});
		%item = (__RULE__ => q{command});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/[a-z]+/i]}, Parse::RecDescent::_tracefirst($text),
					  q{command},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:[a-z]+)//i)
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
					  q{command},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
               $Event->com_str( $item[1] );
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
		


		Parse::RecDescent::_trace(q{>>Matched production: [/[a-z]+/i]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{command},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{command},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{command},
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
					  q{command},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{command},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::middle
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"middle"};
	
	Parse::RecDescent::_trace(q{Trying rule: [middle]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{middle},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/[^\\:\\s\\x00\\x20\\x0A\\x0D]+/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{middle},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{middle});
		%item = (__RULE__ => q{middle});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/[^\\:\\s\\x00\\x20\\x0A\\x0D]+/]}, Parse::RecDescent::_tracefirst($text),
					  q{middle},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:[^\:\s\x00\x20\x0A\x0D]+)//)
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
		


		Parse::RecDescent::_trace(q{>>Matched production: [/[^\\:\\s\\x00\\x20\\x0A\\x0D]+/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{middle},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{middle},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{middle},
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
					  q{middle},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{middle},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::_alternation_1_of_production_1_of_rule_message
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_message"};
	
	Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_message]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{_alternation_1_of_production_1_of_rule_message},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [':']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_message},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_message});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_message});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [':']},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_message},
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
		


		Parse::RecDescent::_trace(q{>>Matched production: [':']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_message},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{_alternation_1_of_production_1_of_rule_message},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{_alternation_1_of_production_1_of_rule_message},
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
					  q{_alternation_1_of_production_1_of_rule_message},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{_alternation_1_of_production_1_of_rule_message},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::message
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"message"};
	
	Parse::RecDescent::_trace(q{Trying rule: [message]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{message},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [prefix command middle ':' trailing]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{message},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{message});
		%item = (__RULE__ => q{message});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{message},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { $Event = new Net::IRC2::Event( 'orig' => $text ) };
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
		

		Parse::RecDescent::_trace(q{Trying repeated subrule: [prefix]},
				  Parse::RecDescent::_tracefirst($text),
				  q{message},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{prefix})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Net::IRC2::Parser::prefix, 0, 1, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [prefix]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{message},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [prefix]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{message},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{prefix(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying subrule: [command]},
				  Parse::RecDescent::_tracefirst($text),
				  q{message},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{command})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Net::IRC2::Parser::command($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [command]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{message},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [command]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{message},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{command}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying repeated subrule: [middle]},
				  Parse::RecDescent::_tracefirst($text),
				  q{message},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{middle})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Net::IRC2::Parser::middle, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [middle]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{message},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [middle]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{message},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{middle(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying repeated subrule: [':']},
				  Parse::RecDescent::_tracefirst($text),
				  q{message},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{':'})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Net::IRC2::Parser::_alternation_1_of_production_1_of_rule_message, 0, 1, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [':']>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{message},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [_alternation_1_of_production_1_of_rule_message]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{message},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{_alternation_1_of_production_1_of_rule_message(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying repeated subrule: [trailing]},
				  Parse::RecDescent::_tracefirst($text),
				  q{message},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{trailing})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Net::IRC2::Parser::trailing, 0, 1, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [trailing]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{message},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [trailing]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{message},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{trailing(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{message},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
	   $Event->prefix(   $item{ 'prefix(?)' }[0] ) ;
	   $Event->command(  $item{  'command'  }    ) ;
	   $Event->middle(   $item{'middle(s?)' }    ) ;
	   $Event->trailing( $item{'trailing(?)'}    ) ;
	   $return = $Event;
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
		$item{__ACTION2__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [prefix command middle ':' trailing]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{message},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{message},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{message},
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
					  q{message},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{message},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::host
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"host"};
	
	Parse::RecDescent::_trace(q{Trying rule: [host]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{host},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/[\\w\\-\\.]+/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{host},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{host});
		%item = (__RULE__ => q{host});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/[\\w\\-\\.]+/]}, Parse::RecDescent::_tracefirst($text),
					  q{host},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:[\w\-\.]+)//)
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
		


		Parse::RecDescent::_trace(q{>>Matched production: [/[\\w\\-\\.]+/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{host},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{host},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{host},
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
					  q{host},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{host},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::chstring
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"chstring"};
	
	Parse::RecDescent::_trace(q{Trying rule: [chstring]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{chstring},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/^[^\\s ,\\x00 \\x0A \\x0D \\x07]+/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{chstring},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{chstring});
		%item = (__RULE__ => q{chstring});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/^[^\\s ,\\x00 \\x0A \\x0D \\x07]+/]}, Parse::RecDescent::_tracefirst($text),
					  q{chstring},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:^[^\s ,\x00 \x0A \x0D \x07]+)//)
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
		


		Parse::RecDescent::_trace(q{>>Matched production: [/^[^\\s ,\\x00 \\x0A \\x0D \\x07]+/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{chstring},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{chstring},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{chstring},
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
					  q{chstring},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{chstring},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::_alternation_1_of_production_1_of_rule_mask
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_mask"};
	
	Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_mask]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{_alternation_1_of_production_1_of_rule_mask},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['#']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_mask},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_mask});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_mask});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['#']},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_mask},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\#//)
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
		


		Parse::RecDescent::_trace(q{>>Matched production: ['#']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_mask},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['$']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_mask},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_mask});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_mask});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['$']},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_mask},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\$//)
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
		


		Parse::RecDescent::_trace(q{>>Matched production: ['$']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_mask},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{_alternation_1_of_production_1_of_rule_mask},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{_alternation_1_of_production_1_of_rule_mask},
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
					  q{_alternation_1_of_production_1_of_rule_mask},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{_alternation_1_of_production_1_of_rule_mask},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::servername
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"servername"};
	
	Parse::RecDescent::_trace(q{Trying rule: [servername]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{servername},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/[\\w\\.\\-]+ /]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{servername},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{servername});
		%item = (__RULE__ => q{servername});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/[\\w\\.\\-]+ /]}, Parse::RecDescent::_tracefirst($text),
					  q{servername},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:[\w\.\-]+ )//)
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
					  q{servername},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
	   chop $item[1] ;
	   $return = $item[1] ;
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
		


		Parse::RecDescent::_trace(q{>>Matched production: [/[\\w\\.\\-]+ /]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{servername},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{servername},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{servername},
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
					  q{servername},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{servername},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::nonwhite
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"nonwhite"};
	
	Parse::RecDescent::_trace(q{Trying rule: [nonwhite]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{nonwhite},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/^[^\\x20 \\x00 \\x0D \\x0A]/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{nonwhite},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{nonwhite});
		%item = (__RULE__ => q{nonwhite});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/^[^\\x20 \\x00 \\x0D \\x0A]/]}, Parse::RecDescent::_tracefirst($text),
					  q{nonwhite},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:^[^\x20 \x00 \x0D \x0A])//)
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
		


		Parse::RecDescent::_trace(q{>>Matched production: [/^[^\\x20 \\x00 \\x0D \\x0A]/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{nonwhite},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{nonwhite},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{nonwhite},
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
					  q{nonwhite},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{nonwhite},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::_alternation_1_of_production_1_of_rule_channel
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_channel"};
	
	Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_channel]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{_alternation_1_of_production_1_of_rule_channel},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['#']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_channel},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_channel});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_channel});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['#']},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_channel},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\#//)
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
		


		Parse::RecDescent::_trace(q{>>Matched production: ['#']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_channel},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['&']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_1_of_production_1_of_rule_channel},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_1_of_production_1_of_rule_channel});
		%item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_channel});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['&']},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_channel},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\&//)
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
		


		Parse::RecDescent::_trace(q{>>Matched production: ['&']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_1_of_production_1_of_rule_channel},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{_alternation_1_of_production_1_of_rule_channel},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{_alternation_1_of_production_1_of_rule_channel},
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
					  q{_alternation_1_of_production_1_of_rule_channel},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{_alternation_1_of_production_1_of_rule_channel},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::_alternation_2_of_production_2_of_rule_from
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"_alternation_2_of_production_2_of_rule_from"};
	
	Parse::RecDescent::_trace(q{Trying rule: [_alternation_2_of_production_2_of_rule_from]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{_alternation_2_of_production_2_of_rule_from},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['@' host]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{_alternation_2_of_production_2_of_rule_from},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{_alternation_2_of_production_2_of_rule_from});
		%item = (__RULE__ => q{_alternation_2_of_production_2_of_rule_from});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['@']},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_2_of_production_2_of_rule_from},
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
		

		Parse::RecDescent::_trace(q{Trying subrule: [host]},
				  Parse::RecDescent::_tracefirst($text),
				  q{_alternation_2_of_production_2_of_rule_from},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{host})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Net::IRC2::Parser::host($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [host]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{_alternation_2_of_production_2_of_rule_from},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [host]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_2_of_production_2_of_rule_from},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{host}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: ['@' host]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{_alternation_2_of_production_2_of_rule_from},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{_alternation_2_of_production_2_of_rule_from},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{_alternation_2_of_production_2_of_rule_from},
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
					  q{_alternation_2_of_production_2_of_rule_from},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{_alternation_2_of_production_2_of_rule_from},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Net::IRC2::Parser::prefix
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"prefix"};
	
	Parse::RecDescent::_trace(q{Trying rule: [prefix]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{prefix},
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
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [':' <commit> from]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{prefix},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{prefix});
		%item = (__RULE__ => q{prefix});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [':']},
					  Parse::RecDescent::_tracefirst($text),
					  q{prefix},
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
		

		

		Parse::RecDescent::_trace(q{Trying directive: [<commit>]},
					Parse::RecDescent::_tracefirst($text),
					  q{prefix},
					  $tracelevel)
						if defined $::RD_TRACE; 
		$_tok = do { $commit = 1 };
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
		

		Parse::RecDescent::_trace(q{Trying subrule: [from]},
				  Parse::RecDescent::_tracefirst($text),
				  q{prefix},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{from})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Net::IRC2::Parser::from($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [from]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{prefix},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [from]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{prefix},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{from}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{prefix},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { 
	    $return = $Event->from( ':' . $item{'from'} ) };
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
		


		Parse::RecDescent::_trace(q{>>Matched production: [':' <commit> from]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{prefix},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{prefix},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{prefix},
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
					  q{prefix},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{prefix},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}
}
package Net::IRC2::Parser; sub new { my $self = bless( {
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
                 'namespace' => 'Parse::RecDescent::Net::IRC2::Parser',
                 '_AUTOACTION' => undef,
                 'rules' => {
                              'nick' => bless( {
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
                                                                                             'pattern' => '[\\w\\-\\\\\\[\\]\\`\\{\\}\\^\\|]+',
                                                                                             'hashname' => '__PATTERN1__',
                                                                                             'description' => '/[\\\\w\\\\-\\\\\\\\\\\\[\\\\]\\\\`\\\\\\{\\\\\\}\\\\^\\\\|]+/',
                                                                                             'lookahead' => 0,
                                                                                             'rdelim' => '/',
                                                                                             'line' => 53,
                                                                                             'mod' => '',
                                                                                             'ldelim' => '/'
                                                                                           }, 'Parse::RecDescent::Token' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'nick',
                                                 'vars' => '',
                                                 'line' => 53
                                               }, 'Parse::RecDescent::Rule' ),
                              'channel' => bless( {
                                                    'impcount' => 1,
                                                    'calls' => [
                                                                 '_alternation_1_of_production_1_of_rule_channel',
                                                                 'chstring'
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
                                                                                                'subrule' => '_alternation_1_of_production_1_of_rule_channel',
                                                                                                'matchrule' => 0,
                                                                                                'implicit' => '\'#\', or \'&\'',
                                                                                                'argcode' => undef,
                                                                                                'lookahead' => 0,
                                                                                                'line' => 51
                                                                                              }, 'Parse::RecDescent::Subrule' ),
                                                                                       bless( {
                                                                                                'subrule' => 'chstring',
                                                                                                'matchrule' => 0,
                                                                                                'implicit' => undef,
                                                                                                'argcode' => undef,
                                                                                                'lookahead' => 0,
                                                                                                'line' => 51
                                                                                              }, 'Parse::RecDescent::Subrule' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'channel',
                                                    'vars' => '',
                                                    'line' => 51
                                                  }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_2_of_rule_from' => bless( {
                                                                                        'impcount' => 0,
                                                                                        'calls' => [
                                                                                                     'user'
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
                                                                                                                                    'pattern' => '!',
                                                                                                                                    'hashname' => '__STRING1__',
                                                                                                                                    'description' => '\'!\'',
                                                                                                                                    'lookahead' => 0,
                                                                                                                                    'line' => 61
                                                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                                                           bless( {
                                                                                                                                    'subrule' => 'user',
                                                                                                                                    'matchrule' => 0,
                                                                                                                                    'implicit' => undef,
                                                                                                                                    'argcode' => undef,
                                                                                                                                    'lookahead' => 0,
                                                                                                                                    'line' => 61
                                                                                                                                  }, 'Parse::RecDescent::Subrule' )
                                                                                                                         ],
                                                                                                              'line' => undef
                                                                                                            }, 'Parse::RecDescent::Production' )
                                                                                                   ],
                                                                                        'name' => '_alternation_1_of_production_2_of_rule_from',
                                                                                        'vars' => '',
                                                                                        'line' => 61
                                                                                      }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_2_of_rule_to' => bless( {
                                                                                      'impcount' => 0,
                                                                                      'calls' => [
                                                                                                   'user',
                                                                                                   'servername'
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
                                                                                                                                  'subrule' => 'user',
                                                                                                                                  'matchrule' => 0,
                                                                                                                                  'implicit' => undef,
                                                                                                                                  'argcode' => undef,
                                                                                                                                  'lookahead' => 0,
                                                                                                                                  'line' => 61
                                                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                                                         bless( {
                                                                                                                                  'pattern' => '@',
                                                                                                                                  'hashname' => '__STRING1__',
                                                                                                                                  'description' => '\'@\'',
                                                                                                                                  'lookahead' => 0,
                                                                                                                                  'line' => 61
                                                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                                                         bless( {
                                                                                                                                  'subrule' => 'servername',
                                                                                                                                  'matchrule' => 0,
                                                                                                                                  'implicit' => undef,
                                                                                                                                  'argcode' => undef,
                                                                                                                                  'lookahead' => 0,
                                                                                                                                  'line' => 61
                                                                                                                                }, 'Parse::RecDescent::Subrule' )
                                                                                                                       ],
                                                                                                            'line' => undef
                                                                                                          }, 'Parse::RecDescent::Production' )
                                                                                                 ],
                                                                                      'name' => '_alternation_1_of_production_2_of_rule_to',
                                                                                      'vars' => '',
                                                                                      'line' => 61
                                                                                    }, 'Parse::RecDescent::Rule' ),
                              'special' => bless( {
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
                                                                                                'pattern' => '^[\\\\\\-\\[\\]\\`\\^\\{\\}]',
                                                                                                'hashname' => '__PATTERN1__',
                                                                                                'description' => '/^[\\\\\\\\\\\\-\\\\[\\\\]\\\\`\\\\^\\\\\\{\\\\\\}]/',
                                                                                                'lookahead' => 0,
                                                                                                'rdelim' => '/',
                                                                                                'line' => 57,
                                                                                                'mod' => '',
                                                                                                'ldelim' => '/'
                                                                                              }, 'Parse::RecDescent::Token' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'special',
                                                    'vars' => '',
                                                    'line' => 57
                                                  }, 'Parse::RecDescent::Rule' ),
                              'to' => bless( {
                                               'impcount' => 0,
                                               'calls' => [
                                                            'channel',
                                                            '_alternation_1_of_production_2_of_rule_to',
                                                            'nick',
                                                            'mask'
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
                                                                                           'subrule' => 'channel',
                                                                                           'matchrule' => 0,
                                                                                           'implicit' => undef,
                                                                                           'argcode' => undef,
                                                                                           'lookahead' => 0,
                                                                                           'line' => 47
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
                                                                                           'subrule' => '_alternation_1_of_production_2_of_rule_to',
                                                                                           'matchrule' => 0,
                                                                                           'implicit' => 'user',
                                                                                           'argcode' => undef,
                                                                                           'lookahead' => 0,
                                                                                           'line' => 48
                                                                                         }, 'Parse::RecDescent::Subrule' )
                                                                                ],
                                                                     'line' => 48
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
                                                                                           'subrule' => 'nick',
                                                                                           'matchrule' => 0,
                                                                                           'implicit' => undef,
                                                                                           'argcode' => undef,
                                                                                           'lookahead' => 0,
                                                                                           'line' => 49
                                                                                         }, 'Parse::RecDescent::Subrule' )
                                                                                ],
                                                                     'line' => 49
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
                                                                                           'subrule' => 'mask',
                                                                                           'matchrule' => 0,
                                                                                           'implicit' => undef,
                                                                                           'argcode' => undef,
                                                                                           'lookahead' => 0,
                                                                                           'line' => 50
                                                                                         }, 'Parse::RecDescent::Subrule' )
                                                                                ],
                                                                     'line' => 50
                                                                   }, 'Parse::RecDescent::Production' )
                                                          ],
                                               'name' => 'to',
                                               'vars' => '',
                                               'line' => 47
                                             }, 'Parse::RecDescent::Rule' ),
                              'target' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'to'
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
                                                                                               'expected' => '<leftop: to /,/ to>',
                                                                                               'min' => 1,
                                                                                               'name' => '\'to(s)\'',
                                                                                               'max' => 100000000,
                                                                                               'leftarg' => bless( {
                                                                                                                     'subrule' => 'to',
                                                                                                                     'matchrule' => 0,
                                                                                                                     'implicit' => undef,
                                                                                                                     'argcode' => undef,
                                                                                                                     'lookahead' => 0,
                                                                                                                     'line' => 46
                                                                                                                   }, 'Parse::RecDescent::Subrule' ),
                                                                                               'rightarg' => bless( {
                                                                                                                      'subrule' => 'to',
                                                                                                                      'matchrule' => 0,
                                                                                                                      'implicit' => undef,
                                                                                                                      'argcode' => undef,
                                                                                                                      'lookahead' => 0,
                                                                                                                      'line' => 46
                                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                               'hashname' => '__DIRECTIVE1__',
                                                                                               'type' => 'leftop',
                                                                                               'op' => bless( {
                                                                                                                'pattern' => ',',
                                                                                                                'hashname' => '__PATTERN1__',
                                                                                                                'description' => '/,/',
                                                                                                                'lookahead' => 0,
                                                                                                                'rdelim' => '/',
                                                                                                                'line' => 46,
                                                                                                                'mod' => '',
                                                                                                                'ldelim' => '/'
                                                                                                              }, 'Parse::RecDescent::Token' )
                                                                                             }, 'Parse::RecDescent::Operator' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'target',
                                                   'vars' => '',
                                                   'line' => 46
                                                 }, 'Parse::RecDescent::Rule' ),
                              'trailing' => bless( {
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
                                                                                                 'pattern' => '[^\\x00\\x0A\\x0D]+',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/[^\\\\x00\\\\x0A\\\\x0D]+/',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => 45,
                                                                                                 'mod' => '',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'trailing',
                                                     'vars' => '',
                                                     'line' => 45
                                                   }, 'Parse::RecDescent::Rule' ),
                              'from' => bless( {
                                                 'impcount' => 2,
                                                 'calls' => [
                                                              'servername',
                                                              'nick',
                                                              '_alternation_1_of_production_2_of_rule_from',
                                                              '_alternation_2_of_production_2_of_rule_from'
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
                                                                                             'subrule' => 'servername',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => 22
                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                    bless( {
                                                                                             'hashname' => '__ACTION1__',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 23,
                                                                                             'code' => '{ 
	    $return = $Event->servername( $item[1] ) }'
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
                                                                                             'subrule' => 'nick',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => 25
                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                    bless( {
                                                                                             'subrule' => '_alternation_1_of_production_2_of_rule_from',
                                                                                             'expected' => '\'!\'',
                                                                                             'min' => 0,
                                                                                             'argcode' => undef,
                                                                                             'max' => 1,
                                                                                             'matchrule' => 0,
                                                                                             'repspec' => '?',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 25
                                                                                           }, 'Parse::RecDescent::Repetition' ),
                                                                                    bless( {
                                                                                             'subrule' => '_alternation_2_of_production_2_of_rule_from',
                                                                                             'expected' => '\'@\'',
                                                                                             'min' => 0,
                                                                                             'argcode' => undef,
                                                                                             'max' => 1,
                                                                                             'matchrule' => 0,
                                                                                             'repspec' => '?',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 25
                                                                                           }, 'Parse::RecDescent::Repetition' ),
                                                                                    bless( {
                                                                                             'hashname' => '__ACTION1__',
                                                                                             'lookahead' => 0,
                                                                                             'line' => 26,
                                                                                             'code' => '{ 
	    $Event->nick( $item[1]    );
	    $Event->user( $item[2][0] );
	    $Event->host( $item[3][0] );
	    $return =     $item[1]                                 .
		      ( ( $item[2][0] ) ? \'!\' . $item[2][0] : \'\' ) .
		      ( ( $item[3][0] ) ? \'@\' . $item[3][0] : \'\' ) ;
	}'
                                                                                           }, 'Parse::RecDescent::Action' )
                                                                                  ],
                                                                       'line' => 25
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'from',
                                                 'vars' => '',
                                                 'line' => 22
                                               }, 'Parse::RecDescent::Rule' ),
                              'user' => bless( {
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
                                                                                             'pattern' => '^~?[\\.\\w\\-]+',
                                                                                             'hashname' => '__PATTERN1__',
                                                                                             'description' => '/^~?[\\\\.\\\\w\\\\-]+/',
                                                                                             'lookahead' => 0,
                                                                                             'rdelim' => '/',
                                                                                             'line' => 56,
                                                                                             'mod' => '',
                                                                                             'ldelim' => '/'
                                                                                           }, 'Parse::RecDescent::Token' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'user',
                                                 'vars' => '',
                                                 'line' => 56
                                               }, 'Parse::RecDescent::Rule' ),
                              'mask' => bless( {
                                                 'impcount' => 1,
                                                 'calls' => [
                                                              '_alternation_1_of_production_1_of_rule_mask',
                                                              'chstring'
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
                                                                                             'subrule' => '_alternation_1_of_production_1_of_rule_mask',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => '\'#\', or \'$\'',
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => 54
                                                                                           }, 'Parse::RecDescent::Subrule' ),
                                                                                    bless( {
                                                                                             'subrule' => 'chstring',
                                                                                             'matchrule' => 0,
                                                                                             'implicit' => undef,
                                                                                             'argcode' => undef,
                                                                                             'lookahead' => 0,
                                                                                             'line' => 54
                                                                                           }, 'Parse::RecDescent::Subrule' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'mask',
                                                 'vars' => '',
                                                 'line' => 54
                                               }, 'Parse::RecDescent::Rule' ),
                              'command' => bless( {
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
                                                                                                'pattern' => '\\d{3}',
                                                                                                'hashname' => '__PATTERN1__',
                                                                                                'description' => '/\\\\d\\{3\\}/',
                                                                                                'lookahead' => 0,
                                                                                                'rdelim' => '/',
                                                                                                'line' => 39,
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
                                                                          'patcount' => 1,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'pattern' => '[a-z]+',
                                                                                                'hashname' => '__PATTERN1__',
                                                                                                'description' => '/[a-z]+/i',
                                                                                                'lookahead' => 0,
                                                                                                'rdelim' => '/',
                                                                                                'line' => 40,
                                                                                                'mod' => 'i',
                                                                                                'ldelim' => '/'
                                                                                              }, 'Parse::RecDescent::Token' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 41,
                                                                                                'code' => '{
               $Event->com_str( $item[1] );
	   }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => 40
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'command',
                                                    'vars' => '',
                                                    'line' => 39
                                                  }, 'Parse::RecDescent::Rule' ),
                              'middle' => bless( {
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
                                                                                               'pattern' => '[^\\:\\s\\x00\\x20\\x0A\\x0D]+',
                                                                                               'hashname' => '__PATTERN1__',
                                                                                               'description' => '/[^\\\\:\\\\s\\\\x00\\\\x20\\\\x0A\\\\x0D]+/',
                                                                                               'lookahead' => 0,
                                                                                               'rdelim' => '/',
                                                                                               'line' => 44,
                                                                                               'mod' => '',
                                                                                               'ldelim' => '/'
                                                                                             }, 'Parse::RecDescent::Token' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'middle',
                                                   'vars' => '',
                                                   'line' => 44
                                                 }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_message' => bless( {
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
                                                                                                                                       'pattern' => ':',
                                                                                                                                       'hashname' => '__STRING1__',
                                                                                                                                       'description' => '\':\'',
                                                                                                                                       'lookahead' => 0,
                                                                                                                                       'line' => 61
                                                                                                                                     }, 'Parse::RecDescent::Literal' )
                                                                                                                            ],
                                                                                                                 'line' => undef
                                                                                                               }, 'Parse::RecDescent::Production' )
                                                                                                      ],
                                                                                           'name' => '_alternation_1_of_production_1_of_rule_message',
                                                                                           'vars' => '',
                                                                                           'line' => 61
                                                                                         }, 'Parse::RecDescent::Rule' ),
                              'message' => bless( {
                                                    'impcount' => 1,
                                                    'calls' => [
                                                                 'prefix',
                                                                 'command',
                                                                 'middle',
                                                                 '_alternation_1_of_production_1_of_rule_message',
                                                                 'trailing'
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
                                                                          'actcount' => 2,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 9,
                                                                                                'code' => '{ $Event = new Net::IRC2::Event( \'orig\' => $text ) }'
                                                                                              }, 'Parse::RecDescent::Action' ),
                                                                                       bless( {
                                                                                                'subrule' => 'prefix',
                                                                                                'expected' => undef,
                                                                                                'min' => 0,
                                                                                                'argcode' => undef,
                                                                                                'max' => 1,
                                                                                                'matchrule' => 0,
                                                                                                'repspec' => '?',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 10
                                                                                              }, 'Parse::RecDescent::Repetition' ),
                                                                                       bless( {
                                                                                                'subrule' => 'command',
                                                                                                'matchrule' => 0,
                                                                                                'implicit' => undef,
                                                                                                'argcode' => undef,
                                                                                                'lookahead' => 0,
                                                                                                'line' => 10
                                                                                              }, 'Parse::RecDescent::Subrule' ),
                                                                                       bless( {
                                                                                                'subrule' => 'middle',
                                                                                                'expected' => undef,
                                                                                                'min' => 0,
                                                                                                'argcode' => undef,
                                                                                                'max' => 100000000,
                                                                                                'matchrule' => 0,
                                                                                                'repspec' => 's?',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 10
                                                                                              }, 'Parse::RecDescent::Repetition' ),
                                                                                       bless( {
                                                                                                'subrule' => '_alternation_1_of_production_1_of_rule_message',
                                                                                                'expected' => '\':\'',
                                                                                                'min' => 0,
                                                                                                'argcode' => undef,
                                                                                                'max' => 1,
                                                                                                'matchrule' => 0,
                                                                                                'repspec' => '?',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 10
                                                                                              }, 'Parse::RecDescent::Repetition' ),
                                                                                       bless( {
                                                                                                'subrule' => 'trailing',
                                                                                                'expected' => undef,
                                                                                                'min' => 0,
                                                                                                'argcode' => undef,
                                                                                                'max' => 1,
                                                                                                'matchrule' => 0,
                                                                                                'repspec' => '?',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 10
                                                                                              }, 'Parse::RecDescent::Repetition' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION2__',
                                                                                                'lookahead' => 0,
                                                                                                'line' => 11,
                                                                                                'code' => '{
	   $Event->prefix(   $item{ \'prefix(?)\' }[0] ) ;
	   $Event->command(  $item{  \'command\'  }    ) ;
	   $Event->middle(   $item{\'middle(s?)\' }    ) ;
	   $Event->trailing( $item{\'trailing(?)\'}    ) ;
	   $return = $Event;
        }'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'message',
                                                    'vars' => '',
                                                    'line' => 8
                                                  }, 'Parse::RecDescent::Rule' ),
                              'host' => bless( {
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
                                                                                             'pattern' => '[\\w\\-\\.]+',
                                                                                             'hashname' => '__PATTERN1__',
                                                                                             'description' => '/[\\\\w\\\\-\\\\.]+/',
                                                                                             'lookahead' => 0,
                                                                                             'rdelim' => '/',
                                                                                             'line' => 52,
                                                                                             'mod' => '',
                                                                                             'ldelim' => '/'
                                                                                           }, 'Parse::RecDescent::Token' )
                                                                                  ],
                                                                       'line' => undef
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'name' => 'host',
                                                 'vars' => '',
                                                 'line' => 52
                                               }, 'Parse::RecDescent::Rule' ),
                              'chstring' => bless( {
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
                                                                                                 'pattern' => '^[^\\s ,\\x00 \\x0A \\x0D \\x07]+',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/^[^\\\\s ,\\\\x00 \\\\x0A \\\\x0D \\\\x07]+/',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => 55,
                                                                                                 'mod' => '',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'chstring',
                                                     'vars' => '',
                                                     'line' => 55
                                                   }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_mask' => bless( {
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
                                                                                                                                    'pattern' => '#',
                                                                                                                                    'hashname' => '__STRING1__',
                                                                                                                                    'description' => '\'#\'',
                                                                                                                                    'lookahead' => 0,
                                                                                                                                    'line' => 61
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
                                                                                                                                    'pattern' => '$',
                                                                                                                                    'hashname' => '__STRING1__',
                                                                                                                                    'description' => '\'$\'',
                                                                                                                                    'lookahead' => 0,
                                                                                                                                    'line' => 61
                                                                                                                                  }, 'Parse::RecDescent::Literal' )
                                                                                                                         ],
                                                                                                              'line' => 61
                                                                                                            }, 'Parse::RecDescent::Production' )
                                                                                                   ],
                                                                                        'name' => '_alternation_1_of_production_1_of_rule_mask',
                                                                                        'vars' => '',
                                                                                        'line' => 61
                                                                                      }, 'Parse::RecDescent::Rule' ),
                              'servername' => bless( {
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
                                                                                                   'pattern' => '[\\w\\.\\-]+ ',
                                                                                                   'hashname' => '__PATTERN1__',
                                                                                                   'description' => '/[\\\\w\\\\.\\\\-]+ /',
                                                                                                   'lookahead' => 0,
                                                                                                   'rdelim' => '/',
                                                                                                   'line' => 34,
                                                                                                   'mod' => '',
                                                                                                   'ldelim' => '/'
                                                                                                 }, 'Parse::RecDescent::Token' ),
                                                                                          bless( {
                                                                                                   'hashname' => '__ACTION1__',
                                                                                                   'lookahead' => 0,
                                                                                                   'line' => 35,
                                                                                                   'code' => '{
	   chop $item[1] ;
	   $return = $item[1] ;
       }'
                                                                                                 }, 'Parse::RecDescent::Action' )
                                                                                        ],
                                                                             'line' => undef
                                                                           }, 'Parse::RecDescent::Production' )
                                                                  ],
                                                       'name' => 'servername',
                                                       'vars' => '',
                                                       'line' => 34
                                                     }, 'Parse::RecDescent::Rule' ),
                              'nonwhite' => bless( {
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
                                                                                                 'pattern' => '^[^\\x20 \\x00 \\x0D \\x0A]',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'description' => '/^[^\\\\x20 \\\\x00 \\\\x0D \\\\x0A]/',
                                                                                                 'lookahead' => 0,
                                                                                                 'rdelim' => '/',
                                                                                                 'line' => 58,
                                                                                                 'mod' => '',
                                                                                                 'ldelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' )
                                                                                      ],
                                                                           'line' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'name' => 'nonwhite',
                                                     'vars' => '',
                                                     'line' => 58
                                                   }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_channel' => bless( {
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
                                                                                                                                       'pattern' => '#',
                                                                                                                                       'hashname' => '__STRING1__',
                                                                                                                                       'description' => '\'#\'',
                                                                                                                                       'lookahead' => 0,
                                                                                                                                       'line' => 61
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
                                                                                                                                       'pattern' => '&',
                                                                                                                                       'hashname' => '__STRING1__',
                                                                                                                                       'description' => '\'&\'',
                                                                                                                                       'lookahead' => 0,
                                                                                                                                       'line' => 61
                                                                                                                                     }, 'Parse::RecDescent::Literal' )
                                                                                                                            ],
                                                                                                                 'line' => 61
                                                                                                               }, 'Parse::RecDescent::Production' )
                                                                                                      ],
                                                                                           'name' => '_alternation_1_of_production_1_of_rule_channel',
                                                                                           'vars' => '',
                                                                                           'line' => 61
                                                                                         }, 'Parse::RecDescent::Rule' ),
                              '_alternation_2_of_production_2_of_rule_from' => bless( {
                                                                                        'impcount' => 0,
                                                                                        'calls' => [
                                                                                                     'host'
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
                                                                                                                                    'pattern' => '@',
                                                                                                                                    'hashname' => '__STRING1__',
                                                                                                                                    'description' => '\'@\'',
                                                                                                                                    'lookahead' => 0,
                                                                                                                                    'line' => 61
                                                                                                                                  }, 'Parse::RecDescent::Literal' ),
                                                                                                                           bless( {
                                                                                                                                    'subrule' => 'host',
                                                                                                                                    'matchrule' => 0,
                                                                                                                                    'implicit' => undef,
                                                                                                                                    'argcode' => undef,
                                                                                                                                    'lookahead' => 0,
                                                                                                                                    'line' => 61
                                                                                                                                  }, 'Parse::RecDescent::Subrule' )
                                                                                                                         ],
                                                                                                              'line' => undef
                                                                                                            }, 'Parse::RecDescent::Production' )
                                                                                                   ],
                                                                                        'name' => '_alternation_2_of_production_2_of_rule_from',
                                                                                        'vars' => '',
                                                                                        'line' => 61
                                                                                      }, 'Parse::RecDescent::Rule' ),
                              'prefix' => bless( {
                                                   'impcount' => 0,
                                                   'calls' => [
                                                                'from'
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
                                                                         'actcount' => 1,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'pattern' => ':',
                                                                                               'hashname' => '__STRING1__',
                                                                                               'description' => '\':\'',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 18
                                                                                             }, 'Parse::RecDescent::Literal' ),
                                                                                      bless( {
                                                                                               'hashname' => '__DIRECTIVE1__',
                                                                                               'name' => '<commit>',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 18,
                                                                                               'code' => '$commit = 1'
                                                                                             }, 'Parse::RecDescent::Directive' ),
                                                                                      bless( {
                                                                                               'subrule' => 'from',
                                                                                               'matchrule' => 0,
                                                                                               'implicit' => undef,
                                                                                               'argcode' => undef,
                                                                                               'lookahead' => 0,
                                                                                               'line' => 18
                                                                                             }, 'Parse::RecDescent::Subrule' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => 0,
                                                                                               'line' => 19,
                                                                                               'code' => '{ 
	    $return = $Event->from( \':\' . $item{\'from\'} ) }'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'prefix',
                                                   'vars' => '',
                                                   'line' => 18
                                                 }, 'Parse::RecDescent::Rule' )
                            }
               }, 'Parse::RecDescent' );
}