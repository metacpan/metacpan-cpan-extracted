# Copyright (c) 2003 Cunningham & Cunningham, Inc.
# Read license.txt in this directory.
#
# Perl translation by Martin Busik <martin.busik@busik.de>
#

package Test::C2FIT::eg::Page;

use base 'Test::C2FIT::RowFixture';
use Test::C2FIT::Parse;
use LWP::UserAgent;
use HTTP::Response;

use URI;

$Test::C2FIT::eg::Page::text = undef;
$Test::C2FIT::eg::Page::URL  = undef;

use strict;

#---------------- access to static variables --------------

sub getText { $Test::C2FIT::eg::Page::text; }
sub setText { $Test::C2FIT::eg::Page::text = $_[0]; }
sub getURL  { $Test::C2FIT::eg::Page::URL; }
sub setURL  { $Test::C2FIT::eg::Page::URL = $_[0]; }

#-----------------------------------------------------------

sub myWget {
    my $url    = shift;
    my $ua     = LWP::UserAgent->new;
    my $resp   = $ua->get($url);
    my $result = undef;
    if ( $resp->is_success ) {
        $result = $resp->content;
    }
    else {
        die "Error " . $resp->code . " while retrieving $url ";
    }
    return $result;
}

sub location {
    my $self = shift;
    my $url  = URI->new(shift);
    setText( myWget($url) );
    setURL($url);
}

sub title {
    my $self = shift;
    return Test::C2FIT::Parse->new( getText, ["title"] )->text();
}

sub link {
    my $self  = shift;
    my $label = quotemeta(shift);
    my $links = new Test::C2FIT::Parse( getText, ["a"] );
    while ( defined($links) && $links->text() !~ /^$label/ ) {
        $links = $links->more();
    }
    my @tokens = grep { /\S/ } split /(?:[<> ="])/, $links->{tag};
    shift(@tokens) while ( @tokens && $tokens[0] !~ /href/i );

    my $url = URI->new_abs( $tokens[1], getURL );

    ## warn "LOADING(LINK): ",$url, "\n";
    setText( myWget($url) );
    setURL($url);
}

# -------- RowFixture part -----------------------------

sub Test::C2FIT::eg::Page::Row::numerator()   { $_[0]->{numerator} }
sub Test::C2FIT::eg::Page::Row::denominator() { $_[0]->{denominator} }
sub Test::C2FIT::eg::Page::Row::quotient()    { $_[0]->{quotient} }

sub query {
    my $self = shift;
    my $rows =
      Test::C2FIT::Parse->new( getText, [ "wiki", "table", "tr", "td" ] )
      ->at( 0, 0, 2 );
    my $result = [];

    while ( defined($rows) ) {
        push(
            @$result,
            bless {
                numerator   => $rows->parts()->at(0)->text(),
                denominator => $rows->parts()->at(1)->text(),
                quotient    => $rows->parts()->at(2)->text(),
            },
            'Test::C2FIT::eg::Page::Row'
        );
        $rows = $rows->more;
    }
    return $result;
}

1;
