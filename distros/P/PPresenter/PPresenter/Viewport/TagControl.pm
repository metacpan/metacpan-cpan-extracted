# Copyright (C) 2000-2002, Free Software Foundation FSF.

# TagControl
# A window which shows the tags, and enables the user to select and
# unselect tagged slides.

package PPresenter::Viewport::TagControl;

use strict;
use Tk;
use Tk::LabFrame;

sub new($$$)
{   my ($class, $show, $info, $viewport) = @_;

    my $control = $viewport->LabFrame
        ( -label       => 'tags'
        , -labelside   => 'acrosstop'
        );

    my $self = bless
        { control      => $control
        , show         => $show
        }, $class;

    my @counts = $self->{show}->countSelectedTags;
    my $row    = 0;
    my $table  = $control->Table
        ( -scrollbars => (@counts < 15 ? '' : 'w')
        , -rows       => 15
        , -fixedrows  => 1
        )->pack(-fill => 'both', -expand => 1
        , -padx=>3, -pady=>3
        , -anchor     => 'n'
        );

    $table->put($row, 0, $table->Label(-text => 'Tag', -anchor => 'w'));
    $table->put($row, 1, $table->Label(-text => 'Total'));
    $table->put($row, 2, $table->Label(-text => 'Set'));
    $table->put($row, 3, $table->Label(-text => 'Clear'));

    foreach (@counts)
    {   my ($tag, $counted, $set, $clear) = @$_;
        $row++;

        $table->put($row, 0, $table->Label
           ( -text         => $tag
           , -anchor       => 'w'
           ));

        $self->{"count_$tag"} = $counted;
        $table->put($row, 1, $table->Label
           ( -text         => $counted
           , -anchor       => 'e'
           ));

        $self->{"set_$tag" }  = $set;
        $table->put($row, 2, $table->Button
           ( -textvariable => \$self->{"set_$tag"}
           , -command      => [ \&setTag, $self, $tag ]
           , -anchor       => 'e'
           ));
 
        $self->{"clear_$tag" } = $clear;
        $table->put($row, 3, $table->Button
           ( -textvariable => \$self->{"clear_$tag"}
           , -command      => [ \&clearTag, $self, $tag ]
           , -anchor       => 'e'
           ));
    }

    $self->{message} = '';
    $control->Label(-textvariable => \$self->{message})->pack;
    $self;
}

sub setTag($)
{   my ($self, $tag) = @_;
    my $set = $self->{"clear_$tag"};
    $self->{show}->setTag($tag);
    $self->{message} = "$set slides selected.";
    $self;
}

sub clearTag($)
{   my ($self, $tag) = @_;
    my $cleared = $self->{"set_$tag"};
    $self->{show}->clearTag($tag);
    $self->{message} = "$cleared slides unselected.";
    $self;
}

sub getControl() { $_[0]->{control} }

sub selectionChanged()
{   my $self          = shift;

    my $control       = $self->{control};
    foreach ($self->{show}->countSelectedTags)
    {   my ($tag, $count, $set, $clear) = @$_;
        $self->{"set_$tag"}   = $set   if $self->{"set_$tag"} != $set;
        $self->{"clear_$tag"} = $clear if $self->{"clear_$tag"} != $clear;
    }

    $self;
}


1;
