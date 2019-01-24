<div>
    <a href="https://travis-ci.org/hirose31/Sys-PageCache"><img src="https://travis-ci.org/hirose31/Sys-PageCache.png?branch=master" alt="Build Status" /></a>
    <a href="https://coveralls.io/r/hirose31/Sys-PageCache?branch=master"><img src="https://coveralls.io/repos/hirose31/Sys-PageCache/badge.png?branch=master" alt="Coverage Status" /></a>
</div>

# NAME

Sys::PageCache - handling page cache related on files

# SYNOPSIS

    use Sys::PageCache;
    
    # determine whether pages are resident in memory
    $r = fincore "/path/to/file";
    printf("cached/total_size=%llu/%llu cached/total_pages=%llu/%llu\n",
           $r->{cached_size}, $r->{file_size},
           $r->{cached_pages}, $r->{total_pages},
       );
    
    # free cached pages on a file
    $r = fadvise "/path/to/file", 0, 0, POSIX_FADV_DONTNEED;

# DESCRIPTION

Sys::PageCache is for handling page cache related on files.

# METHODS

- **fincore**($filepath:Str \[, $offset:Int \[, $length:Int\]\])

    Determine whether pages are resident in memory.
    `$offset` and `$length` are optional.

    `fincore` returns a following hash ref.

        {
           cached_pages => Int, # number of cached pages
           cached_size  => Int, # size of cached pages
           total_pages  => Int, # number of pages if cached whole file
           file_size    => Int, # size of file
           page_size    => Int, # page size on your system
        }

- **fadvise**($filepath:Str, $offset:Int, $length:Int, $advice:Int)

    Call posix\_fadvise(2).

    `fadvise` returns 1 if success.

- **page\_size**()

    Returns size of page size on your system.

# EXPORTS

- fincore
- fadvise
- POSIX\_FADV\_NORMAL
- POSIX\_FADV\_SEQUENTIAL
- POSIX\_FADV\_RANDOM
- POSIX\_FADV\_NOREUSE
- POSIX\_FADV\_WILLNEED
- POSIX\_FADV\_DONTNEED

# AUTHOR

HIROSE Masaaki <hirose31 \_at\_ gmail.com>

# REPOSITORY

[https://github.com/hirose31/Sys-PageCache](https://github.com/hirose31/Sys-PageCache)

    git clone git://github.com/hirose31/Sys-PageCache.git

patches and collaborators are welcome.

# SEE ALSO

mincore(2), posix\_fadvise(2),
[https://code.google.com/p/linux-ftools/](https://code.google.com/p/linux-ftools/),
[https://github.com/nhayashi/pagecache-tool](https://github.com/nhayashi/pagecache-tool)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
