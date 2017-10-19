package Plack::App::URLMux;

use strict;
use 5.008_001;
our $VERSION = '0.05';

use parent qw(Plack::Component);
use Carp qw(croak);

use constant MAX_FINE        => 65535; # if URL will contain url-path segments more than this number - increment it :)

# map[] structure constants
use constant _keys           => 0; # hash of url-path segments => map[]
use constant _level          => 1; # level of map tree
use constant _quant          => 2; # rule for quantifier at branch, this value sensitive for _named array
use constant _app            => 3; # reference to app on this leaf, undefined if does not mounted any
use constant _named          => 4; # reference to map[], if url-path has named parameter then mapping searching in it
use constant _names          => 5; # array of [parameter, index], if app has parameters in the url format
use constant _params         => 6; # array of pairs name=>value of input parameters specified at map
use constant _quants         => 7; # array of quantifiers of each url-path segments for mounted app

# _quant array constants
use constant _quant_n        => 0; # start range quanifier
use constant _quant_m        => 1; # end range qunatifier, -1 unknown maximum as possible
use constant _quant_r        => 2; # rest of posible search path, -1 unknown, unusefull, FIXME delete this
use constant _quant_h        => 3; # greedy/lazy flag for search path and gather subpathes for parameter, 0 lazy, 1 greedy

# _params array constants
use constant _param_name     => 0;
use constant _param_index    => 1;

# matched array constants
use constant _match_map      => 0;
use constant _match_length   => 1;
use constant _match_fine     => 2;
use constant _match_matching => 3;

# matching array constants
use constant _matching_index => 0;
use constant _matching_fine  => 1;

sub mount { shift->map(@_) }

sub map {
    my $self     = shift;
    my $location = shift;
    my $app      = shift;
    my $input_params = \@_;


    if ($location eq '') {
        croak "location 'not found' has already mount app"
            if exists $self->{_mapping_not_found} and defined $self->{_mapping_not_found};
        $self->{_mapping_not_found} = $app;
        return;
    }

    my $host = '*';  #any host
    if ($location =~ m/^https?:\/\/(.*?)(\/.*)/o) {
        $host     = $1;
        $location = $2;
    }

    croak "Path '$location' need to start with '/'"
        unless $location =~ m/^\//o;
    $location =~ s/^\/|\/$//go;

    my @paths = split('/', $location);

    my ($index, $params, $quants, $quant) = (0, [], [], undef);
    my $map = $self->{_mapping}->{$host} ||= [{}, $index, [1, 0]];  # Zero mapping for URL '/'
    $index++;
    foreach my $path (@paths) {
        my $r = @paths - $index;

        if ($path =~
            /^
                \:

                ([^\:\+\*\?\{\}\,]+?)       (?# 1: name of parameter )

                (?:
                      (?:
                            (\+|\*|\?)      (?# 2: '+|*|?' quantifier )
                            (\??)           (?# 3: '?' greedy|lazy flag )
                      )
                    | (?:
                            \{
                                (\d+)       (?# 4: start range quantifier )
                                (?:
                                    (\,)    (?# 5: range delimeter )
                                    (\d+)*  (?# 6: end range quantifier )
                                )*
                            \}
                            (\??)           (?# 7: '?' greedy|lazy flag )
                      )
                )?

            $/xo
        ){
            my ($name, $quant, $n, $m, $h) = ($1, $2 || $5, $4, $6, (($3 || $7) ? 0 : 1));

            ($n, $m) = (0, -1                  ) if $quant eq '*';
            ($n, $m) = (1, -1                  ) if $quant eq '+';
            ($n, $m) = (0,  1                  ) if $quant eq '?';
            ($n, $m) = ($n, ($m ? $m : -1)     ) if $quant eq ',';
            ($n, $m) = ($n = ($n ? $n : 1), $n ) if $quant eq '';

            #check _named now named must be array but we must check
            push(@$params, [$name, $index]);
            push(@$quants, [$n, $m, $r, $h]);

            $map->[_named] ||= {};
            $map = $map->[_named]->{"$n.$m"} ||= [{}, $index, [$n, $m]];
            $index++;
            next;
        }

        if ($path =~ /^\:/o) {
            croak "url '$location' is wrong, syntax sub path '$path' is incorrent, expect :[alphanum](*|+|?|{n,m})?\??";
        }

        #FIXME check than name contain only valid chars need check RFC for that

        $map = $map->[_keys]->{$path} ||= [{}, $index, [1, 1]];
        push(@$quants, [1, 1, $r, 1]);
        $index++;
        next;

    }

    croak "/$location has already mount app"
        if defined $map->[_app];

    @$map[_app,_params,_names,_quants] = ($app, $input_params, @$params ? $params : undef, $quants);

}

sub _parse_quant {

}

sub prepapre_app {
    my $self = shift;
}

sub call {
    my ($self, $env) = @_;
    my ($matches, $params);

    my($http_host, $server_name, $script_name, $path_info)
        = @{$env}{qw( HTTP_HOST SERVER_NAME SCRIPT_NAME PATH_INFO )};

    #FIXME possible BUG
    # is there cases when port is not the same in HTTP_HOST and SERVER_PORT?
    if ($http_host and $env->{SERVER_PORT}) {
        $http_host =~ s/:\d+$//o;
    }

    my @path = split('/', $path_info);
    shift @path; # remove zero

    my $mapping = $self->{_mapping};

    my $matched =
        _matched(
            $self->search(
                  $mapping->{$http_host} || $mapping->{$server_name} || $mapping->{'*'}
                , my $i = 0
                , \@path
                , @path + 0
                , []
            )
        );

    unless ($matched) {
        return [404, [ 'Content-Type' => 'text/plain' ], [ "Not Found" ]]
            unless $self->{_mapping_not_found};
        return $self->{_mapping_not_found}->($env);
    }

    #now we have first matched rule and match path, we need fill params if they exists

    my ($match, $matching) = @{$matched}[_match_map,_match_matching];

    if (defined $match->[_names]) {
        my ($i, $j);
        $params = [
            map {
                $_->[_param_name] =>
                    (
                            (
                                    ($j = $matching->[$_->[_param_index]-1]->[_matching_index] - 1)
                                -
                                    ($i = $_->[_param_index] - 1 > 0 ? $matching->[$_->[_param_index] - 2]->[_matching_index] : 0)
                            ) >= 0
                        ?
                            [(@path[$i..$j])]
                        :
                            []
                    )
            } @{$match->[_names]}
        ];
    }

    my $index = $matching->[-1]->[_matching_index];
    #clone input params, couse they may be mutated by middlewire
    @$env{qw( plack.urlmux.params.map plack.urlmux.params.url SCRIPT_NAME PATH_INFO )}
        = (
              [@{$match->[_params]}]
            , $params || []
            , ($script_name ? $script_name : $index ? '/' : '') . join('/', (@path[0..($index-1)]))
            , ($index == @path ? @path ? '' : '/' : '/') . join('/', (@path[$index..(@path-1)]))
        );

    return $self->response_cb($match->[_app]->($env), sub {
        @{$env}{qw( PATH_INFO SCRIPT_NAME )} = ($path_info, $script_name);
    });
}

sub search {
    my ($self, $map, $index, $parts, $l, $matching) = @_;

    my $path = $parts->[$index];
    my ($_app, $_keys, $_named) = @$map[_app,_keys,_named];

    my $matches = [];

    if (exists $_keys->{$path}) {
        if ($index < $l) {
            push(@$matches, (@{$self->search($_keys->{$path}, $index + 1, $parts, $l, [(@$matching), [$index+1, 0]])}));
        }
        else {
            if (defined $_keys->{$path}->[_app]) {
                my $match = [$_keys->{$path}, $index + 1, 0, [(@$matching), [$index+1, 0]]];
                push (@$matches, $match);
                map {$match->[_match_fine] += $_->[_matching_fine]} @{$match->[_match_matching]};
            }
        }
    }

    if (defined $_named) {
        foreach my $quant (values %{$_named}) {
            my ($n, $m) = @{$quant->[_quant]}[_quant_n,_quant_m];
            my ($ln, $lm) = ($index + $n, ($m==-1 ? MAX_FINE : $index + $m));
            my $matches_ = [];
            for ($ln .. ($lm > $l ? $l : $lm)) {
                if ($_ < $l) {
                    push(@$matches_ , (@{$self->search($quant, $_, $parts, $l, [(@$matching), [$_, $lm - $ln + 1]])}));
                }
                else {
                    if (defined $quant->[_app]) {
                        my $match = [$quant, $_, 0, [(@$matching), [$_, $lm - $ln + 1]]];
                        push(@$matches_, $match);
                        map {$match->[_match_fine] += $_->[_matching_fine]} @{$match->[_match_matching]};
                    }
                }
            }
            next unless @$matches_;
            push(@$matches, _matched_greedy($matches_, $index));
        }
    }

    if (defined $_app) {
        my $match = [$map, $index, 0, [(@$matching), [$index, 0]]];
        push(@$matches, $match);
        map {$match->[_match_fine] += $_->[_matching_fine]} @{$match->[_match_matching]};
    }

    return $matches;

}

sub _matched {
    my ($matches) = @_;

    return unless @$matches;
    return $matches->[0] if @$matches == 1;

    my $match;

    foreach (@$matches) {
        unless (defined $match) {
            $match = $_;
            next;
        }
        if ($_->[_match_length] < $match->[_match_length]) {
            next;
        }
        if ($_->[_match_length] > $match->[_match_length]) {
            $match = $_;
            next;
        }
        if ($_->[_match_fine] < $match->[_match_fine]) {
            $match = $_;
            next;
        }
    }
    return $match;
}

sub _matched_greedy {
    my ($matches, $index) = @_;

    return unless @$matches;
    return $matches->[0] if @$matches == 1;

    my $greedy = $matches->[0]->[_match_map]->[_quants]->[$index-1]->[_quant_h];

    my $match;
    foreach (@$matches) {
        unless (defined $match) {
            $match = $_;
            next;
        }
        if ($_->[_match_length] < $match->[_match_length]) {
            next;
        }
        if ($_->[_match_length] > $match->[_match_length] ) {
            $match = $_;
            next;
        }
        if ($greedy) {
            if ($_->[_match_matching]->[$index-1]->[_matching_index] > $match->[_match_matching]->[$index-1]->[_matching_index]) {
                $match = $_;
                next;
            }
        }
        else {
            if ($_->[_match_matching]->[$index-1]->[_matching_index] < $match->[_match_matching]->[$index-1]->[_matching_index]) {
                $match = $_;
                next;
            }
        }
    }

    return $match;
}

1;

__END__

=head1 NAME

Plack::App::URLMux - Map multiple applications in defferent url path.

=head1 SYNOPSYS

    use Plack::App::URLMux;

    my $app1 = sub { ... };
    my $app2 = sub { ... };
    my $app3 = sub { ... };

    my $urlmap = Plack::App::URLMux->new;
    $urlmap->map("/" => $app1, foo => bar);
    $urlmap->map("/foo/:name/bar" => $app2);
    $urlmap->map("/foo/test/bar"  => $app3);
    $urlmap->map("http://bar.example.com/" => $app4);
    $urlmap->map("/foo/:bar*/baz" => $app2);

    my $app = $urlmap->to_app;

=head1 DESCRIPTION

Plack::App::URLMux is a PSGI application that can dispatch multiple
applications based on URL path and host names (a.k.a "virtual hosting")
and takes care of rewriting C<SCRIPT_NAME> and C<PATH_INFO> (See
L</"HOW THIS WORKS"> for details). This module is based on
L<Plack::App::URLMap> module but optimizied to handle a lot of urls and
has additional rules for parameterized URL and add additional parameteres
provided to application at mapping URL.

Mapping rules for url with parameters /foo/:name/bar will mapped to any
URL wich contains /foo/some/bar and call $app2 with additional parameters
at environmentas name => 'some'. But if you mount /for/test/bar the same
time, then for this URL /for/test/bar mapping will be exactly to $app3
to this URL without parameter and other URLs contain anything between
/foo/ and /bar will be mapped to $app2 with parameter 'name'.

Format for parameters :name, parameter names may be repeated, mapper
returned values as array of pairs name=>value in order as they meet in
URL.


=head1 ENVIRONMENT

On call mapper provide next environment in request:

=over 2

=item plack.urlmux.params.map

Array of pairs key=>value specified when mount app

-item plack.urlmux.params.url

Array of pairs name=>value extracted from url path by url format
specified when mount app

=back

=head1 METHODS

=over 4

=item map

  $urlmap->map("/foo" => $app);
  $urlmap->map("http://bar.example.com/" => $another_app);
  $urlmap->map("/foo/:name/bar" => $app2);
  $urlmap->map('' => $app_not_found);

Maps URL an absolute URL to a PSGI application. Module splits url path by
'/' delimeter and add it into builded search tree structure.

URL paths need to match from the beginning and should match completely
until the path separator (or the end of the path). For example, if you
register the path C</foo>, it I<will> match with the request C</foo>,
C</foo/> or C</foo/bar> but it I<won't> match with C</foox>.

Mapping URLs with host names is also possible, and in that case the URL
mapping works like a virtual host.

Also possible handle 404 error by outer application that handles 'Not found'
event by mapping the application to an empty location.

=item mount

Alias for C<map>.

=item to_app

  my $handler = $urlmap->to_app;

Returns the PSGI application code reference.

=back

=head1 PERFORMANCE

No restriction on number of urls, of course perl has trouble to store 1M
records, it takes a lot of memory. Mounting hundreds of applications cause
a small affect on runtime request performance. Algorithm complexity is
near logN.

=head1 AUTHOR

Aleksey Ozhigov

=head1 SEE ALSO

L<Plack::App::URLMap>

=cut

