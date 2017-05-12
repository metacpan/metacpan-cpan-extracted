
no warnings 'once';

package Parse::Gnaw;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Carp ('cluck','confess');
use Storable qw(nstore dclone retrieve);

our $VERSION = '0.601';

# this package doesn't play nice.
# it uses eval("") to create variables in the caller's namespace.
# if the caller uses these variables, they might get warnings about
# some variable only used once.
#
# to disable that warning, we need to do a 
# no warnings 'once';
# except that's lexical and we can't do that here 
#
# on the other hand, if we have an import function and from import call this:
#	warnings->unimport("once");
# then the no warnings gets pulled into the calling package.
#
# We want to use the Exporter.pm module, but we can't "use" it like this:
#	use Exporter
# because that creates a conflict when we declare our own import method.
# So, instead, we put Exporter in our @ISA and then we can define our import method.
# 
# then from inside import, we call export_to_level to do the importing stuff for us
# that Exporter normally does, but now we're doing it inside an import sub
# which then allows us to call 
#	warnings->unimport("once");
#
# see"
# http://perldoc.perl.org/Exporter.html#Exporting-without-using-Exporter%27s-import-method
# and
# http://mail.pm.org/mailman/private/boston-pm/2013-May/014850.html
# From:   	"Ben Tilly" <btilly@gmail.com>
# Date:   	Sat, May 4, 2013 6:46 pm
# If your module has an import method, and in that method calls
# warnings->unimport("once") then the unimport should be lexically
# scoped to where your package was used.


our @ISA = qw(Exporter);
our @EXPORT = qw ( rule predeclare lit call cc notcc thrifty alt );

sub import {
	warnings->unimport("once");
	strict->unimport("vars");
	Parse::Gnaw->export_to_level(1,@_);
}


our $debug=0;

sub format_package{
	my $callerindex = 0;
	while(1){
		my @caller=caller($callerindex++);
		my $package =$caller[0];
		if($package =~ m{Parse::Gnaw}){

		} else {
			return $package;
		}
	}
}

sub format_filename{
	my $callerindex = 0;
	while(1){
		my @caller=caller($callerindex++);
		my $package =$caller[0];
		my $filename=$caller[1];
		if($package =~ m{Parse::Gnaw}){

		} else {
			return $filename;
		}
	}

}

sub format_linenum{
	my $callerindex = 0;
	while(1){
		my @caller=caller($callerindex++);
		my $package =$caller[0];
		my $linenum =$caller[2];
		if($package =~ m{Parse::Gnaw}){

		} else {
			return $linenum;
		}
	}
}


sub eval_string{
	my $string=shift(@_);

	if($debug){
		my @caller=caller(1);
		my $filename=$caller[1];
		my $linenum =$caller[2];
		print "eval_string('$string') called from $filename, line $linenum\n";
	}

	my $eval_return;

	eval($string);
	if($@){
		die $@;
	}

	return $eval_return;
}


sub get_ref_to_rulebook{
	my($package,$createifnotexist)=@_;
	
	if($debug){
		my @caller=caller(1);
		my $filename=$caller[1];
		my $linenum =$caller[2];
		print "called get_ref_to_rulebook($package) from $filename at $linenum\n";
	}

	my $retval = eval_string("\$eval_return = \$".$package."::rulebook;");

	if(defined($retval) and (ref($retval) eq 'HASH')){
		return $retval;
	}

	if($createifnotexist){
		$retval=eval_string('$'.$package."::rulebook={}; \$eval_return = \$".$package.'::rulebook;');
		return $retval;
	}

	return;
}


sub get_ref_to_rulename{
	my($package,$rulename,$createifnotexist)=@_;
	
	if($debug){
		my @caller=caller(1);
		my $filename=$caller[1];
		my $linenum =$caller[2];
		print "called get_ref_to_rulename($package,$rulename) from $filename at $linenum\n";
	}

	my $package_rulename = $package.'::'.$rulename;

	my $retval = eval_string("no warnings 'once'; \$eval_return = \$".$package_rulename.";");

	if(defined($retval) and (ref($retval) eq 'ARRAY')){
		return $retval;
	}

	if($createifnotexist){
		my $ruleref=eval_string('$'.$package_rulename."=[]; \$eval_return = \$".$package_rulename.";");

		# put it in the rulebook.
		my $bookref = get_ref_to_rulebook($package,1);
		$bookref->{$rulename}=$ruleref;

		return $ruleref;
	}

	return;
}



sub process_first_arguments_and_return_hash_ref{

	#print Dumper \@_; warn "process_first_arguments_and_return_hash_ref arguments (above)";


	# first parameter string is same as payload=> key in hash
	# need to know for error checking this:
	# ('myrule',{method=>'rule', payload=>'myrule'})
	# and need to know if hash doesn't exist or doesn't have the key for first parameter.
	# i.e. this
	# ('myrule')
	# needs to return this:
	# {payload=>'myrule'}
	# 
	# on the other hand, if we're processing inputs to the lit() function, then first parameter is the literal
	# lit('a',{payload=>'a'});
	#
	# the methodname is the subroutine name to call to execute the grammar.
	# the methodname for a rule is 'rule'
	# the methodname for a literal is 'lit'
	# the methodname for a thrifty quantifier is 'thrifty'
	#
	# every hash methodname -> methodvalue should have a corresponding
	# payload -> loadvalue combination.
	# for example a literal might look like this: { methodname=>'lit', payload=>'a' };
	# the methodname tells us it is a 'lit'. payload tells us we're looking for the letter 'a'.
	my $methodname=shift(@_);

	# passing in a reference so we can shift data off the array, and affect the array in the caller space as well.
	my $argref = shift(@_);
	unless(ref($argref) eq 'ARRAY'){
		confess "ERROR: called process_first_arguments_and_return_hash_ref, second argument should be an array reference, found $argref instead ";
	}


	my $parm_payload;
	if(not(ref($argref->[0]))){
		$parm_payload=shift(@$argref);
	}

	my $package = format_package();
	my $source_filename = format_filename();
	my $source_linenum  = format_linenum();

	my $info_href;
	if(ref($argref->[0]) eq 'HASH'){
		my $orig_href=shift(@$argref);
		$info_href = dclone $orig_href;
	} else {
		$info_href={};
	}

	if(defined($parm_payload)){
		if(exists($info_href->{payload})){

			# passed in process ( 'a' { payload=>'a' } ) both 'a's must match.
			my $hash_payload=$info_href->{payload};
			unless($parm_payload eq $hash_payload){
				print Dumper $info_href;
				confess "ERROR: process_first_arguments_and_return_hash_ref parm_payload does not equal hash_payload $methodname ($parm_payload ne $hash_payload)";
			}
		} else {
			# passed in parm_payload and do not have hash_payload. So, put it in hash.
			# process ('a', {} ) 
			$info_href->{payload}=$parm_payload;
		} 
	} else {
		# parm_payload is NOT passed in as string, MUST be defined in hash
		# if we don't say process ('a', {} ), then we must say  process ( { payload => 'a' } )
		unless(exists($info_href->{payload})){
			confess("ERROR: process_first_arguments_and_return_hash_ref without providing a $methodname anywhere");
		}

	}

	# handle the rest of the defaults;
	unless(exists($info_href->{package})){$info_href->{package}		=$package;}
	unless(exists($info_href->{filename})){$info_href->{filename}		=$source_filename;;}
	unless(exists($info_href->{linenum})){$info_href->{linenum}		=$source_linenum;}
	unless(exists($info_href->{methodname})){$info_href->{methodname}	=$methodname;}

	return $info_href;
}


sub copy_location_info_and_make_new_hash_ref{
	my($orig_href)=@_;

	# first copy over only the keys we want. this is a one-deep copy.
	# if any hash values point to other references, those need to a deep copy.
	my $one_deep_copy={};

	foreach my $key ('package', 'filename', 'linenum'){
		$one_deep_copy->{$key}=$orig_href->{$key}
	}

	# make a deep copy of just these keys
	my $full_separate_copy = dclone $one_deep_copy;

	return $full_separate_copy;
}



#######################################################################
#######################################################################
#######################################################################
sub rule {
#######################################################################
#######################################################################
#######################################################################
	my $argref=[@_];


	if($debug){print "called rule, \@_ is: "; print Dumper \@_; warn " ";}


	my $info_href=process_first_arguments_and_return_hash_ref('rule', $argref);
	if($debug){print "called rule ";print Dumper $info_href; warn " ";}

	my $rulename = $info_href->{payload};
	my $package  = $info_href->{package};
	my $filename = $info_href->{filename};
	my $linenum  = $info_href->{linenum};

	unless(exists($info_href->{quantifier})){
		$info_href->{quantifier}='';
	}

	if($rulename =~ m{\:\:}){
		confess "ERROR: called rule and passed in a package name rule '$rulename'. Rulenames should not contain '::'";
	}
	
	my $rulebook = get_ref_to_rulebook($package,1);

	if(exists($rulebook->{$rulename})){
		my $oldruleinfo=$rulebook->{$rulename}->[0];

		#print Dumper $oldruleinfo; die;
		my $hash_info = $oldruleinfo->[2];
		my $oldmethod= $hash_info->{methodname};
		if($oldmethod eq 'predeclare'){

		} else {

			warn "warning: redefining rule '$rulename' for package '$package'";

			# element ->[0] in rule array is the 'rule' method. element ->[1] in 'rule' method is the info_href.
			print "original rule: "; print Dumper $rulebook->{$rulename}->[0]->[1]; 
			print "new rule: "; print Dumper $info_href;
		}
	}
	
	my $currentrule = get_ref_to_rulename($package,$rulename,1);

	# empty out the array for the rule
	@$currentrule = ();

	# first index into rule array is a "ruleinfo" marker to indicate info about this rule
	# such as rulename, where it came from, and other information.
	push(@$currentrule, ['rule',$rulename, $info_href]);


	# now go through the subrules and format them properly.
	# a big thing to do is convert strings like 'a' into [ 'lit', 'a', {info} ]
	# this allows a rule to be a lot less verbose.
	my $index=-1;
	while(@$argref){
		$index++;

		if($debug){warn "shifting element of 'rule', index $index";}

		my $subrule=shift(@$argref);

		my $isnumber=0;
		my $isstring=0;
		my $isarray=0;
		my $ishash=0;

		my $ref=ref($subrule);
		if($ref){
			if($ref eq 'ARRAY'){
				$isarray=1;
			} elsif($ref eq 'HASH'){
				$ishash=1;
			}
		}else{
			no warnings 'numeric';
			if($subrule eq $subrule+0){	
				$isnumber=1;	
			}else{
				$isstring=1;
			}
		}

		my @subrules=();

		# if subrule is 'a', convert that to a literal subrule.
		if($isstring){
			if($debug){warn "subrule is string '$subrule'";}

			# make a copy of hash ref and use that for lit() otherwise the original info_href gets tainted.
			my $location_href=copy_location_info_and_make_new_hash_ref($info_href);
			@subrules = lit($subrule,  $location_href);

	
		# if subrule is an array reference, then fill in the hash ref with any info the caller didn't have.
		} elsif($isarray){
			if($debug){warn "subrule is array "; print Dumper $subrule; warn " ";}
			my ($method,$payload,$subinfo)=@$subrule;
			$subinfo=process_first_arguments_and_return_hash_ref($method,[$payload,$subinfo]);
			@subrules = ( [$method,$payload,$subinfo] );

		# if its a hashref, then 'method' key points to a value like 'lit'.
		# and 'lit' will poitn to the actual payload such as 'a'.
		# and the rest will contain whatever location info caller passed in.
		#} elsif($ishash){
		#	my $method=$subrule->{method};
		#	my $payload=$subrule->{$method};
		#	my $subinfo = process_first_arguments_and_return_hash_ref($method,[$payload,$subrule]);
		#	@subrules = ( [$method,$payload,$subinfo] );

		} else {
			print "\n\n\n";
			print Dumper $subrule;
			print "\n\n\n";

			confess "ERROR: dont know how to handle subrule '$subrule' at $filename, $linenum "; 
		}

		push(@$currentrule, @subrules);
	}

	# now fragment the rule so we can reorder how its called:
	fragment_a_rule($currentrule);
}






# each rule may be split up into fragments
# myrule : 'a' 'b' 'c'
# might get split up into
# myrule : 'a' myrule_fragment_2 
# myrule_fragment_2 : 'b' myrule_fragment_3
# myrule_fragment_3 : 'c'
# need to keep count of how many fragments so the rulenames for each fragment is unique
my $rulefragcntr={};

sub fragment_suffix(){'_rulefragment_'}

sub fragment_a_rule{
	my ($currentrule)=@_;
	my @subrules = @$currentrule;
	@$currentrule=();

	my $first_subrule=$subrules[0];

	my $hash_info = $first_subrule->[2];

	my $rulename=$hash_info->{payload};

	while(@subrules){
		my $subrule = shift(@subrules);
		push(@$currentrule, $subrule);

		return if(scalar(@subrules)==0);

		my $subinfo = $subrule->[2];
		my $method  = $subrule->[0];
		my $iscall  = ($method eq 'call') ? 1 : '';

		my $last_subrule= (scalar(@subrules)==0);
		

		if($iscall){

			# its a rule call. 
			# will still call the rule, but want to append a "then_call" attribute
			# everything AFTER the call will go into a new rule fragment.
			# will put a then_call to that fragment.

			my $fragment_suffix=fragment_suffix();
			my $rulename_without_suffix = $rulename;
			$rulename_without_suffix=~s{$fragment_suffix\d+}{};

			my $package = $subinfo->{package};
			my $key_for_rule_fragment_counter = $package.'::'.$rulename_without_suffix;
			unless(exists($rulefragcntr->{$key_for_rule_fragment_counter})){
				$rulefragcntr->{$key_for_rule_fragment_counter}=0;
			}
			$rulefragcntr->{$key_for_rule_fragment_counter}=$rulefragcntr->{$key_for_rule_fragment_counter}+1;
			my $rule_fragment_count = $rulefragcntr->{$key_for_rule_fragment_counter};

			my $fragrulename = $rulename_without_suffix.$fragment_suffix.$rule_fragment_count;

			my $hashforfragcall = copy_location_info_and_make_new_hash_ref( $subinfo );
			delete($hashforfragcall->{payload});

			# now that we've copied the subinfo from the call, 
			# mark the subinfo then_call attribute
			$subinfo->{then_call}=$fragrulename;

			# whatever is left goes into the rule fragment.
			rule($fragrulename, $hashforfragcall, @subrules);
			@subrules=();
		}
	}

}


# lit('hello') will turn into 5 individual lits 'h', 'e', 'l', 'l', 'o'.
# if you don't want to split them up into individual letters, use term() function instead.
#
# FYI: can call this with lit('a', {hashref with location info}); 
#
# could conceivably also call it with lit('a', {lit=>'a'}) though that would be a bit weird.
#
# could even call it with lit({method=>'lit', lit=>'a', etc})
sub lit{
	my $argref=[@_];

	if($debug){print "called lit, \@_ is: "; print Dumper \@_; warn " ";}

	my $info_href=process_first_arguments_and_return_hash_ref('lit', $argref);
	if($debug){print "called lit ";print Dumper $info_href; warn " ";}

	my $lit      = $info_href->{payload};

	my @letters=split(//,$lit);

	my @retval;

	foreach my $letter (@letters){
		my $dclone_href = dclone $info_href;
		push(@retval, ['lit', $letter, $dclone_href]);
	}
	

	return (@retval);
}


sub predeclare {
#######################################################################
#######################################################################
#######################################################################
	my $argref=[@_];


	if($debug){print "called predeclare, \@_ is: "; print Dumper \@_; warn " ";}


	my $info_href=process_first_arguments_and_return_hash_ref('predeclare', $argref);
	if($debug){print "called predeclare ";print Dumper $info_href; warn " ";}

	my $rulename = $info_href->{payload};
	my $package  = $info_href->{package};
	my $filename = $info_href->{filename};
	my $linenum  = $info_href->{linenum};

	unless(exists($info_href->{quantifier})){
		$info_href->{quantifier}='';
	}

	if($rulename =~ m{\:\:}){
		confess "ERROR: called rule and passed in a package name rule '$rulename'. Rulenames should not contain '::'";
	}
	
	my $rulebook = get_ref_to_rulebook($package,1);

	$rulebook->{$rulename}=[['predeclare', $rulename, $info_href]];
}

#######################################################################
#######################################################################
#######################################################################
sub call{
#######################################################################
#######################################################################
#######################################################################
	my $argref=[@_];

	if($debug){print "called 'call', \@_ is: "; print Dumper \@_; warn " ";}

	my $info_href=process_first_arguments_and_return_hash_ref('call', $argref);
	if($debug){print "called 'call' ";print Dumper $info_href; warn " ";}

	my $ruletocall = $info_href->{payload};
	
	my $package = $info_href->{package};

	my $rulebook = get_ref_to_rulebook($package,1);
	unless(exists($rulebook->{$ruletocall})){
		my $msg="WARNING: call passed a nonexistent rulename '$ruletocall'";
		print "$msg\n";
		cluck($msg);

	}

	return ['call', $ruletocall, $info_href ];
}






my $thriftycounter=0;

#######################################################################
#######################################################################
#######################################################################
sub thrifty{
#######################################################################
#######################################################################
#######################################################################
	my $argref=[@_];


	#print "called thrifty ";print Dumper \@_; warn " ";
	my $min_max=pop(@$argref);

	if(ref($min_max) eq 'HASH'){
		# do nothing, assume user passed in {min=>8, max=>33}
	} else {
		# user didn't pass in a hash. Create a hash, cause we need a hash.
		my ($min, $max);

		# if its an array, assume its [min,max]
		if(ref($min_max) eq 'ARRAY'){
			($min,$max)=@$min_max;

		# else, its a string, try to deal with various formats 
		}else{
			if($min_max =~ m{\A(\d+)?\,(\d+)?\Z}){
				($min,$max)=($1,$2);	
			} elsif($min_max eq '+'){
				($min,$max)=(1,-999);
			} elsif($min_max eq '*'){
				($min,$max)=(0,-999);
			} elsif($min_max eq '?'){
				($min,$max)=(0,1);
			} else {
				die "ERROR: thrifty can't handle min-max indicator '$min_max' ";
			}
		}

		# now that we've extracted min/max from array or string, create a hash.
		$min_max={min=>$min,max=>$max};
	}

	my $thrifty_rule_name = "thrifty_".(++$thriftycounter);

	$min_max->{quantifier}='thrifty';

	# now call the process function to fill in info that might be missing, like filename and linenum.
	# this call needs min_max to be a hash.
	$min_max=process_first_arguments_and_return_hash_ref('rule', [$thrifty_rule_name, $min_max]);

	if($debug){print "in THRIFTY "; print Dumper $min_max;  warn " ";}

	# remainder of @_ is the stuff for the thrifty rule.
	# create a new rule and put the quantify stuff in it.
	rule($thrifty_rule_name, $min_max, @$argref);

	# return a call to newly created thrifty rule.
	my $retval =  call($thrifty_rule_name, $min_max);

	return $retval;
}
















sub cc{
	my $argref=[@_];

	my $info_href=process_first_arguments_and_return_hash_ref('cc', $argref);
	if($debug){print "called cc ";print Dumper $info_href; warn " ";}

	# charclass is a string of characters in the class, such as 'aeiou'.
	# want to turn that into a hashref where the keys are the characters 
	# value doesn't matter, just make it a count

	my $charclass=$info_href->{payload};

	my $hash_of_letters={};
	my @chars = split(//,$charclass);
	foreach my $char (@chars){
		$hash_of_letters->{$char}++;
		if($hash_of_letters->{$char}>1){
			print Dumper $info_href;
			die "ERROR: called cc with duplicates in charclass '$charclass', duplicate is '$char'";		}
	}

	$info_href->{hash_of_letters}=$hash_of_letters;

	my $retval = ['cc', $charclass, $info_href ];

	print Dumper $retval;

	return $retval;
}

sub notcc{
	my $argref=[@_];

	my $info_href=process_first_arguments_and_return_hash_ref('notcc', $argref);
	if($debug){print "called notcc ";print Dumper $info_href; warn " ";}

	# charclass is a string of characters in the class, such as 'aeiou'.
	# want to turn that into a hashref where the keys are the characters 
	# value doesn't matter, just make it a count

	my $charclass=$info_href->{payload};

	my $hash_of_letters={};
	my @chars = split(//,$charclass);
	foreach my $char (@chars){
		$hash_of_letters->{$char}++;
		if($hash_of_letters->{$char}>1){
			print Dumper $info_href;
			die "ERROR: called notcc with duplicates in charclass '$charclass', duplicate is '$char'";		}
	}

	$info_href->{hash_of_letters}=$hash_of_letters;

	my $retval = ['notcc', $charclass, $info_href ];

	print Dumper $retval;

	return $retval;
}




my $alternatecounter=0;

# alt( [ 'a','b'], ['c','d'], ['e','f'] );
sub alt{
	my $argref=['alternates', @_];

	my $info_href=process_first_arguments_and_return_hash_ref('alt',  $argref);
	if($debug){print "called alternation ";print Dumper $info_href; warn " ";}

	$info_href->{alternates}=[];

	while(@$argref){
	 
		my $arr_ref=shift(@$argref);

		# should pass in a list of array refs. turn each one into a rule.
		unless(ref($arr_ref) eq 'ARRAY'){
			confess "ERROR: alternate should be passed a list of array references, each containing an alternate rule description. got '$arr_ref' instead";
		}

		my $alternate_rule_name = "alternate_".(++$alternatecounter);
			
		push(@{$info_href->{alternates}}, $alternate_rule_name);

		# create a new rule and put the quantify stuff in it.
		rule($alternate_rule_name, @$arr_ref);


	}


	my $retval = ['alt', 'alternates', $info_href ];

	print Dumper $retval;

	return $retval;
}



1; # End of Parse::Gnaw


