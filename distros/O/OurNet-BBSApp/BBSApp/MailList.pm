package OurNet::BBSApp::MailList;
use base qw/OurNet::BBSApp::Board/;
use fields qw/domain list group owner password filter starttime/;
use strict;
use vars qw/$toplevel/;

$toplevel = '/usr/local/majordomo';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    print "checking $toplevel/lists/$self->{domain}/$self->{list}\n";
    $self->makelist unless -d "$toplevel/lists/$self->{domain}/$self->{list}";
    $self->{board} = $self->{BBS}{boards}{$self->{name}}{articles};
    $self->{starttime} = (scalar time);
    return $self;
}

sub article {
    my ($self, $article) = @_;
    # check for mail filter...
    return if $article->btime < $self->{starttime}; # do not process past mails
    return if (ref($self->{filter}) eq 'CODE' and !$self->{filter}->($article));
    return if substr($article->{author}, -1) eq '.'; # internet post: not yet
    print "new article at ".$self->{name}.": $article->{title}\n";
    open _, "| sendmail -f$article->{author}.bbs\@$self->{domain} $self->{list}\@$self->{domain}";
    print _ (
        (index($self->{body}, "\n時間: ") > -1)
            ? substr(
                $self->{body},
                index(
                    $self->{body},
                    "\n\n",
                    index(
                        $self->{body},
                        '時間: '
                    )
                )
            )
            : $self->{body}
    );
    close _;
}

sub makelist {
    my $self = shift;
    my $file = "/tmp/newlist-$self->{list}";
    mkdir '/tmp' unless -d '/tmp'; # non-unixish

    open _, ">$file";
    print _ <<"___";
createlist-noarchive-nowelcome-force $self->{list} $self->{owner}
configset $self->{list} default_flags <<TAG
replyto
rewritefrom
TAG
subscribe $self->{list} $self->{name}.board\@$self->{domain}
___

    system("$toplevel/bin/mj_shell -d$self->{domain} -p$self->{password} -F$file");
    unlink $file;
}
1;
