# -*- cperl -*-
# ABSTRACT: Aux file parser


use strict;
use warnings;
package SpeL::Parser::Auxiliary;

use parent 'Exporter';
use Carp;

use IO::File;
use File::Basename;

our $grammar = do {
  use Regexp::Grammars;
  qr{
#      <debug: on>

      <[line]>+ <endinput>

      <nocontext:>

      <token: line> ( <newlabel> | <bibcite> | <.otherwise> ) \n

      <token: newlabel> \\ newlabel <label=Arg> \{ <[args=Arg]>{5} \}

      <token: label> [^\}]+

      <token: bibcite> \\ bibcite <label=Arg> <text=Arg>

      <token: otherwise> [^\n]*

      <token: Arg> \{ <MATCH=TokSeq> \}
                   |
		   <context:>
		   \{ <left=TokSeq> <mid=Arg> <right=TokSeq> \}

      <token: TokSeq> ([^\{\}]*)

      <token: endinput> \\ endinput

  }xms
};

# to debug:
#      <logfile: - >
#      <debug: on>


sub new {
  my $class = shift;

  my $self = {};
  $class = (ref $class ? ref $class : $class );
  bless $self, $class;

  $self->{lines} = [];
  $self->{lineinfo} = [];
  return $self;
}


sub parseAuxFile {
  my $self = shift;
  my ( $filename ) = @_;

  my $file = IO::File->new();
  $file->open( "<$filename" )
    or croak( "Error: canot open aux file '$filename' for reading\n" );
  @{$self->{lines}} = <$file>;

  # setup lineposition bookkeeping
  my $firstlineindex = 0;
  @{$self->{lineinfo}} =
    map{ my $retval = $firstlineindex;
         $firstlineindex += length( $_ );
         $retval
       } @{$self->{lines}};
  push @{$self->{lineinfo}}, $self->{lineinfo}->[-1] + 1;

  # parse
  my $contents = join( '', @{$self->{lines}} ) . '\endinput';

  my $result;
  if ( $result = ( $contents ) =~ $SpeL::Parser::Auxiliary::grammar ) {
    $self->{tree} = \%/;
  }
  else {
    $![0] =~ /^(.*)__(\d+),(\d+)__(.*)$/;
    $![0] = $1 . $self->_errloc( $3 ) . $4;
    die( "Error: failed to parse $filename\n" .
         "=> " . join( "\n   ", @! ) . "\n" );
  }
  delete $self->{lines};
  delete $self->{lineinfo};

  # say STDERR Data::Dumper->Dump( [ $self ] , [ qw (doc) ] );
}



sub parseAuxString {
  my $self = shift;
  my ( $string ) = @_;

  $string .= "\n\\endinput";

  my $result;
  if ( $result = ( $string ) =~ $SpeL::Parser::Auxiliary::grammar ) {
    return \%/;
  }
  else {
    $![0] =~ /^(.*)__(\d+),(\d+)__(.*)$/;
    $![0] = $1 . $self->_errloc( $3 ) . $4;
    die( "Error: failed to parse string\n" .
	 "=> " . join( "\n   ", @! ) . "\n" );
  }
}


sub object {
  my $self = shift;
  return $self;
}


sub database {
  my $self = shift;
  my $db = {};
  for my $line ( @{$self->{tree}->{line}} ) {
    if ( ref( $line ) eq 'HASH' ) {
      foreach my $key ( (keys %$line)[0] ) {
	$key =~ /bibcite/ and do {
	  $db->{$key}->{$line->{$key}->{label}} = $line->{$key}->{text};
	};
	$key =~ /newlabel/ and do{
	  # if the caption text field of the label contains curly brackets,
	  # the field will be the hash of the Regexp::Grammars parser and
	  # we need to replace it by its context field:
	  if ( ref( $line->{$key}->{args}->[2] )  eq 'HASH' ) {
	    $line->{$key}->{args}->[2] = $line->{$key}->{args}->[2]->{''};
	    # remove the opening and closing curly brace
	    $line->{$key}->{args}->[2] =~ s/^\{(.*)\}$/$1/;
	  }
	  $db->{$key}->{$line->{$key}->{label}} = $line->{$key}->{args};
	};
      }
    }
  }
  return $db;
}


sub _report {
  my ( $match ) = @_;
  return "__$match->{matchpos},$match->{matchline}__";
}


sub _errloc {
  my $self = shift;
  my ( $matchline ) = @_;
  return "line $matchline";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SpeL::Parser::Auxiliary - Aux file parser

=head1 VERSION

version 20240617.1739

=head1 METHODS

=head2 new()

creates a new aux-file parser

=head2 parseAuxFile( filename )

parses the aux file with name $fn

=over 4

=item filename: name of the aux-file to parse

=back

=head2 parseAuxString( string )

parses the string containing the aux file contents

=over 4

=item string: string containg the aux file contents

=back

=head2 object()

accessor

=head2 database()

build and return the database (construction and accessor)

=head2 _report( matchinfo )

auxiliary (private) routine to do the error reporting; warning: this is not a member function!

=head2 _errorloc( matchinfo )

auxiliary (private) routine to format the error locatoin.

=head1 SYNOPSYS

Parses .aux files

=head1 AUTHOR

Walter Daems <wdaems@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Walter Daems.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=head1 CONTRIBUTOR

=for stopwords Paul Levrie

Paul Levrie

=cut
