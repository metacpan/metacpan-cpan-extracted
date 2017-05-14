package OSS;
use strict;
use warnings;

use OSS::Bucket;
use Carp;
use HTTP::Date;
use Digest::HMAC_SHA1;
use MIME::Base64 qw(encode_base64);
use base qw(Class::Accessor::Fast);
use HTTP::Headers;
use LWP::UserAgent::Determined;
use XML::Simple;
use URI::Escape qw(uri_escape_utf8);

my $ALI_HEADER_PREFIX ='x-oss';
__PACKAGE__->mk_accessors(
qw(ali_access_key_id ali_secret_access_key host secure timeout ua err errstr)
);

our $VERSION = '0.11';
my $KEEP_ALIVE_CACHESIZE = 10;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    die "No ali_access_key_id"     unless $self->ali_access_key_id;
    die "No ali_secret_access_key" unless $self->ali_secret_access_key;
    $self->secure(0)                if not defined $self->secure;
    $self->timeout(30)              if not defined $self->timeout;
    
    $self->host('oss-cn-hangzhou.aliyuncs.com') if not defined $self->host;
    my $ua;
    $ua = LWP::UserAgent->new(
        keep_alive            => $KEEP_ALIVE_CACHESIZE,
        requests_redirectable => [qw(GET HEAD DELETE PUT)],
    );

    $ua->timeout($self->timeout);
    $ua->env_proxy;
    $self->ua($ua);
    return $self;

}


sub buckets {
    my $self = shift;
    my $r = $self->_send_request('GET', '', {});
    
    return undef unless $r;
    
    my $owner_id          = $r->{Owner}{ID};
    my $owner_displayname = $r->{Owner}{DisplayName};
    
    my @buckets;
    
    if (ref $r->{Buckets}) {
        my $buckets = $r->{Buckets}{Bucket};
        $buckets = [$buckets] unless ref $buckets eq 'ARRAY';
        foreach my $node (@$buckets) {
            push @buckets,
            OSS::Bucket->new(
            {   bucket        => $node->{Name},
                creation_date => $node->{CreationDate},
                account       => $self,
            }
            );
            
        }
    }
    return {
        owner_id          => $owner_id,
        owner_displayname => $owner_displayname,
        buckets           => \@buckets,
    };
};

sub list_bucket {
    my ($self, $conf) = @_;
    my $bucket = delete $conf->{bucket};
    croak 'must specify bucket' unless $bucket;
    $conf ||= {};

    my $path = $bucket . "/";

    if (%$conf) {
        $path .= "?"
          .join('&',
                map {$_ . "=" . $self->_urlencode($conf->{$_}) } keys %$conf );
    }
    my $r = $self->_send_request('GET', $path, {});

    return undef unless $r && !$self->_remember_errors($r);


    my $return = {
                  bucket       => $r->{Name},
                  prefix       => $r->{Prefix},
                  marker       => $r->{Marker},
                  next_marker  => $r->{NextMarker},
                  max_keys     => $r->{MaxKeys},
                  is_truncated => (
                                   scalar $r->{IsTruncated} eq 'true'
                                   ? 1
                                   : 0
                                  ),
                 };
    my @keys;
    for my $node (@{$r->{Contents}}) {
      my $etag = $node->{ETag};
      $etag =~ s{(^"|"$)}{}g if defined $etag;
      push @keys,{
                  key               => $node->{Key},
                  last_modified     => $node->{LastModified},
                  etag              => $etag,
                  size              => $node->{Size},
                  storage_class     => $node->{StorageClass},
                  owner_id          => $node->{Owner}{ID},
                  owner_displayname => $node->{Owner}{DisplayName},
                 };
    }
    $return->{keys} = \@keys;
    
    if ($conf->{delimiter}) {
      my @common_prefixes;
      my $strip_delim = qr/$conf->{delimiter}$/;
      foreach my $node ($r->{CommonPrefixes}) {
        my $prefix = $r->{Prefix};
        $prefix =~ s/$strip_delim//;
        push @common_prefixes, $prefix;
        
      }
      $return->{common_prefixes} = \@common_prefixes;
    }

    return $return;
}

sub add_bucket {
    my ($self, $conf) = @_;
    my $bucket = $conf->{bucket};
    croak 'must specify bucket' unless $bucket;
    
    #验证bucket访问权限
    if ($conf->{acl_short}) {
        $self->_validate_acl_short($conf->{acl_short});
    }
    
    my $header_ref =
    ($conf->{acl_short})
    ? {'x-oss-acl' => $conf->{acl_short}}
    : {};
    
    #指定bucket所在的数据中文 默认是oss-cn-hangzhou
    
    my $data = '';
    if (defined $conf->{location_constraint}) {
        $data =
        "<CreateBucketConfiguration><LocationConstraint>"
        . $conf->{location_constraint}
        . "</LocationConstraint></CreateBucketConfiguration>";
    }
    
    return 0
    unless $self->_send_request_expect_nothing('PUT', "$bucket/",
    $header_ref, $data);
    return $self->bucket($bucket);
}

sub delete_bucket {
    my ($self, $conf) = @_;
    my $bucket;
    if (eval { $conf->isa("OSS::Bucket"); }) {
        $bucket = $conf->bucket;
    }
    else {
        $bucket = $conf->{bucket};
    }
    croak 'must specify bucket' unless $bucket;
    return $self->_send_request_expect_nothing('DELETE', $bucket . "/", {});
}


sub bucket {
    my ($self, $bucketname) = @_;
    return OSS::Bucket->new({bucket => $bucketname, account => $self});
}

sub _send_request_expect_nothing {
    my $self    = shift;
    my $request = $self->_make_request(@_);
    
    my $response = $self->_do_http($request);
    my $content  = $response->content;
    
    return 1 if $response->code =~ /^2\d\d$/;
    
    # anything else is a failure, and we save the parsed result
    $self->_remember_errors($response->content);
    return 0;
}

sub _send_request {
    my $self = shift;
    my $request;
    $request = $self->_make_request(@_);
    my $response = $self->_do_http($request);
    my $content = $response->content;
    return $content unless $response->content_type eq 'application/xml';
    return unless $content;
    return $self->_xpc_of_content($content);
}
# returns 1 if errors were found

sub _remember_errors {
    my ($self, $src) = @_;
    
    unless (ref $src || $src =~ m/^[[:space:]]*</) {    # if not xml
        (my $code = $src) =~ s/^[[:space:]]*\([0-9]*\).*$/$1/;
        $self->err($code);
        $self->errstr($src);
        return 1;
    }
    
    my $r = ref $src ? $src : $self->_xpc_of_content($src);
    
    if ($r->{Error}) {
        $self->err($r->{Error}{Code});
        $self->errstr($r->{Error}{Message});
        return 1;
    }
    return 0;
}

sub _make_request {
    my ($self, $method, $path, $headers) = @_;
    croak 'must specify method' unless $method;
    croak 'must specify path'   unless defined $path;
    $headers ||= {};
    
    my $http_headers = $self->_merge_meta($headers);
    $self->_add_auth_header($http_headers, $method, $path)
    unless exists $headers->{Authorization};
    my $protocol = $self->secure ? 'https' : 'http';
    my $host     = $self->host;
    my $url      = "$protocol://$host/$path";
 
    my $request = HTTP::Request->new($method, $url, $http_headers);
    
    return $request;
}

sub _xpc_of_content {
    return XMLin($_[1], 'SuppressEmpty' => '', 'ForceArray' => ['Contents']);
}

sub _add_auth_header {
    my ($self, $headers, $method, $path) = @_;
    my $ali_access_key_id     = $self->ali_access_key_id;
    my $ali_secret_access_key = $self->ali_secret_access_key;
    
    if (not $headers->header('Date')) {
        $headers->header(Date => time2str(time));
    }
    my $canonical_string = $self->_canonical_string($method, $path, $headers);
    my $encoded_canonical =
    $self->_encode($ali_secret_access_key, $canonical_string);
    $headers->header(
    Authorization => "OSS $ali_access_key_id:$encoded_canonical");
    
}

sub _encode {
    my ($self, $ali_secret_access_key, $str, $urlencode) = @_;
    my $hmac = Digest::HMAC_SHA1->new($ali_secret_access_key);
    $hmac->add($str);

    my $b64 = encode_base64($hmac->digest);
    return $b64;

}

sub _do_http {
    my ($self, $request, $filename) = @_;
    
    # convenient time to reset any error conditions
    $self->err(undef);
    $self->errstr(undef);
    return $self->ua->request($request, $filename);
}

sub _canonical_string  {
    my ($self, $method, $path, $headers) = @_;
    my %interesting_headers = ();
    while (my ($key, $value) = each %$headers) {
        my $lk = lc $key;
        if (   $lk eq 'content-md5'
            or $lk eq 'content-type'
            or $lk eq 'date') {
            $interesting_headers{$key} = $self->_trim($value);
            }
    }
    
    $interesting_headers{'content-type'} ||= '';
    $interesting_headers{'content-md5'}  ||= '';
    
    my $buf = "$method\n";
    foreach my $key (sort keys %interesting_headers) {
        if ($key =~/^$ALI_HEADER_PREFIX/) {
            my $k = lc($key);
            $buf .= "$key:$interesting_headers{$key}\n";
        } else {
            
            $buf .="$interesting_headers{$key}\n";
        }
    }
    $path =~ /^([^?]*)/;
    $buf .= "/$1";
    
    return $buf;
    
}

sub _validate_acl_short {
    my ($self, $policy_name) = @_;
    
    if (!grep({$policy_name eq $_}
    qw(private public-read public-read-write )))
    {
        croak "$policy_name is not a supported canned access policy";
    }
}

sub _trim {
    my ($self, $value) = @_;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    return $value;
}

sub _merge_meta {
    my ($self, $headers) = @_;
    $headers ||= {};
    
    my $http_header = HTTP::Headers->new;
    
    while ( my ($k, $v) = each %$headers ) {
        $http_header->header($k => $v);
    }

    return $http_header;
}

sub _urlencode {
      my ($self, $unencoded) = @_;
      return uri_escape_utf8($unencoded, '^A-Za-z0-9_-');
}
1;

__END__

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

