Mobile::Wurfl is a perl module that provides an interface to mobile device
information represented in wurfl (<http://wurfl.sourceforge.net/>). The
Mobile::Wurfl module works by saving this device information in a database
(preferably mysql).

It offers an interface to create the relevant database tables from a SQL file
containing "CREATE TABLE" statements (a sample is provided with the
distribution). It also provides a method for updating the data in the database
from the wurfl.xml file hosted at
<http://www.nusho.it/wurfl/dl.php?t=d&f=wurfl.xml>.

It provides methods to query the database for lists of capabilities, and groups
of capabilities. It also provides a method for generating a "canonical" user
agent string (see "canonical_ua").

Finally, it provides a method for looking up values for particular capability /
user agent combinations. By default, this makes use of the hierarchical
"fallback" structure of wurfl to lookup capabilities fallback devices if these
capabilities are not defined for the requested device.

For "HOWTO" information on how to use Mobile::Wurfl look at the HOWTO.txt file
in this distribution, or see
<http://wurfl.sourceforge.net/perl/mobile_wurfl.php>.
