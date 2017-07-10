package ZooItServer;

use strict;
use warnings;

use FindBin;
use File::Temp qw(tempdir);

use Net::ZooKeeper qw(:all);
use Net::ZooIt;

sub _gen_cfg {
    my $ip = '127.0.0.1';
    my $port = 2182;
    my $url = "$ip:$port";
    my $ETC = "$FindBin::Bin/etc";
    my $VAR = tempdir(CLEANUP => 1);
    open DEF, '<', "$ETC/zoo.cfg.default" or die $!;
    open CFG, '>', "$VAR/zoo.cfg" or die $!;
    while (<DEF>) {
        s/^(dataDir)=.*/$1=$VAR/;
        s/^(clientPort)=.*/$1=$port/;
        s/^#(preAllocSize)=.*/$1=1024/;
        print CFG;
    }
    close DEF;
    close CFG;
    my $cmd = <<EOF;
/usr/bin/java -cp $ETC:/usr/share/java/jline.jar:/usr/share/java/log4j-1.2.jar:/usr/share/java/xercesImpl.jar:/usr/share/java/xmlParserAPIs.jar:/usr/share/java/netty.jar:/usr/share/java/slf4j-api.jar:/usr/share/java/slf4j-log4j12.jar:/usr/share/java/zookeeper.jar -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false -Dzookeeper.log.dir=$VAR -Dzookeeper.root.logger=INFO,ROLLINGFILE org.apache.zookeeper.server.quorum.QuorumPeerMain $VAR/zoo.cfg
EOF
    return $cmd, $url, $VAR;
}

sub start {
    my $self;
    if (ref $_[0]) {
        $self = shift;
        return unless $$ == $self->{parent};
    } else {
        $self = bless {}, shift;
        $self->{parent} = $$;
        @{$self}{qw(cmd url dir)} = _gen_cfg();
        print STDERR "$$ Running in $self->{dir}\n";
    }

    $self->stop if $self->{pid};
    $self->{pid} = fork;
    die $! unless defined $self->{pid};
    unless ($self->{pid}) {
        print STDERR "$$ Starting ZooKeeper server on $self->{url}\n";
        exec $self->{cmd};
        die $!;
    }

    return $self;
}

sub connect {
    my $self = shift;
    if (!$self->{zk} || $$ != $self->{parent}) {
        delete $self->{zk};
        print STDERR "$$ Connecting to ZK on $self->{url}\n";
        $self->{zk} = Net::ZooKeeper->new($self->{url}, session_timeout => 5000);
    }
    for (1 .. 20) {
        sleep 1;
        print STDERR "$$ Tryimg to connect to $self->{url}: ";
        my @z = $self->{zk}->get_children('/');
        my $err = $self->{zk}->get_error;
        print STDERR Net::ZooIt::zerr2txt($err), "\n";
        unless ($err == ZOK) {
            die "$$ Unable to connect to ZK" if $_ >= 20;
            next;
        }
        print STDERR "$$ Connected to $self->{url}\n";
        last;
    }
    return $self->{zk};
}

sub stop {
    my $self = shift;
    return unless $$ == $self->{parent};
    print STDERR "$$ Stopping server\n";
    $self->{pid} and kill 'TERM', $self->{pid};
    wait;
    delete $self->{pid};
}

sub DESTROY {
    my $self = shift;
    $self->stop;
}

1;
