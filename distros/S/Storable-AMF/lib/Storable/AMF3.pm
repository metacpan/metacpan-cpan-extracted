package Storable::AMF3;
# vim: ts=8 sw=4 sts=4 et
use strict;
use warnings;
use Fcntl qw(:flock);
use subs qw(freeze thaw);
use Exporter 'import';
use Carp qw(croak);
BEGIN {
    our $VERSION;
    $VERSION = '1.23' unless $INC{'Storable/AMF0.pm'};
}
use Storable::AMF0 ();

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our %EXPORT_TAGS = (
    'all' => [
        qw(
          freeze thaw	dclone retrieve lock_retrieve lock_store lock_nstore store nstore
          ref_clear ref_lost_memory
          deparse_amf new_amfdate perl_date
		  new_date
		  parse_option
		  parse_serializator_option
          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

sub retrieve($) {
    my $file = shift;
    my $lock = shift;

    open my $fh, "<:raw", $file or croak "Can't open file \"$file\" for read.";
    flock $fh, LOCK_SH if $lock;
    my $buf;
    sysread $fh, $buf, (( sysseek $fh, 0, 2 ), sysseek $fh, 0,0)[0] ;
    return thaw($buf);
}

sub lock_retrieve($) {
    $_[1] = 1;
    goto &retrieve;
}

sub store($$) {
    my ( $object, $file, $lock ) = @_;

    my $freeze = \freeze($object);
    unless (defined $$freeze ){
        croak "Bad object";
    }
    else  {
        my $fh;
        if ($lock){
            open $fh, ">>:raw", $file or croak "Can't open file \"$file\" for write.";
            flock $fh, LOCK_EX if $lock;
            truncate $fh, 0;
            seek $fh,0,0;
        }
        else {
            open $fh, ">:raw", $file or croak "Can't open file \"$file\" for write.";
        }
        print $fh $$freeze if defined $$freeze;
        close $fh;
    };
}

sub lock_store($$) {
    $_[2] = 1;
    goto &store;
}
{{
    no warnings 'once';
    *nstore = \&store;
    *lock_nstore = \&lock_store;
}};
1;
__END__

=head1 NAME

Storable::AMF3 - serializing/deserializing AMF3 data

=head1 SYNOPSIS

  use Storable::AMF3 qw(freeze thaw); 

  $amf3 = freeze($perl_object);
  $perl_object = thaw($amf3);

	
  # Store/retrieve to disk amf3 data
	
  store $perl_object, 'file';
  $restored_perl_object = retrieve 'file';


  use Storable::AMF3 qw(nstore freeze thaw dclone);

  
  # Advisory locking
  use Storable::AMF3 qw(lock_store lock_nstore lock_retrieve)
  lock_store \%table, 'file';
  lock_nstore \%table, 'file';
  $hashref = lock_retrieve('file');

  # Deparse one object
  use Storable::AMF0 qw(deparse_amf); 

  my( $obj, $length_of_packet ) = deparse_amf( my $bytea = freeze($a1) . freeze($a) ... );

  - or -
  $obj = deparse_amf( freeze($a1) . freeze($a) ... );

=head1 DESCRIPTION

This module is (de)serializer for Adobe's AMF3 (Action Message Format ver 3).
This is only module and it recognize only AMF3 data. 
Almost all function implemented in C for speed. 
And some cases faster then Storable( for me always)

=head1 EXPORT

  None by default.

=head1 FUNCTIONS

=over

=item freeze($obj) 
  --- Serialize perl object($obj) to AMF3, and return AMF data

=item thaw($amf3)
  --- Deserialize AMF data to perl object, and return the perl object

=item store $obj, $file
  --- Store serialized AMF3 data to file

=item nstore $obj, $file
  --- Same as store

=item retrieve $obj, $file
  --- Retrieve serialized AMF3 data from file

=item lock_store $obj, $file
  --- Same as store but with Advisory locking

=item lock_nstore $obj, $file
  --- Same as lock_store 

=item lock_retrieve $file
  --- Same as retrieve but with advisory locking

=item dclone $file
  --- Deep cloning data structure

=item ref_clear $obj
  --- cleaning  arrayref and hashref. (Usefull for destroing complex objects)

=item ref_lost_memory $obj
  --- test if object contain lost memory fragments inside.
  (Example do { my $a = []; @$a=$a; $a})

=item deparse_amf $bytea 
  --- deparse from bytea one item
  Return one object and number of bytes readed
  if scalar context return object

=item parse_serializator_option / parse_option
  generate option scalar for freeze/thaw/deparse_amf
  See L<Storable::AMF0> for complete list of options

=back


=head1 SEE ALSO

L<Data::AMF>, L<Storable>, L<Storable::AMF3>, L<Storable::AMF>

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
