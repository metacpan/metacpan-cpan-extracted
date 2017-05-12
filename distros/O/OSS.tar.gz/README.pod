=encoding utf-8

=head1 NAME

OSS - 阿里云对象存储oss管理接口

=head1 SYNOPSIS

    #!/usr/bin/evn perl
    use warnings;
    use strict;

    use OSS;

    my $ali_access_key_id       = '';
    my $ali_secret_access_key   = '';

    my $oss = OSS->new(
        {
            $ali_access_key_id     => $ali_access_key_id,
            $ali_secret_access_key => $ali_secret_access_key,

        }
    );
    my $buckets = $oss->buckets;


    my $bucket_name = 'mytest';
    #创建bucket
    my $bucket = $oss->add_bucket({bucket =>$bucket_name}) or die $oss->err . ": " . $oss->errstr;

=head1 DESCRIPTION

OSS 提供操作oss存储接口

=head1 AUTHOR

Crisewng <crisewng@gmail.com>
