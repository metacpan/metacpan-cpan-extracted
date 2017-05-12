
use strict;
use warnings;
package Net::IMP::HTTP::Example::SaveResponse;
use base 'Net::IMP::HTTP::Request';
use fields qw(root file);

use Net::IMP;
use Net::IMP::Debug;
use File::Path 'make_path';
use File::Temp 'tempfile';
use Digest::MD5;
use Carp;
use Scalar::Util 'looks_like_number';
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

my $DEFAULT_LIMIT = 10_000_000;

sub RTYPES { (IMP_PREPASS) }

sub new_factory {
    my ($class,%args) = @_;
    my $dir = $args{root} or croak("no root directory given");
    -d $dir && -r _ && -x _ or croak("cannot use base dir $dir: $!");
    $args{limit} = $DEFAULT_LIMIT if ! defined $args{limit};
    return $class->SUPER::new_factory(%args);
}

sub new_analyzer {
    my ($factory,%args) = @_;
    my $self = $factory->SUPER::new_analyzer(%args);
    # we don't modify
    $self->run_callback(
	[ IMP_PREPASS,0,IMP_MAXOFFSET ],
	[ IMP_PREPASS,1,IMP_MAXOFFSET ]
    );
    return $self;
}


sub DESTROY {
    my $self = shift;
    $self->{file} && $self->{file}{tname} && unlink($self->{file}{tname});
}

sub request_hdr {
    my ($self,$hdr) = @_;

    my ($method,$proto,$host,$path) = $hdr =~m{\A([A-Z]+) +(?:(\w+)://([^/]+))?(\S+)};
    $host = $1 if $hdr =~m{\nHost: *(\S+)}i;
    $host or goto IGNORE;
    $proto ||= 'http';
    $host = lc($host);
    my $port = 
	$host=~s{^(?:\[(\w._\-:)+\]|(\w._\-))(?::(\d+))?$}{ $1 || $2 }e ? 
	$3:80;

    if ( my $rx = $self->{factory_args}{only_url} ) {
	goto IGNORE if "$proto://$host:$port$path" !~ $rx
	    and "$proto://$host$path" !~ $rx
    }
    if ( my $rx = $self->{factory_args}{exclude_url} ) {
	goto IGNORE if "$proto://$host:$port$path" =~ $rx
	    or "$proto://$host$path" =~ $rx
    }
    if ( my $srh = $self->{factory_args}{method} ) {
	goto IGNORE if ! _check_srh($srh,$method);
    }
    

    my $dir = $self->{factory_args}{root}."/$host:$port";
    if ( ! -d $dir ) {
	my $err;
	make_path($dir, { error => \$err  });
    }
    my ($fh,$fname) = tempfile( "tmpXXXXXXX", DIR => $dir )
	or goto IGNORE;

    $hdr =~s{^(Content-encoding:|Transfer-encoding:|Content-length:)}{X-Original-$1}mig;
    print $fh $hdr;

    my $qstring = $path =~s{\?(.+)}{} ? $1 : undef;
    $self->{file} = {
	tfh => $fh,
	tname => $fname,
	dir => $dir,
	method => $method,
	md5path => Digest::MD5->new->add($path)->hexdigest,
	md5data => undef,
	size => [ length($hdr),0,0,0 ],
	rphdr => '',
	rpbody => '',
	eof => 0,
    };
    ( $self->{file}{md5data} = Digest::MD5->new )->add("\000$qstring\001")
	if defined $qstring and ! $self->{factory_args}{ignore_parameters};
    return; # continue in request body

    IGNORE:
    # pass thru w/o saving
    debug("no save $host:$port/$path");
    $self->run_callback( 
	# pass thru everything 
	[ IMP_PASS,0,IMP_MAXOFFSET ], 
	[ IMP_PASS,1,IMP_MAXOFFSET ], 
    );
}

sub request_body {
    my ($self,$data) = @_;
    my $f = $self->{file} or return;
    print { $f->{tfh} } $data;
    my $md = $f->{md5data};
    if ( $data ne '' ) {
	$f->{size}[1] += length($data);
	if ( my $l = $self->{factory_args}{limit} ) {
	    return _stop_saving($self) if $f->{size}[1] > $l;
	}
	if ( ! $md ) {
	    return if $self->{factory_args}{ignore_parameters};
	    $md = $f->{md5data} = Digest::MD5->new;
	}
	$md->add($data);
	return;
    }
    if ( defined( my $rp = $f->{rphdr} )) {
	print { $f->{tfh} } $rp;
	$f->{rphdr} = undef;
	if ( defined( $rp = $f->{rpbody} )) {
	    print { $f->{tfh} } $rp;
	    $f->{rpbody} = undef;
	}
    }
    _check_eof($self,1);
}

sub response_hdr {
    my ($self,$hdr) = @_;
    my $f = $self->{file} or return;
    return _stop_saving($self) if $hdr =~m{\AHTTP/1\.[01] (100|304|5\d\d)};
    if ( my $srh = $self->{factory_args}{content_type} ) {
	my ($ct) = $hdr =~m{^Content-type:\s*([^\s;]+)}mi;
	$ct ||= 'application/octet-stream';
	return _stop_saving($self) if ! _check_srh( $srh, lc($ct));
    }
    $hdr =~s{^(Content-encoding:|Transfer-encoding:|Content-length:)}{X-Original-$1}mig;
    $f->{size}[2] = length($hdr);
    if ( defined $f->{rphdr} ) {
	# defer, request body not fully read
	$f->{rphdr} = $hdr;
    } else {
	print {$f->{tfh}} $hdr;
    }
}

sub response_body {
    my ($self,$data) = @_;
    my $f = $self->{file} or return;
    $f->{size}[3] += length($data);
    if ( my $l = $self->{factory_args}{limit} ) {
	return _stop_saving($self) if $f->{size}[3] > $l;
    }
    if ( $data eq '' ) {
	_check_eof($self,2)
    } elsif ( defined $f->{rpbody} ) {
	$f->{rpbody} .= $data;
    } else {
	print {$f->{tfh}} $data;
    }
}

sub _check_eof {
    my ($self,$bit) = @_;
    my $f = $self->{file} or return;
    ( $f->{eof} |= $bit ) == 3 or return;
    $self->{file} = undef;
    print {$f->{tfh}} pack("NNNN",@{ $f->{size} });
    close($f->{tfh});
    my $fname = "$f->{dir}/".join( "-",
	lc($f->{method}),
	$f->{md5path},
	$f->{md5data} ? ($f->{md5data}->hexdigest):()
    );
    rename($f->{tname}, $fname);
}

# will not be tracked
sub any_data {
    my $self = shift;
    my $f = $self->{file} or return;
    unlink($f->{tname});
    $self->{file} = undef;
}

### config stuff ######
sub validate_cfg {
    my ($class,%cfg) = @_;
    my $dir = delete $cfg{root};
    my @err;
    push @err, "no or non-existing root dir given" 
	if ! defined $dir or ! -d $dir;
    if ( my $limit = delete $cfg{limit} ) {
	push @err, "limit should be number" if ! looks_like_number($limit)
    }
    for my $k (qw(content_type method)) {
	my $v = delete $cfg{$k} // next;
	push @err,"$k should be string, hash or regexp" if 
	    ref($v) and not ref($v) ~~ [ 'Regexp','HASH' ];
    }
    for my $k (qw(exclude_url only_url)) {
	my $v = delete $cfg{$k} // next;
	push @err,"$k should be regexp" if ref($v) ne 'Regexp';
    }
    delete $cfg{ignore_parameters};

    push @err, $class->SUPER::validate_cfg(%cfg);
    return @err;
}

sub str2cfg {
    my $self = shift;
    my %cfg = $self->SUPER::str2cfg(@_);
    for my $k (qw(content_type method)) {
	my $v = $cfg{$k} // next;
	if ( $v =~m{^/(.*)/$}s ) {
	    $cfg{$k} = eval { qr/$1/ } or croak("invalid regexp '$v': $@");
	} elsif (( my @v = split( /,/,$v )) > 1 ) {
	    $cfg{$k} = map { lc($_) => 1 } @v 
	} else {
	    $cfg{$k} = lc($v)
	}
    }
    for my $k (qw(exclude_url only_url)) {
	my $v = $cfg{$k} // next;
	$v =~m{^/(.*)/$}s or croak("$k should be /regex/");
	$cfg{$k} = eval { qr/$1/ } or croak("invalid regexp '$v': $@");
    }
    return %cfg;
}

sub _check_srh {
    my ($srh,$v) = @_;
    return $v =~ $srh if ref($srh) eq 'Regexp';
    return $srh->{$_} if ref($srh) eq 'HASH';
    return $srh eq $v;
}

sub _stop_saving {
    my $self = shift;
    my $f = $self->{file} or return;
    unlink($f->{tname});
    $self->{file} = undef;
    $self->run_callback(
	[ IMP_PASS,0,IMP_MAXOFFSET ],
	[ IMP_PASS,1,IMP_MAXOFFSET ],
    );
}


1;

__END__

=head1 NAME 

Net::IMP::HTTP::Example::SaveResponse - save response data to file system

=head1 SYNOPSIS

  # use App::HTTP_Proxy_IMP to listen on 127.0.0.1:8000 and save all data 
  # in myroot/
  $ perl bin/imp_http_proxy --filter Example::SaveResponse=root=myroot 127.0.0.1:8000


=head1 DESCRIPTION

This module is used to save response data into the file system.

The module has the following arguments for C<new_analyzer>:

=over 4

=item root

The base directory for saving the data. This argument is required.

=item content_type

Limits saving of the response body the given content_types, either hash,
string or regular expression.
If not given everything can be saved.

=item method

Limits saving to the given methods, either hash, string or regular
expression.
If not given everything can be saved.

=item limit

No data will be saved, if the request or response body size is greater then
the given limit.
If not given a default of 10_000_000 will be assumed. 
For unlimited saving this can be set to 0.

=item ignore_parameters

If set the contents of the query string or the post data will not be used in
creating the file name.

=item exclude_url

This regular expression describes, which URLs will not be saved.
E.g. setting it to /\?/ causes no URLs with a query string to be saved.
If not given everything can be saved.

=item only_url

If given, this regular expression limits saving to matching URLs.
If not given everything can be saved.

=back

The module has a single argument C<root> for C<new_analyzer>. 
C<root> specifies the base directory, where the data get saved.
The data are saved into a file C<root/host:port/method-md5path-md5data>, where

=over 4

=item * method is the HTTP method, lower cased

=item * md5path is the md5 hash of the path, e.g. excluding query string

=item * md5data is the md5 hash over query string joined with post data

=back

The contents of the saved file consists of the HTTP request header and body,
followed by the response header and body.
Chunking and content-encoding is removed from the body..
To speedup extraction of each of these 4 parts from the file an index of 16
byte is added at the end of the file consisisting of 4 32bit unsigned
integers in network byte order, describing the size of each part.

=head1 AUTHOR

Steffen Ullrich <sullr@cpan.org>
