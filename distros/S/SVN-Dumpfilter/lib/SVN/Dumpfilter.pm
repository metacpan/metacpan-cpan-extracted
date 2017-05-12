#!/usr/bin/perl -w
# $Id: Dumpfilter.pm 278 2007-01-13 12:37:13Z martin $
# Copyright (C) 2006-2008 by Martin Scharrer <martin@scharrer-online.de>
# This is free software under the GPL.

package SVN::Dumpfilter;
use strict;
use warnings;
use 5.8.1;
use English qw( -no_match_vars );

BEGIN {
    use Exporter ();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

    #use version; $  VERSION = qv('0.21');
    $VERSION = '0.21';

    @ISA    = qw(Exporter);
    @EXPORT = qw(&Dumpfilter &svn_recalc_content_header
      &svn_recalc_textcontent_header &svn_recalc_prop_header);
    %EXPORT_TAGS = (
        'recalc' => [
            qw(svn_recalc_content_header svn_recalc_textcontent_header
              svn_recalc_prop_header)
        ],
        'filters'  => [qw(dos2unix_filter null_filter null_recalc_filter)],
        'internal' => [
            qw(svn_read_entry svn_print_entry svn_get_properties
              svn_props2str svn_header_sanitycheck)
        ],
    );
    @EXPORT_OK = qw(&svn_get_properties &svn_props2str &svn_header_sanitycheck
      &svn_read_entry &svn_print_entry &dos2unix_filter
      &null_filter &null_recalc_filter &svn_remove_entry);
}
our @EXPORT_OK;

#use Data::Dumper; # for Debug output
use Digest::MD5 qw(md5_hex);

our $dumpfile;
our $filepos;
our $dumpfh;
our $outfh;

use vars qw($CR $NL);

BEGIN {
    # "\n" and "\r" are not fully platform independend.
    # So explicite ASCII numbers in octal are used.
    # Variables, not constants, are used because these are used inside regexes.
    $CR = "\015";    # carriage return
    $NL = "\012";    # new line
}

sub svn_get_properties (\%\@$);
sub svn_props2str (\%;\@);
sub svn_header_sanitycheck (\%);
sub svn_recalc_content_header(\%);
sub svn_recalc_textcontent_header(\%);
sub svn_recalc_prop_header(\%);
sub svn_read_entry (*\%;$);
sub svn_print_entry(*\%);
sub svn_remove_entry (\%);

# Filter
sub null_filter (\%;$);
sub null_recalc_filter (\%;$);
sub dos2unix_filter (\%;$);

my @SVNHEADER = qw(
  Revision-number
  Node-path
  Node-kind
  Node-action
  Node-copyfrom-rev
  Node-copyfrom-path
  Prop-delta
  Prop-content-length
  Text-delta
  Text-content-length
  Text-copy-source-md5
  Text-content-md5
  Content-length
);

# "inverse array", maps name to index:
#my %svnhdridx = map { $SVNHEADER[$_] => $_ } (0 .. $#SVNHEADER);

sub _supported_dump_format_version {
    my $version = shift;

    # Versions 1 - 3 are supported
    return ( $version >= 1 && $version <= 3 );
}

###############################################################################
# Dumpfilter
####
# Awaits the dumpfile name, an output file name and a reference to a call-back
# function. While parsing the dumpfile the call-back function is called for
# every node and the result is re-assembled and written to the output file.

sub Dumpfilter {
    $dumpfile = shift;
    my $outfile   = shift;
    my $filtersub = shift;

    if ( !defined $dumpfile ) {
        $dumpfile = '-';    # Defaults to STDIN
    }

    if ( !defined $outfile ) {
        $outfile = '-';     # Defaults to STDOUT
    }
    elsif ( $outfile eq q{} ) {
        $outfile = undef;    # An empty string disables output
    }

    if ( !defined $filtersub || ref $filtersub ne 'CODE' ) {
        print STDERR "No filter function given!\n";
        return 1;
    }

    my $dumpfileerror = 0;

    my $SVN_fs_dump_format_version;
    my $UUID;

    unless ( open( $dumpfh, "<$dumpfile" ) ) {
        print STDERR "Couldn't open dumpfile '$dumpfile'.\n";
        return 1;
    }

    if ( defined $outfile ) {
        unless ( open( $outfh, ">$outfile" ) ) {
            print STDERR "Couldn't open output file '$outfile'.\n";
            return 1;
        }
    }

    my $line;
    local $INPUT_RECORD_SEPARATOR = $NL;
    if ( defined( $line = <$dumpfh> )
        && $line =~ /^SVN-fs-dump-format-version: (\d+)$/ )
    {
        $SVN_fs_dump_format_version = $1;
        if ( !_supported_dump_format_version($SVN_fs_dump_format_version) ) {
            print STDERR "Warning: Found dump format version ",
              "($SVN_fs_dump_format_version) is not supported (yet).\n",
              "Unknown entries will be ignored. Use at your own risk.\n";
        }
        print $outfh $line if defined $outfile;
    }
    else {
        print STDERR "Error: Dumpfile looks invalid. Couldn't find valid ",
          "'SVN-fs-dump-format-version' header.\n";
        chomp($line);
        print STDERR "Found '$line' instead.\n"
          if defined($line);
        return 1;
    }

    # Skip empty lines
    while ( defined( $line = <$dumpfh> ) && $line =~ /^$/ ) {
        print $outfh $line if defined $outfile;
    }
    return 1 unless defined($line);    # check for early EOF

    if ( $line =~ /^UUID: (.*)$/ )     # Save UUID if present
    {
        $UUID = $1;
        print $outfh $line if defined $outfile;

        # Skip empty lines
        while ( defined( $line = <$dumpfh> ) && $line =~ /^$/ ) {
            print $outfh $line if defined $outfile;
        }
    }

    return 1 unless defined($line);    # check for early EOF

    while (1) {
        my $href = {};    # Reference to hash which will hold next entry

        # Read next entry into hash
        $dumpfileerror += svn_read_entry( *$dumpfh, %$href, $line );

        # Filter code comes here
        # We call a filter subfunction and pass everything as a hash
        &{$filtersub}($href);

        # Reassemble of dump data
        next unless ($outfile);    # skip if we don't have an output file
        svn_print_entry( *$outfh, %$href );
    }
    continue {

        # Skip empty lines
        while ( defined( $line = <$dumpfh> ) && $line =~ /^$/ ) {
            print $outfh $line if defined $outfile;
        }
        last unless defined($line);
    }

    close($dumpfh);
    close($outfh) if defined $outfile;
    return $dumpfileerror;
}

#################
# Null filter - does nothing
# For before-after self-checks

sub null_filter (\%;$) {
}

#################
# Null Recalc filter - does nothing except recalculation of headers
# For before-after self-checks

sub null_recalc_filter (\%;$) {
    my $href = shift;
    my $recalc = shift || 1;

    if ($recalc) {
        svn_recalc_prop_header(%$href);
        svn_recalc_textcontent_header(%$href);
    }
}

#################
# Dos to Unix filter - changes end-of-line sequences

sub dos2unix_filter (\%;$) {
    my $href = shift;
    my $recalc = shift || 1;

    my $header = $href->{'header'};
    my $prop   = $href->{'properties'};

    # return when no content present
    return unless exists $header->{'Text-content-length'};

    # skip all files which have a mime-type set to something other than 'text/*'
    return
      if exists $prop->{'svn:mime-type'}
      and $prop->{'svn:mime-type'} !~ m{^text/};
    return if exists $prop->{'svn:eol-style'};    # skip if eol-style is set
         # Skip when text is saved as deltas
    return
      if exists $header->{'Text-delta'}
      and lc( $header->{'Text-delta'} ) eq 'true';

    ${ $href->{'content'} } =~ s/$CR$NL/$NL/mog;

    # Set eol-style:
    push( @{ $href->{'properties_order'} }, 'svn:eol-style' );
    $prop->{'svn:eol-style'} = 'native';

    if ($recalc) {
        svn_recalc_prop_header(%$href);
        svn_recalc_textcontent_header(%$href);
    }
}

#################
# new_scalar_ref - Creates and returns a new scalar reference

sub new_scalar_ref () {
    my $new;
    return \$new;    # For C-Programmers: Yes, this works under Perl!
}

#################
# svn_read_entry - Read node entry from filehandle

sub svn_read_entry (*\%;$) {
    my $infh  = shift;    # Filehandle to read
    my $href  = shift;    # (Empty) Hash (as reference) to write node
    my $line  = shift;    # Optional: First line (already read before)
    my $error = 0;

    # Init hash
    my $header     = ( $href->{'header'}           = {} );
    my $prop       = ( $href->{'properties'}       = {} );
    my $prop_order = ( $href->{'properties_order'} = [] );
    my $content    = ( $href->{'content'}          = new_scalar_ref );

    $filepos = tell($infh);

    local $INPUT_RECORD_SEPARATOR = $NL;    # New line

    $line = <$dumpfh>
      unless defined $line;

    # Should be 'Node-path: ' or 'Revision-number: ' now
    if ( $line !~ /^(Node-path|Revision-number): / ) {
        chomp($line);
        print STDERR
"Read error in dumpfile '$dumpfile' at line '$.'. Skipping line: '$line'\n";
        $error++;
    }

    # Read headers
    do {
        if ( $line =~ /^([^:]+):\s*(.*)$/ ) {
            $header->{$1} = $2;
        }
        else {
            print STDERR "Error in header at input line $.\n";
            $error++;
        }
    } while ( defined( $line = <$infh> ) && $line !~ /^$/ );
    last unless defined($line);    # Safety check for EOF

    # Get properties when they exist (but then they can be empty also!)
    if ( exists $header->{'Prop-content-length'} ) {
        my $prop_lines;
        read $infh, $prop_lines, $header->{'Prop-content-length'};
        $.++ while ( $prop_lines =~ /$NL/go );    # Count lines

        if ( not $prop_lines =~ s/PROPS-END$NL\Z//o ) {
            print STDERR
"Didn't found 'PROPS-END' where it was expected at input line $.\n";
            $error++;
        }

        # Parse lines and extract properties:
        unless ( svn_get_properties( %$prop, @$prop_order, $prop_lines ) ) {
            $error++;
        }
    }

    # Get content
    if ( exists( $header->{'Text-content-length'} ) ) {
        read $infh, $$content, $header->{'Text-content-length'};
        $.++ while ( $$content =~ /$NL/go );    # Count lines
              # TODO: check number of bytes returned
    }

    # Some sanity checks:
    $error += svn_header_sanitycheck(%$header);

    return $error;
}

#################
## svn_print_entry - Write node entry to filehandle

sub svn_print_entry (*\%) {
    my $fh     = shift;            # Filehandle to write to
    my $href   = shift;            # Hash (as reference) with node to be written
    my $header = $href->{'header'};
    my $prop = $href->{'properties'};

    return unless ( keys %$header );    # skip if there are no header

    # Header
    # We try to print all header in the original order.
    {

        # Generate hash to check if all header are printed
        my %header_notprinted = map { $_ => 0 } keys %$header;

        # Print header in the standard order given by @SVNHEADER
        foreach my $head (@SVNHEADER) {
            if ( exists $header->{$head} ) {
                print $fh "$head: $header->{$head}" . $NL;
                delete $header_notprinted{$head};    # delete from check-hash
            }
        }

        # Print all remaining (non-standard?) header
        foreach my $head ( sort keys %header_notprinted ) {
            print $fh "$head: $header->{$head}" . $NL;
            print STDERR "Info: header '$head' unknown by script.\n";
        }
        print $fh $NL;                               # delimiter
    }

    # Properties
    if ( exists $header->{'Prop-content-length'}
        and $header->{'Prop-content-length'} > 0 )
    {
        if ( exists $href->{'properties_order'} ) {
            print $fh svn_props2str( %$prop, @{ $href->{'properties_order'} } );
        }
        else { print $fh svn_props2str(%$prop) }
        print $fh "PROPS-END" . $NL;
    }

    # Content
    if (    exists $header->{'Text-content-length'}
        and $header->{'Text-content-length'} > 0
        and exists $href->{'content'} )
    {
        print $fh ${ $href->{'content'} };
    }
}

#################
## svn_recalc_content_header - Recalculate 'Content-length' header
#####
# Depends on correct values in other headers.
# Will be called by other recalc-functions.

sub svn_recalc_content_header(\%) {
    my $href   = shift;
    my $header = $href->{'header'};
    no warnings 'uninitialized';

    my $header_existed = exists $header->{'Content-length'};

    $header->{'Content-length'} =
      $header->{'Text-content-length'} + $header->{'Prop-content-length'};

    if ( $header->{'Content-length'} == 0 && !$header_existed ) {
        delete $header->{'Content-length'};
    }
}

#################
## svn_recalc_textcontent_header - Recalculate 'Text-content'* and dependend headers
#####

sub svn_recalc_textcontent_header(\%) {
    my $href   = shift;
    my $header = $href->{'header'};

    my $header_existed = exists $header->{'Text-content-length'};

    my $length =
      defined $href->{'content'}
      ? length ${ $href->{'content'} }
      : 0;

    if ( $length == 0 and !$header_existed ) {
        delete $header->{'Text-content-length'};
        delete $header->{'Text-content-md5'};
    }
    else {
        $header->{'Text-content-length'} = $length;
        $header->{'Text-content-md5'}    = md5_hex( ${ $href->{'content'} } );
    }

    svn_recalc_content_header(%$href);
}

#################
## svn_recalc_prop_header - Recalculate 'Prop-content-length' and dependend headers
#####

sub svn_recalc_prop_header(\%) {
    my $href   = shift;
    my $header = $href->{'header'};
    my $prop   = $href->{'properties'};

    return unless keys %$prop;    # do nothing when no properties are present

    # Correct properties length:
    $header->{'Prop-content-length'} = 10    # for the "PROPS-END$NL" string
      + length( svn_props2str( %{ $href->{'properties'} } ) );
    svn_recalc_content_header(%$href);
}

#################
## svn_get_properties - Extracts properties from a formatted string
#####
# Opposite of 'svn_props2str'
# Could also be called 'svn_str2props'

sub svn_get_properties (\%\@$) {
    my $prophash  = shift;    # Hash reference to store properties
    my $proporder = shift;    # Array ref. to store order of properties
    my $props     = shift;    # String in SVN property format to parse

    # Parse string
    while ( defined($props) ) {

        # Look for Keyword
        ( $props =~ s/^K (\d+)$NL//o ) or last;
        my $key = substr( $props, 0, $1, '' );    # get key with length given by
                # above line and replace it with an null-string
        $props =~ s/^$NL//o;    # delete trailing new-line

        # Look for Value
        ( $props =~ s/^V (\d+)$NL//o ) or last;
        my $value =
          substr( $props, 0, $1, '' );    # get value with length given by
               # above line and replace it with an null-string
        $props =~ s/^$NL//o;    # delete trailing new-line

        # Save
        push( @$proporder, $key );
        $prophash->{$key} = $value;
    }

    # Deleted properties
    while ( defined($props) ) {
        ( $props =~ s/^D (\d+)$NL//o ) or last;
        my $key = substr( $props, 0, $1, '' );    # get key with length given by
                # above line and replace it with an null-string
        $props =~ s/^($NL)//o;    # delete trailing new-line
        $prophash->{__DELETED_PROPERTIES__} .= $key . ( defined($1) ? $1 : '' );
    }

    # Read unkown but valid looking entries
    while ( defined($props) ) {
        ( $props =~ s/^([A-Z] (\d+)$NL)//o ) or last;
        my $head = $1;
        my $key = substr( $props, 0, $2, '' );    # get key with length given by
             # above line and replace it with an null-string
        $props =~ s/^($NL)//o;    # delete trailing new-line
        print STDERR "Error: Found unknown entry in property field:\n------\n",
          $head, $key, "\n";
        $prophash->{__UNKNOWN_PROPERTY_ENTRY__} .=
          $head . $key . ( defined($1) ? $1 : '' );
    }

    # Debug output
    #print Data::Dumper->Dump([\$prophash, \$proporder], ['prophash',
    #  'proporder']) if @$proporder;

    if ( length($props) != 0 )    # parse errors
    {
        print STDERR "Error at parsing properties at input line $.:",
          "Couldn't understand '$props'.\n";
        return 0;
    }

    return 1;
}

#################
## svn_props2str - Converts properties to a formatted string
#####
# Opposite of 'svn_get_properties';
# Returns formatted string in SVN property format

sub svn_props2str (\%;\@) {
    my $prophash  = shift;          # Hash ref. with properties
    my $proporder = shift || [];    # Array ref. with properties order
    my $props     = '';             # Return string

    # Create check-hash
    my %prop_notprinted = map { $_ => 0 } ( keys %$prophash );

    # Print properties by given order
    foreach my $key (@$proporder) {
        $props .= 'K '
          . length($key)
          . $NL
          . $key
          . $NL . 'V '
          . length( $prophash->{$key} )
          . $NL
          . $prophash->{$key}
          . $NL;
        delete $prop_notprinted{$key};    # printed so delete from check-hash
    }

    # Print now all remaining properties (if any)
    foreach my $key ( sort keys %prop_notprinted ) {
        $props .= 'K '
          . length($key)
          . $NL
          . $key
          . $NL . 'V '
          . length( $prophash->{$key} )
          . $NL
          . $prophash->{$key}
          . $NL;
    }

    # Print list of deleted properties
    if ( exists $prophash->{__DELETED_PROPERTIES__} ) {
        my $value = $prophash->{__DELETED_PROPERTIES__};
        $props .= 'D ' . length($value) . $NL . $value . $NL;
    }

    # Print unknown entries
    if ( exists $prophash->{__UNKNOWN_PROPERTY_ENTRY__} ) {
        $props .= $prophash->{__UNKNOWN_PROPERTY_ENTRY__};
    }

    return $props;
}

#################
## svn_header_sanitycheck - Checks if needed header exists and belong to each other
#####

sub svn_header_sanitycheck (\%) {
    my $header = shift;
    my $error  = 0;

    # Revision entry needs also 'Prop-content-length' and 'Content-length'
    if ( exists $header->{'Revision-number'} ) {
        if (   !exists $header->{'Prop-content-length'}
            || !exists $header->{'Content-length'} )
        {
            print STDERR
              "Missing needed header(s) after 'Revision-number' at line $..\n";
            $error++;
        }
    }

   # if ( exists $header->{'Node-path'} ) # Must have 'Node-path' yet because of
   # above tests (see begin of while loop)
   # Nodes need 'Node-action' at minimum.
    elsif ( !exists $header->{'Node-action'} ) {
        print STDERR
          "Missing needed header 'Node-action' after 'Node-path' at line $..\n";
        $error++;
    }
    else    # 'Node-action' exists:
    {
        my $action = $header->{'Node-action'};    # buffer
        if ( $action eq 'delete' ) {
            my $num_headers_expected =
              ( exists $header->{'Node-kind'} ) ? 3 : 2;

            if ( keys %$header != $num_headers_expected ) {
                print STDERR
                  "Two much headers for 'Node-action: delete' at line $.:\n";
                local $, = "\n";

                while ( my ( $key, $value ) = each %$header ) {
                    print STDERR "$key: $value\n";
                }
                $error++;
            }
        }
        elsif ( $action eq 'add' or $action eq 'replace' ) {
            if ( !exists $header->{'Node-kind'} ) {
                print STDERR
"Missing header 'Node-kind' for 'Node-action: add' at line $..\n";
                $error++;
            }
            elsif ( $header->{'Node-kind'} eq 'file' ) {
                unless (    # This two header both exist
                    (
                           exists $header->{'Text-content-length'}
                        && exists $header->{'Text-content-md5'}
                        && !(    # and this two both exist or both non-exist
                            exists $header->{
                                'Node-copyfrom-rev'} ^    #\ xor+negation
                            exists $header->{
                                'Node-copyfrom-path'}     #/ = equivalence
                        )
                    )
                    || (    # This two header both exist
                        exists $header->{'Node-copyfrom-rev'}
                        && exists $header->{'Node-copyfrom-path'}
                        && !(    # and this two both exist or both non-exist
                            exists $header->{
                                'Text-content-length'} ^    #\ xor+negation
                            exists $header->{
                                'Text-content-md5'}         #/ = equivalence
                        )
                    )
                  )
                {    # then there is something wrong
                    print STDERR
"Missing/wrong header(s) for 'Node-action: add'/'Node-kind: ",
                      "file' ", "at line $..\n";
                    $error++;
                }
            }
            elsif ( $header->{'Node-kind'} eq 'dir' ) {
                if (   exists $header->{'Text-content-length'}
                    || exists $header->{'Text-content-md5'} )
                {
                    print STDERR
"To much header(s) for 'Node-action: add'/'Node-kind: dir' ",
                      "at line $..\n";
                    $error++;
                }
            }
            else {
                print STDERR "Invalid value '", $header->{'Node-kind'},
                  "' for 'Node-kind' ", "at line $..\n";
                $error++;
            }
        }
        elsif ( $action eq 'change' ) {

        }
        else {

        }
    }    # end of else path of "if ( !exists $header->{'Node-action'} )"

    #print STDERR Data::Dumper->Dump([$header], ['%header']) if $error;
    return $error;
}

#################
## svn_remove_entry - Removes given entry, i.e. cleans entry hash, so that
## this entry is not part of the output dump file.
#####
sub svn_remove_entry (\%) {
    my $href = shift;

    %$href = ();
}

1;
__END__

# Documentation

=head1 NAME

SVN::Dumpfilter - Perl extension to filter Subversion dumpfiles

=head1 SYNOPSIS

  use SVN::Dumpfilter;
  
  sub my_filter (\%;$);
  my $dumpfile = shift @ARGV; # filename or '-' for STDIN
  my $outfile  = shift @ARGV; # filename or '-' for STDOUT
  
  Dumpfilter($dumpfile, $outfile, \&my_filter);

  sub my_filter (\%;$)
   {
     my $href   = shift;
     my $recalc = shift || 0;
     my $header = $href->{'header'};
     my $prop   = $href->{'properties'};
  
     # Do something (modify, add, delete) with the current node given by the
     # hash ref $href
     # e.g.:
     if (exists $header->{Node-path})
      {
       $header->{Node-path} =~ s/OLD/NEW/;
       $recalc = 1;
      }
  
     # The node content is accessible as scalar with ${$href->{content}}
     # Can be in every possible text or binary format.
  
     if ($recalc)
      {
       svn_recalc_prop_header(%$href);        # call if you changed properties
       svn_recalc_textcontent_header(%$href); # call if you modified text content
      }
   }


  To filter a dumpfile:
  shell #  svnadmin create /path/to/new/repository
  shell #  svnadmin dump /path/to/repository | my_svndumpfilter - - | svnadmin load /path/to/new/repository

=head1 DESCRIPTION

SVN::Dumpfilter reads a Subversion (http://subversion.tigris.org/) dumpfile.
The file is parsed and a call-back subfunction is called with a hash-reference for
every 'node'. This function can modify, add or delete headers, properties and
the content of the node. After processing of the call-back function the node is
re-assembled and stored in an output file.

The parse and re-assemble processes are done by dedicated subfunctions which
can be also exported ('internal' tag) for special filters (e.g. merging filter
which has to write the output file by its own).

The node hash looks like this for a normal node:

$href = {
          'content' => \'(content)', # scalar ref 
          'properties_order' => [],  # array ref (helps with verification, but not needed)
          'properties' => {},        # hash ref
          'header' => {              # hash ref
                        'Content-length' => '922',
                        'Text-content-length' => 922,
                        'Node-action' => 'change',
                        'Node-kind' => 'file',
                        'Node-path' => 'trunk/filename.pl',
                        'Text-content-md5' => 'c7ed3072d412de68da477350f8e8056f'
                      }
        };

and like this for a revision node:

$href = {
          'properties_order' => [
                                  'svn:log',
                                  'svn:author',
                                  'svn:date'
                                ],
          'properties' => {
                            'svn:log' => 'Log message, ...',
                            'svn:date' => '2006-05-10T13:31:40.486172Z',
                            'svn:author' => 'martin'
                          },
          'header' => {
                        'Content-length' => '151',
                        'Prop-content-length' => 151,
                        'Revision-number' => '58'
                      }
        };

=head2 EXPORT

By default:

&Dumpfilter &svn_recalc_content_header &svn_recalc_textcontent_header &svn_recalc_prop_header

Tags:

=over 4

=item C<'recalc'>

svn_recalc_content_header svn_recalc_textcontent_header svn_recalc_prop_header

=item C<'filters'>

dos2unix_filter null_filter null_recalc_filter

=item C<'internal'>

svn_read_entry svn_print_entry svn_get_properties svn_props2str svn_header_sanitycheck

=back

=head1 SEE ALSO

Authors Module Website: L<http://www.scharrer-online.de/svn/dumpfilter.shtml>

=head1 AUTHOR

Martin Scharrer, E<lt>martin@scharrer-online.deE<gt>; 
L<http://www.scharrer-online.de/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2008 by Martin Scharrer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

