# NAME

bff-pxf-simulator: A script that creates a JSON array of random BFF/PXF

# SYNOPSIS

bff-pxf-simulator \[-options\]

     Options:
       -f|format                      Format [>bff|pxf]
       -n|number                      Number of individuals
       -diseases                      Number of [1]
       -phenotypicFeatures            IDEM
       -treatments                    IDEM
       -max-diseases-pool             To narrow the selection to N first array elements
       -max-phenotypicFeatures-pool   IDEM
       -max-treatments-pool           IDEM
       -o|output                      Output file [individuals.json]
       -external-ontologies           YAML file with ontologies for diseases, phenotypicFeatures and treatments
       -random-seed                   Initializes pseudorandom number sequences for reproducible results (int)

     Generic Options;
       -debug                         Print debugging (from 1 to 5, being 5 max)
       -h|help                        Brief help message
       -man                           Full documentation
       -v|verbose                     Verbosity on
       -V|version                     Print version

# DESCRIPTION

A script that creates a JSON array of random BFF/PXF

# SUMMARY

A script that creates a JSON array of random BFF/PXF. 

For complex properties we only implemented `diseases,phenotypicFeatures` and `treatments`. Depending on the user's adoption we might implement more.

# INSTALLATION

(only needed if you did not install `Pheno-Ranker`)

    $ cpanm --sudo --installdeps .

### System requirements

    * Ideally a Debian-based distribution (Ubuntu or Mint), but any other (e.g., CentOs, OpenSuse) should do as well.
    * Perl 5 (>= 5.10 core; installed by default in most Linux distributions). Check the version with "perl -v"
    * 1GB of RAM.
    * 1 core (it only uses one core per job).
    * At least 1GB HDD.

# HOW TO RUN BFF-PXF-SIMULATOR

The software runs without any argument and assumes defaults. If you want to change some parameters please take a look to the synopsis.

**Examples:**

    $ ./bff-pxf-simulator -f pxf  # BFF with 100 samples

    $ ./bff-pxf-simulator -f pxf -n 1000 -o pxf.json # PXF with 1K samples and saved to pxf.json

    $ ./bff-pxf-simulator -phenotypicFeatures 10 # BFF with 100 samples and 10 pF each

## COMMON ERRORS AND SOLUTIONS

    * Error message: Foo
      Solution: Bar

    * Error message: Foo
      Solution: Bar

# AUTHOR 

Written by Manuel Rueda, PhD. Info about CNAG can be found at [https://www.cnag.crg.eu](https://www.cnag.crg.eu).

# COPYRIGHT AND LICENSE

This PERL file is copyrighted. See the LICENSE file included in this distribution.
