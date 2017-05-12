use 5.006;
use strict;
use warnings;
use Test::More 0.92;
use Test::Filename 0.03;
use Path::Tiny;
use File::Temp;
use File::pushd qw/pushd/;

use lib 't/lib';
use PCNTest;

use Path::Iterator::Rule;

#--------------------------------------------------------------------------#

{
    my ( $rule, @files );

    my $td = make_tree(qw(file1.txt));
    path( $td, 'file2.txt' )->spew( map "$_\n", qw( foo bar baz ) );
    path( $td, 'file3.txt' )->spew(qw( foo bar baz ));
    path( $td, 'file4.txt' )->spew_utf8("\x{2603}");

    is_deeply(
        [
            map { unixify( $_, $td ) }
              Path::Iterator::Rule->new->file->line_match(qr{foo.*baz}s)->all($td)
        ],
        ['file3.txt'],
    );

    is_deeply(
        [
            map { unixify( $_, $td ) }
              Path::Iterator::Rule->new->file->not_line_match( ":encoding(iso-8859-1)",
                qr{foo.*baz}s )->all($td)
        ],
        [qw/file1.txt file2.txt file4.txt/],
    );

    is_deeply(
        [
            map { unixify( $_, $td ) }
              Path::Iterator::Rule->new->file->contents_match(qr{foo.*baz}s)->all($td)
        ],
        [qw/file2.txt file3.txt/],
    );

    is_deeply(
        [
            map { unixify( $_, $td ) }
              Path::Iterator::Rule->new->file->not_contents_match(qr{foo.*baz}s)->all($td)
        ],
        [qw/file1.txt file4.txt/],
    );

    # encoding stuff
    is_deeply(
        [
            map { unixify( $_, $td ) }
              Path::Iterator::Rule->new->file->contents_match(qr{\x{2603}}s)->all($td)
        ],
        ['file4.txt']
    );

    is_deeply(
        [
            map { unixify( $_, $td ) }
              Path::Iterator::Rule->new->file->contents_match( ":encoding(iso-8859-1)",
                qr{\x{2603}}s )->all($td)
        ],
        []
    );

    is_deeply(
        [
            map { unixify( $_, $td ) }
              Path::Iterator::Rule->new->file->contents_match( ":encoding(iso-8859-1)",
                qr{\x{E2}\x{98}\x{83}}s )->all($td)
        ],
        ['file4.txt']
    );
}

done_testing;
#
# This file is part of Path-Iterator-Rule
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: ts=4 sts=4 sw=4 et:
