# NAME

Net::RFC::Search - search for RFC's and dump RFC's content either to a variable or to a file.

# SYNOPSIS

Net::RFC::Search provides 2 methods:

**search_by_header('keyword')** is for searching for a RFC index number by given 'keyword' (through RFC index text file).

**get_by_index($index_number)** is for dumping RFC's content either to a variable or to a file.

    use Net::RFC::Search;

    my $rfc = Net::RFC::Search->new;

    # This will return array of RFC indices with "websocket" keyword in their headers.
    my @found = $rfc->search_by_header('WebSocket');

    # This will dump content of RFC 6455 into $rfc_text variable.
    my $rfc_text = $rfc->get_by_index(6455);

    # Dumps RFC 6455 into /tmp/6455.txt file
    $rfc->get_by_index(6455, '/tmp/6455.txt');

# VERSION

Version 0.02

# DESCRIPTION

Net::RFC::Search is a module aimed to be a simple tool to search and dump RFC's.

# CONSTRUCTOR

- new(%options)

    Create instance of Net::RFC::Search.

    **%options** are optional parameters:

    *indexpath* - a file name to store RFC index file into. Defaults to ~/.rfcindex

    *rfcbaseurl* - URL of the RFC site/mirror where index file and RFC's are going to be downloaded from.

# METHODS

- **search_by_header("keyword")**

    Returns array of RFC index numbers "keyword" has been found in.

    Search occurs in RFC header names (i.e. through RFC index file).

- **get_by_index($index [, $filename ])**

    Downloads RFC of index number C<$index> and returns downloaded content.

    By providing optional C<$filename> content will be dumped into C<$filename>.

# TODO

- add caching facilities

- do not rely on LWP::UserAgent only, add lynx/curl as optional methods to retrieve RFC's

# ACKNOWLEDGEMENTS

This module is heavily based on rfc.pl script written by **Derrick Daugherty** (http://www.dewn.com/rfc/)

# AUTHOR

Nikolay Aviltsev, `navi@cpan.org`

# LICENSE AND COPYRIGHT

Copyright 2013 Nikolay Aviltsev.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See <http://dev.perl.org/licenses/> for more information.
