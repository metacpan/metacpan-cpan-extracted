package ProgressMonitor::SubTask;

use warnings;
use strict;

require ProgressMonitor::AbstractStatefulMonitor if 0;

# Attributes:
# 	scale
#		keeps track of the amount we need to scale ticks when reporting to parent
#	sentToParent
#		keeps track of the tick amount reported to parent
#
use classes
  extends  => 'ProgressMonitor::AbstractStatefulMonitor',
  new      => 'new',
  attrs_pr => ['scale', 'sentToParent',],
  ;

sub new
{
	my $class = shift;
	my $cfg   = shift;

	# call the protected super ctor
	#
	my $self = $class->_new($cfg, $CLASS);

	# init our instance vars
	#
	$self->{$ATTR_scale}        = 0;
	$self->{$ATTR_sentToParent} = 0;

	return $self;
}

sub begin
{
	my $self       = shift;
	my $totalTicks = shift;

	# call the super class to keep track of state
	#
	$self->SUPER::begin($totalTicks);

	# initialize us
	# store the scale we should use (keep in mind we might get 'unknown' or a wacky number)
	#
	$self->{$ATTR_scale}        = (!defined($totalTicks) || $totalTicks <= 0) ? 0 : $self->_get_cfg->get_parentTicks / $totalTicks;
	$self->{$ATTR_sentToParent} = 0;

	return;
}

sub end
{
	my $self = shift;

	# call the super class to keep track of state
	#
	$self->SUPER::end;

	# if we still have ticks not 'tocked', make sure to do that before closing shop
	#
	my $cfg     = $self->_get_cfg;
	my $remains = $cfg->get_parentTicks - $self->{$ATTR_sentToParent};
	$cfg->get_parent->tick($remains) if ($remains > $self->{$ATTR_scale});

	return;
}

sub isCanceled
{
	my $self = shift;

	# propagate this to the parent
	#
	return $self->_get_cfg->get_parent->isCanceled(@_);
}

sub setCanceled
{
	my $self = shift;

	# propagate this to the parent
	#
	return $self->_get_cfg->get_parent->setCanceled(@_);
}

sub setErrorMessage
{
	my $self = shift;

	# propagate this to the parent
	#
	return $self->_get_cfg->get_parent->setErrorMessage(@_);
}

sub tick
{
	my $self  = shift;
	my $ticks = shift;

	# call the super class to keep track of state
	#
	$self->SUPER::tick($ticks);

	# use the scale to calculate the actual ticks to be handled by the parent
	#
	my $realTicks = $ticks ? $self->{$ATTR_scale} * $ticks : 0;
	$self->_get_cfg->get_parent->tick($realTicks);
	$self->{$ATTR_sentToParent} += $realTicks;

	return;
}

sub render
{
	# noop
	# just trap any calls by the super class - rendering is done by the parent
	# when it gets 'tick' calls from us
	#
}

sub subMonitor
{
	my $self = shift;
	my $subCfg = shift || {};
	
	$subCfg->{parent} = $self;
	return ProgressMonitor::SubTask->new($subCfg);
}

sub _set_message
{
	my $self = shift;
	my $msg = shift;
	
	# propagate this to the parent if we're set that way
	#
	my $cfg = $self->_get_cfg;
	$cfg->get_parent->setMessage($msg) if $cfg->get_passMessageToParent;
}

###

package ProgressMonitor::SubTaskConfiguration;

use strict;
use warnings;

use Scalar::Util qw(blessed);

# The configuration class - ensure to extend in the parallel hierarchy as the main class
#
# Attributes:
# 	parent
#		The parent monitor we wrap
# 	parentTicks
#		The number of ticks we should use out of the parent, scaled by the ticks we
#		ourself is told to handle
#   passMessageToParent
#       Set to true if 'setMessage' calls should be passed to parent
#
use classes
  extends => 'ProgressMonitor::AbstractStatefulMonitorConfiguration',
  attrs   => ['parent', 'parentTicks', 'passMessageToParent'],
  ;

sub defaultAttributeValues
{
	my $self = shift;

	return {%{$self->SUPER::defaultAttributeValues()}, passMessageToParent => 0, parentTicks => 1};
}

sub checkAttributeValues
{
	my $self = shift;

	$self->SUPER::checkAttributeValues();

	# ensure the parent has the right interface
	#
	my $parentPkg = "ProgressMonitor";
	my $parent    = $self->get_parent;
	X::Usage->throw("parent must be supplied") unless $parent;
	X::Usage->throw("parent is not derived from $parentPkg") unless (blessed($parent) && $parent->isa($parentPkg));
	X::Usage->throw("must assign a parent tick value >= 0") if $self->get_parentTicks < 0;

	return;
}

############################

=head1 NAME

ProgressMonitor::SubTask - a monitor implementation that wraps another monitor
in order to propagate the correct number of ticks to the parent.

=head1 SYNOPSIS

  ...
  # call someTask and give it a monitor to print on stdout
  #
  someTask(ProgressMonitor::Stringify::ToStream->new({fields => [ ... ]}));
  
  sub someTask
  {
    my $monitor = shift;
    
    monitor->prepare;
    # we gather we have 3215 things to do, but only 215 of them are done by us
    # the others will be accomplished by anotherTask
    #
    monitor->begin(3215);
    for (1..215)
    {
    	...do part of the work...
        monitor->tick(1);
    }
    # farm out 3000 units of work to anotherTask
	# regardless how many units it will use for begin(), the net result is that our monitor will
	# work its way to 3000 ticks
	#
    anotherTask(ProgressMonitor::SubTask->new({parent => monitor, parentTicks => 3000}); 
    monitor->end;
  }
  
  sub anotherTask
  {
    my $monitor = shift;
  	
    monitor->prepare;
    # we're unaware of what kind of monitor we've gotten, nor do we care.
    # In this sample it'll be a SubTask, so it will scale our 189 units into the 3000
    #
    monitor->begin(189);
    for (1..189)
    {
    	...do part of the work...
        monitor->tick(1);
    }
    monitor->end;
  }

=head1 DESCRIPTION

This is a special implementation of the ProgressMonitor interface. It takes another
monitor as its parent, and a number of ticks it can use of the number allotted to
the parent. It will scale its own ticks to the parent.

Inherits from AbstractStatefulMonitor.

=head1 METHODS

=over 2

=item new( $hashRef )

Configuration data:

=over 2

=item parent

The parent monitor.

=item parentTicks (default => 1)

The number of ticks to use from the parent.

=item passMessageToParent (default => 0)

Describes whether setMessage calls should be forwarded to the parent.

=back

=back

=head1 AUTHOR

Kenneth Olwing, C<< <knth at cpan.org> >>

=head1 BUGS

I wouldn't be surprised! If you can come up with a minimal test that shows the
problem I might be able to take a look. Even better, send me a patch.

Please report any bugs or feature requests to
C<bug-progressmonitor at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ProgressMonitor>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find general documentation for this module with the perldoc command:

    perldoc ProgressMonitor

=head1 ACKNOWLEDGEMENTS

Thanks to my family. I'm deeply grateful for you!

=head1 COPYRIGHT & LICENSE

Copyright 2006,2007 Kenneth Olwing, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of ProgressMonitor::SubTask
