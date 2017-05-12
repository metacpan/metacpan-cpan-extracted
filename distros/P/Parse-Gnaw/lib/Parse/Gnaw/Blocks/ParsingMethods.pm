

package Parse::Gnaw::Blocks::ParsingMethods;

our $VERSION = '0.001';

#BEGIN {print "Parse::Gnaw::Blocks::ParsingMethods\n";}

use warnings;
use strict;
use Carp;
use Data::Dumper;
use Storable 'dclone';

use Parse::Gnaw::Blocks::LetterConstants;
use Parse::Gnaw::LinkedListConstants;


=head1 NAME

Parse::Gnaw::Blocks::ParsingMethods - A base package containing all the methods that derived "letter" type classes will inherit.



=head2 parse_grammarref

We get a starting letter, and a reference to a rule.
Because rules can be called like subroutines, we have to process the rule in such a way
that it can be called from anywhere and we don't know who is calling us (or where we will return to).

Note that we need to keep track of whether a rule consumes the current letter or not.
some rules might not consume anything (rules that execute callbacks, for example, or configure flags)
So, we need to call rules until we consume at least the current letter.

if that is the last subrule, then return current letter.

if there are more subrules, we need to get a list of possible connections to go to next.
then loop through each possible connection and try the subrule. 
If it succeeds, great.
If it fails, eval/trap the failure and loop to next connection.

============================
This is a recursive call.
============================


	grammar is ('a', 'b', 'c')

	text is 
		c  b  b
		j  a  k
		m  n  o

	start at "g", look for 'a'. fail, move to next starting position. repeat until hit 'a' in center position.
	match 'a' at center. look a next rule, it's defined and true, so we need to look for it.
	Howerver, we need to try every possible direction from "A".
	'b', 'b', 'k', 'o', 'n', 'm', 'j', 'c'
		
	This means every connection needs to trap for die "GRAMMARFAIL"
	if we try direction 'h', and it dies,
	we need to trap the error and try the next option.



=cut
sub parse_grammarref{
	my ($llobj, $grammarref, $then_call )=@_;

	my $debug=0;

	# first element in grammarref array has information about this rule. get it.
	my $first_subrule = $grammarref->[0];

	my $ruleinfo	  = $first_subrule->[2];
	my $rulename	  = $ruleinfo->{payload};
	my $quantifiertype= exists($ruleinfo->{quantifier}) ? $ruleinfo->{quantifier} : '';
	my $isquantifier  = ($quantifiertype eq '') ? '' : 1;

	my ($min,$max)=(1,1); # if not a quantifier, then want to match this rule exactly once

	if($isquantifier){
		$min=$ruleinfo->{min};
		$max=$ruleinfo->{max};
	}

	my $start_letter	 = $llobj->[LIST__CURR_START];
	my $entry_letter_payload = $start_letter->[LETTER__DATA_PAYLOAD];
	my $minstr=defined($min) ? $min : 'undef';
	my $maxstr=defined($max) ? $max : 'undef';

	my $parse_grammarref_identification_string = "parse_grammarref, called with rule='$rulename', ".
		"letter='$entry_letter_payload', quantifiertype='$quantifiertype', isquantifier='$isquantifier', ".
		"min='$minstr', max='$maxstr', then_call='$then_call'";
	if($debug){warn "$parse_grammarref_identification_string: begin";}


	# We're going to pretend that every rule is like a quantifier
	# if it's not REALLY a quantifier, then min/max is 1/1 and we must match exactly once.
	# if it IS really a quantifier, then we need to match min times

	# first, match "min" number of times.
	# if we fail that,then this rule fails, therefore, no need to trap error

	# if the minimum is 3, then we need to call the rule 3 times.
	foreach my $minimal_match (1 .. $min){

		if($debug){warn "parse_grammarref($rulename): about to try one_iteration_of_grammarref";}
		
		my $discard_retval = $llobj->one_iteration_of_grammarref($grammarref,1);

		if($debug){warn "parse_grammarref($rulename): just tried one_iteration_of_grammarref and succeeded";}
		

	}

	# matched MIN number of times
	# now try 0 to ($max-$min) more times.
	# if min=3 and max=7, then we would try 0 to 4 more times.

	my $remainingattempts = -1;
	if($max>0){
		$remainingattempts=($max-$min);
	}	
	

	if($debug){warn "remainingattempts='$remainingattempts'";}

	for(my $quant_counter=0; (($remainingattempts<0) or ($quant_counter<=$remainingattempts)); $quant_counter++){

		if($debug){warn "quant_counter='$quant_counter'";}

		##################################################################################
		# try one iteration of grammarref
		##################################################################################
		if($quant_counter>0){
			if($debug){warn "parse_grammarref($rulename): try anotehr iteration of grammarref";}
			my $discard_retval = $llobj->one_iteration_of_grammarref($grammarref,1);	
		}


		##################################################################################
		# then try the then_call rule. 
		##################################################################################
		if( not defined($then_call) or ($then_call eq '') ){
			# there is no then_call, we're done and we must have matched. huzzah! return
			if($debug){warn "parse_grammarref($rulename): no then_call, return success";			}
			return;
		} else {
			if($debug){warn "parse_grammarref($rulename): try the then_call rule";}
			# there is a then_call, try it, if it fails, catch and try another  quant_counter.

			my $save_position=$llobj->[LIST__CURR_START];	 # if all fail, go back to here

			#warn "then_call is '$then_call'";

			eval{
				my $thencall_grammarref=$llobj->convert_rule_name_to_rule_reference($then_call);
				my $discard_retval = $llobj->one_iteration_of_grammarref($thencall_grammarref,1);
			};
			if($@){
				if($@ =~ m{GRAMMARFAIL}){
					$llobj->[LIST__CURR_START]=$save_position;
				} else {
					die $@;
				}
			} else {
				# didn't die. must have matched. huzzah!
				if($debug){warn "parse_grammarref($rulename): returning";}
				return;
			}
		}
	}

	# note that if the above for(my $quant_counter=0; loop
	# ever finds a match of the quantifier plus successfully runs then_call
	# then it will return in the "else" part of "if($@)".
	if($debug){warn "parse_grammarref($rulename): tried looping on quant_counter but failed to match";}
	die "GRAMMARFAIL";
}

=head2 one_iteration_of_grammarref

This runs an entire rule exactly one time.

It does not call then_call.

It does not address quantifier issues.



=cut

my $counter=0;

# pass in subrule_iterator, return subrule_iterator
sub one_iteration_of_grammarref{
	my ($llobj, $grammarref,$subrule_iterator)=@_; # no "$thencall" here.
 
	my $debug=0;

	my $size_rule=scalar(@$grammarref);

	my $number_of_possible_connections=1;

	my $initial_subrule=$grammarref->[$subrule_iterator];
	my $sub_method=$initial_subrule->[0];
	my $sub_payload=$initial_subrule->[1];
	my $initial_state_of_call = "called one_iteration_of_grammarref with sub_method='$sub_method' and sub_payload='$sub_payload'";
	if($debug){warn $initial_state_of_call;}
	my @caller=caller(0);
	#print Dumper \@caller;
	#warn "called from (see above)";

	while(($number_of_possible_connections==1) and ($subrule_iterator<$size_rule)){

		if($debug){warn "WHILE: $initial_state_of_call subrule_iterator=$subrule_iterator";}
		#############################################################################################
		#############################################################################################
		#############################################################################################
		# if currentletter is not consumed yet
		# go through the grammar rules until its consumed, then stop this part of loop.
		#############################################################################################
		#############################################################################################
		#############################################################################################
		while( ($llobj->[LIST__CURR_START]->[LETTER__LETTER_HAS_BEEN_CONSUMED]==0) and ($subrule_iterator<$size_rule) ){

			# get the subrule, i.e. ['lit','a',...]
			my $subrule = $grammarref->[$subrule_iterator];
			$subrule_iterator++;

			# get the subrule name, i.e. 'lit'	
			my $methodname=$subrule->[0];	
				
			#my $payloadify = $subrule->[1]; warn "trying methodname '$methodname' with payload '$payloadify'";
	
			# if we can't call the methodname, then die a miserable death.
			if(not($llobj->can($methodname))){
				print "no method found for '$methodname'\n"; warn;	
				my $hashref=$subrule->[2];	
				print Dumper $hashref;
				my $filename=$hashref->{filename};
				my $linenum =$hashref->{linenum};	
				confess "grammar method not defined '$methodname' in $filename line $linenum";
			}
		
			if($debug){warn "methodname is '$methodname', subrule is"; print Dumper $subrule; }
	
			# call the method, i.e. $letter->lit(['lit','a',...]);
			$llobj->$methodname($subrule);

			unless(defined($llobj->[LIST__CURR_START])){
				die "ERROR: called method and got undefined letter back (method == $methodname)";	
			}
		}

		# we consumed the current letter, so if there ARE MORE RULES in this grammar, 
		# we need to figure out which connection to use to get to move to the next letter.
		# If there are NO MORE RULES left, just return letter (marked as consumed) 
		# because we can't iterate the connections from that letter without knowing 
		# what the next rule is. The next rule to get called will see letter is consumed
		# and skip to the possible connections section.
		if($subrule_iterator>=$size_rule){
			return $subrule_iterator;
		}
		
		
		#############################################################################################
		#############################################################################################
		#############################################################################################
		# current letter is consumed and there are more subrules in this rule.
		# get a list of all possible letters connected to the current letter
		# for each possible connection, try setting current letter to that connected letter
		# and see if rest of rule matches. If doesn't match, trap failure, and try next possible letter.
		#############################################################################################
		#############################################################################################
		#############################################################################################

		# get a list of letter objects to try.
		my @list_of_possible_next_letters = $llobj->[LIST__CURR_START]->get_list_of_connecting_letters();
		
		$number_of_possible_connections=scalar(@list_of_possible_next_letters);
		if($number_of_possible_connections==0) {
			die "somehow we mannaged to get into a letter that has no connections?";
		}			
	
		# if there is only 1 possible connection, then we can avoid recursion here.
		# just move current letter to the next possible letter, and loop around.
		# when we're parsing a simple string, this should save us time and memory.
		if($number_of_possible_connections==1){
			if($debug){warn "only 1 connection";}
			die "stuck in a loop" if($counter++>4000);

			$llobj->[LIST__CURR_START] = shift(@list_of_possible_next_letters);
			$llobj->[LIST__CURR_START] ->[LETTER__LETTER_HAS_BEEN_CONSUMED]=0;
		} else {
			if($debug){warn "multiple connections";}
			# else there are multiple possible connections.
			# will have to try each one in sequence until we get a match.
			# will have to be recursive because next letter will also have a bunch of connections
			# and we will have to loop through and try each possible connection for that letter.

			my $save_position=$llobj->[LIST__CURR_START];	 # if all fail, go back to here
			my $save_iterator=$subrule_iterator;

			TRYCONNECTION : foreach my $possible_letter (@list_of_possible_next_letters){

				$llobj->[LIST__CURR_START] = $possible_letter;

				# mark letter as not consumed.				
				$llobj->[LIST__CURR_START]->[LETTER__LETTER_HAS_BEEN_CONSUMED]=0;
		
				eval{
					$subrule_iterator = $llobj->one_iteration_of_grammarref($grammarref,$subrule_iterator);
				};
				if($@){
					if($@ =~ m{GRAMMARFAIL}){	
						# grammar failed, so this connection didn't work. Try another connection.
						$llobj->[LIST__CURR_START]   =$save_position;
						$subrule_iterator =$save_iterator;		
						next TRYCONNECTION;
					} else {
						# else we died, and it wasn't a grammar failure. rethrow the die
						die $@;
					}
				} else {
					######
					# we eval'ed and didn't get $@. must have matched. Hazzah!
					######

					# at the end of recursive calls, the iterator should equal the size of the rule.
					# (i.e. if rule has 3 elements in it, iterator will go 0,1,2 to try each subrule
					#	and then it will increment to 3 and should return as matcihng the entire rule)
					# if iterator doesn't equal size of rule, then something went wrong in the process of parsing.
					unless($subrule_iterator==$size_rule){
						die "ERROR: somehow managed to return a rule without matching all of the rule.";
					}
					
					# OK, we didn't get $@, AND it looks like the recursive calls matched the entire rule. 
					# return as a successful match.
					return $subrule_iterator;
				}
			} 
			die "GRAMMARFAIL"; #tried all possible connections. none worked. Die.
		}

		# if there is only 1 possible connection, the if($number_of_possible_connections==1) statement will kick out here
		# we will use the enclosing while() loop to loop around and try the next letter.
	}

	# end of while(($number_of_possible_connections==1) and ($subrule_iterator<$size_rule)){
	# Should only reach this point when we're parsing a one-dimensional string (connectins==1) 
	# and the entire rule matched (iterator==size of rule)
	# return as a successful match.
	return $subrule_iterator;
}



=head2 rule

The "rule" method is just a placeholder for the first index into each rule array.
This is where we store the name of the rule and any othe rule-specific info.
For now, it doesn't do anything.

=cut

sub rule { 
	my ($llobj, $subrule)=@_;
	return;
}


=head2 call

When one grammar rule needs to call another rule (including itself),
this method will get executed.

Note that this supports recursive calling. A rule can call itself.
A first rule can call a second rule which calls the first rule.

The main reason this works is that when a rule "calls" another rule,
it doesn't actually CONTAIN the rule. A rule is actually made up of
a perl array. 

	my $rule1=[  
		[ 'lit', 'a' ],
		[ 'lit', 'b' ],
	];

If a rule "calls" itself, it simply points to the name of the rule its calling:

	my $rule1=[  
		[ 'lit', 'a' ],
		[ 'call', 'rule1' ],
		[ 'lit', 'b' ],
	];

If a call to a rule resulted in the rule being called being expanded and 
embedded into the original rule, then recursive rules would explode.


	my $rule1;
	
	$rule1=[  
		[ 'lit', 'a' ],
		[ 'call', $rule1 ],	
		[ 'lit', 'b' ],
	];

This would become problematic because it would want to expand itself forever
(which would be grammatically correct, but explode your memory) or it would
only expand one level (which would fit in memory, and be grammatically incorrect).

If a call to another rule only contains the NAME of the rule being called,
then it won't explode memory.

A rule will call a rule only when it needs to, and not explode memory.

So then the only other issue that can cause a recursive rule ot explode
is if a rule calls itself before matching any text in the source string.

This rule will explode when we try to match it against some text:

	$rule1=[  
		[ 'call', 'rule1' ],
		[ 'lit', 'b' ],	
	];

The above example will break because rule1 will keep calling itself infinitely
without ever matching anything.

For the above example NOT to crash, we will eventually have to upgrade the 
"call" method to detect whether a recursive call is taking place, and
if so, check to see that at least SOME text has been consumed. If not,
skip the call and look for an alternation or something.

For now, we can handle recurssion, but only if we match some text first:

	$rule1=[
		['lit','a'],
		['call', 'rule1'],

	];

=cut

sub call{
	my ($llobj, $subrule)=@_;

	my $debug=0;

	if($debug){warn "call subrule is ";print Dumper $subrule;}

	#print "INSIDE CALL\n";
	#print "letter IS\n"; print Dumper $letter;
	#print "SUBRULE IS\n"; print Dumper $subrule;
	my $hash_info=$subrule->[2];	

	my $rule 	= $hash_info->{payload};
	my $package	= $hash_info->{package};

	# then_call is in caller hash.
	# when we get the grammarref, that will be the callee, so need to get next_call here and pass it in separtely
	# can't make it part of callee because multiple things could call this rule.
	my $then_call 	= $hash_info->{then_call};

	if(length($package)){
		$rule = $package.'::'.$rule;
		$then_call = $package.'::'.$then_call;
	}


	if($debug){warn "inside ParsingMethods::call. rule is '$rule', then_call is '$then_call'";}


	my $grammarref=$llobj->convert_rule_name_to_rule_reference($rule);

	if($debug){warn "grammarref for rule '$rule' is "; print Dumper $grammarref;}

	$llobj->parse_grammarref($grammarref, $then_call );

	if($debug){warn "call returned";}
	return;	# must have matched.

}



=head2 lit

lit is short for literal. It is looking for the current letter object to match the letter value in $subrule.

	my $rule1=[  
		[ 'lit', 'a' ],
		[ 'lit', 'b' ],
	];

The above example is looking for 'a' followed by 'b'.

=cut

sub lit { 
	my ($llobj, $subrule)=@_;

	my $grammar_letter=$subrule->[1];
	my $letter_payload = $llobj->[LIST__CURR_START]->[LETTER__DATA_PAYLOAD];
	#warn "lit rule '$grammar_letter' versus letter text '$letter_payload' ";
	if($grammar_letter ne $letter_payload){
		die "GRAMMARFAIL";
	}

	$llobj->[LIST__CURR_START]->[LETTER__LETTER_HAS_BEEN_CONSUMED]=1;
}

=head2 cc

This is short for "character class". 
In perl regular expressions, this is represented with [].
The letters in the square brackets are letters in teh character class you wnat to match.
For example, [aeiou] would match a character class of any single vowel.

=cut

sub cc{
	my ($llobj, $subrule)=@_;
	my $href_info=$subrule->[2];
	my $hash_of_letters = $href_info->{hash_of_letters};


	my $letter_payload = $llobj->[LIST__CURR_START]->[LETTER__DATA_PAYLOAD];

	#print "called cc with letter_payload '$letter_payload' and class hash "; print Dumper $class_hashref; warn " ";

	unless(exists($hash_of_letters->{$letter_payload})){
		#warn "dying ";
		die "GRAMMARFAIL";
	}
	$llobj->[LIST__CURR_START]->[LETTER__LETTER_HAS_BEEN_CONSUMED]=1;
}

=head2 notcc

This is short for "not character class". 
In perl regular expressions, this is represented with [^ ].
The letters in the square brackets are letters in teh character class you do NOT want to match.
For example, [^aeiou] would NOT match a character class of any single vowel.
Or it WOULD match any character that is NOT a vowel.

=cut

sub notcc{
	my ($llobj, $subrule)=@_;
	my $href_info=$subrule->[2];
	my $hash_of_letters = $href_info->{hash_of_letters};


	my $letter_payload = $llobj->[LIST__CURR_START]->[LETTER__DATA_PAYLOAD];

	#print "called cc with letter_payload '$letter_payload' and class hash "; print Dumper $class_hashref; warn " ";

	if(exists($hash_of_letters->{$letter_payload})){
		#warn "dying ";
		die "GRAMMARFAIL";
	}
	$llobj->[LIST__CURR_START]->[LETTER__LETTER_HAS_BEEN_CONSUMED]=1;
}

=head2 thrifty

perform a thrifty quantifier match

Note: Since we want to be able to read petabytes of streamed data,
we will default to using thrifty matching.
i.e. match as little as possible and move on.
if we do greedy matching, then the first .* we run into will
read in the entire stream (petabytes) into memory and crash the system.
if it doesn't crash, it will back up until it finds  amatch.
We default to thrifty matching, meaning we only read in as little as possible
to still find a match. This means we only read in just as much of the
stream as we need to find a match.
We can DO greedy matching, but it can be a problem if we're streaming massive quantities of data.

basic thrifty algorithm:
try the rule at least min times.
if that matches, then return and let rest of grammar try.
If rest of grammar dies, then revert to min location
and try matching one more time.
if that passes, then return and let rest of grammar try.
if rest of grammar dies, then revert to min+1 location
and try another rule.

keep doing this until you reach "max" number of matches.
if that doesn't make things happy, then quantifier dies
and the expression fails.

rule1 : 'a' rule2 'b'

rule2 : 'c' d+ rule3 e+

rule3 : f g+ rule4 h

rule4 : i*



=cut

sub thrifty {
	my ($llobj, $subrule)=@_;

	my $payload=$subrule->[1];

	my $rule 	= $payload->{rule};
	my $then_call 	= $payload->{then_call};

	my $grammarref=$llobj->convert_grammar_name_to_array_ref($rule);

	$llobj->parse_grammarref($grammarref, $then_call );


	

	return;	# must have matched.
}

=head2 greedy

basic greedy algorithm.
try the rule max times.
if not even zero match, die.
at the end of every match, record the letter location of that specific match.

return and let rest of grammar try. 
if rest of grammar dies, then revert to max-1 location,
and try another rule.
return and let rest of grammar try.
if rest of grammar dies, then revert to max-2 location
and try another rule.

keep doing this until you reach "min" number of matches.
we can't find a match even at "min", then quantifier dies
and the expression fails.

=cut

sub greedy {
	my($llobj, $subrule, $overalldirectionforrule)=@_;

	my $payload=$subrule->[1];

	my $min  = $payload->{min};
	my $max  = $payload->{max};
	my $rule = $payload->{rule};


}

1;

