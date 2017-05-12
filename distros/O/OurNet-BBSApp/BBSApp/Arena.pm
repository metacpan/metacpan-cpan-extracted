package OurNet::BBSApp::Arena;

use base qw/OurNet::BBSApp::Board/;
use fields qw/group wg_time pp_time vt_time wg_min proposal_cnt moderator
    veto_time veto_min/;
use strict;
use OurNet::BBSApp::CmdPerm;
use OurNet::BBSApp::Proposal;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{prefix} = $self->{name};
    $self->{prefix} =~ s/(\w+)[_\.\-]\w+/$1/;
    $self->{board} = $self->{BBS}{boards}{$self->{name}}{articles};
    $self->{group} = $self->{BBS}{groups}{$self->{group}};
    $self->{proposal_cnt} = 0;
    $self->{$_} ||= 1 foreach (qw/wg_time pp_time vt_time/);
    $self->{wg_min} ||= 3;

    return $self;
}

sub config {
    my ($self, $article) = @_;
    return unless $article->{author} eq 'sysbot';
    foreach (grep {m,^\#,} split("\n", $article->{body})) {
        my ($cmd, $param) = m|\# ([^\:]+)(?:\: ([\x00-\xff]+))?|;
	    next unless $cmd;
	    $self->{$cmd} = $param if exists $self->[0]{$cmd};
    }
}

sub article {
    my ($self, $article) = @_;
    print "new article at ".$self->{name}.": $article->{title}\n";
    return $self->config($article) if $article->{title} =~ m/\[conf\]/
	                           or $article->{title} =~ m/\[\Q設定\E\]/;
    return unless $article->{title} =~ m/^\[prop\]/
               or $article->{title} =~ m/^\[\Q提案\E\]/;
    $article->{author} .= '.' unless $article->{author} =~ m/\.$/;

    my %proposal;
    $proposal{owner} = $article->{author};
    $proposal{owner} =~ s/\.$//;
    foreach (grep {m,^\#,} split("\n", $article->{body})) {
        my ($cmd, $param) = m|\# ([^\:]+)(?:\: ([\x00-\xff]+))?|;
	next unless $cmd;
	my $ret = OurNet::BBSApp::CmdPerm::check($self, \%proposal, $article, $cmd, $param);
	next if $ret xor defined($ret);
	print "$cmd = $param\n";
        $proposal{$cmd} = $param;
    }
    return if $proposal{'status'} && $proposal{'status'} eq 'closed';
    $proposal{'status'} ||= 'new';
    $proposal{'descr'} ||= 'undescribed';

    foreach my $param (qw/wg_time pp_time vt_time wg_min/) {
        $proposal{$param} = $self->{$param}
            if $proposal{$param} < $self->{$param};
    }


    print "[arena] new proposal $self->{proposal_cnt}\n";
    OurNet::BBSApp::Proposal->new($self, $article, \%proposal, $self->{proposal_cnt}++);
}

1;
