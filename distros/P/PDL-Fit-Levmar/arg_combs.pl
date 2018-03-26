#!/usr/bin/perl -w
# arg_combs.pl --- Test code that writes signatures and calls for levmar routines

# This is mostly used to print the hash of pointers to pdl levmar function calls
# %PDL::Fit::Levmar::PDL_Levmar_funcs
# This is copied by hand into levmar.pd
# There is  probaby a way to make levmar.pd generate this
# This script  arg_combs.pl need not be run to build Levmar

use warnings;
use strict;
use Data::Dumper;



# Note from docs:
#
# * If no lower bound constraint applies for p[i], use -DBL_MAX/-FLT_MAX for lb[i];
# * If no upper bound constraint applies for p[i], use DBL_MAX/FLT_MAX for ub[i].
# Looking at the code, it seems he means that you can pass a null pointer or
# either lb or ub

sub find_levmar_func_name_from_args {
    my ($arglist, $arg_descr) = @_;
    my %seen = ();
    my $nargs = @$arglist;
    my $max_seen = 0;
    foreach my $arg ( @$arglist ) {
        foreach my $routine ( @{ $arg_descr->{$arg}->{ALLOWEDIN} } ) {
            $seen{$routine}++;
            $max_seen = $seen{$routine} if $max_seen < $seen{$routine};
        }
    }
    my @routine_priority = qw( bc lec blec bleic );
    my $routine = 'none';
    foreach my $try_routine ( @routine_priority ) {
        if ( exists $seen{$try_routine} and $seen{$try_routine} == $max_seen ) {
            $routine = $try_routine;
            last;
        }
    }
#    print join(':',@$arglist)," => ";
#    print $routine, "\n";
    return $routine;
}

sub make_hash_key_from_arg_comb {
    my ( $arg_comb ) = @_;
    return join( '_', @$arg_comb);
}

# Make the string for Pars =>
sub make_constraint_signature {
    my ( $arg_comb, $arg_descr ) = @_;
    my $sig_str = '';
    foreach my $arg ( @$arg_comb ) {
        $sig_str .= $arg_descr->{$arg}->{SIGNATURE}  . '; ';
    }
    $sig_str =~ s/;\s$//;
    return $sig_str;
}

sub array_to_hash {
    my ($a) = @_;
    my $h = {};
    foreach ( @$a) {
        $h->{$_} = 1;
    }
    return $h;
}

# not working now,
# need to use $levmar_routine_description
# below to build correct call arguments
# test if arg is present in arg_comb and write NULL , if not
sub make_constraint_call_args {
    my ( $arg_comb, $arg_descr, $levmar_routine_description, $levmar_funtion_name ) = @_;
    my $route_descr = $levmar_routine_description->{$levmar_funtion_name};
    my $args = $route_descr->{ARGS};
    my $reqr = {};
    my $arg_comb_hash = array_to_hash($arg_comb);
    $reqr = $route_descr->{REQR} if exists $route_descr->{REQR};
    my $call_str = '';
    foreach my $arg ( @$args ) {
        if ( exists $reqr->{$arg}) {
            if ( exists $arg_comb_hash->{$reqr->{$arg}} ) {
                $call_str .= "$arg,";
            }
            else {
                $call_str .= '0,';
            }
            next;
        }
        if ( not exists $arg_comb_hash->{$arg} ) {
            $call_str .= 'NULL,';
            next;
        }
        $call_str .= $arg_descr->{$arg}->{CALLARG}  . ', ';
    }
#    $call_str =~ s/,\s$//;
    return $call_str;
}

# We will write  64 (perhaps) pdl function definitions.
# For each constraint option (A,b,C... etc) we have the following:
# SIGNATURE  is the string that is part of the ppdef pdl signature
# CALLARG  is the pp_def argument in the call to the C routine
# ALLOWEDIN is the list of levmar C routines that take this constraint as an argument
sub make_argument_combinations {
    my $arg_descr = {
        A => {
            SIGNATURE => 'A(m,k)',
            CALLARG => '$P(A)',
            ALLOWEDIN => [qw( lec  blec  bleic   )],
            },
        b => {
            SIGNATURE => 'b(k)',
            CALLARG => '$P(b)',
            ALLOWEDIN => [qw( lec  blec  bleic   )],
            },
        ub => {
            SIGNATURE => 'ub(m)',
            CALLARG => '$P(ub)',
            ALLOWEDIN => [qw( bc  blec  bleic   )],
        },
        lb => {
            SIGNATURE => 'lb(m)',
            CALLARG => '$P(lb)',
            ALLOWEDIN => [qw( bc  blec  bleic  )],
        },
        C => {
            SIGNATURE => 'C(m,k2)',
            CALLARG => '$P(C)',
            ALLOWEDIN => [qw(  bleic  )],
        },
        d => {
            SIGNATURE => 'd(k2)',
            CALLARG => '$P(d)',
            ALLOWEDIN => [qw(  bleic  )],
        },
    };

    my $levmar_routine_description = {
        none => { ARGS => [] },
        bc => {  ARGS =>  [qw( lb ub )] },
        lec => {  ARGS => [ 'A',  'b', '$SIZE(k)' ],
                  REQR =>  { '$SIZE(k)' => 'A' },
              },
        blec => {  ARGS =>  [ 'lb', 'ub',  'A', 'b' , '$SIZE(k)' ],
                   REQR =>  { '$SIZE(k)' => 'A' },
               },
        bleic => {  ARGS =>  [ 'lb', 'ub', 'A', 'b', '$SIZE(k)',  'C', 'd', '$SIZE(k2)' ],
                    REQR =>  { '$SIZE(k)' => 'A', '$SIZE(k2)' => 'C' },
                }
    };

    my %arg_combs_analysis =();
        # These are intended to be legal constraint combinations
    # result should also be used to check if a call is legal
    # This should make all leval combinations
    my $arg_combs = [];
    foreach my $linear ( [ ] , [ 'A', 'b' ] ) {
        foreach my $box ( [ ] , [ 'lb', 'ub' ] , [ 'lb' ], [ 'ub' ] ) {
            foreach my $ineq ( [ ] , [ 'C', 'd' ] ) {
               push @$arg_combs, [ @$box, @$linear, @$ineq ];
            }
        }
    }
    foreach my $arg_comb ( @$arg_combs ) {
        my $levmar_funtion_name = find_levmar_func_name_from_args( $arg_comb, $arg_descr );
        my $comb_key = make_hash_key_from_arg_comb( $arg_comb );
        my $constraint_signature = make_constraint_signature( $arg_comb, $arg_descr );
        my $call_args = make_constraint_call_args( $arg_comb, $arg_descr,
                                                   $levmar_routine_description, $levmar_funtion_name );
        $arg_combs_analysis{$comb_key} = {
            LEVMAR_FUNCTION_NAME => $levmar_funtion_name,
            ARG_COMB => [ @$arg_comb ],
            SIGNATURE => $constraint_signature,
            CALLARGS => $call_args,
            PDL_FUNC_NAME_DER => make_pdl_levmar_func_name_from_strings($comb_key, 'der'),
            PDL_FUNC_NAME_DIFF => make_pdl_levmar_func_name_from_strings($comb_key, 'diff'),
        };
    }
    print Dumper(%arg_combs_analysis);
    return \%arg_combs_analysis;
}

# for testing. This replaces the pdl pp_def sub
sub pp_def  {
    my $name = shift;
    my %ppdef = @_;
    $ppdef{NAME} = $name;
    print Dumper(\%ppdef);
}

sub write_pp_defs {
    my ($arg_combs_analysis) = @_;
    foreach my $der ( 'analytic', 'numeric' ) {
#	foreach my $con ( 'none', 'bc', 'lec', 'blec', 'bleic','blic','leic','lic' ) {
        foreach my $argcomb ( keys %$arg_combs_analysis ) {
            # passing workspace is broken for some routines, so...
            my $arg_anal = $arg_combs_analysis->{$argcomb};
	    my $h = {NOWORK => 0}; # default
	    if ($der eq 'analytic') { # analytic derivative
		$h->{NAME} = 'analytic';
		$h->{OPAR} = ' IV jacn; IV sjacn; ';
		$h->{CALL} = 'der';
		$h->{ARG} = '$TFD(tsjacn, tjacn),';
                $h->{DUMI}= 'void * tjacn = (void *) $COMP(jacn);
                             void * tsjacn = (void *) $COMP(sjacn);';
                $h->{WORKFAC} = 2;    # needs less workspace than numeric
	    }
	    else { # numeric derivative
		$h->{NAME} = 'difference';
		$h->{OPAR} = '';
		$h->{CALL} = 'dif';
		$h->{ARG} = '';
                $h->{DUMI}= '';
                $h->{WORKFAC} = 4;
	    }
            $h->{SIG} = $arg_anal->{SIGNATURE} . '; ' ;
            $h->{ARG2} = $arg_anal->{CALLARGS};
            $h->{NAME} = $argcomb . "_" . $h->{NAME};
            if ($arg_anal->{LEVMAR_FUNCTION_NAME} eq 'bleic' ) {
                $h->{NOWORK} = 1;
            }
            my $funcname = '';
            $funcname = $arg_anal->{LEVMAR_FUNCTION_NAME} unless $arg_anal->{LEVMAR_FUNCTION_NAME} eq 'none';
            $h->{CALL} = $funcname . '_' . $h->{CALL} unless $arg_anal->{LEVMAR_FUNCTION_NAME} eq 'none';
            if ($arg_anal->{LEVMAR_FUNCTION_NAME} eq 'blec' ) {
                 $h->{SIG} .= 'wghts(m); ';
                 $h->{ARG2} .= '$P(wghts), ';    
            }
            my $pdl_func_name;
            $pdl_func_name = $arg_anal->{PDL_FUNC_NAME_DER} if $der eq 'analytic';
            $pdl_func_name = $arg_anal->{PDL_FUNC_NAME_DIFF} if $der eq 'numeric';
	    pp_def( $pdl_func_name,
                   Pars => " p(m);  x(n);  t(nt); $h->{SIG} int iopts(in);  opts(nopt); [t] work(wn);
	                [o] covar(m,m) ; int [o] returnval();
                        [o] pout(m);  [o] info(q=10); ",
	          OtherPars => " IV funcn; IV sfuncn;  $h->{OPAR} IV indat; "
                          . " int want_covar;  ",
                  RedoDimsCode => "
                     int im = \$PDL(p)->dims[0];
                     int in = \$PDL(x)->dims[0];
                     int min = $h->{WORKFAC}*in + 4*im + in*im + im*im;
                     int inw = \$PDL(work)->dims[0];
                     \$SIZE(wn) = inw >= min ? inw : min;
                  ",
	          GenericTypes => ['F','D'], Doc => undef,
                  Code => "
                     int * iopts;
                     int maxits;
                     void * tfuncn = (void *) \$COMP(funcn);
                     void * tsfuncn = (void *) \$COMP(sfuncn);
                     \$GENERIC(covar) * pcovar;
                     \$GENERIC(work) * pwork;
                     $h->{DUMI};
                     DFP *dat = (void *) \$COMP(indat);
                     DFP_check( &dat, \$TFD(PDL_F,PDL_D), \$SIZE(m), \$SIZE(n),
		                      \$SIZE(nt), \$P(t) );
                     threadloop %{    
                         loop(m) %{
                            \$pout() = \$p();
                         %}
                         iopts = \$P(iopts);
                         if ( \$COMP(want_covar) == 1 ) pcovar = \$P(covar);
                         else pcovar = NULL; 
                         if ( $h->{NOWORK} == 1 )  pwork = NULL;
                         else pwork =  \$P(work);
                         maxits = iopts[0]; /* for clarity. we hope optimized away  */
         	   \$returnval() = \$TFD(slevmar_$h->{CALL},dlevmar_$h->{CALL}) (
                      \$TFD(tsfuncn,tfuncn) , $h->{ARG}
                      \$P(pout), \$P(x),  \$SIZE(m), \$SIZE(n), $h->{ARG2}
         	      maxits, \$P(opts), \$P(info), pwork, pcovar, dat);
           /*     maxits, \$P(opts), \$P(info), \$P(work), pcovar , dat);     */
                %}
               "
	    );
	}
    }
}

# make a list of strings of names of constraint args that
# have been passed.
# hash is arg hash to top level call
sub make_arg_comb_list {
    my ($h) = @_;
    my @arg_comb = ();
    # order is important in following
    my @possible_args = qw( lb ub A b C d );
    foreach ( @possible_args ) {
        push @arg_comb, $_ if exists $h->{$_};
    }
    return \@arg_comb;
}

# arg_str is string form of constraint arg names, eg lb_ub_A_b
# deriv is numeric or analytic
# returns name of perl function call
sub make_pdl_levmar_func_name_from_strings {
    my ($arg_str, $deriv_type) = @_;
    return  'levmar_' . make_pdl_levmar_func_key($arg_str, $deriv_type);
}

sub make_pdl_levmar_func_name_from_arg_list {
    my ($arg_comb, $deriv_type) = @_;
    return make_pdl_levmar_func_name_from_strings( make_hash_key_from_arg_comb($arg_comb), $deriv_type );
}

sub make_pdl_levmar_func_key {
    my ($arg_str, $deriv_type) = @_;
    return  $deriv_type . '_' . $arg_str;
}

sub print_pdl_func_hash_def {
    my ($arg_combs_analysis) = @_;
    print '%PDL::Fit::Levmar::PDL_Levmar_funcs = (' , "\n";
    foreach my $arg_str ( keys %$arg_combs_analysis ) {
        my $arg_anal = $arg_combs_analysis->{$arg_str};
        my $keyn = make_pdl_levmar_func_key( $arg_str, 'der' );
        $keyn =~ tr/a-z/A-Z/;
        print "  $keyn => \\&PDL::$arg_anal->{PDL_FUNC_NAME_DER},\n";
        $keyn = make_pdl_levmar_func_key( $arg_str, 'diff' );
        $keyn =~ tr/a-z/A-Z/;
        print "  $keyn => \\&PDL::$arg_anal->{PDL_FUNC_NAME_DIFF},\n";
    }
    print ")\n";
}


my $a  = make_argument_combinations();
write_pp_defs($a);
print_pdl_func_hash_def($a);
