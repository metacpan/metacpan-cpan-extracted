package RPKI::RTRlib;

use 5.014002;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('RPKI::RTRlib', $VERSION);

1;
__END__

=head1 NAME

RPKI::RTRlib - provides a simple interface to RTRlib (http://rpki.realmv6.org/)

=head1 SYNOPSIS

  use RPKI::RTRlib;

=head1 DESCRIPTION

RPKI::RTRlib is an interface for RTRlib (http://rpki.realmv6.org/). 
The RTRlib is an open-source C implementation of the RPKI/Router Protocol client. The library allows to fetch and store validated prefix origin data from a RTR-cache and performs origin verification of prefixes.

=head2 example

	use rtrlib;
	my $conf = rtrlib::start("localhost","8282");
	my $result = rtrlib::validate_r($conf,12654,'93.175.146.0',24);
	print "state:",$result->{state},"\n";
	for(@{$result->{roas}}){
		print "preifx:",$_->{prefix};
		print "asn:",$_->{asn};
		print "min:",$_->{min};
		print "max:",$_->{max},"\n";
	}
	rtrlib::stop($conf);
	

=head2 start(host, port) 

start the rtrclient and connect to RTR-cache and return a config. It is used an unprotected TCP-Connection.
(see: int rtr_mgr_start  http://rpki.realmv6.org/doxygen/group__mod__rtr__mgr__h.html#ga665089d8c882e94f0f0f1a8bdf7b15a4)

=head2 validate(conf, asn, ipAddr, cidr) 

validates the origin of a BGP-Route and return the RPKI-State
(see: int pfx_table_validate  http://rpki.realmv6.org/doxygen/group__mod__pfx__h.html#ga9b7eda6712d0c9c45cc7c0ca40196689)

return integer
 - 0 -->Valid
 - 1 -->NotFound
 - 2 -->Invalid

=head2 validate_r(conf, asn, ipAddr,cidr)

validates the origin of a BGP-Route and returns a list of ROAs that decided the result.
(see: int pfx_table_validate_r  http://rpki.realmv6.org/doxygen/group__mod__pfx__h.html#gac5ca36243c500ddfbf079c9d83f7792f)

returns a hash:
 - state -->RPKI-state
 - roas  -->list of ROAs
    - prefix
	- asn
	- min -->minimal prefix length
	- max -->maximal prefix length

=head2 stop(conf)

terminates all connections that are defined in the config. 
(see: void rtr_mgr_stop  http://rpki.realmv6.org/doxygen/group__mod__rtr__mgr__h.html#ga20fc681b1872ccf9fa8961dd21584d91)

=head2 EXPORT

None by default.



=head1 SEE ALSO

http://rpki.realmv6.org/wiki/Documentation


=head1 AUTHOR

Robert Schmidt, rs.schmidt@fu-berlin.de

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Robert Schmidt

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
