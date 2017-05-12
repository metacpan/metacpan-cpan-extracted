package Plack::Middleware::IPMatch;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Net::IP::XS;
use Net::IP::Match::Trie;
our $VERSION = 0.04;

use Plack::Util::Accessor qw( IPFile );

sub _build_real_ip {
    my ($env) = @_; 

    my @possible_forwarded_ips
        = grep {
        $_->iptype
            !~ /^(?:LOOPBACK|LINK\-LOCAL|PRIVATE|UNIQUE\-LOCAL\-UNICAST|LINK\-LOCAL\-UNICAST|RESERVED)$/xo
        }   
        grep {defined}
        map  { Net::IP::XS->new($_) }
        grep {defined} (
            $env->{'HTTP_X_REAL_IP'},
            $env->{'HTTP_CLIENT_IP'},
            split( /,\s*/xo, $env->{'HTTP_X_FORWARDED_FOR'} // '' ),
            $env->{'HTTP_X_FORWARDED'},
            $env->{'HTTP_X_CLUSTER_CLIENT_IP'},
            $env->{'HTTP_FORWARDED_FOR'},
            $env->{'HTTP_FORWARDED'},
        );  

    return $possible_forwarded_ips[0]
        // Net::IP::XS->new( $env->{'REMOTE_ADDR'} // '' );
}


sub prepare_app {
    my $self = shift;

    if (my $ipfiles = $self->IPFile) {
        my @ipfiles = ref $ipfiles ? @{ $ipfiles } : ($ipfiles);
        for my $ipfile (@ipfiles) {
            my $match = Net::IP::Match::Trie->new();

            open my $fh, "<", $ipfile or die "$!";
            while (<$fh>) {
                chomp;
                my ($CIDRS, $lable) = split(/[,|\s]/, $_);
                $match->add( $lable , [$CIDRS] );
            }   
            push @{ $self->{IPMatcher} }, $match;
        }
    }
}

sub call {
    my $self = shift;
    my $env  = shift;

    my $ip;
    if ($env->{QUERY_STRING} =~ /(?:^|&)ip=([^&]+)/) {
        $ip = $1; 
    }
    else {
        $ip = _build_real_ip($env)->ip;
    }
    $env->{MATCH_IP} = $ip;

    foreach my $matcher (@{ $self->{IPMatcher} }) {
        my $label = $matcher->match_ip($ip);
        $env->{IPMATCH_LABEL} = $label and last;
    }

    return $self->app->($env);
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Plack::Middleware::IPMatch - 查找指定 IP (CIDR) 所对应的标签 LABEL  

=head1 SYNOPSIS

  enable 'Plack::Middleware::IPMatch',
      IPFile => [ '/path/to/CT.txt', '/path/to/CNC.txt' ];

=head1 DESCRIPTION

Plack::Middleware::IPMatch 这个是使用, Net::IP::Match::Trie 来实现的超级快的进行 CIDR 转换成指定的 LABEL 的模块.
因为是使用的前缀树实现, 所以有着超级快的查询速度.

=head1 CONFIGURATION


=head2 IPFile

  IPFile =>   '/path/to/CT-IP.dat';
  IPFile => [ '/path/to/CT-IP.dat',   '/path/to/CNC-IP.dat' ];

这个需要本身有自己整理过的 IP 数据库, 然后给整个数据库存成文本格式

=head2 IPFile 格式 
 
格式需要自己来收集 IP 数据, 存成如下格式的文本

  112.122.128.0/21,CNC-AH-AH
  112.122.136.0/23,CNC-AH-AH
  112.122.138.0/25,CNC-AH-AH
  112.122.138.128/29,CNC-AH-AH
  112.122.138.144/28,CNC-AH-AH
  112.122.138.160/27,CNC-AH-AH
  112.122.138.192/26,CNC-AH-AH

=head1 Header

=head2 IPMATCH_LABEL

默认会在 $env 的哈希中增加 C<IPMATCH_LABEL> 的字段的 Header,  这就是查询的结果

可以使用如下的方式来访问

  $env->{IPMATCH_LABEL}

=head2 MATCH_IP

进行 ip 转换时候所使用的 IP 地址, 默认会存到这个 header 中传给应用


=head1 AUTHOR

扶凯 E<lt>iakuf@163.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Net::IP::Match::Trie|https://metacpan.org/pod/Net::IP::Match::Trie>

L<Plack::Middleware::GeoIP|https://metacpan.org/pod/Plack::Middleware::GeoIP>

=cut
