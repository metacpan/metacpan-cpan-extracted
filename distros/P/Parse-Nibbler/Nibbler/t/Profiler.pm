package Profiler;


=for

    Profiler - Automatically profile subroutine calls in a perl program.
    Copyright (C) 2001  Greg London

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

use strict;
use Data::Dumper;
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval );


###########################################################################
###########################################################################
###########################################################################
###########################################################################
#
# This subroutine, __recursively_fetch_subs_in_package, takes a single
# package name as a parameter. The sub then goes through the symbol table
# for that package and finds the name of all existing subroutines.
# The return value is a hash, the key is the name of the sub,
# The data associated with the key is a code reference to that sub.
#
# Note: This subroutine calls itself recursively.
# It stores intermediate results in some our'ed variables.
# A global hash needs to be used so that recursive calls can
# detect if the package they are looking at has already been checked.
# This prevents an infinite loop if you have two packages that both
# contain the other.
#
# These global hashes need to be cleared just prior to an outside call.
# To prevent problems because the user didn't do this, the subroutine
# looks at caller() information and detects whether it was called from
# an outside location, or whether it was called by itself recursively.
# If it is an outside call, the hashes are initialized to be empty.
# This allows you to call this subroutine repeatedly without clearing
# the hash before each call. It is done automatically for you.
#
###########################################################################
###########################################################################
###########################################################################
###########################################################################

our %__package_has_been_checked;
our %__original_subroutine_code_refs;

###########################################################################
###########################################################################
###########################################################################
sub __recursively_fetch_subs_in_package
###########################################################################
###########################################################################
###########################################################################
{
  my $pkg = shift;

  #print "checking package $pkg \n";

  return if ($pkg eq 'Profiler');

  my ($p1, $p2, $p3, $calling_sub) = caller(1);
  #print "calling_sub is $calling_sub \n";

  my ($s1, $s2, $s3, $self_sub) = caller(0);
  #print "   self_sub is $self_sub \n";

  # if I'm not calling myself, 
  # (someone called me externally)
  # then I need to empty out the package_has_been_checked hash
  # so that I can start fresh, and guarantee that I check all
  # the packages properly.
  # just need to clear the hash the first time,
  # all recursive calls should NOT clear the hash.
  my $top_caller = 1;
  $top_caller = 0 if ($calling_sub eq $self_sub); #self-caller

  if($top_caller)
    {
      %__package_has_been_checked = ();
      %__original_subroutine_code_refs = ();
    }

  my @symbols;
  my $sym_str = '@symbols = keys(%'.$pkg.'::);'  ;
  eval($sym_str);

  my @new_packages;
  my %subroutines;

  foreach my $sym (@symbols)
    {
      next if ($sym eq $pkg.'::');
      next if ($sym =~ /^__/);

      if($sym =~ /\:\:$/)
	{
	  $sym = $pkg .'::'. $sym;

	  #print "subpackage is $sym \n";
	  push(@new_packages, $sym);
	  next;
	}

      # subroutine name must contain only valid identifier characters
      next if ($sym =~ /\W/);

      my $code_ref;

      my $sub_str = '$code_ref = *'.$pkg.'::'.$sym.'{CODE};';

      # print "string is $sub_str \n"; next;
      eval($sub_str);

      # if it's not a subroutine, can't instrument it.
      next unless($code_ref);

      # if its a builtin, no point in instrumenting it.
      next if($sym =~ /^[A-Z]+$/);

      # any $sym that has made it this far is a valid subroutine to instrument
      $__original_subroutine_code_refs{$pkg.'::'.$sym} = $code_ref;
    }

  $__package_has_been_checked{$pkg} = 1;

  # now get subroutines from all packages used by this package
  foreach my $sub_pkg (@new_packages)
    {
      $sub_pkg =~ s/\:\:$//;
      __recursively_fetch_subs_in_package($sub_pkg);
    }

  if($top_caller)
    {
      # if this is the top level call (not recursive)
      # then will actually need to return data to user.
      # While I'm at it, I'll clear the 'our' global hashes so
      # that an external user doesn't get any bright ideas and
      # attempt to use the data in those global hashes.
      %__package_has_been_checked = ();
      my %return_hash = %__original_subroutine_code_refs;
      %__original_subroutine_code_refs = ();
      return (%return_hash);
    }
  else
    { return; }
}

###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################
#
# There are a number of built in subroutines that should not be instrumented.
# Also, when a subroutine is exported into other packages, leave it alone.
#
# The best (least likely for the user to mess up) way to do this is for the
# user code to "use" whatever packages they dont want instrumented FIRST,
# and then use this profiler package.
#
# When this package is "use"ed, it runs a BEGIN block which looks to
# see what subroutines are currently installed in package main and below.
# It then marks these subroutines as "DO NOT INSTRUMENT".
# This package then schedules an INIT block to run later.
#
# The user can follow the "use" statement to use this package with
# any code that the user DOES want instrumented. This would most likely
# be use statements to use other packages or simple subroutine declarations.
#
# When the entire program has finished compiling, the INIT block from this
# program is executed. This block looks for all subroutines that exist
# in package main and below (any package used by main).
#
# If it detects any NEW subroutine, i.e. any subroutine that it didn't
# previously mark as "DO NOT INSTRUMENT", then the INIT block will 
# instrument it.
#
###########################################################################
###########################################################################
###########################################################################
###########################################################################

###########################################################################
###########################################################################
###########################################################################
###########################################################################
our %do_not_instrument_this_sub;  # package qualified from main::
our @do_not_instrument_this_sub;  # partially qualified name, ex. Data::Dumper

BEGIN
{
  push(@do_not_instrument_this_sub, 
       'Data::Dumper', 'Time::HiRes',  'DieOnFatalError',
       'usleep', 'ualarm', 'gettimeofday', 'tv_interval',
      'Profiler');
}
###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################

###########################################################################
###########################################################################
sub BEGIN
###########################################################################
###########################################################################
{
  my %subs = __recursively_fetch_subs_in_package('main');

  while( my ($name, $ref) = each(%subs) )
    {
      #print "BEGIN name is $name \n";
      $do_not_instrument_this_sub{$name}=1;
    }

  #print "Do not Instrument:\n";
  #print Dumper \%do_not_instrument_this_sub;
}


###########################################################################
###########################################################################
sub INIT
###########################################################################
###########################################################################
{
  my %subs = __recursively_fetch_subs_in_package('main');

  SUB : while( my ($name, $ref) = each(%subs) )
    {
      foreach my $sub (@do_not_instrument_this_sub)
	{
	  if ($name =~ /$sub/)
	    {
	      next SUB;
	    }
	}
      next if ($do_not_instrument_this_sub{$name});
      #print "INIT name is $name \n";
      __instrument_sub($name, $ref);
    }
}



###########################################################################
###########################################################################
###########################################################################
sub __instrument_sub
###########################################################################
###########################################################################
###########################################################################
{
  my ($name, $coderef) = @_;

  #print "instrumenting $name \n";

  my $instrumented_ref = sub
    {
      __pre_code ( $name );

      my $ret_val;
      eval{ $ret_val = &$coderef; };
      my $eval_error = $@;

      __post_code ( $name );
      die ($eval_error) if ($eval_error);

      return $ret_val;
    };

  my $install_string = '*'.$name.' = \&$instrumented_ref; ' ;
  eval($install_string);


}
###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################
# the code above instruments all the subroutines.
# the code below is for profiling the subroutine calls.
###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################

our %caller_info;
our @timer_info;
our @accumulative_info;

###########################################################################
###########################################################################
sub __pre_code
###########################################################################
###########################################################################
{
  my ($this_subroutine) = @_;

  unless(exists($caller_info{$this_subroutine}))
    {
      $caller_info{$this_subroutine}={} ;
    }

  #print "pre_code for $this_subroutine \n";

  my ($calling_pkg, $filename, $line, $calling_sub) = caller(2);
  my $calling_subroutine = $calling_pkg.'::'.$calling_sub;


  $caller_info{$this_subroutine}->{total_calls} ++;
  $caller_info{$this_subroutine}->{$calling_subroutine} ++;

  push(@accumulative_info, 0.0);

  my $start_time =  [gettimeofday];
  push(@timer_info, $start_time);
}

###########################################################################
###########################################################################
sub __post_code
###########################################################################
###########################################################################
{
  my ($this_subroutine) = @_;

  #print "post_code for $this_subroutine \n";

  my $accum = pop(@accumulative_info);

  my $start_time = pop(@timer_info);
  my $end_time =  [gettimeofday];
  my $elapsed = tv_interval ( $start_time, $end_time );
  #print "elapsed time for $this_subroutine is $elapsed \n";

  my $time_in_sub = $elapsed - $accum;
  #print "time_in_sub for $this_subroutine is $time_in_sub \n";

  $caller_info{$this_subroutine}->{total_time_in_sub} += $time_in_sub;

  if(scalar(@accumulative_info))
    {
      $accumulative_info[-1] += $accum + $time_in_sub;
    }
}



sub by_total_time 
{ 
  return $a->{total_time_in_sub} <=> $b->{total_time_in_sub}; 
}

sub END
{
  print Dumper \%Profiler::caller_info;

  my @keys = keys(%Profiler::caller_info);

  foreach my $key (@keys)
    {
      my $href = $Profiler::caller_info{$key};

      $href->{who_am_i} = $key;
    }

  my @subs = values(%Profiler::caller_info);


  my @sorted = sort by_total_time ( @subs );

  print Dumper \@sorted;
}

1;

__END__

=head1 NAME

    Profiler - Automatically profile subroutine calls in a perl program.

=head1 SYNOPSIS

    use Profiler;


=head1 DESCRIPTION

  The profiler module is completely automatic in its basic mode.
  You simply "use" the module at the top of you main script.
  The module will then automatically instrument all subroutines
  in the code, profile each subroutine call during the execution
  of the script, and print out a report of usage.


=head2 EXPORT

  Every subroutine that exists at "INIT" time will be redefined
  to call an instrumented version of the subroutine.


=head1 AUTHOR


    Profiler - Automatically profile subroutine calls in a perl program.
    Copyright (C) 2001  Greg London

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    contact the author via http://www.greglondon.com


=head1 SEE ALSO


=cut
