package ProgressMonitor;

use warnings;
use strict;

use 5.008;

our $VERSION = '0.33';

# Here follows the closest we come to describing an interface.
#
use classes 0.943
  new     => 'ABSTRACT',
  clone   => 'classes::clone',
  methods => {
			  begin           => 'ABSTRACT',
			  end             => 'ABSTRACT',
			  isCanceled      => 'ABSTRACT',
			  prepare         => 'ABSTRACT',
			  setCanceled     => 'ABSTRACT',
			  setMessage      => 'ABSTRACT',
			  setErrorMessage => 'ABSTRACT',
			  tick            => 'ABSTRACT',
			  subMonitor      => 'ABSTRACT',
			 };

############################

=head1 NAME

ProgressMonitor - a flexible and configurable framework for providing feedback on how a long-running task is proceeding.

=head1 VERSION

Version 0.31

=head1 SYNOPSIS

    use strict;
    use warnings;

    use Time::HiRes qw(usleep);

    use ProgressMonitor::Stringify::ToStream;
    use ProgressMonitor::Stringify::Fields::Bar;
    use ProgressMonitor::Stringify::Fields::Fixed;
    use ProgressMonitor::Stringify::Fields::Percentage;

    sub someTask
    {
        my $monitor = shift;

        $monitor->prepare();
        $monitor->begin(100);
        for (1 .. 40)
        {
            usleep(100_000);
            $monitor->tick(1);
        }

        anotherTask($monitor->subMonitor({parentTicks => 20}));

        for (1 .. 40)
        {
            usleep(100_000);
            $monitor->tick(1);
        }
    
        $monitor->end();
    }

    sub anotherTask
    {
        my $monitor = shift;
    
        $monitor->prepare();
        $monitor->begin(3000);

        for (1 .. 3000)
        {
            usleep(1_000);
            $monitor->tick(1);
        }
    
        $monitor->end();
    }

    someTask(
		ProgressMonitor::Stringify::ToStream->new(
			{
				fields =>
                    [
                        ProgressMonitor::Stringify::Fields::Bar->new,
                        ProgressMonitor::Stringify::Fields::Fixed->new,
                        ProgressMonitor::Stringify::Fields::Percentage->new,
                    ]
			}
		)
	);

=head1 DESCRIPTION

The above synopsis shows it in a nutshell - cut and paste and try it. Or, peruse
the examples in the examples/ directory.

=head2 BACKGROUND

This is one more implementation of the idea of making code report progress in
what it's doing, and, typically, use this reporting to give feedback to a user
on how far we've come and/or how much there is left to do. There are other
Perl modules for this, but this is bigger and better :-).

The rationale for this module was twofold: first, I needed a reasonable-sized
excuse to try out Rob Muhlestein's (RMUHLE) 'classes' pragma as preparation for 
a later, bigger project. Second, I like IProgressMonitor, a Java interface in
the Eclipse project (more information in L</"SEE ALSO"> below) that I've dealt
with and thought the basic ideas around that could be put to good use in Perl
code also. There are some differences from IProgressMonitor though, if you end
up comparing them.

=head2 CONCEPT

An overall principle of a feedback mechanism is that the code doing progress really
has no idea as to how (if at all) any of the progress it reports actually result in
any feedback, or, more importantly, what form such feedback takes. Thus, this package
only provides an abstract interface for progressee's to call into, and this has to be
done in a clearly defined manner so as to ensure that any feedback will indicate
the right things at the right time. The object of all this is to keep the user informed: 'cool
your heels - maybe it's taking a long time but I *am* working!'.

Thus, any code that has no UI of its own should, 
in the best of worlds, accept an instance of the ProgressMonitor interface, and 
report its progress through that. Ideally, an entire framework should at all appropriate
places be able to make use of a monitor in order to allow the most granular feedback
possible. 

The other side of the coin is the code that does have an UI and thus knows 
how feedback should be shown. This code should instantiate a monitor of the correct
type and pass it in to the method that reports progress.

There is a middle ground however: a progresse may have need to use lower level functions
and they might also be able to use a monitor. In such a case, the higher level progressee
should instantiate a SubTask monitor. This special monitor type will pass on information
to the parent monitor and cause feedback to be correctly scaled. It is important
to never pass on the monitor you have been given to someone else!

=head2 The ProgressMonitor 'contract'

So, being a progressee, you get a monitor instance. What do you do?

=over 2

=item PREPARING YOURSELF

The first call you should do as soon as possible is to call the 'prepare' method.
This tells the monitor that you are in prepare mode, and this means that you now spend
your time figuring out how many 'things' you will need to do. While doing this you should
as regularly as possible call the 'tick' method (any arguments to tick will be ignored in prepare
mode). This will, depending on feedback mechanism, trigger some visible indication of
'work in progress'.

This step is actually
optional - maybe you already know how much work you need to do. Or, also common, you really don't know, and
it may be either impossible to figure out, or it may be prohibitive to calculate. In this case, you can go
straight to calling 'begin'.

=item BEING ACTIVE

Having called the begin method, you're saying "I'm now actively working with the task".

The begin method takes an optional parameter, an integer. The significance is that 
if you don't pass anything, you're saying 'the extent of this work is unknown, you'll just have to wait...I will
call back once in a while to ensure you see me working'. Some feedback presentations
are better at portraying this situation than others - for example, a character changing
shape for each call will give a good view of this.

Passing a number however, constitutes
a promise; 'I will call back exactly this number of times' (there's no implication of
time between calls though). Again, some presentations look better than others in this
situation - specifically, presentations that can show "I'm now here, and so much remains" 
will then give a fairly clear picture. A typical presentation is the percentage - '85 %' 
clearly shows that it's almost finished.

So, in either of the above cases you should call the 'tick' method. If the total is
unknown, each tick simply increments the internal counter by one (i.e. any argument to 
tick is ignored). If the total is unknown however, you should call with an integer argument.
Actually, the integer may be 0 in which case presentations sees it as an 'idle' tick
but still may do something visually interesting. Any other integer is simply added to
the current count - but beware of calling tick with a number that causes the total to 
be greater than your promise; this is an error. In any event, this gives the clearest
signal to presentations, one which they typically use to calculate amount done vs amount 
remaining, and then render this in the best way.

While 'ticking' is the primary way of informing the user, sometimes it makes sense
not only saying "I'm active", but also saying 'I'm currently doing this', i.e. a straightforward
message. Messages is a sort of out-of-band communication in regards to ticks. Depending
on how the monitor was set up, they may be ignored altogether, written using newlines 'beside'
the tick, or perhaps overlaying the tick field(s) (all or in part) - and then automatically
time out, restoring the tick fields. Anyway, feel free to give informational messages as
needed (but don't assume they'll be seen - just as with ticks, as the monitor in total
may be just a black hole). 

=item FINISHING

When all your tasks are complete, you should call the 'end' method. Ideally, you should
by now have called tick the right number of times, and thus the final presentation should
show (the equivalent to) 100% complete.

The monitor is now unusuable for further calls and should be discarded. 

=item CANCELLATION

Preferably, you should intermittently also call 'isCanceled' on the monitor. A true value
signals that you should cancel your work at the earliest convenience - if at all possible.
I.e. it is legal to not care about the cancellation status. Only you can decide, but it's very
nice to allow users to cancel a task.

=item SUBTASKS

During your prepare or active phase, you may utilize a lower level method/function to
do the overall task. In order to still report progress, you need to wrap your monitor inside
a SubTask monitor and pass that on.

It is illegal to pass on your own monitor - this will break as the lower level method should
follow the same pattern detailed here - thus, the first thing called will be 'prepare' and
since your own monitor is already in the active phase, it could get very confusing indeed!

The pattern here is that you allocate the subtask a certain amount of 'your' progress. Regardless
of how many iterations the subtask will do, the progress will be scaled to the parent so that 
by the time the subtask is 100% complete, it has used up only the allotment it was given. 

If you think about it, it's clear that this will work for arbitrarily deeply nested
subtasks - as long as all methods accept a monitor and use the pattern described here,
they can call each other in any order.

=back

=head1 Available monitor and field types

This package provides 4 concrete types that can be used. Two of them are special purpose
monitors, and the other two are variations on how to present the feedback as strings.

The last two uses 'field' objects to display in different ways (spinner, percentage, bar etc).

If this is not adequate for you, it's fairly easy to derive new specializations of either
complete monitors or field variations.

For each of these, see their respective documentation for details.

=head2 MONITOR TYPES

=over 2

=item ProgressMonitor::Null

If you wish to skip feedback, you may instantiate a null monitor. It implements
the interface and contract but doesn't do anything with the information.

Note: this is commonly used inside monitor accepting methods; if the caller sends no
monitor, the code instantiates a null monitor and can then use the monitor
interface normally.

=item ProgressMonitor::SubTask

This is the monitor necessary to wrap a parent monitor for a subtask. This is a
concrete implementation and you may use this or call on the monitor for a new
suitable instance using 'subMonitor'.

=item ProgressMonitor::Stringify::ToStream

This monitor type is ideal for simply displaying feedback on stdout, for example.
It must be given some field objects which defines the ultimate presentation.

=item ProgressMonitor::Stringify::ToCallback

This monitor type is useful if you have special needs for displaying, but is still
content with a plain string. It acts like ToStream, but instead of printing to the
defined stream, it will callback to a code reference you provide. 

=back

=head2 FIELD TYPES

=over 2

=item ProgressMonitor::Stringify::Fields::Bar

This will display a traditional 'bar' that grows from left to right indicating
completion amount. If the resolution is too poor to show progress, it will still 
do something. In cases of an unknown total it will provide a visual indication
of movement.

=item ProgressMonitor::Stringify::Fields::Counter

This will display the common counter, optionally with the total. It will try to show
idle progress, but for unknown totals it can only show '?'. It may also overflow if
the numbers get to big (settable though, and uncommon mostly). 

=item ProgressMonitor::Stringify::Fields::ETA

This will display an estimated time to completion. When the task is finished, this
field will show the actual time it spent (this is very different from other fields as
they typically end with the final value, e.g. '100%').

Note that since there is nothing
forcing progress to happen at a steady beat, this can be a very unreliable estimate.
For many tasks however, progress is regular enough to give a reasonable value. 

=item ProgressMonitor::Stringify::Fields::Fixed

This will display a fixed text. Useful for combining with other fields.

=item ProgressMonitor::Stringify::Fields::Percentage

This will display a percentage showing completion.

=item ProgressMonitor::Stringify::Fields::Spinner

This will display a 'moving' character/string only. Totals can't be shown with this.

=back

=head1 SEE ALSO

ProgressMonitor is (loosely) based on IProgressMonitor and associated 
mechanisms in the Eclipse/Java framework. Throw 'IProgressMonitor' into Google
and you'll most likely find your way to Eclipse docs around it. Also, this is
an article I wrote on how to deal with IProgressMonitor; it is somewhat relevant
in this context: L<http://www.eclipse.org/articles/Article-Progress-Monitors/article.html>

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

You can find documentation for this module with the perldoc command.

    perldoc ProgressMonitor

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ProgressMonitor>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ProgressMonitor>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ProgressMonitor>

=item * Search CPAN

L<http://search.cpan.org/dist/ProgressMonitor>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to my family. I'm deeply grateful for you!

Thanks to the Eclipse project for coming up with the IProgressMonitor interface
and surrounding mechanisms.

=head1 COPYRIGHT & LICENSE

Copyright 2006, 2007, 2008 Kenneth Olwing, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of ProgressMonitor
