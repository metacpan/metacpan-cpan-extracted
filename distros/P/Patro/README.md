# NAME

Patro - proxy access to remote objects

# SYNOPSIS

```perl
# on machine 1 (server)
use Patro;
my $obj = ...
$config = patronize($obj);
open my $fh, '>config_file'; print $fh $config; close $fh;
```

```perl
# on machines 2 through n (clients)
use Patro;
open my $fh, '<config_file'; my $config=<$fh>; close $fh;
my ($proxy) = getProxies($config);
...
$proxy->{key} = $val;         # updates $obj->{key} for obj on server
$val = $proxy->method(@args); # calls $obj->method for obj on server
```

# DESCRIPTION

`Patro` is a mechanism for making any Perl reference in one Perl program
accessible is other processes, even processes running on different hosts.
The "proxy" references have the same look and feel as the native references
in the original process, and any manipulation of the proxy reference
will have an effect on the original reference.

## Some important features:

* Hash members and array elements

Accessing or updating hash values or array values on a remote reference
is done with the same syntax as with the local reference:

```perl
# host 1
use Patro;
my $hash1 = { abc => 123, def => [ 456, { ghi => "jkl" }, "mno" ] };
my $config = patronize($hash1);
...

# host 2
use Patro;
my $hash2 = getProxies($config);
print $hash2->{abc};                # "123"
$hash2->{def}[2] = "pqr";           # updates $hash1 on host 1
print delete $hash2->{def}[1]{ghi}; # "jkl", updates $hash1 on host1
```

* Remote method calls

Method calls on the proxy object are propagated to the original object,
affecting the remote object and returning the result of the call.

```perl
# host 1
use Patro;
sub Foofie::new { bless \$_[1],'Foofie' }
sub Foofie::blerp { my $self=shift; wantarray ? (5,6,7,$$self) : ++$$self }
$config = patronize(Foofie->new(17));
...

# host 2
use Patro;
my $foo = getProxies($config);
my @x = $foo->blerp;           # (5,6,7,17)
my $x = $foo->blerp;           # 18
```

* Overloaded operators

Any overloaded operations on the original object are supported on the
remote object.

```perl
# host 1
use Patro;
my $obj = Barfie->new(2,5);
$config = patronize($obj);
package Barfie;
use overload '+=' => sub { $_ += $_[1] for @{$_[0]->{vals}};$_[0] },
     fallback => 1;
sub new {
    my $pkg = shift;
    bless { vals => [ @_ ] }, $pkg;
}
sub prod { my $self = shift; my $z=1; $z*=$_ for @{$_[0]->{vals}}; $z }

# host 2
use Patro;'
my $proxy = getProxies($config);
print $proxy->prod;      # calls Barfie::prod($obj) on host1, 2 * 5 => 10
$proxy += 4;             # calls Barfie '+=' sub on host1
print $proxy->prod;      # 6 * 9 => 54
```

# FUNCTIONS

## `patronize(@REFS)`

Creates a server on the local machine that provides proxy access to
the given list of references. It returns a string (some `Data::Dumper`
output) with information about how to connect to the server. The output
can be used as input to the `getProxies()` function to retrieve
proxies to the shared references.

## `getProxies(CONFIG)`

Connects to a server on another machine, specified in the `CONFIG`
string, and returns proxies to the list of references that are served.

