package Storable::AMF;
# vim: ts=8 sw=4 sts=4 et
use strict;
use warnings;
BEGIN {
    our $VERSION;
    $VERSION = '1.23' unless $INC{'Storable/AMF0.pm'};
}
use Storable::AMF0; # install and create all methods
use Exporter 'import';

our %EXPORT_TAGS = (
    'all' => [
        qw(
          freeze thaw	dclone retrieve lock_retrieve lock_store lock_nstore store nstore ref_lost_memory ref_clear
          deparse_amf new_amfdate perl_date
		  new_date
		  parse_serializator_option
		  parse_option
		  freeze0 freeze3 thaw0 thaw3 thaw0_sv
		  deparse_amf0 deparse_amf3
          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

1;
__END__

=head1 NAME

Storable::AMF - serializing/deserializing AMF0/AMF3 data

=head1 SYNOPSIS

  use Storable::AMF0 qw(freeze thaw); # Handle AMF0 data
  use Storable::AMF3 qw(freeze thaw); # Handle AMF3 data

  $amf0 = freeze($perl_object);
  if ($@){
	  die "Can't freeze perl_object"
  };

  $perl_object = thaw($amf0);
  if ($@){
	  die "It seems data is not valid AMF0 data";
  }

  # Deparse one object and getting its length
  use Storable::AMF0 qw(deparse_amf); 

  # reading stream of objects
  my $bytea = freeze($a1) . freeze($a2) . ...; # objects data stream
  my @objects;
  while( length $bytea ){
	my( $obj, $length_of_packet ) = deparse_amf( my $bytea = freeze($a1) . freeze($a) ... );
	if ( $@ ){
		# We meet trouble with deparse
		die "This is not amf0 data";
	}
	# have read one object and gets it's length
	# So put it in array and continue
	push @objects, $obj;
	# remove readed part of object bytearray
	substr $bytea, 0, $length_of_packet, '';
  }


	
  # Dumping/Undumping amf0 objects to/from file
	
  store $perl_object, 'file';
  $restored_perl_object = retrieve 'file';
	
  # Same with locking

  lock_store \%table, 'file';
  $hashref = lock_retrieve('file');

  # Dates serializing/deserializing 

  use Storable::AMF0 qw(new_amfdate perl_date);
  my $timestamp = time(); # UTC time --- seconds from epoch

  # new_amfdate( $time ) 
  my $object = { now => new_amfdate( $timestamp ), name => "Object with DateTime" };
  my $bytea  = freeze ( $object );

  # getting perl timestamp from thawed flash object;

  my $object = thaw $bytes;

  my $time   = perl_date( $object->{field_with_date} );  

  - or use simple by your own risk

  my $time   = $object->{field_with_date} ; # 

  # return $time may be seconds from epoch, or milliseconds from epoch, or some kind of object .
  # Result are not defined at this time it depends of module version


  # Working with AMF0 and AMF3 format simultaneously
  use Storable::AMF0 ();
  use Storable::AMF3 ();

  $bytea = Storable::AMF0::freeze( ... );
  $bytea = Storable::AMF3::freeze( ... );

  ...

=head1 DESCRIPTION

This module is (de)serializer for Adobe's AMF0/AMF3 (Action Message Format ver 0-3).
To deserialize AMF3 objects you can export function from Storable::AMF3 package
Almost all function implemented in XS/C for speed, except file operation. 

=head1 MOTIVATION

Speed, simplicity and agile. 

=head1 BENCHMARKS

	About 50-60 times faster than Data::AMF pure perl module. (2009)
	About 40% faster than Storable in big objects.        (2009)
	About 6 times faster than Storable for small object    (2009)

=head1 FUNCTIONS

=over

=item freeze($obj, [ $option]  ) 
  --- Serialize perl object($obj) to AMF, and return AMF data if successfull. 
      Set $@ in case of error and return undef of empty list.

=item thaw($amf0, [$option] )
  --- Deserialize AMF data to perl object, and return the perl object if successfull.
      Set $@ in case of error and return undef of empty list.

=item deparse_amf $bytea 
  --- deparse from bytea one item
  Return object and number of bytes readed if successull.
  Set $@ in case of error and return undef or empty list.
  in scalar context works as thaw

=item $date_object = new_amfdate( $perl_timestamp)
	Return object representing date in AMF world.

=item $perl_time = perl_date( $date_member )
	Converts value from AMF date to perl timestampr, can croak.

=item store $obj, $file
  --- Store serialized AMF0 data to file

=item nstore $obj, $file
  --- Same as store

=item retrieve $obj, $file
  --- Retrieve serialized AMF0 data from file

=item lock_store $obj, $file
  --- Same as store but with Advisory locking

=item lock_nstore $obj, $file
  --- Same as lock_store 

=item lock_retrieve $file
  --- Same as retrieve but with advisory locking

=item dclone $file
  --- Deep cloning data structure

=item ref_clear $obj
  --- recurrent cleaning arrayrefs and hashrefs.

=item ref_lost_memory $obj
  --- test if object contain lost memory fragments inside.
  (Example do { my $a = []; @$a=$a; $a})

=item parse_serializator_option / parse_option
  generate option scalar for freeze/thaw/deparse_amf
  See L<Storable::AMF0> for complete list of options

=back

=head1 EXPORT

  None by default.

=head1 LIMITATION

At current moment and with restriction of AMF0/AMF3 format referrences to scalar are not serialized,
and can't/ may not serialize tied variables.
And dualvars (See Scalar::Util) are serialized as string value.
Freezing CODEREF, IO, Regexp, GLOB referenses are restricted.

=head1 SEE ALSO

L<Data::AMF>, L<Storable>, L<Storable::AMF0>, L<Storable::AMF3>

=head1 AUTHOR

Anatoliy Grishaev, <grian at cpan dot org>

=head1 THANKS

	Alberto Reggiori. ( basic externalized object support )
	Adam Lounds.      ( tests and some ideas and code for boolean support )

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by A. G. Grishaev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.
