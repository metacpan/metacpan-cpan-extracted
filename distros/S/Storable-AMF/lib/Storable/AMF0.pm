package Storable::AMF0;
# vim: ts=8 sw=4 sts=4 et
use strict;
use warnings;
use Fcntl qw(:flock);
our $VERSION = '1.23';
use subs qw(freeze thaw);
use Exporter 'import';
use Carp qw(croak);
{   our @Bool = (bless( do{\(my $o = 0)},'JSON::PP::Boolean'), bless( do{\(my $o = 1)},'JSON::PP::Boolean')); 
    local $@; 
    eval { 
	require Types::Serialiser; 
	@Bool = (Types::Serialiser::false(), Types::Serialiser::true());
	1
    } or 
    eval {
	require JSON::XS;
	@Bool = (JSON::XS::false(), JSON::XS::true());
	1
    }; 
};

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_TAGS_ALL = qw(
    freeze thaw	dclone
    retrieve lock_retrieve lock_store lock_nstore store nstore
    ref_lost_memory ref_clear
    deparse_amf new_amfdate perl_date
	    new_date
	    parse_option
	    parse_serializator_option
    );

our %EXPORT_TAGS = ( 'all' => \@EXPORT_TAGS_ALL);
our @EXPORT_OK = ( @EXPORT_TAGS_ALL );

sub retrieve($) {
    my $file = shift;
    my $lock = shift;

    open my $fh, "<:raw", $file or croak "Fail on open file \"$file\" for reading $!";
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
        croak "Bad object $@";
    }
    else  {
        my $fh;
        if ($lock){
            open $fh, ">>:raw", $file or croak "Fail on open file \"$file\" for writing $!";
            flock $fh, LOCK_EX if $lock;
            truncate $fh, 0;
            seek $fh,0,0;
        }
        else {
            open $fh, ">:raw", $file or croak "Fail on open file \"$file\" for writing $!";
        }
        print $fh $$freeze if defined $$freeze;
        close $fh;
    };
}

sub lock_store($$) {
    $_[2] = 1;
    goto &store;
}
sub ref_lost_memory($);
sub ref_clear($);
{{
	require XSLoader;
	XSLoader::load( 'Storable::AMF', $VERSION );
        no warnings 'once';
        *nstore = \&store;
        *lock_nstore = \&lock_store;

	no strict 'refs';

	my $my_package = __PACKAGE__ . "::";
	for my $other_package ( "Storable::AMF::", "Storable::AMF3::" ){
            *{ $other_package . $_ } = *{ $my_package . $_} for qw(ref_clear ref_lost_memory VERSION);
	}
	*{"Storable::AMF::$_"} = *{"Storable::AMF0::$_"} for grep m/retrieve|store/, @EXPORT_OK;
}};

*refaddr = \&Scalar::Util::refaddr;
*reftype = \&Scalar::Util::reftype;

sub _ref_selfref($$);
sub _ref_selfref($$){
    require Scalar::Util;
    my $obj_addr = shift;
    my $value    = shift;
    my $addr     = refaddr($value);
    return unless defined $addr;
    if ( reftype($value) eq 'ARRAY' ) {

        return $$obj_addr{$addr} if exists $$obj_addr{$addr};
        $$obj_addr{$addr} = 1;
        _ref_selfref( $obj_addr, $_ ) && return 1 for @$value;
        $$obj_addr{$addr} = 0;
    }
    elsif ( reftype($value) eq 'HASH' ) {

        return $$obj_addr{$addr} if exists $$obj_addr{$addr};
        $$obj_addr{$addr} = 1;
        _ref_selfref( $obj_addr, $_ ) && return 1 for values %$value;
        $$obj_addr{$addr} = 0;
    }

    return;
}

sub ref_clear($) {
    my $ref = shift;
    my %addr;
    require Scalar::Util;
    return unless ( refaddr($ref));
    my @r;
    if ( reftype($ref) eq 'ARRAY' ) {
        @r    = @$ref;
        @$ref = ();
        ref_clear($_) for @r;
    }
    elsif ( reftype($ref) eq 'HASH' ) {
        @r    = values %$ref;
        %$ref = ();
        ref_clear($_) for @r;
    }
}

sub ref_lost_memory($) {
    my $ref = shift;
    my %obj_addr;
    return _ref_selfref( \%obj_addr, $ref );
}

1;
__END__

=head1 NAME

Storable::AMF0 - serializing/deserializing AMF0 data

=head1 SYNOPSIS

  use Storable::AMF0 qw(freeze thaw); # or use Storable::AMF3 qw(freeze thaw) for AMF3 format

  $amf0 = freeze($perl_object);
  $perl_object = thaw($amf0);

	
  # Store/retrieve to disk amf0 data
	
  store $perl_object, 'file';
  $restored_perl_object = retrieve 'file';


  use Storable::AMF0 qw(nstore freeze thaw dclone);

  # Network order: Due to spec of AMF0 format objects (hash, arrayref) stored in network order.
  # and thus nstore and store are synonyms 

  nstore \%table, 'file';
  $hashref = retrieve('file'); 

  
  # Advisory locking
  use Storable::AMF0 qw(lock_store lock_nstore lock_retrieve)
  lock_store \%table, 'file';
  lock_nstore \%table, 'file';
  $hashref = lock_retrieve('file');

  # Deparse one object
  use Storable::AMF0 qw(deparse_amf); 

  my( $obj, $length_of_packet ) = deparse_amf( my $bytea = freeze($a1) . freeze($a) ... );

  - or -
  $obj = deparse_amf( freeze($a1) . freeze($a) ... );

  # JSON::XS boolean support
  
  use JSON::XS;

  $json =  encode_json( thaw( $amf0, parse_serializator_option( 'json_boolean' ))); #  

  $amf_with_boolean = freeze( $JSON::XS::true  or $JSON::XS::false);
  
  # boolean support;

  use boolean;
  $amf_with_boolean = freeze( boolean( 1 or '' ));

  # Options support 
  use Storable::AMF[03] qw(parse_option parse_serializator_option);

  my $options = parse_serializator_option( "raise_error, prefer_number, json_boolean" ); # or parse
  $obj = thaw( $amf, $options );
  $amf = freeze( $obj, $options );

=head1 DESCRIPTION

This module is (de)serializer for Adobe's AMF0/AMF3 (Action Message Format ver 0-3).
This is only module and it recognize only AMF0 data. 
Almost all function implemented in C for speed. 
And some cases faster then Storable( for me always)

=head1 EXPORT

  None by default.

=head1 FUNCTIONS

=over

=item freeze($obj [, $option ]) 
  --- Serialize perl object($obj) to AMF0, and return AMF0 data

=item thaw($amf0, [, $option ])
  --- Deserialize AMF0 data to perl object, and return the perl object

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
  --- recurrent refs clearing . (Succefully destroy recurrent objects with circular links too)

=item ref_lost_memory $obj
  --- test if object contain lost memory fragments inside.
  (Example do { my $a = []; @$a=$a; $a})

=item deparse_amf $bytea 
  --- deparse from bytea one item
  Return one object and number of bytes readed
  if scalar context return object

=item parse_serializator_option( $option_string ) / parse_option( $option_string )
  --- generate option scalar from string usefull for some options of thaw/freeze/deparse_amf 


=back

=head1 OPTIONS
	There are several options supported

=over 4

=item strict

    --- strict mode ( DoS related option)

=item json_boolean

	--- support for JSON::XS boolean

=item prefer_number 

	--- try freezing double val scalars as numbers

=item millisecond_date (depreciated don't use it)

=item raise_error

=item utf8_decode

=item utf8_encode

=back

=head1 LIMITATION

At current moment and with restriction of AMF0/AMF3 format 
referrences to function, filehandles are not serialized,
and can't/may not serialize tied variables.

=head1 FEATURES

	Due bug of Macromedia 'XML' type not serialized properly (it loose all atributes for AMF0) 
	For AMF0 has to use XMLDocument type.

=head1 SEE ALSO

L<Data::AMF>, L<Storable>, L<Storable::AMF3>

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
