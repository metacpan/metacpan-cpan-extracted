# String::DiffLine
perl5 module to find the character, line, and line position of the first difference in two strings, 
written in perlxs/C for speed

# DESCRIPTION
String::DiffLine defines a C/perlxs function "diffline" which finds the
character position, line number, and line character position of 
the first difference in two strings quickly. See POD documentation for more details

# INSTALLATION
To install this module use the cpan perl installer script: `cpan String::Diffline`, 
the CPAN perl module: `perl -MCPAN -e 'install(q{String::DiffLine})'`
or if you like the hard way:
```bash
perl Makefile.PL
make
make test # check for absence of 'not ok' lines
make install
```

# AUTHOR
Andrew Allen, andrew_d_allen (at) hotmail.com
