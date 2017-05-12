The Motivation of writing NetObj::MacAddress
============================================

There are already other modules dealing with MAC addresses available on the
CPAN, so writing another one merits some thought.

The existing modules for MAC addresses seem to fall into one of two categories.
One is helpers to extract information about the hardware a program is running
on.  The other is dealing with different notations of MAC addresses and
converting between them.  If anything the present module falls into the second
category.

If we look at [Net::MAC](https://metacpan.org/pod/Net::MAC) its goal is
clearly to provide the most general support to convert between representation
most of which are not common at all.  This may be a worthwhile goal but it
comes at a cost.  The object interface is bigger than it needs to be if one
wants to represent just MAC addresses rather than their string representation.
Two different representations of the same MAC address will compare equal
numerically but unequal stringwise.  This means our code using this module
needs to test all the cases of different representations.  This makes the
object oriented design more complex than necessary if all one needs is the MAC
address itself and not its representation.

Likewise [NetAddr::MAC](https://metacpan.org/pod/NetAddr::MAC) has a rather
extensive object interface too.  Its main goal is to provide named conversion
routines.  It also wants to avoid the reliance on Moose.

If we just want the most minimal class to represent a MAC address independently
of its representation there seems to be a niche which no other module on CPAN
fills.  The present module fills this niche.  It uses Moo to fit into the Moose
system for OO programming with Perl while avoiding the rather extensive
dependency chain of Moose proper.  This allows us to have a most simple class
representing a MAC address that can be extended as necessary.

As an example, NetObj::MacAddress does not allow to configure the default
format for stringification.  This is by design to keep the class simple.
However, we can easily deal with such a need by writing a sub class.  The
following Perl script is an example of how this could be done:

```perl
#!/usr/bin/env perl
use 5.014;
use warnings FATAL => 'all';


package MyApp::MacAddress {
    use Moo;
    use NetObj::MacAddress;
    use NetObj::MacAddress::Formatter::Colons;
    extends 'NetObj::MacAddress';

    use overload q("") => sub {shift->to_string('colons')};
};

my $mac = MyApp::MacAddress->new('00-11-22-33-44-55');
say "$mac"; # prints 00:11:22:33:44:55
```

The same can be done for a simple non-Moo class:

```perl
#!/usr/bin/env perl
use 5.014;
use warnings FATAL => 'all';


package MyApp::MacAddress {
    use NetObj::MacAddress;
    use NetObj::MacAddress::Formatter::Colons;
    use base 'NetObj::MacAddress';

    use overload q("") => sub {shift->to_string('colons')};
};

my $mac = MyApp::MacAddress->new('00-11-22-33-44-55');
say "$mac"; # prints 00:11:22:33:44:55
```

If we needed a class that retained knowledge about the original representation
of the MAC address at the time of constructing the object we could we could
create a sub class for this too.  However, there is hardly a need for such a
sub class as the available modules already fill that niche.
