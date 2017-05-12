package OurNet::BBSApp::Proposal;

use strict;
use OurNet::BBSApp::Arena;
use OurNet::BBSApp::Issue;
use OurNet::BBSApp::Consensus;
use fields qw/arena article name issue consensus task owner propno/;

sub new {
    my $class = shift;
    my $self = fields::new($class);
    $self->{arena} = shift;
    $self->{article} = shift;
    # pass to issue, etc
    my %var = %{scalar shift};
    $self->{propno} = shift;
    $var{prefix} = $self->{arena}{prefix};
    $var{proposal} = $self;
    if (!$var{issue} || $var{issue} ne 'closed') {
	print "[proposal] issue $self->{propno}\n";
	$self->{issue} = OurNet::BBSApp::Issue->new($self->{arena}{BBS}, \%var);
    }
    if ($var{consensus} eq 'open') {
	print "[proposal] consensus $self->{propno}\n";
	$self->{consensus} = OurNet::BBSApp::Consensus->new($self->{arena}{BBS}, \%var);
    }
    return $self;
}

sub involved {
    my $self = shift;
    return $self->{issue}{involved} if $self->{issue};
    return $self->{arena}{moderator} if $self->{consensus};
}

1;
