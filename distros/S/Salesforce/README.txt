#
# Salesforce dot com Perl Module
# Author: Byrne Reese <byrne at majordojo dot com>
# Last Updated - Nov 2, 2004
#
# $Id: README.txt,v 1.1.1.1 2006/02/14 16:48:49 shimizu Exp $

The following Perl module is to facilitate communication with the
Saleforce Web service APIs.

Note - This module is based off of Salesforce's Partner WSDL.
       Enterprise WSDLs are a little more tricky since code stubs
       must be generated on the fly. Stay tuned to SOAP::Lite's 
       wsdl2perl project which will make Enterprise WSDL's easier
       to deal with.

HISTORY

This Perl module was originally provided and presented as part of
the first Salesforce.com dreamForce conference on Nov. 11, 2003 in
San Francisco.

It has been maintained by the original author and sfroce developers
ever since.

WHAT WORKS

All 4.0 API calls now work.

WHAT DOESN'T WORK (a.k.a. TO DO)

* make login call an automatic one if the sessionId has not been
  provided - in other words, check first to see if user has set
  the sessionId, and if not, call login to fetch one. Otherwise,
  just use the provided one in the Session header.

* The TYPES global variable only dexcribes the Account datatype.
  Certain functions (like update and create) will require this
  hashmap to be updated with additional types, and their
  respective element data types.

ABOUT THE AUTHOR

Byrne Reese is the Lead Developer of the SOAP::Lite project. He is
the author of many articles online about Perl and Web Services, a
teacher for UC Berkeley Extension, and the maintainer of a blog 
dedicated to SOAP::Lite development:

   http://majordojo.com/soaplite/