package OurNet::BBSApp::Issue;
use base qw/OurNet::BBSApp::Board/;
use fields qw/proposal issue owner status depend involved
              descr sched cr_time wg_time pp_time vt_time draft draft_cnt
              predraft_cnt votes poll/;
use strict;

use OurNet::BBSApp::Arena;
use OurNet::BBSApp::Consensus;
use OurNet::BBSApp::Schedule;
use Text::Wrap;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    my $len = length($self->{prefix});
    $self->{name} = sprintf("I_%s%0*d", $self->{prefix}, 10-$len, $self->{proposal}{propno});
    print "[issue]: new issue called $self->{name}\n";
    $self->_create unless $self->{issue};
    $self->{board} = $self->{BBS}{boards}{$self->{name}}{articles};
    $self->{draft} = ();
    $self->{draft_cnt} = 0;
    $self->{predraft_cnt} = 0;
    OurNet::BBSApp::Monitor::add($self);
    return $self;
}

sub _create {
    my $self = shift;

    $self->{BBS}{boards}{$self->{name}} = {
    id => $self->{name},
    bm => 'sysbot',
    title => "議題   $self->{descr}"
    };
    ++$self->{proposal}{arena}{group}{$self->{name}};
    print "[issue] new board $self->{name} created!\n";
    $self->{board} = $self->{BBS}{boards}{$self->{name}}{articles};
    $self->{cr_time} = time();
    push @{$self->{board}}, {
        author => 'sysbot',
        title  => "new issue: $self->{descr}",
        body   => << "___",
# status: $self->{status}
# descr: $self->{descr}
# involved: $self->{owner}
# owner: $self->{owner}
# cr_time: $self->{cr_time}
# wg_time: $self->{wg_time}
# pp_time: $self->{pp_time}
# vt_time: $self->{vt_time}
___
    };
    $self->{issue} = 'open';
    $self->{proposal}{article}{body} .= "--\n# issue: open\n";
    $self->{BBS}{boards}->shm->{touchtime} = time()
	if $self->{BBS}{boards}->shm;
}

sub _delete {
    my ($self, $issue, $reason) = @_;
    $self->{proposal}{article}{body} .= "--\n# issue: $issue\n$reason\n";
    delete $self->{proposal}{arena}{group}{$self->{name}};
    delete $self->{BBS}{boards}{$self->{name}};
    OurNet::BBSApp::Monitor::del($self);
}

sub involved {
    my ($self, $who) = @_;
    return 1 if index(",$self->{involved},", ",$who,") > -1;
    return undef;
}

sub cmd_involved {
    my ($self, $cmd, $param, $article, $author) = @_;
    return 'too late' if $self->{status} eq 'polling'; # too late, dude
    return 'permission denied'
	unless $author eq 'sysbot' or $self->involved($author);
    return 'already involved' if $self->involved($param);
    return 'useless' if index($param, ',') > -1;
    $self->{involved} = join(',',(split(',',$self->{involved}), $param));
    return 'OK';
}

sub cmd_draft {
    my ($self, $cmd, $param, $article, $author, $first_time) = @_;
    return 'too late' if $self->{status} eq 'polling';
    if ($author ne 'sysbot') {
	unless (int($param) or $param eq '0') {
	    my $draftrefno = $article->recno+1;
	    push @{$self->{board}}, {
        author => 'sysbot',
        title  => "new draft accepted: #$self->{predraft_cnt}",
        body   => << "___",
# draft: $draftrefno
draft #$self->{predraft_cnt} is at article #$draftrefno
___
	    } if $first_time;
	    ++$self->{predraft_cnt};
	}
	elsif ($param < $self->{draft_cnt}) {
	    return 'permission denied'
        if $self->{draft}[$param]{author} ne $author.'.';
	    $self->{draft}[$param] = $article;
	    push @{$self->{board}}, {
        author => 'sysbot',
        title  => "draft revision accepted: #$param now at ".
        ($article->recno+1),
        body => "\n",
	    } if $first_time;
	}
    }
    if ($author eq 'sysbot') {
	$self->{draft}[$self->{draft_cnt}++] = $self->{board}[$param];
    }
    # we do not allow other commands after # draft
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
    # remember who's involved in status eq 'new'
    $self->{involved} = join(',',(split(',',$self->{involved}), $author))
        if $self->{status} eq 'new' and $author ne 'sysbot'
           and !($self->{involved} =~ m/\b$author\b/);
    my @involved = split(',',$self->{involved});
    # ignore article from non-workgroup users.
    return unless $self->{status} eq 'new' || $author eq 'sysbot' ||
    grep {$_ eq $author} @involved;
    print "new article at ".$self->{name}.":($author) $article->{title}(".$article->btime.",$self->{mtime})\n";
    foreach (grep {m,^\#,} (split("\n", $article->{body}), $article->{title})) {
        my ($cmd, $param) = m|\# ([^\:]+)(?:\: ([\x00-\xff]+))?|;
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

sub archive {
    my ($self, $brd) = @_;
    push @{$brd->{archives}}, bless ({
        title  => "◆ $self->{descr}",
        author => $self->{owner},
    }, 'OurNet::BBS::CVIC::ArticleGroup');

    push @{$brd->{archives}[-1]}, @{$self->{board}}[1..$#{$self->{board}}];
}

sub _finish_wg {
    my $self = shift;
    my @involved = split(',',$self->{involved});
    if ($#involved+1 < $self->{proposal}{arena}{wg_min}) {
	# we could close the issue board right here because finish_wg
	# is invoked by OurNet::BBSApp::Schedule rather than OurNet::BBSApp::Monitor.
	$self->_delete('closed', "member of workgroup is ".($#involved+1));
	return;
    }
    $self->{status} = 'proposing';
    push @{$self->{board}}, {
    author => 'sysbot',
    title  => "status change: proposing",
    body => << "___",
# status: $self->{status}
# involved: $self->{involved}
___
    };
    delete $self->{sched};
}

sub _finish_pp {
    my $self = shift;
    unless ($self->{draft_cnt}) {
	$self->archive($self->{BBS}{boards}{$self->{proposal}{arena}{name}});
	$self->_delete('closed', 'no proposal');
	return;
    }
    $self->{status} = 'polling';
    push @{$self->{board}}, {
    author => 'sysbot',
    title  => "status change: polling",
    body   => << "___",
# status: $self->{status}
___
    };
    delete $self->{sched};
}

sub _finish_vt {
    my $self = shift;
    my $poll = $self->{poll};
    my @granted;

    for (0..$self->{draft_cnt}-1) {
        push @granted, $_
            if $poll->{vote}[$_] > $poll->{veto}[$_];
    }

    my $cname = $self->{proposal}{arena}{name}; # default to arena

    if (@granted) {
        my $len = length($self->{prefix});
        $cname = sprintf("C_%s%0*d", $self->{prefix}, 10-$len, $self->{proposal}{propno});

        $self->{BBS}{boards}{$cname} = {
            id => $cname,
            bm => 'sysbot',
            title => "共識   $self->{descr}"
        };

        ++$self->{proposal}{arena}{group}{$cname};

        for my $i (0..$self->{draft_cnt}-1) {
            my $art = { %{$self->{draft}[$i]}}; # copy

	        unless ($poll->{vote}[$i] > $poll->{veto}[$i]) {
                $art->{title} = '[-]'.$art->{title};
                $art->{body} =~ s/^\#/>\#/mg;
	        }

            push @{$self->{BBS}{boards}{$cname}{articles}}, $art;
        }
	push @{$self->{BBS}{boards}{$cname}{articles}}, {
	    author => 'sysbot',
	    title  => "new consensus",
	    body   => "# cr_time: ".time()."\n",
	};
	$self->{proposal}{consensus} = OurNet::BBSApp::Consensus->new($self->{BBS},
		{ 'proposal' => $self->{proposal},
		  'prefix' => $self->{prefix},
	      });
    }
    $self->archive($self->{BBS}{boards}{$cname});

    $self->_delete('closed', @granted ? "# consensus: open\n" : '');
    delete $self->{sched};
}

# construct scheduled callback in postprocess because we don't want to
# construct and then cancel it many times when starting up the script
# with existing issues.
sub post_process {
    my $self = shift;
    $self->summarize();
    unless ($self->{sched}) {
    if ($self->{status} eq 'new') {
        $self->{sched} = {
        'time' => $self->wg_time,
        'desc' => "maturization of issue $self->{name}",
        'func' => sub {
            $self->_finish_wg;
        }
        };
    }
    elsif ($self->{status} eq 'proposing') {
        $self->{sched} = {
        'time' => $self->pp_time,
        'desc' => "finalizing of issue $self->{name}",
        'func' => sub {
                $self->_finish_pp;
        },
        };
    }
    elsif ($self->{status} eq 'polling') {
        $self->{sched} = {
        'time' => $self->vt_time,
        'desc' => "killing of issue $self->{name}",
        'func' => sub {
            $self->_finish_vt;
        },
        };
    }
    else {
        die 'unknown status';
    }
      OurNet::BBSApp::Schedule::add($self->{sched});
    }
}

sub wg_time {
    my $self = shift;
    return $self->{cr_time} + $self->{wg_time} * 3600;
}

sub pp_time {
    my $self = shift;
    return $self->wg_time + $self->{pp_time} * 3600;
}

sub vt_time {
    my $self = shift;
    return $self->pp_time + $self->{vt_time} * 3600;
}

sub summarize {
    my $self = shift;
    my ($wg, $output, $progress, $deadline);
    ($wg = $self->{involved}) =~ tr/,/ /;
    $output .= wrap('成員: ', '      ', $wg)."\n";
    if ($output =~ s|^([^\n]+\n[^\n]+\n[^\n]+\n)[\x00-\xff]+|$1|) {
        substr($output, -4) = "...\n";
    }

    if ($self->{status} eq 'new') {
        $output .= "進度: *討論*($#{$self->{board}})\n";
        $output .= "[".localtime($self->wg_time)." 截止]\n";
    }
    elsif ($self->{status} eq 'proposing') {
        $output .= "進度: 討論($#{$self->{board}}) *草案*($self->{draft_cnt})\n";
        $output .= "[".localtime($self->pp_time)." 截止]\n";
    }
    elsif ($self->{status} eq 'polling') {
        $progress = "進度: 討論($#{$self->{board}}) 草案($self->{draft_cnt}) *投票*";
        $deadline = "[".localtime($self->vt_time)." 截止]\n";
        $output .= $progress . (' ' x (80-length($progress)-length($deadline))) . $deadline;

        my $poll = '';
        foreach my $draft (0..$self->{draft_cnt}-1) {
            $poll .= "[$draft:+".int($self->{poll}{vote}[$draft])."/-".
                               int($self->{poll}{veto}[$draft])."] ";
        }

        $output .= wrap('計票: ', '      ', $poll)."\n";
        $output .= "\n";
    }

    my @cnt = $output =~ m/\n/g;
    $output = "\n$output" if $#cnt < 4;

    $self->{BBS}{boards}{$self->{name}}{etc_brief} = "$self->{descr}\n$output";
}

1;
