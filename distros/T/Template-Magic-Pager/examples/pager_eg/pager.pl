#!/usr/bin/perl
#use strict;
use Template::Magic::HTML;
use Template::Magic::Pager;

my $page_number = 1;

# specify page to test
if (@ARGV) { $page_number = $ARGV[0]; }
my $total_results = 100;
my $rows_per_page = 8;
my $offset = $rows_per_page * ($page_number - 1);

our $pager = Template::Magic::Pager->new
	( total_results   => $total_results
	  , page_number     => $page_number
	  , rows_per_page   => $rows_per_page
	  , pages_per_index => 5
	  , page_rows       => \&page_rows
	  ) ;

Template::Magic::HTML->new->print( 'results.html' );

sub link_url {
    # URL to use for all page links, eg: $s->cgi->url(-relative=>1) . "?p=" . $s->page_name
    "url?p=page";
}

sub page_rows {
    my @results;
    foreach my $i ($offset + 1..$offset + $rows_per_page) {
	push @results, { user => "user$i", fullname => "User #$i" };
    }
    return \@results;
}
