#!/usr/bin/perl  -w
# vim=:SetNumberAndWidth

=encoding utf-8

=head1 NAME
P  -   Safer, friendlier printf/print/sprintf + say

=head1 VERSION

Version  "1.1.41"

=cut

################################################################################
{ package P;
	use warnings; use strict;use mem;
	our $VERSION='1.1.41';

# RCS $Revision: 1.57 $ -  $Date: 2019-06-02 01:58:47-07 $
# 1.1.41	- Attempt to fix bug in Metacpan, that was reported fixed in
# 					Mar, 2013 (over 6 years ago), but seems to still be a problem
# 					It was suggested that Megacpan copy the working code from
# 					Cpan's search section as it worked correctly, but apparently
# 					that never happened.
# 1.1.40	- remove check for parent pid in test phase -- not important
#           and caused win platform to fail
# 1.1.39	- fix in carat encoding; had Single Quote (SQ) included in string
#						of chars to match for encoding resulting in SQ being converted
#						for carat encoding (print SQ though %s printed ^G )
# 1.1.38  - split declare + definition  in "local *fn=sub" to 
#           "local (*fn); *fn=sub"
#         - expand SCALAR refs even past limit as they don't take much space
#           and shouldn't cause more recursion
#         - moderate code cleanups
#         - handle 'undef' if 1st param passed:
#           - 1) if only parm, unshift in a format "%s", so undef will print
#           - 2) if 2nd parm looks like format, discard the null(ignore)
#         - OUTPUT CHANGE: if 1st char of a variable is a control character
#           then print it as carat(0x40+cc), so ctl-W, becomes ^W.
#         - remove unneeded reference to '@ISA' (Xporter doesn't need it)
#         - refactor module-default handling; have global default module
#           default and single-usage OO method to supply non-default params
# 1.1.37	- instead of trying to disable non-working tests in early perl's,
# 					require perl 5.8.5 and perlIO 1.0.3 to build;
# 				- only do win32 checks in P.Pt
# 1.1.36	- instead of disabling broken perl's, in a Major series, disable code
#           was set to diable all: fixed that (changes in P.Pt test).
# 1.1.35	- Add per-MAJOR-series min req'd. perl (else skip test)
# 1.1.34  - Compensating for odd Strawberry Perl var-values...
# 1.1.33  - Trying to Compensate for Strawberry Perl bugs...
# 1.1.32  - Change FAILS in 1.1.31 for bad env's to "skips"
# 1.1.31  - More pruning of bad test environments
# 1.1.30  - Attempt to prune unsupported OS's (WinXP)
# 1.1.29  - sprintf broken: include zero-width string spec to workaround
# 1.1.28	- testsuite fix - unknown failure case in sprintf:
#           "Redundant argument in sprintf "... for "return sprintf $fmt, $v";
#           Trying parens around sprintf($fmt, $v);
#           (shot in dark for strawberry win32 perl on win10...)
# 1.1.27	- test fix -- Makefile.PL improperly specified "test", rather
#           rather than using t/*.*t as pattern
# 1.1.26  - add code to allow changing defaults for literals and run-time 
#           constants previously only accessible through the OO method
#         - Allow setting defaults globally as well as per-package
#         - fix for bug in testcase 5 in "P.t" in some later versions
#           of Strawberry Perl (5.22, 5.20?).  Where the perlvar '$^X'
#           contained a win32-backslash-separated path to perl.  In double
#           quotes, the backslashes are removed as literalizing the next
#           character.  Changing the path usage to not have double-quotes
#           around the path should prevent the backslash-removal and pass
#           the literal string to the perl 'system' call.
# 1.1.25	- put initial POD w/VERSION @ top to keep version #'s together
# 				- remove BEGIN that was needed for running/passing tests
# 				  and instead use 'mem'
# 				- move changelog to column one and use vim markers to hide
# 				  older changes
# 				- add dflts hash to allow 'use' time change of defaults (W.I.P.)
# 				- split local define+assignment ~#283 due to side effects
# 1.1.24	- respin for another Makefile change  
# 1.1.23	- respin for a Makefile change
# 1.1.22	- respin to use alt version format 
# 1.1.21	- respin to have BUID_REQ include more modern Ext:MM
# 1.1.20	- respin to have Makefile rely on Xporter 1.0.6
# 1.1.19	- Prereqs not being loaded in Cpantesters; attempt fix
# 1.1.18  - Unreported bugfix:
# 					the words HASH & ARRAY were sometimes printed in ref notation
# 				- remove included 'Types' code to use Types::Core (now published)
# 1.1.17  - Documentation refinements/fixes;  Found possible culprit as to
#           why Windows native tests could fail -- my source files in 
#           lib have pointed back to my real lib dir via a symlink.
#           Windows wouldn't like those.  Why any other platform did is
#           likely some fluke of directory organization during test
# 1.1.16	- Different shot in dark to see if a change in P.env can make
# 					things work on Win-native
# 1.1.15	- Shot in dark to get 5.8.x to work(5.10 and newer seem to 
# 					be working!
# 1.1.14	- and write out buffer from editor! (arg!)
# 1.1.13	- get perl w/ ^X rather than config
# 1.1.12	- Found another potential problem in the test prog.
# 1.1.11	- May have found another test bug.... trying fix for some fails
# 1.1.10	- Another internal format error bug (unreported), but caught
# 					in testing.
# 1.1.9		- Try to fix paths for test
# 1.1.8		- use ptar to generate Archive::tar compat archives
# 1.1.7		- Fix Makefile.PL
# 1.1.6		- Use t/P.env for premodifying  ENV
# 					Document effect of printing to a FH & recording return val;
# 1.1.5		- Distribution change: use --format=v7 on tar to produce tarball
# 					(rt#90165)
# 				- Use shell script to preset env for test since 
# 				  Test::More doesn't set ENV 
# 1.1.4		- Quick patch to enable use of state w/CORE::state
# 1.1.3		- [#$@%&!!!]
# 1.1.2		- Second try for test in P.t to get prereq's right
# 1.1.1   - Fix rest of (rt#89050)
# 1.1.0		- Fixed Internal bug#001, below & embedded \n@end of int. str
# 					(rt#89064)
# Version history continued...					#{{{
# 1.0.32	- Fix double nest test case @{[\*STDERR, ["fmt:%s", "string"]]}
# 					(rt#89056)
# 					only use sprintf's numeric formats (e.g. %d, %f...) on
# 					numbers supported by sprintf (for now only arabic numerals).
# 					Otherwise print as string. (rt#89063)
# 					its numeric formats (ex "%d", "%f"...)
# 1.0.31	- Fix check for previously printed items to apply only to
# 				- the current output statement;
# 1.0.30  - Fix LF suppression -- instead of suppressing EOL, suppressed
# 					all output in the case where no FD was specified (code was
# 					confused in deciding whether or not to suppress output and 
# 					return it as a string. (rt#89058)
# 				- Add missing quote in Synopsis (rt#89047)
# 				- Change NAME section to reference module following CPAN
# 				  standard to re-list name of module instead of functions
# 				  (rt#89046)
# 				- Fix L<> in POD that referenced "module" P::P instead of name, "P"
# 				  (forms bad link in HTML) (rt#89051)
# 				- Since ($;@) prototypes cause more problems than (@), clean p
# 				  proto's to use '@'; impliciation->remove array variations
# 				  (rt@89052, #89055) (rt#89058)
# 				- fix outdated and inconsistent doc examples regarding old protos
#						(rt#89056)(rt#89058)
#						Had broken P's object oriented flag passing in adding 
#						the 'seen' function (to prevent recursive outptut.  Fixed this
#						while testing that main::DATA is properly closed (rt#89057,#89067)
#					- Internal Bug #001
#							#our @a = ("Hello %s", "World");
#							#P(\*STDERR, \@a);       
#							#		prints-> ARRAY(0x1003b40)
# 1.0.29	- Convert to using 'There does not exist' sign (∄), U+2204
# 					instead of (undef);  use  '🔁 ' for recursion/repeat;
# 					U+1F500
# 1.0.28	- When doing explicit out (FH specified), be sure to end
# 					with newln. 
# 1.0.27  - DEFAULT change - don't do implicit IO reads (change via 
# 						impicit_io option)
#           - not usually needed in debugging or most output;
#           could cause problems
#           reading data from a file and causing desychronization problems; 
# 1.0.26	- detect recursive data structs and don't expand them
# 1.0.25	- Add expansion for 'REF'; 
# 				- WIP: Trying to incorporate enumeration of duplicate adjacent 
# 					data: Work In Progress: status: disabled
# 1.0.24	- limit default max string expanded to 140 chars (maybe want to
# 					do this only in brace expansions?)  Method to change in OOO
# 					not documented at this time. NOTE: limiting output by default
# 					is not a great idea.
# 1.0.23	- When printing contents of a hash, print non-refs before 
# 					refs, and print each subset in alpha sorted order
# 1.0.22  - Switch to {…} instead of HASH(0x12356892) or 
# 										[…] for arrays
# 1.0.21  - Doc change: added example of use in "die".
# 1.0.20	- Rewrite of testcase 5 in self-execution; no external progs
#           anymore: use fork and print from P in perl child, then
#           print from FH in parent, including uses of \x83 to
#           inhibit extra LF's;
# 1.0.19  - Regretting fancy thru 'rev' P direct from FH test case (a bit)
#           **seems** like some people don't have "." in path for test 
#           cases, so running "t/prog" doesn't work, trying "./t/prog"
#           (1 fail on a Win32 base on a x64 system...so tempted
#           to just ignore it...) >;^); guess will up this for now
#           and think about that test case some more...
#           I'm so gonna rewrite that case! (see xtodox below)
# 1.0.18  - convert top format-case statement to load-time compile
#           and see if that helps BSD errors;
#         - change test case w/array to use P & not old Pa-form
#         - change test case to print to STDERR to use Pe
#         - fix bug in decrement of $lvl in conditional (decrement must
#           be in first part of conditional)
#         - xtodox fix adaptation of 'rev' test case to work w/o 
#           separate file(done)
# 1.0.17  - another try at fixing pod decoding on metacpan
# 1.0.16  - pod '=encoding' move to before '=head' 
#           (ref:https://github.com/CPAN-API/metacpan-web/issues/800 )
# 1.0.15  - remove 'my $_' usage; old perl compat probs; use local
#           in once instance were needed local copy of $_
# 1.0.14  - arg! misspelled Win nul: devname(fixed)
# 1.0.13  - test case change only to better test print to STDERR
# 1.0.12  - test case change: change of OBJ->print to print OBJ to
#           try to get around problem on BSD5.12 in P.pm (worked!)
#         - change embedded test case to not use util 'rev', but
#           included perl script 'rev' in 't' directory...(for native win)
# 1.0.11	- revert printing decimals using %d: dropped significant leading
#           zero's;  Of NOTE: floating point output in objects is
#           not default: we use ".2f"
#         - left off space after comma in arrays(fixed)
#         - rewrite of sections using given/when/default to not use
#           them; try for 5.8 compat
#         - call perl for invoking test vs. relying on #! invokation
#         - pod updates mentioning 'ops'/depth
# 1.0.10	- remove Carp::Always from test (wasn't needed and caused it
#           to fail on most test systems)
#           add OO-oriented way to set internal P ops (to be documented)
#         - fixed bug in logic trimming recursion depth on objects
# 1.0.9 	- Add Px - recursive object print in squished form;
#       		Default to using Px for normal print
# 1.0.8 	- fix when ref to IO -- wasn't dereferenced properly
#       	- upgrade of self-test/demo to allow specifying which test
#       	  to run from cmd line; test numbers are taken from
#       	  the displayed examples when run w/no arguments
#       	B:still doesn't run cleanly under test harness may need to
#       	  change cases for that (Fixed)
#       	- POD update to current code 
# 1.0.7 	- (2013-1-9) add support for printing blessed objects
#       	- pod corrections
#       	- strip added LF from 'rev' example with tr (looks wrong)
# 1.0.6 	- add manual check for LF at end (chomp doesn't always work)
# 1.0.5 	- if don't recognize ref type, print var
# 1.0.4 	- added support for printing contents of arrays and hashes.
# 					(tnx 2 MidLifeXis@prlmnks 4 brain reset)
# 1.0.3 	- add Pea
# 1.0.2 	- found 0x83 = "no break here" -- use that for NL suppress
# 				- added support for easy inclusion in other files 
# 					(not just as lib);
# 				- add ISA and EXPORT to 'mem' so they are available @ BEGIN time
#
# 1.0.1 	- add 0xa0 (non breaking space) to suppress NL
#						#}}}

	use utf8;
	{ no warnings "once"; *IO::Handle::P = \&P::P }
		
	use Types::Core qw(blessed);

	our @EXPORT;
	use mem(@EXPORT=qw(P Pe));
	use Xporter;

	my $ignore=<<'IGN'									#{{{
	BEGIN {
		use constant EXPERIMENTAL=>0;
		if (EXPERIMENTAL) {				
			sub rm_adjacent {
				my $c = 1;
				($a, $c) = @$a if ref $a;
				$b //= "∄";
				if ($a ne $b) { $c > 1 ? "$a × $c" : $a , $b } 
				else { (undef, [$a, ++$c]) }
			}
			sub reduce(&\[@$]) { my $f = shift;
				my (@final, $i)		= ((), 0);
				my ($cnt, $term) = (0, undef);
				my ($parms, $rv);
				if (@_ < 2 && ARRAY $_[0] ? $_[0] : \@_;
				$parms = q(ARRAY) eq 
				$rv = 

				while (@_ >= 2) {
					my $res = $f->($_[0], $_[1])) {
					if ($f->($_[0], $_[1])) {
						if ($cnt == 0) {
							$term = $_[0];
							++$cnt;
						} else { ++$cnt};
					} else {
						if ($cnt) {
							push @final, "\"$term\" × $cnt";
							($cnt, $term) = (undef, 0);
						}
					}
					shift;
				}
				@final

				for (my $i=0; $i < (@$ar-1); ++$i ) {
					my ($x, $y) = ($ar->[$i], $ar->[$i+1]);
					my @r = &$f($ar->[$i], $ar->[$i+1]);
					push @final, $r[0] if $r[0];
					$ar->[$i+1] = $r[1];
				}
				@final;
			}
		} 
	}												
IGN
	||undef;															#}}}

	

	use constant NoBrHr => 0x83;					# Unicode codepoint="No Break Here"
	our	%_dflts;
	our (%mod_dflts, %types);
	BEGIN {
		%_dflts=(
			depth						=> 3, 
			ellipsis				=> '…', 
			expand_duprefs	=> 0,
			implicit_io			=> 0,
			maxstring				=> undef,
			noquote					=> 1, 
			seen						=> '🔁',		# 🔁
			undef						=> '∄',
		);

		my $bool	 = sub { $_[0] ? 1 : 0 };
		my $intnum = sub { $_[0] =~ m{^([0-9]+)$} ? 0 + $1 : 0 };
		my $string = sub { length($_[0]) ? "$_[0]"  : '' };
		my $true	 = sub { 1 };

		%types=(
			default					=> $true,
			depth						=> $intnum, 
			ellipsis				=> $string,
			expand_duprefs	=> $bool,
			implicit_io			=> $bool,
			maxstring				=> $intnum,
			noquote					=> $bool,
			seen						=> $string,
			undef						=> $string,
		);

		#global default copy
		$mod_dflts{""}	= \%_dflts;
	}


	use constant cc => '\x00-\x1f'; 			## cc = caret class

	sub vrfmt($) {
		my ($v, $pkg)		= (shift || "", "");
		#my ($vl, $ic)		= (length $v, 2+index $v, "::");
		#if ($ic >= 2  &&  $vl - $ic > 0) {
		#	$pkg	= substr $v, 0, $ic;
		#	$v 		= substr $v, $ic;
		#}																						# here, 'v' is a var name
		#if ( $v =~ m{^([\x00-\x1f])(\w*)$} ) {				# varname starting w/ctl-ch
		#	$v = "^" . chr(0x40 + ord $1) . $2;					# use carot encoding
		#}
		$pkg . $v;
	}

################################################################################


	sub sw(*):lvalue;
# sub sw_decr(*);

	sub _Px($$;$) { my ($p, $v) = (shift, shift);
		local (*sw); *sw = sub (*):lvalue {
  		defined($p->{$_[0]}) 
              ?  $p->{$_[0]}
              : ($p->{$_[0]} = $mod_dflts{""}->{$_[0]});
		};
#    local (*sw_decr); *sw_decr = sub(*) { my $res;
#      0 >= ($res = sw($_[0])) and return $res;
#      --sw($_[0]); $res };

		unless (sw(expand_duprefs)) {
			if (ref $v && ! SCALAR $v) {
				if ($p->{__P_seen}{$v}) { return "*". sw(seen) . ":" . $v . "*" }
				else { $p->{__P_seen}{$v} = 1 }
			}
		}
		my ($nargs, $lvl, $ro) = (scalar @_, 2, 0);
		if ($nargs) {
			$lvl = $_[0];
			if ($nargs>1) { $ro = $_[1] }
		}
		return sw('undef') unless defined $v;
		my $rv = ref $v;
		if (1 > $lvl-- || !$rv) {													# LAST level actions:
			my $fmt;			# prototypes are documentary (rt#89053)
			my $given = [	
				sub ($$) { $_[0] =~ /^[-+]?[0-9]+\.?\z/						&& 	q{%s}		},
				#sub ($$) { $_[1] && ($_[0] = vrfmt($_[0])), $_[1]	&& qq{%s}		},
				sub ($$) { $_[1] 												 					&& qq{%s}		},
				sub ($$) { 1 == length($_[0]) 										&& q{'%s'}	},
				sub ($$) { $_[0] =~ m{^(?:[+-]?(?:\.\d+)
															|(?:\d+\.\d+))\z}x  				&& q{%.2f}	},
				sub ($$) { substr($_[0],0,5) eq 'HASH('						&& 
																	'{'. sw(q(ellipsis)) .'}' . q{%.0s}	},
				sub ($$) { substr($_[0],0,6) eq 'ARRAY('					&& 
																	'['. sw(q(ellipsis)) .']' . q{%.0s}	},
				sub ($$) { substr($_[0],0,7) eq 'SCALAR('					&& 
																do {'\\' . $p->_Px(${$_[0]}, $lvl) .' ' } },
				#	sub ($$) { $mxstr && length ($_[0])>$mxstr 			&& qq("%.${mxstr}s")},
				sub ($$) { ref $_[0]															&& q{%s}	}, 
				sub ($$) { 1																			&& q{"%s"}	},
			];

			do { $fmt = $_->($v, $ro) and last } for @$given;
			return sprintf($fmt, $v);
		} else { 
			my $pkg = '';

			($pkg, $rv) = ($1, $2) if 0 <= (index $v, '=') && 
																$v =~ m{([\w:]+)=([cc\w][\w:]+)}; 

			local * nonrefs_b4_refs ; * nonrefs_b4_refs = sub {
				ref $v->{$a} cmp ref $v->{$b}  || $a cmp $b 
			};

			local (*IO_glob, *NIO_glob, *IO_io, *NIO_io);
			(*IO_glob, *NIO_glob, *IO_io, *NIO_io) = (
						sub(){'<*'.<$v>.'>'}, sub(){'<*='.$p->_Px($v, $lvl-1).'>'},
						sub(){'<='.<$v>.'>'}, sub(){'<|'.$p->_Px($v, $lvl-1).'|>'},
					);
			no strict 'refs';
			my %actions = ( 
				GLOB	=>	($p->{implicit_io}? *IO_glob: *NIO_glob),
				IO		=>	($p->{implicit_io}? *IO_io	 : *NIO_io),
				REF		=>	sub(){ "\\" . $p->_Px($$_, $lvl-1) . ' '},
				SCALAR=>	sub(){ $pkg.'\\' . $p->_Px($$_, $lvl).' ' },
				ARRAY	=>	sub(){ $pkg."[". 
												(join ', ', 
#	not working: why?			#reduce \&rm_adjacent, (commented out)
												map{ $p->_Px($_, $lvl) } @$v ) ."]" },
				HASH	=>	sub(){ $pkg.'{' . ( join ', ', @{[
										map {	$p->_Px($_, $lvl, 1) . '=>'. 
													$p->_Px($v->{$_}, $lvl,0) } 
										sort  nonrefs_b4_refs keys %$v]} ) . '}' },
			);
			if (my $act=$actions{$rv}) { &$act } 
			else { return "$v" }
		}
	}

	sub _init_p($) { my $p; my $caller	= $_[0];
		croak P "FATAL: P::_init_p called with wrong# args (%s)", 0+@_
						unless (@_ == 1);
		if (blessed $mod_dflts{$caller}) {			# blessed caller already stored
			$p = $mod_dflts{$caller};
		} elsif (HASH $mod_dflts{$caller}) {		# have hash, so bless it
			bless $p = $mod_dflts{$caller};
		} else {
			bless $p = $mod_dflts{$caller} = {};	# init caller's flag hash
		}
		$p;
	}

	
	sub P(@) {
		my $undef_cnt=0;
		if (!defined($_[0])) {
			my $fmt = ("%s, " x (@_-1))."%s";
			unshift @_, $fmt;
		}

		my $p = ref $_[0] eq 'P' ? shift : _init_p(caller);

		local (*sw); *sw = sub (*):lvalue {
  		defined($p->{$_[0]}) 
              ?  $p->{$_[0]}
              : ($p->{$_[0]} = $mod_dflts{""}->{$_[0]});
		};

		$p->{__P_seen} = {} unless ref $p->{__P_seen};

		local * unsee_ret  = sub ($) { 
			delete $p->{__P_seen} if exists $p->{__P_seen}; 
			$_[0] };

		my $v = $_[0];
    my $rv = ref $v;
		my ($depth, $noquote) = (sw(depth), sw(noquote));

    if (HASH eq $rv) {
			my $params = $v; $v = shift; $rv = ref $v;
			$depth = $params->{depth} if exists $params->{depth};
    }
    if (ARRAY eq $rv ) { $v = shift;
      @_ = (@$v, @_); $v = $_[0]; $rv = ref $v }

		my ($fh, $explicit_out);
		if ($rv eq GLOB || $rv eq IO) {
			($fh, $explicit_out) = (shift, 1);
			$v = $_[0]; $rv = ref $v;
		} else { $fh =\*STDOUT }
    
		if (ARRAY eq $rv ) { $v = shift;
      @_=(@$v, @_); $v=$_[0]; $rv = ref $v }
    
		my $fmt = shift;
		my $res = do {
			no warnings;
			sprintf $fmt,	
			map {local $_ = $p->_Px($_, $depth, $noquote) } @_ 
		};

		chomp $res;
	
		my ($nl, $ctx) = ("\n", defined wantarray ? 1 : 0);
	
#		our $Pcount;
#		sub Pe(@);
#		if (!$Pcount) {
#			++$Pcount;
#			my $from = caller ;
#			#Pe "cts=%s, from=%s", $ctx, $from;
#			$ctx=0 if $from =~ /^DB/;
#		}
		


		($res, $nl, $ctx) = (substr($res, 0, -1 + length $res), "", 2) if
					ord(substr $res,-1) == NoBrHr;									#"NO_BREAK_HERE"

		if (!$fh && !$ctx) {	#internal consistancy check
			($fh = \*STDERR) and 
				P $fh "Invalid File Handle presented for output, using STDERR";
			($explicit_out, $nl) = (1, "\n") }

		else { return unsee_ret($res) if (!$explicit_out and $ctx == 1) }

		no warnings 'utf8';
		print $fh ($res . (!$ctx && (!$\ || $\ ne "\n") ? "\n" : "")  );
		unsee_ret($res);
	}


	sub Pe(@) {
		my $p = ref $_[0] eq 'P' ? shift : _init_p(caller);
		unshift @_, \*STDERR;
		unshift @_, $p if ref $p;
		goto &P 
	}


	sub import { my $p = ref $_[0] eq 'P' ? $_[0] : _init_p(caller);
		my ($modname, @args) = @_;
		goto &Xporter::import if caller eq 'P';
		if (@args) {
			my @others;
			my $default = 0;
			my $got_default = 0;
			my $save_p	= [];
			my @tags = grep { 
					my $full_switch;				# has tag+args, but no colon
					if (0 == index $_, ':') {
						$_						= substr $_, 1;
						$full_switch	= $_;		# includes any '=' fields
						my ($l, $tag, $val) = (-1, $_);
						if (($l = index $_, '=') > 0) {
							$tag = substr $_, 0, $l;
							$val = substr $_, $l+1;
						}
						if ($tag eq 'default' && !$got_default) {	#can only have 1 dflt sec.
							$default = 1;
							push @$save_p, $p;
							$p = $mod_dflts{""};
						} elsif ($tag eq '--') {	#end of dflts (:--)
							$p = pop @$save_p;
							$default			= 0;
							$got_default	= 1;
						} else {
							warnings::warn P "Unrecognized flag: %s", $tag unless
								exists $mod_dflts{""}->{$tag};
							$p->{"$tag"} = defined("$val") ? "$val" : -1;
						}
					} else {
						push @others, $_;
					}
			} @args;
			@_=($modname, @others);
		}
		goto &Xporter::import;
	}




	sub ops($) { my $p = shift; my $c = ref $p || $p;
		bless $p = {};
		use Carp qw(croak);
		my $caller	= (caller)[0];
		my	$args = $_[0];
		croak "ops takes a hash to pass arguments" unless HASH $args;
		foreach (sort keys %$args) {
			if (defined $_dflts{$_}) { $p->{$_} = $args->{$_} } 
			else { 
				warn  "Unknown key \"$_\" passed to ops";} 
		}
		$p
 	}
1}

{
	package main;
	use utf8;

	unless ((caller 0)[0]) {
		binmode P::DATA, ":utf8";
		binmode *STDOUT, ":utf8";
		binmode *STDERR, ":utf8";
    $_=do{ $/=undef, <P::DATA>};
		close P::DATA;
		our @globals;
		eval $_;
    die "self-test failed: $@" if $@;
		1;
	} else {
		close P::DATA;
	}
1;
}
###########################################################################
#							Pod documentation						{{{1
#    use P;

=head1 SYNOPSIS

  use P qw[:depth=5 :undef="(undef)"];

  P FILEHANDLE FORMAT, LIST
  P FILEHANDLE, LIST         # comma is not disallowed
  P FORMAT, (LIST)
  P (LIST)
  P @ARRAY                   # may contain File Handle, Format and ARGS
	                           # all in 1 array.
  $s = P @ARRAY; P $s;       # can be same output as "P @ARRAY" 
  Pe                         # same as P STDERR,...
  $s = P FILEHANDLE ...      # sends same output to $s and FILEHANDLE

=head1 DESCRIPTION

C<P> is a combined print, printf, sprintf & say in 1 routine.  It saves
tremendously on development time.  It's not just a 1 character 'verb', 
but has other time-saving and powerful features.  It has the convenience
of C<say> in adding a newline when needed but also allows specifying
a File Handle and format statement.
C<P> accepts a filehandle with or without a comma after the filehandle.

=over

=item  o B<No more switching between print, printf, sprintf, and say.>

=back

A fixed string can be changed to formatted output with no change of
verb:

 Example: 
     # Starting with a "die" statement.
  1) die "Wrong number of params";
    # Then number of arguments passed is added:
  2) die P "Expecting 2 params, got %s", scalar @ARGV;
    # Then contents of @ARGV can be printed as well (no loop needed):
  3) die P "Expecting 2 params, got %s (ARGV=%s), 0+@ARGV, \@ARGV;


C<P> can replacing C<sprintf> without the need for a temporary
variable and without printing cryptic representations for @ARGV,
like "C<ARRAY(0x5A2B3C66)>".  Instead,
C<P> displays the actual contents of the array, showing
["arg1", "arg2"].


=over

=item B<· Auto-Newline Handling>

=back

When it comes to C<newline>'s, or "\n" at the end of line, C<P> 
attempts to look at context.  If output is assigned to a variable,
then C<P> acts like C<sprintf>.  If it is to a file handle, then
it will act like C<say> and automatically append a C<newline>.
Unlike C<say>, C<P> can use formatted output and print to a file
handle.  Printing to STDERR is simplified with the C<Pe> form of
C<P>, which is a short form of 'P STDERR, "..."'.

When C<P> prints to strings, any one newline at the end of the 
string will be suppressed.  Conversely it will add one if
printing to a device.  If printing to a string and a device
at the same time, it will favor suppression and not output
a newline to the device.

=over

=item B<· Trapping C<undef>>

=back

Rather than aborting output when C<undef> is part of the output, 
C<P> prints a configurable symbol, '∄', by default, the symbol
for "does not exist" where the undef would have printed and the 
rest of the string is printed normally.

=over

=item B<· Less restrictive syntax>

=back

C<P> tries not to have arbitrary restrictions on it's arguments.

It handles cases that the equivalent perl statement won't.



              VERB ->           P    print   printf  sprintf   say
          V --FEATURE-- V      ---   -----   ------  -------   ---
      1) to a FH               Yes    Yes     Yes       No     Yes
      2) to $fh                Yes    Yes     Yes       No      No
      3) to a string           Yes     No      No      Yes      No 
      4) add EOL-NL to FH?     Yes     No      No       No     Yes
      5) sub EOL-NL in string  Yes     No      No       No      No
      6) FMT                   Yes     No     Yes      Yes      No
      7) @[FMT,ARGS]           Yes     No     Yes       No      No
      8) undef to "%s"         Yes     No      No       No      No
      9) @[$fh,FMT,ARGS]       Yes     No      No       No      No
     10) like "tee"            Yes     No      No       No      No

   (9) - File Handle in 1st member of ARRAY used for output.

  (10) - When P is being used as a string formatter like sprintf,
         it can still have a "$fh" as the first argument that will 
         print the formatted string to the file handle as well as 
         returning it's value (note: this will force the string
         to be printed w/o a trailing newline).




=head3 Undefs


When printed as strings (C<"%s">), undefs are automatically caught and 
"E<0x2204>", (U+2204 - meaning "I<There does not exist>") is
printed in place of "C<Use of uninitialized value $x in xxx at -e line z.>"

By default C<P>, prints the content of references (instead HASH 
(or ARRAY)=(0x12345678).  By default, it prints three levels deep with
deeper nesting replaced by by the unicode ellipsis character (U+2026).

While designed for development use, it is useful in many more situations, as 
tries to "do the right thing" based on context.  It can usually be used
as a drop-in replacement the perl functions C<print>, C<printf>, C<sprintf>,
and, C<say>.  

P tries to smartly handle newlines at the end of the line -- adding them 
or subtracting them based on if they are going to a file handle or to another
variable.

The newline handling at the end of a line can be supressed by adding
the Unicode control char "Don't break here" (0x83) at the end of a string
or by assigning the return value B<and> having a file handle as the first
argument.  Ex: C<my $fmt = P STDOUT, "no LF added here--E<gt>">.


C<Bless>ed objects, by default, are printed with the class or package name
in front of the reference. Note that these substitutions are performed only with 
references printed through a string (C<"%s">) format -- features designed
to give useful output in development or debug situations.

One difference between C<P> and C<sprintf>: C<P> can take 
an array with the format in the 0th element, and parameters following.  
C<Sprintf> will cause an error to be raised, if you try passing an array
to it, as it will force the array into scalar context -- which as 
the manpage says "is almost never useful", and the perl-developers
admit "is never useful".  Rather than follow in the
design flaws of its predecessors, P I<tries> to do the right thing.


B<NOTE:> A side effect of P being a contextual replacement for sprintf,
is if it is used as the last line of a subroutine.  By default, this
won't print it's arguments to STDOUT unless you explicity specify the
filehandle, as it will think it is supposed to return the result -- not
print it.  An alternate workaround -- return another value, like a
status value.  OR use it as a feature.  A subroutine that has 
a C<P-statment> at the end can be used in string construction or
can be used for direct output.

=head1 EXAMPLE: Duel-Use Subroutines for Strings or Printing


   sub items_in_list() {
	    my $numitems = get_num();
			P "num items=%s", $numitems;
   }   # can be used:

	 my $s=items_in_list();
	 # or
	 $items_in_list();	# prints to STDOUT w/newline on end





=head2 Special Use Features


While C<P> is normally called procedurally, and not as an object, there are 
some rare cases where one would really like it to print "just 1 level
deeper".  To do that, you need to get a pointer to C<P>'s C<options>. 

To get that pointer, call C<P::-E<gt>ops({key=>value})> to set C<P>'s options and
save the return value.  Use that pointer to call P.  See following example.

=head1 EXAMPLE: (changing P's defaults)

Suppose you had an array of objects, and you wanted to see the contents
of the objects in the array.  Normally P would only print the first two levels:


  my %complex_probs = (                                
      questions =E<gt> [ "sqrt(-4)",  "(1-i)**2"     ],
      answers   =E<gt> [ {real => 0, i =>2 }, 
                     {real => 0, i => -2 } ] );
  my $prob_ref = \%complex_problems;
  P "my probs = %s", [$prob_ref];


The above would normally produce:

  my probs = [{answers=>[{…}, {…}], questions=>["sqrt(-4)", "(1-i)**2"]}]


Instead of the contents of the hashes, P shows the ellipses (a
1 char-width wide character) for the interior of the hashes.  If you
wanted the interior to print, you'd need to raise the default data
expansion I<depth> for C<P> as we do here:


  my %complex_probs = (                                     
      questions => [ "sqrt(-4)",          "(1-i)**2"     ],
      answers   => [ {real => 0, i =>2 }, { real => 0, i => -2 } ] );
  my $p=P::->ops({depth=>4});                                
  $p->P("my array = %s", \%complex_probs);


The above allows 1 extra level of depth to be printed, so the elements in the
hash are displayed producing: 

  my probs = [{answers=>[{i=>2, real=>0}, {i=>-2, real=>0}],  # extra "\n" 
               questions=>["sqrt(-4)", "(1-i)**2"]}]


B<NOTE:>  when referring to the B<package> B<C<P>>, a double colon is usually
needed to tell perl you are not talking about the function name.

Please don't expect data printed by P to be "pretty" or parseable.  It's not
meant to be a Perl::Tidy or Data::Dumper.  I<Especially>, when printing
references, it was designed as a development aid.



=head2 Summary of possible OO args to "ops" (and defaults)

=over

=item C<depth =E<gt> 3>

=over

Allows setting depth of nested structure printing.  NOTE: regardless of depth,
recursive structures in the same call to C<P>, will not expand but be displayed
in an abbreviated form.

=back

=item C<implicit_io =E<gt> 0>

=over

When printing references, GLOBS and IO refs do not have their
contents printed (since printing contents of such refs may do I/O that 
changes the object's state).  If this is wanted, one would call C<ops> with C<implicit_io> set to true (1).

=back

=item C<noquote =E<gt> 1>

=over

In printing items in hashes or arrays, data that are Read-Only or do not need
quoting won't have quoting (contrast to Data::Dumper, where it can be turned
off or on, but not turned on, only when needed).

=back

=item C<maxstring =E<gt> undef>

=over 2

Allows specifying a maximum length of any single datum when expanded from an indirection expansion.

=back

=back

=head2 Example 2: Not worrying about "undefs"

Looking at some old code of mine, I found this:

  print sprintf STDERR,
    "Error: in parsing (%s), proto=%s, host=%s, page=%s\n",
    $_[0] // "null", $proto // "null", $host // "null",
    $path // "null";
  die "Exiting due to error."

Too many words and effort in upgrading a die message! Now it looks like:

  die P "Error: in parsing (%s), proto=%s, host=%s, page=%s",
          $_[0], $proto, $host, $path;

It's not just about formatting or replacing sprintf -- but automatically
giving you sanity in places like error messages and debug output when
the variables you are printing may be 'undef' -- which would abort the
output entirely!



=head1 MORE EXAMPLES


 P "Hello %s", "World";            # auto NL when to a FH
 P "Hello \x83"; P "World";        # \x83: suppress auto-NL to FH's 
 $s = P "%s", "Hello %s";          # not needed if printing to string 
 P $s, "World";                    # still prints "Hello World" 

 @a = ("Hello %s", "World");       # using array, fmt as 1st arg 
 P @a;                             # print "Hello World"
 P 0 + @a;                         # prints #items in '@a': 2

 P "a=%s", \@a;                    # prints contents of 'a': [1,2,3...]

 P STDERR @a                       # use @a as args to a specific FH
                                   # Uses indirect method calls when
                                   # invoked like "print FH ARGS"
                                   #
 Pe  "Output to STDERR"            # 'Shortcut' for P to STDERR

 %H=(one=>1, two=>2, u=>undef);    # P Hash bucket usage + contents:

 P "%H hash usage: %s", "".%H;     # Shows used/total Hash bucket usage
 P "%H=%s", \%H;                   # print contents of hash:

   %H={u=>(undef), one=>1, two=>2}

 bless my $h=\%H, 'Hclass';        # Blessed objects...
 P "Obj_h = %s", $h;               #   & content:

   Obj_h = Hclass{u=>(undef), one=>1, two=>2}


=head1 Sample Code + Test + Demo

To demonstrate the various usages of P, several examples are embedded
with this documenation in a special C<DATA> section.  If this module
is executed as with C<perl P.pm> or just C<P.pm> if the module is
set to be executable, it will run a short program that shows
different features of P as well as doing a short run-time test 
(that is actually part of the test suite).

The demo/example/test code embedded in this module is NOT compiled or
accessed when it is C<use>ed in code.

As of this writing there are 13 examples.  The output of these 
examples follows:

=over 

   #1  (ret from func)          : Hello Perl 1
   #2  (w/string)               : Hello Perl 2
   #3  (passed array)           : Hello Perl 3
   #4  (w/fmt+string)           : Hello Perl 4
   #5  (to STDERR)              : Hello Perl 5
   #6  (to strng embedded in #7): 
   #7  (prev string)            : prev str="Hello Perl 6" (no LF) && Hello Perl 7
   #8  (P && array ref)         : ["one", "two", "three", 4, 5, 6]
   #9  (P HASH ref)             : {a=>"apple", b=>"bread", c=>"cherry"}
   #10 (P Pkg ref)              : Pkg{a=>1, b=>2, x=>'y'}
   #11 (P @{[FH,["fmt:%s",…]]}) : fmt:Hello Perl 11
   #12 (truncate embedded float): norm=3.14159265358979324, embed={pi=>3.14}
   #13 (test mixed digit string): embed roman pi = ["3.ⅰⅳⅰⅴⅸ"]

=back

The code uses a function C<iter> that prints I<Hello Perl> followed by
an autoincrementing counter that also is used as the test or example
number. 

Putting the format + its arguments in an array is simple and does not
change if P is printing to output or to a string (cf. sprintf/printf).
P goes further than allowing the format specification in an array -- it
also allows putting the file handle as the 1st element in the array as
shown in #11.

P is not picky about how file handles can be used -- they can be
followed by a space or by a comma.  No special syntax is needed for the
arguments of P, it can follow the example of printf or the standard
usage of using commas to separate arguments.


=head1 NOTES

Values given as args with a format statement, are checked for B<undef>
and have "E<0x2204>" substituted for undefined values.  If you print
vars as in decimal or floating point, they'll likely show up as 0, which
doesn't stand out as well.

Sometimes the perl parser gets confused about what args belong to P and
which do not.  Using parentheses (I<ex.> C<P("Hello World")>) can help
in those cases.

Usable in any code, P was was designed to save typing, time and work of
undef checking, newline handling, peeking at data structures in small
spaces during development.  It tries to do the "right thing" with the
given input. It may not be suitable where speed is paramount.

=cut


#}}}1

package P;
__DATA__
# line ' .__LINE__ . ' "' ' __FILE__ . "\"\n" . '
use utf8;
use open IN => q(:utf8);
use open OUT => q(:utf8);
foreach (qw{STDERR STDOUT}) {select *$_; $|=1};
use strict; use warnings; 
use P;
my %tests;
my $MAXCASES=13;
{ my $i=1;
  foreach (@ARGV) {
    if (/^\d+/ && $_<=$MAXCASES) {$tests{$_}=1}
    else {die P "%s: no such test case", $_}
  }
}
exists $tests{7} and $tests{6}=1;

my $format="#%-2d %-25s: ";
{	#mini-package
  my $case=0;
  sub newcase() {++$case}
  sub caseno() {$case};
  sub iter(){"Hello Perl ${\(0+&caseno)}"}
}

sub case ($) {
  &newcase;
  if (!@ARGV || $tests{&caseno}) {
	  P ("$format\x83",  &caseno, "(".$_[0].")");
    1
  } else {
    0;
  }
}


case "ret from func" &&
  P iter;                         			# case 1: return from func


case "w/string" &&
  P "${\(+iter())}";                   	# case 2 w/string

case "passed array" && do {
  my @msg = ("%s", &iter ); 
  P  @msg;                              # case 3 -- being passed Array
};

case "w/fmt+string" &&
  P "%s",iter;                       		# case 4

case "to STDERR" &&
  Pe iter;                           		# case 5 #needs redirection to see

our $str;

case "to strng embedded in #7" && do {	# case 6 to string; prints in case 7
	$str = P "%s",iter; 
  P "";
};

sub timed_read($$) {
	my ($fh, $timeout)= @_;
	my $result;
	eval {
		local $SIG{ALRM} = sub {die P "timeout"};
		alarm $timeout;
		$result=<$fh>; 
		alarm 0;
	};
	return $result unless $@;
	die P "unexpected error in read: $@" unless $@ eq "timeout";
	$result="timeout";
}

sub rev{ 1 >= length $_[0] ?	$_[0] : 
							substr( $_[0], -1) .  rev(substr $_[0], 0, -1) } 

case "prev string" &&										# case 7 - print embedded P output
  P "prev str=\"%s\" (no LF) && ${\(+iter())}", $str;

case "P && array ref"  && do {
  my @ar=qw(one two three 4 5 6);
  P "%s",\@ar;													# case 8 - array expansion
};

my %hash=(a=>'apple', b=>'bread', c=>'cherry');
case "P HASH ref" &&										# case 9 - hash expansion
  P "%s", \%hash;

case "P Pkg ref" && do									# case 10 - blessed object
{	my $hp;
	bless $hp={a=>1, b=>2, x=>'y'}, 'Pkg';
	P "%s", $hp;
};

case "P \@{[FH,[\"fmt:%s\",…]]}" && do	# case 11 - embed (FH,[fmt,parms])
{																				# (rt#89056)
	P @{[\*STDOUT, ["fmt:%s", &iter]]};
};

case "truncate embedded float" && do		# case 12 - embedded float
{	my $pi=4*atan2(1,1);
	P "norm=%s, embed=%s", $pi, {pi=>$pi};
};

case "test mixed digit string" && do		# case 13 - embed foreign digits
{	use utf8;my $p="3.ⅰⅳⅰⅴⅸ";
	P "embed roman pi = %s", [$p];
};
# vim: ts=2 sw=2 fdc=1 ai

