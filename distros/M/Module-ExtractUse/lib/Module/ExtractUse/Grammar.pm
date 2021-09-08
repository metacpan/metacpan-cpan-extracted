#
# This parser was generated with
# Parse::RecDescent version 1.967013
#

package Module::ExtractUse::Grammar;
use Parse::RecDescent;
{ my $ERRORS;


package Parse::RecDescent::Module::ExtractUse::Grammar;
use strict;
use vars qw($skip $AUTOLOAD  );
@Parse::RecDescent::Module::ExtractUse::Grammar::ISA = ();
$skip = '\\s*';



{
local $SIG{__WARN__} = sub {0};
# PRETEND TO BE IN Parse::RecDescent NAMESPACE
*Parse::RecDescent::Module::ExtractUse::Grammar::AUTOLOAD   = sub
{
    no strict 'refs';

    ${"AUTOLOAD"} =~ s/^Parse::RecDescent::Module::ExtractUse::Grammar/Parse::RecDescent/;
    goto &{${"AUTOLOAD"}};
}
}

push @Parse::RecDescent::Module::ExtractUse::Grammar::ISA, 'Parse::RecDescent';
# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load"};

    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'Class::Load::'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['Class::Load::' class_load_functions]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['Class::Load::']},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\AClass\:\:Load\:\:/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [class_load_functions]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{class_load_functions})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::class_load_functions($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [class_load_functions]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [class_load_functions]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{class_load_functions}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: ['Class::Load::' class_load_functions]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load},
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
                      q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use"};

    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'Module::Runtime::'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['Module::Runtime::' module_runtime_use_fcn '(']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['Module::Runtime::']},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\AModule\:\:Runtime\:\:/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [module_runtime_use_fcn]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{module_runtime_use_fcn})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::module_runtime_use_fcn($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [module_runtime_use_fcn]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [module_runtime_use_fcn]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{module_runtime_use_fcn}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: ['(']},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{'('})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\(/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING2__}=$current_match;
        

        Parse::RecDescent::_trace(q{>>Matched production: ['Module::Runtime::' module_runtime_use_fcn '(']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
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
                      q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_class_load
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_class_load"};

    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_class_load]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule_class_load},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'Class::Load::', or /\\b/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['Class::Load::']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_class_load});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_class_load});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_class_load},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_class_load},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: ['Class::Load::']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\b/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_class_load});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_class_load});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_class_load},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_class_load},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [/\\b/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule_class_load},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule_class_load},
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
                      q{_alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_class_load_first_existing
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_class_load_first_existing"};

    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_class_load_first_existing]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule_class_load_first_existing},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'Class::Load::load_first_existing_class', or /\\bload_first_existing_class/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['Class::Load::load_first_existing_class']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_class_load_first_existing},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_class_load_first_existing});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_class_load_first_existing});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['Class::Load::load_first_existing_class']},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_class_load_first_existing},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\AClass\:\:Load\:\:load_first_existing_class/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{>>Matched production: ['Class::Load::load_first_existing_class']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_class_load_first_existing},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\bload_first_existing_class/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_class_load_first_existing},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_class_load_first_existing});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_class_load_first_existing});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/\\bload_first_existing_class/]}, Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_class_load_first_existing},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\bload_first_existing_class)/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{>>Matched production: [/\\bload_first_existing_class/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_class_load_first_existing},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule_class_load_first_existing},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule_class_load_first_existing},
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
                      q{_alternation_1_of_production_1_of_rule_class_load_first_existing},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule_class_load_first_existing},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_comma
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_comma"};

    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_comma]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule_comma},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{',', or '=>'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [',']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_comma},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_comma});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_comma});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [',']},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_comma},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\,/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{>>Matched production: [',']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_comma},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['=>']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_comma},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_comma});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_comma});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['=>']},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_comma},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\=\>/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{>>Matched production: ['=>']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_comma},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule_comma},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule_comma},
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
                      q{_alternation_1_of_production_1_of_rule_comma},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule_comma},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_hash_pair
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_hash_pair"};

    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_hash_pair]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule_hash_pair},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/[^\\s,\}]+/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<perl_quotelike>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_hash_pair},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_hash_pair});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_hash_pair});
        my $repcount = 0;


        

        Parse::RecDescent::_trace(q{Trying directive: [<perl_quotelike>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_hash_pair},
                      $tracelevel)
                        if defined $::RD_TRACE; 
        $_tok = do { my ($match,@res);
                     ($match,$text,undef,@res) =
                          Text::Balanced::extract_quotelike($text,$skip);
                      $match ? \@res : undef;
                     };
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
        

        Parse::RecDescent::_trace(q{>>Matched production: [<perl_quotelike>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_hash_pair},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/[^\\s,\}]+/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_hash_pair},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_hash_pair});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_hash_pair});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/[^\\s,\}]+/]}, Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_hash_pair},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[^\s,}]+)/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{>>Matched production: [/[^\\s,\}]+/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_hash_pair},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule_hash_pair},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule_hash_pair},
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
                      q{_alternation_1_of_production_1_of_rule_hash_pair},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule_hash_pair},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_module_runtime_require_module
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_module_runtime_require_module"};

    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_module_runtime_require_module]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule_module_runtime_require_module},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'Module::Runtime::require_module(', or /\\brequire_module\\(/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['Module::Runtime::require_module(']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_module_runtime_require_module},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_module_runtime_require_module});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_module_runtime_require_module});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['Module::Runtime::require_module(']},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_module_runtime_require_module},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\AModule\:\:Runtime\:\:require_module\(/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{>>Matched production: ['Module::Runtime::require_module(']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_module_runtime_require_module},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\brequire_module\\(/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_module_runtime_require_module},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_module_runtime_require_module});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_module_runtime_require_module});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/\\brequire_module\\(/]}, Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_module_runtime_require_module},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\brequire_module\()/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{>>Matched production: [/\\brequire_module\\(/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_module_runtime_require_module},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule_module_runtime_require_module},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule_module_runtime_require_module},
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
                      q{_alternation_1_of_production_1_of_rule_module_runtime_require_module},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule_module_runtime_require_module},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_module_runtime_use
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_module_runtime_use"};

    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_module_runtime_use]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule_module_runtime_use},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'Module::Runtime::', or /\\b/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['Module::Runtime::']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_module_runtime_use});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_module_runtime_use});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_module_runtime_use},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_module_runtime_use},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: ['Module::Runtime::']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\b/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_module_runtime_use});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_module_runtime_use});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_module_runtime_use},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_module_runtime_use},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [/\\b/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule_module_runtime_use},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule_module_runtime_use},
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
                      q{_alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_module_runtime_use_fcn
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_module_runtime_use_fcn"};

    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_module_runtime_use_fcn]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule_module_runtime_use_fcn},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'use_module', or 'use_package_optimistically'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['use_module']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_module_runtime_use_fcn},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_module_runtime_use_fcn});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_module_runtime_use_fcn});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['use_module']},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_module_runtime_use_fcn},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\Ause_module/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{>>Matched production: ['use_module']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_module_runtime_use_fcn},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['use_package_optimistically']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_module_runtime_use_fcn},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_module_runtime_use_fcn});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_module_runtime_use_fcn});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['use_package_optimistically']},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_module_runtime_use_fcn},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\Ause_package_optimistically/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{>>Matched production: ['use_package_optimistically']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_module_runtime_use_fcn},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule_module_runtime_use_fcn},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule_module_runtime_use_fcn},
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
                      q{_alternation_1_of_production_1_of_rule_module_runtime_use_fcn},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule_module_runtime_use_fcn},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_no_stuff
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_no_stuff"};

    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_no_stuff]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule_no_stuff},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{base, or version, or module});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [base]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_no_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_no_stuff});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_no_stuff});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [base]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_no_stuff},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::base($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [base]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_no_stuff},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [base]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_no_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{base}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [base]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_no_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [version]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_no_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_no_stuff});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_no_stuff});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [version]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_no_stuff},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::version($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [version]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_no_stuff},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [version]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_no_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{version}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [version]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_no_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [module]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_no_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_no_stuff});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_no_stuff});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [module]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_no_stuff},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::module($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [module]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_no_stuff},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [module]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_no_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{module}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [module]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_no_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule_no_stuff},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule_no_stuff},
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
                      q{_alternation_1_of_production_1_of_rule_no_stuff},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule_no_stuff},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_require_stuff
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_require_stuff"};

    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_require_stuff]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule_require_stuff},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{version, or require_name, or module});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [version]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_require_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_require_stuff});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_require_stuff});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [version]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_require_stuff},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::version($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [version]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_require_stuff},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [version]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_require_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{version}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [version]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_require_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [require_name]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_require_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_require_stuff});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_require_stuff});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [require_name]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_require_stuff},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::require_name($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [require_name]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_require_stuff},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [require_name]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_require_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{require_name}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [require_name]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_require_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [module]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_require_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_require_stuff});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_require_stuff});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [module]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_require_stuff},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::module($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [module]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_require_stuff},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [module]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_require_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{module}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [module]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_require_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule_require_stuff},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule_require_stuff},
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
                      q{_alternation_1_of_production_1_of_rule_require_stuff},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule_require_stuff},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_use_stuff
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_1_of_rule_use_stuff"};

    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_1_of_rule_use_stuff]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_1_of_rule_use_stuff},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{base, or parent, or version, or module});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [base]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_use_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_use_stuff});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_use_stuff});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [base]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_use_stuff},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::base($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [base]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_use_stuff},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [base]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_use_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{base}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [base]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_use_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [parent]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_use_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_use_stuff});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_use_stuff});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [parent]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_use_stuff},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::parent($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [parent]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_use_stuff},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [parent]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_use_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{parent}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [parent]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_use_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [version]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_use_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_use_stuff});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_use_stuff});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [version]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_use_stuff},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::version($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [version]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_use_stuff},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [version]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_use_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{version}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [version]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_use_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [module]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_1_of_rule_use_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[3];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_1_of_rule_use_stuff});
        %item = (__RULE__ => q{_alternation_1_of_production_1_of_rule_use_stuff});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [module]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_1_of_rule_use_stuff},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::module($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [module]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_1_of_rule_use_stuff},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [module]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_use_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{module}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [module]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_1_of_rule_use_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_1_of_rule_use_stuff},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_1_of_rule_use_stuff},
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
                      q{_alternation_1_of_production_1_of_rule_use_stuff},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_1_of_rule_use_stuff},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load"};

    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/\\b/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\b/ class_load_functions]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load});
        %item = (__RULE__ => q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/\\b/]}, Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\b)/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [class_load_functions]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{class_load_functions})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::class_load_functions($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [class_load_functions]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [class_load_functions]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{class_load_functions}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [/\\b/ class_load_functions]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load},
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
                      q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use"};

    Parse::RecDescent::_trace(q{Trying rule: [_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/\\b/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\b/ module_runtime_use_fcn '(']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use});
        %item = (__RULE__ => q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/\\b/]}, Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\b)/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [module_runtime_use_fcn]},
                  Parse::RecDescent::_tracefirst($text),
                  q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{module_runtime_use_fcn})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::module_runtime_use_fcn($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [module_runtime_use_fcn]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [module_runtime_use_fcn]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{module_runtime_use_fcn}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: ['(']},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{'('})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\(/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{>>Matched production: [/\\b/ module_runtime_use_fcn '(']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
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
                      q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::base
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"base"};

    Parse::RecDescent::_trace(q{Trying rule: [base]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{base},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'base'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['base' import_list]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{base},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{base});
        %item = (__RULE__ => q{base});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['base']},
                      Parse::RecDescent::_tracefirst($text),
                      q{base},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   do { $_tok = "base"; 1 } and
             substr($text,0,length($_tok)) eq $_tok and
             do { substr($text,0,length($_tok)) = ""; 1; }
        )
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $_tok . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$_tok;
        

        Parse::RecDescent::_trace(q{Trying subrule: [import_list]},
                  Parse::RecDescent::_tracefirst($text),
                  q{base},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{import_list})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::import_list($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [import_list]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{base},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [import_list]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{base},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{import_list}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: ['base' import_list]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{base},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{base},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{base},
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
                      q{base},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{base},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::class_load
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"class_load"};

    Parse::RecDescent::_trace(q{Trying rule: [class_load]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{class_load},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'Class::Load::', or /\\b/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['Class::Load::', or /\\b/ '(' <perl_quotelike> comma_hashref ')']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{class_load});
        %item = (__RULE__ => q{class_load});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_1_of_rule_class_load]},
                  Parse::RecDescent::_tracefirst($text),
                  q{class_load},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_class_load($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_1_of_rule_class_load]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{class_load},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_1_of_rule_class_load]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule_class_load}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: ['(']},
                      Parse::RecDescent::_tracefirst($text),
                      q{class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{'('})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\(/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        

        Parse::RecDescent::_trace(q{Trying directive: [<perl_quotelike>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{class_load},
                      $tracelevel)
                        if defined $::RD_TRACE; 
        $_tok = do { my ($match,@res);
                     ($match,$text,undef,@res) =
                          Text::Balanced::extract_quotelike($text,$skip);
                      $match ? \@res : undef;
                     };
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
        

        Parse::RecDescent::_trace(q{Trying repeated subrule: [comma_hashref]},
                  Parse::RecDescent::_tracefirst($text),
                  q{class_load},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{comma_hashref})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Module::ExtractUse::Grammar::comma_hashref, 0, 1, $_noactions,$expectation,sub { \@arg },undef)))
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [comma_hashref]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{class_load},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [comma_hashref]<< (}
                    . @$_tok . q{ times)},

                      Parse::RecDescent::_tracefirst($text),
                      q{class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{comma_hashref(?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying terminal: [')']},
                      Parse::RecDescent::_tracefirst($text),
                      q{class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{')'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\)/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $return = $item[3][2] };
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
        

        Parse::RecDescent::_trace(q{>>Matched production: ['Class::Load::', or /\\b/ '(' <perl_quotelike> comma_hashref ')']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{class_load},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{class_load},
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
                      q{class_load},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{class_load},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::class_load_first_existing
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"class_load_first_existing"};

    Parse::RecDescent::_trace(q{Trying rule: [class_load_first_existing]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{class_load_first_existing},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'Class::Load::load_first_existing_class', or /\\bload_first_existing_class/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['Class::Load::load_first_existing_class', or /\\bload_first_existing_class/ '(' first_existing_arg comma_first_existing_arg ')']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{class_load_first_existing},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{class_load_first_existing});
        %item = (__RULE__ => q{class_load_first_existing});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_1_of_rule_class_load_first_existing]},
                  Parse::RecDescent::_tracefirst($text),
                  q{class_load_first_existing},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_class_load_first_existing($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_1_of_rule_class_load_first_existing]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{class_load_first_existing},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_1_of_rule_class_load_first_existing]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{class_load_first_existing},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule_class_load_first_existing}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: ['(']},
                      Parse::RecDescent::_tracefirst($text),
                      q{class_load_first_existing},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{'('})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\(/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [first_existing_arg]},
                  Parse::RecDescent::_tracefirst($text),
                  q{class_load_first_existing},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{first_existing_arg})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::first_existing_arg($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [first_existing_arg]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{class_load_first_existing},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [first_existing_arg]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{class_load_first_existing},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{first_existing_arg}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying repeated subrule: [comma_first_existing_arg]},
                  Parse::RecDescent::_tracefirst($text),
                  q{class_load_first_existing},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{comma_first_existing_arg})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Module::ExtractUse::Grammar::comma_first_existing_arg, 0, 100000000, $_noactions,$expectation,sub { \@arg },undef)))
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [comma_first_existing_arg]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{class_load_first_existing},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [comma_first_existing_arg]<< (}
                    . @$_tok . q{ times)},

                      Parse::RecDescent::_tracefirst($text),
                      q{class_load_first_existing},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{comma_first_existing_arg(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying terminal: [')']},
                      Parse::RecDescent::_tracefirst($text),
                      q{class_load_first_existing},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{')'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\)/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{class_load_first_existing},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $return = $item{first_existing_arg};
                              $return .= " " . join(" ", @{$item{'comma_first_existing_arg(s?)'}}) if $item{'comma_first_existing_arg(s?)'};
                              1;
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
        

        Parse::RecDescent::_trace(q{>>Matched production: ['Class::Load::load_first_existing_class', or /\\bload_first_existing_class/ '(' first_existing_arg comma_first_existing_arg ')']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{class_load_first_existing},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{class_load_first_existing},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{class_load_first_existing},
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
                      q{class_load_first_existing},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{class_load_first_existing},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::class_load_functions
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"class_load_functions"};

    Parse::RecDescent::_trace(q{Trying rule: [class_load_functions]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{class_load_functions},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'load_class', or 'try_load_class', or 'load_optional_class'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['load_class']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{class_load_functions},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{class_load_functions});
        %item = (__RULE__ => q{class_load_functions});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['load_class']},
                      Parse::RecDescent::_tracefirst($text),
                      q{class_load_functions},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\Aload_class/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{>>Matched production: ['load_class']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{class_load_functions},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['try_load_class']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{class_load_functions},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{class_load_functions});
        %item = (__RULE__ => q{class_load_functions});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['try_load_class']},
                      Parse::RecDescent::_tracefirst($text),
                      q{class_load_functions},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\Atry_load_class/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{>>Matched production: ['try_load_class']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{class_load_functions},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['load_optional_class']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{class_load_functions},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{class_load_functions});
        %item = (__RULE__ => q{class_load_functions});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['load_optional_class']},
                      Parse::RecDescent::_tracefirst($text),
                      q{class_load_functions},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\Aload_optional_class/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{>>Matched production: ['load_optional_class']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{class_load_functions},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{class_load_functions},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{class_load_functions},
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
                      q{class_load_functions},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{class_load_functions},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::comma
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"comma"};

    Parse::RecDescent::_trace(q{Trying rule: [comma]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{comma},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{',', or '=>'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [',', or '=>']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{comma},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{comma});
        %item = (__RULE__ => q{comma});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_1_of_rule_comma]},
                  Parse::RecDescent::_tracefirst($text),
                  q{comma},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_comma($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_1_of_rule_comma]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{comma},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_1_of_rule_comma]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{comma},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule_comma}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [',', or '=>']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{comma},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{comma},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{comma},
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
                      q{comma},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{comma},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::comma_first_existing_arg
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"comma_first_existing_arg"};

    Parse::RecDescent::_trace(q{Trying rule: [comma_first_existing_arg]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{comma_first_existing_arg},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{comma});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [comma first_existing_arg]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{comma_first_existing_arg},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{comma_first_existing_arg});
        %item = (__RULE__ => q{comma_first_existing_arg});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [comma]},
                  Parse::RecDescent::_tracefirst($text),
                  q{comma_first_existing_arg},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::comma($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [comma]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{comma_first_existing_arg},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [comma]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{comma_first_existing_arg},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{comma}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying subrule: [first_existing_arg]},
                  Parse::RecDescent::_tracefirst($text),
                  q{comma_first_existing_arg},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{first_existing_arg})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::first_existing_arg($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [first_existing_arg]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{comma_first_existing_arg},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [first_existing_arg]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{comma_first_existing_arg},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{first_existing_arg}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{comma_first_existing_arg},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $return = $item{first_existing_arg} };
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
        

        Parse::RecDescent::_trace(q{>>Matched production: [comma first_existing_arg]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{comma_first_existing_arg},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{comma_first_existing_arg},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{comma_first_existing_arg},
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
                      q{comma_first_existing_arg},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{comma_first_existing_arg},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::comma_hash_pair
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"comma_hash_pair"};

    Parse::RecDescent::_trace(q{Trying rule: [comma_hash_pair]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{comma_hash_pair},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{comma});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [comma hash_pair]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{comma_hash_pair},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{comma_hash_pair});
        %item = (__RULE__ => q{comma_hash_pair});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [comma]},
                  Parse::RecDescent::_tracefirst($text),
                  q{comma_hash_pair},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::comma($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [comma]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{comma_hash_pair},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [comma]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{comma_hash_pair},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{comma}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying subrule: [hash_pair]},
                  Parse::RecDescent::_tracefirst($text),
                  q{comma_hash_pair},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{hash_pair})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::hash_pair($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [hash_pair]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{comma_hash_pair},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [hash_pair]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{comma_hash_pair},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{hash_pair}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [comma hash_pair]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{comma_hash_pair},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{comma_hash_pair},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{comma_hash_pair},
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
                      q{comma_hash_pair},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{comma_hash_pair},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::comma_hashref
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"comma_hashref"};

    Parse::RecDescent::_trace(q{Trying rule: [comma_hashref]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{comma_hashref},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{comma});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [comma hashref]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{comma_hashref},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{comma_hashref});
        %item = (__RULE__ => q{comma_hashref});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [comma]},
                  Parse::RecDescent::_tracefirst($text),
                  q{comma_hashref},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::comma($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [comma]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{comma_hashref},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [comma]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{comma_hashref},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{comma}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying subrule: [hashref]},
                  Parse::RecDescent::_tracefirst($text),
                  q{comma_hashref},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{hashref})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::hashref($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [hashref]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{comma_hashref},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [hashref]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{comma_hashref},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{hashref}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [comma hashref]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{comma_hashref},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{comma_hashref},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{comma_hashref},
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
                      q{comma_hashref},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{comma_hashref},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::comma_list_item
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"comma_list_item"};

    Parse::RecDescent::_trace(q{Trying rule: [comma_list_item]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{comma_list_item},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{comma});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [comma list_item]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{comma_list_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{comma_list_item});
        %item = (__RULE__ => q{comma_list_item});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [comma]},
                  Parse::RecDescent::_tracefirst($text),
                  q{comma_list_item},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::comma($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [comma]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{comma_list_item},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [comma]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{comma_list_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{comma}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying subrule: [list_item]},
                  Parse::RecDescent::_tracefirst($text),
                  q{comma_list_item},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{list_item})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::list_item($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [list_item]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{comma_list_item},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [list_item]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{comma_list_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{list_item}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{comma_list_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $return=$item{list_item} };
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
        

        Parse::RecDescent::_trace(q{>>Matched production: [comma list_item]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{comma_list_item},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{comma_list_item},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{comma_list_item},
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
                      q{comma_list_item},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{comma_list_item},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::eos
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"eos"};

    Parse::RecDescent::_trace(q{Trying rule: [eos]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{eos},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: []},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{eos},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{eos});
        %item = (__RULE__ => q{eos});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{eos},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $text=~/^[\s;]+$/ ? 1 : undef;};
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
        

        Parse::RecDescent::_trace(q{>>Matched production: []<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{eos},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{eos},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{eos},
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
                      q{eos},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{eos},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::first_existing_arg
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"first_existing_arg"};

    Parse::RecDescent::_trace(q{Trying rule: [first_existing_arg]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{first_existing_arg},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<perl_quotelike> comma_hashref]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{first_existing_arg},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{first_existing_arg});
        %item = (__RULE__ => q{first_existing_arg});
        my $repcount = 0;


        

        Parse::RecDescent::_trace(q{Trying directive: [<perl_quotelike>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{first_existing_arg},
                      $tracelevel)
                        if defined $::RD_TRACE; 
        $_tok = do { my ($match,@res);
                     ($match,$text,undef,@res) =
                          Text::Balanced::extract_quotelike($text,$skip);
                      $match ? \@res : undef;
                     };
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
        

        Parse::RecDescent::_trace(q{Trying repeated subrule: [comma_hashref]},
                  Parse::RecDescent::_tracefirst($text),
                  q{first_existing_arg},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{comma_hashref})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Module::ExtractUse::Grammar::comma_hashref, 0, 1, $_noactions,$expectation,sub { \@arg },undef)))
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [comma_hashref]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{first_existing_arg},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [comma_hashref]<< (}
                    . @$_tok . q{ times)},

                      Parse::RecDescent::_tracefirst($text),
                      q{first_existing_arg},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{comma_hashref(?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{first_existing_arg},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $return = $item[1][2] };
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
        

        Parse::RecDescent::_trace(q{>>Matched production: [<perl_quotelike> comma_hashref]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{first_existing_arg},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{first_existing_arg},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{first_existing_arg},
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
                      q{first_existing_arg},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{first_existing_arg},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::hash_pair
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"hash_pair"};

    Parse::RecDescent::_trace(q{Trying rule: [hash_pair]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{hash_pair},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/\\S+/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\S+/ comma /[^\\s,\}]+/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{hash_pair},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{hash_pair});
        %item = (__RULE__ => q{hash_pair});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/\\S+/]}, Parse::RecDescent::_tracefirst($text),
                      q{hash_pair},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\S+)/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [comma]},
                  Parse::RecDescent::_tracefirst($text),
                  q{hash_pair},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{comma})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::comma($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [comma]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{hash_pair},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [comma]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{hash_pair},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{comma}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_1_of_rule_hash_pair]},
                  Parse::RecDescent::_tracefirst($text),
                  q{hash_pair},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{/[^\\s,\}]+/})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_hash_pair($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_1_of_rule_hash_pair]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{hash_pair},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_1_of_rule_hash_pair]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{hash_pair},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule_hash_pair}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [/\\S+/ comma /[^\\s,\}]+/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{hash_pair},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{hash_pair},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{hash_pair},
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
                      q{hash_pair},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{hash_pair},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::hashref
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"hashref"};

    Parse::RecDescent::_trace(q{Trying rule: [hashref]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{hashref},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'\{'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['\{' hash_pair comma_hash_pair '\}']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{hashref},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{hashref});
        %item = (__RULE__ => q{hashref});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['\{']},
                      Parse::RecDescent::_tracefirst($text),
                      q{hashref},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\{/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [hash_pair]},
                  Parse::RecDescent::_tracefirst($text),
                  q{hashref},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{hash_pair})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::hash_pair($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [hash_pair]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{hashref},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [hash_pair]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{hashref},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{hash_pair}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying repeated subrule: [comma_hash_pair]},
                  Parse::RecDescent::_tracefirst($text),
                  q{hashref},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{comma_hash_pair})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Module::ExtractUse::Grammar::comma_hash_pair, 0, 100000000, $_noactions,$expectation,sub { \@arg },undef)))
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [comma_hash_pair]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{hashref},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [comma_hash_pair]<< (}
                    . @$_tok . q{ times)},

                      Parse::RecDescent::_tracefirst($text),
                      q{hashref},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{comma_hash_pair(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying terminal: ['\}']},
                      Parse::RecDescent::_tracefirst($text),
                      q{hashref},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{'\}'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\}/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING2__}=$current_match;
        

        Parse::RecDescent::_trace(q{>>Matched production: ['\{' hash_pair comma_hash_pair '\}']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{hashref},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{hashref},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{hashref},
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
                      q{hashref},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{hashref},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::import_list
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"import_list"};

    Parse::RecDescent::_trace(q{Trying rule: [import_list]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{import_list},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/[(]?/, or /[(]\\s*[)]/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/[(]?/ list_item comma_list_item /[)]?/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{import_list},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{import_list});
        %item = (__RULE__ => q{import_list});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/[(]?/]}, Parse::RecDescent::_tracefirst($text),
                      q{import_list},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[(]?)/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [list_item]},
                  Parse::RecDescent::_tracefirst($text),
                  q{import_list},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{list_item})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::list_item($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [list_item]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{import_list},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [list_item]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{import_list},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{list_item}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying repeated subrule: [comma_list_item]},
                  Parse::RecDescent::_tracefirst($text),
                  q{import_list},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{comma_list_item})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Module::ExtractUse::Grammar::comma_list_item, 0, 100000000, $_noactions,$expectation,sub { \@arg },undef)))
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [comma_list_item]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{import_list},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [comma_list_item]<< (}
                    . @$_tok . q{ times)},

                      Parse::RecDescent::_tracefirst($text),
                      q{import_list},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{comma_list_item(s?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying terminal: [/[)]?/]}, Parse::RecDescent::_tracefirst($text),
                      q{import_list},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{/[)]?/})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[)]?)/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{import_list},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $return=$item[2];
		  $return.=" ".join(" ",@{$item[3]}) if $item[3];
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
        

        Parse::RecDescent::_trace(q{>>Matched production: [/[(]?/ list_item comma_list_item /[)]?/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{import_list},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/[(]\\s*[)]/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{import_list},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{import_list});
        %item = (__RULE__ => q{import_list});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/[(]\\s*[)]/]}, Parse::RecDescent::_tracefirst($text),
                      q{import_list},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[(]\s*[)])/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{import_list},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $return='' };
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
        

        Parse::RecDescent::_trace(q{>>Matched production: [/[(]\\s*[)]/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{import_list},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{import_list},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{import_list},
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
                      q{import_list},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{import_list},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::list_item
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"list_item"};

    Parse::RecDescent::_trace(q{Trying rule: [list_item]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{list_item},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/-?\\w+/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<perl_quotelike>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{list_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{list_item});
        %item = (__RULE__ => q{list_item});
        my $repcount = 0;


        

        Parse::RecDescent::_trace(q{Trying directive: [<perl_quotelike>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{list_item},
                      $tracelevel)
                        if defined $::RD_TRACE; 
        $_tok = do { my ($match,@res);
                     ($match,$text,undef,@res) =
                          Text::Balanced::extract_quotelike($text,$skip);
                      $match ? \@res : undef;
                     };
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
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{list_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $return=$item[1][2] };
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
        

        Parse::RecDescent::_trace(q{>>Matched production: [<perl_quotelike>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{list_item},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<perl_codeblock>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{list_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{list_item});
        %item = (__RULE__ => q{list_item});
        my $repcount = 0;


        

        Parse::RecDescent::_trace(q{Trying directive: [<perl_codeblock>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{list_item},
                      $tracelevel)
                        if defined $::RD_TRACE; 
        $_tok = do { Text::Balanced::extract_codeblock($text,undef,$skip,'(){}[]');
                     };
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
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{list_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $return=$item[1] };
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
        

        Parse::RecDescent::_trace(q{>>Matched production: [<perl_codeblock>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{list_item},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/-?\\w+/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{list_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[2];
        $text = $_[1];
        my $_savetext;
        @item = (q{list_item});
        %item = (__RULE__ => q{list_item});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/-?\\w+/]}, Parse::RecDescent::_tracefirst($text),
                      q{list_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:-?\w+)/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{list_item},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $return=$item[1] };
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
        

        Parse::RecDescent::_trace(q{>>Matched production: [/-?\\w+/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{list_item},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{list_item},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{list_item},
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
                      q{list_item},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{list_item},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::module
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"module"};

    Parse::RecDescent::_trace(q{Trying rule: [module]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{module},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{module_name});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [module_name module_more]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{module},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{module});
        %item = (__RULE__ => q{module});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [module_name]},
                  Parse::RecDescent::_tracefirst($text),
                  q{module},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::module_name($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [module_name]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{module},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [module_name]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{module},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{module_name}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying subrule: [module_more]},
                  Parse::RecDescent::_tracefirst($text),
                  q{module},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{module_more})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::module_more($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [module_more]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{module},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [module_more]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{module},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{module_more}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{module},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $return=$item{module_name} };
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
        

        Parse::RecDescent::_trace(q{>>Matched production: [module_name module_more]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{module},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{module},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{module},
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
                      q{module},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{module},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::module_more
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"module_more"};

    Parse::RecDescent::_trace(q{Trying rule: [module_more]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{module_more},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{eos, or version});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [eos]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{module_more},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{module_more});
        %item = (__RULE__ => q{module_more});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [eos]},
                  Parse::RecDescent::_tracefirst($text),
                  q{module_more},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::eos($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [eos]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{module_more},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [eos]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{module_more},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{eos}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [eos]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{module_more},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [version var import_list]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{module_more},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{module_more});
        %item = (__RULE__ => q{module_more});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying repeated subrule: [version]},
                  Parse::RecDescent::_tracefirst($text),
                  q{module_more},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Module::ExtractUse::Grammar::version, 0, 1, $_noactions,$expectation,sub { \@arg },undef)))
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [version]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{module_more},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [version]<< (}
                    . @$_tok . q{ times)},

                      Parse::RecDescent::_tracefirst($text),
                      q{module_more},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{version(?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying repeated subrule: [var]},
                  Parse::RecDescent::_tracefirst($text),
                  q{module_more},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{var})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Module::ExtractUse::Grammar::var, 0, 1, $_noactions,$expectation,sub { \@arg },undef)))
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [var]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{module_more},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [var]<< (}
                    . @$_tok . q{ times)},

                      Parse::RecDescent::_tracefirst($text),
                      q{module_more},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{var(?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying repeated subrule: [import_list]},
                  Parse::RecDescent::_tracefirst($text),
                  q{module_more},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{import_list})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Module::ExtractUse::Grammar::import_list, 0, 1, $_noactions,$expectation,sub { \@arg },undef)))
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [import_list]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{module_more},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [import_list]<< (}
                    . @$_tok . q{ times)},

                      Parse::RecDescent::_tracefirst($text),
                      q{module_more},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{import_list(?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{>>Matched production: [version var import_list]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{module_more},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{module_more},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{module_more},
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
                      q{module_more},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{module_more},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::module_name
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"module_name"};

    Parse::RecDescent::_trace(q{Trying rule: [module_name]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{module_name},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/[\\w:]+/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/[\\w:]+/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{module_name},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{module_name});
        %item = (__RULE__ => q{module_name});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/[\\w:]+/]}, Parse::RecDescent::_tracefirst($text),
                      q{module_name},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[\w:]+)/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{>>Matched production: [/[\\w:]+/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{module_name},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{module_name},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{module_name},
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
                      q{module_name},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{module_name},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::module_runtime_require_module
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"module_runtime_require_module"};

    Parse::RecDescent::_trace(q{Trying rule: [module_runtime_require_module]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{module_runtime_require_module},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'Module::Runtime::require_module(', or /\\brequire_module\\(/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['Module::Runtime::require_module(', or /\\brequire_module\\(/ <perl_quotelike> ')']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{module_runtime_require_module},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{module_runtime_require_module});
        %item = (__RULE__ => q{module_runtime_require_module});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_1_of_rule_module_runtime_require_module]},
                  Parse::RecDescent::_tracefirst($text),
                  q{module_runtime_require_module},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_module_runtime_require_module($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_1_of_rule_module_runtime_require_module]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{module_runtime_require_module},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_1_of_rule_module_runtime_require_module]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{module_runtime_require_module},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule_module_runtime_require_module}} = $_tok;
        push @item, $_tok;
        
        }

        

        Parse::RecDescent::_trace(q{Trying directive: [<perl_quotelike>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{module_runtime_require_module},
                      $tracelevel)
                        if defined $::RD_TRACE; 
        $_tok = do { my ($match,@res);
                     ($match,$text,undef,@res) =
                          Text::Balanced::extract_quotelike($text,$skip);
                      $match ? \@res : undef;
                     };
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
        

        Parse::RecDescent::_trace(q{Trying terminal: [')']},
                      Parse::RecDescent::_tracefirst($text),
                      q{module_runtime_require_module},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{')'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\)/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{module_runtime_require_module},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $return = $item[2][2] };
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
        

        Parse::RecDescent::_trace(q{>>Matched production: ['Module::Runtime::require_module(', or /\\brequire_module\\(/ <perl_quotelike> ')']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{module_runtime_require_module},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{module_runtime_require_module},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{module_runtime_require_module},
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
                      q{module_runtime_require_module},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{module_runtime_require_module},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::module_runtime_use
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"module_runtime_use"};

    Parse::RecDescent::_trace(q{Trying rule: [module_runtime_use]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{module_runtime_use},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'Module::Runtime::', or /\\b/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['Module::Runtime::', or /\\b/ <perl_quotelike> module_runtime_version ')']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{module_runtime_use});
        %item = (__RULE__ => q{module_runtime_use});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_1_of_rule_module_runtime_use]},
                  Parse::RecDescent::_tracefirst($text),
                  q{module_runtime_use},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_module_runtime_use($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_1_of_rule_module_runtime_use]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{module_runtime_use},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_1_of_rule_module_runtime_use]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule_module_runtime_use}} = $_tok;
        push @item, $_tok;
        
        }

        

        Parse::RecDescent::_trace(q{Trying directive: [<perl_quotelike>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE; 
        $_tok = do { my ($match,@res);
                     ($match,$text,undef,@res) =
                          Text::Balanced::extract_quotelike($text,$skip);
                      $match ? \@res : undef;
                     };
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
        

        Parse::RecDescent::_trace(q{Trying repeated subrule: [module_runtime_version]},
                  Parse::RecDescent::_tracefirst($text),
                  q{module_runtime_use},
                  $tracelevel)
                    if defined $::RD_TRACE;
        $expectation->is(q{module_runtime_version})->at($text);
        
        unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Module::ExtractUse::Grammar::module_runtime_version, 0, 1, $_noactions,$expectation,sub { \@arg },undef)))
        {
            Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [module_runtime_version]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{module_runtime_use},
                          $tracelevel)
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched repeated subrule: [module_runtime_version]<< (}
                    . @$_tok . q{ times)},

                      Parse::RecDescent::_tracefirst($text),
                      q{module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{module_runtime_version(?)}} = $_tok;
        push @item, $_tok;
        


        Parse::RecDescent::_trace(q{Trying terminal: [')']},
                      Parse::RecDescent::_tracefirst($text),
                      q{module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{')'})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\)/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $return = $item[2][2] };
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
        

        Parse::RecDescent::_trace(q{>>Matched production: ['Module::Runtime::', or /\\b/ <perl_quotelike> module_runtime_version ')']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{module_runtime_use},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{module_runtime_use},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{module_runtime_use},
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
                      q{module_runtime_use},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{module_runtime_use},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::module_runtime_use_fcn
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"module_runtime_use_fcn"};

    Parse::RecDescent::_trace(q{Trying rule: [module_runtime_use_fcn]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{module_runtime_use_fcn},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'use_module', or 'use_package_optimistically'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['use_module', or 'use_package_optimistically']},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{module_runtime_use_fcn},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{module_runtime_use_fcn});
        %item = (__RULE__ => q{module_runtime_use_fcn});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_1_of_rule_module_runtime_use_fcn]},
                  Parse::RecDescent::_tracefirst($text),
                  q{module_runtime_use_fcn},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_module_runtime_use_fcn($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_1_of_rule_module_runtime_use_fcn]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{module_runtime_use_fcn},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_1_of_rule_module_runtime_use_fcn]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{module_runtime_use_fcn},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule_module_runtime_use_fcn}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: ['use_module', or 'use_package_optimistically']<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{module_runtime_use_fcn},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{module_runtime_use_fcn},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{module_runtime_use_fcn},
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
                      q{module_runtime_use_fcn},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{module_runtime_use_fcn},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::module_runtime_version
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"module_runtime_version"};

    Parse::RecDescent::_trace(q{Trying rule: [module_runtime_version]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{module_runtime_version},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{','});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [',' /\\s*/ version]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{module_runtime_version},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{module_runtime_version});
        %item = (__RULE__ => q{module_runtime_version});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [',']},
                      Parse::RecDescent::_tracefirst($text),
                      q{module_runtime_version},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A\,/)
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying terminal: [/\\s*/]}, Parse::RecDescent::_tracefirst($text),
                      q{module_runtime_version},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{/\\s*/})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\s*)/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [version]},
                  Parse::RecDescent::_tracefirst($text),
                  q{module_runtime_version},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{version})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::version($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [version]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{module_runtime_version},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [version]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{module_runtime_version},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{version}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [',' /\\s*/ version]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{module_runtime_version},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{module_runtime_version},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{module_runtime_version},
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
                      q{module_runtime_version},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{module_runtime_version},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::no_stuff
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"no_stuff"};

    Parse::RecDescent::_trace(q{Trying rule: [no_stuff]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{no_stuff},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{base, or version, or module});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [base, or version, or module]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{no_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{no_stuff});
        %item = (__RULE__ => q{no_stuff});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_1_of_rule_no_stuff]},
                  Parse::RecDescent::_tracefirst($text),
                  q{no_stuff},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_no_stuff($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_1_of_rule_no_stuff]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{no_stuff},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_1_of_rule_no_stuff]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{no_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule_no_stuff}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [base, or version, or module]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{no_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{no_stuff},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{no_stuff},
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
                      q{no_stuff},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{no_stuff},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::parent
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"parent"};

    Parse::RecDescent::_trace(q{Trying rule: [parent]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{parent},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{'parent'});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: ['parent' import_list]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{parent},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{parent});
        %item = (__RULE__ => q{parent});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: ['parent']},
                      Parse::RecDescent::_tracefirst($text),
                      q{parent},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   do { $_tok = "parent"; 1 } and
             substr($text,0,length($_tok)) eq $_tok and
             do { substr($text,0,length($_tok)) = ""; 1; }
        )
        {
            $text = $lastsep . $text if defined $lastsep;
            
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $_tok . q{])},
                          Parse::RecDescent::_tracefirst($text))
                            if defined $::RD_TRACE;
        push @item, $item{__STRING1__}=$_tok;
        

        Parse::RecDescent::_trace(q{Trying subrule: [import_list]},
                  Parse::RecDescent::_tracefirst($text),
                  q{parent},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{import_list})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::import_list($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [import_list]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{parent},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [import_list]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{parent},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{import_list}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{parent},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $return='parent'; $return.=' '.$item[2] if $item[2] !~ /^\s*-norequire\b/; };
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
        

        Parse::RecDescent::_trace(q{>>Matched production: ['parent' import_list]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{parent},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{parent},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{parent},
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
                      q{parent},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{parent},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::require_name
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"require_name"};

    Parse::RecDescent::_trace(q{Trying rule: [require_name]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{require_name},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [<perl_quotelike>]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{require_name},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{require_name});
        %item = (__RULE__ => q{require_name});
        my $repcount = 0;


        

        Parse::RecDescent::_trace(q{Trying directive: [<perl_quotelike>]},
                    Parse::RecDescent::_tracefirst($text),
                      q{require_name},
                      $tracelevel)
                        if defined $::RD_TRACE; 
        $_tok = do { my ($match,@res);
                     ($match,$text,undef,@res) =
                          Text::Balanced::extract_quotelike($text,$skip);
                      $match ? \@res : undef;
                     };
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
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{require_name},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { my $name=$item[1][2];
		  return 1 if ($name=~/\.pl$/);
		  $name=~s(/)(::)g;
		  $name=~s/\.pm//;
		  $return=$name;
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
        

        Parse::RecDescent::_trace(q{>>Matched production: [<perl_quotelike>]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{require_name},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{require_name},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{require_name},
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
                      q{require_name},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{require_name},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::require_stuff
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"require_stuff"};

    Parse::RecDescent::_trace(q{Trying rule: [require_stuff]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{require_stuff},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{version, or require_name, or module});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [version, or require_name, or module]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{require_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{require_stuff});
        %item = (__RULE__ => q{require_stuff});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_1_of_rule_require_stuff]},
                  Parse::RecDescent::_tracefirst($text),
                  q{require_stuff},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_require_stuff($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_1_of_rule_require_stuff]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{require_stuff},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_1_of_rule_require_stuff]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{require_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule_require_stuff}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [version, or require_name, or module]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{require_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{require_stuff},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{require_stuff},
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
                      q{require_stuff},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{require_stuff},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::token_class_load
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"token_class_load"};

    Parse::RecDescent::_trace(q{Trying rule: [token_class_load]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{token_class_load},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{class_load, or class_load_first_existing});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [class_load]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{token_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{token_class_load});
        %item = (__RULE__ => q{token_class_load});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [class_load]},
                  Parse::RecDescent::_tracefirst($text),
                  q{token_class_load},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::class_load($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [class_load]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{token_class_load},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [class_load]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{token_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{class_load}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [class_load]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{token_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [class_load_first_existing]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{token_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{token_class_load});
        %item = (__RULE__ => q{token_class_load});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [class_load_first_existing]},
                  Parse::RecDescent::_tracefirst($text),
                  q{token_class_load},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::class_load_first_existing($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [class_load_first_existing]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{token_class_load},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [class_load_first_existing]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{token_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{class_load_first_existing}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [class_load_first_existing]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{token_class_load},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{token_class_load},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{token_class_load},
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
                      q{token_class_load},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{token_class_load},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::token_module_runtime
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"token_module_runtime"};

    Parse::RecDescent::_trace(q{Trying rule: [token_module_runtime]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{token_module_runtime},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{module_runtime_require_module, or module_runtime_use});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [module_runtime_require_module]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{token_module_runtime},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{token_module_runtime});
        %item = (__RULE__ => q{token_module_runtime});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [module_runtime_require_module]},
                  Parse::RecDescent::_tracefirst($text),
                  q{token_module_runtime},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::module_runtime_require_module($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [module_runtime_require_module]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{token_module_runtime},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [module_runtime_require_module]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{token_module_runtime},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{module_runtime_require_module}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [module_runtime_require_module]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{token_module_runtime},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [module_runtime_use]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{token_module_runtime},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[1];
        $text = $_[1];
        my $_savetext;
        @item = (q{token_module_runtime});
        %item = (__RULE__ => q{token_module_runtime});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [module_runtime_use]},
                  Parse::RecDescent::_tracefirst($text),
                  q{token_module_runtime},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::module_runtime_use($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [module_runtime_use]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{token_module_runtime},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [module_runtime_use]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{token_module_runtime},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{module_runtime_use}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [module_runtime_use]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{token_module_runtime},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{token_module_runtime},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{token_module_runtime},
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
                      q{token_module_runtime},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{token_module_runtime},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::token_no
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"token_no"};

    Parse::RecDescent::_trace(q{Trying rule: [token_no]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{token_no},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/\\bno\\s/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\bno\\s/ no_stuff /[;\}]/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{token_no},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{token_no});
        %item = (__RULE__ => q{token_no});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/\\bno\\s/]}, Parse::RecDescent::_tracefirst($text),
                      q{token_no},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\bno\s)/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [no_stuff]},
                  Parse::RecDescent::_tracefirst($text),
                  q{token_no},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{no_stuff})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::no_stuff($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [no_stuff]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{token_no},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [no_stuff]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{token_no},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{no_stuff}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: [/[;\}]/]}, Parse::RecDescent::_tracefirst($text),
                      q{token_no},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{/[;\}]/})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[;}])/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{token_no},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $return=$item{no_stuff} };
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
        

        Parse::RecDescent::_trace(q{>>Matched production: [/\\bno\\s/ no_stuff /[;\}]/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{token_no},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{token_no},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{token_no},
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
                      q{token_no},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{token_no},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::token_require
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"token_require"};

    Parse::RecDescent::_trace(q{Trying rule: [token_require]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{token_require},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/\\brequire\\s/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\brequire\\s/ require_stuff /[;\}]/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{token_require},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{token_require});
        %item = (__RULE__ => q{token_require});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/\\brequire\\s/]}, Parse::RecDescent::_tracefirst($text),
                      q{token_require},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\brequire\s)/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [require_stuff]},
                  Parse::RecDescent::_tracefirst($text),
                  q{token_require},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{require_stuff})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::require_stuff($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [require_stuff]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{token_require},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [require_stuff]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{token_require},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{require_stuff}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: [/[;\}]/]}, Parse::RecDescent::_tracefirst($text),
                      q{token_require},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{/[;\}]/})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[;}])/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{token_require},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $return=$item{require_stuff} };
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
        

        Parse::RecDescent::_trace(q{>>Matched production: [/\\brequire\\s/ require_stuff /[;\}]/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{token_require},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{token_require},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{token_require},
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
                      q{token_require},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{token_require},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::token_use
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"token_use"};

    Parse::RecDescent::_trace(q{Trying rule: [token_use]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{token_use},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/\\buse\\s/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\buse\\s/ use_stuff /[;\}]/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{token_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{token_use});
        %item = (__RULE__ => q{token_use});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/\\buse\\s/]}, Parse::RecDescent::_tracefirst($text),
                      q{token_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\buse\s)/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying subrule: [use_stuff]},
                  Parse::RecDescent::_tracefirst($text),
                  q{token_use},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{use_stuff})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::use_stuff($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [use_stuff]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{token_use},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [use_stuff]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{token_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{use_stuff}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{Trying terminal: [/[;\}]/]}, Parse::RecDescent::_tracefirst($text),
                      q{token_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{/[;\}]/})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:[;}])/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN2__}=$current_match;
        

        Parse::RecDescent::_trace(q{Trying action},
                      Parse::RecDescent::_tracefirst($text),
                      q{token_use},
                      $tracelevel)
                        if defined $::RD_TRACE;
        

        $_tok = ($_noactions) ? 0 : do { $return=$item{use_stuff} };
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
        

        Parse::RecDescent::_trace(q{>>Matched production: [/\\buse\\s/ use_stuff /[;\}]/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{token_use},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{token_use},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{token_use},
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
                      q{token_use},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{token_use},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::use_stuff
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"use_stuff"};

    Parse::RecDescent::_trace(q{Trying rule: [use_stuff]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{use_stuff},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{base, or parent, or version, or module});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [base, or parent, or version, or module]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{use_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{use_stuff});
        %item = (__RULE__ => q{use_stuff});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying subrule: [_alternation_1_of_production_1_of_rule_use_stuff]},
                  Parse::RecDescent::_tracefirst($text),
                  q{use_stuff},
                  $tracelevel)
                    if defined $::RD_TRACE;
        if (1) { no strict qw{refs};
        $expectation->is(q{})->at($text);
        unless (defined ($_tok = Parse::RecDescent::Module::ExtractUse::Grammar::_alternation_1_of_production_1_of_rule_use_stuff($thisparser,$text,$repeating,$_noactions,sub { \@arg },undef)))
        {
            
            Parse::RecDescent::_trace(q{<<Didn't match subrule: [_alternation_1_of_production_1_of_rule_use_stuff]>>},
                          Parse::RecDescent::_tracefirst($text),
                          q{use_stuff},
                          $tracelevel)
                            if defined $::RD_TRACE;
            $expectation->failed();
            last;
        }
        Parse::RecDescent::_trace(q{>>Matched subrule: [_alternation_1_of_production_1_of_rule_use_stuff]<< (return value: [}
                    . $_tok . q{]},

                      Parse::RecDescent::_tracefirst($text),
                      q{use_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;
        $item{q{_alternation_1_of_production_1_of_rule_use_stuff}} = $_tok;
        push @item, $_tok;
        
        }

        Parse::RecDescent::_trace(q{>>Matched production: [base, or parent, or version, or module]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{use_stuff},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{use_stuff},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{use_stuff},
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
                      q{use_stuff},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{use_stuff},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::var
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
    my $thisrule = $thisparser->{"rules"}{"var"};

    Parse::RecDescent::_trace(q{Trying rule: [var]},
                  Parse::RecDescent::_tracefirst($_[1]),
                  q{var},
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/\\$[\\w+]/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/\\$[\\w+]/]},
                      Parse::RecDescent::_tracefirst($_[1]),
                      q{var},
                      $tracelevel)
                        if defined $::RD_TRACE;
        my $thisprod = $thisrule->{"prods"}[0];
        $text = $_[1];
        my $_savetext;
        @item = (q{var});
        %item = (__RULE__ => q{var});
        my $repcount = 0;


        Parse::RecDescent::_trace(q{Trying terminal: [/\\$[\\w+]/]}, Parse::RecDescent::_tracefirst($text),
                      q{var},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:\$[\w+])/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{>>Matched production: [/\\$[\\w+]/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{var},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
        Parse::RecDescent::_trace(q{<<Didn't match rule>>},
                     Parse::RecDescent::_tracefirst($_[1]),
                     q{var},
                     $tracelevel)
                    if defined $::RD_TRACE;
        return undef;
    }
    if (!defined($return) && defined($score))
    {
        Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
                      q{var},
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
                      q{var},
                      $tracelevel);
        Parse::RecDescent::_trace(q{(consumed: [} .
                      Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])},
                      Parse::RecDescent::_tracefirst($text),
                      , q{var},
                      $tracelevel)
    }
    $_[1] = $text;
    return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args, $_itempos)
sub Parse::RecDescent::Module::ExtractUse::Grammar::version
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
    my $repeating =  $_[2];
    my $_noactions = $_[3];
    my @arg =    defined $_[4] ? @{ &{$_[4]} } : ();
    my $_itempos = $_[5];
    my %arg =    ($#arg & 01) ? @arg : (@arg, undef);
    my $text;
    my $lastsep;
    my $current_match;
    my $expectation = new Parse::RecDescent::Expectation(q{/v?[\\d\\._]+/});
    $expectation->at($_[1]);
    
    my $thisline;
    tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

    

    while (!$_matched && !$commit)
    {
        
        Parse::RecDescent::_trace(q{Trying production: [/v?[\\d\\._]+/]},
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


        Parse::RecDescent::_trace(q{Trying terminal: [/v?[\\d\\._]+/]}, Parse::RecDescent::_tracefirst($text),
                      q{version},
                      $tracelevel)
                        if defined $::RD_TRACE;
        undef $lastsep;
        $expectation->is(q{})->at($text);
        

        unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ m/\A(?:v?[\d\._]+)/)
        {
            $text = $lastsep . $text if defined $lastsep;
            $expectation->failed();
            Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;

            last;
        }
        $current_match = substr($text, $-[0], $+[0] - $-[0]);
        substr($text,0,length($current_match),q{});
        Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
                        . $current_match . q{])},
                          Parse::RecDescent::_tracefirst($text))
                    if defined $::RD_TRACE;
        push @item, $item{__PATTERN1__}=$current_match;
        

        Parse::RecDescent::_trace(q{>>Matched production: [/v?[\\d\\._]+/]<<},
                      Parse::RecDescent::_tracefirst($text),
                      q{version},
                      $tracelevel)
                        if defined $::RD_TRACE;



        $_matched = 1;
        last;
    }


    unless ( $_matched || defined($score) )
    {
        

        $_[1] = $text;  # NOT SURE THIS IS NEEDED
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
}
package Module::ExtractUse::Grammar; sub new { my $self = bless( {
                 '_AUTOACTION' => undef,
                 '_AUTOTREE' => undef,
                 '_check' => {
                               'itempos' => '',
                               'prevcolumn' => '',
                               'prevline' => '',
                               'prevoffset' => '',
                               'thiscolumn' => '',
                               'thisoffset' => ''
                             },
                 'localvars' => '',
                 'namespace' => 'Parse::RecDescent::Module::ExtractUse::Grammar',
                 'rules' => {
                              '_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load' => bless( {
                                                                                                                                     'calls' => [
                                                                                                                                                  'class_load_functions'
                                                                                                                                                ],
                                                                                                                                     'changed' => 0,
                                                                                                                                     'impcount' => 0,
                                                                                                                                     'line' => 125,
                                                                                                                                     'name' => '_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load',
                                                                                                                                     'opcount' => 0,
                                                                                                                                     'prods' => [
                                                                                                                                                  bless( {
                                                                                                                                                           'actcount' => 0,
                                                                                                                                                           'dircount' => 0,
                                                                                                                                                           'error' => undef,
                                                                                                                                                           'items' => [
                                                                                                                                                                        bless( {
                                                                                                                                                                                 'description' => '\'Class::Load::\'',
                                                                                                                                                                                 'hashname' => '__STRING1__',
                                                                                                                                                                                 'line' => 125,
                                                                                                                                                                                 'lookahead' => 0,
                                                                                                                                                                                 'pattern' => 'Class::Load::'
                                                                                                                                                                               }, 'Parse::RecDescent::Literal' ),
                                                                                                                                                                        bless( {
                                                                                                                                                                                 'argcode' => undef,
                                                                                                                                                                                 'implicit' => undef,
                                                                                                                                                                                 'line' => 125,
                                                                                                                                                                                 'lookahead' => 0,
                                                                                                                                                                                 'matchrule' => 0,
                                                                                                                                                                                 'subrule' => 'class_load_functions'
                                                                                                                                                                               }, 'Parse::RecDescent::Subrule' )
                                                                                                                                                                      ],
                                                                                                                                                           'line' => undef,
                                                                                                                                                           'number' => 0,
                                                                                                                                                           'patcount' => 0,
                                                                                                                                                           'strcount' => 1,
                                                                                                                                                           'uncommit' => undef
                                                                                                                                                         }, 'Parse::RecDescent::Production' )
                                                                                                                                                ],
                                                                                                                                     'vars' => ''
                                                                                                                                   }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use' => bless( {
                                                                                                                                             'calls' => [
                                                                                                                                                          'module_runtime_use_fcn'
                                                                                                                                                        ],
                                                                                                                                             'changed' => 0,
                                                                                                                                             'impcount' => 0,
                                                                                                                                             'line' => 125,
                                                                                                                                             'name' => '_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use',
                                                                                                                                             'opcount' => 0,
                                                                                                                                             'prods' => [
                                                                                                                                                          bless( {
                                                                                                                                                                   'actcount' => 0,
                                                                                                                                                                   'dircount' => 0,
                                                                                                                                                                   'error' => undef,
                                                                                                                                                                   'items' => [
                                                                                                                                                                                bless( {
                                                                                                                                                                                         'description' => '\'Module::Runtime::\'',
                                                                                                                                                                                         'hashname' => '__STRING1__',
                                                                                                                                                                                         'line' => 125,
                                                                                                                                                                                         'lookahead' => 0,
                                                                                                                                                                                         'pattern' => 'Module::Runtime::'
                                                                                                                                                                                       }, 'Parse::RecDescent::Literal' ),
                                                                                                                                                                                bless( {
                                                                                                                                                                                         'argcode' => undef,
                                                                                                                                                                                         'implicit' => undef,
                                                                                                                                                                                         'line' => 125,
                                                                                                                                                                                         'lookahead' => 0,
                                                                                                                                                                                         'matchrule' => 0,
                                                                                                                                                                                         'subrule' => 'module_runtime_use_fcn'
                                                                                                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                                                                                                bless( {
                                                                                                                                                                                         'description' => '\'(\'',
                                                                                                                                                                                         'hashname' => '__STRING2__',
                                                                                                                                                                                         'line' => 125,
                                                                                                                                                                                         'lookahead' => 0,
                                                                                                                                                                                         'pattern' => '('
                                                                                                                                                                                       }, 'Parse::RecDescent::Literal' )
                                                                                                                                                                              ],
                                                                                                                                                                   'line' => undef,
                                                                                                                                                                   'number' => 0,
                                                                                                                                                                   'patcount' => 0,
                                                                                                                                                                   'strcount' => 2,
                                                                                                                                                                   'uncommit' => undef
                                                                                                                                                                 }, 'Parse::RecDescent::Production' )
                                                                                                                                                        ],
                                                                                                                                             'vars' => ''
                                                                                                                                           }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_class_load' => bless( {
                                                                                              'calls' => [
                                                                                                           '_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load',
                                                                                                           '_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load'
                                                                                                         ],
                                                                                              'changed' => 0,
                                                                                              'impcount' => 1,
                                                                                              'line' => 125,
                                                                                              'name' => '_alternation_1_of_production_1_of_rule_class_load',
                                                                                              'opcount' => 0,
                                                                                              'prods' => [
                                                                                                           bless( {
                                                                                                                    'actcount' => 0,
                                                                                                                    'dircount' => 0,
                                                                                                                    'error' => undef,
                                                                                                                    'items' => [
                                                                                                                                 bless( {
                                                                                                                                          'argcode' => undef,
                                                                                                                                          'implicit' => '\'Class::Load::\'',
                                                                                                                                          'line' => 125,
                                                                                                                                          'lookahead' => 0,
                                                                                                                                          'matchrule' => 0,
                                                                                                                                          'subrule' => '_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_class_load'
                                                                                                                                        }, 'Parse::RecDescent::Subrule' )
                                                                                                                               ],
                                                                                                                    'line' => undef,
                                                                                                                    'number' => 0,
                                                                                                                    'patcount' => 0,
                                                                                                                    'strcount' => 0,
                                                                                                                    'uncommit' => undef
                                                                                                                  }, 'Parse::RecDescent::Production' ),
                                                                                                           bless( {
                                                                                                                    'actcount' => 0,
                                                                                                                    'dircount' => 0,
                                                                                                                    'error' => undef,
                                                                                                                    'items' => [
                                                                                                                                 bless( {
                                                                                                                                          'argcode' => undef,
                                                                                                                                          'implicit' => '/\\\\b/',
                                                                                                                                          'line' => 125,
                                                                                                                                          'lookahead' => 0,
                                                                                                                                          'matchrule' => 0,
                                                                                                                                          'subrule' => '_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load'
                                                                                                                                        }, 'Parse::RecDescent::Subrule' )
                                                                                                                               ],
                                                                                                                    'line' => 125,
                                                                                                                    'number' => 1,
                                                                                                                    'patcount' => 0,
                                                                                                                    'strcount' => 0,
                                                                                                                    'uncommit' => undef
                                                                                                                  }, 'Parse::RecDescent::Production' )
                                                                                                         ],
                                                                                              'vars' => ''
                                                                                            }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_class_load_first_existing' => bless( {
                                                                                                             'calls' => [],
                                                                                                             'changed' => 0,
                                                                                                             'impcount' => 0,
                                                                                                             'line' => 125,
                                                                                                             'name' => '_alternation_1_of_production_1_of_rule_class_load_first_existing',
                                                                                                             'opcount' => 0,
                                                                                                             'prods' => [
                                                                                                                          bless( {
                                                                                                                                   'actcount' => 0,
                                                                                                                                   'dircount' => 0,
                                                                                                                                   'error' => undef,
                                                                                                                                   'items' => [
                                                                                                                                                bless( {
                                                                                                                                                         'description' => '\'Class::Load::load_first_existing_class\'',
                                                                                                                                                         'hashname' => '__STRING1__',
                                                                                                                                                         'line' => 125,
                                                                                                                                                         'lookahead' => 0,
                                                                                                                                                         'pattern' => 'Class::Load::load_first_existing_class'
                                                                                                                                                       }, 'Parse::RecDescent::Literal' )
                                                                                                                                              ],
                                                                                                                                   'line' => undef,
                                                                                                                                   'number' => 0,
                                                                                                                                   'patcount' => 0,
                                                                                                                                   'strcount' => 1,
                                                                                                                                   'uncommit' => undef
                                                                                                                                 }, 'Parse::RecDescent::Production' ),
                                                                                                                          bless( {
                                                                                                                                   'actcount' => 0,
                                                                                                                                   'dircount' => 0,
                                                                                                                                   'error' => undef,
                                                                                                                                   'items' => [
                                                                                                                                                bless( {
                                                                                                                                                         'description' => '/\\\\bload_first_existing_class/',
                                                                                                                                                         'hashname' => '__PATTERN1__',
                                                                                                                                                         'ldelim' => '/',
                                                                                                                                                         'line' => 125,
                                                                                                                                                         'lookahead' => 0,
                                                                                                                                                         'mod' => '',
                                                                                                                                                         'pattern' => '\\bload_first_existing_class',
                                                                                                                                                         'rdelim' => '/'
                                                                                                                                                       }, 'Parse::RecDescent::Token' )
                                                                                                                                              ],
                                                                                                                                   'line' => 125,
                                                                                                                                   'number' => 1,
                                                                                                                                   'patcount' => 1,
                                                                                                                                   'strcount' => 0,
                                                                                                                                   'uncommit' => undef
                                                                                                                                 }, 'Parse::RecDescent::Production' )
                                                                                                                        ],
                                                                                                             'vars' => ''
                                                                                                           }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_comma' => bless( {
                                                                                         'calls' => [],
                                                                                         'changed' => 0,
                                                                                         'impcount' => 0,
                                                                                         'line' => 125,
                                                                                         'name' => '_alternation_1_of_production_1_of_rule_comma',
                                                                                         'opcount' => 0,
                                                                                         'prods' => [
                                                                                                      bless( {
                                                                                                               'actcount' => 0,
                                                                                                               'dircount' => 0,
                                                                                                               'error' => undef,
                                                                                                               'items' => [
                                                                                                                            bless( {
                                                                                                                                     'description' => '\',\'',
                                                                                                                                     'hashname' => '__STRING1__',
                                                                                                                                     'line' => 125,
                                                                                                                                     'lookahead' => 0,
                                                                                                                                     'pattern' => ','
                                                                                                                                   }, 'Parse::RecDescent::Literal' )
                                                                                                                          ],
                                                                                                               'line' => undef,
                                                                                                               'number' => 0,
                                                                                                               'patcount' => 0,
                                                                                                               'strcount' => 1,
                                                                                                               'uncommit' => undef
                                                                                                             }, 'Parse::RecDescent::Production' ),
                                                                                                      bless( {
                                                                                                               'actcount' => 0,
                                                                                                               'dircount' => 0,
                                                                                                               'error' => undef,
                                                                                                               'items' => [
                                                                                                                            bless( {
                                                                                                                                     'description' => '\'=>\'',
                                                                                                                                     'hashname' => '__STRING1__',
                                                                                                                                     'line' => 125,
                                                                                                                                     'lookahead' => 0,
                                                                                                                                     'pattern' => '=>'
                                                                                                                                   }, 'Parse::RecDescent::Literal' )
                                                                                                                          ],
                                                                                                               'line' => 125,
                                                                                                               'number' => 1,
                                                                                                               'patcount' => 0,
                                                                                                               'strcount' => 1,
                                                                                                               'uncommit' => undef
                                                                                                             }, 'Parse::RecDescent::Production' )
                                                                                                    ],
                                                                                         'vars' => ''
                                                                                       }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_hash_pair' => bless( {
                                                                                             'calls' => [],
                                                                                             'changed' => 0,
                                                                                             'impcount' => 0,
                                                                                             'line' => 125,
                                                                                             'name' => '_alternation_1_of_production_1_of_rule_hash_pair',
                                                                                             'opcount' => 0,
                                                                                             'prods' => [
                                                                                                          bless( {
                                                                                                                   'actcount' => 0,
                                                                                                                   'dircount' => 1,
                                                                                                                   'error' => undef,
                                                                                                                   'items' => [
                                                                                                                                bless( {
                                                                                                                                         'code' => 'my ($match,@res);
                     ($match,$text,undef,@res) =
                          Text::Balanced::extract_quotelike($text,$skip);
                      $match ? \\@res : undef;
                    ',
                                                                                                                                         'hashname' => '__DIRECTIVE1__',
                                                                                                                                         'line' => 125,
                                                                                                                                         'lookahead' => 0,
                                                                                                                                         'name' => '<perl_quotelike>'
                                                                                                                                       }, 'Parse::RecDescent::Directive' )
                                                                                                                              ],
                                                                                                                   'line' => undef,
                                                                                                                   'number' => 0,
                                                                                                                   'patcount' => 0,
                                                                                                                   'strcount' => 0,
                                                                                                                   'uncommit' => undef
                                                                                                                 }, 'Parse::RecDescent::Production' ),
                                                                                                          bless( {
                                                                                                                   'actcount' => 0,
                                                                                                                   'dircount' => 0,
                                                                                                                   'error' => undef,
                                                                                                                   'items' => [
                                                                                                                                bless( {
                                                                                                                                         'description' => '/[^\\\\s,\\}]+/',
                                                                                                                                         'hashname' => '__PATTERN1__',
                                                                                                                                         'ldelim' => '/',
                                                                                                                                         'line' => 125,
                                                                                                                                         'lookahead' => 0,
                                                                                                                                         'mod' => '',
                                                                                                                                         'pattern' => '[^\\s,}]+',
                                                                                                                                         'rdelim' => '/'
                                                                                                                                       }, 'Parse::RecDescent::Token' )
                                                                                                                              ],
                                                                                                                   'line' => 125,
                                                                                                                   'number' => 1,
                                                                                                                   'patcount' => 1,
                                                                                                                   'strcount' => 0,
                                                                                                                   'uncommit' => undef
                                                                                                                 }, 'Parse::RecDescent::Production' )
                                                                                                        ],
                                                                                             'vars' => ''
                                                                                           }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_module_runtime_require_module' => bless( {
                                                                                                                 'calls' => [],
                                                                                                                 'changed' => 0,
                                                                                                                 'impcount' => 0,
                                                                                                                 'line' => 125,
                                                                                                                 'name' => '_alternation_1_of_production_1_of_rule_module_runtime_require_module',
                                                                                                                 'opcount' => 0,
                                                                                                                 'prods' => [
                                                                                                                              bless( {
                                                                                                                                       'actcount' => 0,
                                                                                                                                       'dircount' => 0,
                                                                                                                                       'error' => undef,
                                                                                                                                       'items' => [
                                                                                                                                                    bless( {
                                                                                                                                                             'description' => '\'Module::Runtime::require_module(\'',
                                                                                                                                                             'hashname' => '__STRING1__',
                                                                                                                                                             'line' => 125,
                                                                                                                                                             'lookahead' => 0,
                                                                                                                                                             'pattern' => 'Module::Runtime::require_module('
                                                                                                                                                           }, 'Parse::RecDescent::Literal' )
                                                                                                                                                  ],
                                                                                                                                       'line' => undef,
                                                                                                                                       'number' => 0,
                                                                                                                                       'patcount' => 0,
                                                                                                                                       'strcount' => 1,
                                                                                                                                       'uncommit' => undef
                                                                                                                                     }, 'Parse::RecDescent::Production' ),
                                                                                                                              bless( {
                                                                                                                                       'actcount' => 0,
                                                                                                                                       'dircount' => 0,
                                                                                                                                       'error' => undef,
                                                                                                                                       'items' => [
                                                                                                                                                    bless( {
                                                                                                                                                             'description' => '/\\\\brequire_module\\\\(/',
                                                                                                                                                             'hashname' => '__PATTERN1__',
                                                                                                                                                             'ldelim' => '/',
                                                                                                                                                             'line' => 125,
                                                                                                                                                             'lookahead' => 0,
                                                                                                                                                             'mod' => '',
                                                                                                                                                             'pattern' => '\\brequire_module\\(',
                                                                                                                                                             'rdelim' => '/'
                                                                                                                                                           }, 'Parse::RecDescent::Token' )
                                                                                                                                                  ],
                                                                                                                                       'line' => 125,
                                                                                                                                       'number' => 1,
                                                                                                                                       'patcount' => 1,
                                                                                                                                       'strcount' => 0,
                                                                                                                                       'uncommit' => undef
                                                                                                                                     }, 'Parse::RecDescent::Production' )
                                                                                                                            ],
                                                                                                                 'vars' => ''
                                                                                                               }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_module_runtime_use' => bless( {
                                                                                                      'calls' => [
                                                                                                                   '_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use',
                                                                                                                   '_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use'
                                                                                                                 ],
                                                                                                      'changed' => 0,
                                                                                                      'impcount' => 1,
                                                                                                      'line' => 125,
                                                                                                      'name' => '_alternation_1_of_production_1_of_rule_module_runtime_use',
                                                                                                      'opcount' => 0,
                                                                                                      'prods' => [
                                                                                                                   bless( {
                                                                                                                            'actcount' => 0,
                                                                                                                            'dircount' => 0,
                                                                                                                            'error' => undef,
                                                                                                                            'items' => [
                                                                                                                                         bless( {
                                                                                                                                                  'argcode' => undef,
                                                                                                                                                  'implicit' => '\'Module::Runtime::\'',
                                                                                                                                                  'line' => 125,
                                                                                                                                                  'lookahead' => 0,
                                                                                                                                                  'matchrule' => 0,
                                                                                                                                                  'subrule' => '_alternation_1_of_production_1_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use'
                                                                                                                                                }, 'Parse::RecDescent::Subrule' )
                                                                                                                                       ],
                                                                                                                            'line' => undef,
                                                                                                                            'number' => 0,
                                                                                                                            'patcount' => 0,
                                                                                                                            'strcount' => 0,
                                                                                                                            'uncommit' => undef
                                                                                                                          }, 'Parse::RecDescent::Production' ),
                                                                                                                   bless( {
                                                                                                                            'actcount' => 0,
                                                                                                                            'dircount' => 0,
                                                                                                                            'error' => undef,
                                                                                                                            'items' => [
                                                                                                                                         bless( {
                                                                                                                                                  'argcode' => undef,
                                                                                                                                                  'implicit' => '/\\\\b/',
                                                                                                                                                  'line' => 125,
                                                                                                                                                  'lookahead' => 0,
                                                                                                                                                  'matchrule' => 0,
                                                                                                                                                  'subrule' => '_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use'
                                                                                                                                                }, 'Parse::RecDescent::Subrule' )
                                                                                                                                       ],
                                                                                                                            'line' => 125,
                                                                                                                            'number' => 1,
                                                                                                                            'patcount' => 0,
                                                                                                                            'strcount' => 0,
                                                                                                                            'uncommit' => undef
                                                                                                                          }, 'Parse::RecDescent::Production' )
                                                                                                                 ],
                                                                                                      'vars' => ''
                                                                                                    }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_module_runtime_use_fcn' => bless( {
                                                                                                          'calls' => [],
                                                                                                          'changed' => 0,
                                                                                                          'impcount' => 0,
                                                                                                          'line' => 125,
                                                                                                          'name' => '_alternation_1_of_production_1_of_rule_module_runtime_use_fcn',
                                                                                                          'opcount' => 0,
                                                                                                          'prods' => [
                                                                                                                       bless( {
                                                                                                                                'actcount' => 0,
                                                                                                                                'dircount' => 0,
                                                                                                                                'error' => undef,
                                                                                                                                'items' => [
                                                                                                                                             bless( {
                                                                                                                                                      'description' => '\'use_module\'',
                                                                                                                                                      'hashname' => '__STRING1__',
                                                                                                                                                      'line' => 125,
                                                                                                                                                      'lookahead' => 0,
                                                                                                                                                      'pattern' => 'use_module'
                                                                                                                                                    }, 'Parse::RecDescent::Literal' )
                                                                                                                                           ],
                                                                                                                                'line' => undef,
                                                                                                                                'number' => 0,
                                                                                                                                'patcount' => 0,
                                                                                                                                'strcount' => 1,
                                                                                                                                'uncommit' => undef
                                                                                                                              }, 'Parse::RecDescent::Production' ),
                                                                                                                       bless( {
                                                                                                                                'actcount' => 0,
                                                                                                                                'dircount' => 0,
                                                                                                                                'error' => undef,
                                                                                                                                'items' => [
                                                                                                                                             bless( {
                                                                                                                                                      'description' => '\'use_package_optimistically\'',
                                                                                                                                                      'hashname' => '__STRING1__',
                                                                                                                                                      'line' => 125,
                                                                                                                                                      'lookahead' => 0,
                                                                                                                                                      'pattern' => 'use_package_optimistically'
                                                                                                                                                    }, 'Parse::RecDescent::Literal' )
                                                                                                                                           ],
                                                                                                                                'line' => 125,
                                                                                                                                'number' => 1,
                                                                                                                                'patcount' => 0,
                                                                                                                                'strcount' => 1,
                                                                                                                                'uncommit' => undef
                                                                                                                              }, 'Parse::RecDescent::Production' )
                                                                                                                     ],
                                                                                                          'vars' => ''
                                                                                                        }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_no_stuff' => bless( {
                                                                                            'calls' => [
                                                                                                         'base',
                                                                                                         'version',
                                                                                                         'module'
                                                                                                       ],
                                                                                            'changed' => 0,
                                                                                            'impcount' => 0,
                                                                                            'line' => 125,
                                                                                            'name' => '_alternation_1_of_production_1_of_rule_no_stuff',
                                                                                            'opcount' => 0,
                                                                                            'prods' => [
                                                                                                         bless( {
                                                                                                                  'actcount' => 0,
                                                                                                                  'dircount' => 0,
                                                                                                                  'error' => undef,
                                                                                                                  'items' => [
                                                                                                                               bless( {
                                                                                                                                        'argcode' => undef,
                                                                                                                                        'implicit' => undef,
                                                                                                                                        'line' => 125,
                                                                                                                                        'lookahead' => 0,
                                                                                                                                        'matchrule' => 0,
                                                                                                                                        'subrule' => 'base'
                                                                                                                                      }, 'Parse::RecDescent::Subrule' )
                                                                                                                             ],
                                                                                                                  'line' => undef,
                                                                                                                  'number' => 0,
                                                                                                                  'patcount' => 0,
                                                                                                                  'strcount' => 0,
                                                                                                                  'uncommit' => undef
                                                                                                                }, 'Parse::RecDescent::Production' ),
                                                                                                         bless( {
                                                                                                                  'actcount' => 0,
                                                                                                                  'dircount' => 0,
                                                                                                                  'error' => undef,
                                                                                                                  'items' => [
                                                                                                                               bless( {
                                                                                                                                        'argcode' => undef,
                                                                                                                                        'implicit' => undef,
                                                                                                                                        'line' => 125,
                                                                                                                                        'lookahead' => 0,
                                                                                                                                        'matchrule' => 0,
                                                                                                                                        'subrule' => 'version'
                                                                                                                                      }, 'Parse::RecDescent::Subrule' )
                                                                                                                             ],
                                                                                                                  'line' => 125,
                                                                                                                  'number' => 1,
                                                                                                                  'patcount' => 0,
                                                                                                                  'strcount' => 0,
                                                                                                                  'uncommit' => undef
                                                                                                                }, 'Parse::RecDescent::Production' ),
                                                                                                         bless( {
                                                                                                                  'actcount' => 0,
                                                                                                                  'dircount' => 0,
                                                                                                                  'error' => undef,
                                                                                                                  'items' => [
                                                                                                                               bless( {
                                                                                                                                        'argcode' => undef,
                                                                                                                                        'implicit' => undef,
                                                                                                                                        'line' => 125,
                                                                                                                                        'lookahead' => 0,
                                                                                                                                        'matchrule' => 0,
                                                                                                                                        'subrule' => 'module'
                                                                                                                                      }, 'Parse::RecDescent::Subrule' )
                                                                                                                             ],
                                                                                                                  'line' => 125,
                                                                                                                  'number' => 2,
                                                                                                                  'patcount' => 0,
                                                                                                                  'strcount' => 0,
                                                                                                                  'uncommit' => undef
                                                                                                                }, 'Parse::RecDescent::Production' )
                                                                                                       ],
                                                                                            'vars' => ''
                                                                                          }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_require_stuff' => bless( {
                                                                                                 'calls' => [
                                                                                                              'version',
                                                                                                              'require_name',
                                                                                                              'module'
                                                                                                            ],
                                                                                                 'changed' => 0,
                                                                                                 'impcount' => 0,
                                                                                                 'line' => 125,
                                                                                                 'name' => '_alternation_1_of_production_1_of_rule_require_stuff',
                                                                                                 'opcount' => 0,
                                                                                                 'prods' => [
                                                                                                              bless( {
                                                                                                                       'actcount' => 0,
                                                                                                                       'dircount' => 0,
                                                                                                                       'error' => undef,
                                                                                                                       'items' => [
                                                                                                                                    bless( {
                                                                                                                                             'argcode' => undef,
                                                                                                                                             'implicit' => undef,
                                                                                                                                             'line' => 125,
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'matchrule' => 0,
                                                                                                                                             'subrule' => 'version'
                                                                                                                                           }, 'Parse::RecDescent::Subrule' )
                                                                                                                                  ],
                                                                                                                       'line' => undef,
                                                                                                                       'number' => 0,
                                                                                                                       'patcount' => 0,
                                                                                                                       'strcount' => 0,
                                                                                                                       'uncommit' => undef
                                                                                                                     }, 'Parse::RecDescent::Production' ),
                                                                                                              bless( {
                                                                                                                       'actcount' => 0,
                                                                                                                       'dircount' => 0,
                                                                                                                       'error' => undef,
                                                                                                                       'items' => [
                                                                                                                                    bless( {
                                                                                                                                             'argcode' => undef,
                                                                                                                                             'implicit' => undef,
                                                                                                                                             'line' => 125,
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'matchrule' => 0,
                                                                                                                                             'subrule' => 'require_name'
                                                                                                                                           }, 'Parse::RecDescent::Subrule' )
                                                                                                                                  ],
                                                                                                                       'line' => 125,
                                                                                                                       'number' => 1,
                                                                                                                       'patcount' => 0,
                                                                                                                       'strcount' => 0,
                                                                                                                       'uncommit' => undef
                                                                                                                     }, 'Parse::RecDescent::Production' ),
                                                                                                              bless( {
                                                                                                                       'actcount' => 0,
                                                                                                                       'dircount' => 0,
                                                                                                                       'error' => undef,
                                                                                                                       'items' => [
                                                                                                                                    bless( {
                                                                                                                                             'argcode' => undef,
                                                                                                                                             'implicit' => undef,
                                                                                                                                             'line' => 125,
                                                                                                                                             'lookahead' => 0,
                                                                                                                                             'matchrule' => 0,
                                                                                                                                             'subrule' => 'module'
                                                                                                                                           }, 'Parse::RecDescent::Subrule' )
                                                                                                                                  ],
                                                                                                                       'line' => 125,
                                                                                                                       'number' => 2,
                                                                                                                       'patcount' => 0,
                                                                                                                       'strcount' => 0,
                                                                                                                       'uncommit' => undef
                                                                                                                     }, 'Parse::RecDescent::Production' )
                                                                                                            ],
                                                                                                 'vars' => ''
                                                                                               }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_1_of_rule_use_stuff' => bless( {
                                                                                             'calls' => [
                                                                                                          'base',
                                                                                                          'parent',
                                                                                                          'version',
                                                                                                          'module'
                                                                                                        ],
                                                                                             'changed' => 0,
                                                                                             'impcount' => 0,
                                                                                             'line' => 125,
                                                                                             'name' => '_alternation_1_of_production_1_of_rule_use_stuff',
                                                                                             'opcount' => 0,
                                                                                             'prods' => [
                                                                                                          bless( {
                                                                                                                   'actcount' => 0,
                                                                                                                   'dircount' => 0,
                                                                                                                   'error' => undef,
                                                                                                                   'items' => [
                                                                                                                                bless( {
                                                                                                                                         'argcode' => undef,
                                                                                                                                         'implicit' => undef,
                                                                                                                                         'line' => 125,
                                                                                                                                         'lookahead' => 0,
                                                                                                                                         'matchrule' => 0,
                                                                                                                                         'subrule' => 'base'
                                                                                                                                       }, 'Parse::RecDescent::Subrule' )
                                                                                                                              ],
                                                                                                                   'line' => undef,
                                                                                                                   'number' => 0,
                                                                                                                   'patcount' => 0,
                                                                                                                   'strcount' => 0,
                                                                                                                   'uncommit' => undef
                                                                                                                 }, 'Parse::RecDescent::Production' ),
                                                                                                          bless( {
                                                                                                                   'actcount' => 0,
                                                                                                                   'dircount' => 0,
                                                                                                                   'error' => undef,
                                                                                                                   'items' => [
                                                                                                                                bless( {
                                                                                                                                         'argcode' => undef,
                                                                                                                                         'implicit' => undef,
                                                                                                                                         'line' => 125,
                                                                                                                                         'lookahead' => 0,
                                                                                                                                         'matchrule' => 0,
                                                                                                                                         'subrule' => 'parent'
                                                                                                                                       }, 'Parse::RecDescent::Subrule' )
                                                                                                                              ],
                                                                                                                   'line' => 125,
                                                                                                                   'number' => 1,
                                                                                                                   'patcount' => 0,
                                                                                                                   'strcount' => 0,
                                                                                                                   'uncommit' => undef
                                                                                                                 }, 'Parse::RecDescent::Production' ),
                                                                                                          bless( {
                                                                                                                   'actcount' => 0,
                                                                                                                   'dircount' => 0,
                                                                                                                   'error' => undef,
                                                                                                                   'items' => [
                                                                                                                                bless( {
                                                                                                                                         'argcode' => undef,
                                                                                                                                         'implicit' => undef,
                                                                                                                                         'line' => 125,
                                                                                                                                         'lookahead' => 0,
                                                                                                                                         'matchrule' => 0,
                                                                                                                                         'subrule' => 'version'
                                                                                                                                       }, 'Parse::RecDescent::Subrule' )
                                                                                                                              ],
                                                                                                                   'line' => 125,
                                                                                                                   'number' => 2,
                                                                                                                   'patcount' => 0,
                                                                                                                   'strcount' => 0,
                                                                                                                   'uncommit' => undef
                                                                                                                 }, 'Parse::RecDescent::Production' ),
                                                                                                          bless( {
                                                                                                                   'actcount' => 0,
                                                                                                                   'dircount' => 0,
                                                                                                                   'error' => undef,
                                                                                                                   'items' => [
                                                                                                                                bless( {
                                                                                                                                         'argcode' => undef,
                                                                                                                                         'implicit' => undef,
                                                                                                                                         'line' => 125,
                                                                                                                                         'lookahead' => 0,
                                                                                                                                         'matchrule' => 0,
                                                                                                                                         'subrule' => 'module'
                                                                                                                                       }, 'Parse::RecDescent::Subrule' )
                                                                                                                              ],
                                                                                                                   'line' => 125,
                                                                                                                   'number' => 3,
                                                                                                                   'patcount' => 0,
                                                                                                                   'strcount' => 0,
                                                                                                                   'uncommit' => undef
                                                                                                                 }, 'Parse::RecDescent::Production' )
                                                                                                        ],
                                                                                             'vars' => ''
                                                                                           }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load' => bless( {
                                                                                                                                     'calls' => [
                                                                                                                                                  'class_load_functions'
                                                                                                                                                ],
                                                                                                                                     'changed' => 0,
                                                                                                                                     'impcount' => 0,
                                                                                                                                     'line' => 125,
                                                                                                                                     'name' => '_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_class_load',
                                                                                                                                     'opcount' => 0,
                                                                                                                                     'prods' => [
                                                                                                                                                  bless( {
                                                                                                                                                           'actcount' => 0,
                                                                                                                                                           'dircount' => 0,
                                                                                                                                                           'error' => undef,
                                                                                                                                                           'items' => [
                                                                                                                                                                        bless( {
                                                                                                                                                                                 'description' => '/\\\\b/',
                                                                                                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                                                                                                 'ldelim' => '/',
                                                                                                                                                                                 'line' => 125,
                                                                                                                                                                                 'lookahead' => 0,
                                                                                                                                                                                 'mod' => '',
                                                                                                                                                                                 'pattern' => '\\b',
                                                                                                                                                                                 'rdelim' => '/'
                                                                                                                                                                               }, 'Parse::RecDescent::Token' ),
                                                                                                                                                                        bless( {
                                                                                                                                                                                 'argcode' => undef,
                                                                                                                                                                                 'implicit' => undef,
                                                                                                                                                                                 'line' => 125,
                                                                                                                                                                                 'lookahead' => 0,
                                                                                                                                                                                 'matchrule' => 0,
                                                                                                                                                                                 'subrule' => 'class_load_functions'
                                                                                                                                                                               }, 'Parse::RecDescent::Subrule' )
                                                                                                                                                                      ],
                                                                                                                                                           'line' => undef,
                                                                                                                                                           'number' => 0,
                                                                                                                                                           'patcount' => 1,
                                                                                                                                                           'strcount' => 0,
                                                                                                                                                           'uncommit' => undef
                                                                                                                                                         }, 'Parse::RecDescent::Production' )
                                                                                                                                                ],
                                                                                                                                     'vars' => ''
                                                                                                                                   }, 'Parse::RecDescent::Rule' ),
                              '_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use' => bless( {
                                                                                                                                             'calls' => [
                                                                                                                                                          'module_runtime_use_fcn'
                                                                                                                                                        ],
                                                                                                                                             'changed' => 0,
                                                                                                                                             'impcount' => 0,
                                                                                                                                             'line' => 125,
                                                                                                                                             'name' => '_alternation_1_of_production_2_of_rule__alternation_1_of_production_1_of_rule_module_runtime_use',
                                                                                                                                             'opcount' => 0,
                                                                                                                                             'prods' => [
                                                                                                                                                          bless( {
                                                                                                                                                                   'actcount' => 0,
                                                                                                                                                                   'dircount' => 0,
                                                                                                                                                                   'error' => undef,
                                                                                                                                                                   'items' => [
                                                                                                                                                                                bless( {
                                                                                                                                                                                         'description' => '/\\\\b/',
                                                                                                                                                                                         'hashname' => '__PATTERN1__',
                                                                                                                                                                                         'ldelim' => '/',
                                                                                                                                                                                         'line' => 125,
                                                                                                                                                                                         'lookahead' => 0,
                                                                                                                                                                                         'mod' => '',
                                                                                                                                                                                         'pattern' => '\\b',
                                                                                                                                                                                         'rdelim' => '/'
                                                                                                                                                                                       }, 'Parse::RecDescent::Token' ),
                                                                                                                                                                                bless( {
                                                                                                                                                                                         'argcode' => undef,
                                                                                                                                                                                         'implicit' => undef,
                                                                                                                                                                                         'line' => 125,
                                                                                                                                                                                         'lookahead' => 0,
                                                                                                                                                                                         'matchrule' => 0,
                                                                                                                                                                                         'subrule' => 'module_runtime_use_fcn'
                                                                                                                                                                                       }, 'Parse::RecDescent::Subrule' ),
                                                                                                                                                                                bless( {
                                                                                                                                                                                         'description' => '\'(\'',
                                                                                                                                                                                         'hashname' => '__STRING1__',
                                                                                                                                                                                         'line' => 125,
                                                                                                                                                                                         'lookahead' => 0,
                                                                                                                                                                                         'pattern' => '('
                                                                                                                                                                                       }, 'Parse::RecDescent::Literal' )
                                                                                                                                                                              ],
                                                                                                                                                                   'line' => undef,
                                                                                                                                                                   'number' => 0,
                                                                                                                                                                   'patcount' => 1,
                                                                                                                                                                   'strcount' => 1,
                                                                                                                                                                   'uncommit' => undef
                                                                                                                                                                 }, 'Parse::RecDescent::Production' )
                                                                                                                                                        ],
                                                                                                                                             'vars' => ''
                                                                                                                                           }, 'Parse::RecDescent::Rule' ),
                              'base' => bless( {
                                                 'calls' => [
                                                              'import_list'
                                                            ],
                                                 'changed' => 0,
                                                 'impcount' => 0,
                                                 'line' => 10,
                                                 'name' => 'base',
                                                 'opcount' => 0,
                                                 'prods' => [
                                                              bless( {
                                                                       'actcount' => 0,
                                                                       'dircount' => 0,
                                                                       'error' => undef,
                                                                       'items' => [
                                                                                    bless( {
                                                                                             'description' => '\'base\'',
                                                                                             'hashname' => '__STRING1__',
                                                                                             'line' => 10,
                                                                                             'lookahead' => 0,
                                                                                             'pattern' => 'base'
                                                                                           }, 'Parse::RecDescent::InterpLit' ),
                                                                                    bless( {
                                                                                             'argcode' => undef,
                                                                                             'implicit' => undef,
                                                                                             'line' => 10,
                                                                                             'lookahead' => 0,
                                                                                             'matchrule' => 0,
                                                                                             'subrule' => 'import_list'
                                                                                           }, 'Parse::RecDescent::Subrule' )
                                                                                  ],
                                                                       'line' => undef,
                                                                       'number' => 0,
                                                                       'patcount' => 0,
                                                                       'strcount' => 1,
                                                                       'uncommit' => undef
                                                                     }, 'Parse::RecDescent::Production' )
                                                            ],
                                                 'vars' => ''
                                               }, 'Parse::RecDescent::Rule' ),
                              'class_load' => bless( {
                                                       'calls' => [
                                                                    '_alternation_1_of_production_1_of_rule_class_load',
                                                                    'comma_hashref'
                                                                  ],
                                                       'changed' => 0,
                                                       'impcount' => 1,
                                                       'line' => 78,
                                                       'name' => 'class_load',
                                                       'opcount' => 0,
                                                       'prods' => [
                                                                    bless( {
                                                                             'actcount' => 1,
                                                                             'dircount' => 1,
                                                                             'error' => undef,
                                                                             'items' => [
                                                                                          bless( {
                                                                                                   'argcode' => undef,
                                                                                                   'implicit' => '\'Class::Load::\', or /\\\\b/',
                                                                                                   'line' => 78,
                                                                                                   'lookahead' => 0,
                                                                                                   'matchrule' => 0,
                                                                                                   'subrule' => '_alternation_1_of_production_1_of_rule_class_load'
                                                                                                 }, 'Parse::RecDescent::Subrule' ),
                                                                                          bless( {
                                                                                                   'description' => '\'(\'',
                                                                                                   'hashname' => '__STRING1__',
                                                                                                   'line' => 78,
                                                                                                   'lookahead' => 0,
                                                                                                   'pattern' => '('
                                                                                                 }, 'Parse::RecDescent::Literal' ),
                                                                                          bless( {
                                                                                                   'code' => 'my ($match,@res);
                     ($match,$text,undef,@res) =
                          Text::Balanced::extract_quotelike($text,$skip);
                      $match ? \\@res : undef;
                    ',
                                                                                                   'hashname' => '__DIRECTIVE1__',
                                                                                                   'line' => 78,
                                                                                                   'lookahead' => 0,
                                                                                                   'name' => '<perl_quotelike>'
                                                                                                 }, 'Parse::RecDescent::Directive' ),
                                                                                          bless( {
                                                                                                   'argcode' => undef,
                                                                                                   'expected' => undef,
                                                                                                   'line' => 78,
                                                                                                   'lookahead' => 0,
                                                                                                   'matchrule' => 0,
                                                                                                   'max' => 1,
                                                                                                   'min' => 0,
                                                                                                   'repspec' => '?',
                                                                                                   'subrule' => 'comma_hashref'
                                                                                                 }, 'Parse::RecDescent::Repetition' ),
                                                                                          bless( {
                                                                                                   'description' => '\')\'',
                                                                                                   'hashname' => '__STRING2__',
                                                                                                   'line' => 78,
                                                                                                   'lookahead' => 0,
                                                                                                   'pattern' => ')'
                                                                                                 }, 'Parse::RecDescent::Literal' ),
                                                                                          bless( {
                                                                                                   'code' => '{ $return = $item[3][2] }',
                                                                                                   'hashname' => '__ACTION1__',
                                                                                                   'line' => 79,
                                                                                                   'lookahead' => 0
                                                                                                 }, 'Parse::RecDescent::Action' )
                                                                                        ],
                                                                             'line' => undef,
                                                                             'number' => 0,
                                                                             'patcount' => 0,
                                                                             'strcount' => 2,
                                                                             'uncommit' => undef
                                                                           }, 'Parse::RecDescent::Production' )
                                                                  ],
                                                       'vars' => ''
                                                     }, 'Parse::RecDescent::Rule' ),
                              'class_load_first_existing' => bless( {
                                                                      'calls' => [
                                                                                   '_alternation_1_of_production_1_of_rule_class_load_first_existing',
                                                                                   'first_existing_arg',
                                                                                   'comma_first_existing_arg'
                                                                                 ],
                                                                      'changed' => 0,
                                                                      'impcount' => 1,
                                                                      'line' => 87,
                                                                      'name' => 'class_load_first_existing',
                                                                      'opcount' => 0,
                                                                      'prods' => [
                                                                                   bless( {
                                                                                            'actcount' => 1,
                                                                                            'dircount' => 0,
                                                                                            'error' => undef,
                                                                                            'items' => [
                                                                                                         bless( {
                                                                                                                  'argcode' => undef,
                                                                                                                  'implicit' => '\'Class::Load::load_first_existing_class\', or /\\\\bload_first_existing_class/',
                                                                                                                  'line' => 87,
                                                                                                                  'lookahead' => 0,
                                                                                                                  'matchrule' => 0,
                                                                                                                  'subrule' => '_alternation_1_of_production_1_of_rule_class_load_first_existing'
                                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                                         bless( {
                                                                                                                  'description' => '\'(\'',
                                                                                                                  'hashname' => '__STRING1__',
                                                                                                                  'line' => 87,
                                                                                                                  'lookahead' => 0,
                                                                                                                  'pattern' => '('
                                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                                         bless( {
                                                                                                                  'argcode' => undef,
                                                                                                                  'implicit' => undef,
                                                                                                                  'line' => 87,
                                                                                                                  'lookahead' => 0,
                                                                                                                  'matchrule' => 0,
                                                                                                                  'subrule' => 'first_existing_arg'
                                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                                         bless( {
                                                                                                                  'argcode' => undef,
                                                                                                                  'expected' => undef,
                                                                                                                  'line' => 87,
                                                                                                                  'lookahead' => 0,
                                                                                                                  'matchrule' => 0,
                                                                                                                  'max' => 100000000,
                                                                                                                  'min' => 0,
                                                                                                                  'repspec' => 's?',
                                                                                                                  'subrule' => 'comma_first_existing_arg'
                                                                                                                }, 'Parse::RecDescent::Repetition' ),
                                                                                                         bless( {
                                                                                                                  'description' => '\')\'',
                                                                                                                  'hashname' => '__STRING2__',
                                                                                                                  'line' => 87,
                                                                                                                  'lookahead' => 0,
                                                                                                                  'pattern' => ')'
                                                                                                                }, 'Parse::RecDescent::Literal' ),
                                                                                                         bless( {
                                                                                                                  'code' => '{ $return = $item{first_existing_arg};
                              $return .= " " . join(" ", @{$item{\'comma_first_existing_arg(s?)\'}}) if $item{\'comma_first_existing_arg(s?)\'};
                              1;
                            }',
                                                                                                                  'hashname' => '__ACTION1__',
                                                                                                                  'line' => 88,
                                                                                                                  'lookahead' => 0
                                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                                       ],
                                                                                            'line' => undef,
                                                                                            'number' => 0,
                                                                                            'patcount' => 0,
                                                                                            'strcount' => 2,
                                                                                            'uncommit' => undef
                                                                                          }, 'Parse::RecDescent::Production' )
                                                                                 ],
                                                                      'vars' => ''
                                                                    }, 'Parse::RecDescent::Rule' ),
                              'class_load_functions' => bless( {
                                                                 'calls' => [],
                                                                 'changed' => 0,
                                                                 'impcount' => 0,
                                                                 'line' => 76,
                                                                 'name' => 'class_load_functions',
                                                                 'opcount' => 0,
                                                                 'prods' => [
                                                                              bless( {
                                                                                       'actcount' => 0,
                                                                                       'dircount' => 0,
                                                                                       'error' => undef,
                                                                                       'items' => [
                                                                                                    bless( {
                                                                                                             'description' => '\'load_class\'',
                                                                                                             'hashname' => '__STRING1__',
                                                                                                             'line' => 76,
                                                                                                             'lookahead' => 0,
                                                                                                             'pattern' => 'load_class'
                                                                                                           }, 'Parse::RecDescent::Literal' )
                                                                                                  ],
                                                                                       'line' => undef,
                                                                                       'number' => 0,
                                                                                       'patcount' => 0,
                                                                                       'strcount' => 1,
                                                                                       'uncommit' => undef
                                                                                     }, 'Parse::RecDescent::Production' ),
                                                                              bless( {
                                                                                       'actcount' => 0,
                                                                                       'dircount' => 0,
                                                                                       'error' => undef,
                                                                                       'items' => [
                                                                                                    bless( {
                                                                                                             'description' => '\'try_load_class\'',
                                                                                                             'hashname' => '__STRING1__',
                                                                                                             'line' => 76,
                                                                                                             'lookahead' => 0,
                                                                                                             'pattern' => 'try_load_class'
                                                                                                           }, 'Parse::RecDescent::Literal' )
                                                                                                  ],
                                                                                       'line' => 76,
                                                                                       'number' => 1,
                                                                                       'patcount' => 0,
                                                                                       'strcount' => 1,
                                                                                       'uncommit' => undef
                                                                                     }, 'Parse::RecDescent::Production' ),
                                                                              bless( {
                                                                                       'actcount' => 0,
                                                                                       'dircount' => 0,
                                                                                       'error' => undef,
                                                                                       'items' => [
                                                                                                    bless( {
                                                                                                             'description' => '\'load_optional_class\'',
                                                                                                             'hashname' => '__STRING1__',
                                                                                                             'line' => 76,
                                                                                                             'lookahead' => 0,
                                                                                                             'pattern' => 'load_optional_class'
                                                                                                           }, 'Parse::RecDescent::Literal' )
                                                                                                  ],
                                                                                       'line' => 76,
                                                                                       'number' => 2,
                                                                                       'patcount' => 0,
                                                                                       'strcount' => 1,
                                                                                       'uncommit' => undef
                                                                                     }, 'Parse::RecDescent::Production' )
                                                                            ],
                                                                 'vars' => ''
                                                               }, 'Parse::RecDescent::Rule' ),
                              'comma' => bless( {
                                                  'calls' => [
                                                               '_alternation_1_of_production_1_of_rule_comma'
                                                             ],
                                                  'changed' => 0,
                                                  'impcount' => 1,
                                                  'line' => 124,
                                                  'name' => 'comma',
                                                  'opcount' => 0,
                                                  'prods' => [
                                                               bless( {
                                                                        'actcount' => 0,
                                                                        'dircount' => 0,
                                                                        'error' => undef,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'argcode' => undef,
                                                                                              'implicit' => '\',\', or \'=>\'',
                                                                                              'line' => 124,
                                                                                              'lookahead' => 0,
                                                                                              'matchrule' => 0,
                                                                                              'subrule' => '_alternation_1_of_production_1_of_rule_comma'
                                                                                            }, 'Parse::RecDescent::Subrule' )
                                                                                   ],
                                                                        'line' => undef,
                                                                        'number' => 0,
                                                                        'patcount' => 0,
                                                                        'strcount' => 0,
                                                                        'uncommit' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'vars' => ''
                                                }, 'Parse::RecDescent::Rule' ),
                              'comma_first_existing_arg' => bless( {
                                                                     'calls' => [
                                                                                  'comma',
                                                                                  'first_existing_arg'
                                                                                ],
                                                                     'changed' => 0,
                                                                     'impcount' => 0,
                                                                     'line' => 84,
                                                                     'name' => 'comma_first_existing_arg',
                                                                     'opcount' => 0,
                                                                     'prods' => [
                                                                                  bless( {
                                                                                           'actcount' => 1,
                                                                                           'dircount' => 0,
                                                                                           'error' => undef,
                                                                                           'items' => [
                                                                                                        bless( {
                                                                                                                 'argcode' => undef,
                                                                                                                 'implicit' => undef,
                                                                                                                 'line' => 84,
                                                                                                                 'lookahead' => 0,
                                                                                                                 'matchrule' => 0,
                                                                                                                 'subrule' => 'comma'
                                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                                        bless( {
                                                                                                                 'argcode' => undef,
                                                                                                                 'implicit' => undef,
                                                                                                                 'line' => 84,
                                                                                                                 'lookahead' => 0,
                                                                                                                 'matchrule' => 0,
                                                                                                                 'subrule' => 'first_existing_arg'
                                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                                        bless( {
                                                                                                                 'code' => '{ $return = $item{first_existing_arg} }',
                                                                                                                 'hashname' => '__ACTION1__',
                                                                                                                 'line' => 85,
                                                                                                                 'lookahead' => 0
                                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                                      ],
                                                                                           'line' => undef,
                                                                                           'number' => 0,
                                                                                           'patcount' => 0,
                                                                                           'strcount' => 0,
                                                                                           'uncommit' => undef
                                                                                         }, 'Parse::RecDescent::Production' )
                                                                                ],
                                                                     'vars' => ''
                                                                   }, 'Parse::RecDescent::Rule' ),
                              'comma_hash_pair' => bless( {
                                                            'calls' => [
                                                                         'comma',
                                                                         'hash_pair'
                                                                       ],
                                                            'changed' => 0,
                                                            'impcount' => 0,
                                                            'line' => 70,
                                                            'name' => 'comma_hash_pair',
                                                            'opcount' => 0,
                                                            'prods' => [
                                                                         bless( {
                                                                                  'actcount' => 0,
                                                                                  'dircount' => 0,
                                                                                  'error' => undef,
                                                                                  'items' => [
                                                                                               bless( {
                                                                                                        'argcode' => undef,
                                                                                                        'implicit' => undef,
                                                                                                        'line' => 70,
                                                                                                        'lookahead' => 0,
                                                                                                        'matchrule' => 0,
                                                                                                        'subrule' => 'comma'
                                                                                                      }, 'Parse::RecDescent::Subrule' ),
                                                                                               bless( {
                                                                                                        'argcode' => undef,
                                                                                                        'implicit' => undef,
                                                                                                        'line' => 70,
                                                                                                        'lookahead' => 0,
                                                                                                        'matchrule' => 0,
                                                                                                        'subrule' => 'hash_pair'
                                                                                                      }, 'Parse::RecDescent::Subrule' )
                                                                                             ],
                                                                                  'line' => undef,
                                                                                  'number' => 0,
                                                                                  'patcount' => 0,
                                                                                  'strcount' => 0,
                                                                                  'uncommit' => undef
                                                                                }, 'Parse::RecDescent::Production' )
                                                                       ],
                                                            'vars' => ''
                                                          }, 'Parse::RecDescent::Rule' ),
                              'comma_hashref' => bless( {
                                                          'calls' => [
                                                                       'comma',
                                                                       'hashref'
                                                                     ],
                                                          'changed' => 0,
                                                          'impcount' => 0,
                                                          'line' => 74,
                                                          'name' => 'comma_hashref',
                                                          'opcount' => 0,
                                                          'prods' => [
                                                                       bless( {
                                                                                'actcount' => 0,
                                                                                'dircount' => 0,
                                                                                'error' => undef,
                                                                                'items' => [
                                                                                             bless( {
                                                                                                      'argcode' => undef,
                                                                                                      'implicit' => undef,
                                                                                                      'line' => 74,
                                                                                                      'lookahead' => 0,
                                                                                                      'matchrule' => 0,
                                                                                                      'subrule' => 'comma'
                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                             bless( {
                                                                                                      'argcode' => undef,
                                                                                                      'implicit' => undef,
                                                                                                      'line' => 74,
                                                                                                      'lookahead' => 0,
                                                                                                      'matchrule' => 0,
                                                                                                      'subrule' => 'hashref'
                                                                                                    }, 'Parse::RecDescent::Subrule' )
                                                                                           ],
                                                                                'line' => undef,
                                                                                'number' => 0,
                                                                                'patcount' => 0,
                                                                                'strcount' => 0,
                                                                                'uncommit' => undef
                                                                              }, 'Parse::RecDescent::Production' )
                                                                     ],
                                                          'vars' => ''
                                                        }, 'Parse::RecDescent::Rule' ),
                              'comma_list_item' => bless( {
                                                            'calls' => [
                                                                         'comma',
                                                                         'list_item'
                                                                       ],
                                                            'changed' => 0,
                                                            'impcount' => 0,
                                                            'line' => 121,
                                                            'name' => 'comma_list_item',
                                                            'opcount' => 0,
                                                            'prods' => [
                                                                         bless( {
                                                                                  'actcount' => 1,
                                                                                  'dircount' => 0,
                                                                                  'error' => undef,
                                                                                  'items' => [
                                                                                               bless( {
                                                                                                        'argcode' => undef,
                                                                                                        'implicit' => undef,
                                                                                                        'line' => 121,
                                                                                                        'lookahead' => 0,
                                                                                                        'matchrule' => 0,
                                                                                                        'subrule' => 'comma'
                                                                                                      }, 'Parse::RecDescent::Subrule' ),
                                                                                               bless( {
                                                                                                        'argcode' => undef,
                                                                                                        'implicit' => undef,
                                                                                                        'line' => 121,
                                                                                                        'lookahead' => 0,
                                                                                                        'matchrule' => 0,
                                                                                                        'subrule' => 'list_item'
                                                                                                      }, 'Parse::RecDescent::Subrule' ),
                                                                                               bless( {
                                                                                                        'code' => '{ $return=$item{list_item} }',
                                                                                                        'hashname' => '__ACTION1__',
                                                                                                        'line' => 122,
                                                                                                        'lookahead' => 0
                                                                                                      }, 'Parse::RecDescent::Action' )
                                                                                             ],
                                                                                  'line' => undef,
                                                                                  'number' => 0,
                                                                                  'patcount' => 0,
                                                                                  'strcount' => 0,
                                                                                  'uncommit' => undef
                                                                                }, 'Parse::RecDescent::Production' )
                                                                       ],
                                                            'vars' => ''
                                                          }, 'Parse::RecDescent::Rule' ),
                              'eos' => bless( {
                                                'calls' => [],
                                                'changed' => 0,
                                                'impcount' => 0,
                                                'line' => 101,
                                                'name' => 'eos',
                                                'opcount' => 0,
                                                'prods' => [
                                                             bless( {
                                                                      'actcount' => 1,
                                                                      'dircount' => 0,
                                                                      'error' => undef,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'code' => '{ $text=~/^[\\s;]+$/ ? 1 : undef;}',
                                                                                            'hashname' => '__ACTION1__',
                                                                                            'line' => 101,
                                                                                            'lookahead' => 0
                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                 ],
                                                                      'line' => undef,
                                                                      'number' => 0,
                                                                      'patcount' => 0,
                                                                      'strcount' => 0,
                                                                      'uncommit' => undef
                                                                    }, 'Parse::RecDescent::Production' )
                                                           ],
                                                'vars' => ''
                                              }, 'Parse::RecDescent::Rule' ),
                              'first_existing_arg' => bless( {
                                                               'calls' => [
                                                                            'comma_hashref'
                                                                          ],
                                                               'changed' => 0,
                                                               'impcount' => 0,
                                                               'line' => 81,
                                                               'name' => 'first_existing_arg',
                                                               'opcount' => 0,
                                                               'prods' => [
                                                                            bless( {
                                                                                     'actcount' => 1,
                                                                                     'dircount' => 1,
                                                                                     'error' => undef,
                                                                                     'items' => [
                                                                                                  bless( {
                                                                                                           'code' => 'my ($match,@res);
                     ($match,$text,undef,@res) =
                          Text::Balanced::extract_quotelike($text,$skip);
                      $match ? \\@res : undef;
                    ',
                                                                                                           'hashname' => '__DIRECTIVE1__',
                                                                                                           'line' => 81,
                                                                                                           'lookahead' => 0,
                                                                                                           'name' => '<perl_quotelike>'
                                                                                                         }, 'Parse::RecDescent::Directive' ),
                                                                                                  bless( {
                                                                                                           'argcode' => undef,
                                                                                                           'expected' => undef,
                                                                                                           'line' => 81,
                                                                                                           'lookahead' => 0,
                                                                                                           'matchrule' => 0,
                                                                                                           'max' => 1,
                                                                                                           'min' => 0,
                                                                                                           'repspec' => '?',
                                                                                                           'subrule' => 'comma_hashref'
                                                                                                         }, 'Parse::RecDescent::Repetition' ),
                                                                                                  bless( {
                                                                                                           'code' => '{ $return = $item[1][2] }',
                                                                                                           'hashname' => '__ACTION1__',
                                                                                                           'line' => 82,
                                                                                                           'lookahead' => 0
                                                                                                         }, 'Parse::RecDescent::Action' )
                                                                                                ],
                                                                                     'line' => undef,
                                                                                     'number' => 0,
                                                                                     'patcount' => 0,
                                                                                     'strcount' => 0,
                                                                                     'uncommit' => undef
                                                                                   }, 'Parse::RecDescent::Production' )
                                                                          ],
                                                               'vars' => ''
                                                             }, 'Parse::RecDescent::Rule' ),
                              'hash_pair' => bless( {
                                                      'calls' => [
                                                                   'comma',
                                                                   '_alternation_1_of_production_1_of_rule_hash_pair'
                                                                 ],
                                                      'changed' => 0,
                                                      'impcount' => 1,
                                                      'line' => 66,
                                                      'name' => 'hash_pair',
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'actcount' => 0,
                                                                            'dircount' => 0,
                                                                            'error' => undef,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'description' => '/\\\\S+/',
                                                                                                  'hashname' => '__PATTERN1__',
                                                                                                  'ldelim' => '/',
                                                                                                  'line' => 68,
                                                                                                  'lookahead' => 0,
                                                                                                  'mod' => '',
                                                                                                  'pattern' => '\\S+',
                                                                                                  'rdelim' => '/'
                                                                                                }, 'Parse::RecDescent::Token' ),
                                                                                         bless( {
                                                                                                  'argcode' => undef,
                                                                                                  'implicit' => undef,
                                                                                                  'line' => 68,
                                                                                                  'lookahead' => 0,
                                                                                                  'matchrule' => 0,
                                                                                                  'subrule' => 'comma'
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'argcode' => undef,
                                                                                                  'implicit' => '/[^\\\\s,\\}]+/',
                                                                                                  'line' => 68,
                                                                                                  'lookahead' => 0,
                                                                                                  'matchrule' => 0,
                                                                                                  'subrule' => '_alternation_1_of_production_1_of_rule_hash_pair'
                                                                                                }, 'Parse::RecDescent::Subrule' )
                                                                                       ],
                                                                            'line' => undef,
                                                                            'number' => 0,
                                                                            'patcount' => 1,
                                                                            'strcount' => 0,
                                                                            'uncommit' => undef
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'vars' => ''
                                                    }, 'Parse::RecDescent::Rule' ),
                              'hashref' => bless( {
                                                    'calls' => [
                                                                 'hash_pair',
                                                                 'comma_hash_pair'
                                                               ],
                                                    'changed' => 0,
                                                    'impcount' => 0,
                                                    'line' => 72,
                                                    'name' => 'hashref',
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'actcount' => 0,
                                                                          'dircount' => 0,
                                                                          'error' => undef,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'description' => '\'\\{\'',
                                                                                                'hashname' => '__STRING1__',
                                                                                                'line' => 72,
                                                                                                'lookahead' => 0,
                                                                                                'pattern' => '{'
                                                                                              }, 'Parse::RecDescent::Literal' ),
                                                                                       bless( {
                                                                                                'argcode' => undef,
                                                                                                'implicit' => undef,
                                                                                                'line' => 72,
                                                                                                'lookahead' => 0,
                                                                                                'matchrule' => 0,
                                                                                                'subrule' => 'hash_pair'
                                                                                              }, 'Parse::RecDescent::Subrule' ),
                                                                                       bless( {
                                                                                                'argcode' => undef,
                                                                                                'expected' => undef,
                                                                                                'line' => 72,
                                                                                                'lookahead' => 0,
                                                                                                'matchrule' => 0,
                                                                                                'max' => 100000000,
                                                                                                'min' => 0,
                                                                                                'repspec' => 's?',
                                                                                                'subrule' => 'comma_hash_pair'
                                                                                              }, 'Parse::RecDescent::Repetition' ),
                                                                                       bless( {
                                                                                                'description' => '\'\\}\'',
                                                                                                'hashname' => '__STRING2__',
                                                                                                'line' => 72,
                                                                                                'lookahead' => 0,
                                                                                                'pattern' => '}'
                                                                                              }, 'Parse::RecDescent::Literal' )
                                                                                     ],
                                                                          'line' => undef,
                                                                          'number' => 0,
                                                                          'patcount' => 0,
                                                                          'strcount' => 2,
                                                                          'uncommit' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'vars' => ''
                                                  }, 'Parse::RecDescent::Rule' ),
                              'import_list' => bless( {
                                                        'calls' => [
                                                                     'list_item',
                                                                     'comma_list_item'
                                                                   ],
                                                        'changed' => 0,
                                                        'impcount' => 0,
                                                        'line' => 105,
                                                        'name' => 'import_list',
                                                        'opcount' => 0,
                                                        'prods' => [
                                                                     bless( {
                                                                              'actcount' => 1,
                                                                              'dircount' => 0,
                                                                              'error' => undef,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'description' => '/[(]?/',
                                                                                                    'hashname' => '__PATTERN1__',
                                                                                                    'ldelim' => '/',
                                                                                                    'line' => 105,
                                                                                                    'lookahead' => 0,
                                                                                                    'mod' => '',
                                                                                                    'pattern' => '[(]?',
                                                                                                    'rdelim' => '/'
                                                                                                  }, 'Parse::RecDescent::Token' ),
                                                                                           bless( {
                                                                                                    'argcode' => undef,
                                                                                                    'implicit' => undef,
                                                                                                    'line' => 106,
                                                                                                    'lookahead' => 0,
                                                                                                    'matchrule' => 0,
                                                                                                    'subrule' => 'list_item'
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'argcode' => undef,
                                                                                                    'expected' => undef,
                                                                                                    'line' => 107,
                                                                                                    'lookahead' => 0,
                                                                                                    'matchrule' => 0,
                                                                                                    'max' => 100000000,
                                                                                                    'min' => 0,
                                                                                                    'repspec' => 's?',
                                                                                                    'subrule' => 'comma_list_item'
                                                                                                  }, 'Parse::RecDescent::Repetition' ),
                                                                                           bless( {
                                                                                                    'description' => '/[)]?/',
                                                                                                    'hashname' => '__PATTERN2__',
                                                                                                    'ldelim' => '/',
                                                                                                    'line' => 108,
                                                                                                    'lookahead' => 0,
                                                                                                    'mod' => '',
                                                                                                    'pattern' => '[)]?',
                                                                                                    'rdelim' => '/'
                                                                                                  }, 'Parse::RecDescent::Token' ),
                                                                                           bless( {
                                                                                                    'code' => '{ $return=$item[2];
		  $return.=" ".join(" ",@{$item[3]}) if $item[3];
		}',
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'line' => 109,
                                                                                                    'lookahead' => 0
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => undef,
                                                                              'number' => 0,
                                                                              'patcount' => 2,
                                                                              'strcount' => 0,
                                                                              'uncommit' => undef
                                                                            }, 'Parse::RecDescent::Production' ),
                                                                     bless( {
                                                                              'actcount' => 1,
                                                                              'dircount' => 0,
                                                                              'error' => undef,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'description' => '/[(]\\\\s*[)]/',
                                                                                                    'hashname' => '__PATTERN1__',
                                                                                                    'ldelim' => '/',
                                                                                                    'line' => 113,
                                                                                                    'lookahead' => 0,
                                                                                                    'mod' => '',
                                                                                                    'pattern' => '[(]\\s*[)]',
                                                                                                    'rdelim' => '/'
                                                                                                  }, 'Parse::RecDescent::Token' ),
                                                                                           bless( {
                                                                                                    'code' => '{ $return=\'\' }',
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'line' => 113,
                                                                                                    'lookahead' => 0
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => 112,
                                                                              'number' => 1,
                                                                              'patcount' => 1,
                                                                              'strcount' => 0,
                                                                              'uncommit' => undef
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'vars' => ''
                                                      }, 'Parse::RecDescent::Rule' ),
                              'list_item' => bless( {
                                                      'calls' => [],
                                                      'changed' => 0,
                                                      'impcount' => 0,
                                                      'line' => 115,
                                                      'name' => 'list_item',
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'actcount' => 1,
                                                                            'dircount' => 1,
                                                                            'error' => undef,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'code' => 'my ($match,@res);
                     ($match,$text,undef,@res) =
                          Text::Balanced::extract_quotelike($text,$skip);
                      $match ? \\@res : undef;
                    ',
                                                                                                  'hashname' => '__DIRECTIVE1__',
                                                                                                  'line' => 115,
                                                                                                  'lookahead' => 0,
                                                                                                  'name' => '<perl_quotelike>'
                                                                                                }, 'Parse::RecDescent::Directive' ),
                                                                                         bless( {
                                                                                                  'code' => '{ $return=$item[1][2] }',
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'line' => 115,
                                                                                                  'lookahead' => 0
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => undef,
                                                                            'number' => 0,
                                                                            'patcount' => 0,
                                                                            'strcount' => 0,
                                                                            'uncommit' => undef
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'actcount' => 1,
                                                                            'dircount' => 1,
                                                                            'error' => undef,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'code' => 'Text::Balanced::extract_codeblock($text,undef,$skip,\'(){}[]\');
                    ',
                                                                                                  'hashname' => '__DIRECTIVE1__',
                                                                                                  'line' => 117,
                                                                                                  'lookahead' => 0,
                                                                                                  'name' => '<perl_codeblock>'
                                                                                                }, 'Parse::RecDescent::Directive' ),
                                                                                         bless( {
                                                                                                  'code' => '{ $return=$item[1] }',
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'line' => 117,
                                                                                                  'lookahead' => 0
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => 116,
                                                                            'number' => 1,
                                                                            'patcount' => 0,
                                                                            'strcount' => 0,
                                                                            'uncommit' => undef
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'actcount' => 1,
                                                                            'dircount' => 0,
                                                                            'error' => undef,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'description' => '/-?\\\\w+/',
                                                                                                  'hashname' => '__PATTERN1__',
                                                                                                  'ldelim' => '/',
                                                                                                  'line' => 119,
                                                                                                  'lookahead' => 0,
                                                                                                  'mod' => '',
                                                                                                  'pattern' => '-?\\w+',
                                                                                                  'rdelim' => '/'
                                                                                                }, 'Parse::RecDescent::Token' ),
                                                                                         bless( {
                                                                                                  'code' => '{ $return=$item[1] }',
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'line' => 119,
                                                                                                  'lookahead' => 0
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => 118,
                                                                            'number' => 2,
                                                                            'patcount' => 1,
                                                                            'strcount' => 0,
                                                                            'uncommit' => undef
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'vars' => ''
                                                    }, 'Parse::RecDescent::Rule' ),
                              'module' => bless( {
                                                   'calls' => [
                                                                'module_name',
                                                                'module_more'
                                                              ],
                                                   'changed' => 0,
                                                   'impcount' => 0,
                                                   'line' => 15,
                                                   'name' => 'module',
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'actcount' => 1,
                                                                         'dircount' => 0,
                                                                         'error' => undef,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'argcode' => undef,
                                                                                               'implicit' => undef,
                                                                                               'line' => 15,
                                                                                               'lookahead' => 0,
                                                                                               'matchrule' => 0,
                                                                                               'subrule' => 'module_name'
                                                                                             }, 'Parse::RecDescent::Subrule' ),
                                                                                      bless( {
                                                                                               'argcode' => undef,
                                                                                               'implicit' => undef,
                                                                                               'line' => 15,
                                                                                               'lookahead' => 0,
                                                                                               'matchrule' => 0,
                                                                                               'subrule' => 'module_more'
                                                                                             }, 'Parse::RecDescent::Subrule' ),
                                                                                      bless( {
                                                                                               'code' => '{ $return=$item{module_name} }',
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'line' => 16,
                                                                                               'lookahead' => 0
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef,
                                                                         'number' => 0,
                                                                         'patcount' => 0,
                                                                         'strcount' => 0,
                                                                         'uncommit' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'vars' => ''
                                                 }, 'Parse::RecDescent::Rule' ),
                              'module_more' => bless( {
                                                        'calls' => [
                                                                     'eos',
                                                                     'version',
                                                                     'var',
                                                                     'import_list'
                                                                   ],
                                                        'changed' => 0,
                                                        'impcount' => 0,
                                                        'line' => 20,
                                                        'name' => 'module_more',
                                                        'opcount' => 0,
                                                        'prods' => [
                                                                     bless( {
                                                                              'actcount' => 0,
                                                                              'dircount' => 0,
                                                                              'error' => undef,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'argcode' => undef,
                                                                                                    'implicit' => undef,
                                                                                                    'line' => 20,
                                                                                                    'lookahead' => 0,
                                                                                                    'matchrule' => 0,
                                                                                                    'subrule' => 'eos'
                                                                                                  }, 'Parse::RecDescent::Subrule' )
                                                                                         ],
                                                                              'line' => undef,
                                                                              'number' => 0,
                                                                              'patcount' => 0,
                                                                              'strcount' => 0,
                                                                              'uncommit' => undef
                                                                            }, 'Parse::RecDescent::Production' ),
                                                                     bless( {
                                                                              'actcount' => 0,
                                                                              'dircount' => 0,
                                                                              'error' => undef,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'argcode' => undef,
                                                                                                    'expected' => undef,
                                                                                                    'line' => 20,
                                                                                                    'lookahead' => 0,
                                                                                                    'matchrule' => 0,
                                                                                                    'max' => 1,
                                                                                                    'min' => 0,
                                                                                                    'repspec' => '?',
                                                                                                    'subrule' => 'version'
                                                                                                  }, 'Parse::RecDescent::Repetition' ),
                                                                                           bless( {
                                                                                                    'argcode' => undef,
                                                                                                    'expected' => undef,
                                                                                                    'line' => 20,
                                                                                                    'lookahead' => 0,
                                                                                                    'matchrule' => 0,
                                                                                                    'max' => 1,
                                                                                                    'min' => 0,
                                                                                                    'repspec' => '?',
                                                                                                    'subrule' => 'var'
                                                                                                  }, 'Parse::RecDescent::Repetition' ),
                                                                                           bless( {
                                                                                                    'argcode' => undef,
                                                                                                    'expected' => undef,
                                                                                                    'line' => 20,
                                                                                                    'lookahead' => 0,
                                                                                                    'matchrule' => 0,
                                                                                                    'max' => 1,
                                                                                                    'min' => 0,
                                                                                                    'repspec' => '?',
                                                                                                    'subrule' => 'import_list'
                                                                                                  }, 'Parse::RecDescent::Repetition' )
                                                                                         ],
                                                                              'line' => 20,
                                                                              'number' => 1,
                                                                              'patcount' => 0,
                                                                              'strcount' => 0,
                                                                              'uncommit' => undef
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'vars' => ''
                                                      }, 'Parse::RecDescent::Rule' ),
                              'module_name' => bless( {
                                                        'calls' => [],
                                                        'changed' => 0,
                                                        'impcount' => 0,
                                                        'line' => 18,
                                                        'name' => 'module_name',
                                                        'opcount' => 0,
                                                        'prods' => [
                                                                     bless( {
                                                                              'actcount' => 0,
                                                                              'dircount' => 0,
                                                                              'error' => undef,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'description' => '/[\\\\w:]+/',
                                                                                                    'hashname' => '__PATTERN1__',
                                                                                                    'ldelim' => '/',
                                                                                                    'line' => 18,
                                                                                                    'lookahead' => 0,
                                                                                                    'mod' => '',
                                                                                                    'pattern' => '[\\w:]+',
                                                                                                    'rdelim' => '/'
                                                                                                  }, 'Parse::RecDescent::Token' )
                                                                                         ],
                                                                              'line' => undef,
                                                                              'number' => 0,
                                                                              'patcount' => 1,
                                                                              'strcount' => 0,
                                                                              'uncommit' => undef
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'vars' => ''
                                                      }, 'Parse::RecDescent::Rule' ),
                              'module_runtime_require_module' => bless( {
                                                                          'calls' => [
                                                                                       '_alternation_1_of_production_1_of_rule_module_runtime_require_module'
                                                                                     ],
                                                                          'changed' => 0,
                                                                          'impcount' => 1,
                                                                          'line' => 50,
                                                                          'name' => 'module_runtime_require_module',
                                                                          'opcount' => 0,
                                                                          'prods' => [
                                                                                       bless( {
                                                                                                'actcount' => 1,
                                                                                                'dircount' => 1,
                                                                                                'error' => undef,
                                                                                                'items' => [
                                                                                                             bless( {
                                                                                                                      'argcode' => undef,
                                                                                                                      'implicit' => '\'Module::Runtime::require_module(\', or /\\\\brequire_module\\\\(/',
                                                                                                                      'line' => 52,
                                                                                                                      'lookahead' => 0,
                                                                                                                      'matchrule' => 0,
                                                                                                                      'subrule' => '_alternation_1_of_production_1_of_rule_module_runtime_require_module'
                                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                                             bless( {
                                                                                                                      'code' => 'my ($match,@res);
                     ($match,$text,undef,@res) =
                          Text::Balanced::extract_quotelike($text,$skip);
                      $match ? \\@res : undef;
                    ',
                                                                                                                      'hashname' => '__DIRECTIVE1__',
                                                                                                                      'line' => 52,
                                                                                                                      'lookahead' => 0,
                                                                                                                      'name' => '<perl_quotelike>'
                                                                                                                    }, 'Parse::RecDescent::Directive' ),
                                                                                                             bless( {
                                                                                                                      'description' => '\')\'',
                                                                                                                      'hashname' => '__STRING1__',
                                                                                                                      'line' => 52,
                                                                                                                      'lookahead' => 0,
                                                                                                                      'pattern' => ')'
                                                                                                                    }, 'Parse::RecDescent::Literal' ),
                                                                                                             bless( {
                                                                                                                      'code' => '{ $return = $item[2][2] }',
                                                                                                                      'hashname' => '__ACTION1__',
                                                                                                                      'line' => 53,
                                                                                                                      'lookahead' => 0
                                                                                                                    }, 'Parse::RecDescent::Action' )
                                                                                                           ],
                                                                                                'line' => undef,
                                                                                                'number' => 0,
                                                                                                'patcount' => 0,
                                                                                                'strcount' => 1,
                                                                                                'uncommit' => undef
                                                                                              }, 'Parse::RecDescent::Production' )
                                                                                     ],
                                                                          'vars' => ''
                                                                        }, 'Parse::RecDescent::Rule' ),
                              'module_runtime_use' => bless( {
                                                               'calls' => [
                                                                            '_alternation_1_of_production_1_of_rule_module_runtime_use',
                                                                            'module_runtime_version'
                                                                          ],
                                                               'changed' => 0,
                                                               'impcount' => 1,
                                                               'line' => 59,
                                                               'name' => 'module_runtime_use',
                                                               'opcount' => 0,
                                                               'prods' => [
                                                                            bless( {
                                                                                     'actcount' => 1,
                                                                                     'dircount' => 1,
                                                                                     'error' => undef,
                                                                                     'items' => [
                                                                                                  bless( {
                                                                                                           'argcode' => undef,
                                                                                                           'implicit' => '\'Module::Runtime::\', or /\\\\b/',
                                                                                                           'line' => 59,
                                                                                                           'lookahead' => 0,
                                                                                                           'matchrule' => 0,
                                                                                                           'subrule' => '_alternation_1_of_production_1_of_rule_module_runtime_use'
                                                                                                         }, 'Parse::RecDescent::Subrule' ),
                                                                                                  bless( {
                                                                                                           'code' => 'my ($match,@res);
                     ($match,$text,undef,@res) =
                          Text::Balanced::extract_quotelike($text,$skip);
                      $match ? \\@res : undef;
                    ',
                                                                                                           'hashname' => '__DIRECTIVE1__',
                                                                                                           'line' => 59,
                                                                                                           'lookahead' => 0,
                                                                                                           'name' => '<perl_quotelike>'
                                                                                                         }, 'Parse::RecDescent::Directive' ),
                                                                                                  bless( {
                                                                                                           'argcode' => undef,
                                                                                                           'expected' => undef,
                                                                                                           'line' => 59,
                                                                                                           'lookahead' => 0,
                                                                                                           'matchrule' => 0,
                                                                                                           'max' => 1,
                                                                                                           'min' => 0,
                                                                                                           'repspec' => '?',
                                                                                                           'subrule' => 'module_runtime_version'
                                                                                                         }, 'Parse::RecDescent::Repetition' ),
                                                                                                  bless( {
                                                                                                           'description' => '\')\'',
                                                                                                           'hashname' => '__STRING1__',
                                                                                                           'line' => 59,
                                                                                                           'lookahead' => 0,
                                                                                                           'pattern' => ')'
                                                                                                         }, 'Parse::RecDescent::Literal' ),
                                                                                                  bless( {
                                                                                                           'code' => '{ $return = $item[2][2] }',
                                                                                                           'hashname' => '__ACTION1__',
                                                                                                           'line' => 60,
                                                                                                           'lookahead' => 0
                                                                                                         }, 'Parse::RecDescent::Action' )
                                                                                                ],
                                                                                     'line' => undef,
                                                                                     'number' => 0,
                                                                                     'patcount' => 0,
                                                                                     'strcount' => 1,
                                                                                     'uncommit' => undef
                                                                                   }, 'Parse::RecDescent::Production' )
                                                                          ],
                                                               'vars' => ''
                                                             }, 'Parse::RecDescent::Rule' ),
                              'module_runtime_use_fcn' => bless( {
                                                                   'calls' => [
                                                                                '_alternation_1_of_production_1_of_rule_module_runtime_use_fcn'
                                                                              ],
                                                                   'changed' => 0,
                                                                   'impcount' => 1,
                                                                   'line' => 55,
                                                                   'name' => 'module_runtime_use_fcn',
                                                                   'opcount' => 0,
                                                                   'prods' => [
                                                                                bless( {
                                                                                         'actcount' => 0,
                                                                                         'dircount' => 0,
                                                                                         'error' => undef,
                                                                                         'items' => [
                                                                                                      bless( {
                                                                                                               'argcode' => undef,
                                                                                                               'implicit' => '\'use_module\', or \'use_package_optimistically\'',
                                                                                                               'line' => 55,
                                                                                                               'lookahead' => 0,
                                                                                                               'matchrule' => 0,
                                                                                                               'subrule' => '_alternation_1_of_production_1_of_rule_module_runtime_use_fcn'
                                                                                                             }, 'Parse::RecDescent::Subrule' )
                                                                                                    ],
                                                                                         'line' => undef,
                                                                                         'number' => 0,
                                                                                         'patcount' => 0,
                                                                                         'strcount' => 0,
                                                                                         'uncommit' => undef
                                                                                       }, 'Parse::RecDescent::Production' )
                                                                              ],
                                                                   'vars' => ''
                                                                 }, 'Parse::RecDescent::Rule' ),
                              'module_runtime_version' => bless( {
                                                                   'calls' => [
                                                                                'version'
                                                                              ],
                                                                   'changed' => 0,
                                                                   'impcount' => 0,
                                                                   'line' => 57,
                                                                   'name' => 'module_runtime_version',
                                                                   'opcount' => 0,
                                                                   'prods' => [
                                                                                bless( {
                                                                                         'actcount' => 0,
                                                                                         'dircount' => 0,
                                                                                         'error' => undef,
                                                                                         'items' => [
                                                                                                      bless( {
                                                                                                               'description' => '\',\'',
                                                                                                               'hashname' => '__STRING1__',
                                                                                                               'line' => 57,
                                                                                                               'lookahead' => 0,
                                                                                                               'pattern' => ','
                                                                                                             }, 'Parse::RecDescent::Literal' ),
                                                                                                      bless( {
                                                                                                               'description' => '/\\\\s*/',
                                                                                                               'hashname' => '__PATTERN1__',
                                                                                                               'ldelim' => '/',
                                                                                                               'line' => 57,
                                                                                                               'lookahead' => 0,
                                                                                                               'mod' => '',
                                                                                                               'pattern' => '\\s*',
                                                                                                               'rdelim' => '/'
                                                                                                             }, 'Parse::RecDescent::Token' ),
                                                                                                      bless( {
                                                                                                               'argcode' => undef,
                                                                                                               'implicit' => undef,
                                                                                                               'line' => 57,
                                                                                                               'lookahead' => 0,
                                                                                                               'matchrule' => 0,
                                                                                                               'subrule' => 'version'
                                                                                                             }, 'Parse::RecDescent::Subrule' )
                                                                                                    ],
                                                                                         'line' => undef,
                                                                                         'number' => 0,
                                                                                         'patcount' => 1,
                                                                                         'strcount' => 1,
                                                                                         'uncommit' => undef
                                                                                       }, 'Parse::RecDescent::Production' )
                                                                              ],
                                                                   'vars' => ''
                                                                 }, 'Parse::RecDescent::Rule' ),
                              'no_stuff' => bless( {
                                                     'calls' => [
                                                                  '_alternation_1_of_production_1_of_rule_no_stuff'
                                                                ],
                                                     'changed' => 0,
                                                     'impcount' => 1,
                                                     'line' => 46,
                                                     'name' => 'no_stuff',
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'actcount' => 0,
                                                                           'dircount' => 0,
                                                                           'error' => undef,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'argcode' => undef,
                                                                                                 'implicit' => 'base, or version, or module',
                                                                                                 'line' => 46,
                                                                                                 'lookahead' => 0,
                                                                                                 'matchrule' => 0,
                                                                                                 'subrule' => '_alternation_1_of_production_1_of_rule_no_stuff'
                                                                                               }, 'Parse::RecDescent::Subrule' )
                                                                                      ],
                                                                           'line' => undef,
                                                                           'number' => 0,
                                                                           'patcount' => 0,
                                                                           'strcount' => 0,
                                                                           'uncommit' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'vars' => ''
                                                   }, 'Parse::RecDescent::Rule' ),
                              'parent' => bless( {
                                                   'calls' => [
                                                                'import_list'
                                                              ],
                                                   'changed' => 0,
                                                   'impcount' => 0,
                                                   'line' => 12,
                                                   'name' => 'parent',
                                                   'opcount' => 0,
                                                   'prods' => [
                                                                bless( {
                                                                         'actcount' => 1,
                                                                         'dircount' => 0,
                                                                         'error' => undef,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'description' => '\'parent\'',
                                                                                               'hashname' => '__STRING1__',
                                                                                               'line' => 12,
                                                                                               'lookahead' => 0,
                                                                                               'pattern' => 'parent'
                                                                                             }, 'Parse::RecDescent::InterpLit' ),
                                                                                      bless( {
                                                                                               'argcode' => undef,
                                                                                               'implicit' => undef,
                                                                                               'line' => 12,
                                                                                               'lookahead' => 0,
                                                                                               'matchrule' => 0,
                                                                                               'subrule' => 'import_list'
                                                                                             }, 'Parse::RecDescent::Subrule' ),
                                                                                      bless( {
                                                                                               'code' => '{ $return=\'parent\'; $return.=\' \'.$item[2] if $item[2] !~ /^\\s*-norequire\\b/; }',
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'line' => 13,
                                                                                               'lookahead' => 0
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef,
                                                                         'number' => 0,
                                                                         'patcount' => 0,
                                                                         'strcount' => 1,
                                                                         'uncommit' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'vars' => ''
                                                 }, 'Parse::RecDescent::Rule' ),
                              'require_name' => bless( {
                                                         'calls' => [],
                                                         'changed' => 0,
                                                         'impcount' => 0,
                                                         'line' => 31,
                                                         'name' => 'require_name',
                                                         'opcount' => 0,
                                                         'prods' => [
                                                                      bless( {
                                                                               'actcount' => 1,
                                                                               'dircount' => 1,
                                                                               'error' => undef,
                                                                               'items' => [
                                                                                            bless( {
                                                                                                     'code' => 'my ($match,@res);
                     ($match,$text,undef,@res) =
                          Text::Balanced::extract_quotelike($text,$skip);
                      $match ? \\@res : undef;
                    ',
                                                                                                     'hashname' => '__DIRECTIVE1__',
                                                                                                     'line' => 31,
                                                                                                     'lookahead' => 0,
                                                                                                     'name' => '<perl_quotelike>'
                                                                                                   }, 'Parse::RecDescent::Directive' ),
                                                                                            bless( {
                                                                                                     'code' => '{ my $name=$item[1][2];
		  return 1 if ($name=~/\\.pl$/);
		  $name=~s(/)(::)g;
		  $name=~s/\\.pm//;
		  $return=$name;
		}',
                                                                                                     'hashname' => '__ACTION1__',
                                                                                                     'line' => 32,
                                                                                                     'lookahead' => 0
                                                                                                   }, 'Parse::RecDescent::Action' )
                                                                                          ],
                                                                               'line' => undef,
                                                                               'number' => 0,
                                                                               'patcount' => 0,
                                                                               'strcount' => 0,
                                                                               'uncommit' => undef
                                                                             }, 'Parse::RecDescent::Production' )
                                                                    ],
                                                         'vars' => ''
                                                       }, 'Parse::RecDescent::Rule' ),
                              'require_stuff' => bless( {
                                                          'calls' => [
                                                                       '_alternation_1_of_production_1_of_rule_require_stuff'
                                                                     ],
                                                          'changed' => 0,
                                                          'impcount' => 1,
                                                          'line' => 29,
                                                          'name' => 'require_stuff',
                                                          'opcount' => 0,
                                                          'prods' => [
                                                                       bless( {
                                                                                'actcount' => 0,
                                                                                'dircount' => 0,
                                                                                'error' => undef,
                                                                                'items' => [
                                                                                             bless( {
                                                                                                      'argcode' => undef,
                                                                                                      'implicit' => 'version, or require_name, or module',
                                                                                                      'line' => 29,
                                                                                                      'lookahead' => 0,
                                                                                                      'matchrule' => 0,
                                                                                                      'subrule' => '_alternation_1_of_production_1_of_rule_require_stuff'
                                                                                                    }, 'Parse::RecDescent::Subrule' )
                                                                                           ],
                                                                                'line' => undef,
                                                                                'number' => 0,
                                                                                'patcount' => 0,
                                                                                'strcount' => 0,
                                                                                'uncommit' => undef
                                                                              }, 'Parse::RecDescent::Production' )
                                                                     ],
                                                          'vars' => ''
                                                        }, 'Parse::RecDescent::Rule' ),
                              'token_class_load' => bless( {
                                                             'calls' => [
                                                                          'class_load',
                                                                          'class_load_first_existing'
                                                                        ],
                                                             'changed' => 0,
                                                             'impcount' => 0,
                                                             'line' => 93,
                                                             'name' => 'token_class_load',
                                                             'opcount' => 0,
                                                             'prods' => [
                                                                          bless( {
                                                                                   'actcount' => 0,
                                                                                   'dircount' => 0,
                                                                                   'error' => undef,
                                                                                   'items' => [
                                                                                                bless( {
                                                                                                         'argcode' => undef,
                                                                                                         'implicit' => undef,
                                                                                                         'line' => 93,
                                                                                                         'lookahead' => 0,
                                                                                                         'matchrule' => 0,
                                                                                                         'subrule' => 'class_load'
                                                                                                       }, 'Parse::RecDescent::Subrule' )
                                                                                              ],
                                                                                   'line' => undef,
                                                                                   'number' => 0,
                                                                                   'patcount' => 0,
                                                                                   'strcount' => 0,
                                                                                   'uncommit' => undef
                                                                                 }, 'Parse::RecDescent::Production' ),
                                                                          bless( {
                                                                                   'actcount' => 0,
                                                                                   'dircount' => 0,
                                                                                   'error' => undef,
                                                                                   'items' => [
                                                                                                bless( {
                                                                                                         'argcode' => undef,
                                                                                                         'implicit' => undef,
                                                                                                         'line' => 93,
                                                                                                         'lookahead' => 0,
                                                                                                         'matchrule' => 0,
                                                                                                         'subrule' => 'class_load_first_existing'
                                                                                                       }, 'Parse::RecDescent::Subrule' )
                                                                                              ],
                                                                                   'line' => 93,
                                                                                   'number' => 1,
                                                                                   'patcount' => 0,
                                                                                   'strcount' => 0,
                                                                                   'uncommit' => undef
                                                                                 }, 'Parse::RecDescent::Production' )
                                                                        ],
                                                             'vars' => ''
                                                           }, 'Parse::RecDescent::Rule' ),
                              'token_module_runtime' => bless( {
                                                                 'calls' => [
                                                                              'module_runtime_require_module',
                                                                              'module_runtime_use'
                                                                            ],
                                                                 'changed' => 0,
                                                                 'impcount' => 0,
                                                                 'line' => 62,
                                                                 'name' => 'token_module_runtime',
                                                                 'opcount' => 0,
                                                                 'prods' => [
                                                                              bless( {
                                                                                       'actcount' => 0,
                                                                                       'dircount' => 0,
                                                                                       'error' => undef,
                                                                                       'items' => [
                                                                                                    bless( {
                                                                                                             'argcode' => undef,
                                                                                                             'implicit' => undef,
                                                                                                             'line' => 62,
                                                                                                             'lookahead' => 0,
                                                                                                             'matchrule' => 0,
                                                                                                             'subrule' => 'module_runtime_require_module'
                                                                                                           }, 'Parse::RecDescent::Subrule' )
                                                                                                  ],
                                                                                       'line' => undef,
                                                                                       'number' => 0,
                                                                                       'patcount' => 0,
                                                                                       'strcount' => 0,
                                                                                       'uncommit' => undef
                                                                                     }, 'Parse::RecDescent::Production' ),
                                                                              bless( {
                                                                                       'actcount' => 0,
                                                                                       'dircount' => 0,
                                                                                       'error' => undef,
                                                                                       'items' => [
                                                                                                    bless( {
                                                                                                             'argcode' => undef,
                                                                                                             'implicit' => undef,
                                                                                                             'line' => 62,
                                                                                                             'lookahead' => 0,
                                                                                                             'matchrule' => 0,
                                                                                                             'subrule' => 'module_runtime_use'
                                                                                                           }, 'Parse::RecDescent::Subrule' )
                                                                                                  ],
                                                                                       'line' => 62,
                                                                                       'number' => 1,
                                                                                       'patcount' => 0,
                                                                                       'strcount' => 0,
                                                                                       'uncommit' => undef
                                                                                     }, 'Parse::RecDescent::Production' )
                                                                            ],
                                                                 'vars' => ''
                                                               }, 'Parse::RecDescent::Rule' ),
                              'token_no' => bless( {
                                                     'calls' => [
                                                                  'no_stuff'
                                                                ],
                                                     'changed' => 0,
                                                     'impcount' => 0,
                                                     'line' => 41,
                                                     'name' => 'token_no',
                                                     'opcount' => 0,
                                                     'prods' => [
                                                                  bless( {
                                                                           'actcount' => 1,
                                                                           'dircount' => 0,
                                                                           'error' => undef,
                                                                           'items' => [
                                                                                        bless( {
                                                                                                 'description' => '/\\\\bno\\\\s/',
                                                                                                 'hashname' => '__PATTERN1__',
                                                                                                 'ldelim' => '/',
                                                                                                 'line' => 43,
                                                                                                 'lookahead' => 0,
                                                                                                 'mod' => '',
                                                                                                 'pattern' => '\\bno\\s',
                                                                                                 'rdelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' ),
                                                                                        bless( {
                                                                                                 'argcode' => undef,
                                                                                                 'implicit' => undef,
                                                                                                 'line' => 43,
                                                                                                 'lookahead' => 0,
                                                                                                 'matchrule' => 0,
                                                                                                 'subrule' => 'no_stuff'
                                                                                               }, 'Parse::RecDescent::Subrule' ),
                                                                                        bless( {
                                                                                                 'description' => '/[;\\}]/',
                                                                                                 'hashname' => '__PATTERN2__',
                                                                                                 'ldelim' => '/',
                                                                                                 'line' => 43,
                                                                                                 'lookahead' => 0,
                                                                                                 'mod' => '',
                                                                                                 'pattern' => '[;}]',
                                                                                                 'rdelim' => '/'
                                                                                               }, 'Parse::RecDescent::Token' ),
                                                                                        bless( {
                                                                                                 'code' => '{ $return=$item{no_stuff} }',
                                                                                                 'hashname' => '__ACTION1__',
                                                                                                 'line' => 44,
                                                                                                 'lookahead' => 0
                                                                                               }, 'Parse::RecDescent::Action' )
                                                                                      ],
                                                                           'line' => undef,
                                                                           'number' => 0,
                                                                           'patcount' => 2,
                                                                           'strcount' => 0,
                                                                           'uncommit' => undef
                                                                         }, 'Parse::RecDescent::Production' )
                                                                ],
                                                     'vars' => ''
                                                   }, 'Parse::RecDescent::Rule' ),
                              'token_require' => bless( {
                                                          'calls' => [
                                                                       'require_stuff'
                                                                     ],
                                                          'changed' => 0,
                                                          'impcount' => 0,
                                                          'line' => 24,
                                                          'name' => 'token_require',
                                                          'opcount' => 0,
                                                          'prods' => [
                                                                       bless( {
                                                                                'actcount' => 1,
                                                                                'dircount' => 0,
                                                                                'error' => undef,
                                                                                'items' => [
                                                                                             bless( {
                                                                                                      'description' => '/\\\\brequire\\\\s/',
                                                                                                      'hashname' => '__PATTERN1__',
                                                                                                      'ldelim' => '/',
                                                                                                      'line' => 26,
                                                                                                      'lookahead' => 0,
                                                                                                      'mod' => '',
                                                                                                      'pattern' => '\\brequire\\s',
                                                                                                      'rdelim' => '/'
                                                                                                    }, 'Parse::RecDescent::Token' ),
                                                                                             bless( {
                                                                                                      'argcode' => undef,
                                                                                                      'implicit' => undef,
                                                                                                      'line' => 26,
                                                                                                      'lookahead' => 0,
                                                                                                      'matchrule' => 0,
                                                                                                      'subrule' => 'require_stuff'
                                                                                                    }, 'Parse::RecDescent::Subrule' ),
                                                                                             bless( {
                                                                                                      'description' => '/[;\\}]/',
                                                                                                      'hashname' => '__PATTERN2__',
                                                                                                      'ldelim' => '/',
                                                                                                      'line' => 26,
                                                                                                      'lookahead' => 0,
                                                                                                      'mod' => '',
                                                                                                      'pattern' => '[;}]',
                                                                                                      'rdelim' => '/'
                                                                                                    }, 'Parse::RecDescent::Token' ),
                                                                                             bless( {
                                                                                                      'code' => '{ $return=$item{require_stuff} }',
                                                                                                      'hashname' => '__ACTION1__',
                                                                                                      'line' => 27,
                                                                                                      'lookahead' => 0
                                                                                                    }, 'Parse::RecDescent::Action' )
                                                                                           ],
                                                                                'line' => undef,
                                                                                'number' => 0,
                                                                                'patcount' => 2,
                                                                                'strcount' => 0,
                                                                                'uncommit' => undef
                                                                              }, 'Parse::RecDescent::Production' )
                                                                     ],
                                                          'vars' => ''
                                                        }, 'Parse::RecDescent::Rule' ),
                              'token_use' => bless( {
                                                      'calls' => [
                                                                   'use_stuff'
                                                                 ],
                                                      'changed' => 0,
                                                      'impcount' => 0,
                                                      'line' => 3,
                                                      'name' => 'token_use',
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'actcount' => 1,
                                                                            'dircount' => 0,
                                                                            'error' => undef,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'description' => '/\\\\buse\\\\s/',
                                                                                                  'hashname' => '__PATTERN1__',
                                                                                                  'ldelim' => '/',
                                                                                                  'line' => 5,
                                                                                                  'lookahead' => 0,
                                                                                                  'mod' => '',
                                                                                                  'pattern' => '\\buse\\s',
                                                                                                  'rdelim' => '/'
                                                                                                }, 'Parse::RecDescent::Token' ),
                                                                                         bless( {
                                                                                                  'argcode' => undef,
                                                                                                  'implicit' => undef,
                                                                                                  'line' => 5,
                                                                                                  'lookahead' => 0,
                                                                                                  'matchrule' => 0,
                                                                                                  'subrule' => 'use_stuff'
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'description' => '/[;\\}]/',
                                                                                                  'hashname' => '__PATTERN2__',
                                                                                                  'ldelim' => '/',
                                                                                                  'line' => 5,
                                                                                                  'lookahead' => 0,
                                                                                                  'mod' => '',
                                                                                                  'pattern' => '[;}]',
                                                                                                  'rdelim' => '/'
                                                                                                }, 'Parse::RecDescent::Token' ),
                                                                                         bless( {
                                                                                                  'code' => '{ $return=$item{use_stuff} }',
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'line' => 6,
                                                                                                  'lookahead' => 0
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => undef,
                                                                            'number' => 0,
                                                                            'patcount' => 2,
                                                                            'strcount' => 0,
                                                                            'uncommit' => undef
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'vars' => ''
                                                    }, 'Parse::RecDescent::Rule' ),
                              'use_stuff' => bless( {
                                                      'calls' => [
                                                                   '_alternation_1_of_production_1_of_rule_use_stuff'
                                                                 ],
                                                      'changed' => 0,
                                                      'impcount' => 1,
                                                      'line' => 8,
                                                      'name' => 'use_stuff',
                                                      'opcount' => 0,
                                                      'prods' => [
                                                                   bless( {
                                                                            'actcount' => 0,
                                                                            'dircount' => 0,
                                                                            'error' => undef,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'argcode' => undef,
                                                                                                  'implicit' => 'base, or parent, or version, or module',
                                                                                                  'line' => 8,
                                                                                                  'lookahead' => 0,
                                                                                                  'matchrule' => 0,
                                                                                                  'subrule' => '_alternation_1_of_production_1_of_rule_use_stuff'
                                                                                                }, 'Parse::RecDescent::Subrule' )
                                                                                       ],
                                                                            'line' => undef,
                                                                            'number' => 0,
                                                                            'patcount' => 0,
                                                                            'strcount' => 0,
                                                                            'uncommit' => undef
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'vars' => ''
                                                    }, 'Parse::RecDescent::Rule' ),
                              'var' => bless( {
                                                'calls' => [],
                                                'changed' => 0,
                                                'impcount' => 0,
                                                'line' => 103,
                                                'name' => 'var',
                                                'opcount' => 0,
                                                'prods' => [
                                                             bless( {
                                                                      'actcount' => 0,
                                                                      'dircount' => 0,
                                                                      'error' => undef,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'description' => '/\\\\$[\\\\w+]/',
                                                                                            'hashname' => '__PATTERN1__',
                                                                                            'ldelim' => '/',
                                                                                            'line' => 103,
                                                                                            'lookahead' => 0,
                                                                                            'mod' => '',
                                                                                            'pattern' => '\\$[\\w+]',
                                                                                            'rdelim' => '/'
                                                                                          }, 'Parse::RecDescent::Token' )
                                                                                 ],
                                                                      'line' => undef,
                                                                      'number' => 0,
                                                                      'patcount' => 1,
                                                                      'strcount' => 0,
                                                                      'uncommit' => undef
                                                                    }, 'Parse::RecDescent::Production' )
                                                           ],
                                                'vars' => ''
                                              }, 'Parse::RecDescent::Rule' ),
                              'version' => bless( {
                                                    'calls' => [],
                                                    'changed' => 0,
                                                    'impcount' => 0,
                                                    'line' => 97,
                                                    'name' => 'version',
                                                    'opcount' => 0,
                                                    'prods' => [
                                                                 bless( {
                                                                          'actcount' => 0,
                                                                          'dircount' => 0,
                                                                          'error' => undef,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'description' => '/v?[\\\\d\\\\._]+/',
                                                                                                'hashname' => '__PATTERN1__',
                                                                                                'ldelim' => '/',
                                                                                                'line' => 99,
                                                                                                'lookahead' => 0,
                                                                                                'mod' => '',
                                                                                                'pattern' => 'v?[\\d\\._]+',
                                                                                                'rdelim' => '/'
                                                                                              }, 'Parse::RecDescent::Token' )
                                                                                     ],
                                                                          'line' => undef,
                                                                          'number' => 0,
                                                                          'patcount' => 1,
                                                                          'strcount' => 0,
                                                                          'uncommit' => undef
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'vars' => ''
                                                  }, 'Parse::RecDescent::Rule' )
                            },
                 'startcode' => ''
               }, 'Parse::RecDescent' );
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::ExtractUse::Grammar

=head1 VERSION

version 0.344

=head1 AUTHORS

=over 4

=item *

Thomas Klausner <domm@cpan.org>

=item *

Kenichi Ishigaki <kishigaki@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
