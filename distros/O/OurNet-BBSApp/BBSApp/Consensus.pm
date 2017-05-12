package OurNet::BBSApp::Consensus;
use base qw/OurNet::BBSApp::Board/;
use fields qw/proposal status cr_time draft draft_cnt votes poll sched/;
use strict;
use OurNet::BBSApp::CmdPerm;
use OurNet::BBSApp::Arena;
use OurNet::BBSApp::Proposal;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my $len = length($self->{prefix});
    $self->{name} = sprintf("C_%s%0*d", $self->{prefix}, 10-$len, $self->{proposal}{propno});
    print "[consensus]: new consensus $self->{name}\n";
    $self->{board} = $self->{BBS}{boards}{$self->{name}}{articles};

    $self->{draft} = ();
    $self->{draft_cnt} = 0;
    OurNet::BBSApp::Monitor::add($self);
    return $self;
}

sub cmd_draft {
    my ($self, $cmd, $param, $article, $author, $first_time) = @_;
    return 'too late' if $self->{stauts} ne 'new';
    $self->{draft}[$self->{draft_cnt}++] = $article;
    return 'QUIT';
}

sub cmd_vote {
    my ($self, $cmd, $param, $article, $author) = @_;
    my ($vote, $draft) = $param =~ m|([+-])?(\d+)|;
    my $origvote = $self->{votes}{$author}[$draft];
    ++$self->{poll}{vote}[$draft] if $vote eq '+';
    ++$self->{poll}{veto}[$draft] if $vote eq '-';
    --$self->{poll}{vote}[$draft] if $origvote eq '+';
    --$self->{poll}{veto}[$draft] if $origvote eq '-';
    $self->{votes}{$author}[$draft] = $vote;
    return 'OK';
}

sub article {
    my ($self, $article) = @_;
    my $author = $article->{author};
    my $first_time;
    # add `.' to author so nobody could change or delete the article.
    unless ($author eq 'sysbot' || $author =~ m/\.$/) {
	$article->{author} .= '.';
	$first_time = 1;
    }
    $author =~ s/\.$//;

    foreach (grep {m,^\#,} (split("\n", $article->{body}), $article->{title})) {
        my ($cmd, $param) = m|(\w+)(?:\: ([\x00-\xff]+))?|;
	next unless $cmd;
	my $ret = OurNet::BBSApp::CmdPerm::check($self, $self->{proposal}, $article, $cmd, $param);
	next if $ret xor defined($ret);
	my $method = "cmd_$cmd";
	if ($self->can($method)) {
	    my $ret = $self->$method($cmd, $param, $article, $author, $first_time);
	    return if $ret eq 'QUIT';
	}
        else {
	    # check the pseudo-hash rather than `exists $self->{$cmd}'
            $self->{$cmd} = $param if exists $self->[0]{$cmd};
        }
    }
}

sub _finish_veto {
    my $self = shift;
    my ($num, $den) = $self->{proposal}{arena}{veto_min} =~ m|(\d+)/(\d+)|;
    my $poll = $self->{poll};
    # curse!
    my $nmod = (scalar $@{[split(',', $self->{proposal}{arena}{moderator})]});
    my (@granted, @task);

    for (0..$self->{draft_cnt}-1) {
	if ($poll->{veto}[$_] * $den > $nmod * $num and
	    $self->{draft}[$_]{body} =~ m/^\# (?:[Tt]ask|任務|附帶任務): ([^\n]+)/) {
	    push @granted, $_;
	    $task[$_] = $1;
	}
    }
    foreach (@granted) {
        my $len = length($self->{prefix});
	# XXX: draft no. gt 9 ?
        my $cname = sprintf("C_%s%0*d-%d", $self->{prefix}, 10-$len-2, $self->{proposal}{propno}, $_);

        $self->{BBS}{boards}{$cname} = {
            id => $cname,
            bm => 'sysbot',
            title => "任務   $task[$_]",
        };

        ++$self->{proposal}{arena}{group}{$cname};
    }
    delete $self->{sched};
}

sub post_process {
    my $self = shift;
    $self->summarize();
    unless ($self->{sched}) {
    if ($self->{status} eq 'pending') {
        $self->{sched} = {
        'time' => $self->{cr_time} + $self->{proposal}{arena}{veto_time} * 3600,
        'desc' => "finalization of issue $self->{name}",
        'func' => sub {
            $self->_finish_veto;
        }
    };
    }
}
}

sub summarize {
}

1;
