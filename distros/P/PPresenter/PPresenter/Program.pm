# Copyright (C) 2000-2002, Free Software Foundation FSF.

# Program
#
# Maintaining the slide dynamics during the presentation.
#

package PPresenter::Program;

use strict;

sub new(@)
{   my $class = shift;
    bless { last_phase => 0,
            @_ }, $class;
}

sub add($$)
{   my ($program, $phase, $command) = @_;
    push @{$program->{$phase}}, $command;

    $program->{last_phase} = $phase
        if $phase > $program->{last_phase};
    $program;
}

sub start($)
{   my $program = shift;
    my ($show, $viewport) = @$program{'show', 'viewport'};

    $program->{startPhase} = $program->{last_phase}
        if $program->{startPhase} > $program->{last_phase}
           || $show->mustFlushPhases;

    $program->{phase} = -1;

    $program->nextPhase
        while $program->{phase} < $program->{startPhase};
}

sub numberPhases() {shift->{last_phase}+1}
sub lastPhase()    {shift->{last_phase}}
sub phase()        {shift->{phase}}
sub inLastPhase()  {$_[0]->{phase} == $_[0]->{last_phase}}

sub nextPhase()
{   my $program = shift;

    $program->flush_phase;
    return if $program->{phase} == $program->{last_phase};

    my $phase = ++$program->{phase};
    $program->{show}->updatePhaseSymbols($phase, $program->{last_phase});

    return unless exists $program->{$phase}; # empty phase.

    my ($canvas,$dx) = @$program{'canvas', 'dx'};
    map {$_->start($canvas, $dx)} @{$program->{$phase}};

    $program->flush_phase if $program->{show}->mustFlushPhases;
    $program;
}

sub gotoPhase($)
{   my ($program, $phase) = @_;

    $program->nextPhase
       while $program->{phase} < $phase
          && $program->{phase} < $program->{last_phase};
}

sub flush_phase()
{   my $program = shift;
    my $phase   = $program->{phase};
    return unless defined $phase;

    map {$_->flushMove($program->{canvas})}
        @{$program->{$phase}};

    $program;
}

1;
