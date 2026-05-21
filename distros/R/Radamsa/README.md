# Radamsa for Perl 5

`Radamsa` is an XS wrapper around the Radamsa mutational fuzzer library for
Perl 5.

## Install

```bash
cpan Radamsa
```

This distribution vendors the generated Radamsa C source, so installation does
not fetch anything from the network.

## Usage

```perl
use Radamsa qw(mutate);

my $output = mutate("hello world\n", seed => 1234, max_len => 4096);

my $rad = Radamsa->new(seed => 1, max_len => 4096);
my $case = $rad->mutate("sample input");
```

## Examples

```bash
perl examples/mutate-string.pl 'hello world'
perl examples/simple-fuzzer.pl /path/to/program sample.bin
```
