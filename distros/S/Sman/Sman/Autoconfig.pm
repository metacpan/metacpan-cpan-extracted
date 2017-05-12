package Sman::Autoconfig;
use Sman::Man::Convert;
use Storable;


#$Id$

use strict;
use warnings;

# this package finds which man command works best on this system 
# Chooses 'best' man command for Sman.
# Our logic is that either 'man %F' or 'man %S %C' will work
# given a list of manfiles, we deterministically pick
# representatives, and see which man command works best 
# on each, XML-wise.
    # this works for most linuxes we've tested
    #MANCMD man -c %F 
    # this works for freebsd 4.4 and Mac OS X up to 10.3
    #MANCMD man -c %S %C

    # these are the man commands we try
#my @tries = ( 'man -c %F', 'man -c %S %C', 'cat %F | gunzip -f --stdout | man -c' );   
    # the last option above does not work, so it's been removed. (it needs tmp file in the middle.)
    # we once left it in anyway, it won't get used if doesn't work, but it causes warnings under cron
my @tries = ( 
                'man %F',              # debian 4.0 needs this, the simplest one, which none supported for years.
                'man -c %F', 
                'man -c %S %C',
            );
    # man -c means to reparse manpage input (and not use the manpage cache)
    # gunzip -f means just cat it if it's not compressed
    # gunzip --stdout means put the output to stdout (I think this is the default)


sub GetBestManCommand {
    my ($smanconfig, $manfilesref) = @_;
    
    my %converters = ();
    for my $cmd (@tries) {
        my $newconfig = Storable::dclone($smanconfig);
        $newconfig->SetConfigData("MANCMD", $cmd);
        $newconfig->SetConfigData("AUTOCONFIGURING", 1);    # internal flag
        $converters{ $cmd } = new Sman::Man::Convert($newconfig, { nocache=>1 } );
    }
    my $numfiles = 10;  # number of files to test
    my @testfiles = (); # the files we'll be testing
    if (scalar(@$manfilesref) < $numfiles) { $numfiles = scalar(@$manfilesref); }
    for (my $i=0; $i < $numfiles; $i++) {
        push(@testfiles, $manfilesref->[ int(  $i / $numfiles * scalar(@$manfilesref) ) ] );
    }

    my %cmdwins = ();   # hash of cmd -> sum of lengths of output for this command
    for my $file (@testfiles) {
        warn "Testing $file" if $smanconfig->GetConfigData("VERBOSE");
        my ($maxlen, $winningcmd) = (0, "");
        for my $mancmd (keys(%converters)) {    # go through the converters
            my ($parser, $contentref) = $converters{$mancmd}->ConvertManfile($file);
            printf( "$0: Got %d bytes from %s\n", length($$contentref), $mancmd ) if $smanconfig->GetConfigData( "DEBUG" );
            if (length($$contentref) > $maxlen) {   # record the largest output and its cmd
                $maxlen = length($$contentref);
                $winningcmd = $mancmd;
            }
        }
        $cmdwins{$winningcmd}++;    # whichever cmd had largest output gets a point
    }
    my @wins = sort { $cmdwins{$b} <=> $cmdwins{$a} } keys(%cmdwins);
    if (scalar(@wins)) { return $wins[0]; }
    return 'man %S %C';  # or 'man %F'
} 

1;
__END__ 

=head1 NAME

Sman::Autoconfig - Automatically choose the 'best' man command

=head1 SYNOPSIS 

    ...
    my $mancmd = Sman::Autoconfig::GetBestManCommand(
        $smanconfig, \@manfiles);
    ...
    
=head1 DESCRIPTION

Chooses a representative sample of the manfiles passed and tests
which usual man command seems to work best on this system's man
files.

=head1 AUTHOR

Josh Rabinowitz <joshr>

=head1 SEE ALSO

L<Sman::Man::Convert>, L<Sman::Config>, L<sman.conf>

=cut
