SlideMap.pm
===========

SlideMap is a utility module that generates a mapping between DNA spotted
on 2-color cDNA spotted arrays and the source microtiter plates used to 
manufacture the arrays.  This utility is generally useful to researchers 
designing and fabricating their own arrays.  It is capable of generating 
the mappings for IAS, Molecular Dynamics (II and III), Lucidea and Stanford
style arrayers.  The module can also produce mappings for generic arrayers, 
but the GeneMachines arrayer is not currently supported.  This arrayer will 
be supported in the next incremental version.  

In order to install SlideMap.pm, use standard methods to install this Perl
module, i.e.:

	perl Makefile.PL
	make
	make test
	make install

In addition, the test.pl script will run through a series of tests to verify
that the module has been correctly installed.  

Documentation for this object-oriented module can be found in 
'slidemap_documentation.txt'.  

J. White	2005
