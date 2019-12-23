# OSSEC Module

## Description

This is a collection of perl modules and scripts simplifying working with OSSEC(https://www.ossec.net/) from perl.

### Modules

#### OSSEC

Main module of this distribution. Provides OSSEC configuration file parsing to read database credentials from it.

Using methods of the OSSEC module makes sure that the base path to OSSEC
is always set in the other modules.

#### OSSEC::Log

Simplifies logging to files, e.g. for active response at the moment. You are able
to use different logging types (info,error,fatal,debug) and select the file to log
to.

#### OSSEC::MySQL

Simplifies to query and work with OSSEC and its MySQL database output.
At the moment you are able to search for an alert given by its id.
Update the signature table within the database, which is not done by the current(3.5.0)
version of OSSEC.

### Scripts

#### ossec-update-agents-database.pl

Updates the agent tabes within the MySQL database.

#### ossec-update-rules-database.pl

Parses all the rules files of OSSEC and updates the signature table wthin
the MySQL database.

## Installation

### Stable Version
The stable version can always be installed from CPAN using the *cpan*
tool of your linux distribution.

### Git install

For installing fresh from the git repository you need a perl installation including the Dist::Zilla package. The use of plenv(https://github.com/tokuhirom/plenv) is encouraged.

```{r, engine='bash', code_block_name}
git clone https://gitcloud.federationhq.de/byterazor/OSSEC.git
cd OSSEC
dzil build
cpanm OSSEC-<version>.tar.gz
```

## Author

Dominik Meyer <dmeyer@federationhq.de>


## License

GPLv3
