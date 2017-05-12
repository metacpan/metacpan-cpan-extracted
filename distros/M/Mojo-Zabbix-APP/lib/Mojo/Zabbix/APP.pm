package Mojo::Zabbix::APP;

use strict;
use warnings;
use Mojo::Zabbix;
use utf8;

use POSIX qw(strftime);

require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(initZ pVersion getAllhost getname getItem getAlert  getEvents pHitems pTriggers);

=encoding utf8

=head1 NAME

Mojo::Zabbix::APP - The application module of Mojo-Zabbix .Using to get
data from zabbix data include host,items, Triggers and warns and so on.


=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use Mojo::Zabbix::APP;

    my @myzinfo = <DATA>; ##(get zabbix info from __DATA__ )

# Define for debug and traceing processe infomaition。（打开调试和跟踪）
   
   my $DEBUG=0;
   my $TRACE=0;

#my @myzinfo = ('test1 http://test1/zabbix testuser pass');
# @可以定义为多行数据，格式按照这种，一个zabbix 服务地址一个

  for (@myzinfo) {
    next if /^#/;
    next if /^\s*$/;
    my ( $name, $url,$user, $pass ) = split;
    print "\n$name\n";
    my $z;

    eval { $z = initZ( $url,$user,$pss ); };

    if ($@) {

        print "Error $@!\n";
 
    } else {
       
      ## Print the version of zabbix api. 打印zabbix 版本 
       
        pVersion($z);
        
       ## Print all host lists。 获取所有的主机列表
        
       print  getAllhost($z);

       ## Print warning info of Triggers。打印取得的所有触发器告警信息
       pTriggers($z);
       
       ## Print the history data of given items, default for past 24 hours.
       ## 打印给定时间段的item历史数据，如果默认不给时间默认为过去24小时内的
       pHitems($z);

    }
 }

=cut

#### 初始化的Mojo::zabbix ，必须安装Mojo::zabbix模块,可用cpanm Mojo::zabbix 安装
my %EVcache;
my %HTcache;
my %Vcache;
## 缓存hash 对事件id进行缓存，防止重复调用
my $DEBUG = 0;
my $TRACE = 0;

sub initZ {

    my ( $url, $user, $pass ) = @_;
    print "debug-initZ { parameter } : $url, $user, $pass \n" if $DEBUG;
    my $zbbix = Mojo::Zabbix->new(
        url      => $url,
        username => $user,
        password => $pass,
        debug    => $DEBUG,
        trace    => $TRACE,
    );
}

### 打印zabbix 版本

sub pVersion {

   my $z = shift;
   my $ckey=$z->{'API_URL'};
  unless ( exists $Vcache{$ckey} ) {
    my $result;
    my $auth=$z->{'Auth'};
    $z->{'Auth'}="";
    my $r = $z->get( "apiinfo.version", );
     $z->{'Auth'}=$auth;
     $result = $r->{'result'} if $r->{'result'};
     $result = pVersion2($z) unless $r->{'result'};

     $Vcache{$ckey} = $result;
   }
    return $Vcache{$ckey};
}

sub pVersion2 {

    my $z = shift;
    my $r = $z->get( "apiinfo.version", );
    my $result = $r->{'result'};
    return $result;
}

### 打印给定时间段的item历史数据，如果默认不给时间默认为过去24小时内的
sub pHitems {
    my ( $z, $host, $key, $btime, $ltime ) = @_;
    $host  //= '192.168.1.1';
    $key   //= 'net.if.in[bond0]';
    $btime //= time() - 1 * 3600;
    $ltime //= time();
    my $info;
    my $hostid = gethostID( $z, $host );
    my ( $name, $itemid ) = getItemID( $z, $hostid, $key );
    $info = "The Item of $name-$key \n\n";
    print "debug-PHitems { parameter } : $host $key $btime $ltime \n" if $DEBUG;
    my $v = getHisv( $z, $hostid, $itemid, $btime, $ltime );

    for ( sort { $b <=> $a } @{$v} ) {

        #print Dumper($_);
        my $stime = strftime( "%Y-%m-%d %H:%M:%S", localtime( $_->[0] ) );
        $info .= "$stime  $_->[1] \n";

    }
    return $info;
}

### 打印取得的所有触发器告警信息

sub pTriggers {

    my $z = shift;
    my $info;
    my $reslut = getTriggers($z);
    $info = "\n\nWarning info of Triggers \n\n";

    for ( sort { $b <=> $a } keys %{$reslut} ) {

        $info .= "$reslut->{$_}";

    }
    return $info;
}
##### 获取给定主机和key值的所有监控项以及当前值

sub getItem {

    my ( $z, $host, $key ) = @_;

    return unless gethostID( $z, $host );
    my $hostid = gethostID( $z, $host );
    my $r = $z->get(
        "item",
        {

            output => [ "name", "key_", "prevvalue" ],
            search  => { "key_" => $key },
            hostids => $hostid,

            #    limit => 10,

        },
    );

    my $result = $r->{'result'};
    my $sresult;

    $sresult .= "$_->{'name'} - { $_->{'key_'} } : $_->{'prevvalue'} \n"
      for ( @{$result} );

    return $sresult;
}

sub getItemID {

    my ( $z, $hostid, $key ) = @_;
    print "DEBUG-function(getItemID): $z, $key \n" if $DEBUG;
    my $r = $z->get(
        "item",
        {

            output => [ "itemids", "name" ],
            search  => { "key_" => $key },
            hostids => $hostid,

        },
    );

    my $result = $r->{'result'};
    my $sresult;

    $sresult = $result->[0]->{'itemid'};

    return ( $result->[0]->{'name'}, $result->[0]->{'itemid'} );
}

sub getHost {

    my ( $z, $hostid) = @_;
    my $r = $z->get(
        "host",
        {
     
            hostids => $hostid,
            output=> ["host"],

        },
    );

return  $r->{'result'}->[0]->{host} if $r->{'result'};


}

sub getHisv {

    my ( $z, $hostid, $itemid, $btime, $ltime ) = @_;
    print "DEBUG-function(-getHist): $z, $hostid, $itemid, $btime, $ltime \n"
      if $DEBUG;
    my $r = $z->get(
        "history",
        {
            #        history => 0,
            itemids   => $itemid,
            time_from => $btime,
            time_till => $ltime,
            output    => "extend",
            hostids   => $hostid,

        },
    );

    my $result = $r->{'result'};
    my $sresult;

#$sresult.="$_->{'name'} - $_->{'_key'} : $_->{'prevvalue'} \n" for(@{$result});
#print Dumper($result);
    for ( @{$result} ) {

        push @{$sresult}, [ $_->{'clock'}, $_->{'value'} ];

    }
    return $sresult;
}

#### 获取给定主机（ip）的主机号
sub gethostID {
    my ( $z, $host ) = @_;
    my $ckey = $host;
    unless ( exists $HTcache{$ckey} ) {
        print "DEBUG-function(gethostID): $z, $host \n" if $DEBUG;
        my $r = $z->get(
            "host",
            {
                filter => {
                    host => $host,
                },
                output => ["hostid"],
            },
        );
        $HTcache{$ckey} = $r->{'result'}->[0]->{'hostid'} if $r->{'result'};
    }
    return $HTcache{$ckey};
}

sub getname {

    my ( $z, $host ) = @_;
    print "DEBUG-function(gethostname): $z, $host \n" if $DEBUG;
    my $r = $z->get(
        "host",
        {
            filter => {
                host => $host,
            },
            output => ["name"],
        },
    );

    #use Data::Dumper;
    return $r->{'result'}->[0]->{'name'} if $r->{'result'};
}
#### 获取所有的主机列表

sub getAllhost {

    my $z = shift;
    my $r = $z->get(
        "host",
        {
            filter => undef,
            search => undef,
            output => [ "host", "name" ],
        },
    );

    my $hresult;
    my $host = $r->{'result'};
    for (@$host) {
        $hresult .= $_->{'host'} . ": $_->{'name'}" . "\n";
    }

    return $hresult;
}

sub getAllhostid {

    my $z = shift;
    my $hostsids;
    my $r = $z->get(
        "host",
        {
            filter => undef,
            search => undef,
            output => [ "hostid" ],
        },
    );

    my $hresult;
    my $host = $r->{'result'};
    for (@$host) {
        push(@{$hostsids},$_->{'hostid'});
    }

    return $hostsids;;
}

####获取所有的有问题触发警告信息,返回一个包含时间、主机ip和描述的哈希引用

sub getTriggers {
    my $z        = shift;
    my $V=pVersion($z);
       $V=~s/(\d).*/$1/;
    my $getv3={
            filter => {
                value                    => 1,
                only_true                => 1,
                withUnacknowledgedEvents => 1,
            },
            output     => ["hostid","triggerid", "description", "priority" ],
            sortfield  => "triggerid",
            sortorder  => "DESC",
            selectHosts => "host",

    };

    my $getv2={
            filter => {
                value                    => 1,
                only_true                => 1,
                withUnacknowledgedEvents => 1,
            },
            output     => ["hostid","triggerid", "description", "priority" ],
            sortfield  => "triggerid",
            sortorder  => "DESC",
            expandData => "host",
    };

    my $hresult;
   
 if ($V eq "2") {
        my $r = $z->get("trigger",$getv2);
        my $host=$r->{'result'};
        for (@$host) {
        my $hostid   = gethostID( $z, $_->{'host'});
        my $etime = getTgtime( $z, $_->{'triggerid'}, $hostid );
        next unless $etime;
        my $time = strftime( "%Y-%m-%d %H:%M:%S", localtime($etime) );
        $hresult->{$etime} =
          "$time : $_->{'host'}: " . $_->{'description'} . "\n";
        }
   }
   else {
 
        my $r=  $z->get("trigger",$getv3);
        my $host=$r->{'result'};
         for (@$host) {
        my $hostid = $_->{'hosts'}->[0]->{'hostid'};
        my $host=getHost($z,$hostid);
        my $etime = getTgtime( $z, $_->{'triggerid'}, $_->{'hosts'}->[0]->{'hostid'} );
        next unless $etime;
        my $time = strftime( "%Y-%m-%d %H:%M:%S", localtime($etime) );
           $hresult->{$etime} =
          "$time : $host  " . $_->{'description'} . "\n";
    }
   }   
    return $hresult;
}

### 给定触发器，触发器处罚时间(限制24小时候内的).

sub getTgtime {

    my ( $z, $tgid, $host ) = @_;
    my $hostid=$host;
    #my $hostid   = gethostID( $z, $host );
    my $ysterday = time() - 20 * 3600;
    my $vkey     = $tgid . $hostid;
    unless ( exists $EVcache{$vkey} ) {
        my $r = $z->get(
            "event",
            {
                filter => {

                    # value => 1,
                    # objectids => '19011' ,
                    # triggerids  => '19011' ,
                    #source  => 0,
                },

                objectids  => $tgid,
                triggerids => $tgid,
                time_from  => $ysterday,
                hostids    => $hostid,

                #select_acknowledges => "extend",
                output => "extend",

                sortfield => "eventid",
                sortorder => "DESC",

                #  expandData=>"host",

            },
        );
        $EVcache{$vkey} = $r->{'result'}->[0]->{'clock'} if $r->{'result'};
    }
    return $EVcache{$vkey};
}


sub getEvent {
    my $z        = shift;
    my $ysterday = time() - 1 * 3600;
    my $r        = $z->get(
        "event",
        {
         filter => {

                # value => 1,
                acknowledged => 0,

                #time_from=> "$ysterday",
            },
            time_from           => "$ysterday",
            output              => "extend",
            source              => 0,
            select_acknowledges => "extend",

            #sortfield =>["clock", "eventid"],
            #sortorder => "DESC",
            #  expandData=>"host",

        },
    );
    my $host    = $r;
    my $hresult = Dumper($r);
    return $hresult;
}


sub getEvents {
    my $z        = shift;
    my $ysterday = time() - 15 * 3600;
    my $r        = $z->get(
        "event",{
            #filter => {

               # value => 1,
               # acknowledged => 0,

                #time_from=> "$ysterday",
           # },
            acknowledged =>0,
            value => 1,
            time_from           => "$ysterday",
            output              => "extend",
           # select_acknowledges=> "extend",
            source              => 0,
            sortfield =>["clock", "eventid"],
            sortorder => "DESC",
            expandData=>"host",

        },
    );
    my $hresult = Dumper($r);
    my $result=$r->{'result'} if $r->{'result'};
    # print getTrigger($z,$_->{'objectid'}) for(@$result); 
    #return $hresult;
}

sub getAlert {
    my $z        = shift;
    my $ysterday = time() - 24 * 3600;
    my $r        = $z->get(
        "alert",
        {
#            time_from           => "$ysterday",
            output => "extend",
            sortfield => ["clock"],
            sortorder => "DESC",

        },
    );
    my $hresult = Dumper($r);
    return $hresult;
}


=head1 AUTHOR

ORANGE, C<< <bollwarm at ijz.me> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojo-zabbix-app at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojo-Zabbix-APP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojo::Zabbix::APP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojo-Zabbix-APP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojo-Zabbix-APP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojo-Zabbix-APP>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojo-Zabbix-APP/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 ORANGE.

This is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.

=cut

1;

