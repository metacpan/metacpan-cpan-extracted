#!perl
use strict;
use warnings;
use OptArgs2;
use Test2::Bundle::Extended;

like dies {
    opt one => (
        isa     => 'Flag',
        ishelp  => 1,
        trigger => sub { },
        comment => 'comment',
    );
},
  qr/Define::IshelpTrigger/,
  'ishelp and trigger conflict';

done_testing;
