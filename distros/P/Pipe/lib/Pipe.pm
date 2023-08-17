package Pipe;
use strict;
use warnings;
use 5.006;

use Want qw(want);
our $DEBUG;

our $VERSION = '0.06';

sub logger {
    my ($self, $msg, $class) = @_;

    return if not $DEBUG;

    $class = $self if not $class;
    my $t = localtime;
    open my $fh, ">>", "pipe.log" or return;
    print $fh "[$t] [$class] $msg\n";

    return;
}

our $AUTOLOAD;

AUTOLOAD {
    my ($self) = @_;

    my $module = $AUTOLOAD;
    $module =~ s/.*:://;
    $module =~ s/=.*//;
    my $class = "Pipe::Tube::" . ucfirst $module;
    $self->logger("AUTOLOAD: '$AUTOLOAD', module: '$module', class: '$class'");
    ## no critic (ProhibitStringyEval)
    eval "use $class";
    die "Could not load '$class' $@\n" if $@;

    if ($self eq "Pipe") {
        $self = bless {}, "Pipe";
    }
    #my $last_thingy = (want('VOID') or want('LIST') or (want('SCALAR') and not want('OBJECT')) ? 1 : 0);
    $self->logger("context: $_: " . want($_)) for (qw(VOID SCALAR LIST OBJECT));

    $self->logger("params: " . join "|", @_);
    my $obj = $class->new(@_);
    push @{ $self->{Pipe} }, $obj;

    #if ($last_thingy) {
    #    $self->logger("last thingy");
    #    return $self->run_pipe;
    #}
    return $self;
}

sub run {
    my ($self) = @_;
    $self->logger("Pipe::run_pipe called");
    return if not @{ $self->{Pipe} };

    my $in = shift @{ $self->{Pipe} };
    my $in_finished = 0;
    my @results;
    while (1) {
        $self->logger("Pipe::run_pipe calls in: $in");
        my @res = $in->run;
        $self->logger("Pipe::run_pipe resulted in {" . join("|", @res) . "}");
        if (not @res) {
            $self->logger("Pipe::run_pipe calling finish");
            @res = $in->finish();
            $in_finished = 1;
        }
        foreach my $i (0..@{ $self->{Pipe} }-1) {
            my $call = $self->{Pipe}[$i];
            $self->logger("Pipe::run_pipe calls: $call");
            @res = $call->run(@res);
            $self->logger("Pipe::run_pipe results: {" . join("}{", @res) . "}");
            last if not @res;
        }
        push @results, @res;
        if ($in_finished) {
            $self->logger("IN finished");
            $in = shift @{ $self->{Pipe} };
            last if not defined $in;
            $in_finished = 0;
        }
    }
    return @results;
}




DESTROY {
   # to avoid trouble because of AUTOLOAD catching this as well 
}

=head1 NAME

Pipe - Framework for creating pipes using iterators

=head1 SYNOPSIS

 use Pipe;
 my @input = Pipe->cat("t/data/file1", "t/data/file2")->run;
 my @lines = Pipe->cat("t/data/file1", "t/data/file2")->chomp->run;
 my @uniqs = Pipe->cat("t/data/file1", "t/data/file2")->chomp->uniq->run;

 my $pipe = Pipe->cat("t/data/file1", "t/data/file2")->uniq->print("t/data/out");
 $pipe->run;


=head1 WARNING

This is Alpha version. The user API might still change

=head1 DESCRIPTION

Building an iterating pipe with prebuilt and home made tubes.

=head2 Methods

=over 4

=item logger

Method to print something to the log file, especially for debugging
This method is here to be use by Tube authors

    $self->logger("log messages");

=item run

The method that actually executes the whole pipe.

my $pipe  = Pipe->cat("file");
$pipe->run;

=back

=head2 Tubes

Tubes available in this distibution:

=over 4

=item cat

Read in the lines of one or more file.

=item chomp

Remove trailing newlines from each line.


=item find

Pipe->find(".")

Returns every file, directory, etc. under the directory tree passed to it.

=item for

Pipe->for(@array)

Iterates over the elements of an array. Basically the same as the for or foreach loop of Perl.

=item glob

Implements the Perl glob function.

=item grep

Selectively pass on values.

Can be used either with a regex:

 ->grep( qr/regex/ )

Or with a sub:

 ->grep( sub { length($_[0]) > 12 } )


Very similar to the built-in grep command of Perl but instead of regex
you have to pass a compiled regex using qr// and instead of a block you
have to pass an anonymous   sub {}

=item map

Similar to the Perl map construct, except that instead of a block you pass
an anonymous function sub {}.

 ->map(  sub {  length $_[0] } );

=item print

Prints out its input.
By default it prints to STDOUT but the user can supply a filename or a filehandle.

 Pipe->cat("t/data/file1", "t/data/file2")->print;
 Pipe->cat("t/data/file1", "t/data/file2")->print("out.txt");
 Pipe->cat("t/data/file1", "t/data/file2")->print(':a', "out.txt");

=item say

It is the same as print but adds a newline at the end of each line.
The name is Perl6 native.

=item sort

Similar to the built in sort function of Perl. As sort needs to have all 
the data in the memory, once you use sort in the Pipe it stops being
an iterator for the rest of the pipe.

By default it sorts based on ascii table but you can provide your own
sorting function. The two values to be compared are passed to this function.

 Pipe->cat("t/data/numbers1")->chomp->sort( sub { $_[0] <=> $_[1] } );

=item split

Given a regex (or a simple string), will split all the incoming strings and return
an array reference for each row.

Param: string or regex using qr//

Input: string(s)

Output: array reference(s)

=item tuple

Given one or more array references, on every iteration it will return an n-tuple
(n is the number of arrays), one value from each source array.

    my @a = qw(foo bar baz moo);
    my @b = qw(23  37  77  42);

    my @one_tuple = Pipe->tuple(\@a);
    # @one_tuple is ['foo'], ['bar'], ['baz'], ['moo']

    my @two_tuple = Pipe->tuple(\@a, \@b);
    # @two_tuple is ['foo', 23], ['bar', 37], ['baz', 77], ['moo', 42]

Input: disregards any input so it can be used as a starting element of a Pipe

Ouput: array refs of n elements

=item uniq

Similary to the unix uniq command eliminate duplicate consecutive values.

23, 23, 19, 23     becomes  23, 19, 23

Warning: as you can see from the example this method does not give real unique
values, it only eliminates consecutive duplicates.

=back

=head1 Building your own tube

If you would like to build a tube called "thing" create a module called
Pipe::Tube::Thing that inherits from Pipe::Tube, our abstract Tube.

Implement one or more of these methods in your subclass as you please.

=over 4

=item init

Will be called once when initializing the pipeline.
It will get ($self, @args)  where $self is the Pipe::Tube::Thing object
and @args are the values given as parameters to the ->thing(@args) call
in the pipeline.

=item run

Will be called every time the previous tube in the pipe returns one or more values.
It can return a list of values that will be passed on to the next tube.
If based on the current state of Thing there is nothing to do you should call
return; with no parameters.

=item finish

Will be called once when the Pipe Manager notices that this Thing should be finished.
This happens when Thing is the first active element in the pipe (all the previous tubes
have already finshed) and its run() method returns an empty list.

The finish() method should return a list of values that will be passed on to the next
tube in the pipe. This is especially useful for Tubes such as sort that can to their thing
only after they have received all the input.

=back

=head2 Debugging your tube

You can call $self->logger("some message") from your tube.
It will be printed to pipe.log if someone sets $Pipe::DEBUG = 1;

=head1 Examples

A few examples of UNIX Shell commands combined with pipelines

=over 4

=item *

cat several files together

UNIX:

 cat file1 file2 > filenew

Perl:

 open my $out, ">", "filenew" or die $!;
 while (<>) {
    print $out $_;
 }


Perl with Pipe:

 perl -MPipe 'Pipe->cat(@ARG)->print("filenew")'

=item *

UNIX:

 grep REGEX file* | uniq

Perl:

 my $last;
 while (<>) {
    next if not /REGEX/;

    if (not defined $last) {
        $last = $_;
        print;
        next;
    }
    next if $last eq $_;
    $last = $_;
    print;
 }

Perl with Pipe:

one of these will work, we hope:

 Pipe->grep(qr/REGEX/, <file*>)->uniq->print
 Pipe->cat(<file*>)->grep(qr/REGEX/)->uniq->print
 Pipe->files("file*")->cat->grep(qr/REGEX/)->uniq->print

=item *

UNIX:

 find / -name filename -print 

Perl with Pipe:

 perl -MPipe -e'Pipe->find("/")->grep(qr/filename/)->print'

=item *

Delete all the CVS directories in a directory tree (from the journal of brian_d_foy)
http://use.perl.org/~brian_d_foy/journal/29267

UNIX:

 find . -name CVS | xargs rm -rf

 find . -name CVS -type d -exec rm -rf '{}' \;

Perlish:

 find2perl . -name CVS -type d -exec rm -rf '{}' \; > rm-cvs.pl
 perl rm-cvs.pl

Perl with Pipe:

 perl -MPipe -e'Pipe->find(".")->grep(qr/^CVS$/)->rmtree;


=back



=head1 BUGS

Probably plenty but nothing I know of. Please report them to the author.

=head1 Thanks

to Gaal Yahas

=head1 AUTHOR

Gabor Szabo L<http://szabgab.com/>

=head1 COPYRIGHT

Copyright 2006 by Gabor Szabo <szabgab@cpan.org>.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=head1 See Also

L<Shell::Autobox> and L<File::Tools>


=cut

# TODOs, ideas
# ----------------
# Every pipe element have 
# @output = $obj->run(@input)
# @output = $obj->finish is called when the previous thing in the pipe finishes
#
# The run function of a pipe element should return () if it has nothing more to do 
#    (either because of lack of input or some other reason. e.g. sort cannot output anything
#    until it has all the its input data ready and thus its finish method was called
# The finish method also returns the output or () if notthing to say
# 
# the Pipe manager can recognize that a Pipe element finished if it is the first element (so it has nothing 
#    else to wait for) and its run method returned (). Then its finish method is called and it is dropped
#    
# the Pipe can easily recognize which is the first piece (it is called as class method)
# 
# the Pipe needs to recognize what is the last call, we can enforce it by a speciall call ->run
#      but if would be also nice to recognize it in other way
#      using the Want module: 
#      $o->thing         VOID
#      $z = $o->thing    SCALAR
#      if ($o->thing)    SCALAR and BOOL  
#      @ret = $o->thing  LIST

#      $o->thing->other  SCALAR and OBJECT

# TODO 
#   find
#     Improve find to provid full interface to File::Find::Rule or 
#     implement a simple version for the standard Pipe and move the one 
#     using File::Find::Rule to a separate distribution.
#   sub
#     Pipe->sub( sub {} ) can get any subroutine and will insert it in the pipe
#   tupple  
#     given two or more array, on each call reaturn an array created from one element
#     of each of the input array. Behavior in case the arrays are not the same length
#     should be defined.
#
#   process groups of values
#     given an input stream once every n iteration return an array of the n latest elemenets 
#     and in the other n-1 iterations return (). What should happen if number of elements is
#     not dividable by n ?
#
#   say
#     print with \n added like in Perl6 but with optional ("filename") to print to that file
#     without explicitely opening it.
#     
#=item flat

#Will flatten a pipe. I am not sure it is useful at all.
#The issue is that most of the tubes are iterators but "sort" needs to collect all the inputs
#before it can do its job. Then, once its done, it returns the whole array in its finish() 
#method. The rest of the pipe will get copies of this array. Including a ->flat tube in the
#pipe will receive all the array but then will serve them one by one
#
# Actualy I think ->for will do the same
#

# - Enable alternative Pipe Manager ?
# - Add a call to every tube to be executed before we start running the pipe but after building it ?
# - Describe the access to the Pipe object from the Tubes to see how a tube could change the pipe....
#
# For each tube, describe what are the expected input values, command line values and output values
#
# Check if the context checking needs any improvement
# Go over all the contexts mentioned in Want and try to build a test to each one of them
#
# 
#  split up the input stream and have more than one tails
#

# A tube might need to be able to terminate itself (or the whole pipe ?) without calling exit or die.
#   We might allow any tube to tell the pipe to skip any further call to it.
#   Or it can just decide it will keep calling  return; on every call except in finish() ?
# 
#

# Trim

# TODO: add 3rd parameter of split
 
1;

