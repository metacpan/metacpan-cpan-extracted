#
# This file is part of MooseX-Unique
#
# This software is copyright (c) 2011 by Edward J. Allen III.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
use strict; use warnings;
use Test::More;

my $objecta = MyApp->new_or_matching(identity => 'Mine', secret_identity => 'Edward');
my $objectb = MyApp->new_or_matching(identity => 'Mine', secret_identity => 'Edward');
my $objectc = MyApp->new_or_matching(identity => 'Mine', secret_identity => 'Michele');
my $objectd = MyApp->new_or_matching(identity => 'Yours', secret_identity => 'Michele');

$objecta->number(40);

is($objecta->number, 40, "Object A is good (control test)");
is($objectb->number, 40, "Object B is good");
isnt($objectc->number, 40, "Object C is good");
isnt($objectd->number, 40, "Object D is good");

$objectc->number(100);

isnt($objecta->number, 100, "Object A is good");
isnt($objectb->number, 100, "Object B is good");
is($objectc->number, 100, "Object C is good");
isnt($objectd->number, 100, "Object D is good");

my $objecte = MyApp->new_or_matching(identity => 'Mine', secret_identity => 'Michele');

is($objecte->number, 100, "Object E is good");

1;
