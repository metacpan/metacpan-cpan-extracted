package String::Lookup::AsyncDBI;
$VERSION= 0.13;

# what runtime features we need
use 5.014;
use warnings;
use autodie qw( binmode close mkdir open );

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
    my $filename= "$options->{tagdir}/" . time . ".lookup";
    
    # open file for flushing (again)
    open my $handle, '>>', $filename;
    binmode $handle;

    # write all ID's
    foreach my $id ( @$ids ) {
        print( $handle
          pack( $format, $id, bytes::length($_), is_utf8($_) ), $_ ) ||
          die "Error writing data: $!"
          foreach $list->[$id];
    }

    # make sure it's on disk
    die "Could not flush data: $!" if !$handle->close;

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

    # sanity check
    my @errors;
    push @errors, "Must have a 'dir' specified" if !$options->{dir};
    push @errors, "Must have a 'tag' specified" if !$options->{tag};
    my $tagdir= $options->{tagdir}= "$options->{dir}/$options->{tag}";
    eval { mkdir $tagdir }; # don't care whether worked

    # too bad
    die join "\n", "Found the following problems with init:", @errors
      if @errors;

    # initializations
    state $headerlen= 7;
    my %hash;

    # set up reading of all files in tagdir
    foreach my $filename ( grep { -s } glob "$tagdir/*.lookup" ) {
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

    return \%hash;
} #init

#-------------------------------------------------------------------------------
# parameters_ok
#
#  IN: 1 class (not used)
# OUT: 1 .. N parameter names

sub parameters_ok { state $ok= [qw( dir ) ]; @{$ok} } #parameters_ok

#-------------------------------------------------------------------------------

__END__

=head1 NAME

String::Lookup::AsyncDBI - flush String::Lookup to flat files

=head1 SYNOPSIS

 use String::Lookup;

 tie my %lookup, 'String::Lookup',

   # standard persistent storage parameters
   storage => 'AsyncDBI', # store in a flat file per epoch
   tag     => $tag,       # name of directory for this lookup hash
   fork    => 1,          # fork for each flush, default: no

   # parameters specific to 'AsyncDBI'
   dir     => $dir,       # directory in which tag directories are stored

   # other parameters for String::Lookup
   ...
 ;

=head1 VERSION

This documentation describes version 0.13.

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

Indicate the directory in which directories will be created per tag.  The
actual flat files will be stored in there per second.
Defaults to the content of the C<STRING_LOOKUP_ASYNC_DIR> environment
variable.  C<Must be specified> either directly or indirectly with the
environment variable.

=back 4

=head1 REQUIRED MODULES

 (none)

=head1 AUTHOR

 Elizabeth Mattijsen

=head1 COPYRIGHT

Copyright (c) 2012 Elizabeth Mattijsen <liz@dijkmat.nl>.  All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
