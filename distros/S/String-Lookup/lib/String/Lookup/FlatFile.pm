package String::Lookup::FlatFile;
$VERSION= 0.14;

# what runtime features we need
use 5.014;
use warnings;
use autodie qw( binmode close open );

# modules that we need
no  bytes;
use Encode qw( is_utf8 _utf8_on );

# initializations
my $format= 'Nnc';

# satisfy -require-
1;

#-------------------------------------------------------------------------------
#
# Class Methods
#
#-------------------------------------------------------------------------------
# flush
#
#  IN: 1 class
#      2 options hash ref
#      3 underlying list ref with strings
#      4 list ref with ID's to be flushed
# OUT: 1 boolean indicating success

sub flush {
    my ( $class, $options, $list, $ids )= @_;

    # initializations
    local $_;
    my $handle= $options->{handle};

    # write all ID's
    foreach my $id ( @$ids ) {
        print( $handle
          pack( $format, $id, bytes::length($_), is_utf8($_) ), $_ ) ||
          die "Error writing data: $!"
          foreach $list->[$id];
    }

    # make sure it's on disk
    die "Could not flush data: $!" if !defined $handle->flush;

    return 1;
} #flush

#-------------------------------------------------------------------------------
# init
#
#  IN: 1 class
#      2 options hash ref
# OUT: 1 hash ref with lookup

sub init {
    my ( $class, $options )= @_;

    # defaults
    state $headerlen= 7;
    $options->{dir} //= $ENV{STRING_LOOKUP_FLATFILE_DIR};

    # sanity check
    my @errors;
    push @errors, "Must have a 'dir' specified" if !$options->{dir};
    push @errors, "Must have a 'tag' specified" if !$options->{tag};
    die join "\n", "Found the following problems with init:", @errors
      if @errors;

    # initializations
    my %hash;
    my $filename= "$options->{dir}/$options->{tag}.lookup";

    # set up reading of file if there is one
    if ( -s $filename ) {
        open my $handle, '<', $filename;
        binmode $handle;

        # while we have something
        my ( $bytes, $header, $id, $stringlen, $string, $utf8on );
        while ( $bytes= read $handle, $header, $headerlen ) {
            die "Did not read complete header: only $bytes of $headerlen"
              if $bytes != $headerlen;

            # fetch ID and string
            ( $id, $stringlen, $utf8on )= unpack $format, $header;
            $bytes= read $handle, $string, $stringlen;
            die "Error reading data: $!" if !defined $bytes;
            die "Did not read complete data: only $bytes of $stringlen"
              if $bytes != $stringlen;

            # store it in the right way
            _utf8_on($string) if $utf8on;
            $hash{$string}= $id;
        }

        # all ok?
        die "Error reading header: $!" if !defined $bytes;
        close $handle;
    }

    # open file for flushing (again)
    open my $handle, '>>', $filename;
    binmode $handle;
    $options->{handle}= $handle;

    return \%hash;
} #init

#-------------------------------------------------------------------------------
# parameters_ok
#
#  IN: 1 class (not used)
# OUT: 1 .. N parameter names

sub parameters_ok { state $ok= [ qw( dir ) ]; @{$ok} } #parameters_ok

#-------------------------------------------------------------------------------

__END__

=head1 NAME

String::Lookup::FlatFile - flush String::Lookup to flat files

=head1 SYNOPSIS

 use String::Lookup;

 tie my %lookup, 'String::Lookup',

   # standard persistent storage parameters
   storage => 'FlatFile', # store in a flat file
   tag     => $tag,       # name of flat file for this lookup hash
   fork    => 1,          # fork for each flush, default: no

   # parameters specific to 'FlatFile'
   dir     => $dir,       # directory in which flat files are stored

   # other parameters for String::Lookup
   ...
 ;

=head1 VERSION

This documentation describes version 0.14.

=head1 DESCRIPTION

This module is a class for providing persistent storage for lookup hashes,
as provided by L<String::Lookup>.

Please see the C<METHODS IN STORAGE MODULE> section in L<String::Lookup> for
documentation on which methods this storage class provides.

=head1 ADDITIONAL PARAMETERS

The following additional parameters are provided by this storage class:

=over 4

=item dir

 tie my %lookup, 'String::Lookup',
   dir     => $dir,       # directory in which flat files are stored
 ;

Indicate the directory in which the lookup hash will be stored in flat files.
Defaults to the content of the C<STRING_LOOKUP_FLATFILE_DIR> environment
variable.  C<Must be specified> either directly or indirectly with the
environment variable.

=back

=head1 REQUIRED MODULES

 (none)

=head1 AUTHOR

 Elizabeth Mattijsen

=head1 COPYRIGHT

Copyright (c) 2012 Elizabeth Mattijsen <liz@dijkmat.nl>.  All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
