=== One
--- code -trim prep hilite
# This is a comment
sub divide {
    my $numerator = shift;
    my $divisor = shift;
    return $numerator / $divisor;
}

bbb g+ 2
--- html expand
<pre>
# This is a comment
BBBsub/// GGGdivide {///
    my $numerator = shift;
    my $divisor = shift;
    return $numerator / $divisor;
}
</pre>

===
--- code -trim prep hilite

        rrrrrrr  4
--- html expand
<pre>
# This is a comment
sub divide {
    my $numerator = shift;
    my $RRRdivisor/// = shift;
    return $numerator / $divisor;
}
</pre>



