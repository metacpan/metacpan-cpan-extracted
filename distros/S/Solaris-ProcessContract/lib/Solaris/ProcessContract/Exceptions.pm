package Solaris::ProcessContract::Exceptions;

our $VERSION = '1.01';

# Standard modules
use strict;
use warnings;

# Exceptions
use Exception::Class 
(
  
  'Solaris::ProcessContract::Exception' =>
  {
    description => 'Generic exception for process contract',
  },

  'Solaris::ProcessContract::Exception::XS' =>
  {
    isa         => 'Solaris::ProcessContract::Exception',
    description => 'Error calling function in libcontract',
  },

  'Solaris::ProcessContract::Exception::Params' =>
  {
    isa         => 'Solaris::ProcessContract::Exception',
    description => 'Invalid parameters passed to method',
  },

);


1;
