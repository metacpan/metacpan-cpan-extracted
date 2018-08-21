# Set::Hash::Keys
Perl module for treating 'Hash Objects' as sets, solely based on their 'keys'

## NAME
Set::Hash::Keys - Hash Objects as sets, based on their keys

## SYNOPSIS

```perl
    use Set::Hash::Keys;
    my $set1 = Set::Hash::Keys->new(
        foo => 'blue',
        bar => 'july',
    );
    my $set2 = Set::Hash::Keys->new(
        foo => 'bike',
        baz => 'fish',
    );
    
    my $set3 = $set1 + $set2; # union
    #   foo => 'bike', # only the last remains
    #   bar => 'july',
    #   baz => 'fish',
    
    my $set4 = $set1 * $set2; # intersection
    #   foo => 'bike', # only the last remains
    
    my $set5 = $set1 - $set2; # difference
    #   bar => 'july',
    
    my ($sub1, $sub2) = $set1 / $set2;
    
    my $set5 += { qux => 'moon', ... }; # add new elements
    #   bar => 'july',
    #   qux => 'moon',
    
    my $set3 -= { foo => 'sofa', ... };
    #   bar => 'july',
    #   baz => 'fish',
    
```

## AUTHOR
Theo van Hoesel
