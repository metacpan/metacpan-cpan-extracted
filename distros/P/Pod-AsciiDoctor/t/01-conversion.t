#!perl -T

use 5.006;
# use strict;
use warnings FATAL => 'all';
use Test::More;
use Pod::AsciiDoctor;



my $adoc = Pod::AsciiDoctor->new();
$adoc->parse_from_file("t/data/pod.pm");

# Test C<...>
ok($adoc->adoc() =~ /`\$x >> 3` or even `\$y >> 5`/, "Converted C<<< \$x >> 3 >>> or even C<<<< \$y >> 5 >>>>.");

# Test B<...>
ok($adoc->adoc() =~ /\*test\*/);

# Test I<...>
ok($adoc->adoc() =~ /_grand_/);

# Test L<text|http://...>
ok($adoc->adoc() =~ /reference \[Asciidoctor User Manual\]/);

done_testing();
