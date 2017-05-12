#
# This file is part of Soar-WM
#
# This software is copyright (c) 2012 by Nathan Glenn.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Soar::WM::Slurp;

use strict;
use warnings;
use 5.010;
use autodie;
use Carp;

use base qw(Exporter);
our @EXPORT_OK = qw(read_wm_file read_wm);

our $VERSION = '0.04'; # VERSION
# ABSTRACT: Read and parse Soar working memory dumps

say Dump read_wm( file => $ARGV[0] ) unless caller;

sub read_wm_file {
    my ($file) = @_;
    return read_wm( file => $file );
}

#structure will be:
# return_val->{$wme} = { $attr=>[@values]}
# {'root_wme'} = 'S1' or some such
#parse a WME dump file and create a WM object; return the WM hash and the name of the root WME.
sub read_wm {    ## no critic (RequireArgUnpacking)
    my %args = (
        text => undef,
        file => undef,
        @_
    );
    my $fh;
    if ( $args{text} ) {
        $fh = _get_fh_from_string( $args{text} );
    }
    elsif ( $args{file} ) {
        $fh = _get_fh( $args{file} );
    }
    else {
        $fh = \*STDIN;
        print "Reading WME dump from standard in.\n";
    }

    #control variables
    my ( $hasOpenParen, $hasCloseParen );

    #keep track of results/return value
    my ( $root_wme, %wme_hash );
    while ( my $inline = <$fh> ) {
        chomp $inline;
        next if $inline eq '';
        my $line = "";

        #note: do we need $hasOpenParen?
        $hasOpenParen  = ( $inline =~ /^\s*\(/ );
        $hasCloseParen = ( $inline =~ /\)\s*$/ );

        #read entire space between parentheses
        while ( $hasOpenParen && !($hasCloseParen) ) {
            chomp $inline;
            $line .= $inline;
            $inline = <$fh>;

            #if this line of the WME dump is incomplete, ignore it.
            if ( !$inline ) {
                $inline = '';
                $line   = '';
                last;
            }
            $hasCloseParen = ( $inline =~ /\)\s*$/ );
        }
        $line .= $inline;
        if ($line) {

            #separate wme and everything else [(<wme> ^the rest...)]
            my ( $wme, $rest ) = split " ", $line, 2;

            # initiate the record
            my $rec = {};

            # hash each of the attr/val pairs
            my @attVals = split /\^/, $rest;

            #if line were 'S16 ^foo bar ^baz biff', then @attvals
            #now contains ['S16', 'foo bar', 'baz biff']

            #get rid of the WME ID
            shift @attVals;

            foreach my $attVal (@attVals) {
                my ( $attr, $val ) = split " ", $attVal;
                if ( !length($attr) ) {    #note: would this ever happen?
                    next;
                }

                #get rid of final parenthesis
                $val =~ s/\)$//;

                # store attr/val association in the record
                push @{ $rec->{"$attr"} }, $val;
            }

            #strip opening parenthesis
            $wme =~ s/^\(//;

            # $rec->{'#wmeval'} = $wme;

            #rootwme is S1, or similar
            $root_wme = $wme unless $root_wme;

            # add the record to the wme hash
            $wme_hash{$wme} = $rec;
        }
    }
    close $fh;
    return \%wme_hash, $root_wme;
}

sub _get_fh_from_string {
    my ($text) = @_;
    open my $sh, '<', \$text;
    return $sh;
}

sub _get_fh {
    my ($name) = @_;
    return $name if ref $name eq 'GLOB';
    open my $fh, '<', $name;
    return $fh;
}

1;

__END__

=pod

=head1 NAME

Soar::WM::Slurp - Read and parse Soar working memory dumps

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  use Soar::WM::Slurp qw(read_wm);
  use Data::Dumper;
  my ($WM_hash, $root_name) = read_wm(file => 'path/to/wme/dump/file');
  print 'root is ' . $root_name;
  print Dumper($WM_hash);

=head1 NAME

Soar::WM::Slurp - Perl extension for slurping Soar WME dump files.

=head1 DESCRIPTION
This module can be used to read in a Soar WME dump file. It exports one function, read_wm, which reads a WME dump and returns a hash pointer representing it.

=head1 METHODS

=head2 C<read_wm_file>
A shortcut for C<read_wm( file=>$arg )>

=head2 C<read_wm>
Takes a named argument, either file => 'path/to/file', file => $fileGlob, or text => 'WME dump here'.
Returns a pointer to a hash structure representing the input WME dump, and the name of the root WME, in a list like this: ($hash, $root).

Note that any incomplete WME structures will be ignored; for example:

	(S1 ^foo bar ^baz boo ^link S2)
	(S2 ^faz far ^boo baz ^fuzz buzz

The second line in the above text will be ignored. Although some of the structure there is apparent, accepting incomplete structures would require much more 
error and input checking. WME dumps are normally complete, so this should not be a problem.

=head1 AUTHOR

Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nathan Glenn.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
