package RT::Condition::CIFMinimal_Stale;

use strict;
use warnings;

use base 'RT::Condition::Generic';

use DateTime;
use DateTime::Format::DateParse;
use Regexp::Common qw/net/;
use Regexp::Common::net::CIDR;

my $map = RT->Config->Get('CIFMinimal_StaleMap');

sub IsApplicable {
    my $self = shift;
    my $tkt = $self->TicketObj();
    my $arg = $self->Argument() || return;

    my $regex = qr/^$RE{'net'}{'IPv4'}$/;
    for($arg){
        if($arg eq 'ipv4-net'){
            $regex = qr/^$RE{'net'}{'CIDR'}{'IPv4'}$/;
            last;
        }
        if($arg eq 'domain'){
            $regex = qr/^[a-zA-Z0-9-.]+\.[a-z]{2,5}$/;
            last;
        }
        if($arg eq 'url'){
            $regex = qr/^https?\:\/\/[a-zA-Z0-9-.]+\.[a-z]{2,5}/;
            last;
        }
    }

    $arg = $map->{$arg} || return;
    my $addr = $tkt->FirstCustomFieldValue('Address') || $tkt->FirstCustomFieldAddress('Hash');
    my $impact = $tkt->FirstCustomFieldValue('Assessment Impact');
    return(1) unless($addr);
    return(0) unless(($addr && $addr =~ $regex) || lc($impact) =~ /whitelist/);
    if(lc($impact) =~ /whitelist/){
        $arg = $map->{'whitelist'};
    }

    $arg = (time() - ($arg * 86400));

    my $lastupdated = $self->TicketObj->LastUpdatedObj->AsString();
    $lastupdated = DateTime::Format::DateParse->parse_datetime($lastupdated);
   
    return(0) unless($lastupdated->epoch() < $arg);
    $RT::Logger->debug('Ticket: '.$tkt->Id());
    return(1);
}

1;
