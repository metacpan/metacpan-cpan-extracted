package RDF::LDF::Error;
# The error handling via Error in RDF::Trine is in conflict with
# Moo packages. This Throwable package is a stop gap
use Moo;
with 'Throwable';
 
has text => (is => 'ro');

1;