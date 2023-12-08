# Sys-User-UIDhelper

Helps for locating free UIDs using getpwuid.

```perl
use Sys::User::UIDhelper;

# invokes it with the default values
my $foo = Sys::User::UIDhelper->new();

# sets the min to 2000 and the max to 4000
my $foo = Sys::User::UIDhelper->new(min=>2000, max=>4000);

# finds the first free one
my $first = $foo->firstfree();
if(defined($first)){
    print $first."\n";
}else{
    print "not found\n";
}

# finds the last free one
my $last = $foo->lastfree();
if(defined($last)){
    print $last."\n";
}else{
    print "not found\n";
}
```
