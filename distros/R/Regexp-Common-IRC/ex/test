#!/usr/bin/perl 
use strict;
use Regexp::Common qw(URI IRC);

while(<DATA>){
 chomp;
 /$RE{URI}{HTTP}{-keep}/ and print "$_ -> $1 -> uri\n";
 /^$RE{IRC}{nick}{-keep}$/ and print "$_ -> $1 ->  nick\n";
 /$RE{IRC}{channel}{-keep}/ and print "$_ -> $1 -> channel\n";
}

for ('Flexo: summon shaïtan' =~ /($RE{IRC}{nick}): summon \b($RE{IRC}{nick})\b/){
	print "$_\n";
}
1;
__DATA__
http://foo.com
perigrin
#axkit-dahut
shaïtan
#shaïtan
