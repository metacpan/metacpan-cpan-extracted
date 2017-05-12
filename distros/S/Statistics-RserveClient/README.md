Statistics::RserveClient
========================

This is a Perl module implementing a client library for Rserve
http://www.rforge.net/Rserve/ (a TCP/IP server for R statistical
software).  The software is largely based on the PHP implementation
of Clément Turbelin.

The implementation of this library was sponsored in part by a
University of British Columbia Teaching and Learning Enhancement Fund
grant awarded to Dr.  Bruce Dunham, UBC Statistics.  

Thanks also to Dr. Davor Cubranic for substantial contributions
including most of the tests.

Tests
-----

You can run tests using prove:

   prove -r t

Usage
-----

The use of the library is simple

1. create an instance of Rserve_Connection

  $cnx = new Statistics::RserveClient::Connection('myserverhost');

2. Send R commands and get the results as perl array

  @result = $cnx->evalString('x ="Hello world !"; x');

For additional information and examples please visit the project
wiki at https://github.com/djun-kim/Statistics--RserveClient/wiki.

Contacts
--------

Djun Kim, djun.kim@cielosystems.com
http://puregin.org

