# $Id: APO_ID_Term_Map.pm 2013-02-20 erick.antezana $
#
# Module  : APO_ID_Term_Map.pm
# Purpose : A (birectional) map APO_ID vs Term name.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
package OBO::APO::APO_ID_Term_Map;

=head1 NAME

OBO::APO::APO_ID_Term_Map - A map between APO IDs and term names.
    
=head1 SYNOPSIS

use OBO::APO::APO_ID_Term_Map;

$apo_id_set  = APO_ID_Term_Map -> new;

$apo_id_set->file("ontology.ids");

$file = $apo_id_set -> file;

$size = $apo_id_set -> size;

$apo_id_set->file("APO");

if ($apo_id_set->add("APO:C1234567")) { ... }

$new_id = $apo_id_set->get_new_id("APO", "C");

=head1 DESCRIPTION

The OBO::APO::APO_ID_Term_Map class implements a map for storing APO IDs and their corresponding names.

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

our @ISA = qw(OBO::XO::OBO_ID_Term_Map);
use OBO::XO::OBO_ID_Term_Map;
use Carp;
use strict;

use open qw(:std :utf8); # Make All I/O Default to UTF-8

use OBO::APO::APO_ID_Set;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{FILE} = shift;

    %{ $self->{MAP_BY_ID} }   = ();    # key=apo_id; value=term name
    %{ $self->{MAP_BY_TERM} } = ();    # key=term name; value=apo_id
    $self->{KEYS} = OBO::APO::APO_ID_Set->new();

    bless( $self, $class );

    confess if ( !defined $self->{FILE} );

    # if the file exists:
    if ( -e $self->{FILE} && -r $self->{FILE} ) {
        open( APO_ID_MAP_IN_FH, "<$self->{FILE}" );
        while (<APO_ID_MAP_IN_FH>) {
            chomp;
            if ( $_ =~ /(APO:[A-Z][a-z]?[0-9]{7})\s+(.*)/ ) { ### vlmir
            my ( $key, $value ) = ( $1, $2 );                 # e.g.: APO:I1234567		test
				$self->{MAP_BY_ID}->{$key}     = $value;      # put
				$self->{MAP_BY_TERM}->{$value} = $key;        # put
            } else {
            	warn "\nThe following entry: '", $_, "' found in '", $self->{FILE}, "' is not recognized as a valid APO key-value pair!";
            }
        }
        close APO_ID_MAP_IN_FH;
    }
    else {
        open( APO_ID_MAP_IN_FH, "$self->{FILE}" );
        # TODO Should I include a date?
        close APO_ID_MAP_IN_FH;
    }

    $self->{KEYS}->add_all_as_string( keys( %{ $self->{MAP_BY_ID} } ) );
    return $self;
}

sub _is_valid_id () {
	my $new_name = $_[0];
	return ($new_name =~ /APO:[A-Z]\d{7}/)?1:0;
}

=head2 get_new_id

  Usage    - $map->get_new_id("APO", "P", "cell cycle") or $map->get_new_id("APO", "Pa", "cell cycle")
  Returns  - a new APO ID (string)
  Args     - idspace (string), subnamespace (string), term (string)
  Function - get a new APO ID and insert it (put) into this map
  
=cut

sub get_new_id () {
	my ( $self, $idspace, $subnamespace, $term ) = @_;
	my $result;
	if ( $idspace && $subnamespace && $term ) {
		if ( $self->is_empty() ) {
			$result = $idspace.':'.$subnamespace.'0000001';
		} else {
			$result = $self->{KEYS}->get_new_id($idspace, $subnamespace);
		}
		$self->put( $result, $term );    # put
	}
	return $result;
}

1;