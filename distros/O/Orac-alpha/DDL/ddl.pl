#! /usr/bin/perl -w

# $Id: ddl.pl,v 1.12 2001/03/31 18:27:42 rvsutherland Exp $

use strict;

use DBI;
use DDL::Oracle;
use English;

my  $dbh = DBI->connect(
                        "dbi:Oracle:",
                        "",
                        "",
                        {
                         PrintError => 0,
                         RaiseError => 1
                        }
    );

DDL::Oracle->configure( 
                        dbh      => $dbh,
                        resize   => 1,
#                        view     => 'user',
#                        heading  => 0,
#                        prompt   => 0,
                      );

my $user = getlogin
        || scalar getpwuid($REAL_USER_ID)
        || undef;

print STDERR "Enter Action [CREATE]: ";
chomp( my $action = <STDIN> );
$action = "create" unless $action;

print STDERR "Enter Type    [TABLE]: ";
chomp( my $type = <STDIN> );
$type = "TABLE" unless $type;

print STDERR "Enter Owner [\U$user]: ";
chomp( my $owner = <STDIN> );
$owner = $user unless $owner;
die "\nYou must specify an Owner.\n" unless $owner;

print STDERR "Enter Name           : ";
chomp( my $name = <STDIN> );
die "\nYou must specify an object.\n"
   unless (
                $name
             or "\U$type" eq 'COMPONENTS'
          );

print STDERR "\n";

my $obj = DDL::Oracle->new(
                            type  => $type,
                            list  => [
                                       [
                                         $owner,
                                         $name,
                                       ]
                                     ]
                          );

my $sql;

if ( $action eq "drop" ){
    $sql = $obj->drop;
}
elsif ( $action eq "create" ){
    $sql = $obj->create;
}
elsif ( $action eq "resize" ){
    $sql = $obj->resize;
}
elsif ( $action eq "compile" ){
    $sql = $obj->compile;
}
elsif ( $action eq "show_space" ){
    $sql = $obj->show_space;
}
else{
    die "\n$0 doesn't know how to '$action'.\n";
} ;

print $sql;

=head1 NAME

ddl.pl - Generates DDL for a single, named object

=head1 DESCRIPTION

Calls DDL::Oracle for the DDL of a specified object.

=head1 AUTHOR

 Richard V. Sutherland
 rvsutherland@yahoo.com

=head1 COPYRIGHT

Copyright (c) 2000, 2001 Richard V. Sutherland.  All rights reserved.
This module is free software.  It may be used, redistributed, and/or
modified under the same terms as Perl itself.  See:

    http://www.perl.com/perl/misc/Artistic.html

=cut

