Module-JSAN
===========

SYNOPSIS
========

In `Build.PL`

    use inc::Module::JSAN;
    
    
    name            'Digest.MD5';
        
    version         '0.01';
        
    author          'SamuraiJack <root@symbie.org>';
    abstract        'JavaScript implementation of MD5 hashing algorithm';
        
    license         'perl';
        
    requires        'Cool.JS.Lib' => '1.1';
    requires        'Another.Cool.JS.Lib' => '1.2';
    
    docs_markup     'mmd';
    
    WriteAll;
    
or more relaxed DSL syntax:    

    use inc::Module::JSAN::DSL;
    
    
    name            Digest.MD5
        
    version         0.01
        
    author          'SamuraiJack <root@symbie.org>'
    abstract        'JavaScript implementation of MD5 hashing algorithm'
        
    license         perl
        
    requires        Cool.JS.Lib             1.1
    requires        Another.Cool.JS.Lib     1.2
    
    docs_markup     mmd
    

To build, test and install a distribution:

  % perl Build.PL
  % ./Build
  % ./Build test  
  % ./Build install
    
    

DESCRIPTION
===========

JSAN is the "JavaScript Archive Network," a JavaScript library akin to CPAN. Visit L<http://www.openjsan.org/> for details.
This module is a developer aid for creating JSAN distributions. 

This module works as simple wrapper for Module::Build::JSAN::Installable, please also refer to its documentation for additional details. 
The difference is that this module provides a less perl-specifiec and more relaxed syntax for builder scripts. 


INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Module::JSAN

You can also look for information at:

    RT, CPAN's request tracker
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-JSAN

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Module-JSAN

    CPAN Ratings
        http://cpanratings.perl.org/d/Module-JSAN

    Search CPAN
        http://search.cpan.org/dist/Module-JSAN/


COPYRIGHT AND LICENCE

Copyright (C) 2009 Nickolay Platonov

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

