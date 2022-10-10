package Pg::SQL::PrettyPrinter::Node::SQLValueFunction;

# UTF8 boilerplace, per http://stackoverflow.com/questions/6162484/why-does-modern-perl-avoid-utf-8-by-default/
use v5.26;
use strict;
use warnings;
use warnings qw( FATAL utf8 );
use utf8;
use open qw( :std :utf8 );
use Unicode::Normalize qw( NFC );
use Unicode::Collate;
use Encode qw( decode );

if ( grep /\P{ASCII}/ => @ARGV ) {
    @ARGV = map { decode( 'UTF-8', $_ ) } @ARGV;
}

# If there is __DATA__,then uncomment next line:
# binmode( DATA, ':encoding(UTF-8)' );
# UTF8 boilerplace, per http://stackoverflow.com/questions/6162484/why-does-modern-perl-avoid-utf-8-by-default/

# Useful common code
use autodie;
use Carp qw( carp croak confess cluck );
use English qw( -no_match_vars );
use Data::Dumper qw( Dumper );

# give a full stack dump on any untrapped exceptions
local $SIG{ __DIE__ } = sub {
    confess "Uncaught exception: @_" unless $^S;
};

# now promote run-time warnings into stackdumped exceptions
#   *unless* we're in an try block, in which
#   case just generate a clucking stackdump instead
local $SIG{ __WARN__ } = sub {
    if   ( $^S ) { cluck "Trapped warning: @_" }
    else         { confess "Deadly warning: @_" }
};

# Useful common code

use parent qw( Pg::SQL::PrettyPrinter::Node );

sub as_text {
    my $self = shift;

    my %mapping = (
        "SVFOP_CURRENT_CATALOG"     => "current_catalog",
        "SVFOP_CURRENT_ROLE"        => "current_role",
        "SVFOP_CURRENT_SCHEMA"      => "current_schema",
        "SVFOP_CURRENT_USER"        => "current_user",
        "SVFOP_SESSION_USER"        => "session_user",
        "SVFOP_USER"                => "user",
        "SVFOP_CURRENT_DATE"        => "current_date",
        "SVFOP_CURRENT_TIME"        => "current_time",
        "SVFOP_CURRENT_TIMESTAMP"   => "current_timestamp",
        "SVFOP_LOCALTIME"           => "localtime",
        "SVFOP_LOCALTIMESTAMP"      => "localtimestamp",
        "SVFOP_CURRENT_TIME_N"      => "current_time( TYPMOD )",
        "SVFOP_CURRENT_TIMESTAMP_N" => "current_timestamp( TYPMOD )",
        "SVFOP_LOCALTIME_N"         => "localtime( TYPMOD )",
        "SVFOP_LOCALTIMESTAMP_N"    => "localtimestamp( TYPMOD )",
    );

    my $mapped = $mapping{ $self->{ 'op' } };
    $mapped =~ s{TYPMOD}{ $self->{'typmod'} // 0 }e;
    return $mapped if defined $mapped;
    croak( 'Unknown SQLValueFunction: ' . Dumper( $self ) );
}

1;
