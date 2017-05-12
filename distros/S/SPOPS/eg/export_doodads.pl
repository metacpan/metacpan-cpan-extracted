#!/usr/bin/perl

# $Id: export_doodads.pl,v 3.2 2004/01/10 02:49:58 lachoy Exp $

# To use this, first edit My/Common.pm with your database information
# and then run (mysql example)

# $ mysql test < users_groups_mysql.sql
# $ perl stock_user_group.pl
# $ perl stock_doodad.pl
# $ perl export_doodads.pl

# As XML:
# $ perl export_doodads.pl xml

use strict;
use Log::Log4perl;
Log::Log4perl::init( 'log4perl.conf' );

use SPOPS::Export;

require My::Security;
require My::User;
require My::Doodad;

{
    my $type = shift @ARGV || 'object';
    my $exporter = SPOPS::Export->new( $type );
    $exporter->object_class( 'My::Doodad' );
    print $exporter->run;
}


