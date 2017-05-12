use strict;
use warnings;
use t::scan::Util;

test(<<'TEST'); # LAWALSH/P-1.1.34/lib/P.pm
{ package P;
	use warnings; use strict;use mem;
	our $VERSION='1.1.34';

# RCS $Revision: 1.45 $ -  $Date: 2015-12-14 12:09:03-08 $
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
	our (@ISA, @EXPORT);
	# no sense to support iohandle w/Pe, as Pe is tied to stderr
	{ no warnings "once"; *IO::Handle::P = \&P::P }
		
	use Types::Core;

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
		sub reduce(&@) {
			my (@final, $i) =((), 0);
			my ($f, $ar)=@_;
			for (my $i=0; $i <  $#$ar; ++$i ) {
				($a, $b) = ($ar->[$i], $ar->[$i+1]);
				my @r = &$f;
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
	our ($dflts, %mod_dflts, %types);
	BEGIN {
		%_dflts=(
			implicit_io	=> 0, 
			depth				=> 3, 
			ellipsis		=> '…', 
			noquote			=> 1, 
			maxstring		=> undef,
			seen				=> '🔁',
			undef				=> '∄',
		);

		my $bool	 = sub { $_[0] ? 1 : 0 };
		my $intnum = sub { $_[0] =~ m{^([0-9]+)$} ? 0 + $1 : 0 };
		my $string = sub { length($_[0]) ? $_[0]  : '' };
		my $true	 = sub { 1 };

		%types=(
			default			=> $true,
			depth				=> $intnum, 
			ellipsis		=> $string,
			implicit_io	=> $bool,
			maxstring		=> $intnum,
			seen				=> $string,
			undef				=> $string,
		);


		#global default copy
		$mod_dflts{""}	= \%_dflts;
		$dflts					=	$mod_dflts{""};

	}

	sub sw(*);

	sub Px { my ($p, $v) = (shift, shift);
		local (*sw); *sw = sub (*) {$dflts->{$_[0]}};
		if (ref $v) {
			if ($p->{__P_seen}{$v}) { return "*". sw(seen) . ":" . $v . "*" }
			else {$p->{__P_seen}{$v} = 1}
		}
		my $lvl = scalar @_ ? $_[0] : 2;
		my $ro	= scalar @_>1 ? $_[1]:0;
		return sw('undef') unless defined $v;
		my $ref = ref $v;
		if (1 > $lvl-- || !$ref) {
			my $fmt;			# prototypes are documentary (rt#89053)
			my $given = [	sub ($$) { $_[0] =~ /^[-+]?[0-9]+\.?\z/			&& q{%s}	},
										sub ($$) { $_[1] 														&& qq{%s}},
										sub ($$) { 1 == length($_[0]) 							&& q{'%s'}},
										sub ($$) { $_[0] =~ m{^(?:[+-]?(?:\.[0-9]+)
															|	(?:[0-9]+\.[0-9]+))\z}x  				&&  q{%.2f}},
										sub ($$) { substr($_[0],0,5) eq 'HASH('			&& 
																								'{'.sw(ellipsis).'}'.q{%.0s}	},
										sub ($$) { substr($_[0],0,6) eq 'ARRAY('		&& 
																								'['.sw(ellipsis).']'.q{%.0s}	},
										#	sub ($$) { $mxstr && length ($_[0])>$mxstr 
										#						&& qq("%.${mxstr}s")},
										sub ($$) { 1																&& q{"%s"}} ];

			do { $fmt = $_->($v, $ro) and last } for @$given;
			return sprintf($fmt, $v);
		} else { 
			my $pkg = '';
			($pkg, $ref) = ($1, $2) if 0 <= (index $v,'=') && $v=~m{([\w:]+)=(\w+)}; 
			local * nonrefs_b4_refs ;
			* nonrefs_b4_refs = sub {
				ref $v->{$a} cmp ref $v->{$b}  || $a cmp $b 
			};

			local (*IO_glob, *NIO_glob, *IO_io, *NIO_io);
			(*IO_glob, *NIO_glob, *IO_io, *NIO_io) = (
						sub(){'<*'.<$v>.'>'}, sub(){'<*='.$p->Px($v, $lvl-1).'>'},
						sub(){'<='.<$v>.'>'}, sub(){'<|'.$p->Px($v, $lvl-1).'|>'},
					);
			no strict 'refs';
			my %actions = ( 
				GLOB	=>	($p->{implicit_io}? *IO_glob: *NIO_glob),
				IO		=>	($p->{implicit_io}? *IO_io	 : *NIO_io),
				REF		=>	sub(){ "\\" . $p->Px($$_, $lvl-1) . ' '},
				SCALAR=>	sub(){ $pkg.'\\' . $p->Px($$_, $lvl).' ' },
				ARRAY	=>	sub(){ $pkg."[". 
												(join ', ', 
#	not working: why?			#reduce \&rm_adjacent, (commented out)
												map{ $p->Px($_, $lvl) } @$v ) ."]" },
				HASH	=>	sub(){ $pkg.'{' . ( join ', ', @{[
										map {$p->Px($_, $lvl, 1) . '=>'. $p->Px($v->{$_}, $lvl,0)} 
										sort  nonrefs_b4_refs keys %$v]} ) . '}' },);
			if (my $act=$actions{$ref}) { &$act } 
			else { return "$v" }
		}
	}

	sub get_dflts($) {
		my $p = shift; my $caller = $_[0];
		return $p->{dflts}  if exists $p->{dflts};
		return exists $mod_dflts{$caller} ? $mod_dflts{$caller} : $mod_dflts{""};
	}
			


	sub P(@) {    # 'safen' to string or FH or STDOUT
		local *sw = sub (*) {$dflts->{$_[0]}};
		my $p = ref $_[0] eq 'P' ? shift: bless {};
		$p->{__P_seen}={} unless ref $p->{__P_seen};

		local * unsee_ret  = sub ($) { 
			delete $p->{__P_seen} if exists $p->{__P_seen}; 
			$_[0] };

		my $v = $_[0];
    my $rv = ref $v;
		$dflts = $p->get_dflts((caller)[0]);
		my ($depth, $noquote) = (sw(depth), sw(noquote));
    if (HASH eq $rv) {
			my $params = $v; $v = shift; $rv = ref $v;
			$depth = $params->{depth} if exists $params->{depth};
    }
    if (ARRAY eq $rv ) { $v = shift;
      @_=(@$v, @_); $v=$_[0]; $rv = ref $v }

		my ($fh, $f, $explicit_out);
		if ($rv eq GLOB || $rv eq IO) {
			($fh, $explicit_out) = (shift, 1);
			$v = $_[0]; $rv = ref $v;
		} else { $fh =\*STDOUT }
    
		if (ARRAY eq $rv ) { $v = shift;
      @_=(@$v, @_); $v=$_[0]; $rv = ref $v }
    
		my ($fc, $fmt, @flds, $res)=(1, $_[0]);
		if ($fc) { $f = shift; no warnings;
			$res =  sprintf $f,	map {local $_ = $p->Px($_,$depth,$noquote) } @_ } 
		else { $res = $p->Px(@_)}

		chomp $res;

		my ($nl, $ctx) = ("\n", defined wantarray ? 1 : 0);

		($res, $nl, $ctx) = (substr($res, 0, -1 + length $res), "", 2) if
					ord(substr $res,-1) == NoBrHr;									#"NO_BREAK_HERE"

		if (!$fh && !$ctx) {	#internal consistancy check
			($fh = \*STDERR) and 
				P $fh "Invalid File Handle presented for output, using STDERR";
			($explicit_out, $nl) = (1, "\n") }

		else { return unsee_ret($res) if (!$explicit_out and $ctx==1) }

		no warnings 'utf8';
		print $fh ($res . (!$ctx && (!$\ || $\ ne "\n") ? "\n" : "")  );
		unsee_ret($res);
	};

	sub Pe(@) {
		my $p = shift if ref $_[0];
		return '' unless @_;
		unshift @_, \*STDERR;
		unshift @_, $p if ref $p;
		goto &P 
	}


	#Pe "_dflts=%s", \%_dflts;
	#Pe "mod_dflts{}=%s", $mod_dflts{""};
	#Pe "mod_dflts=%s", \%mod_dflts;

	sub import {
		my ($modname, @args) = @_;
		if (@args) {
			my @others;
			my $caller = (caller)[0];
			if (exists $mod_dflts{$caller}) {
				$dflts = $mod_dflts{$caller};
			} else {
				$dflts = undef;					# indicate no customization to dflts
			}
			my $default = 0;
			my @tags = grep {	if (m{^:(.*)$}) {
													if ($1 eq 'default') { $default = 1; $_ = undef } 
													else { $_ = $1 }
												} else { push @others, $_; undef }
											} @args;
			if (@tags) {
				if ($default) {
					# change global defaults (don't use copy)
					$dflts = $mod_dflts{""};
				} else {
					# if dflts was undef start w/copy of glbl-dflts
					%{$mod_dflts{$caller}} = %{$mod_dflts{""}} unless exists
						$mod_dflts{$caller};
						$dflts=$mod_dflts{$caller}
				}
				for (@tags) {
					my ($tag, $value) = m{^(\w+)(?:=(.+))?$} or 
							die "Tag-format: missing :TAG=VALUE for tag '" . $_ . "'";

					my $chk;
				 	{no warnings; no strict; $chk = eval $types{$tag}->($value) };
					$dflts->{$tag} = $chk;
				}
			}
			$dflts = $mod_dflts{""} unless $dflts;	# set to global if not set
			@_=($modname, @others);
		}
		goto &Xporter::import;
	}




	sub ops($) {
		my $p = shift; my $c=ref $p || $p;
		bless $p = {}, $c unless ref $p;
		my $args = $_[0];
		my $ldflts = $p->get_dflts((caller)[0]);
		%{$p->{dflts}} = %$dflts unless ref $p->{dflts};
		die "ops takes a hash to pass arguments" unless HASH $args;
		$ldflts = $p->{dflts};
		foreach (sort keys %$args) {
			if (exists $ldflts->{$_}) { $ldflts->{$_} = $args->{$_} } 
			else { 
				warn  "Unknown key \"$_\" passed to ops";} 
		}
		$p }
1;}		#value 1 placed at as w/most of my end-of-packages (rt#89054)
TEST
done_testing;
