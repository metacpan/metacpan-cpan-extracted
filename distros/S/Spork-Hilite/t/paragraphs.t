use t::SporkHilite;

__DATA__
=== One
--- code
sub foo {
    ...
}

sub bar {
    ...
}

b+ 1-3
m+ 5-7
--- html
BBBsub foo {///
BBB    ...///
BBB}///

MMMsub bar {///
MMM    ...///
MMM}///

=== Two
--- code

g+ 1@
y+ 5@
--- html
GGGsub foo {///
GGG    ...///
GGG}///

YYYsub bar {///
YYY    ...///
YYY}///
