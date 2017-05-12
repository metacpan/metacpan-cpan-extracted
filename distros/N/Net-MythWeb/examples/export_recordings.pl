#!/home/acme/perl-5.10.0/bin/perl
use strict;
use warnings;
use lib 'lib';
use Net::MythWeb;
use Perl6::Say;

my $mythweb = Net::MythWeb->new( hostname => 'owl.local', port => 80 );

foreach my $recording ( $mythweb->recordings ) {
    say $recording->channel->id, ', ', $recording->channel->number, ', ',
        $recording->channel->name;
    say $recording->start, ' -> ', $recording->stop, ': ', $recording->title,
        ', ',
        $recording->subtitle, ', ',
        $recording->description;
    my $title;
    if ( $recording->subtitle ) {
        $title = $recording->title . ' ' . $recording->subtitle;
    } else {
        $title = $recording->title;
    }
    my $filename = $title . ' ' . $recording->start;
    $filename =~ s{[^a-zA-Z0-9]}{_}g;
    $filename = '/media/disk/tv/' . $filename . '.mpg';
    say $filename;
    $recording->download($filename);
    $recording->delete if -f $filename && -s $filename;
}
