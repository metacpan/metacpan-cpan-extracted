# `Term::DataMatrix` Perl Module

Display [Data Matrix](https://en.wikipedia.org/wiki/Data_Matrix) 2D barcodes
on the terminal.

## Usage

After installing, use `term-datamatrix <TEXT>` to generate a barcode:

```sh
term-datamatrix 'hello world'
```

## Installation

`Term::DataMatrix` can be installed through CPAN:

```sh
cpan Term::DataMatrix
```

Otherwise, download it, unpack it, then build it as per usual:

```sh
perl Makefile.PL
make && make test && make install
```

## Documentation

`Term::DataMatrix` is self-documenting using POD:

```sh
perldoc Term::DataMatrix
```

to read the documentation online with your favorite pager.
