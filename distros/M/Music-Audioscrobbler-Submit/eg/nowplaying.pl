#!/usr/bin/perl -w
use strict;

use Music::Audioscrobbler::Submit;

my $options = {
    verbose => 4,
    logfile => "STDERR",
    musictag => 1,
};

print "Please enter your last.fm username:";
my $user = <STDIN>;
chomp $user;
print "Please enter your last.fm password:";
my $pass = <STDIN>;
chomp $pass;

$options->{lastfm_username} = $user;
$options->{lastfm_password} = $pass;

my $mas = Music::Audioscrobbler::Submit->new($options);

foreach my $file (@ARGV) {
    if (-e $file) {
        print STDERR "Submitting $file to now playing\n";
        $mas->now_playing($file);
    }
}
