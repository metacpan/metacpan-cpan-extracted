#!/usr/bin/perl


#################################################################################################################################################################

=head1 NAME

B<Params::Clean> (Parse A Routine Allowing Modest Syntax--Casually List Explicit Arg Names): Process @_ as positional/named/flag/list/typed arguments

=cut

#################################################################################################################################################################



=head1 SYNOPSIS

Instead of starting your sub with C<my ($x, $y, $z) = @_;>

  #Get positional args, named args, and flags
  my  ( $x, $y, $z,    $blue, $man, $group,    $semaphore, $six_over_texas )
   = args POSN 0, 1, 2, NAME fu, man, chu,  FLAG pennant,  banner;
  
  #Any of the three types of argument is optional
  my ($tom, $dick, $harry) = args NAME tom, randal, larry;
  
  #...or repeatable -- order doesn't matter
  my ($p5, $s, @others) = args NAME pearl, FLAG white, NAME ruby, POSN 0;
  
  #If no types specified, ints are taken to mean positional args, text as named
  my ($fee, $fo, $fum) = args 0, -1, jack;
  
  #Can also retrieve any args left over after pulling out NAMEs/FLAGs/POSNs/etc.
  my    ($gilligan,  $skipper,  $thurston,  $lovey,  $ginger,  @prof_mary_ann)
   = args first_mate, skipper,  millionaire, wife,    star,    REST;
  
  #Or collect args that qualify as matching a certain type
  my ($objects, @rest) = args TYPE "Class::Name", REST;  # ref() string
  my ($files, @rest) = args TYPE \&is_filehandle, REST;  # code-ref
  
  #Specify a LIST by giving starting and (optional) ending points
  #  <=> includes end-point in the returned list; <= excludes it
  my ($fields, $tables, $conditions)
   = args LIST Select<=From, LIST From<=Where, LIST Where<=>-1;
  
  #Or by giving a list of positions relative to the LIST's starting point
  my ($man, $machine) = args LIST vs = [-1, 1];
  my ($tick, $santa)  = args LIST vs & [-1, 1];    # include starting key
  my ($kong, $godzilla)=args LIST vs ^ [-1, 1];    # exclude starting key
  
  #Specify synonymous alternatives using brackets
  my ($either_end, $tint) = args [0, -1], [Colour, Color];


=head1 VERSION

Version 0.9.4 (December 2007)

This version introduces the PARSE keyword.

=cut




	#===========================================================================
	#
	# 	INFRASTRUCTURE
	#
	#===========================================================================

	package Params::Clean;
	use version; our $VERSION = qv"0.9.4";
	
	use 5.6.0;																			# Because we use "our", etc.
	use strict; use warnings; no warnings qw(uninitialized);							# Be good little disciplinarians (but not too good)
	use Devel::Caller::Perl 'called_args';		                                      	# for stealing our caller's @_
	
	
	our (@keywords, @KEYWORDS);					                                    	# We need to declare these and then init them with BEGIN so they're ready for the "use UID"
	BEGIN { our @keywords=qw/POSN NAME FLAG REST TYPE PARSE/; }	                       	# UID keywords
	BEGIN { our @KEYWORDS=(@keywords, "LIST", "args"); }		                       	# all keywords (LIST handled specially)
	
	use UID @keywords;			# Set up some lexicals that won't be available anywhere else, so exporting refs to them will act as unique identifiers
	
	our %Warn;																			# categories of warning levels by caller: e.g. $Warn{main}{missing_start}=fatal
	BEGIN {
		$Warn{undef}={			               	# default warning levels
					invalid_opts=>"warn", 		# illegal warning or keyword options used
					funny_arglist=>"ignore",	# asked to PARSE something that's not an ARRAY, HASH, or CODE
					missing_start=>"ignore", 	# LIST cannot find specified starting key
					missing_end=>"warn", 		# LIST cannot find specified ending key
					invalid_list=>"warn", 		# tried to use a FLAG or LIST, etc, as endpoint to a LIST
					invalid_type=>"warn", 		# tried to use an illegal TYPE definition
					nonint_name=>"warn",  		# non-integral key will be used as a name
					orphaned_type=>"warn", 		# TYPE not followed by a definition
					misplaced_rest=>"warn", 	# REST used before last parameter
					misplaced_parse=>"die", 	# PARSE used after first parameter
					 };
		}
	# now create constants with all our exception-type names (handy, and helps catch typos!)	
	BEGIN { no strict 'refs'; for my $s (keys %{$Warn{undef}}) {*{$s}=sub {return $s, @_ if wantarray; warn "ERROR: attempt to use args after '$s' which is in scalar context (perhaps you need a comma after '$s'?)" if @_; return $s};} }	# stolen from UID.pm
	
	
	our $CaseSensitive=0;																# By default, we match match names case-insensitively
	our $Debug=0;																		# Whether to show debugging messages (0 level=none)
	sub same($$);	sub insame($@);	sub typewriter($$); sub warning;					# predeclare!
	sub un {grep !$_[$_], 0..@_-1;}														# pull out all the keys that work out to false (used with @used!)
	sub array { map ref($_) eq "ARRAY"?@$_:$_, (@_) }									# Normalise a list by expanding array-refs
	sub comma { "[".join(", ", array @_)."]" } 											# Format array(ref) into "[a, b, c]"
	
	sub debug 
	# For showing debugging messages
	#	Does some basic cleanup, like unpacking array-refs, or looking up our UIDs
	#	Pass each thing you want cleaned as a separate arg
	{ 
		return unless $Debug>=shift;													# do nothing unless our debugging level is high enough
		my $i; my %ID=reverse(POSN=>POSN, FLAG=>FLAG, NAME=>NAME, TYPE=>TYPE, REST=>REST);		# lookup hash for our special IDs
		warn join " ", map $ID{$_}?"|$ID{$_}|":ref eq"ARRAY"?"[".(join " ", map $ID{$_}?"|$ID{$_}|":$_, (@$_))."]":ref eq "HASH"?"{".(join "", map {$i++%2?"$_; ":"$_=>"} %$_)."}":"$_", (@_), "\n"
	}
	
	

	#===========================================================================
	#
	# 	STARTUP
	#
	#===========================================================================
	
	sub import
	# Handle module options: renaming exported UIDs and setting desired warnings
	#
	# RENAMING: pass a keyword ID followed by the new name (LIST=>"PLIST") -- setting to undef means don't export it at all
	# WARNINGS: warn=>"type", or die=>"type" or fatal=>"type", or ignore=>"type"
	{
		my $me=shift; 							# our package name
		my @opts, my $i; push @opts, [$_[$i++]=>$_[$i++]] while $i<@_;	# pair up the options (we would use a hash, but we want to preserve order, and anyway we could have the same key repeated)
		my %EXPORT=map {$_=>$_} @KEYWORDS;		# keywords to be exported (normally all @KEYWORDS) in convenient hash format
		my $keys=join "|", @KEYWORDS;			# for regex to test for any of our keywords
		my $caller=(caller)[0];					# caller's package
		
		
		# Set up warning/fatal/ignoral categories
		$Warn{$caller}={%{$Warn{undef}}};					      		# start by setting up default warning levels
		for (grep $opts[$_][0]=~/^(warn|die|fatal|ignore)$/, 0..$#opts)	# grep through the key-halves of each opt for exception-levels
		{
			my $opt=delete $opts[$_];
			warning(invalid_opts qq[WARNING: Ignoring attempt to set unrecogised warning category "$opt->[1]"]) and next unless exists $Warn{$caller}{$opt->[1]};	# complain if trying to set an invalid category
			$Warn{$caller}{$opt->[1]}=$opt->[0];		# set level for this caller and remove opts as we handle them
		}
		
		
		# Look for our keywords: pairs that start with a keyword substitute the new name instead
		$EXPORT{$opts[$_][0]}=$opts[$_][1] and delete $opts[$_] for grep $opts[$_][0]=~/^($keys)$/, grep exists $opts[$_], 0..$#opts; # look for our keywords and remove opts as we deal with them
		no strict 'refs';		                                                        # so we can manually "export" the subs to the caller's namespace
		*{$caller."::".$EXPORT{$_}}=\&{$_} for grep defined $EXPORT{$_}, keys %EXPORT;	# skipping undefs
		
		
		# If there are any opts left, we don't know what to do with them
		warning invalid_opts "WARNING: Ignoring unrecognised options [".join(", ", map "$opts[$_][0]=>$opts[$_][1]", grep exists $opts[$_], 0..$#opts)."]" if @opts;
	}
	
	
	
	#===========================================================================
	#
	# 	LISTs
	#
	#===========================================================================
	
	# "LIST" types are objects containing the pieces we need to handle lists
	#	{
	#	  spec => what kind of list this is: <abs>olute or <rel>ative, 
	#	  start => the param key(s) which begin the list, 
	#	  end => the param(s) which end an absolute list, 
	#	  pos => the list of positions to grab for a relative list,
	#	  incl => a flag indicating whether to include the starting/ending param
	#	}
	#
	#	A few operators are overloaded to provide convenient syntax for building up our LIST objects
	#	Since assignment isn't overloadable, we also tie our object so we can STORE it ourselves
	
	sub LIST ($) :lvalue { tie my $list, __PACKAGE__, @_; $list }								# takes a single arg and turns it into a tied List-object
	sub TIESCALAR { my $class=shift; bless {spec=>"abs", start=>[array @_]}, $class }			# object is a hash containing the setup; all we know upon creation is the starting-point; assume absolute [can override that later if we specify more details]
	sub FETCH { shift; };	                                                                	# nothing fancy here, just return the object straight
	
	use overload '<=>',sub { @{$_[0]}{spec=>end=>incl=>}=("abs", [array $_[1]], 1); shift };	# absolute list, include end point
	use overload '<=', sub { @{$_[0]}{spec=>end=>incl=>}=("abs", [array $_[1]], 0); shift };	# absolute list, don't include end point
	
	sub STORE($)          { @{$_[0]}{spec=>pos=>incl=>}=("rel", [array $_[1]], "?"); }			# "overload =": relative, don't force starting point either way
	use overload '&', sub { @{$_[0]}{spec=>pos=>incl=>}=("rel", [array $_[1]], "Y"); shift };	# relative list, include start point
	use overload '^', sub { @{$_[0]}{spec=>pos=>incl=>}=("rel", [array $_[1]], "N"); shift };	# relative list, don't include start point
	
	use overload q(""), sub { "{". (join ", ", map "$_=>".(join ":", array($_[0]->{$_})), (qw/spec start end pos incl/) )."}" };	#stringify for debug messages
###check for attempting to use operators more than once in a row? or to use other operators?!?	
	


	#===========================================================================
	#
	# 	PARSE ARGS
	#
	#===========================================================================
	
	sub args
	{

		#------------------------------------------------------
		# 	DECLARE/INITIALISE VARIABLES
		#------------------------------------------------------
		
		my @sig=@_;															# The signature specifying how to parse the caller's args
		
		# Get args to be parsed
		if (same $sig[0], PARSE)		    		                    	# then specially passed in the list to parse
		{	shift @sig; @_=preparse(shift @sig);	}  			         	# drop first arg(=PARAM) and grab the second(=arrayref)
		else 		                        		                    	# we use [the caller's] @_ by default
		{	@_=called_args(0);	}											# get the @_ args passed in to the original sub (=our caller)
		
		my $n;																# Counter for which parameter we're processing
		my $type;															# holder for the ID of the arg-type currently being processed
		my $subtype;														# holder for the arg-type inside a param group

		my @keys;															# Holds the param key(s) we're going to look for at any one time
		my @used=(undef)x@_;												# track which args we've used (filled out so we can use it in parallel with @_)
		my $rest;  															# flag indicating whether to return any leftover args
		my @REST;															# list of leftover args, if any

		my @results;														# the resulting args for each param ($result[$n]=array ref containing all possible args matching that param)
		my $results;														# collects results in a string for debugging
		my @number;															# the count of resulting args for each param ($number[$n]=count of @$results[$n])
		
		our $args=@_;														# number of args ("our" so other subs can see it, specifically parse())
		
		local $_;      														# so we don't clobber $_

		
		#------------------------------------------------------
		# 	LOOP THROUGH PARAMS, GRAB MATCHING ARGS 	
		#------------------------------------------------------
		
		debug 4, POSN=>POSN, FLAG=>FLAG, NAME=>NAME, TYPE=>TYPE, REST=>REST;
		debug 1, "ARGS: @_\n";
		
	my $typesub;	
		for my $param (@sig)
		{
			warning misplaced_rest "WARNING: attempt to use REST before last parameter" and $rest++ if $rest==1;		# complain if REST flag is set and we're still looping (i.e. not done with the sig) [increment and check only when ==1 so the warning doesn't spam us every time through the loop!]
			
			warning misplaced_parse "ERROR: encountered PARSE after beginning of parameter list" if same $param, PARSE;	# complain if PARSE wasn't the first parameter (would've been dealt with above)
			
			#Switch type whenever we hit one of our identifiers
			
			if ($type==PARSE)																# We found a PARSE keyword last pass through (which was an error, of course)
			{
				warning misplaced_parse "\tIgnoring misplaced PARSE values"; 				# but too late to do anything with them
				undef $type;																# reset for next arg
			}
			elsif ($typesub)																# previous item was a TYPE type, so look for the sub
			{
				$param=[TYPE, $param];														# put our TYPE=>sub into an array-ref so we can deal with it as a single unit below
				$typesub=0;
				debug 2, "\t", $param, "TYPE-sub";	
				redo;																		# start checking again; our new array-ref will get handled by the "else" below
			}
			elsif (same $param, TYPE)
			{
				$typesub=1;																	# set flag so next pass we can grab the type-sub
			}
			elsif (insame $param => POSN, NAME, FLAG, PARSE)								# we've hit one of our types
			{
				$type=$param;  																# Switch current type-holder to that type
				debug 2, "\t", $type, "type";
			}
			elsif (same $param, REST)
			{
				$rest=1;																	# Flag=true: we want to return any leftover args
				
			}
			elsif (ref($param) eq __PACKAGE__)												# if it's one of our objects, it must be a LIST
			{
				my $err;																	# holds error message if something goes wrong
				debug 3, "\t LIST", $param;
				
				#Break up a parameter [list] into keys and subtypes
				debug 3, "\t\tChecking starting params", $param->{start};
				my ($keys, $types)=parse($param->{start}, $type);
				
				
				#Begin by finding the start key
				my $start;																	# will contain the index of the starting arg (once we've found it)
				Arg: for my $a (un@used)													# only remaining unused args can be potential keys
				{
					for my $i (0..@$keys-1)													# compare arg against each key
					{
						my ($key, $kind) = ($keys->[$i], $types->[$i]);
						debug 4, "\t#$n\tKey[$i]:", $key, "\tType:", $kind, "\tArg[$a]:", $_[$a], ;
						
						if (ref $key eq __PACKAGE__)										# check this first because LIST produces a key that is a LIST-object, but doesn't affect the current $kind
						{
							$err="Whoa, can't use other LISTs inside a LIST!  Ignoring starting param key: @{$key->{start}}";
						}
						elsif (insame $kind => FLAG, TYPE)
						{
							$err="Whoa, can't use FLAGs or TYPEs inside a LIST!  Ignoring starting param key: $key";
						}
						elsif ( ($kind==POSN and $a==$key) or ($kind==NAME and same $_[$a], $key) )
						{
							debug 3, "\t\t", $kind, "«$key» matches «$_[$a]»";
							$start=$a; last Arg;											# no need to check any other args once we've got the starting point
						}
					}
				}
				
				debug 2, "\t\tStarting arg[$start] =", $_[$start];
				if (!defined $start)
				{ 
					unless ($err)															# we might already have an error because of an invalid starting key
					{
						$err="ERROR: couldn't find beginning of LIST starting with ".comma $param->{start}; 
						$err.=" (probably already used up by another param!)" if insame $param->{start}->[0], @_;	# more helpful message -- if starting keyword really is in the arg list, then we most likely can't find it because it already got used somewhere else
					}
					
					warning missing_start $err; 
					
					$results[$n++]=[];	push @number, undef; 								# add an empty result since we could find it properly
					next;
				}
				
				#Next we want to build up a list of indices of the args that should go in this list
				#	If it's a relative list, the elements are defined by $list->{pos}
				#	If it's absolute, we need to loop through the args until we hit the end point
				
				my @grab;																	# will store the arg indices we want
				
				if ($param->{spec} eq "rel")												# relative lists already know the positions to grab
				{
					my %grab;																# use a hash because it's an easy way to prevent duplicates
					@grab{@{$param->{pos}}}=1;												# set all the desired keys to true to grab everything 
					
					if ($param->{incl} eq "Y")		{ $grab{0}=1; }							# if LIST is inclusive, grab the starting key itself (the 0 position) 
 					elsif ($param->{incl} eq "N")	{ delete $grab{0}; }					# else LIST is exclusive, so make sure exclude 0 in the positions
					$used[$start]=1;														# even if we're not collecting the starting key itself, we still want to make sure it gets flagged as used
					
					@grab=map $_+$start, (sort keys %grab);									# convert relative positions into absolute, all sorted and unique
					debug 3, "\t\tRelative:", @grab;
				}
				else																		# must be an absolute list
				{
					#Search for the ending point, collecting the in-between elements as we go
					my $end;																# will contain the index of the ending arg (once we've found it)

					if ($param->{end})														# an ending key was specified, so search for it
					{
						#Break up a parameter [list] into keys and subtypes
						debug 3, "\t\tChecking ending params", $param->{end};
						my ($keys, $types)=parse($param->{end}, $type);
						
						#Finish by finding the end key
						Arg: for my $a (un@used)											# only remaining unused args can be potential keys
						{
							next unless $a>$start;											# don't look for the end prior to the start!
							
							for my $i (0..@$keys-1)											# compare arg against each key
							{
								my ($key, $kind) = ($keys->[$i], $types->[$i]);
								debug 4, "\t#$n\tKey[$i]:", $key, "\tType:", $kind, "\tArg[$a]:", $_[$a], ;
								
								if (ref $key eq __PACKAGE__)								# check this first because LIST produces a key that is a LIST-object, but doesn't affect the current $kind
								{
									$err="Whoa, can't use other LISTs inside a LIST!  Ignoring ending param key: @{$key->{start}}";
								}
								elsif (insame $kind => FLAG, TYPE)
								{
									$err="Whoa, can't use FLAGs or TYPEs inside a LIST!  Ignoring list with ending param key: $key";
									$end=$start;											# invalid ending point, so collect only the starting point
								}
								elsif ( ($kind==POSN and $a==$key) or ($kind==NAME and same $_[$a], $key) )
								{
									debug 3, "\t\t", $kind, "«$key» matches «$_[$a]»";
									$end=$a; last Arg;										# no need to check any other args once we've got the ending point
								}
								#### ^---- should make this into a function -- almost identical to the same code for Starting keys
							}
						}
						
						if ($err or !defined $end)
						{ 
							unless ($err)													# we might already have an error because of an invalid starting key
							{
								$err="ERROR: couldn't find ending of LIST from ".comma($param->{start})." to ".comma($param->{end});
								$err.=" (probably already used up by another param!)" if insame $param->{end}->[0], @_;	# more helpful message -- if ending keyword really is in the arg list, then we most likely can't find it because it already got used somewhere else
							}
							
							warning missing_end $err; 
							$end=$args-1 unless defined $end; 	#to grab all until end... or should we skip this because of the error: "next;" ??
						}
						elsif (!$param->{incl})
						{
							$end--;										                	# back up if exclusive -- don't include the ending arg itself
						}
					}
					else																	# no ending key specified means go up to the next used arg
					{
						debug 3, "\t\tEndless list...";
						$end=$start;														# we go at least this far!
						$end++ while !$used[$end] and $end<$args-1;							# bump up as long as we're not used, or haven't run off the end of the args yet
					}
					
					debug 2, "\t\tEnding arg[$end] =", $_[$end];
					
					#Now collect all the args up to the ending point
					for my $a ($start..$end)
					{
						push @grab, $a if !$used[$a];
						$used[$a]=1;														# if it wasn't used before, it is now!
					}
					
					debug 3, "\t\tAbsolute: [$start..$end] ", @grab;
				}
				
				#Now that we know what items we want, grab them!
				for (@grab)
				{
					push @{$results[$n]}, $_[$_];
					$used[$_]=1;
				}
				
				debug 2, "---> LIST", $param, "=", @{$results[$n]}, "\n";
				push @number, 0-@{$results[$n]};	#<--negative to force array-ref!		# keep count of how many args we just collected
				$n++;																		# ready for next param
			}
			#else we've possibly hit a variable-ref, once we add features for mixing them in to the specs!  =)
			#
			else	#we've hit a param specifier (or array-ref'd group of them)
			{
				#Get all the param keys we're looking for for this arg into a standard format (an array, @keys)
				# possibly multiple options for the key, normalise on an array whether we have a single value or more
				debug 4, "Checking params", $param;
				my ($keys, $types)=parse($param, $type);
				
				
				# Now loop through all the args and pick out the ones that match the param keys
				debug 3, "\tunused: ", un@used;
				debug 3, "\tSEEKING:", @$keys;
				
				for my $a (un@used)															# only remaining unused args can be potential keys
				{
					for my $i (0..@$keys-1)													# compare arg against each key
					{
						my ($key, $kind) = ($keys->[$i], $types->[$i]);
						debug 4, "\t#$n\tKey[$i]:", $key, "\tType:", $kind, "\tArg[$a]:", $_[$a];
						
						if ($kind==POSN and $a==$key)
						{
							push @{$results[$n]}, $_[$a];
							$used[$a]=1;
							last;															# no need to check any other keys against this arg, we already grabbed it
						}
						elsif ($kind==FLAG and same $_[$a], $key)
						{
							$results[$n]->[0]++;											# count the flag
					######### hm, fine if only a flag, we can ++ to count it... but what if we try to synonymise [POSN 1, NAME foo, FLAG bar]??? $res[0] might not be the flag one, hm, then what?!?!?
							$used[$a]=1;
							debug 3, "\t «$key» matches «$_[$a]»";
							last;															# no need to check any other keys against this arg, we already grabbed it
						}
						elsif ($kind==NAME and same $_[$a], $key)
						{
							push @{$results[$n]}, $_[$a+1];
							$used[$a]=1; $used[$a+1]=1;										# mark param key and its arg value as used
							debug 3, "\t «$key» matches «$_[$a]: $_[$a+1]»";
							last;															# no need to check any other keys against this arg, we already grabbed it
						}
						elsif ($kind==TYPE)													# TYPE and &typesub(arg) returns true
						{
							my $match;														# flag whether the current arg matches this TYPE, once we figure out what the type is!
							if ( ref($key) eq "CODE" )  { $match=&$key($_[$a]) }			# if CODE, call it with the arg to see whether it meets the criteria
							#anything else to check for? the the CODE takes a single arg?
							elsif ( !ref($key) )		{ $match=$key eq ref($_[$a]) }		# if $key is a plain value (string), then see if the arg is that kind of ref/class
							# other possibilities?  Compare classes/refs directly (does that make sense??)
							
							else															# not a type of TYPE that we recognise!
							{
								debug 2, "ERROR! Invalid TYPE!!!\t#$n\tKey[$i]:", $key, "\tType:", $kind, "\tArg[$a]:", $_[$a];
								warning invalid_type "WARNING: attempt to use invalid TYPE";
							}
							
							if ($match)
							{
								push @{$results[$n]}, $_[$a];
								$used[$a]=1;
								debug 3, "\t «$_[$a]» is", $key;
								last;														# no need to check any other keys against this arg, we already grabbed it
							}
						}
						#else... should be impossible to reach here; everything already accounted for and caught above...
					}						
				}
				
				debug 2, "--->", $param, "=", @{$results[$n]}, "\n";
				
				push @number, 0+@{$results[$n]};											# keep count of how many args we just collected
				$n++;																		# ready for next param
			}
		}
		
		debug 2, "\tunused:", un@used, "\n\n";
		
		
		#------------------------------------------------------
		# 	THAT'S ALL OF THEM, RETURN THE RESULTS!
		#------------------------------------------------------
		
		for $n (0..$#results)
		# Each result is an array-ref -- figure out whether to return single value or array-ref:
		#	if single, return scalar; if multiple values, or negative count (=force array), return arrayref
		{
			$results[$n]=$results[$n]->[0] if $number[$n]==0 || $number[$n]==1;				# if only one (or no) elements, use a scalar
			$results.=($number[$n]==0 || $number[$n]==1 ? " $results[$n] " : " [@{$results[$n]}]") if $Debug;	# build string for debugging
		}

		debug 1, "SIG:", $results[$n], (@sig);
		debug 1, " #: ", @number;
		debug 1, "VARS:$results" . ($rest?" -- @_[un@used]":"")."\n";
		
		push @results, @_[un@used] if $rest;												# remaining unused args = REST
		return @results;
	}
	
	
	
	#===========================================================================
	#
	# 	SAME
	#
	#===========================================================================
	
	sub same($$)
	#	Compare two items
	#	
	#	String comparison -- case insensitive depending on our settings
	#	Also compares ref's and so can be used to do special unique ID (or object) comparisons
	#	Note that we use lc() (for case-insensitive comparisons) only if both args are strings (no ref)
	{
		ref($_[0]) eq ref($_[1]) and					# must be same type
		($CaseSensitive || ref($_[0]) || ref($_[1]))	# if objects involved, or case-sensitive strings,
			? $_[0] eq $_[1]							#	then do an exact comparison
			: lc $_[0] eq lc $_[1];						#	otherwise case-insensitive
	}
	
	#===========================================================================
	
	sub insame($@)
	#	Compare one item to all the elements in a list
	#	Returns true if anything in the list is the same() as the first arg
	{
		my $i=shift;										# first item, the one to search for in the list
		for (@_)
		{
			return 1 if same($i, $_);						# this one matched
		}
		return undef;										# made it through whole list with no matches
	}
	
	
	
	#===========================================================================
	#
	# 	TYPEWRITER
	#
	#===========================================================================
	
	sub typewriter($$)
	#	Figure out what type to use for a parameter
	#	
	#	typewriter($param, $type)
	#	$param = the parameter key under consideration
	#	$type = if set, force the parameter to be evaluated as this type 
	{
		my ($param, $type)=@_;
		
		return $type if $type;															# If a type has been set, use it
### But how to emit a warning if we detect a type mismatch -- even if warnings weren't asked for, because it's important to let the user know that we're overriding $param and making it "0"
###if ($t==POSN && !$numeric) { warnings::warn "WARNING: using non-numeric key '$param' as positional parameter"; $param=0; }
	### ???warning if we're looking for POSNs and our key doesn't look like an int (force item to zero to prevent refs evaluating to huge numbers!)
		
		return NAME if ref $param;														# an object or something... could numify to an int, but we want to preserve it???
		###... or should we check for stringification first?  what to do about objects/refs... can numify to ints, hm...
		
		# If no type is set, check whether the parameter looks like an int or a string and assume POSN or NAMES accordingly...
		no warnings;					                                            	# or else we get "Argument isn't numeric in <"  =P
		if ($param<0 || $param>0 || $param=~/^\s*[+-]?0+\.?0*\s*$/)						# evaluates as a number (neg, pos, or looks like 0)
		{
			return POSN if $param==int($param);											# numeric and an int
			###Maybe warn if some kind of ref? not an object?? Hm....
			##perhaps use "$param"<0, etc., since a stringified int will still numify to an int...
			warning nonint_name if "WARNING: non-integral number $param will be interpreted as a named parameter";
		}
		
		# Not an int, so assume named
		return NAME;
	}
	
	
	
	#===========================================================================
	#
	# 	WARNINGS
	#
	#===========================================================================
	
	sub warning
	# Display a warning message, or die, or do nothing, according to our error levels
	{
		my $category=shift;					# error category, as controlled by %Warn
		my $level=1;						# start one level up (our caller)
		my @caller=(caller $level);	    	# to find out whose settings to use; 
		@caller=(caller ++$level) while $caller[0] eq __PACKAGE__;		# keep moving a level up until we go beyond our own package
		
		my $w=$Warn{$caller[0]}{$category};
		
		return if $w eq "ignore";
		warn "@_ at $caller[1] line $caller[4]\n";
		die "\t(Fatal exception category: $category)\n" if $w eq "die" or $w eq "fatal";
	}
	
	
	
	#===========================================================================
	#
	# 	PREPARSE LIST of ARGS
	#
	#===========================================================================
	
	sub preparse	
	# Get the list of args to be parsed, passed in via a PARSE keyword
	{	
		my $args=shift;							# we pass in a single value
		my $ref=ref $args || "value";
		
		# normally, the list should be passed in as an array-ref
		return @$args if $ref eq "ARRAY";
		
		# but might be a hashref, we just expand as a list
		return %$args if $ref eq "HASH";
		
		# of it we've got a coderef, call it and return the results
		return &$args if $ref eq "CODE";
		
		# anything else, just assume it's the only arg and return it!
		warning funny_arglist "WARNING: suspicious arg-list given to PARSE (a single unrecognised $ref)";	
		return $args;
	}
	
	
	
	#===========================================================================
	#
	# 	PARSE PARAMS
	#
	#===========================================================================
	
	sub parse	
	# Break up a parameter [list] into keys and subtypes
	{	
		our $args;
		my (@keys, @types, $i);
		my $typesub;																	# Flag for handling TYPE types when we find them
		my $subtype=pop;																# Inner types start off as the outer-type
		
		debug 3, "Parsing params:", @_;
		for my $p (array shift)															# Loop through all the param keys sought
		{
			#Switch subtype whenever we hit one of our identifiers
			if ($typesub)																# previous item was a TYPE type, so look for the sub
			{
				push @keys, $p;
				push @types, TYPE;
				$i++;
				$typesub=0;
				debug 2, "\t", $p, "TYPE-sub";		
			}
			elsif (same $p, TYPE)
			{
				$typesub=1;																# set flag so next pass we can grab the type-sub
			}
			elsif (insame $p => POSN, NAME, FLAG)										# we've hit one of our types
			{
				$subtype=$p;  															# switch current subtype-holder to that type
				debug 2, "\t", $subtype, "subtype";
			}
			else		#we've hit a param specifier, so build up our lists
			{
				my $t=typewriter $p, $subtype;
				$p+=$args if $t==POSN && $p<0;											# convert negative indices to the positive equivalent
				
				push @keys, $p;
				push @types, $t;
				$i++;
			}
		}
		
		warning orphaned_type "WARNING: Orphaned TYPE" if $typesub; 	         		# we found a TYPE but no type-sub was following it!
		
		return \@keys, \@types;
	}	
	
	
	
	
	#===========================================================================
	#
	# 	POD
	#
	#===========================================================================


=head1 INTRODUCTION

C<Params::Clean> is intended to provide a relatively simple and clean way to parse an argument list.
Perl subroutines typically assign the values of C<@_> to a list of variables, which is even simpler and cleaner, 
but has the disadvantage that all the parameters are thus determined by position.
If you have optional parameters, or are worried about the order in which they might be passed
(it can be a pain to have to know the order when there are more than a couple of arguments),
it's much nicer to be able to use named arguments.  

The traditional way to pass a bunch of named arguments is to interpret C<@_> as a hash (a series of paired parameter names and values).
Easy, but you have to refer to your arguments via the hash, and you can't have 
multiple parameters with the same name or any parameters that I<aren't> named.
There are many modules that provide nifty mechanisms for much fancier arg processing;
however, they entail a certain amount of overhead to work their magic.  
(Even in simple cases, they usually at least require extra punctuation or brackets.)

C<Params::Clean> lacks various advanced features in favour of a minimal interface.
It's meant to be easy to learn and easier to use, covering the most common cases
in a way that keeps your code simple and obvious.
If you need something more powerful (or just think code should be as hard to read as it was to write (and real programmers know that it should!)),
then this module may not be for you.

(C<Params::Clean> does have a few semi-advanced features, but you may need extra punctuation to use them.
(In some cases, even extra brackets.))



=head1 DESCRIPTION


=head2 Basics

In its simplest form, the B<C<args>> function provided by C<Params::Clean> 
takes a series of names or positions and returns the arguments
that correspond to those positions in C<@_>, or that are identified by those names.  
The values are returned in the same order that you ask for them in the call to C<args>.
C<@_> itself is never changed.
(Thus you could call C<args> several times, if you wanted to for some reason.
You can also manipulate C<@_> before calling C<args>.)

  marine("begin", bond=>007, "middle", smart=>86, "end");
  
  sub marine
  {
    my ($first, $last, $between, $maxwell, $james)=args 0,-1, 3, 'smart','bond';
    #==>"begin"  "end"  "middle"    86       007
    
    my ($last, $max, $between, $first, $jim) = args(6, 'smart', -4, 0, 'bond');
    #same thing in a different order
  }

By default, integers passed to C<args> are taken to refer to positions in C<@_>, and
anything else is taken to be a name, or key, that returns the element following it if it is found in C<@_>.
(Note that you can use negative values to count backwards from the end of C<@_>.  
If some values are too big or too small for the number of elements in C<@_>, undef is returned for those positions.)

=for TODO: add a warning? probably off by default, but settable if you're worried about overshooting...


There is nothing special about the names as far as Perl is concerned: calling a function passes a list via C<@_> as always. 
Then C<args> loops through C<@_> and looks for matching elements; if it finds a match, the element of C<@_>
following the key is returned.  If no match is found, undef is returned, and if multiple matches are found,
a reference is returned to an array containing all the appropriate values (in the order in which they occurred in C<@_>).

  human(darryl=>$brother, darryl=>$other_brother);
  
  sub human
  {
    my ($larry, $darryls) = args Larry, Darryl;
    #==> undef  [$brother, $other_brother]
  }

Keys are insensitive to case by default, but this is controlled by whether C<$Params::Clean::CaseSensitive> is true or not when C<args> is called.

=over 1

=item 

Note that although C<Params::Clean> will let you mix named and positional arguments indiscriminately, 
that doesn't mean it's a good idea, of course.  It's not uncommon to have one or a few positional args 
required at the beginning of a parameter list, followed by various (optional) named args.  In particular,
methods always have the object passed as the argument in position 0.
It also might be reasonable sometimes to use fixed positions at the end of an arg list (since we can refer to them with negative positions).
Trying to mix named and positional params in the middle of your args, though, is asking for confusion.
(But many of the examples here do that for the sake of demonstrating how things work!)

=back



=head2 Specifying the argument list

By default, C<args> parses C<@_> to get the list of arguments.  You can override this with the C<PARSE> keyword, 
which takes a single value to be used for the args list.  For example, C<args PARSE \@_, ...> would explicitly get its arguments from C<@_>.
You can use any array-ref, or a hash-ref which will be flattened and treated as a plain list, or a code-ref which will be called and
the results used as the argument list.  
Anything else will be used as a (single) argument value.

The C<PARSE> keyword and its value must come immediately after C<args>; putting other parameters before it will raise an error.



=head2 POSN/NAME/FLAG identifiers

You can also explicitly identify the kind of parameter using the keywords C<POSN> or C<NAME>.
This can be useful when you have, for example, keys that look like integers but that you want to treat as named keys.

  tract(1=>money, 2=>show, 3=>'get ready', Four, go);
  
  sub tract
  {
    my ($one,  $two,  $three,  $four) = args NAME 1, 2, 3, four;
    #==> money  show  get ready go
    
    #Without the NAMES identifier, the 1/2/3 would be interpreted as positions:
    # $two would end up as "2" (the third element of @_), $three as "show", etc.
  }

Conversely, you could use the C<POSN> keyword to force parameters to be interpreted positionally.  
(Of course, most strings reduce to a numeric value of zero, which refers to the first position.)

Besides named parameters, you can also pass C<FLAG>s to a function 
-- flags work like names,
except that they do not take their value from the following element of C<@_>; they simply become true
if they are found.  More exactly, flags are counted; a flag returns C<undef> if it does not occur in C<@_>,
or returns the count of the number of times it was matched.  (This allows you to handle flags
such as a "verbose" switch that can have a differing effect depending on how many times it was used.)

  scribe(black, white, red_all_over, black, jack, black);
  
  sub scribe
  {
    my ($raid, $surrender, $rule, $britannia)=args FLAG qw/black white union jack/;
    #==>  3        1        undef      1
  }

The identifiers (C<POSN, NAME, FLAG>) can be mixed and repeated in any order, as desired.
The default integer/string distinction applies only until the first identifier is encountered;
once an identifier is used, it remains in effect until another identifier is found.
(Well, except in the case of I<alternatives>, as explained in the next section.)



=head2 Alternative parameter names

There may be situations where you want to mix different parameters together;
that is, return all the args named "foo" and all the args named "bar" in one set, as though they were all named "foo" (or all named "bar").
You can specify alternatives that should be treated as synonymous by putting them in square brackets (i.e., using an array-ref).
If a single match is found, it is grabbed; if there are more, they are all returned as an array-ref
(or in the case of a flag, it will be incremented as many times as there are matches).

  text(hey=>there, colour=>123, over=>here, color=>321);
  
  sub text
  {
    my    ($horses,    $hues,           $others)
     =args [hey, hay],  [colour, color],  [4, 5];
      #===> there        [123, 321]        [over, here]
  }

As the example shows, this also works for positional parameters, so you can return multiple positions as a single arg too.
Like any parameters, synonyms are by default positional (if numeric) or named (if not);
they are also affected normally by any identifier (C<POSN>/C<NAME>/C<FLAG>) that precedes them.
If you specify an identifier B<inside> the alternatives, the brackets provide a limited scope,
so the identifier does not extend to any parameters outside the list of alternatives.

  lime(alpha, Jack=>"B. Nimble", verbosity, verbosity);
  
  sub lime
  {
    my    ($start,         $verb,     $water_bearer,     $pomp) 
     =args [0, FIRST], FLAG verbosity, [NAME Jack, Jill], pomposity;
      #===> alpha             2          B. Nimble
  }

Without the C<NAME> identifier, "Jack" and "Jill" would be parsed as flags; 
if the C<NAME> came in front of the opening bracket instead of inside it, "pomposity" would also be considered a C<NAME> instead of a C<FLAG>.
(There's nothing to say a list of synonyms can't contain only one item; so you might say
C<[FLAG foo]> to identify that single parameter as a flag without affecting the parameters that follow it.)

The order of the synonyms is irrelevant; once keys are declared as alternatives for each other, 
C<Params::Clean> sees no difference between them.  All the args that match a given key or keys are
returned in the order in which they occur in C<@_>.



=head2 The REST

Another keyword C<args> understands is C<REST>, to return any elements of C<@_> that are left over 
after all the other kinds of parameters have been parsed.  
The leftovers are not grouped into an array-ref; they are simply returned as a list of items coming after the other args.

  $I->conscious(earth, sky, plants, sun, fish, animals, holiday);
  
  sub conscious
  {
    ($self, @days[1..6], @sabbath) = args 0, 1..6, REST;
  }

Although the REST identifier can appear anywhere in the call to C<args>, the remaining arguments are always returned last.  
(If warnings are turned on, C<args> will complain about C<REST> not being specified last.
(There wouldn't be any point to returning the leftover values in the middle of the other arguments anyway,
since you don't know how many there are.  (And if you really do know, then just use positionals instead.)))

=for TODO ### What if we allow [REST] to return as arrayref instead of loose? -- and then you could put it anywhere; or also do [foo, 1, REST]?



=head2 Identifying args by type

As well as by name or position, C<args> can also gather parameters by type.  
For instance, you can collect any array-refs passed to your function by asking for C<TYPE "ARRAY">.  
C<TYPE> checks the C<ref> of each argument, so you can select any built-in reference (C<SCALAR, ARRAY, HASH, CODE, GLOB, REF>),
or the name of a class to grab all objects of a certain type.

  #Assume we have created some filehandle objects with a module like IO::All
  version($INPUT, $OUTPUT, some, random, stuff, $LOGFILE);
  
  sub version
  {
    my ($files, @leftovers) = args TYPE "IO::All", REST;
    #===> [$INPUT, $OUTPUT, $LOGFILE], some, random, stuff
  }

C<TYPE> can also take a code-ref for more complex conditions.  
Each argument will be passed to the code block, and it must return true or false according to whether the arg qualifies.

  stance(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, oops, 13, 2048);
  
  sub Even { $_=shift; return $_ && /^\d+$/ && $_%2==0 }  
  # check whether the given value looks like an int and is even
  
  sub stance
  {
    my ($odds, $evens, @others) 
      = args TYPE sub {shift()%2}, TYPE \&Even, REST;     
        # one inline code-ref and one ref to a sub
    
    #===> [1,3,5,7,9,13], [2,4,6,8,10,2048], oops
  }

Note that since all the args are passed to our TYPE functions, that "oops" is going to cause a warning
about not being numeric when the odd-number coderef simply attempts to C<% 2> it.  
The C<Even> sub is better behaved: it first checks (with the regex) whether it's got something that looks like a number.
Since you never know what kind of arguments might get passed in, C<TYPE> blocks should always take appropriate precautions.

Also note that C<TYPE> functions do not validate the arguments.  Although the code block can be quite complex,
it doesn't reject anything; args that don't pass the test are simply not collected for that parameter.



=head2 Lists

=head3 Absolute lists

It is possible to collect a C<LIST> of arguments starting from a certain name or position,
and grabbing all the args that follow it up to an ending name or position.  
If the end point cannot be found (e.g., we run out of args because there aren't any more, or because 
we've reached an arg that was already grabbed by some previous parameter), the list stops.
If the end point is found, you can choose to include it in the list of args, or to exclude it
(in which case, the list will consist of the args from the starting point to the one just before the end point).

  dominant(some, stuff, Start=> C, G, A, E, F, C, End, something, else);
  
  sub dominant
  {
    my ($notes, @rest) = args LIST Start<=>End, REST;    # including end point
    #===> [Start,C,G,A,E,F,C,End], some, stuff, something, else
    
    my ($notes, @rest) = args LIST Start<=End, REST;     # excluding end point
    #===> [Start,C,G,A,E,F,C], some, stuff, End, something, else
  }

The C<LIST> keyword is followed by a parameter name or position to start from. 
An ending parameter is not required (the list will go until the end of the arg list, 
or until hitting an argument that was already collected).  
Use C<< <=> >> after the starting parameter key to indicate that the following end-point
should be included in the resulting list; use C<< <= >> to indicate that it should not.
(The starting argument is always included -- if you don't want it, you can always C<shift>
it off the front of the list later.)


Excluding the end-points from a list can be useful when you want to indicate that a list should stop where something else begins.
The following example has three C<LIST>s, where the end of one is the start of the next; if each list included its end-point,
then the starting-point for the next list would already be used up, and C<args> wouldn't see it.

  query(SELECT=>@fields, FROM=>$table, WHERE=>@conditions);
  
  sub query
  {
    my ($select, $from, $where)
      = args LIST SELECT<=FROM, LIST FROM<=WHERE, LIST WHERE;  #explicit endings
      #===> [SELECT, @fields], [FROM, $table], [WHERE, @conditions]
      
      # But this is not what we want -- the first list grabs everything:
      = args LIST SELECT, LIST FROM, LIST WHERE;                 #oops!
      #===> [SELECT, @fields, FROM, $table, WHERE, @conditions], undef, undef
      
      
    my ($where, $from, $select)     # note the reversed order
      = args LIST WHERE, LIST FROM, LIST SELECT;               #this is OK
      #===> [WHERE, @conditions], [FROM, $table], [SELECT, @fields]
  }

The middle part of the example shows that even though it's not necessary to specify an ending for a list, 
without one the argument-gathering might run amok.  
The last part illustrates how lists stop when they run out of ungathered args, even if the end-point hasn't been reached.
By collecting the C<WHERE> list first, the C<FROM> list is forced to stop when it reaches the last arg preceding the C<WHERE>,
and similarly the C<SELECT> list stops with the last element of C<@fields>, since the subsequent C<FROM> has already been used.
(See also L<"Using up arguments">.)



=head3 Relative lists

Specifying the starting and ending points for a list gives absolute bounds for the list.
Lists can also be relative; that is, specifying the desired positions surrounding the starting key.
The starting point itself represents position zero, and you can choose args before or after it.
You can specify just a single position to grab, but usually you will want to grab several positions, using the "alternatives" syntax [brackets/array-ref].
(However, you may not specify NAMEd params or FLAGs; a relative list can collect only args positionally relative to the starting parameter.)

  merge(black =>vs=> white);
  
  sub merge
  {
    my ($spys) = args LIST vs=[-1, 1];
    #===> [black, white]      # -1=posn before "vs", +1=posn after "vs"
  }

Use C<=> after the starting point to specify exactly what positions to collect (include position C<0> to grab the starting parameter too);
use C<&> followed by the positions to collect them as well as the the starting point itself (without having to include position C<0> explicitly); 
use C<^> to collect positions but exclude the starting point itself (even if C<0> is included in the positions given).
This lets you say things like C<LIST I<Start> ^ [-3..+3]> instead of spelling it out explicitly without the C<0>: C<LIST I<Start> = [-3. -2. -1. 1. 2. 3]>.
(The symbol used for the exclusive case is the same character that Perl uses for I<exclusive>-or.)

  due(First=>$a, $b, $c, Second=>$d, $e, Third=>$f);
  
  sub due
  {
    my ($first, $second, $third)
      = args LIST First=[1,2,3], LIST Second & 2, LIST Third^[-1..+1];
    #===> [$a, $b, $c], [Second, $e], [$e, $f]
  }

As shown, a relative list can take a just a single position, in which case the brackets are optional: C<LIST Foo=2> or C<LIST Foo=[2]>.


=head3 General notes about lists

You can mix positionals and named parameters in the starting point for any list, or for the ending point of an absolute C<LIST> 
in the expected way (using brackets/array-refs for alternatives):

  let(foo, Color=> $red, $green, $blue, Begin=>@scrabble=>Stop, bar);
  
  sub let
  {
    my ($rgb, $tiles, @rest)
     = args LIST [Colour,Color]=[1,2,3], LIST [Start,Begin]<=>[Stop,-1], REST;
    #===> [$red,$green,$blue], [Begin,@scrabble,Stop], foo, bar
  }

(In this example, the second list will end when it finds the string C<Stop> or reaches the last (C<-1>) position;
the first element of the list will be whichever parameter was found 
-- in this case, "C<Begin>").

If the starting key for a list appears more than once, the first occurrence (that has not already been used) will match.
So calling C<< some_func(FOO=>a,b,c. FOO=>x,y,z) >> could produce two lists with, e.g., C<< args LIST FOO=[1,2,3], LIST FOOE<lt>=>[-1] >>.

Unlike the other kinds of parameter (which return a single scalar or an array-ref if multiple matches are found),
lists always return an array-ref, even though it might contain only one arg.  
(Calling it a "list" implies you're expecting more than one result 
-- if you're not, you can simply use a C<NAME> or C<POSN> instead.)
The exception is that if the list runs into a problem (e.g. cannot find a legitimate starting point), it will return C<undef>.



=head2 Using up arguments

Every time an argument is found, C<Params::Clean> marks it as used.  
Used arguments are not checked again, regardless of whether they could match other parameters or not.

  side(left=>right);
  
  sub side
  {
    my ($dextrous, $sinister, @others) = args NAME left, FLAG left, REST;
    #===> right      undef      ()
    #"left" was not found as a FLAG because it was already used as a NAME
    
    # But...
    
    my ($sinister, $dextrous, @others) = args FLAG left, NAME left, REST;
    #===>   1        undef      right
    #now "left" was not found as a NAME because it was found first as a FLAG
  }

Note that the second case, the argument "C<right>" was found as a leftover (C<REST>), because it did not get collected by the other parameters.
Since the "C<left>" argument was found and used as a C<FLAG>, it was no longer available to be used as a C<NAME>, and so nothing happened to
the arg (C<right>) that it was meant to be a name for.  

It is possible to collect the same value more than once, however.  
This can happen when the parameter that C<args> is searching for has not been used yet, even though an arg that parameter points to already has.
For example, this next example gets the C<$fh> argument from all three parameters:

  #Assume that $fh is a filehandle, 
  # and &handle() returns true when it identifies a filehandle
  
  tend(Input=>$fh, Pipe "/dev/null");
  
  sub tend
  {
    my ($file, $input, $pipe)=args TYPE \&handle, NAME Input, LIST Pipe=[-1, 1];
    #===> $fh,  $fh,   [$fh, /dev/null]
  }

First, C<args> searches by type for any args that satisfy the C<handle()> function, so it grabs C<$fh> for the first parameter, C<$file>.
Next, C<args> looks for an argument identified by the name C<Input>; the first element of C<@_> is indeed "C<Input>", so it gets the following element of C<@_>.
(That second element has already been used to get the C<$file>, but the I<name> has not yet been used, so it still qualifies.  
Once the name has been found, the collected arg is always what comes immediately after it 
-- for example, C<args> will not grab the I<second> element after the name just because the first value after was already used.)
Finally, the relative list successfully identifies the C<Pipe> label, so it takes the preceding and succeeding elements of C<@_> (relative positions -1 and +1).
Again, once C<Pipe> is found, it does not matter whether the values identified by the positions have been used already or not.
(However, recall that for an absolute list, a used argument will stop processing the list, 
even if that means the list consists of nothing but the starting point.)


=head2 Care and C<Usage> of your module

You can simply C<use Params::Clean>, or you can supply some extra options to control warnings and exported names.
The options are a series of keys and values (so they must be correctly paired).

To change the name under which a keyword will be exported into your namespace, give its default name followed by
the name you wish to use for it in your calling module, e.g. if you already have a C<LIST> function, you can rename
C<Params::Clean>'s C<LIST> by including an option like C<< LIST=>PLIST >>.

You can also control how C<Params::Clean> will handle various kinds of errors.  Most exceptions simply emit a warning
message and try to continue.  You can set the level for recognised categories to "warn" to display a message; 
to "die" or "fatal" to display the message and die; or to "ignore" to do nothing.
Give the level of error-handling followed by the category name, e.g. C<< die=>missing_start >>.
See L<Diagnostics|"DIAGNOSTICS"> for the names of each category, and the default level.

Example:

	use Params::Clean  LIST=>"PLIST", NAME=>"Key",  fatal=>"misplaced_rest";

C<Params::Clean> will issue a warning for any unrecognised options that it encounters.  (You can C<< ignore=>invalid_opts >>,
but of course that will affect only subsequent options, not any that came before it.)



=head1 UIDs

Perl cannot tell a parameter name (or flag or list boundary) from any other argument passed to a subroutine.
If someone passes an arg with a value of "date" to your sub (e.g., C<< lunch(fruit=>"date", date=>"tomorrow") >>), 
and it is looking for a parameter called "date" (e.g., C<my ($when, $snack)=args 'date', 'fruit'>), 
it will match the first occurrence (e.g., C<$when> will find the first C<date> string and get as its value what comes next, which is the second C<date>)
-- unless you can be sure that there will be no confusion; 
for example, because that arg will be caught as one of the positional params and thus ignored by any subsequent FLAG or NAME or LIST parts of the process.

Of course, it is difficult to guarantee that no such confusion will arise; even if the values that could be ambiguous don't make sense,
you can't stop somebody from calling your function with nonsensical arguments!
What is possible, though, is to avoid using ordinary strings for parameters names (or flags, etc.).
The L<UID> module is useful in this respect: it creates unique identifier objects that cannot be duplicated accidentally.
(You can deliberately copy one, of course; but you cannot create separate UIDs that would match each other.)
Thus if you use UIDs for your parameter flags, you do not have to worry about your caller (accidentally!) passing a value that could be a false positive.

  use UID Stop;                  # create a unique ID
  way(Delimiter=>"Stop", Stop "Morningside Crescent");
  
  sub way
  {
    my ($tube, $telegram) = args Stop, Delimiter;
    #===>"Morningside Crescent", "Stop"
  }

When C<args> is looking for the parameter name C<Stop>, it will not find the plain string "Stop" 
-- only a UID object (in fact, the same UID object) will do.
Note also that a UID doesn't (usually) require a comma between it and the following value.

Of course, if you are exporting a function for other packages to use, you will probably want to export any UIDs that go along with it
(otherwise the UIDs will have to be fully-qualified to use them from another package, e.g., C<do_stuff(Some::Module::FOO $value)>).
The same considerations apply as for exporting any other subroutine 
-- allow the user control over what gets exported to avoid conflicts from different modules trying to export UIDs of the same name.

C<Params::Clean> exports UIDs for its identifiers (C<NAME, POSN, FLAG, TYPE, REST, LIST>) so that you can use them with the C<args> function in your subroutines.
(They can be renamed for importing into your namespace: see L<"Care and Usage of your module">).




=head1 DIAGNOSTICS

The list below includes the category of each exception, so that you can control how C<Params::Clean> handles that type
of exception, e.g. C<< warn=>foo >> means that any "foo" errors will issue a warning by default.
(See L<"Care and Usage of your module">).


=over 1

=item I<WARNING: Ignoring attempt to set unrecogised warning category>

=item I<WARNING: Ignoring unrecognised options>

B<C<< warn=>invalid_opts >>>

An option (pair) given in the C<use> statement is invalid, misspelled, or otherwise not recognised by C<Params::Clean>.
The unknown option will be skipped over.


=item I<ERROR: encountered PARSE after beginning of parameter list>

B<C<< fatal=>misplaced_parse >>>

When explcitly giving a list of arguments to parse, the C<PARSE> keyword must be the first thing passed to C<args>.
By default, C<Params::Clean> will die when it finds a C<PARSE> command out of place; 
if you set it to C<ignore> or C<warn>, the value passed in via C<PARSE> will be ignored
(and if you have set C<< warn=>misplaced_parse >>, you will get a "B<Ignoring misplaced PARSE values>" message).


=item I<WARNING: suspicious arg-list given to PARSE (a single unrecognised value)>

B<C<< ignore=>funny_arglist >>>

The value you pass in for an argument list using C<PARSE> should be an arrayref, or a hashref, or a coderef.
Anything else will trigger this warning, if you turn it on.


=item I<WARNING: attempt to use REST before last parameter>

B<C<< warn=>misplaced_rest >>>

The C<REST> keyword was not the last item passed to C<args>.  The leftover values are always returned after everything else,
so C<REST> should appear last to avoid confusion.


=item I<WHOA: can't use other LISTs inside a LIST!  Ignoring starting >[orI< ending>]I< param key: $key>

=item I<WHOA: can't use FLAGs or TYPEs inside a LIST!  Ignoring starting >[orI< ending>]I< param key: $key>

B<C<< warn=>invalid_list >>>

A C<LIST> can take only named or positional parameters as the starting (or ending) point.  
Something like C<< LIST [FLAG Foo] <=> [TYPE \&foo] >> will trigger a warning for either the starting or ending point (or both).
An invalid starting point means nothing will be returned for the list (C<undef>); 
an invalid ending point means that only the starting key will be returned; no other args will be collected.


=item I<ERROR: couldn't find beginning of LIST starting with '$key'>

=item I<ERROR: couldn't find ending of LIST from $start to $end>

B<C<< ignore=>missing_start >>>

B<C<< warn=>missing_end >>>

The starting or ending parameter specified for a LIST could not be found. 
If the given parameter does appear somewhere in C<@_>, the message will also say, I<"(probably already used up by another param!)">
(meaning a previously-collected arg already marked that parameter as "used" -- see L<"Using up arguments">).
If the starting point cannot be found, then nothing (C<undef>) is returned for the list (surprisingly enough).
If the ending point cannot be found, then everything else (not already collected) until the end of C<@_> will be grabbed by the list.
To deliberately allow a list to run off the end of C<@_>, make C<-1> (one of) the ending keys, or else do not specify an ending point at all.


=item I<WARNING: attempt to use invalid TYPE>

B<C<< warn=>invalid_type >>>

C<TYPE> parameters must be the name of a class (a C<ref> value), or a code-ref that can check each arg.
Trying to use anything else as a C<TYPE> (e.g. a plain number or string) will result in this error.


=item I<WARNING: non-integral number $param will be interpreted as a named parameter>

B<C<< warn=>nonint_name >>>

A number that's not an integer was found as a parameter key.  Since positional params must be integers,
the value will be interpreted as a C<NAME>d parameter.  To avoid the error, explicitly mark the key using the C<NAME> keyword.


=item I<WARNING: Orphaned TYPE>

B<C<< warn=>orphaned_type >>>

A C<TYPE> keyword was encountered without a following string or coderef, e.g., C<args 1,2, [TYPE];>.


=back



=head1 BUGS & OTHER ANNOYANCES

There are no known bugs at the moment.  (That's what they all say!) 
Please report any problems you may find, or any other feedback, to C<E<lt>bug-params-clean at rt.cpan.orgE<gt>>, 
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Clean>.


Using C<args>, variables are not right next to the parameter identifiers they are assigned from.
It probably helps to line up the variables and the call to C<args> if you have more than a few parameters,
so that you can see what matches up with what:

  my     ($foo,     $bar,     $baz)
    = args(foo, POSN -1,  FLAG on)


Defaults must be set in a separate step after parsing the parameters with C<args> (e.g., C<$foo||=$default;>).


C<@_> is aliased to the actual calling parameters, that is, changing C<@_> will change the original variables
passed to the function.  Variables assigned from a call to C<args> are of course copies rather than aliases.
C<@_> can be used directly, although if you're making the effort to use named parameters, you can require the 
caller to pass in references to the original variables where appropriate.


The special identifiers (C<NAME>, C<POSN>, etc.) are UID objects, and UID objects are really functions, 
so C<< NAME=>foo >> will not work; the C<< => >> auto-quotes the preceding bareword, even when the "bareword" is really meant to call a sub.
Fortunately, you can usually simply say C<NAME foo> instead.  See the documentation for C<L<UID>> for further details and caveats.


If a named parameter (or position) does not appear in the argument list, then C<args> will return C<undef> for it
-- just as if someone had explicitly specified a parameter with that name and passed it a value of C<undef>.
Thus there is no way to tell the difference between a deliberate value of C<undef> and a parameter that is simply missing altogether.
However, you could force an extra argument of that name into C<@_> before parsing it with C<args>;
if the parameter was missing altogether, your dummy value will be the only one returned;
if you get back multiple values, you know that others were explicitly passed for that parameter.


The examples given here use lots of barewords.  Omitting all those quotation marks makes them look cleaner,
but any real program, with C<use strict> and C<use warnings> in effect, will need to quote everything, 
even if it does add slightly to the clutter.  Judicious use of C<< => >> to quote the preceding word can help, as can defining L<UID>s.


C<LIST>s cannot identify starting (or ending) points by C<TYPE>.  They probably should be able to.


Additional or more helpful diagnostics would be nice.


Sometimes, trying to read C<@_> automatically seems not to work.  If this happens, the simple workaround is to explicitly
specify C<PARSE \@_> as the first thing passed to C<args>.  
(And if you know what makes Devel::Caller::Perl's C<called_args> function sometimes unable to read C<@_>, please let me know!)


To paraphrase L<Damian Conway|Getopt::Declare>: 
It shouldn't take hundreds and hundreds of lines to explain a package that was designed for intuitive ease of use!



=head1 RELATED MODULES

This module requires L<UID.pm|UID> and L<Devel::Caller::Perl>.

=for TODO: see also other modules?



=head1 METADATA

Copyright 2007-2008 David Green, C<< <plato at cpan.org> >>.  

This module is free software; you may redistribute it or modify it under the same terms as Perl itself. See L<perlartistic>. 

=cut



AYPWIP: "I think so, Brain, but I get all clammy inside the tent!"
