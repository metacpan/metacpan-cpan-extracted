#!/usr/bin/env perl

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
use Carp         qw( carp croak confess cluck );
use English      qw( -no_match_vars );
use Data::Dumper qw( Dumper );

# give a full stack dump on any untrapped exceptions
local $SIG{ __DIE__ } = sub {
    confess "Uncaught exception: @_" unless $^S;
};

# Useful common code

use FindBin;
use lib "$FindBin::Bin/../lib";
use Getopt::Long qw(GetOptions);
use Pg::SQL::PrettyPrinter;

my $cfg = {};

GetOptions( $cfg, 'help|?', 'single', 'pretty', 'quiet' ) or show_help_and_die( 'Error in command line arguments' );
show_help_and_die() if $cfg->{ 'help' };

delete $cfg->{ 'single' } if $cfg->{ 'pretty' };

my $sql = join( '', <> );
my $pp  = Pg::SQL::PrettyPrinter->new(
    sql     => $sql,
    service => $ENV{ 'PARSER_SERVICE' } // 'http://127.0.0.1:15283/'
);
$pp->parse();
for my $i ( 0 .. $#{ $pp->{ 'statements' } } ) {
    printf( "-- Statement #%d\n", $i + 1 ) unless $cfg->{ 'quiet' };
    if ( $cfg->{ 'single' } ) {
        print $pp->{ 'statements' }->[ $i ]->as_text() . "\n";
    }
    else {
        print $pp->{ 'statements' }->[ $i ]->pretty_print() . "\n";
    }
}

exit;

sub show_help_and_die {
    my $error = shift;
    my $fh    = $error ? *STDERR : *STDOUT;
    if ( $error ) {
        printf $fh "%s\n\n", $error;
    }
    print $fh <<_END_OF_HELP_;
Syntax:
    $PROGRAM_NAME [-s] < query.sql
    $PROGRAM_NAME [-s] query.sql

Options:
    --single (-s) - single line output
    --pretty (-p) - pretty output (default)
    --quiet  (-q) - don't output statement # comment lines
    --help   (-h) - this help page

Environment:
    PARSER_SERVICE - url of pg-query-parser-microservice. Defaults to http://127.0.0.1:15283/

Sources:
    https://gitlab.com/depesz/pg-sql-prettyprinter
    https://gitlab.com/depesz/pg-query-parser-microservice
_END_OF_HELP_
    exit 1 if $error;
    exit 0;
}

# vim: set ft=perl:
