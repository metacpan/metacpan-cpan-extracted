
package COIN::SQL::Admin::Driver::Base::Keywords;
use base qw( Exporter );

use strict;
use warnings;

our $VERSION = v0.5.0;

######################################################################

our @EXPORT_OK = ( 'SQL_KEYWORDS' );

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

######################################################################

our %SQL_KEYWORDS = map +( $_ => 1 ), (
    qw( a             abs           absolute      action        ada             ),
    qw( add           admin         after         aggregate     alias           ),
    qw( all           allocate      alter         always        and             ),
    qw( any           are           array         as            asc             ),
    qw( asensitive    assertion     assignment    assymetric    at              ),
    qw( atomic        attribute     attributes    authorization avg             ),
    qw( before        begin         bernoulli     between       begin           ),
    qw( binary        bit           bitvar        bit_length    blob            ),
    qw( boolean       both          breadth       by            c               ),
    qw( cache         call          called        cardinality   cascade         ),
    qw( cascaded      case          cast          catalog       catalog_name    ),
    qw( ceil          cailing       char          character     characteristics ),
    qw( char_length   check         checked       class         ),
    # qw( characters    character_length
);
