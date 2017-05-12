
use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('Term::MultiSpinner') }

{
    package TestFH;

    our $TFHOUT;

    sub TIEHANDLE {
        my $self;
        $TFHOUT = '';
        bless \$self => shift;
    }

    sub PRINT {
        my $self = shift;
        $TFHOUT .= join(q{},@_);
    }

    sub CLOSE { $TFHOUT='' }
}

tie(*FOO, 'TestFH');
my $spinner = Term::MultiSpinner->new(
    output_handle => \*FOO,
);
$spinner->advance(0);
$spinner->advance(1);
$spinner->advance(0);
$spinner->finish(0);
$spinner->advance(1);
$spinner->advance(2);
$spinner->clear();
$spinner->advance(0);
undef $spinner;
is(
    $TestFH::TFHOUT,
    qq{\\\010 \010\\\\\010\010  \010\010|\\\010\010  \010\010x\\\010\010  \010\010x|\010\010  \010\010x|\\\010\010\010   \010\010\010\\|\\\010\010\010   \010\010\010xxx\010\010\010   \010\010\010}
);
close(FOO);
