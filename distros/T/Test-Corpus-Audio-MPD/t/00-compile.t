#!perl
#
# This file is part of Test-Corpus-Audio-MPD
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use Test::More tests => 1;

eval "use Test::Corpus::Audio::MPD";
SKIP: {
    skip "module is expected to fail under some circumstance", 1
        if $@ =~ /mpd not installed|installed mpd is not music player daemon|mpd is running/;
    is( $@, '', "module loads ok" );
}
