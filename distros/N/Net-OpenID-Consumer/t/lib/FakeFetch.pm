package FakeFetch;
# networkless URIFetch::fetch()
# SYNOPSIS
# 

use strict;
use warnings;

use vars qw/@EXPORT @ISA/;
@ISA = qw/Exporter/;
@EXPORT = qw(
    uri_scenario
    resetf
    addf_dead_h   
    addf_404_h    
    addf_500_h    
    addf_dead_uri 
    addf_404_uri  
    addf_500_uri  
    addf_dead_ure 
    addf_404_ure  
    addf_500_ure  
    addf_h
    addf_uri
    addf_ure
);

# copied from URIFetch::fetch
my @useful_headers = qw(last-modified etag content-type x-yadis-location x-xrds-location);

# list of { ure => regexp, final_uri => ..., code => 200, content => , [<hdr> => <string>,...]}
our @fetchables = ();
sub resetf { @fetchables = (); }
sub uri_scenario {
    my ($code) = @_;
    local @fetchables = ();
    $code->();
}
my @respond_dead = (code => '000');
my @respond_404  = (code => '404', content =>'Not Found -- random text');
my @respond_500  = (code => '500', content =>'Internal Error -- random text');
sub addf_dead_h   { addf_h(@respond_dead, @_); }
sub addf_404_h    { addf_h(@respond_404,  @_); }
sub addf_500_h    { addf_h(@respond_500,  @_); }
sub addf_dead_uri { addf_uri(@respond_dead, @_); }
sub addf_404_uri  { addf_uri(@respond_404,  @_); }
sub addf_500_uri  { addf_uri(@respond_500,  @_); }
sub addf_dead_ure { addf_ure(@respond_dead, @_); }
sub addf_404_ure  { addf_ure(@respond_404,  @_); }
sub addf_500_ure  { addf_ure(@respond_500,  @_); }

sub addf_h {
    my (%bad) = @_;
    my %h = map {exists $bad{$_} ? ($_,delete $bad{$_}) : ()} 
      @useful_headers, qw(uri ure final_uri code content);
    die 'unexpected params: '.join(',',keys %bad) if keys %bad;
    if ($h{uri}) {
	die 'uri and ure' if $h{ure};
	$h{ure} = qr/^$h{uri}$/;
	$h{final_uri} = $h{uri} unless $h{final_uri};
    }
    elsif (!$h{ure}) {
	die 'need uri or ure';
    }
    $h{code} = 200 unless $h{code};
    die 'weird code' unless $h{code} =~ m/^[02-5]\d\d$/;
    unless ($h{content}) {
	$h{content} = '';
    }
    unshift @fetchables, \%h;
}
sub addf_uri {
    my $uri = shift;
    addf_h(uri => $uri, @_);
}
sub addf_ure {
    my $ure = shift;
    addf_h(ure => $ure, @_);
}

our %fake_cache = ();

sub _my_fetch {
    my ($class, $uri, $consumer, $content_hook, $prefix) = @_;
    $prefix ||= '';
    # keep behavior of actual URI::Fetch->fetch()
    if ($uri eq 'x-xrds-location') {
        Carp::confess("Buh?");
    }

    my $cache_key = "URIFetch:${prefix}:${uri}";
    if (my $blob = $fake_cache{$cache_key}) {
        my $ref = Storable::thaw($blob);
        return Net::OpenID::URIFetch::Response->new(
            status => 200,
            content => $ref->{Content},
            headers => $ref->{Headers},
            final_uri => $ref->{FinalURI},
        );
    }


    # pretend to get $uri
    # $req = HTTP::Request->new(GET => $uri);
    # $res = $ua->request($req);
    # $content = $res->content;
    # $final_uri = $res->request->uri->as_string();
    foreach my $f (@fetchables) {
	next if $uri !~ $f->{ure};
	return if $f->{code} eq '000';

	my $content = $f->{content};
	if ($content_hook) {
	    $content_hook->(\$content);
	}

	my $headers = {};
	foreach my $k (@useful_headers) {
	    $headers->{$k} = $f->{$k};
	}

        my $final_uri = $f->{final_uri} || $uri;
        if ($f->{code} == 200) {
            my $cache_data = {
                Headers => $headers,
                Content => $content,
                FinalURI => $final_uri,
                CacheTime => time(),
            };
            my $cache_blob = Storable::freeze($cache_data);
            my $final_cache_key = "URIFetch:${prefix}:${final_uri}";
            $fake_cache{$final_cache_key} = $cache_blob;
            $fake_cache{$cache_key} = $cache_blob;
        }

	return Net::OpenID::URIFetch::Response->new
	  (
	   status => $f->{code},
	   final_uri => $final_uri,
	   content => $content,
	   headers => $headers,
	  );
    }
    diag("unexpected URI: $uri")
}
no warnings;
*Net::OpenID::URIFetch::fetch = \&_my_fetch;

1;
