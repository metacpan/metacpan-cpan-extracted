package Solaris::Vmem;

use 5.006;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Solaris::Vmem ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
   alloc
   release
   trim
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
   alloc
   release
   trim
);
our $VERSION = '0.01';

bootstrap Solaris::Vmem $VERSION;

# Preloaded methods go here.

1;
__END__

=head1 NAME

Solaris::Vmem - Perl interface to virtual memory allocator

=head1 SYNOPSIS

  use Solaris::Vmem;

  $size = alloc($tie, 16384);
  $size = trim($tie, 8192);
  release($tie);

=head1 DESCRIPTION

   Modern applications tend to consume more and more memory as more memory and computer power 
   become available, so the importance of large array handling has been increasing. Also, the 
   relative importance of memory efficiency is becoming higher and higher because CPU speeds 
   are increasing much faster than memory access speeds. 
   Here is one way to better address the issue, especially for large arrays in the 64-bit mode 
   applications. The idea presented here is to use the virtual memory page-demand capabilities built 
   into the Solaris platform or any modern operating system (OS). 
   The solution to the problem of undersized malloc-allocated arrays is to create much bigger arrays, but 
   to do so without incurring the costs in memory (swap space) that malloc requires. This is what 
   Virtual Memory Arrays provide. Developers can create very large arrays that have the same 
   performance characteristics as normal malloc-allocated memory, but without the need to consume 
   the resources up front. 
   
   The Solaris::Vmem package allows you to reserve a large amount of virtual address space for 
   an array of arbitrary objects, without reserving the memory or swap space for it. The actual 
   memory (swap) allocation occurs lazily, that is, only when you fill the memory with data, 
   page by page. The particular implementation presented here is for Solaris systems running on UltraSPARC 
   processors. 
   Note that in Virtual Memory (VM) system environments malloc also does not allocate memory until that 
   memory is filled with data. However, malloc does reserve the memory (swap space) for each allocation. 
   Therefore, if you allocate a large amount of memory with malloc, you must have enough swap space to 
   support it, or else malloc will return NULL. Virtual Memory Arrays do not reserve memory (swap space), 
   allowing you to create virtual arrays much larger than the available memory (swap space). 
   
   This difference is especially important in the 64-bit mode where Solaris::Vmem allows you to reserve 
   many terabytes of virtual address space. Creating enough disk swap space to support this much address 
   space (not to mention physical memory) is impractical even with today's inexpensive disks. 
   The proposed Virtual Memory Arrays API consists of three routines, the first two of which 
   resemble traditional malloc-free. The following are the prototypes and brief descriptions of these functions. 
   
      $size = alloc($var, $req_size);
   
   alloc() allocated a chunk of virtual address space of a given size, in bytes. On success, alloc() 
   returns the actual size of the memory chunk and "ties" the $var argument to the allocated space. 
   The VM system will allocate memory for this array, page by page, as you fill the array with data. 
   The $req_size value is rounded up to the next hardware page boundary. 
   
      release($var);
   
   release() destroys the virtual memory space associated with $var argument and returns any memory and 
   the virtual address space reserved for it back to the system. 
   
      $newsize = trim($var, $req_size);
   
   trim() reduces the size of the given virtual memory chunk to a smaller virtual size (in bytes). 
   This routine is optional. It may be useful when you have filled the array with data and know that 
   you will not need any more memory than you've already allocated and filled. The $req_size value 
   is rounded up to the next page boundary. The funcation returns the new (actual) size of the virtual 
   memory chunk.
   The trim() function allows you to return some virtual address space in the back to the system. 
   If you have put any data into the range of addresses past the end of the "trimmed" memory chunk, 
   it will free the corresponding memory, such that the data there will no longer be available. 
   Calling this routine only has an effect if $req_size (rounded up to the next page boundary) is 
   smaller than the original virtual size. 
   Once you've trimmed a virtual memory chunk with trim(), you can't grow it any more by adding data 
   to its end. Any reference beyond the $newsize boundary will result in a fault. It's a good idea to 
   trim a chunk of memory only if you are reasonably sure you won't ever need to expand this array again. 
   
=head2 EXPORT
   alloc
   release
   trim

=head1 AUTHOR

Alexander Golomshtok, E<lt>golomshtok_alexander@jpmorgan.comE<gt>
Based on the vmem_array package by Greg Nakhimovsky, Sun Microsystems

=head1 SEE ALSO

L<perl>, L<http://developers.sun.com/solaris/articles/virtual_memory_arrays.html>

=cut
