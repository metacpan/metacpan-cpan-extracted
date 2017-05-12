use strict;
use warnings;

use Test::More tests => 353;

BEGIN { use_ok 'Range::Object::Serial' };

my $tests = eval do { local $/; <DATA>; };
die "Data eval error: $@" if $@;

die "Nothing to test!" unless $tests;

require 't/tests.pl';

run_tests( $tests );

__DATA__
[
    'Range::Object::Serial' => [
        # Custom code
        undef,

        # Invalid input
        [ '1, 2, 5; 7-10; foo', 'bar', 'baz', -1, undef ],

        # Valid input
        [ '0, 1, 2, 5; 7-10, 15..20', 30, '40..50' ],

        # Valid in() items
        [ qw(0 1 2 5 7 8 9 10 15 16 17 18 19 20 30 40
             41 42 43 44 45 46 47 48 49 50)],

        # Not in() input
        [ qw(3 4 6 11 12 13 14 21 22 23 24 25 26
             27 28 29 31 32 33 34 35 36 37 38 39) ],

        # Not in() output
        [ qw(3 4 6 11 12 13 14 21 22 23 24 25 26
             27 28 29 31 32 33 34 35 36 37 38 39) ],

        # List context range() output
        [ qw(0 1 2 5 7 8 9 10 15 16 17 18 19 20 30 40 41
             42 43 44 45 46 47 48 49 50) ],

        # Scalar context range() output
        '0,1,2,5,7,8,9,10,15,16,17,18,19,20,30,40,'.
        '41,42,43,44,45,46,47,48,49,50',

        # List context collapsed() output
        [ { start => 0,  end => 2,  count => 3  }, 5,
          { start => 7,  end => 10, count => 4  },
          { start => 15, end => 20, count => 6  }, 30,
          { start => 40, end => 50, count => 11 }, ],

        # Scalar context collapsed() output
        '0-2,5,7-10,15-20,30,40-50',

        # Initial range size()
        26,

        # add() input
        [ '101;105-107', 110, 115..118 ],

        # Valid in() items after add()
        [ qw(0 1 2 5 7 8 9 10 15 16 17 18 19 20 30 40 41
             42 43 44 45 46 47 48 49 50 101 105 106 107
             110 115 116 117 118) ],

        # Not in() input after add()
        [ qw(3 4 6 11 12 13 14 21 22 23 24 25 26
             27 28 29 31 32 33 34 35 36 37 38 39 51 52 53
             54 55 56 57 58 59 60 61 62 63 64 65 66 67 68
             69 70 71 72 73 74 75 76 77 78 79 80 81 82 83
             84 85 86 87 88 89 90 91 92 93 94 95 96 97 98
             99 100 102 103 104 108 109 111 112 113 114
             119) ],

        # Not in() output after add()
        [ qw(3 4 6 11 12 13 14 21 22 23 24 25 26
             27 28 29 31 32 33 34 35 36 37 38 39 51 52 53
             54 55 56 57 58 59 60 61 62 63 64 65 66 67 68
             69 70 71 72 73 74 75 76 77 78 79 80 81 82 83
             84 85 86 87 88 89 90 91 92 93 94 95 96 97 98
             99 100 102 103 104 108 109 111 112 113 114
             119) ],

        # List context range() output after add()
        [ qw(0 1 2 5 7 8 9 10 15 16 17 18 19 20 30 40 41
             42 43 44 45 46 47 48 49 50 101 105 106 107
             110 115 116 117 118) ],

        # Scalar context range() output after add()
        '0,1,2,5,7,8,9,10,15,16,17,18,19,20,30,40,'.
        '41,42,43,44,45,46,47,48,49,50,101,105,106,107,'.
        '110,115,116,117,118',

        # List context collapsed() output after add()
        [ { start => 0,   end => 2,   count => 3  }, 5,
          { start => 7,   end => 10,  count => 4  },
          { start => 15,  end => 20,  count => 6  }, 30,
          { start => 40,  end => 50,  count => 11 }, 101,
          { start => 105, end => 107, count => 3  }, 110,
          { start => 115, end => 118, count => 4  } ],

        # Scalar context collapsed() output after add()
        '0-2,5,7-10,15-20,30,40-50,101,105-107,110,115-118',

        # size() after add()
        35,

        # remove() input
        [ '10-100' ],

        # Valid in() items after remove()
        [ qw( 0 1 2 5 7 8 9 101 105 106 107 110 115 116 117 118 ) ],

        # Not in() input after remove()
        [ qw(3  4  6  10 11 12 13 14 15 16 17 18 19 20 21 22
             23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38
             39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54
             55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70
             71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86
             87 88 89 90 91 92 93 94 95 96 97 98 99 100 102
             103 104 108 109 111 112 113 114 119) ],

        # Not in() output after remove()
        [ qw(3  4  6  10 11 12 13 14 15 16 17 18 19 20 21 22
             23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38
             39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54
             55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70
             71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86
             87 88 89 90 91 92 93 94 95 96 97 98 99 100 102
             103 104 108 109 111 112 113 114 119) ],

        # List context range() output after remove()
        [ qw( 0 1 2 5 7 8 9 101 105 106 107 110 115 116 117 118 ) ],

        # Scalar context range() output after remove()
        '0,1,2,5,7,8,9,101,105,106,107,110,115,116,117,118',

        # List context collapsed() output after remove()
        [
            { start => 0,   end => 2,   count => 3 }, 5,
            { start => 7,   end => 9,   count => 3 }, 101,
            { start => 105, end => 107, count => 3 }, 110,
            { start => 115, end => 118, count => 4 }
        ],

        # Scalar context collapsed() output after remove()
       '0-2,5,7-9,101,105-107,110,115-118',

        # size() after remove()
        16,
    ],
]
