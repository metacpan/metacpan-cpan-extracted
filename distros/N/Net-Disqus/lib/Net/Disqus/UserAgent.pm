use strict;
use warnings;
package Net::Disqus::UserAgent;
BEGIN {
  $Net::Disqus::UserAgent::VERSION = '1.19';
}
use Net::Disqus::Exception;
use Try::Tiny;

sub new {
    my $pkg = shift;
    my %args = (
        pass_content_as_is  => 0,
        forcelwp            => 0,
        @_,
        ua_class            => 'LWP::UserAgent',
        ua_key              => 'lwp',
    );

    $args{agent} ||= "Net::Disqus/$Net::Disqus::VERSION";
    if(!$args{'forcelwp'}) {
        eval 'use Mojo::UserAgent; use Mojo::JSON; use Mojo::URL';
        unless($@) {
            $args{'ua_class'} = 'Mojo::UserAgent';
            $args{'name'} = delete($args{'agent'});
            $args{'ua_key'} = 'mojo';
        }  else {
            eval 'use LWP::UserAgent; use JSON::PP; use URI; use URI::Escape;';
            die Net::Disqus::Exception->new({code => 500, text => 'Something really funny is going on, cannot find one of LWP::UserAgent, JSON::PP, URI, URI::Escape'}) if($@);
        }
    } else {
        eval 'use LWP::UserAgent; use JSON::PP; use URI; use URI::Escape;';
        die Net::Disqus::Exception->new({code => 500, text => 'Something really funny is going on, cannot find one of LWP::UserAgent, JSON::PP, URI, URI::Escape'}) if($@);
    }
    my $self = bless({%args}, $pkg);
    delete($args{$_}) for(qw(pass_content_as_is forcelwp ua_class ua_key)); # and this is for LWP who doesn't like being passed unknown options
    $self->{'ua'} = $self->{'ua_class'}->new(%args);
    return $self;
}

sub ua { return shift->{ua} }
sub ua_key { return shift->{ua_key} }
sub ua_class { return shift->{ua_class} }
sub pass_content_as_is { return shift->{pass_content_as_is} }

sub request { 
    my $self = shift; 
    my $method = shift; 
    my $f = "tx_" . $self->ua_key; 
    return $self->$f($method, @_);
};

sub tx_mojo {
    my $self = shift;
    my $method = shift;
    my $url = shift;
    my %args = (@_);
    my $rate = {};

    my $uri = Mojo::URL->new(
        ($method eq 'get') 
            ?  sprintf('%s?%s', $url, join('&', map { sprintf('%s=%s', $_, $args{$_}) } (keys(%args))))
            : $url
        );
    my $f = ($method eq 'get') 
        ? 'get' 
        : 'post_form';
    my @fa = ($uri);
    push(@fa, { %args }) if($method eq 'post');

    my $res = $self->ua->$f(@fa)->res;
    die Net::Disqus::Exception->new({ code => 500, text => 'Did not receive a JSON response'}) if( 
        ($res->headers->content_type && $res->headers->content_type ne 'application/json') && 
        !$self->pass_content_as_is
        );

    $rate->{$_} = $res->headers->to_hash->{$_} || 0 for(qw(X-Ratelimit-Remaining X-Ratelimit-Limit X-Ratelimit-Reset));
    my @ret = (
        ($self->pass_content_as_is) ? $res->body : $res->json, 
        $rate
    );
    return @ret;
}

sub json_decode {
    my $self = shift;
    my $str  = shift;

    return ($self->ua_key eq 'mojo') 
        ? Mojo::JSON->decode($str)
        : JSON::PP::decode_json($str);
}

sub tx_lwp {
    my $self = shift;
    my $method = shift;
    my $url  = shift;
    my %args = (@_);
    my $rate = {};

    my $uri = URI->new($url);
    my $query_args = join('&', map { sprintf('%s=%s', $_, uri_escape($args{$_})) } (keys(%args)));
    $uri->query($query_args) if($method eq 'get');

    my $request = HTTP::Request->new(uc($method), $uri);
    $request->content($query_args) if($method eq 'post');
    my $res = $self->ua->request($request);
    die Net::Disqus::Exception->new({ code => 500, text => 'Did not receive a JSON response'}) if($res->header('Content-Type') ne 'application/json' && !$self->pass_content_as_is);
    my $json;
    if($self->pass_content_as_is) {
        $json = $res->content;
    } else {
        try {
            $json = JSON::PP::decode_json($res->content);
        } catch {
            die Net::Disqus::Exception->new({ code => 500, text => "Failed JSON decoding: $_"});
        };
    }
    $rate->{$_} = $res->header($_) || 0 for(qw(X-Ratelimit-Remaining X-Ratelimit-Limit X-Ratelimit-Reset));
    return ($json, $rate);
}

1;

__END__
=head1 NAME

Net::Disqus::UserAgent - Wrapper around LWP::UserAgent or Mojo::UserAgent

=head1 VERSION

version 1.19

=head1 SYNOPSIS
    
    # Do not use this module directly, it's full of little internal tidbits for
    # Net::Disqus, this is just here as an example

    use Net::Disqus::UserAgent
    my $ua = Net::Disqus::UserAgent->new(%options);

=head1 OBJECT METHODS

=head2 new(%options)
    
Creates a new Net::Disqus::UserAgent object. This is usually done by L<Net::Disqus>, but the options below are valid to pass to the 'ua_args' option in the constructor for L<Net::Disqus>.

    forcelwp            (optional)  When set to a true value, will always use LWP::UserAgent even if Mojo::UserAgent is available
    pass_content_as_is  (optional)  When set, will not check to see whether a JSON response was returned, and will not attempt any decoding, but will return content as-is.

=head1 USER AGENT AUTO DETECTION

If you don't force LWP, Net::Disqus::UserAgent will try in order:

    Mojo::UserAgent
    LWP::UserAgent

LWP::UserAgent is a requirement for Net::Disqus to be installed, so at the very least you will always have that. This behaviour was introduced for the L<Mojolicious::Plugin::Disqus> plugin, to make sure that we always use the best user agent for a given job.

=head1 AUTHOR

Ben van Staveren, C<< <madcat at cpan.org> >>

=head1 SEE ALSO

L<Net::Disqus>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Ben van Staveren.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut