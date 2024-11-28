use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 8;
use Perlmazing qw(unbless is_blessed);

my $self_1 = bless {}, 'main';
my $self_2 = bless {}, 'main2';
my $self_3 = bless {}, 'main3';

is is_blessed $self_1, 'main', '$self_1 is blessed into main';
is is_blessed $self_2, 'main2', '$self_2 is blessed into main2';
is is_blessed $self_3, 'main3', '$self_3 is blessed into main3';

unbless $self_1;

is is_blessed $self_1, '', '$self_1 is no longer blessed';
is is_blessed $self_2, 'main2', '$self_2 is blessed into main2';
is is_blessed $self_3, 'main3', '$self_3 is blessed into main3';

unbless $self_2, $self_3;

is is_blessed $self_2, '', '$self_2 is no longer blessed';
is is_blessed $self_3, '', '$self_3 is no longer blessed';