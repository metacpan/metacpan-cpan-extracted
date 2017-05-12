# $File: //depot/libOurNet/BBS/lib/OurNet/BBS/BBSAgent/BBS.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 3792 $ $DateTime: 2003/01/24 19:34:06 $

package OurNet::BBS::BBSAgent::BBS;

use strict;
no warnings 'deprecated';
use base qw/OurNet::BBS/;
use fields qw/backend bbsroot login password timeout logfile bbsobj _ego _hash/;
use OurNet::BBS::Base (
    '@BOARDS' => [qw/bbsroot bbsobj/],
);

use OurNet::BBSAgent;

sub refresh_boards {
    my ($self, $key) = @_;

    $self->load_bbsobj;

    no strict 'refs';
    return $self->fillin(
        $key, 'BoardGroup', map { $self->{$_} } @BOARDS
    );
}

sub load_bbsobj {
    my ($self, $bbsname, $nologin) = @_;
    $self = $self->ego;

    return $self->{bbsobj} if $self->{bbsobj};

    $bbsname ||= $self->{bbsroot};
    $bbsname .= ".bbs" unless substr($bbsname, -4) eq '.bbs';

    my $bbsobj = OurNet::BBSAgent->new(
	OurNet::BBS::Utils::locate($bbsname, 'OurNet::BBSAgent'),
        $self->{timeout} ||= 60,
        $self->{logfile},
    );

    return $bbsobj if $nologin;

    $self->{bbsobj} = $bbsobj;
    $self->{bbsobj}{debug} = $OurNet::BBS::DEBUG;

    $self->{login} ||= 'guest';
    $self->{password} = $1 if $self->{login} =~ s/[,:](.*)$//;

    eval {
	$self->{bbsobj}->login(
	    grep {defined $_} ($self->{login}, $self->{password})
	);
    };

    $self->{bbsobj}{var}{username} ||= $self->{login};
    return $@ ? undef : $self->{bbsobj};
}

# Run sanity test. 
# if $nologin, no actual login will be attempted.
sub sanity_test {
    my ($self, $nologin) = @_;

    my $ego  = $self->ego;
    my $vars = ($ego->load_bbsobj('', $nologin) || return)->{var};
    my $brd  = $vars->{sanity_board} or return 1;

    my %var = map {
        (substr($_, length("sanity_board_")), $vars->{$_})
    } grep {
        m/^sanity_board_/
    } keys(%{$vars}); # gets sanity_board_* variables

    my $rec = delete($var{rec}) || 1;

    print "Sanity testing: board $brd, rec $rec\n" if $OurNet::BBS::DEBUG;
    my $art = $self->{$brd}{articles}[$rec] or return;

    while (my ($k, $v) = each %var) {
	print "Asserting $k = $v\n" if $OurNet::BBS::DEBUG;
        next unless exists $art->{$k};
        return unless index($art->{$k}, $v) > -1; 
    }

    print "Sanity test passed.\n" if $OurNet::BBS::DEBUG;
    
    return 1;
}

1;
