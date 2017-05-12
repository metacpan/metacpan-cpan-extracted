#!/bin/perl

use Modern::Perl;

use autodie qw(:all);
no indirect ':fatal';

use Data::Dump 'pp';
use Getopt::Euclid qw( :vars<opt_> );

use TSQL::SplitStatement;

use version ; our $VERSION = qv('1.0.0');

my @re      = @opt_regexp ;
my @exre    = @opt_ex_regexp ;

my $s = do { local $/ = undef; <> ;} ;

my $parser = TSQL::SplitStatement->new();
my @parsedInput = $parser->splitSQL($s);

STATEMENT: foreach my $statement (@parsedInput) {
    foreach my $re (@re) {
        my $qr_re = qr{$re}  ;
        if ( $statement =~ m/$qr_re/imsg ) {
            foreach my $exre (@exre) {
                my $qr_exre = qr{$exre}  ;
                if ( $statement =~ m/$qr_exre/imsg ) {
                    next STATEMENT;
                }
            }
            say $statement;
            next STATEMENT;
        }
    }
}



__DATA__



=head1 NAME


grepTSQL.pl - Greps for TSQL statements in a SQL Script.  The search is performed case-insensitively across multiple lines
Uses TSQL::SplitStatement to determine what is and is not a statement.
In brief, anything that can contain another simpler statement is *NOT* a statement.
E.G. CREATE PROCEDURE is not by itself, a complete statement, as it contains other TSQL statements.

=head1 VERSION

1.0.0

=head1 USAGE

grepTSQL.pl -r <regexp> 


=head1 REQUIRED ARGUMENTS

=over

=item  -r[e][gexp]   [=] <regexp> 

Specify regular expressions to match (Or-ed together)

=for Euclid:
    regexp.type:    string
    repeatable

=back

=head1 OPTIONS

=over

=item  -ex_r[e][gexp]   [=] <ex_regexp> 

Specify regular expressions to exclude (Or-ed together), these are applied after the match expressions

=for Euclid:
    ex_regexp.type:    string
    repeatable

=back



=head1 AUTHOR

Ded MedVed.



=head1 BUGS

Hopefully none.



=head1 COPYRIGHT

Copyright (c) 2013, Ded MedVed. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

