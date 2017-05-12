package Sort::External;
use strict;
use warnings;

use 5.006_001;

our $VERSION = '0.18';

use XSLoader;
XSLoader::load( 'Sort::External', $VERSION );

use File::Temp;
use Fcntl qw( :DEFAULT );
use Carp;

our %instance_vars = (
    sortsub        => undef,
    working_dir    => undef,
    cache_size     => 0,
    mem_threshold  => 1024**2 * 8,
    line_separator => undef,         # no-op, backwards compatibility only
);

# Maximum number of runs that SortEx object is allowed without triggering
# multi-level consolidation at finish().
our $MAX_RUNS = 30;

sub new {
    my $class = shift;
    $class = ref($class) || $class;

    # Process labeled params.
    my %args = %instance_vars;
    while (@_) {
        my ( $var, $val ) = ( shift, shift );
        # Back compat: labeled params used to start with a dash.
        $var =~ s/^-//;
        croak("Illegal parameter: '$var'") unless exists $args{$var};
        $args{$var} = $val;
    }

    # Verify that supplied working directory is valid.
    if ( defined $args{working_dir} ) {
        croak("Invalid working_dir '$args{working_dir}'")
            unless -d $args{working_dir};
    }

    # Open a temp file.
    my $tempfile_fh = File::Temp->new(
        DIR    => $args{working_dir},
        UNLINK => 1,
    );

    return _new( $class, $args{working_dir}, $args{sortsub}, $args{cache_size},
        $args{mem_threshold}, $tempfile_fh );
}

my %finish_defaults = (
    outfile => undef,
    flags   => ( O_CREAT | O_EXCL | O_WRONLY ),
);

sub finish {
    my $self = shift;
    my $runs = $self->_get_runs;

    # If we've never flushed the cache, perform the final sort in-memory.
    if ( !@$runs ) {
        my $item_cache = $self->_get_item_cache;
        my $sortsub    = $self->_get_sortsub;
        @$item_cache
            = $sortsub ? sort $sortsub @$item_cache : sort @$item_cache;
    }
    else {
        $self->_write_item_cache_to_tempfile;
        while ( @$runs > $MAX_RUNS ) { 
            $self->_consolidate;
        }
    }

    # If called with arguments, we must be printing everything to an outfile.
    if (@_) {
        # Verify args.
        my %args = %finish_defaults;
        while (@_) {
            my ( $var, $val ) = ( shift, shift );
            # Back compat: labeled params used to start with a dash.
            $var =~ s/^-//;
            croak("Illegal parameter: '$var'")
                unless exists $finish_defaults{$var};
            $args{$var} = $val;
        }

        # Get an outfile and print everything to it.
        croak('Argument outfile is required') unless defined $args{outfile};
        sysopen( my $out_fh, $args{outfile}, $args{flags} )
            or croak("Couldn't open outfile '$args{outfile}': $!");
        $self->_finish_to_filehandle($out_fh);
        close $out_fh or croak("Couldn't close '$args{outfile}': $!");
    }
}

sub _finish_to_filehandle {
    my ( $self, $fh ) = @_;
    my $item_cache = $self->_get_item_cache;
    do {
        print $fh $_ for @$item_cache;
        @$item_cache = ();
        $self->_gatekeeper; # Refreshes @$item_cache.
    } while (@$item_cache);
}

sub _consolidate {
    my $self = shift;
    my $item_cache = $self->_get_item_cache;
    my $runs = $self->_get_runs;
    my $fh   = File::Temp->new(
        DIR    => $self->_get_working_dir,
        UNLINK => 1,
    );
    my @to_consolidate = @$runs;
    @$runs = ();
    my @consolidated;
    while (@to_consolidate) {
        my $num_to_splice = @to_consolidate < 10 ? @to_consolidate : 10;
        push @$runs, splice( @to_consolidate, 0, 10 );
        my $start = tell $fh;
        do {
            $self->_print_to_sortfile( $item_cache, $fh );
            @$item_cache = ();
            $self->_gatekeeper;    # Refreshes @$item_cache.
        } while (@$item_cache);
        my $run = Sort::External::SortExRun->_new( $fh, $start, tell($fh) );
        push @consolidated, $run;
        @$runs = ();
    }
    @$runs = @consolidated;
    $self->_set_temp_fh($fh);
}

# Reload the main cache using elements from the individual run caches.
# 
# Examine all SortExRun objects, making sure that they have at least one
# recovered element in memory.  Find the element among the run caches which we
# can guarantee sorts before any element yet to be recovered from disk.  Move
# all elements from the run caches which sort before or equal to this cutoff
# into the main object's cache.
sub _gatekeeper {
    my $self       = shift;
    my $runs       = $self->_get_runs;
    my $item_cache = $self->_get_item_cache;
    my $sortsub    = $self->_get_sortsub;

    # Discard exhausted runs.
    @$runs = grep { $#{ $_->_get_buffarray } != -1 or $_->_refill_buffer } @$runs;

    if ( @$runs == 0 ) {
        @$item_cache = ();
    }
    elsif ( @$runs == 1 ) {
        # If there's only one SortExRun, no need to sort.
        my $run       = $runs->[0];
        my $buffarray = $run->_get_buffarray;
        $run->_set_buffarray( [] );
        @$item_cache = @$buffarray;
    }
    else {
        # Choose the cutoff from among the lowest elements present in each 
        # run's cache.
        my @on_the_bubble = map { $_->_get_buffarray->[-1] } @$runs;
        @on_the_bubble
            = $sortsub
            ? sort $sortsub @on_the_bubble
            : sort @on_the_bubble;
        my $cutoff = $on_the_bubble[0];

        # Let all qualified items into the out_batch.
        my @out_batch;
        for my $run (@$runs) {
            my $buffarray = $run->_get_buffarray;
            my $tick = $self->_define_range( $buffarray, $cutoff );
            next if $tick == -1;
            my $num_to_splice = $tick + 1;
            push @out_batch, splice( @$buffarray, 0, $num_to_splice );
        }

        # Refresh the item cache and prepare to return elements.
        @$item_cache = $sortsub ? sort $sortsub @out_batch : sort @out_batch;
    }

    $self->_set_fetch_tick(0);
    return;
}

# Compare two elements using either standard lexical comparison or the sortsub
# provided to the object's constructor.
sub _compare {
    my ( $self, $item_a, $item_b ) = @_;
    my $sortsub = $self->_get_sortsub;
    if ( defined $sortsub ) {
        local $a = $item_a;
        local $b = $item_b;
        return $sortsub->( $a, $b );
    }
    else {
        return $item_a cmp $item_b;
    }
}

# Flush the items in the input cache to a tempfile, sorting as we go.
sub _write_item_cache_to_tempfile {
    my $self       = shift;
    my $item_cache = $self->_get_item_cache;
    my $sortsub    = $self->_get_sortsub;

    return unless @$item_cache;

    # Print the sorted cache to the tempfile.
    @$item_cache = $sortsub ? sort $sortsub @$item_cache : sort @$item_cache;
    my $tempfile_fh = $self->_get_tempfile_fh;
    my $start       = tell($tempfile_fh);
    $self->_print_to_sortfile( $item_cache, $tempfile_fh );

    # Add a SortExRun object to the runs array.
    my $run = Sort::External::SortExRun->_new( $tempfile_fh, $start,
        tell($tempfile_fh) );
    push @{ $self->_get_runs }, $run;

    # Reset cache variables.
    $self->_set_mem_bytes(0);
    $#$item_cache = -1;
}

# Return the highest index in an array representing an element lower than
# a given cutoff.
sub _define_range {
    my ( $self, $array, $target ) = @_;
    my ( $lo, $mid, $hi ) = ( 0, 0, $#$array );

    # Binary search.
    while ( $hi - $lo > 1 ) {
        $mid = ( $lo + $hi ) >> 1;
        my $delta = $self->_compare( $array->[$mid], $target );
        if    ( $delta < 0 ) { $lo = $mid }
        elsif ( $delta > 0 ) { $hi = $mid }
        elsif ( $delta == 0 ) { $lo = $hi = $mid }
    }

    # Get that last item in...
    while ( $mid < $#$array
        and $self->_compare( $array->[ $mid + 1 ], $target ) < 1 )
    {
        $mid++;
    }
    while ( $mid >= 0 and $self->_compare( $array->[$mid], $target ) > 0 ) {
        $mid--;
    }

    return $mid;
}

1;

__END__

=head1 NAME

Sort::External - Sort huge lists.

=head1 SYNOPSIS

    my $sortex = Sort::External->new( mem_threshold => 1024**2 * 16 );
    while (<HUGEFILE>) {
        $sortex->feed($_);
    }
    $sortex->finish;
    while ( defined( $_ = $sortex->fetch ) ) {
        do_stuff_with($_);
    }

=head1 DESCRIPTION

Problem: You have a list which is too big to sort in-memory.  

Solution: "feed, finish, and fetch" with Sort::External, the closest thing to
a drop-in replacement for Perl's sort() function when dealing with
unmanageably large lists.

=head2 How it works

Cache sortable items in memory.  Periodically sort the cache and flush it to
disk, creating a sorted "run".  Complete the sort by sorting the input cache
and any existing runs into an output stream.

Note that if Sort::External hasn't yet flushed the cache to disk when finish()
is called, the whole operation completes in-memory.

In the CompSci world, "internal sorting" refers to sorting data in RAM, while
"external sorting" refers to sorting data which is stored on disk, tape,
punchcards, or any storage medium except RAM -- hence, this module's name.

=head2 Stringification

Items fed to Sort::External will be returned in stringified form (assuming
that the cache gets flushed at least once): C<$foo = "$foo">.  Since this is
unlikely to be desirable when objects or deep data structures are involved,
Sort::External throws an error if you feed it anything other than simple
scalars.

Expert note: Sort::External does a little extra bookkeeping to sustain each
item's taint and UTF-8 flags through the journey to disk and back.

=head1 METHODS

=head2 new()

    my $sortscheme = sub { $Sort::External::b <=> $Sort::External::a };
    my $sortex = Sort::External->new(
        mem_threshold   => 1024**2 * 16,     # default: 1024**2 * 8 (8 MiB)
        cache_size      => 100_000,          # default: undef (disabled) 
        sortsub         => $sortscheme,      # default sort: standard lexical
        working_dir     => $temp_directory,  # default: see below
    );

Construct a Sort::External object.

=over

=item 

B<mem_threshold> - Allow the input cache to consume approximately
C<mem_threshold> bytes before sorting it and flushing to disk.  Experience
suggests that the optimum setting is somewhere in the range of 1-16 MiB.

=item 

B<cache_size> - Specify a hard limit for the input cache in terms of
sortable items.  If set, overrides C<mem_threshold>. 

=item 

B<sortsub> -- A sorting subroutine.  Be advised that you MUST use
$Sort::External::a and $Sort::External::b instead of $a and $b in your sub.
Before deploying a sortsub, consider using a GRT instead, as described in the
L<Sort::External::Cookbook|Sort::External::Cookbook> -- it's probably a lot
faster.

=item 

B<working_dir> - The directory where the temporary sortfile will reside.
By default, the location of the sortfile is determined by the behavior of
L<File::Temp|File::Temp>'s constructor.

=back

=head2 feed()

    $sortex->feed(@items);

Feed one or more sortable items to your Sort::External object.  It is normal
for occasional pauses to occur during feeding as caches are flushed.

=head2 finish() 

    # if you intend to call fetch...
    $sortex->finish; 
    
    # otherwise....
    use Fcntl;
    $sortex->finish( 
        outfile => 'sorted.txt',
        flags => ( O_CREAT | O_WRONLY ),
    );

Prepare to output items in sorted order.

If you specify the parameter C<outfile>, Sort::External will attempt to write
your sorted list to that location.  By default, Sort::External will refuse to
overwrite an existing file; if you want to override that behavior, you can
pass Fcntl flags to finish() using the optional C<flags> parameter.

Note that you can either finish() to an outfile, or finish() then fetch()...
but not both.  

=head2 fetch()

    while ( defined( $_ = $sortex->fetch ) ) {
        do_stuff_with($_);
    }

Fetch the next sorted item.  

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sort-external@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sort-External>.

=head1 SEE ALSO

The L<Sort::External::Cookbook|Sort::External::Cookbook>.

L<File::Sort|File::Sort>, L<File::MergeSort|File::MergeSort>, and 
L<Sort::Merge|Sort::Merge> as possible alternatives.

=head1 AUTHOR

Marvin Humphrey E<lt>marvin at rectangular dot comE<gt>
L<http://www.rectangular.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2008 Marvin Humphrey.  All rights reserved.
This module is free software.  It may be used, redistributed and/or 
modified under the same terms as Perl itself.

=cut

