package Parallel::Simple;

use strict;
use warnings;

use Exporter ();
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
$VERSION = '0.01';

@ISA       = qw( Exporter );
@EXPORT    = qw();
@EXPORT_OK = qw( prun );

my $error;
my $return_values;

sub err { $error         }
sub rv  { $return_values }

sub errplus {
    return unless ( defined $error );
    "$error\n" . ( ref($return_values) =~ /HASH/ ?
        join( '', map { "\t$_ => $return_values->{$_}\n" } sort keys %$return_values ) :
        join( '', map { "\t$_ => $return_values->[$_]\n" } 0..$#$return_values )
    );
}

sub prun {
    ( $error, $return_values ) = ( undef, undef );         # reset globals
    return 1 unless ( @_ );                                # return true if 0 args passed
    my %options = %{pop @_} if ( ref($_[-1]) =~ /HASH/ );  # grab options, if specified
    return 1 unless ( @_ );                                # return true if 0 code blocks passed

    # normalize named and unnamed blocks into similar structure to simplify main loop
    my $named  = ref($_[0]) ? 0 : 1;  # if first element is a subref, they're not named
    my $i      = 0;                   # used to turn array into hash with array-like keys
    my %blocks = $named ? @_ : map { $i++ => $_ } @_;

    # fork children
    my %child_registry;  # pid => { name => $name, return_value => $return_value }
    while ( my ( $name, $block ) = each %blocks ) {
        my $child = fork();
        unless ( defined $child ) {
            $error = "$!";
            last;  # something's wrong; stop trying to fork
        }
        if ( $child == 0 ) {  # child
            my ( $subref, @args ) = ref($block) =~ /ARRAY/ ? @$block : ( $block );
            my $return_value = eval { $subref->( @args ) };
            warn( $@ ) if ( $@ );  # print death message, because eval doesn't
            exit( $@ ? 255 : $options{use_return} ? $return_value : 0 );
        }
        $child_registry{$child} = { name => $name, return_value => undef };
    }

    # wait for children to finish
    my $successes = 0;
    my $child;
    do {
        $child = waitpid( -1, 0 );
        if ( $child > 0 and exists $child_registry{$child} ) {
            $child_registry{$child}{return_value} = $? unless ( defined $child_registry{$child}{return_value} );
            $successes++ if ( $? == 0 );
            if ( $? > 0 and $options{abort_on_error} ) {
                while ( my ( $pid, $child ) = each %child_registry ) {
                    unless ( defined $child->{return_value} ) {
                        kill( 9, $pid );
                        $child->{return_value} = -1;
                    }
                }
            }
        }
    } while ( $child > 0 );

    # store return values using appropriate data type
    $return_values = $named
        ? { map { $_->{name} => $_->{return_value} } values %child_registry }
        : [ map { $_->{return_value} } sort { $a->{name} <=> $b->{name} } values %child_registry ];

    my $num_blocks = keys %blocks;
    return 1 if ( $successes == $num_blocks );  # all good!

    $error = "only $successes of $num_blocks blocks completed successfully";
    return 0;  # sorry... better luck next time
}

1;

__END__

=pod

=head1 NAME

Parallel::Simple - the simplest way to run code blocks in parallel

=head1 SYNOPSIS

 use Parallel::Simple qw( prun );

 # style 1: simple list of code blocks
 prun(
     sub { print "$$ foo\n" },
     \&my_bar_func,
 ) or die( Parallel::Simple::errplus() );

 # style 1 with options
 prun(
     sub { print "$$ foo\n" },
     \&my_bar_func,
     { use_return => 1 },
 ) or die( Parallel::Simple::errplus() );

 # style 2: named code blocks (like the Benchmark module)
 prun(
     foo => sub { print "$$ foo\n" },
     bar => \&my_bar_func,
 ) or die( Parallel::Simple::errplus() );

 # getting fancy with arg binding
 prun(
     [ \&my_bar_func, @args ],
     [ \&my_bar_func, @other_args ],
 ) or die( Parallel::Simple::errplus() );

=head1 DESCRIPTION

I generally write my scripts in a linear fashion.  Do A, then B, then C.
However, I often have parts that don't depend on each other, and therefore
don't have to run in any particular order, or even linearly.  I could save time
by running them in parallel - but I'm too lazy to deal with forking, and
reaping zombie processes, and other nastiness.

The goal of this module is to make it so mind-numbingly simple to run blocks of
code in parallel that there is no longer any excuse not to do it, and in the
process, drastically cut down the runtimes of many of our applications,
especially when running on multi-processor servers (which are pretty darn
common these days).

Parallel code execution is now as simple as calling C<prun> and passing it a
list of code blocks to run, followed by testing the return value for truth
using the common "or die" perl idiom.

=head1 EXPORTS

By default, Parallel::Simple does not export any symbols.  You generally want
to export the C<prun> function to save time:

    use Parallel::Simple qw(prun);
    prun( ... );

No other functions are exportable.  You will have to full qualify calls to
them, like this:

    print Parallel::Simple::errplus();

=head1 FUNCTIONS

=over

=item B<prun>

Runs multiple code blocks in parallel by forking a process for each one and
returns when all processes have exited.  Returns true if nothing went wrong,
false otherwise.  Therefore, returns true if no code blocks are passed, since
nothing can go wrong if there are no code blocks to execute!

There are two styles of passing code blocks:

B<Style 1 - Simple List of Code Blocks>

In its simplest form (which is what we're all about here), C<prun> takes a list
of code blocks and then forks a process to run each block.  It returns true if
all processes exited with exit value 0, false otherwise.  Example:

    prun(
        sub { print "$$ foo\n" },
        \&my_bar_func,
    ) or die( Parallel::Simple::errplus() );

By default, the exit value will be 255 if the code block dies or throws any
exceptions, or 0 if it doesn't.  You can exercise more control over this by
using the C<use_return> option (documented below) and returning values from
your code block.

If C<prun> returns false and you want to see what went wrong, try the C<err>,
C<errplus>, and C<rv> functions documented below - especially C<rv> which will
tell you the exit values of the processes that ran the code blocks.

B<Style 2 - Named Code Blocks>

Alternatively, you can specify names for all of your code blocks by using the
common "named params" perl idiom.  The only benefit you get from this currently
is an improved lookup method for code block return values (see C<rv> for more
details).  Example:

    prun(
        foo => sub { print "$$ foo\n" },
        bar => \&my_bar_func,
    ) or die( Parallel::Simple::errplus() );

Other than looking nicer, this behaves identically to the Style 1 example.

B<Argument Binding>

You can include arguments to be passed to the code block along with the block
itself by passing a listref containing the code block followed by the args:

    prun(
        [ \&my_bar_func, @args ],
        [ \&my_bar_func, @other_args ],
    ) or die( Parallel::Simple::errplus() );

This will fork two processes, one of which will call &my_bar_func and pass it
@args, the other of which will call &my_bar_func and pass it @other_args.  This
works with both styles.  Here a similar example using named code blocks:

    prun(
        foo  => sub { print "$$ foo\n" },
        bar1 => [ \&my_bar_func, @args ],
        bar2 => [ \&my_bar_func, @other_args ],
    ) or die( Parallel::Simple::errplus() );

B<Options>

You can optionally pass a reference to a hash containing additional options as
the last argument.  Example:

    prun(
        sub { print "$$ foo\n" },
        \&my_bar_func,
        { use_return => 1 },
    ) or die( Parallel::Simple::errplus() );

There are currently only two options:

=over

=item B<use_return>

By default, the return values for the code blocks, which are retrieved using
the C<rv> function, will be 0 if the code block executed normally or 255 if the
code block died or threw any exceptions.  By default, any value the code block
returns is ignored.

If you use the C<use_return> option, then the return value of the code block is
used as the return value (unless the code block dies or throws an exception, in
which case the return value will still be 255).  This value is passed to the
exit function, so B<please please please> use only number between 0 and 255!

Note:  If you use the C<abort_on_error> option, blocks may also have a return
value of -1 indicating that they were terminated because another block failed.

=item B<abort_on_error>

Normally, a call to C<prun> will block until all code blocks have exited,
regardless of exit status.  If you use the C<abort_on_error> option, all blocks
will be terminated immediately as soon as any block exits unsuccessfully.  Note
that terminated blocks will have a return value of -1.

=back

=item B<err>

Returns a string describing the last error that occured, or undef if there
has not yet been any errors.

Currently, only two error messages are possible:

=over

=item *

if the call to C<fork> fails, C<err> returns the contents of C<$!>

=item *

if any blocks fail, C<err> returns a message describing how many blocks failed
out of the total

=back

=item B<errplus>

Returns a string containing the return value of C<err> plus a nicely formatted
version of the return value of C<rv>.  I strongly recommend using this function
in the following idiom, because it is the laziest way to present the greatest
amount of failure/debugging information to the user:

    prun(
      ...  # code blocks
    ) or die( Parallel::Simple::errplus() );

=item B<rv>

Returns different value types depending on whether or not you used named code
blocks:

=over

=item B<Style 1> (not using named code blocks)

returns a reference to an array containing the return values of the code blocks
in the order they were passed to C<prun>

=item B<Style 2> (using named code blocks)

returns a reference to a hash, where keys are the code block names, and values
are the return values of the respective code block

=back

See the C<use_return> option for the C<prun> function for more details on how
to control return values.

=back

=head1 PLATFORM SUPPORT

This module was developed and tested on Red Hat Linx 9.0, kernel 2.6.11, and
perl v5.8.4 built for i686-linux-thread-multi.  I have not tested it anywhere
else.  This module is obviously limited to platforms that have a working
C<fork> implementation.

I would appreciate any feedback from people using this module in different
environments, whether it worked or not, so I can note it here.

=head1 FUTURE

The world could probably use a thread-based version of the C<prun> function.
I'm currently accepting applications from volunteer coders.  :)

Also:

 - capture stdout/stderr
 - capture block die/exception messages
 - capture entire 16 bit exit code, just in case

However, these all make Parallel::Simple less Simple.

=head1 SEE ALSO

L<Parallel::ForkControl>, L<Parallel::ForkManager>, and L<Parallel::Jobs>
are all similarly themed, and offer different interfaces and advanced features.
I suggest you skim the docs on all three (in addition to mine) before choosing
the right one for you.  Or you can foolishly trust the executive summaries
below:

=over

=item B<Parallel::ForkControl>

Only takes one subroutine reference to run, but provides wonderful ways to
control how many children are forked and keeping activity below certain
thresholds.  Arguments to the C<run> method will be passed on to the subroutine
you specified during construction, so there's some run-time flexibility.  It
is not yet possible to learn anything about what happened to the forked
children, such as inspecting return or exit values.

Conclusion: Best for repetitive, looped tasks, such as fetching web pages or
running a command across a cluster of machines in parallel.

Incidentally, B<Parallel::ForkControl> would be far more useful with the
following two changes:

=over

=item *

Support some kind of feedback - return/exit values at a minimum, or even a
single value summary, like the return value of my B<prun> function.

=item *

Allow the user to specify the Code value in the B<run> method instead of during
construction.  Then B<Parallel::ForkControl> could do everything this module
does and more, albeit with a more sophisticated interface.

=back

=item B<Parallel::ForkManager>

Unique in the Parallel::* world in that it keeps the user somewhat involved in
the forking process.  Rather than taking a code reference, you call the start()
method to B<fork> and test the return value to determine whether you are now
the parent or child... almost like just calling B<fork> yourself.  :)

Provides control over how many child processes to allow, and blocks new forks
until some previous children have exited.  Let's child determine the process
exit value.  Provides a trigger mechanism to run callbacks when certain events
happen (child start, child exit, and start blocking).  You must supply a
callback for the child exit event to inspect the exit value of the child.

Conclusion: While also designed for repetitive, looped tasks, it is far more
flexible, being a thin wrapper around B<fork> rather than taking over child
creation and management entirely.  Useful mostly if you want to limit child
processes to a certain number at a time and/or if the native system calls scare
you.

=item B<Parallel::Jobs>

Different in that it executes shell commands as opposed to subroutines or code
blocks.  Provides all the features of the open3 function, including explicit
control over C<STDIN>, C<STDOUT>, and C<STDERR> on all 'jobs'.  Lets you
monitor jobs for output and exit events (with associated details for each
event).

Conclusion: Great for shell commands!  Not great for not shell commands.

=back

=head1 AUTHORS

Written by Ofer Nave E<lt>ofer@netapt.comE<gt>.
Sponsered by Shopzilla, Inc. (formerly BizRate.com).

=head1 COPYRIGHT

Copyright 2005 by Shopzilla, Inc.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut

