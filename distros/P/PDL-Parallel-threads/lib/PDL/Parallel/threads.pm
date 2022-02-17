package PDL::Parallel::threads;

use strict;
use warnings;
use Carp;
use PDL;
use PDL::IO::FastRaw;

my $can_use_threads;
BEGIN {
	$can_use_threads = eval {
		require threads;
		threads->import();
		require threads::shared;
		threads::shared->import();
		1;
	};
	
	our $VERSION = '0.04';
	use XSLoader;
	XSLoader::load 'PDL::Parallel::threads', $VERSION;
}

# These are the means by which we share data across Perl threads. Note that
# we cannot share piddles directly accross threads, but we can share arrays
# of scalars, scalars whose integer values are the pointers to piddle data,
# etc.
my %datasv_pointers :shared;
my %dim_arrays :shared;
my %types :shared;
my %originating_tid :shared;
my %file_names :shared;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(share_pdls retrieve_pdls free_pdls);

# PDL data should not be naively copied by Perl. This is only necessary
# for older versions of PDL. Newer versions contain the CLONE_SKIP
# method... which is nice except that it issues warning. So wrap this
# in a no-warnings block.
{
	no warnings;
	sub PDL::CLONE_SKIP { 1 }
	# Also suppress the warnings that PDL now apparently issues
	$PDL::no_clone_skip_warning = 1;
}

sub auto_package_name {
	my $name = shift;
	my ($package_name) = caller(1);
	$name = "$package_name/$name" if $name =~ /^\w+$/;
	return $name;
}

sub share_pdls {
	croak("share_pdls: expected key/value pairs")
		unless @_ % 2 == 0;
	my %to_store = @_;
	
	while (my ($name, $to_store) = each %to_store) {
		$name = auto_package_name($name);
		
		# Make sure we're not overwriting already shared data
		if (exists $datasv_pointers{$name} or exists $file_names{$name}) {
			croak("share_pdls: you already have data associated with '$name'");
		}
		
		# Handle the special case where a memory mapped piddle was sent, and
		# for which the memory mapped piddle knows its file name
		if ( eval{$to_store->isa("PDL")}
			and exists $to_store->hdr->{mmapped_filename}
		) {
			$to_store = $to_store->hdr->{mmapped_filename};
		}
		
		if ( eval{$to_store->isa("PDL")} ) {
			# Share piddle memory directly
			$datasv_pointers{$name} = eval{_get_and_mark_datasv_pointer($to_store)};
			if ($@) {
				my $error = $@;
				chomp $error;
				delete $datasv_pointers{$name};
				croak('share_pdls: Could not share a piddle under '
					. "name '$name' because $error");
			}
			if ($can_use_threads) {
				$dim_arrays{$name} = shared_clone([$to_store->dims]);
				$originating_tid{$name} = threads->tid;
			}
			else {
				$dim_arrays{$name} = [$to_store->dims];
			}
			$types{$name} = $to_store->get_datatype;
		}
		elsif (ref($to_store) eq '') {
			# A file name, presumably; share via memory mapping
			if (-w $to_store and -r "$to_store.hdr") {
				$file_names{$name} = $to_store;
			}
			else {
				my $to_croak = join('', 'When share_pdls gets a scalar, it '
									, 'expects that to be a file to share as '
									, "memory mapped data.\nFor key '$name', "
									, "'$to_store' was given, but");
				croak("$to_croak there is no associated header file")
					unless -f "$to_store.hdr";
				croak("$to_croak you do not have permissions to read the "
					. "associated header file") unless -r "$to_store.hdr";
				croak("$to_croak you do not have write permissions for that "
					. "file") if -w $to_store;
				# Default: the file does not exist
				croak("$to_croak the file does not exist");
			}
		}
		else {
			croak("share_pdls passed data under '$name' that it doesn't "
				. "know how to store");
		}
	}
}



# Frees the memory associated with the given names.
sub free_pdls {
	# Keep track of each name that is successfully freed
	my @removed;
	
	for my $short_name (@_) {
		my $name = auto_package_name($short_name);
		
		# If it's a regular piddle, decrement the memory's refcount
		if (exists $datasv_pointers{$name}) {
			_dec_datasv_refcount($datasv_pointers{$name});
			delete $datasv_pointers{$name};
			delete $dim_arrays{$name};
			delete $types{$name};
			delete $originating_tid{$name};
			push @removed, $name;
		}
		# If it's mmapped, remove the file name
		elsif (exists $file_names{$name}) {
			delete $file_names{$name};
			push @removed, $name;
		}
		# If its none of the above, indicate that we didn't free anything
		else {
			push @removed, '';
		}
	}
	
	return @removed;
}

# PDL method to share an individual piddle
sub PDL::share_as {
	my ($self, $name) = @_;
	share_pdls(auto_package_name($name) => $self);
	return $self;
}

# Method to get a piddle that points to the shared data assocaited with the
# given name(s).
sub retrieve_pdls {
	return if @_ == 0;
	
	my @to_return;
	for my $short_name (@_) {
		my $name = auto_package_name($short_name);
		
		if (exists $datasv_pointers{$name}) {
			# Make sure that the originating thread still exists, or the
			# data will be gone.
			if ($can_use_threads and $originating_tid{$name} > 0
				and not defined (threads->object($originating_tid{$name}))
			) {
				croak("retrieve_pdls: '$name' was created in a thread that "
						. "has ended or is detached");
			}
			
			# Create the new thinly wrapped piddle
			my $new_piddle = _new_piddle_around($datasv_pointers{$name},
				$types{$name});
			
			# Set the dimensions
			my @dims = @{$dim_arrays{$name}};
			$new_piddle->setdims(\@dims);
			
			# Set flags to protect the piddle's memory:
			_update_piddle_data_state_flags($new_piddle);
			
			push @to_return, $new_piddle;
		}
		elsif (exists $file_names{$name}) {
			push @to_return, mapfraw($file_names{$name});
		}
		else {
			croak("retrieve_pdls could not find data associated with '$name'");
		}
	}
	
	# In list context, return all the piddles
	return @to_return if wantarray;
	
	# Scalar context only makes sense if they asked for a single name
	return $to_return[0] if @_ == 1;
	
	# We're here if they asked for multiple names but assigned the result
	# to a single scalar, which is probably not what they meant:
	carp("retrieve_pdls: requested many piddles... in scalar context?");
	return $to_return[0];
}

# Now for a nasty hack: this code modifies PDL::IO::FastRaw's symbol table
# so that it adds the "mmapped_filename" key to the piddle's header before
# returning the result. As long as the user says "use PDL::IO::FastRaw"
# *after* using this module, this will allow for transparent sharing of both
# memory mapped and standard piddles.

{
	no warnings 'redefine';
	my $old_sub = \&PDL::IO::FastRaw::mapfraw;
	*PDL::IO::FastRaw::mapfraw = sub {
		my $name = $_[0];
		my $to_return = $old_sub->(@_);
		$to_return->hdr->{mmapped_filename} = $name;
		return $to_return;
	};
}

1;

__END__

=head1 NAME

PDL::Parallel::threads - sharing PDL data between Perl threads

=head1 VERSION

This documentation describes version 0.04 of PDL::Parallel::threads.

=head1 SYNOPSIS

 use PDL;
 use PDL::Parallel::threads qw(retrieve_pdls share_pdls);
 
 # Technically, this is pulled in for you by PDL::Parallel::threads,
 # but using it in your code pulls in the named functions like async.
 use threads;
 
 # Also, technically, you can use PDL::Parallel::threads with
 # single-threaded programs, and even with perl's not compiled
 # with thread support.
 
 # Create some shared PDL data
 zeroes(1_000_000)->share_as('My::shared::data');
 
 # Create a piddle and share its data
 my $test_data = sequence(100);
 share_pdls(some_name => $test_data);  # allows multiple at a time
 $test_data->share_as('some_name');    # or use the PDL method
 
 # Or work with memory mapped files:
 share_pdls(other_name => 'mapped_file.dat');
 
 # Kick off some processing in the background
 async {
     my ($shallow_copy, $mapped_piddle)
         = retrieve_pdls('some_name', 'other_name');
     
     # thread-local memory
     my $other_piddle = sequence(20);
     
     # Modify the shared data:
     $shallow_copy++;
 };
 
 # ... do some other stuff ...
 
 # Rejoin all threads
 for my $thr (threads->list) {
     $thr->join;
 }
 
 use PDL::NiceSlice;
 print "First ten elements of test_data are ",
     $test_data(0:9), "\n";

=head1 DESCRIPTION

This module provides a means to share PDL data between different Perl
threads. In contrast to PDL's posix thread support (see
L<PDL::Parallel::CPU> or, for older versions of PDL, L<PDL::ParallelCPU>),
this module lets you work with Perl's built-in threading model. In contrast
to Perl's L<threads::shared>, this module focuses on sharing I<data>, not
I<variables>.

Because this module focuses on sharing data, not variables, it does not use
attributes to mark shared variables. Instead, you must explicitly share your
data by using the L</share_pdls> function or L</share_as> PDL method that this
module introduces. Those both associate a name with your data, which you use
in other threads to retrieve the data with the L</retrieve_pdls>. Once your
thread has access to the piddle data, any modifications will operate directly
on the shared memory, which is exactly what shared data is supposed to do.
When you are completely done using a piece of data, you need to explicitly
remove the data from the shared pool with the L</free_pdls> function.
Otherwise your data will continue to consume memory until the originating
thread terminates, or put differently, you will have a memory leak.

This module lets you share two sorts of piddle data. You can share data for
a piddle that is based on actual I<physical memory>, such as the result of
L<PDL::Core/zeroes>. You can also share data using I<memory mapped> files.
(Note: PDL v2.4.11 and higher support memory mapped piddles on all major
platforms, including Windows.) There are other sorts of piddles whose data
you cannot share. You cannot directly share slices (though a simple 
L<PDL::Core/sever> or L<PDL::Core/copy> will give you a
piddle based on physical memory that you can share). Also, certain functions
wrap external data into piddles so you can manipulate them with PDL methods.
For example, see L<PDL::Graphics::PLplot/plmap> and
L<PDL::Graphics::PLplot/plmeridians>. These you cannot share directly, but
making a physical copy with L<PDL::Core/copy> will give you
something that you can safey share.

=head2 Physical Memory

The mechanism by which this module achieves data sharing of physical memory
is remarkably cheap. It's even cheaper then a simple affine transformation.
The sharing works by creating a new shell of a piddle for each call to 
L</retrieve_pdls> and setting that piddle's memory structure to point back to
the same locations of the original (shared) piddle. This means that you can
share piddles that are created with standard constructors like
L<PDL::Core/zeroes>, L<PDL::Core/pdl>, and L<PDL::Basic/sequence>, or which
are the result of operations and function evaluations for which there is no
data flow, such as L<PDL::Core/cat> (but not L<PDL::Core/dog>), arithmetic,
L<PDL::Core/copy>, and L<PDL::Core/sever>. When in doubt, C<sever> your
piddle before sharing and everything should work.

There is an important nuance to sharing physical memory: The memory will
always be freed when the originating thread terminates, even if it terminated
cleanly. This can lead to segmentation faults when one thread exits and
frees its memory before another thread has had a chance to finish
calculations on the shared data. It is best to use barrier synchronization
to avoid this (via L<PDL::Parallel::threads::SIMD>), or to share data solely
from your main thread.

=head2 Memory Mapped Data

The mechanism by which this module achieves data sharing of memory mapped
files is exactly how you would share data across threads or processes using 
L<PDL::IO:::FastRaw>. However, there are a couple of important caveats to
using memory mapped piddles with C<PDL::Parallel::threads>. First, you must
load C<PDL::Parallel::threads> before loading L<PDL::IO::FastRaw>:

 # Good
 use PDL::Parallel::threads qw(retrieve_pdls);
 use PDL::IO::FastRaw;
 
 # BAD
 use PDL::IO::FastRaw;
 use PDL::Parallel::threads qw(retrieve_pdls);

This is necessary because C<PDL::Parallel::threads> has to perform a few
internal tweaks to L<PDL::IO::FastRaw> before you load its fuctions into
your local package.

Furthermore, any memory mapped files B<must> have header files associated
with the data file. That is, if the data file is F<foo.dat>, you must have
a header file called F<foo.dat.hdr>. This is overly restrictive and in the
future the module may perform more internal tweaks to L<PDL::IO::FastRaw> to
store whatever options were used to create the original piddle. But for the
meantime, be sure that you have a header file for your raw data file.

There is much less nuance to sharing memory mapped data across threads
compared to directly sharing physical memory as discussed above. When
you ask for a thread-local copy of that file, you get your very own fully
baked memory-mapped piddle that gets freed when the piddle goes out of scope.
This means you cannot get memory leaks. Furthermore, the data underlying the
piddle come from a file and not from a shared space in RAM. That means there
is no "originating thread", and you cannot trigger a segmentation fault
by trying to access memory that has disappeared, because... there's nothing
that can disappear.

=over

You may ask yourself why loading this module must come before loading the
FastRaw module. The reason is that L<PDL::IO::FastRaw> exports a few methods
to your namespace, and C<PDL::Parallel::threads> modifies one of those
exported functions. If you pull in FastRaw before this module, this module
won't have been able to work its magic on FastRaw first, and the functions
in your package won't be the ones needed for proper sharing of memory
mapped data. Put differently, the earlier you can manage to
C<use PDL::Parallel::threads>, the better.

=back

=head2 Package and Name Munging

C<PDL::Parallel::threads> lets you associate your data with a specific text
name. Put differently, it provides a global namespace for data. Users of the
C<C> programming language will immediately notice that this means there is
plenty of room for developers using this module to choose the same name for
their data. Without some combination of discipline and help, it would be
easy for shared memory names to clash. One solution to this would be to
require users (i.e. you) to choose names that include thier current package,
such as C<My-Module-workspace> or, following L<perlpragma>,
C<My::Module/workspace> instead of just C<workspace>. This is sometimes
called name mangling. Well, I decided that this is such a good idea that
C<PDL::Parallel::threads> does the second form of name mangling for you
automatically! Of course, you can opt out, if you wish.

The basic rules are that the package name is prepended to the name of the
shared memory as long as the name is only composed of word characters, i.e.
names matching C</^\w+$/>. Here's an example demonstrating how this works:

 package Some::Package;
 use PDL;
 use PDL::Parallel::threads 'retrieve_pdls';
 
 # Stored under '??foo'
 sequence(20)->share_as('??foo');
 
 # Shared as 'Some::Package/foo'
 zeroes(100)->share_as('foo');
 
 sub do_something {
   # Retrieve 'Some::Package/foo'
   my $copy_of_foo = retrieve_pdls('foo');
   
   # Retrieve '??foo':
   my $copy_of_weird_foo = retrieve_pdls('??foo');
   
   # ...
 }
 
 # Move to a different package:
 package Other::Package;
 use PDL::Parallel::threads 'retrieve_pdls';
 
 sub something_else {
   # Retrieve 'Some::Package/foo'
   my $copy_of_foo = retrieve_pdls('Some::Package/foo');
   
   # Retrieve '??foo':
   my $copy_of_weird_foo = retrieve_pdls('??foo');
   
   # ...
 }

The upshot of all of this is that if you use some module that also uses
C<PDL::Parallel::threads>, namespace clashes are highly unlikely to occur
as long as you (and the author of that other module) use simple names,
like the sort of thing that works for variable names.

=head1 FUNCTIONS

This module provides three stand-alone functions and adds one new PDL method.

=head2 share_pdls

=for ref

Shares piddle data across threads using the given names.

=for usage

  share_pdls (name => piddle|filename, name => piddle|filename, ...)

This function takes key/value pairs where the value is the piddle to store
or the file name to memory map, and the key is the name under which to store
the piddle or file name. You can later retrieve the memory (or a piddle
mapped to the given file name) with the L</retrieve_pdls> method.

Sharing a piddle with physical memory increments the data's reference count;
you can decrement the reference count by calling L</free_pdls> on the given
C<name>. In general this ends up doing what you mean, and freeing memory
only when you are really done using it. Memory mapped data does not need to
worry about reference counting as there is always a persistent copy on disk.

=for example

 my $data1 = zeroes(20);
 my $data2 = ones(30);
 share_pdls(foo => $data1, bar => $data2);

This can be combined with constructors and fat commas to allocate a
collection of shared memory that you may need to use for your algorithm:

 share_pdls(
     main_data => zeroes(1000, 1000),
     workspace => zeroes(1000),
     reduction => zeroes(100),
 );

=for bad

C<share_pdls> does not pay attention to bad values. There is no technical
reason for this: it simply hadn't occurred to me until I had to write the
bad-data documentation. Expect it to happen in a forthcoming release. :-)

=head2 share_as

=for ref

Method to share a piddle's data across threads under the given name.

=for usage

  piddle->share_as(name)

This PDL method lets you directly share a piddle. It does the exact same
thing as L</shared_pdls>, but it's invocation is a little different:

=for example

 # Directly share some constructed memory
 sequence(20)->share_as('baz');
 
 # Share individual piddles:
 my $data1 = zeroes(20);
 my $data2 = ones(30);
 $data1->share_as('foo');
 $data2->share_as('bar');

Like many other PDL methods, this method returns the just-shared piddle.
This can lead to some amusing ways of storing partial calculations partway
through a long chain:

 my $results = $input->sumover->share_as('pre_offset') + $offset;
 
 # Now you can get the result of the sumover operation
 # before that offset was added, by calling:
 my $pre_offset = retrieve_pdls('pre_offset');

This function achieves the same end as L</share_pdls>: There's More Than One
Way To Do It, because it can make for easier-to-read code. In general I
recommend using the C<share_as> method when you only need to share a single
piddle memory space.

=for bad

C<share_as> does not pay attention to bad values. There is no technical
reason for this: it simply hadn't occurred to me until I had to write the
bad-data documentation. Expect it to happen in a forthcoming release. :-)

=head2 retrieve_pdls

=for ref

Obtain piddles providing access to the data shared under the given names.

=for usage

  my ($copy1, $copy2, ...) = retrieve_pdls (name, name, ...)

This function takes a list of names and returns a list of piddles that
provide access to the data shared under those names. In scalar context the
function returns the piddle corresponding with the first named data set,
which is usually what you mean when you use a single name. If you specify
multiple names but call it in scalar context, you will get a warning
indicating that you probably meant to say something differently.

=for example

 my $local_copy = retrieve_pdls('foo');
 my @both_piddles = retrieve_pdls('foo', 'bar');
 my ($foo, $bar) = retrieve_pdls('foo', 'bar');

=for bad

C<retrieve_pdls> does not pay attention to bad values. There is no technical
reason for this: it simply hadn't occurred to me until I had to write the
bad-data documentation. Expect it to happen in a forthcoming release. :-)

=head2 free_pdls

=for ref

Frees the shared memory (if any) associated with the named shared data.

=for usage

  free_pdls(name, name, ...)

This function marks the memory associated with the given names as no longer
being shared, handling all reference counting and other low-level stuff.
You generally won't need to worry about the return value. But if you care,
you get a list of values---one for each name---where a successful removal
gets the name and an unsuccessful removal gets an empty string.

So, if you say C<free_pdls('name1', 'name2')> and both removals were
successful, you will get C<('name1', 'name2')> as the return values. If
there was trouble removing C<name1> (because there is no memory associated
with that name), you will get C<('', 'name2')> instead. This means you
can handle trouble with perl C<grep>s and other conditionals:

 my @to_remove = qw(name1 name2 name3 name4);
 my @results = free_pdls(@to_remove);
 if (not grep {$_ eq 'name2'} @results) {
     print "That's weird; did you remove name2 already?\n";
 }
 if (not $results[2]) {
     print "Couldn't remove name3 for some reason\n";
 }

=for bad

This function simply removes a piddle's memory from the shared pool. It
does not interact with bad values in any way. But then again, it does not
interfere with or screw up bad values, either.

=head1 DIAGNOSTICS

=over

=item C<< share_pdls: expected key/value pairs >>

You called C<share_pdl> with an odd number of arguments, which means that
you could not have supplied key/value pairs. Double-check that every piddle
(or filename) that you supply is preceeded by it's shared name.

=item C<< share_pdls: you already have data associated with '$name' >>

You tried to share some data under C<$name>, but some data is already
associated with that name. Typo? You can avoid namespace clashes with other
modules by using simple names and letting C<PDL::Parallel::threads> mangle
the name internally for you.

=item C<< share_pdls: Could not share a piddle under name '$name' because ... >>

=over

=item C<< ... the piddle is a slice. >>

You tried to share a slice, which is not allowed. Try C<sever>ing or
C<copy>ing your slice, then share it.

=item C<< ... the piddle does not have any allocated memory (but is not a
slice?). >>

You tried to share a piddle that does not have any memory associated with it.
I'm actually not sure how you can do this, so if you managed to create such
a piddle, you probably already know what's going on. :-)

=item C<< ... the piddle has no datasv, which means it's probably a special
piddle. >>

You tried to share a piddle that has no datasv. This usually happens when
you try to wrap a piddle around some externally provided data. It may also
happen when you've managed to get data from L<PDL::IO::FastRaw> and you've
used the wrong loading order (see L</Memory Mapped Data>), or perhaps when
you try to share data that you've mapped using L<PDL::IO::FlexRaw>.

=item C<< ... the piddle's data does not come from the datasv. >>

You tried to share a piddle that has a funny internal structure, in which
the data does not point to the buffer portion of the datasv. I'm not sure
how that could happen without triggering a more specific error, so I hope
you know what's going on if you get this. :-)

=back

=item C<< When share_pdls gets a scalar, it expects that to be a file to share
as memory mapped data. For key '$name', '$to_store' was given, but ... >>

=over

=item C<< ... there is no associated header file >>

The header file must have the name "$to_store.hdr". If it doesn't, this
module won't be able to map the file.

=item C<< ... you do not have permissions to read the associated header
file >>

There seems to be a permissions issue and this module cannot open the
header file associated with your mapped data. Check the permissions?

=item C<< ... you do not have write permissions for that file >>

Yes, ostensibly you can work with a memory mapped file that is read only,
but that's complicated and I didn't want to have to figure out how to mark
your shared piddle as read-only. Patches welcome!

=item C<< ... the file does not exist >>

The file to memory map doesn't exist. Typo, perhaps?

=back

=item C<< share_pdls passed data under '$name' that it doesn't know how to
store >>

C<share_pdls> only knows how to store memory mapped files and raw data
piddles. It'll croak if you try to share other kinds of piddles, and it'll
throw this error if you try to share anythin else, like a hashref.

=item C<< retrieve_pdls: '$name' was created in a thread that has ended or
is detached >>

In some other thread, you added some data to the shared pool. If that thread
ended without you freeing that data (or the thread has become a detached
thread), then we cannot know if the data is available. You should always
free your data from the data pool when you're done with it, to avoid this
error.

=item C<< retrieve_pdls could not find data associated with '$name' >>

Pretty simple: either data has never been added under this name, or data
under this name has been removed.

=item C<< retrieve_pdls: requested many piddles... in scalar context? >>

This is just a warning. You requested multiple piddles (sent multiple names)
but you called the function in scalar context. Why do such a thing?

=back

=head1 LIMITATIONS

I have tried to make it clear, but in case you missed it, this module does
not let you share slices or specially marked piddles. If you need to share a
slice, you should C<sever> or C<copy> the slice first.

Another limitation is that you cannot share memory mapped files that require
features of L<PDL::IO::FlexRaw>. That is a cool module that lets you pack
multiple piddles into a single file, but simple cross-thread sharing is not
trivial and is not (yet) supported.

If you are dealing
with a physical piddle (i.e. not memory mapped), you have to be a bit careful
about how the memory gets freed. If you don't call C<free_pdls> on the data,
it will persist in memory until the end of the originating thread, which
means you have a classic memory leak. On the other hand, if another thread
creates a thread-local copy of the data before the originating thread ends,
but then tries to access the data after the originating thread ends, you
will get a segmentation fault.

Finally, you B<must> load C<PDL::Parallel::threads> before loading
L<PDL::IO::FastRaw> if you wish to share your memory mapped piddles. Also,
you must have a C<.hdr> file for your data file, which is not strictly
necessary when using C<mapfraw>. Hopefully that limitation will be lifted
in forthcoming releases of this module.

=head1 BUGS

None known at this point.

=head1 SEE ALSO

L<PDL::Parallel::CPU>, L<MPI>, L<PDL::Parallel::MPI>, L<OpenCL>, L<threads>,
L<threads::shared>

=head1 AUTHOR, COPYRIGHT, LICENSE

This module was written by David Mertens. The documentation is copyright (C)
David Mertens, 2012. The source code is copyright (C) Northwestern University,
2012. All rights reserved.

This module is distributed under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

Parallel computing is hard to get right, and it can be exacerbated by errors
in the underlying software. Please do not use this software in anything that
is mission-critical unless you have tested and verified it yourself. I cannot
guarantee that it will perform perfectly under all loads. I hope this is
useful and I wish you well in your usage thereof, but BECAUSE THIS SOFTWARE
IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE
EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING
THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS"
WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT
NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE
COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL
ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE
THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED
TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU
OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

