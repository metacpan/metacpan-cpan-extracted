#!/usr/bin/env perl

use strict;
use warnings;

use Open::This        qw( to_editor_args );
use Test::Differences qw( eq_or_diff );
use Test::More import => [qw( done_testing )];
use Test::Warnings ();

my @editors = ( 'code', 'codium' );

for my $editor (@editors) {

    local $ENV{EDITOR} = $editor;

    eq_or_diff(
        [ to_editor_args('t/git.t') ],
        [ '--goto', 't/git.t', ],
        $editor . ' filename'
    );

    eq_or_diff(
        [ to_editor_args('t/git.t:10') ],
        [ '--goto', 't/git.t:10', ],
        $editor . ' line'
    );

    eq_or_diff(
        [ to_editor_args('t/git.t:10:22') ],
        [ '--goto', 't/git.t:10:22', ],
        $editor . ' line and column'
    );

}
done_testing();
