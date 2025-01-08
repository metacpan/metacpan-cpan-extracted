# Scalar::Dynamizer

Scalar::Dynamizer enables the creation of dynamic scalars that automatically 
recompute their values whenever they are accessed. This module simplifies 
working with dynamically evaluated scalars using Perl's `tie` mechanism and 
operator overloading, making it intuitive and transparent to implement scalars 
that depend on the program's state at the time of access.

Dynamic scalars are particularly useful for counters, timestamps, or real-time 
data from external sources such as databases or APIs.

## Installation

To install this module, run the following commands:

```
perl Makefile.PL
make
make test
make install
```

## Usage

Here’s a quick example:

```
use Scalar::Dynamizer qw(dynamize);

my $count = 0;

# Create a dynamic scalar
my $counter = dynamize { ++$count };

print $counter;             # 1
print $counter * 100;       # 200
print "Count is $counter";  # "Count is 3"
```

See the `examples/` directory for additional examples.

## Support and Documentation

After installing, you can find documentation for this module with the `perldoc` 
command:

```
perldoc Scalar::Dynamizer
```

You can also look for additional information at:

- **RT (CPAN's request tracker):** [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Scalar-Dynamizer](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Scalar-Dynamizer)
- **CPAN Ratings:** [https://cpanratings.perl.org/d/Scalar-Dynamizer](https://cpanratings.perl.org/d/Scalar-Dynamizer)
- **MetaCPAN:** [https://metacpan.org/release/Scalar-Dynamizer](https://metacpan.org/release/Scalar-Dynamizer)

## License and Copyright

This software is copyright (c) 2025 by Jeremi Gosney < epixoip at cpan.org >

This is free software, licensed under:
**The Artistic License 2.0 (GPL Compatible)**
