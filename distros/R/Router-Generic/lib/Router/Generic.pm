
package Router::Generic;

use strict;
use warnings 'all';
use Carp 'confess';

our $VERSION = '0.021';

sub new
{
  my ($class, %args) = @_;
  
  my $s = bless {
    cache     => { },
    routes    => [ ],
    patterns  => { },
    names     => { },
    paths_methods  => { },
    %args
  }, $class;
  
  $s->init();
  
  return $s;
}# end new()

sub init { }


sub add_route
{
  my ($s, %args) = @_;
  
  # Set the method:
  $args{method} ||= '*';
  $args{method} = uc($args{method});
  
  my $uid = "$args{method} $args{path}";
  my $starUID = "* $args{path}";
  
  # Validate the args:
  confess "Required param 'path' was not provided."
    unless defined($args{path}) && length($args{path});
  
  confess "Required param 'target' was not provided."
    unless defined($args{target}) && length($args{target});
  
  confess "Required param 'name' was not provided."
    unless defined($args{name}) && length($args{name});
  
  confess "name '$args{name}' is already in use by '$s->{names}->{$args{name}}->{path}'."
    if exists($s->{names}->{$args{name}});
  
  confess "path '$args{method} $args{path}' conflicts with pre-existing path '$s->{paths_methods}->{$uid}->{method} $s->{paths_methods}->{$uid}->{path}'."
    if exists($s->{paths_methods}->{$uid});
  
  confess "name '* $args{name}' is already in use by '$s->{paths_methods}->{$starUID}->{method} $s->{paths_methods}->{$starUID}->{path}'."
    if exists($s->{paths_methods}->{$starUID});
  
  
  $args{defaults} ||= { };
  
  # Fixup our pattern:
  ($args{regexp}, $args{captures}, $args{uri_template}) = $s->_patternize( $args{path} );
  
  my $regUID = "$args{method} " . $args{regexp};
  
  if( my $exists = $s->{patterns}->{$regUID} )
  {
    confess "path '$args{path}' conflicts with pre-existing path '$exists'.";
  }# end if()
  
  push @{$s->{routes}}, \%args;
  $s->{patterns}->{$regUID} = $args{path};
  $s->{names}->{$args{name}} = $s->{routes}->[-1];
  $s->{paths_methods}->{$uid} = $s->{routes}->[-1];

  return 1;
}# end add_route()


sub replace_route
{
  my ($s, %args) = @_;
  
  $s->add_route( %args )
    unless eval { $s->uri_for($args{name}) };
  1;
}# end replace_route()


sub _patternize
{
  my ($s, $path) = @_;
  
  # For lack of real *actual* named captures:
  my @captures = ( );
  
  # Construct a regexp that can be used to select the matching route for any
  # given uri:
  my $regexp = do {
    (my $copy = $path) =~ s!
      \{(\w+\:(?:\{[0-9,]+\}|[^{}]+)+)\} | # /foo/{Page:\d+}
      :([^/\{\}\:\-]+)                   | # /foo/:title
      \{([^\}]+)\}                       | # /foo/{Bar} and /foo/{*WhateverElse}
      ([^/\{\}\:\-]+)                      # /foo/literal/
    !
      if( $1 )
      {
        my ($name, $pattern) = split /:/, $1;
        push @captures, $name;
        $pattern ? "($pattern)" : "([^/]*?)";
      }
      elsif( $2 )
      {
        push @captures, $2;
        "([^/]*?)";
      }
      elsif( $3 )
      {
        my $part = $3;
        if( $part =~ m/^\*/ )
        {
          $part =~ s/^\*//;
          push @captures, $part;
          "(.*?)";
        }
        else
        {
          push @captures, $part;
          "([^/]*?)";
        }# end if()
      }
      elsif( $4 )
      {
        quotemeta($4);
      }# end if()
    !sgxe;
    
    # Make the trailing '/' optional:
    unless( $copy =~ m{\/[^/]+\.[^/]+$} )
    {
      $copy .= '/' unless $copy =~ m/\/$/;
      $copy =~ s{\/$}{\/?};
    }# end unless()
    qr{^$copy$};
  };
  
  # This tokenized string becomes a template for the 'uri_for(...)' method:
  my $uri_template = do {
    (my $copy = $path) =~ s!
      \{(\w+\:(?:\{[0-9,]+\}|[^{}]+)+)\} | # /foo/{Page:\d+}
      :([^/\{\}\:\-]+)                   | # /foo/:title
      \{([^\}]+)\}                       | # /foo/{Bar} and /foo/{*WhateverElse}
      ([^/\{\}\:\-]+)                      # /foo/literal/
    !
      if( $1 )
      {
        my ($name, $pattern) = split /:/, $1;
        "[:$name:]";
      }
      elsif( $2 )
      {
        "[:$2:]";
      }
      elsif( $3 )
      {
        my $part = $3;
        if( $part =~ m/^\*/ )
        {
          $part =~ s/^\*//;
          "[:$part:]"
        }
        else
        {
          "[:$part:]"
        }# end if()
      }
      elsif( $4 )
      {
        $4;
      }# end if()
    !sgxe;
    
    unless( $copy =~ m{\/[^/]+\.[^/]+$} )
    {
      $copy .= '/' unless $copy =~ m/\/$/;
      $copy =~ s{\/$}{\/?};
      $copy =~ s/\?$//;
    }# end unless()

    $copy;
  };
  
  return ($regexp, \@captures, $uri_template);
}# end _patternize()


# $router->match('/products/all/4/');
sub match
{
  my ($s, $full_uri, $method) = @_;
  
  $method ||= '*';
  $method = uc($method);
  
  my ($uri, $querystring) = split /\?/, $full_uri;
  
  if( exists( $s->{cache}->{"$method $full_uri"} ) )
  {
    if( ref($s->{cache}->{"$method $full_uri"}) )
    {
      return wantarray ? @{ $s->{cache}->{"$method $full_uri"} } : $s->{cache}->{"$method $full_uri"};
    }
    else
    {
      return unless defined $s->{cache}->{"$method $full_uri"};
      return $s->{cache}->{"$method $full_uri"};
    }# end if()
  }# end if()
  
  foreach my $route ( grep { $method eq '*' || $_->{method} eq $method || $_->{method} eq '*' } @{$s->{routes}} )
  {
    if( my @captured = ($uri =~ $route->{regexp}) )
    {
      if( ref($route->{target}) eq 'ARRAY' )
      {
        $s->{cache}->{"$method $full_uri"} = [
          map {
            $s->_prepare_target( $route, $_, $querystring, @captured )
          } @{ $route->{target} }
        ];
        return wantarray ? @{ $s->{cache}->{"$method $full_uri"} } : $s->{cache}->{"$method $uri"};
      }
      else
      {
        return $s->{cache}->{"$method $full_uri"} = $s->_prepare_target( $route, "$route->{target}", $querystring, @captured );
      }# end if()
    }# end if()
  }# end foreach()
  
  $s->{cache}->{"$method $uri"} = undef;
  return;
}# end match()


sub _prepare_target
{
  my ($s, $route, $target, $querystring, @captured) = @_;

  $querystring = '' unless defined($querystring);
  no warnings 'uninitialized';
  my $values = {map { my ($k,$v) = split /\=/, $_; ($k => $v) } split /&/, $querystring};
  
  my %defaults = %{ $route->{defaults} };
  map {
    my $value = @captured ? shift(@captured) : $defaults{$_};
    $value =~ s/\/$//;
    $value = $defaults{$_} unless length($value);
    $values->{$_} = $value;
    delete($defaults{$_}) if exists $defaults{$_};
  } @{$route->{captures}};
  
  map { $target =~ s/\[\:\Q$_\E\:\]/$values->{$_}/g } keys %$values;

  my %skip = ( );
  my $form_params = join '&', grep { $_ } map {
    $skip{$_}++;
    urlencode($_) . '=' . urlencode($values->{$_})
      if defined($values->{$_});
  } grep { defined($values->{$_}) } sort {lc($a) cmp lc($b)} keys %$values;
  my $default_params = join '&', map {
    urlencode($_) . '=' . urlencode($defaults{$_})
      if defined($defaults{$_});
  } grep { defined($defaults{$_}) && ! $skip{$_} } sort {lc($a) cmp lc($b)} keys %defaults;
  my $params = join '&', ( grep { $_ } $form_params, $default_params );
  
  if( $target =~ m/\?/ )
  {
    return $target . ($params ? "&$params" : "" );
  }
  else
  {
    return $target . ($params ? "?$params" : "" );
  }# end if()
}# end _prepare_target()


# $router->uri_for('Zipcodes', { zip => 90210 }) # eg: /Zipcodes/90201/
sub uri_for
{
  my ($s, $name, $args) = @_;
  
  confess "Unknown route '$name'."
    unless my $route = $s->{names}->{$name};
  
  my $template = $route->{uri_template};
  map {
    $args->{$_} = $route->{defaults}->{$_}
      unless defined($args->{$_})
  } keys %{$route->{defaults}};
  my %used = ( );
  map {
    $template =~ s!
      \[\:$_\:\](\/?)
    !
      if( defined($args->{$_}) && length($args->{$_}) )
      {
        $used{$_}++;
        "$args->{$_}$1"
      }
      else
      {
        "";
      }# end if()
    !egx
  } @{ $route->{captures} };
  
  my $params = join '&', map { urlencode($_) . '=' . urlencode($args->{$_}) }
    grep { defined($args->{$_}) && length($args->{$_}) && ! $used{$_} }
      keys %$args;
  if( length($params) )
  {
    $template .= $template =~ m/\?/ ? "&$params" : "?$params";
  }# end if()
  
  return $template;
}# end uri_for()


sub route_for
{
  my ($s, $uri, $method) = @_;
  
  $method ||= '*';
  $method = uc($method);
  
  ($uri) = split /\?/, $uri
    or return;
  
  foreach my $route ( grep { $method eq '*' || $_->{method} eq $method || $_->{method} eq '*' } @{$s->{routes}} )
  {
    if( my @captured = ($uri =~ $route->{regexp}) )
    {
      return $route;
    }# end if()
  }# end foreach()
  
  return;
}# end route_for()


sub urlencode
{
  my $toencode = shift;
  no warnings 'uninitialized';
  $toencode =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/esg;
  $toencode;
}# end urlencode()


1;# return true:

=pod

=head1 NAME

Router::Generic - A general-purpose router for the web.

=head1 DEPRECATED

Do not use for new code.

=head1 SYNOPSIS

=head2 Constructor

  use Router::Generic;
  
  my $router = Router::Generic->new();
  
=head2 Simple Route

  $router->add_route(
    name      => 'Simple',
    path      => '/foo/bar',
    target    => '/foobar.asp',
  );
  
  $router->match('/foo/bar/');  # /foobar.asp

=head2 Simple Named Capture

  $router->add_route(
    name      => 'Zipcodes',
    path      => '/zipcodes/:code',
    target    => '/zipcode.asp'
  );
  
  $router->match('/zipcodes/90210/');  # /zipcode.asp?code=90210
  $router->match('/zipcodes/80104/');  # /zipcode.asp?code=80104
  $router->match('/zipcodes/00405/');  # /zipcode.asp?code=00405

=head2 Another way to spell the same thing

  $router->add_route(
    name      => 'Zipcodes',
    path      => '/zipcodes/{code}',
    target    => 'zipcode.asp'
  );

=head2 Eager Named Capture

  $router->add_route(
    name      => 'Eager',
    path      => '/stuff/{*Whatever}',
    target    => '/yay.asp',
  );
  
  $router->match('/stuff/blah/');     # /stuff/blah
  $router->match('/stuff/a/b/c');     # /yay.asp?Whatever=a%2Fb%2Fc - (a/b/c escaped)

=head2 Named Capture with RegExp

  $router->add_route(
    name      => 'ZipcodeRegexp',
    path      => '/zipcodesRegExp/{code:\d{5}}',
    target    => '/zipcode.asp'
  );
  
  $router->match('/zipcodesRegExp/90210/');   # /zipcode.asp?code=90210
  $router->match('/zipcodesRegExp/80104/');   # /zipcode.asp?code=80104
  $router->match('/zipcodesRegExp/00405/');   # /zipcode.asp?code=00405

=head2 More Interesting

  $router->add_route(
    name      => 'WikiPage',
    path      => '/:lang/:locale/{*Article}',
    target    => '/wiki.asp',
    defaults  => {
      Article => 'Home',
      lang    => 'en',
      locale  => 'us',
    }
  );
  
  $router->match('/en/us/');              # /wiki.asp?lang=en&locale=us&Article=Home
  $router->match('/fr/ca/');              # /wiki.asp?lang=fr&locale=ca&Article=Home
  $router->match('/en/us/Megalomania');   # /wiki.asp?lang=en&locale=us&Article=Megalomania

=head2 Route with Default Values

  $router->add_route({
    name      => 'IceCream',
    path      => '/ice-cream/:flavor',
    target    => '/dessert.asp',
    defaults  => {
      flavor  => 'chocolate'
    }
  });

=head2 Fairly Complex

  $router->add_route(
    name      => "ProductReviews",
    path      => '/shop/{Product}/reviews/{reviewPage:\d+}',
    target    => '/product-reviews.asp',
    defaults  => {
      reviewPage  => 1,
    }
  );
  
  $router->match('/shop/Ford-F-150/reviews/2/');  # /product-reviews.asp?Product=Ford-F-150&reviewPage=2

=head2 List of Targets

As of version 0.006 you can also pass an arrayref of targets and get them all back, parameterized just the same:

  $router->add_route(
    name      => "Bank",
    path      => '/banks/:city',
    target    => [ '/bank-[:city:].asp', '/bank-generic.asp' ],
    defaults  => {
      reviewPage  => 1,
    }
  );
  
  # Scalar context returns an arrayref when there are multiple targets:
  my $matches = $router->match('/banks/Dallas/');
  print $matches->[0];  # /bank-Dallas.asp?city=Dallas
  print $matches->[1];  # /bank-generic.asp?city=Dallas
  
  # List context returns a list:
  my @matches = $router->match('/banks/Dallas/');
  print $matches[0];    # /bank-Dallas.asp?city=Dallas
  print $matches[1];    # /bank-generic.asp?city=Dallas

B<*> This whole contextual-return-types thing started up in v0.007.

=head2 Get the URI for a Route

  my $uri = $router->uri_for('IceCream');
  print $uri;   # /ice-cream/chocolate/
  
  my $uri = $router->uri_for('/ProductReviews', {
    Product => 'Tissot-T-Sport',
    reviewPage  => 3,
  });
  print $uri;   # /shop/Tissot-T-Sport/reviews/3/
  
  my $uri = $router->uri_for('WikiPage', {
    Article => 'Self-aggrandizement',
    lang    => 'en',
    locale  => 'ca',
  });
  print $uri;   # /en/ca/Self-aggrandizement/
  
  my $uri = $router->uri_for('Zipcodes', {
    code => '12345'
  });
  print $uri;   # /zipcodes/12345/

=head2 Get the Route for a URI

  my $route = $router->route_for('/banks/Dallas/');
  
  my $route = $router->route_for('/banks/Dallas/', 'POST');
  
  my $route = $router->route_for('/banks/Dallas/', 'GET');

=head1 DESCRIPTION

C<Router::Generic> provides B<URL Routing> for the web.

=head2 What is URL Routing?

URL Routing is a way to connect the dots between a URL you see in your browser
and the page that the webserver should actually process.  You could also say that
URL Routing is a way to abstract the URL in the browser from the page that the
webserver should actually process.  It's all in your perspective.

URL Routing is valuable for search engine optimization (SEO) and for reducing 
work associated with moving files and folders around during the iterative process of building a website.

=head2 Anatomy of a Route

Every route must have a C<name>, a C<path> and a C<target>.  The C<defaults> hashref is optional.

=over 4

=item * name (Required)

The C<name> parameter should be something friendly that you can remember and reference later.

Examples are "Homepage" or "Products" or "SearchResults" - you get the picture.

=item * path (Required)

The C<path> parameter describes what the incoming URL will look like in the browser.

Examples are:

=over 8

=item C</hello/:who>

Matches C</hello/world/> and C</hello/kitty/>

Does B<not> match C</hello/every/one/>

=item C</colors/{Color}>

Matches C</colors/red/> and C</colors/not-really-a-color/>

Does B<not> match C</colors/red/white/blue/>

=item C</options/{*Options}>

Matches C</options/>, C</options/foo/> and C</options/foo/bar/baz/bux/>

=item C</areacodes/{Area:\d{3}}>

You can use regular expressions to restrict what your paths match.

Matches C</areacodes/303/> but does B<not> match C</areacodes/abc/>

=back

=item * target (Required)

The url that should be processed instead.  Any string is accepted as valid input.

So C</ice-cream.asp> and C</flavor.asp?yay=hooray> are OK.

=item * defaults (Optional)

The C<defaults> parameter is a hashref containing values to be used in place of
missing values from the path.

So if you have a path like C</pets/{*petName}> and your C<defaults> looks like this:

  $router->add_route(
    name    => 'Pets',
    path    => '/pets/{*petName}',
    target  => '/pet.asp',
    defaults => {
      petName => 'Spot',
    }
  );

You get this:

  $router->match('/pets/');   # /pet.asp?petName=Spot

And this:

  $router->uri_for('Pets');   # /pets/Spot/

The C<defaults> are overridden simply by supplying a value:

  $router->match('/pets/Fluffy/');  # /pet.asp?petName=Fluffy

And this:

  $router->uri_for('Pets', {petName => 'Sparky'});  # /pets/Sparky/

Similarly, if you have the following route:

  $router->add_route(
    name  => "DefaultsAlways",
    path  => "/",
    target  => "/index.asp",
    method  => "*",
    defaults  => {
      foo => "bar"
    }
  );

You get this:

  $router->uri_for("DefaultsAlways"); # /?foo=bar

  $router->match('/');  # /index.asp?foo=bar

=back

=head2 Caching

C<Router::Generic> provides route caching - so the expensive work of connecting a
uri to a route is only done once.

=head1 PUBLIC METHODS

=head2 add_route( name => $str, route => $str, [ defaults => \%hashref ] )

Adds the given "route" to the routing table.  Routes must be unique - so you can't
have 2 routes that both look like C</foo/:bar> for example.  An exception will
be thrown if an attempt is made to add a route that already exists.

Returns true on success.

=head2 match( $uri )

Returns the 'routed' uri with the intersection of parameters from C<$uri> and the
defaults (if any).

Returns C<undef> if no matching route is found.

=head2 uri_for( $routeName, \%params )

Returns the uri for a given route with the provided params.

Given this route:

  $router->add_route({
    name      => 'IceCream',
    path      => '/ice-cream/:flavor',
    target    => '/dessert.asp',
    defaults  => {
      flavor  => 'chocolate'
    }
  });

You would get the following results depending on what params you supply:

  my $uri = $router->uri_for('IceCream');
  print $uri;   # /ice-cream/chocolate/
  
  my $uri = $router->uri_for('IceCream', {
    flavor  => 'strawberry',
  });
  print $uri;   # /ice-cream/strawberry/

=head2 route_for( $path, [ $method ] )

Returns the route matching the path and method.

=head1 LIMITATIONS

Before version 0.009 there were some limitations in the grammar that prevented
paths like C</wiki/:lang-:locale/{*Page}> from picking up the C<:lang> and C<:locale>
correctly.  As of version 0.009 this works correctly.

=head1 SIMPLE CRUD EXAMPLE

  $router->add_route(
    name    => 'CreatePage',
    path    => '/main/:type/create',
    target  => '/pages/[:type:].create.asp',
    method  => 'GET'
  );
  
  $router->add_route(
    name    => 'Create',
    path    => '/main/:type/create',
    target  => '/handlers/dev.[:type:].create',
    method  => 'POST'
  );
  
  $router->add_route(
    name    => 'View',
    path    => '/main/:type/{id:\d+}',
    target  => '/pages/[:type:].view.asp',
    method  => '*',
  );
  
  $router->add_route(
    name      => 'List',
    path      => '/main/:type/list/{page:\d+}',
    target    => '/pages/[:type:].list.asp',
    method    => '*',
    defaults  => { page => 1 }
  );
  
  $router->add_route(
    name    => 'Delete',
    path    => '/main/:type/delete/{id:\d+}',
    target  => '/handlers/dev.[:type:].delete',
    method  => 'POST'
  );

This works great with L<ASP4>.

=head1 ACKNOWLEDGEMENTS

Part of the path parsing logic was originally based on L<Router::Simple> by 
Matsuno Tokuhiro L<http://search.cpan.org/~tokuhirom/> I<et al>.

The path grammar is a copy of the route grammar used by ASP.Net 4.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 LICENSE

This software is B<Free> software and may be used and redistributed under the
same terms as any version of Perl itself.

=cut

