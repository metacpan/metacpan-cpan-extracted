package Net::Amazon::MechanicalTurk::Command::GetHITTypeURL;
use strict;
use warnings;
use Net::Amazon::MechanicalTurk::Constants ':ALL';

our $VERSION = '1.00';

=head1 NAME

Net::Amazon::MechanicalTurk::Command::GetHITTypeURL - Returns a URL for viewing a HITType.

Returns a URL for viewing a HITType on the MechanicalTurk worker website.

=head1 SYNOPSIS

    my $url = $mturk->getHITTypeURL($hitTypeId);
    printf "To view your created hits, go to: %s\n", $url;

=cut 

sub getHITTypeURL {
    my ($mturk, $hitTypeId) = @_;
    my $workerUrl = $mturk->workerUrl;
    $workerUrl = $SANDBOX_WORKER_URL unless $workerUrl;
    return sprintf "%s/mturk/preview?groupId=%s", $workerUrl, $hitTypeId;
}

return 1;
