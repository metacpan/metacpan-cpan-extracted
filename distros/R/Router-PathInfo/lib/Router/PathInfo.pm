package Router::PathInfo;
use strict;
use warnings;

our $VERSION = '0.05';

use namespace::autoclean;
use Carp;

use Router::PathInfo::Controller;
use Router::PathInfo::Static;

=head1 NAME

B<Router::PathInfo> - PATH_INFO router, based on search trees

=head1 DESCRIPTION

Allows balancing PATH_INFO to static and controllers.
It has a simple and intuitive interface.

=head1 WARNING

Version less than 0.05 is depricated.

=head1 SYNOPSIS

    use Router::PathInfo;
    
    # or
    use Router::PathInfo as => singletone;
    # this allow to call after new: instance, clear_singleton
    
    my $r = Router::PathInfo->new( 
        static => {
            allready => {
                path => '/path/to/static',
                first_uri_segment => 'static'
            }
        },
        cache_limit => 300
    );
    
    $r->add_rule(
        connect         => '/foo/:enum(bar|baz)/:name(year):re(^\d{4}$)/:any', 
        action          => $some_thing,
        mthods          => ['GET','DELETE'],
        match_callback  => $code_ref
    );
    
    my $env = {PATH_INFO => '/foo/bar/2011/baz', REQUEST_METHOD => 'GET'};
    
    my $res = $r->match($env);
    # or
    my $res = $r->match('/foo/bar/2011/baz'); # GET by default
    
    # $res = {
    #     type => 'controller',
    #     action => $some, # result call $code_ref->($match, $env)
    #     name_segments => {'year' => 2011}
    # }
    
    
    $env = {PATH_INFO => '/static/img/some.jpg'};
    
    $res = $r->match($env);
    
    # $res = {
    #     type  => 'static',
    #     file  => '/path/to/static/img/some.jpg',
    #     mime  => 'image/jpeg'
    # }    

See more details L<Router::PathInfo::Controller>, L<Router::PathInfo::Static>

=head1 PACKAGE VARIABLES

=head2 $Router::PathInfo::as_singleton

Mode as singletone. By default - 0.
You can pick up directly, or:

    use Router::PathInfo as => singletone;
    # or
    require Router::PathInfo;
    Router::PathInfo->import(as => singletone);
    # or
    $Router::PathInfo::as_singleton = 1
    
If you decide to work in singletone mode, raise the flag before the call to C<new>. 

=cut

my $as_singletone = 0;

sub import {
    my ($class, %param) = @_;
    $as_singletone = 1 if ($param{as} and $param{as} eq 'singletone');
    return;
}

=head1 SINGLETON

When you work in a mode singletone, you have access to methods: C<instance> and C<clear_singleton>

=cut


=head1 METHODS

=head2 new(static => $static, cache_limit => $cache_limit)

Constructor. All arguments optsioanlny.

static - it hashref arguments for the constructor L<Router::PathInfo::Static>

cache_limit - limit of matches stored by the rules contain tokens C<:re> and C<:any>, statics and errors. By default - 200.
All matches (that occur on an accurate description) cached without limit.

=cut

my $singleton = undef;

sub new {
    return $singleton if ($as_singletone and $singleton);
    
    my $class = shift;
    my $param = {@_};
    
    my $self = bless {
        static      => UNIVERSAL::isa($param->{static}, 'HASH')     ? Router::PathInfo::Static->new(%{delete $param->{static}}) : undef,
        controller  => UNIVERSAL::isa($param->{controller}, 'HASH') ? Router::PathInfo::Controller->new(%{delete $param->{controller}}) : Router::PathInfo::Controller->new(),
        cache                   => {},
        _hidden_cache           => {},
        cache_limit             => (defined $param->{cache_limit} and $param->{cache_limit}) =~ /^\d+$/ ? $param->{cache_limit} : 200,
        cache_cnt               => 0
    }, $class;
    
    $singleton = $self if $as_singletone;
     
    return $self;
}

=head2 add_rule

See C<add_rule> from L<Router::PathInfo::Controller>

=cut
sub add_rule {
    my $self = shift;
    my $ret = 0;
    if ($self->{controller}) {
        $self->{cache_cnt}  = 0;
        $self->{cache}      = {};
        $self->{controller}->add_rule(@_);
    } else {
        carp "controller not defined";
    }
}

sub instance        {$as_singletone ? $singleton : carp "singletone not allowed"}
sub clear_singleton {undef $singleton}

=head2 match({PATH_INFO => $path_info, REQUEST_METHOD => $method})

Search match. Initially checked for matches on static, then according to the rules of the controllers.
In any event returns hashref coincidence or an error.

Example:

    {
      type  => 'error',
      code => 400,
      desc  => '$env->{PATH_INFO} not defined'  
    }
    
    {
      type  => 'error',
      code => 404,
      desc  => sprintf('not found for PATH_INFO = %s with REQUEST_METHOD = %s', $env->{PATH_INFO}, $env->{REQUEST_METHOD}) 
    }
    
    {
        type => 'controller',
        action => $action,
        name_segments => $hashref_of_names_segments 
    }
    
    {
        type  => 'static',
        file  => $serch_file,
        mime  => $mime_type
    }

=cut
sub match {
    my $self = shift; 
    my $env  = shift;
    
    unless (ref $env) {
        $env = {PATH_INFO => $env, REQUEST_METHOD => 'GET'};
    } else {
        $env->{REQUEST_METHOD} ||= 'GET';
    }
    
    my $match = undef;
    
    $match = {
      type  => 'error',
      code => 400,
      desc  => '$env->{PATH_INFO} not defined'  
    } unless $env->{PATH_INFO};
    
    # find in cache
    my $cache_key = join('#',$env->{PATH_INFO}, $env->{REQUEST_METHOD});
    my $cache_match = $self->{cache}->{$cache_key} || $self->{_hidden_cache}->{$cache_key};
    if ($cache_match) {
        # only for controller
        $cache_match = $cache_match->{_callback}->({%$cache_match},$env) if exists $cache_match->{_callback};
        return $cache_match;
    };
    
    my @segment = split '/', $env->{PATH_INFO}, -1; shift @segment;
    $env->{'psgix.tmp.RouterPathInfo'} = {
        segments => [@segment],
        depth => scalar @segment 
    };
    
    # check in static
    if (not $match and $self->{static}) {
        $match = $self->{static}->match($env);
    }
    
    # check in controllers
    # $not_exactly - match with regexp
    my $not_exactly = 0;
    if (not $match and $self->{controller}) {
        ($not_exactly, $match) = $self->{controller}->match($env);
    }
    
    # not found?
    $match ||= {
      type  => 'error',
      code => 404,
      desc  => sprintf('not found for PATH_INFO = %s with REQUEST_METHOD = %s', $env->{PATH_INFO}, $env->{REQUEST_METHOD}) 
    };
    
    delete $env->{'psgix.tmp.RouterPathInfo'};
    
    # cache!
    if (not $not_exactly and $match->{type} eq 'controller') {
        $self->{_hidden_cache}->{$cache_key} = $match;
    } elsif ($self->{cache_limit}) {
        if ($self->{cache_cnt} > $self->{cache_limit}) {
            $self->{cache_cnt} = 0;
            $self->{cache} = {};
        } else {
            $self->{cache_cnt}++;
        }
        $self->{cache}->{$cache_key} = $match;        
    }
    
    # only for controller    
    $match = $match->{_callback}->({%$match},$env) if exists $match->{_callback};
    
    # match is done
    return $match;
}

=head1 SOURSE

git@github.com:mrRico/p5-Router-Path-Info.git

=head1 SEE ALSO

L<Router::PathInfo::Static>, L<Router::PathInfo::Controller>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut
1;
__END__
