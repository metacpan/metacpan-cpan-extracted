perl-Sphinx-Config-Builder
=========================

The motivation behind this module is the need to manage many indexes and corresponding sources
handled by a single Sphinx searchd instance.  Managing a configuration file with many indexes
and sources quickly becomes unweildy, and a programatic solution is necessary. Using
Sphinx::Config::Builder, one may more easily manage Sphinx configurations using a more
appropriate backend (e.g., a simple .ini file or even a  MySQL database). This is particularly
useful if one is frequently adding or deleting indexes and sources. This approach is
particularly useful for managing non-natively supported Sphinx datasources that might
require the additional step of generating XMLPipe/Pipe2 sources.

This module doesn't read in Sphinx configuration files, it simply allows one to construct and 
output a configuration file programmtically.
