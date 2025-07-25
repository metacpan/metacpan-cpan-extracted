# -*- cperl -*-
package SpeL::Object::Command;
# ABSTRACT: SpeL command object


use strict;
use warnings;

use parent 'Exporter';
use Carp;

use SpeL::Object::Option;
use SpeL::Object::ElementList;

use SpeL::I18n;

our $macrohash = {};
our $labelhash = {};
our $citationhash = {};



sub read {
  my $self = shift;
  my ( $level ) = @_;

  my $command = $self->{Name};

  my $returnvalue = ' ';

  
  # 1. check if this macro can be found
  if ( exists $SpeL::Object::Command::macrohash->{$command} ) {
    my $macro = $SpeL::Object::Command::macrohash->{$command};

    $macro->{argc} = 0 if ( $macro->{argc} eq '-NoValue-' );
    
    # make parameter list
    my @parameterlist;
    # 1. perform sanity check: if the macro has a '-NoValue-' optarg,
    #    then there cannot be any <Options> field in the Command. Fatal error!
    croak( "Error: usage of macro not consistent with its definition\n" .
	   "The definition \\$command does not specify optional values, " .
	   "while the usage specifies an optional argument.\n" )
      if ( $macro->{optarg} eq '-NoValue-'
	   and exists $self->{Options} );

    # 2. Check if the <Options> field exists, then push this onto parameter list
    #          else, grab the optarg and if it is valid, push that on the list
    if ( exists $self->{Options} ) {
      push @parameterlist, $self->{Options}->read( $level + 1 );
    } else {
      push @parameterlist, $macro->{optarg}
	unless $macro->{optarg} eq '-NoValue-';
    }

    # 3. Push all remaining <[Args]> onto the parameter list
    foreach my $arg ( @{$self->{Args}} ) {
      push @parameterlist, $arg->read( $level + 1 );
    }

    # 4. perform sanity check: the marco's argc should be equal or higher
    #    to length of the parameter list. Fatal error!
    #    too many arguments are just parsed as if they were in 'trailing'
    #    grouping brackets
    croak( "Error: usage of macro not consistent with its definition\n" .
	   "The definition of \\$command does specify $macro->{argc} arguments " .
	   "while the usage specifies @{[ scalar @parameterlist ]} arguments.\n" )
      if ( scalar @parameterlist < $macro->{argc} );

    # make the return value
    # 5. replace the parameter tags in the 'reader' field of the macro, with
    #    the 'read' versions of the parameters.
    my $returnvalue = ' ';

    # 1. check fi it is a LaTeX special macro:
    if ( $command eq 'ref' ) {
      # 1. Check whether this is a ref
      my $arg = $parameterlist[0];
      # say STDERR Data::Dumper->Dump( [ $SpeL::Object::Command::labelhash ], [ qw(lh) ] );
      die( "Error: could not find reference '$arg'\n" )
	unless exists $SpeL::Object::Command::labelhash->{$arg};
      $returnvalue .=
	$SpeL::Object::Command::labelhash->{$arg}->[0];
    }
    elsif ( $command eq 'pageref' ) {
      my $arg = $parameterlist[0];
      die( "Error: could not find reference '$arg'\n" )
	unless exists $SpeL::Object::Command::labelhash->{$arg};
      $returnvalue .=
	$SpeL::Object::Command::labelhash->{$arg}->[1];
    }
    elsif ( $command eq 'cite' ) {
      my $arg = $parameterlist[0];
      die( "Error could not find citation '$arg'\n" )
	unless exists $SpeL::Object::Command::citationhash->{$arg};
      $returnvalue .=
	'(see reference ' .
	$SpeL::Object::Command::citationhash->{$arg} . ')';
    }
    else {
      # strip any i18n constructs and replace them with... wat?
      my @limbs = split( /(\@\{i18n\([^)]+\)\})/, $macro->{reader} );
      foreach my $limb (@limbs) {
	# treat i18n calls
	my $i18nargs;
	if ( ( $i18nargs ) = ( $limb =~ /^\@\{i18n\(([^)]+)\)\}/ ) ) {
	  
	  $limb = $SpeL::I18n::lh
	    ->maketext( split( /\s*,\s*/, $i18nargs ) );
	}
	
	# then treat arguments
	for( my $i = 1; $i <= $macro->{argc}; ++$i ) {
	  $limb =~ s/##$i/$parameterlist[$i-1]/g;
	}
	$returnvalue .= $limb;
      }
    }

    # add trailing grouping brackets
    for( my $i = $macro->{argc}; $i < @parameterlist ; ++$i ) {
      $returnvalue .= ' ' . $parameterlist[$i];
    }

    if ( $command eq 'text' ) {
      $returnvalue =~ s/~/ /g;
    }

    # 6. This is the return value
    return $returnvalue;
  }
  else {
    croak( "Error: there is no reader definition for the macro with name $command.\n" .
	   "       Consider adding it to your LaTeX source using the \\spelmacad macro.\n" );
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SpeL::Object::Command - SpeL command object

=head1 VERSION

version 20250511.1428

=head1 METHODS

=head2 new()

We keep the default method, as the object is generated by the parser.

=head2 read( level )

returns a string with the spoken version of the node

=over 4

=item level: parsing level

=back

=head1 SYNOPSYS

Represents a LaTeX command

=head1 AUTHOR

Walter Daems <wdaems@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Walter Daems.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=head1 CONTRIBUTOR

=for stopwords Paul Levrie

Paul Levrie

=cut
