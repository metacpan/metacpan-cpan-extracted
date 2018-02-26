#/usr/bin/env perl
use Modern::Perl;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Steemit::WsClient;

my $steem = Steemit::WsClient->new;
say "Initialized Steemit client with url ".$steem->url;

#get the last 99 discussions with the tag utopian-io
#truncate the body since we dont care here
my $discussions = $steem->get_discussions_by_created({
      tag => 'utopian-io',
      limit => 99,
      truncate_body => 100,
});

#extract the author names out of the result
my @author_names = map { $_->{author} } @$discussions;
say "last 99 authors: ".join(", ", @author_names);

#load the author details
my $authors = $steem->get_accounts( [@author_names] );
#say Dumper $authors->[0];

#calculate the reputation average
my $reputation_sum = 0;
for my $author ( @$authors ){
   $reputation_sum += int( $author->{reputation} / 1000_000_000 );
}

say "Average reputation of the last 99 utopian authors: ". ( int( $reputation_sum / scalar(@$authors) )  / 100 );


