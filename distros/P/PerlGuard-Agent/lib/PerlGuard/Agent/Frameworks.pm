# A subclass of this will be the entry point, which takes all config parameters, handles creation and deletion of Profile objects

package PerlGuard::Agent::Frameworks;
use 5.010001;
use Moo;

has agent => ( is=>'lazy' );


1;