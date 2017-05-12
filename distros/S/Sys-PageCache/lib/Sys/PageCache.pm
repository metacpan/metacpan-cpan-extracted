package Sys::PageCache;

use strict;
use warnings;
use 5.008001;
use Carp;
use base qw(Exporter);
our @EXPORT = qw(page_size fincore fadvise
                 POSIX_FADV_NORMAL
                 POSIX_FADV_SEQUENTIAL
                 POSIX_FADV_RANDOM
                 POSIX_FADV_NOREUSE
                 POSIX_FADV_WILLNEED
                 POSIX_FADV_DONTNEED
            );
our @EXPORT_OK = qw();

our $VERSION = '0.03';

use POSIX;

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub fincore {
    my($file, $offset, $length) = @_;

    if (! $offset) {
        $offset = 0;
    } elsif ($offset < 0) {
        croak "offset must be >= 0";
    } else {
        my $pa_offset = $offset & ~(page_size() - 1);
        if ($pa_offset != $offset) {
            carp(sprintf "[WARN] offset must be a multiple of the page size so change %llu to %llu",
                 $offset,
                 $pa_offset,
             );
            $offset = $pa_offset;
        }
    }

    my $fsize = (stat $file)[7];
    if (! $length) {
        $length = $fsize;
    } elsif ($length > $fsize - $offset) {
        my $new_length = $fsize - $offset;
        carp(sprintf "[WARN] fincore: length(%llu) is greater than file size(%llu) - offset(%llu). so use file size - offset (=%llu)",
             $length,
             $fsize,
             $offset,
             $new_length,
         );
        $length = $new_length;
    }

    open my $fh, '<', $file or croak $!;
    my $fd = fileno $fh;

    my($r, $e);
    {
        local $@;
        $r = eval {
            _fincore($fd, $offset, $length);
        };
        chomp($e = $@) if $@;
    }
    close $fh;

    if (defined $e) {
        carp $e;
        return;
    }

    $r->{file_size}   = $fsize;
    $r->{total_pages} = ceil($fsize / $r->{page_size});

    return $r;
}

sub fadvise {
    my($file, $offset, $length, $advice) = @_;

    croak "missing advice" unless defined $advice;
    croak "missing length" unless defined $length;
    croak "missing offset" unless defined $offset;
    croak "missing file"   unless defined $file;

    croak "offset must be >= 0" if $offset < 0;

    my $fsize = (stat $file)[7];
    if ($length > $fsize - $offset) {
        my $new_length = $fsize - $offset;
        carp(sprintf "[WARN] fadvise: length(%llu) is greater than file size(%llu) - offset(%llu). so use file size - offset (=%llu)",
             $length,
             $fsize,
             $offset,
             $new_length,
         );
        $length = $new_length;
    }

    open my $fh, '<', $file or croak $!;
    my $fd = fileno $fh;

    my($r, $e);
    {
        local $@;
        $r = eval {
            _fadvise($fd, $offset, $length, $advice);
        };
        chomp($e = $@) if $@;
    }
    close $fh;

    if (defined $e) {
        carp $e;
        return;
    }

    return $r == 0 ? 1 : ();
}

1;
__END__

=encoding utf-8

=begin html

<a href="https://travis-ci.org/hirose31/Sys-PageCache"><img src="https://travis-ci.org/hirose31/Sys-PageCache.png?branch=master" alt="Build Status" /></a>
<a href="https://coveralls.io/r/hirose31/Sys-PageCache?branch=master"><img src="https://coveralls.io/repos/hirose31/Sys-PageCache/badge.png?branch=master" alt="Coverage Status" /></a>

=end html

=head1 NAME

Sys::PageCache - handling page cache related on files

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

=end readme

=head1 SYNOPSIS

    use Sys::PageCache;
    
    # determine whether pages are resident in memory
    $r = fincore "/path/to/file";
    printf("cached/total_size=%llu/%llu cached/total_pages=%llu/%llu\n",
           $r->{cached_size}, $r->{file_size},
           $r->{cached_pages}, $r->{total_pages},
       );
    
    # free cached pages on a file
    $r = fadvise "/path/to/file", 0, 0, POSIX_FADV_DONTNEED;

=head1 DESCRIPTION

Sys::PageCache is for handling page cache related on files.

=head1 METHODS

=over 4

=item B<fincore>($filepath:Str [, $offset:Int [, $length:Int]])

Determine whether pages are resident in memory.
C<$offset> and C<$length> are optional.

C<fincore> returns a following hash ref.

    {
       cached_pages => Int, # number of cached pages
       cached_size  => Int, # size of cached pages
       total_pages  => Int, # number of pages if cached whole file
       file_size    => Int, # size of file
       page_size    => Int, # page size on your system
    }


=item B<fadvise>($filepath:Str, $offset:Int, $length:Int, $advice:Int)

Call posix_fadvise(2).

C<fadvise> returns 1 if success.

=item B<page_size>()

Returns size of page size on your system.

=back

=head1 EXPORTS

=over 4

=item fincore

=item fadvise

=item POSIX_FADV_NORMAL

=item POSIX_FADV_SEQUENTIAL

=item POSIX_FADV_RANDOM

=item POSIX_FADV_NOREUSE

=item POSIX_FADV_WILLNEED

=item POSIX_FADV_DONTNEED

=back

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 REPOSITORY

L<https://github.com/hirose31/Sys-PageCache>

  git clone git://github.com/hirose31/Sys-PageCache.git

patches and collaborators are welcome.

=head1 SEE ALSO

mincore(2), posix_fadvise(2),
L<https://code.google.com/p/linux-ftools/>,
L<https://github.com/nhayashi/pagecache-tool>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
