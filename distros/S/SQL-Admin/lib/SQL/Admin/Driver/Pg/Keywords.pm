
package SQL::Admin::Driver::Pg::Keywords;
use base qw( Exporter );

use strict;
use warnings;

our $VERSION = v0.5.0;

######################################################################

our @EXPORT_OK = (
    '%RESERVED_KEYWORDS',
    '%NONRESERVED_KEYWORDS',
    '%SQL_KEYWORDS',
);


our %EXPORT_TAGS = ( all => \@EXPORT_OK );

######################################################################

our %RESERVED_KEYWORDS = map +( $_ => 1 ), (
    qw( all analyse analyze and any ),
    qw( array as asc assymetric authorization ),
    qw( between binary both case cast ),
    qw( check collate column constraint create ),
    qw( cross current_date current_role current_time current_timestamp ),
    qw( current_user default deferrable desc distinct ),
    qw( do else end except false ),
    qw( for foreign freeze from full ),
    qw( grant group having ilike in ),
    qw( initially inner intersect into is ),
    qw( isnull join leading left like ),
    qw( limit localtime localtimestamp natural new ),
    qw( not notnull null off offset ),
    qw( old on only or order ),
    qw( outer overlaps placing primary references ),
    qw( right select session_user similar some ),
    qw( symmetric table then to trailing ),
    qw( true union unique user using ),
    qw( verbose when where ),
);

our %NONRESERVED_KEYWORDS = map +( $_ => 1 ), (
    qw( abort absolute access     action add ),
    qw( admin after    aggreggate also   alter ),
    qw( assertion assignment at bacward before ),
    qw( begin bigint bit boolean by ),
    qw( cache called cascade chain char ),
    qw( character characteristics checkpoint class close ),
    qw( cluster coalesce comment commit committed ),
    qw( connection constraints conversion convert copy ),
    qw( createdb createrole createuser csv cursor cycle ),
    qw( database day deallocate dec decimal ),
    qw( declare defaults deferred definer delete ),
    qw( delimiter delimiters disable domain double ),
    qw( drop each enable encoding encrypted ),
    qw( escape excluding exclusive execute exists ),
    qw( explain external extract fetch first ),
    qw( float force forward function global ),
    qw( granted greatest handler header hold ),
    qw( hour immediate immutable implicit including ),
    qw( increment index inherit inherits inout ),
    qw( input insensitive insert instead int ),
    qw( integer interval invoker isolation key ),
    qw( lancompiler language large last least ),
    qw( level listen load local location ),
    qw( lock login match maxvalue minute ),
    qw( minvalue mode month move names ),
    qw( national nchar next no nocreatedb ),
    qw( nocreaterole nocreateuser noinherit nologin none ),
    qw( nosuperuser nothing notify nowait nullif ),
    qw( numeric object of oids operator ),
    qw( option out overlay owner partial ),
    qw( password position precision prepare prepared ),
    qw( preserve prior privileges procedural procedure ),
    qw( quote read real recheck reindex ),
    qw( relative release rename repeatable replace ),
    qw( reset restart restrict returns revoke ),
    qw( role rollback row rows rule ),
    qw( savepoint schema scroll second security ),
    qw( sequence serializable session set setof ),
    qw( share show simple smalling stable ),
    qw( start statement statistics stdin stdout ),
    qw( storage strict substring superuser sysid ),
    qw( system tablespace temp template temporary ),
    qw( time timestamp toast transaction treat ),
    qw( trigger trim truncate trusted type ),
    qw( uncommited unencrypted unknown unlisten until ),
    qw( update vacuum valid validator values ),
    qw( varchar varying view volatile with ),
    qw( without work write year zone ),
);

our %SQL_KEYWORDS = map +( $_ => 1 ), (
);

package SQL::Admin::Driver::Pg::Keywords;

1;

