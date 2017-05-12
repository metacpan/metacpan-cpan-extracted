
use strict;
use warnings;

use Test::More tests => 4;

BEGIN { use_ok('Term::Spinner') }

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
my $spinner = Term::Spinner->new(
    output_handle => \*FOO,
);
$spinner->advance();
$spinner->advance();
$spinner->advance();
$spinner->finish();
$spinner->advance();
$spinner->advance();
$spinner->clear();
$spinner->advance();
undef $spinner;
is(
    $TestFH::TFHOUT,
    qq{\\\010 \010|\010 \010/\010 \010x\010 \010\\\010 \010|\010 \010/\010 \010x\010 \010}
);
close(FOO);

tie(*FOO, 'TestFH');
$spinner = Term::Spinner->new(
    output_handle => \*FOO,
    clear_on_destruct => 0,
);
$spinner->advance();
$spinner->advance();
$spinner->advance();
$spinner->finish();
$spinner->advance();
$spinner->advance();
$spinner->clear();
$spinner->advance();
undef $spinner;
is(
    $TestFH::TFHOUT,
    qq{\\\010 \010|\010 \010/\010 \010x\010 \010\\\010 \010|\010 \010/\010 \010x}
);
close(FOO);

tie(*FOO, 'TestFH');
$spinner = Term::Spinner->new(
    output_handle => \*FOO,
    finish_on_destruct => 0,
    clear_on_destruct => 0,
);
$spinner->advance();
$spinner->advance();
$spinner->advance();
$spinner->finish();
$spinner->advance();
$spinner->advance();
$spinner->clear();
$spinner->advance();
undef $spinner;
is(
   $TestFH::TFHOUT,
   qq{\\\010 \010|\010 \010/\010 \010x\010 \010\\\010 \010|\010 \010/}
);
close(FOO);

