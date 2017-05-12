#!perl
#
# This file is part of POE-Component-Client-MPD
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use 5.010;
use strict;
use warnings;

use POE;
use POE::Component::Client::MPD;
use POE::Component::Client::MPD::Test;
use Test::More;

# are we able to test module?
eval 'use Test::Corpus::Audio::MPD';
plan skip_all => $@ if $@ =~ s/\n+Compilation failed.*//s;
plan tests => 30;

# launch fake mpd
POE::Component::Client::MPD->spawn;

# launch the tests
POE::Component::Client::MPD::Test->new( { tests => [
    # [ 'event', [ $arg1, $arg2, ... ], $sleep, \&check_results ]

    # repeat
    [ 'repeat', [1],  0, \&check_success       ],
    [ 'status', [],   0, \&check_repeat_is_on  ],
    [ 'repeat', [0],  0, \&check_success       ],
    [ 'status', [],   0, \&check_repeat_is_off ],
    [ 'repeat', [],   1, \&check_success       ],
    [ 'status', [],   0, \&check_repeat_is_on  ],
    [ 'repeat', [],   1, \&check_success       ],
    [ 'status', [],   0, \&check_repeat_is_off ],

    # fade
    [ 'fade',   [15], 0, \&check_success       ],
    [ 'status', [],   0, \&check_fade_is_on    ],
    [ 'fade',   [],   0, \&check_success       ],
    [ 'status', [],   0, \&check_fade_is_off   ],

    # random
    [ 'random', [1],  0, \&check_success       ],
    [ 'status', [],   0, \&check_random_is_on  ],
    [ 'random', [0],  0, \&check_success       ],
    [ 'status', [],   0, \&check_random_is_off ],
    [ 'random', [],   1, \&check_success       ],
    [ 'status', [],   0, \&check_random_is_on  ],
    [ 'random', [],   1, \&check_success       ],
    [ 'status', [],   0, \&check_random_is_off ],
] } );
POE::Kernel->run;
exit;

#--

sub check_success {
    my ($msg) = @_;
    is($msg->status, 1, "command '" . $msg->request . "' returned an ok status");
}

sub check_repeat_is_on  { check_success($_[0]); is($_[1]->repeat, 1, 'repeat is on'); }
sub check_repeat_is_off { check_success($_[0]); is($_[1]->repeat, 0, 'repeat is off'); }

sub check_random_is_on  { check_success($_[0]); is($_[1]->random, 1, 'random is on'); }
sub check_random_is_off { check_success($_[0]); is($_[1]->random, 0, 'random is off'); }

sub check_fade_is_on    { check_success($_[0]); is($_[1]->xfade, 15, 'enabling fading'); }
sub check_fade_is_off   { check_success($_[0]); is($_[1]->xfade, 0,  'disabling fading by default'); }

