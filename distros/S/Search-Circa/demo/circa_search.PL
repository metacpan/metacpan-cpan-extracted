#!/usr/bin/perl -w
#
# Simple perl exmple to interface with module Search::Circa::Search
# Copyright 200x A.Barbet alian@alianwebserver.com.  All rights reserved.
# $Date: 2002/12/29 03:18:37 $

use strict;
use Getopt::Long;
use lib '/path/to/circa';
use Search::Circa::Search;
use Pod::Usage;

my $search = new Search::Circa::Search;
my %opts;
my @options = qw/id=i url=s langue=s update=s create=s 
                 request=s debug=i help man nb=i/;
GetOptions(\%opts,@options) or pod2usage( -verbose => 1, -exitval => 1 );
$opts{help}  and pod2usage( -verbose => 1, -exitval => 0 );
$opts{man}   and pod2usage( -verbose => 2, -exitval => 0 );
$opts{nb}    and $search->{nbResultPerPage}=$opts{nb};
$opts{debug} and $search->{DEBUG}=$opts{debug};

# Connection à MySQL
die "Erreur à la connection MySQL:$DBI::errstr\n" if (!$search->connect);

# Masque pour recherche en ligne de commande
$CircaConf::templateS = '"
$indiceG - $url
\t$titre
\tScore: $facteur"';

if ($opts{request} && ($opts{id}))  {
  print "Search::Circa::Search $Search::Circa::Search::VERSION - Account ".
    $opts{id}." - For '$opts{request}'\n";
  my ($resultat,$links,$indice) = 
    $search->search($CircaConf::templateS,$opts{request},0,
		    $opts{id},
		    $opts{langue},
		    $opts{url},
		    $opts{create},
		    $opts{update});
  if (!$resultat and !$links and !$indice) {
    print "Error on search. Did you have one account and url in database ?\n";
  }
  else { print $resultat,"\n" if ($resultat); }
} else { pod2usage( -verbose => 1, -exitval => 1 ); }

=pod

=head1 NAME

circa_search - Perform search on a circa database

=head1 SYNOPSIS

B<circa_search> --id=your_id --request=your_request [OPTIONS]

=head1 DESCRIPTION

circa_search is used to perform search on a circa database. Eg:

  circa_search --id=1 --request="tie filehandle perl"

=head1 OPTIONS

Options supported at this moment:

=over 4

=item B<--help>

Display this help

=item B<--man>

Longer help

=item B<--request=>I<string>

String to search

=item B<--create=>I<string>

Only url added after this date (YYYY/MM/DD)

=item B<--debug=>I<0-5>

Level of debug / verbose

=item B<--id=>I<integer>

Account to used

=item B<--langue=>I<string>

Restrict to langue l

=item B<--update=>I<string>

Only url updated after this date (YYYY/MM/DD)

=item B<--url=>I<string>

Restrict to site with url beginning with u

=item B<--nb=>I<integer>

Number of items to display

=back

=head1 SEE ALSO

L<Search::Circa::Search>

=head1 VERSION

$Revision: 1.6 $

=head1 AUTHOR

Alain BARBET

=cut
