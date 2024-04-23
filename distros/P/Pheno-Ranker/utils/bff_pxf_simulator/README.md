# NAME

bff-pxf-simulator: A script that creates a JSON array of simulated BFF/PXF

# SYNOPSIS

bff-pxf-simulator \[-options\]

     Options:
       -f|format                      Format [>bff|pxf]
       -n|number                      Set the number of individuals to generate [100]
       -o|output                      Output file [individuals.json]
       -external-ontologies           Path to a YAML file containing ontology terms for diseases, exposures, phenotypicFeatures, procedures, and treatments
       -random-seed                   Initializes pseudorandom number sequences for reproducible results (int)

       -diseases                      Set the number of diseases per individual [1]
       -exposures                     Set the number of exposures per individual [1]
       -phenotypicFeatures            Set the number of phenotypic features per individual [1]
       -procedures                    Set the number of procedures per individual [1]
       -treatments                    Set the number of treatments per individual [1]
       -max-[term]-pool               Limit the selection to the first N elements of the term array
       -max-ethnicity-pool            Restrict the ethnicity pool size; each individual will have only one ethnicity

     Generic Options;
       -debug                         Print debugging (from 1 to 5, being 5 max)
       -h|help                        Brief help message
       -man                           Full documentation
       -v|verbose                     Verbosity on
       -V|version                     Print version

# DESCRIPTION

This script generates a JSON array of simulated BFF/PXF data. The files can be created based on pre-loaded ontologies or by utilizing an external YAML file.

# SUMMARY

A script that creates a JSON array of simulated BFF/PXF. 

Implemented array terms:

**BFF:** `diseases, exposures, interventionsOrProcedures, phenotypicFeatures, treatments`. 

procedures = interventionsOrProcedures

**PXF:** `interventionsOrProcedures, medicalActions.procedure, medicalActions.treatment, phenotypicFeatures`.

procedures = medicalActions.procedure

treatments = medicalActions.treatment

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

When run without any arguments, the software will use default settings. To modify any parameters, please refer to the synopsis for guidance.

If you prefer not to include a specific term in the analysis, set its value to zero. For example:

`--treatments 0`

**Examples:**

    $ ./bff-pxf-simulator -f pxf  # BFF with 100 samples

    $ ./bff-pxf-simulator -f pxf -n 1000 -o pxf.json # PXF with 1K samples and saved to pxf.json

    $ ./bff-pxf-simulator -phenotypicFeatures 10 # BFF with 100 samples and 10 pF each

    $ ./bff-pxf-simulator -diseases 0 -exposures 0 -procedures 0 -phenotypicFeatures 0 -treatments 0 # Only sex and ethnicity

## COMMON ERRORS AND SOLUTIONS

    * Error message: Foo
      Solution: Bar

    * Error message: Foo
      Solution: Bar

# AUTHOR 

Written by Manuel Rueda, PhD. Info about CNAG can be found at [https://www.cnag.eu](https://www.cnag.eu).

# COPYRIGHT AND LICENSE

This PERL file is copyrighted. See the LICENSE file included in this distribution.
