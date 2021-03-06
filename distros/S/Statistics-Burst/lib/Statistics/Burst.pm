package Statistics::Burst;

use 5.008004;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Statistics::Burst ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.2';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Statistics::Burst -  Perl Implementation of Kleinberg's Word Busts algorithm

=head1 SYNOPSIS

  use Statistics::Burst;
  my $burstObj=Burst::new();
  $burstObj->generateStates(3,.111,2);
  $burstObj->gamma(.5);
  $burstObj->setData(\@gap_space);
  $burstObj->process();
  $statesUsed=$burstObj->getStatesUsed();

=head1 DESCRIPTION

This Burst Module is an implementation of Kleinberg's Word Bursts algorithm.
The paper describing the algorithm is located at http://www.cs.cornell.edu/home/kleinber/bhs.pdf.

What this algorithm implementation does is after a few parameters are set the driver code will pass it a list of numbers. The list of numbers are the time diferences between different arrivals.  So if you were modelling the arrivals of people into a store entrance and they arrive at times 8:10,8:20,8:25,8:30 then the list of numbers you would pass to Burst will be (10,5,5). 

Bursts can be used to model the popularity of words by defining what is the arrival and rate for words.  For instance you could monitor RSS titles from Slashdot.  If the word appears in a title you could consider that an arrival of that word.  Your arrival rate could be defined as how many arrivals of a paticular word in a day or how many times a word appears per a heading (This would usually be less than 1)

With this information you would build the seperation lists  that will be used processed by the Burst function.



=cut

=head2 new

  $burst=Statistics::Burst::new();

Returns a burst object.

=cut
	

sub new
{
	my $self={states=>[],gamma=>undef, statesUsed=>[], data=>[]};
	bless $self;
	return $self;
}


=head2 setState($lamba, [$index])

     $burst->setState(.112);
     $burst->setState(.24,1);

Allows you to set or change the lamba of a paticular state. If $index is not specified then it creates a new state.

=cut
	
sub setState
{
	my ($self, $lamba, $index)=@_;
	if (defined($index))
	{
		return undef if (scalar(@{$self->{states}}) < $index);
		$self->{states}->[$index]=$lamba;
	}
	else
	{
		push @{$self->{states}}, $lamba;
	}
}

=head2 generateStates($count,$rate, $sigma)

     $burst->generateStates(4,.123,1);

Allows developer to generate the states programatically.  You specify the number of states to create [$count], The initial rate for state 0 [$rate], and sigma the parameter that defines how much the state changes.

The higher the sigma the larger the difference between states.

=cut

sub generateStates
{
	my ($self, $count, $rate, $sigma)=@_;
	for (my $i=0;$i<$count;$i++)
	{
	   $self->setState($rate*($sigma**$i));
	}

}

=head2 gamma($gamma)

     $burst->gamma(2,);

A parameter for the transistion cost.  The larger the gamma value the more expensive it is to move to a higher state.

=cut

sub gamma
{
	my ($self, $gamma)=@_;
	$self->{gamma}=$gamma;
}

=head2 setData($gap_space)

     $burst->setData([4,5,6,3,4,2]);

Sets the data that will be processed.

=cut

sub setData
{
	my ($self, $gap_space)=@_;
	$self->{data}=[];
	@{$self->{data}}=@$gap_space;
}

=head2 process

     $burst->process();

Triggers the calculation of the bursts.

=cut

sub process
{
	my ($self)=@_;
	my $result={};
	$self->calcCost(11);
}
##################################################

sub calcCost
{
   my ($self,$pos)=@_;
	my @lamba=@{$self->{states}};
   my $stateCount=scalar(@lamba);
   if ($pos==0)
   {
     $self->{statesUsed}->[$pos]=0;
     return {state=>0,minCosts=>0};

   }
   my ($trans, $pc, $cost);
   my $minCosts=99999;
   my $state=-1;
	my @gap_space=@{$self->{data}};

	my $costImprove=1;

   for(my $tryState=0;($tryState<$stateCount) && ($costImprove) ;$tryState++)
   {
       my $prevresult={};
       $prevresult=$self->calcCost($pos-1,$prevresult);

       my $trans= $self->transistion($prevresult->{state},$tryState,
				 $gap_space[$pos]);
       my $pc=  $prevresult->{minCosts} ;
       my $alignment=-1*log(func($lamba[$tryState],$gap_space[$pos])) ;
       my $cost= $alignment + $pc + $trans;
#print "$pos: $tryState ->",$cost,
#          " = a:$alignment + prev:$pc +trans:$trans \n";
      if ($cost<$minCosts)
      {
         $minCosts=$cost;
         $state=$tryState;
         $self->{statesUsed}->[$pos]=$state;
      }
		else
		{  #If the costs didnt improve (the tryState should be >=1 by now)
			#Then there is no use in trying higher states.
			$costImprove=0;
		}
   }
   return {state=>$state,minCosts=>$minCosts};
}

sub transistion
{ 
   my ($self,$prev,$curr,$pos)=@_;
   if ($prev >= $curr)
   {
      return 0;
   }
   else
   {
      return ( $self->{gamma}*($curr-$prev) *log($pos));
   }
}

sub func($$)
{
  my ($lamba, $x)=@_;
  my $e=2.718;
  my $value=$lamba*($e ** ($lamba *$x *-1));
  return $value
}

=head2 getStatesUsed
  
  $array_ref=$burst->getStatesUsed();
  
Returns the states of the automaton for each step in the data set.

=cut

sub getStatesUsed
{
	my ($self)=@_;
	return $self->{statesUsed};
}

=head1 AUTHOR

Copyright 2004-2005, Tommie M. Jones All Rights Reserved.
This library is free software; you can redistribute it and/or modify it
       under the same terms as Perl itself.

=cut
