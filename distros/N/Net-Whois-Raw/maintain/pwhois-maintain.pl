#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use LWP::Simple;
use Template;
use File::Slurp;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Net::Whois::Raw;

use constant {
    GTLD_URL        => 'http://data.iana.org/TLD/tlds-alpha-by-domain.txt',
    NOTFOUND_DOMAIN => '3b43763b-09b87hidaf',
};

sub usage() {
    die "usage:
    $0 --check-for-new-gtlds [--cache-dir /path/to/whois-cachedir] [--max-new num]
        --check-for-new-gtlds - try to find whois servers for gTLDs which are not in Data.pm yet
        --cache-dir - cache dir for whois responses, cache lifetime is 24 hrs
        --max-new - stop when specified number of new gTLDs found
        
        Workflow:
            1. $0 --check-for-new-gtlds --cache-dir /tmp
            2. chromium new-gtlds.html
            3. Check Not Found pattern for each TLD (edit if wrong), accept or skip TLD
            4. Press `Process` button. Accepted TLDs will be added to output,
               skipped will not.
            5. Copy and paste output from textarea to Data.pm
            6. Save and commit Data.pm\n";
}

GetOptions(
    'check-for-new-gtlds' => \my $check_for_new_gtlds,
    'cache-dir=s'         => \my $cache_dir,
    'max-new=i'           => \my $max_new,
) || usage;

$Net::Whois::Raw::TIMEOUT = 10;
if ($cache_dir) {
    $Net::Whois::Raw::CACHE_DIR = $cache_dir;
    $Net::Whois::Raw::CACHE_TIME = 24*60; # one day
}

if ($check_for_new_gtlds) {
    my @new;
    
    # get TLD list
    my $raw_list = get(GTLD_URL) or die "Can't get TLD list";
    
    for my $tld (split /\n/, $raw_list) {
        # skip empty lines and comments
        next if $tld =~ /^\s*#/;
        $tld =~ s/\s//g;
        next if !$tld;
        
        # check if we already have such TLD
        $tld = uc $tld;
        next if exists $Net::Whois::Raw::Data::servers{$tld};
        
        # get whois server for TLD using whois.iana.org
        print "new TLD found: $tld\n";
        print "\tdetermining whois server\n";
        my $tld_info = eval { whois($tld, 'whois.iana.org', 'QRY_FIRST') }
            or warn "can't receive whois response for `$tld'\n" and next;
        my ($whois_server) = $tld_info =~ /^\s*whois:\s*(\S+)/im
            or warn "can't find whois server for `$tld'" and next;
        
        my $notfound = 0;
        my $notfound_pat;
        unless ( exists $Net::Whois::Raw::Data::notfound{$whois_server} ) {
            # receive "not found" response, so we can make "not found" pattern
            print "\tdetermining `not found` response\n";
            $notfound = eval { whois(NOTFOUND_DOMAIN.".$tld", $whois_server, 'QRY_LAST') }
                or warn "can't receive `not found` response for `$tld`\n";
                
            if ($notfound) {
                $notfound =~ s/^\s+//;
                # try to suggest not found pattern
                ($notfound_pat) = $notfound =~ /([^\n]+)/;
                $notfound_pat =~ s/\s+$//;
                my $fix_re = NOTFOUND_DOMAIN.'.*';
                $notfound_pat =~ s/$fix_re//i;
                $notfound_pat =~ s/([\[\].+'\(\)?*\{\}])/\\$1/g; # used in regexp
                
                # prevent duplicates
                $Net::Whois::Raw::Data::notfound{$whois_server} = 0;
            }
        }
        
        push @new, {
            tld          => $tld,
            whois_server => $whois_server,
            notfound     => $notfound,
            notfound_pat => $notfound_pat,
        };
        
        if ($max_new && @new == $max_new) {
            print "--max-new limit exceeded\n";
            last;
        }
    }
    
    unless (@new) {
        print "No new GTLD records found. Data.pm is up to date\n";
        exit;
    }
    
    # tlds with not found message at the top
    @new = sort { 
        $a->{whois_server} cmp $b->{whois_server} or
        defined($b->{notfound}) <=> defined($a->{notfound}) or
        ($b->{notfound}&&1||0) <=> ($a->{notfound}&&1||0)
    } @new;
    
    # generate HTML
    my $lib_path = $FindBin::Bin.'/pwhois-maintain';
    my $template = read_file( $lib_path.'/index.html', {binmode => ':utf8'} );
    my $tpl = Template->new;
    $tpl->process(\$template, {
        new      => \@new,
        source   => scalar read_file( $FindBin::Bin.'/../lib/Net/Whois/Raw/Data.pm', {binmode => ':utf8'} ),
    }, \my $html) or die "Can't process template: ", $tpl->error;
    
    write_file( 'new-gtlds.html', {binmode => ':utf8'}, \$html );
    
    print "Done! Now open `new-gtlds.html' in your favorite browser.\n";
}
else {
    usage;
}
