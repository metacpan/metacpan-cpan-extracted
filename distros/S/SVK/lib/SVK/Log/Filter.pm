# BEGIN BPS TAGGED BLOCK {{{
# COPYRIGHT:
# 
# This software is Copyright (c) 2003-2008 Best Practical Solutions, LLC
#                                          <clkao@bestpractical.com>
# 
# (Except where explicitly superseded by other copyright notices)
# 
# 
# LICENSE:
# 
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of either:
# 
#   a) Version 2 of the GNU General Public License.  You should have
#      received a copy of the GNU General Public License along with this
#      program.  If not, write to the Free Software Foundation, Inc., 51
#      Franklin Street, Fifth Floor, Boston, MA 02110-1301 or visit
#      their web page on the internet at
#      http://www.gnu.org/copyleft/gpl.html.
# 
#   b) Version 1 of Perl's "Artistic License".  You should have received
#      a copy of the Artistic License with this package, in the file
#      named "ARTISTIC".  The license is also available at
#      http://opensource.org/licenses/artistic-license.php.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# CONTRIBUTION SUBMISSION POLICY:
# 
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of the
# GNU General Public License and is only of importance to you if you
# choose to contribute your changes and enhancements to the community
# by submitting them to Best Practical Solutions, LLC.)
# 
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with SVK,
# to Best Practical Solutions, LLC, you confirm that you are the
# copyright holder for those contributions and you grant Best Practical
# Solutions, LLC a nonexclusive, worldwide, irrevocable, royalty-free,
# perpetual, license to use, copy, create derivative works based on
# those contributions, and sublicense and distribute those contributions
# and any derivatives thereof.
# 
# END BPS TAGGED BLOCK }}}
package SVK::Log::Filter;
use strict;
use warnings;

sub new {
    my ($pkg, $argument) = @_;
    return bless { argument => $argument }, $pkg;
}

# generate exceptions which control the filter pipeline.  The wording is
# so that we can distinguish control exceptions from real exceptions
sub pipeline {
    my ($self, $command) = @_;
    die "pipeline, $command please";
}

# empty implementations so that derived classes only have to implement
# the methods that they need
sub setup    { 1 }
sub header   { 1 }
sub footer   { 1 }
sub teardown { 1 }
sub revision { 1 }

1;

__END__

=head1 NAME

SVK::Log::Filter - base class for all log filters

=head1 DESCRIPTION

SVK::Log::Filter is a class for displaying or otherwise processing revision
properties.  The SVK "log" command uses filter classes to handle the details
of processing the revision properties.  The bulk of this document explains how
to write those filter classes.

A log filter is just a Perl class with special methods.  At specific points
while processing log information, SVK calls these methods on the filter
object.  SVK::Log::Filter provides sensible defaults for each of the methods
it calls.  The methods (in order of invocation) are L</setup>, L</header>,
L</revision>, L</footer>, L</teardown>. Each is fully documented in the
section L</METHOD REFERENCE>.


=head1 TUTORIAL

Although log filters which output and log filters which select are exactly the
same kind of objects, they are generally conceptualized separately.  The
following tutorial provides a simple example for each type of filter.

=head2 OUTPUT

For our simple output filter example, we want to display something like the following

    1. r3200 by john
    2. r3194 by tom
    3. r3193 by larry

Namely, the number the revisions we've seen, then show the actual revision
number from the repository and indicate the author of that revision.   We want
this log filter to be accessible by a command like "svk log --output list"
The code to accomplish that is

   1   package SVK::Log::Filter::List;
   2   use base qw( SVK::Log::Filter );
       
   3   sub setup {
   4       my ($self) = @_;
   5       $self->{count} = 1;
   6   }
       
   7   sub revision {
   8       my ($self, $args) = @_;
       
   9       printf "%d. r%d by %s\n",
  10           $self->{count}++,
  11           $args->{rev},
  12           $args->{props}{'svn:author'}
  13       ;
  14   }

First, we must establish the name of this filter.  SVK looks for filters with
the namespace prefix C<SVK::Log::Filter>.  The final portion of the name can
either have the first letter capitalized or all the letters capitalized.  On
line 2, we use SVK::Log::Filter as the base class so that we can get the
default method implementations.

On lines 3-6, we get to the first meat.  Since we want to count the revisions
that we see, we have to store the information somewhere that will persist
between method calls.  We just store it in the log filter object itself.
Finally, on line 6, our C<setup> method is finished.  The return value of the
method is irrelevant.

The C<revision> method on lines 7-14 does the real work of the filter.  First
(line 8) we extract arguments into a hashref C<$args>.  Then it simply prints
what we want it to display.  SVK takes care of directing output to the
appropriate place.  You'll notice that the revision properties are provided as
a hash.  The key of the hash is the name of the property and the value of the
hash is the value of the property.

That's it.  Put SVK::Log::Filter::List somewhere in C<@INC> and SVK will find
it.

=head2 SELECTION

Our simple selection filter example will pass revisions based on whether the
revision number is even or odd.  The filter accepts a single argument 'odd' or
'even' indicating which revisions should be passed down the pipeline.
Additionally, if the filter ever encounters the revision number "42" it will
stop the entire pipeline and process no more revisions.  The invocation is
something like "svk log --filter 'parity even'" to display all even revisions
up to r42.

   1   package SVK::Log::Filter::Parity;
   2   use base qw( SVK::Log::Filter );
       
   3   sub setup {
   4       my ($self) = @_;
       
   5       my $argument = lc $self->{argument};
   6       $self->{bit} = $argument eq 'even' ? 0
   7                    : $argument eq 'odd'  ? 1
   8                    : die "Parity argument not 'even' or 'odd'\n"
   9                    ;
  10   }
       
  11   sub revision {
  12       my ($self, $args) = @_;
       
  13       my $rev = $args->{rev};
  14       $self->pipeline('last') if $rev == 42;
  15       $self->pipeline('next') if $rev % 2 != $self->{bit};
  16   }

There are only a few differences between this implementation and the output
filter implementation.  The first difference is in line 5.  When a log filter
object is created, the default C<new> method creates the 'argument' key which
contains the command-line argument provided to your filter.  In this case, the
argument should be either 'even' or 'odd'.  Based on the argument, we update
the object to remind us what parity we're looking for.

The unique characteristics of C<revision> are the calls to the C<pipeline>
method in lines 14 and 15.  If we want to stop the pipeline entirely, call
C<pipeline> with the argument 'last' (think "this is the last revision").  The
current revision and all subsequent revisions will not be processed by the
filter pipelin.  If the argument to C<pipeline> is 'next' (think "go to the
next revision"), the current revision will not be displayed and the pipeline
will proceed with the next revision in sequence.  If you don't call
C<pipeline>, the current revision is passed down the remainder of the pipeline
so that it can be processed and displayed.

=head1 METHODS

This is a list of all the methods that L<SVK::Log::Filter> implements and a
description of how they should be called.  When defining a subclass, one need
only override those methods that are necessary for implementing the filter.
All methods have sensible defaults (namely, do nothing).  The methods are
listed here in the order in which they are called by the pipeline.

All methods except L</new> and L</pipeline> receive a single hash reference
as their first argument (after the invocant, of course).  The 'Receives'
section in the documentation below indicates which named arguments are present
in that hash.

=head2 new

Builds a new object from a hash reference.  The value of any arguments
provided to the log filter on the command line are placed in the 'argument'
attribute of the object.  Generally, there is no need to override the C<new>
method because the L</setup> method can be overriden instead.

=head2 setup

Receives: L</stash>

This method is called once just before the filter is used for the first time.
It's conceptually similar to L</new>, but allows the filter developer to
ignore the creation of the filter object.  This is the place to do filter
initialization, process command-line arguments, read configuration files,
connect to a database, etc.

=head2 header

Receives: L</stash>

This method is called once just before the first revision is processed but
after C<setup> has completed.  This is an ideal place to display information
which should appear at the top of the log display.

=head2 revision

Receives: L</paths>, L</rev>, L</props>, L</stash>, L</get_remoterev>

This method is called for each revision that SVK wants to process.  The bulk
of a log filter's code implements this method.  Output filters may simply
print the information that they want displayed.  Other filters should either
modify the revision properties (see L</props>) or use pipeline commands (see
L</pipeline>) to skip irrelevant revisions.

=head2 footer

Receives: L</stash>

This method is similar to the C<header> method, but it's called once after all
the revisions have been displayed.  This is the place to do any final output.

=head2 teardown

Receives: L</stash>

This method is called once just before the log filter is discarded.  This is
the place to disconnect from databases, close file handles, etc.

=head2 pipeline

This method is not called by the filter pipeline.  Rather, it's used by log
filters to control the pipeline's behavior.  It accepts a single scalar as the
argument.  If the argument is 'next', the pipeline stops processing the
current revision (including any output filter) and starts processing the next
revision starting over at the beginning of the pipeline.  If the argument to
C<pipeline> is 'last', the pipeline is stopped entirely (including any output
filters).  Once the pipeline has stopped, the SVK log command finishes any
final details and stops.

=head1 ARGUMENTS

This section describes the possible keys and values of the hashref that's
provided to method calls.

=head1 get_remoterev

If the value of this argument is true, the value is a coderef.  When the
coderef is invoked with a single revision number as the argument, it returns
the number of the equivalent revision in the upstream repository.  The value
of this key may be undefined if the logs are being processed for something
other than a mirror.  The following code may be useful when working with
"get_remoterev"

    my           ( $stash, $rev, $get_remoterev)
    = @{$args}{qw(  stash   rev   get_remoterev )};
    my $remote_rev = $get_remoterev ? $get_remoterev->($rev) : 'unknown';
    print "The remote revision for r$rev is $remote_rev.\n";


=head2 paths

The value of the 'paths' argument is an L<SVK::Log::ChangedPaths> object.
The object provides methods for indicating which paths were changed by this
revision and approximately how they were changed (modified file contents,
modified file properties, etc.)

See the documentation for SVK::Log::ChangedPaths for more details.

=head2 rev

The value of the 'rev' argument is the Subversion revision number for the
current revision.

=head2 props

The value of the 'props' argument is a hash reference containing all the
revision properties for the current revision.  The keys of the hash are the
property names and the values of the hash are the property values.  For
example, the author of a revision is available with
C<< $args->{'svn:author'} >>.

If you change values in the 'props' hashref, those changes are visible to all
subsequent filters in the pipeline.  This can be useful and dangerous.
Dangerous if you accidentally modify a property, useful if you intentionally
modify a property.  For instance, it's possible to make a "selection" filter
which uses Babelfish to translate log messages from one language to another
(see L<SVK::Log::Filter::Babelfish> on CPAN).  By modifying the 'svn:log'
property, other log filters can operate on the translated log message without
knowing that it's translated.

=head2 stash

The value of the 'stash' argument is a reference to a hash.  The stash
persists throughout the entire log filtering process and is provided to every
method that the filter pipeline calls.  The stash may be used to pass
information from one filter to another filter in the pipeline.

When creating new keys in the stash, it's important to avoid unintentional
name collisions with other filters in the pipeline.  A good practice is to
preface the name of each stash key with the name of your filter
("myfilter_key") or to create your own hash reference inside the stash (C<<
$stash->{myfilter}{key} >>).  If your filter puts information into the stash
that other filters may want to access, please document the location and format
of that information for other filter authors.

=head1 STASH REFERENCE

=head1 quiet

If the user included the "--quiet" flag when invoking "svk log" the value of
this key will be a true value.  Otherwise, the value will be false.

=head1 verbose

If the user included the "--verbose" flag when invoking "svk log" the value of
this key will be a true value.  Otherwise, the value will be false.

