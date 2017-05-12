package Mojolicious::Plugin::DirectoryQueue;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON qw(decode_json encode_json);
use Directory::Queue;
use POSIX qw(chown);

our $VERSION = '0.01';


sub register {
    my ($plugin, $app, $args) = @_;

    $args->{path}  ||= '/tmp/DirQueue';
    my $dirq = Directory::Queue->new( path => $args->{path} );

    my $config = $app->config;
    if ( $config->{hypnotoad} and $config->{hypnotoad}->{user} ) {
        my ($uid,$gid) = ( getpwnam($config->{hypnotoad}->{user}) )[2,3];
        chown $uid, $gid, $args->{path};
    }

    $app->helper(
        enqueue => sub {
            my ($self, $args) = @_;
            $dirq->add(encode_json($args));
        },
    );

    $app->helper(
        dequeue => sub {
            for (my $name = $dirq->first(); $name; $name = $dirq->next()) {
               next unless $dirq->lock($name);
               my $data = $dirq->get($name);
               $dirq->remove($name);
               return decode_json($data) if $data;
            }
            return;
        },
    );

    $app->helper(
        show => sub {
            my @all;
            for (my $name = $dirq->first(); $name; $name = $dirq->next()) {
               next unless $dirq->lock($name);
               my $data = $dirq->get($name);
               push @all, decode_json($data) if $data;
               $dirq->unlock($name);
            }
            return \@all;
        },
    );

    $app->helper(
        count => sub {
            return $dirq->count();
        },
    );
    $app->helper(
        purge => sub {
            my $self = shift;
            return $dirq->purge(@_);
        },
    );
};

1;
__END__

=pod 

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::DirectoryQueue - Mojolicious 应用使用的内部队列服务, 基本本地文件系统的队列系统 , 为方便做任务应用使用. 

=head1 SYNOPSIS

    plugin 'DirectoryQueue' => {
        path => '/tmp/DirQueue',
    };


=head1 DESCRIPTION

Mojolicious::Plugin::DirectoryQueue 这个模块主要是基于本地文件系统, 创建一个队列服务, 为 Mojolicious 的多进程时共享使用, 并可以很简单方便的和第三方结合. 如果直接给 Mojolicious 内部使用事件驱动的其它功能可以直接使用这个来做内部的队列调度. 

默认内部传送的入队可以直接使用任意的数据库结构. 会被序列化成 json 结构.

=head1 配置

=over 1

=item path

  path => '/tmp/DirQueue',

用于设置队列存放的位置

=back

=head1 方法

=over 5

=item enqueue 

入队, 可以传送任意数据结构到队列中, 会被存成 json 结构到队列系统内部 ( 文件系统 ).

=item dequeue 

出队, 取出队列中一个任务, 结果会被反序列化成数据结构.

=item show 

一次性查看所有的队列中的任务的详细信息. 这时会给所有的数据都显示出来. 并不删除任务.

=item count

当前队列中所存在的任务数量

=item purge

调用的时候清除任务 hash 时不用的文件夹

=back

=head1 AUTHOR

fu kai E<lt>iakuf {at} 163.comE<gt>

=head1 SEE ALSO

L<Directory::Queue>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
