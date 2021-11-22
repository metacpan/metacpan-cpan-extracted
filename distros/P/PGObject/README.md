PGObject

PGObject is a module intended to be a base for object class frameworks which map
PostgreSQL stored procedures to object methods in a relatively loosely coupled
way.  PGObject provides the bare-bones infrastructure required to make it 
happen.  This module is primarily of interest to individuals writing such 
frameworks, and very little in here is likely to be used directly outside of 
such frameworks.

The initial release, 1.0.0 is based on our six years of experience using 
essentially the same approach in LedgerSMB (starting with the beginnings of the
1.3 codebase in 2007).  This release is largely based on the code I wrote for
LedgerSMB but it cleans up and refactors such work based on the lessons learned.

INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc PGObject

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        https://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject

    MetaCPAN
        https://metacpan.org/dist/PGObject


WRITING PGOBJECT-AWARE PERL CLASSES

One of the powerful features of PGObject is the ability to declare methods in 
types which can be dynamically detected and used to serialize data for query 
purposes. Objects which contain a pgobject_to_db(), that method will be called
and the return value used in place of the object.  This can allow arbitrary 
types to serialize themselves in arbitrary ways.

For example a date object could be set up with such a method which would export 
a string in yyyy-mm-dd format.  An object could look up its own definition and
return something like :

   { cast => 'dbtypename', value => '("A","List","Of","Properties")'}

If a scalar is returned that is used as the serialized value.  If a hashref is 
returned, it must follow the type format:

  type  => variable binding type,
  cast  => db cast type
  value => literal representation of type, as intelligible by DBD::Pg


WRITING TOP-HALF OBJECT FRAMEWORKS FOR PGOBJECT

PGObject is intended to be the database-facing side of a framework for objects. 
The intended structure is for three tiers of logic:

 1.  Database facing, low-level API's
 2.  Object management modules 
 3.  Application handlers with things like database connection management.

By top half, we are referring to the second tier.  The third tier exists in the 
client application.

The PGObject module provides only low-level API's in that first tier.  The job
of this module is to provide database function information to the upper level 
modules.  

We do not supply type information, If your top-level module needs this, please
check out https://code.google.com/p/typeutils/ which could then be used via our
function mapping APIs here.

LICENSE AND COPYRIGHT

  COPYRIGHT (C) 2013-2014 Chris Travers
  COPYRIGHT (C) 2014-2021 The LedgerSMB Core Team

Redistribution and use in source and compiled forms with or without 
modification, are permitted provided that the following conditions are met:

*  Redistributions of source code (Perl) must retain the above
   copyright notice, this list of conditions and the following disclaimer as the
   first lines of this file unmodified.

*  Redistributions in compiled form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   source code, documentation, and/or other materials provided with the 
   distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
