#!/bin/perl

use Modern::Perl;
use strict;
use warnings;
use autodie qw(:all);
no indirect ':fatal';

use Carp;

use TSQL::FlatFile;
use Text::CSV ;
use Readonly ;
use List::MoreUtils qw(any) ;

use File::Basename;
use Smart::Comments;
use Try::Tiny;

use Getopt::Euclid qw( :vars<opt_> );
use List::MoreUtils qw{firstidx} ;
use Data::Dumper;
use Regexp::Exhaustive qw/ exhaustive /;

use version ; our $VERSION = qv('1.0.1');
our $opt_asciifile;
our $opt_csvfile;
our $opt_linenumber;
our $opt_datalinenumber;
our $opt_nodebug;
our $opt_nodatadebug;
our $opt_noincrementalsearch;

use Text::CSV;

my $csvfile             = $opt_csvfile;
my $asciifile           = $opt_asciifile;
my $linenumber          = $opt_linenumber;
my $datalinenumber      = $opt_datalinenumber;
my $debug               = defined($opt_nodebug)             ? !$opt_nodebug             : 0;
my $datadebug           = defined($opt_nodatadebug)         ? !$opt_nodatadebug         : 0;
my $incrementalsearch   = defined($opt_noincrementalsearch) ? !$opt_noincrementalsearch : 0;

my $obj = TSQL::FlatFile->new();

my $csv = Text::CSV->new ({ binary => 1, auto_diag => 1 });
open my $fh, "<:encoding(utf8)", $csvfile or die "csvfile: $!";

if ($datadebug) 
{
    my $res = $obj->getLinePositions
                            ( $asciifile
                            , $csv
                            , $fh
                            , $linenumber
                            , $incrementalsearch
                            ) ;
    say "best_line:",$$res->{best_line};
    say "best_unmatchedcount:",$$res->{best_unmatchedcount};
    say "best_unmatchedamount:",$$res->{best_unmatchedamount};

}
else {
    my $res = $obj->processLine
                            ( $asciifile
                            , $csv
                            , $fh
                            , $linenumber
                            , $incrementalsearch
                            , $debug
                            ) ;
    say $res;
}

close $fh;

exit ;

# #######################################################################################


END {
}

__DATA__


=head1 NAME


gen-Ascii.pl - ???????????????????

=head1 VERSION

1.0.1

=head1 USAGE

gen-Ascii.pl -c <csvfile> 


=head1 REQUIRED ARGUMENTS

=over

=item  -c[sv][file]   [=] <csvfile>

Specify csv file

=for Euclid:
    csvfile.type:    readable


=back


=over

=item  -a[scii][file]   [=] <asciifile>

Specify ascii file

=for Euclid:
    asciifile.type:    readable


=back


=over



=item  -l[ine][number]   [=] <linenumber>

Specify linenumber

=for Euclid:
    linenumber.type:    int


=back



=head1 OPTIONS

=over


=item  -d[ata]l[ine][number]   [=] <datalinenumber>

Specify datalinenumber

=for Euclid:
    datalinenumber.type:     int
    datalinenumber.default:    1


=back



=over

=item  --[no]debug

[Don't] generate detailed debug info

=for Euclid:
    false: --nodebug


=back


=over

=item  --[no]datadebug

[Don't] generate detailed data debug info

=for Euclid:
    false: --nodatadebug


=back



=over

=item  --[no]i[ncremental]s[earch]

[Don't] automatically search up to 100 lines past the start point for a full error free match

=for Euclid:
    false: --noincrementalsearch


=back


=head1 AUTHOR

Ded MedVed.



=head1 BUGS

Hopefully none.



=head1 COPYRIGHT

Copyright (c) 2020, Ded MedVed. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

