package Router::Resource;

use strict;
use 5.8.1;
use Router::Simple::Route;
use Sub::Exporter -setup => {
    exports => [ qw(router resource missing GET POST PUT DELETE HEAD OPTIONS TRACE CONNECT PATCH)],
    groups  => { default => [ qw(resource router missing GET POST PUT DELETE HEAD OPTIONS TRACE CONNECT PATCH) ] }
};

our $VERSION = '0.21';

sub new {
    my $class = shift;
    bless { @_, routes => [] };
}

our (%METHS, $ROUTER);

sub router(&;@) {
    my ($block, @settings) = @_;
    local $ROUTER = __PACKAGE__->new(@settings);
    $block->();
    return $ROUTER;
}

sub resource ($&) {
    my ($path, $code) = @_;
    local %METHS = ();
    $code->();

    # Let HEAD use GET if not specified.
    $METHS{HEAD} ||= $METHS{GET};

    # Add OPTIONS if requested.
    if ($ROUTER->{auto_options} && !$METHS{OPTIONS}) {
        my $methods = join(', ' => 'OPTIONS', keys %METHS);
        $METHS{OPTIONS} = sub { [200, ['Allow', $methods], []] };
    }

    # Add the route.
    push @{ $ROUTER->{routes} }, Router::Simple::Route->new(
        $path, { meths => { %METHS } }
    );
}

sub missing(&) { $ROUTER->{missing} = shift }
sub GET(&)     { $METHS{GET}     = shift }
sub HEAD(&)    { $METHS{HEAD}    = shift }
sub POST(&)    { $METHS{POST}    = shift }
sub PUT(&)     { $METHS{PUT}     = shift }
sub DELETE(&)  { $METHS{DELETE}  = shift }
sub OPTIONS(&) { $METHS{OPTIONS} = shift }
sub TRACE(&)   { $METHS{TRACE}   = shift }
sub CONNECT(&) { $METHS{CONNECT} = shift }
sub PATCH(&)   { $METHS{PATCH}   = shift }

sub dispatch {
    my ($self, $env) = @_;
    my $match = $self->match($env);
    if (my $meth = $match->{meth}) {
        return $meth->($env, $match->{data});
    }
    my $missing = $self->{missing} or return [
        $match->{code}, $match->{headers}, [$match->{message}]
    ];
    return $missing->($env, $match);
}

sub match {
    my ($self, $env) = @_;
    my $meth = uc($env->{REQUEST_METHOD} || '') or return;

    for my $route (@{ $self->{routes} }) {
        my $match = $route->match($env) or next;
        my $meths = delete $match->{meths};
        my $code = $meths->{$meth} or return {
            code    => 405,
            message => 'not allowed',
            headers => [Allow => join ', ', sort keys %{ $meths } ],
        };
        return { meth => $code, code => 200, data => $match };
    }
    return { code => 404, message => 'not found', headers => [] };
}

1;
__END__

=head1 Name

Router::Resource - Build REST-inspired routing tables

=head1 Synopsis

  use Router::Resource;
  use Plack::Builder;
  use namespace::autoclean;

  sub app {
      # Create a routing table.
      my $router = router {
          resource '/' => sub {
              GET  { $template->render('home') };
          };

          resource '/blog/{year}/{month}' => sub {
              GET  { [200, [], [ $template->render({ posts => \@posts }) ] };
              POST { push @posts, new_post(shift); [200, [], ['ok']] };
          };
      };

      # Build the Plack app to use it.
      builder {
          sub { $router->dispatch(shift) };
      };
  }

=head1 Description

There are a bunch of path routers on CPAN, but they tend not to be very RESTy.
A basic idea of a RESTful API is that URIs point to resources and the standard
HTTP methods indicate the actions to be taken on those resources. So to
encourage you to think about it that way, Router::Resource requires that you
declare resources and then the HTTP methods that are implemented for those
resources.

The rules for matching paths are defined by
L<Router::Simple's routing rules|Router::Simple/HOW TO WRITE A ROUTING RULE>,
which offer quite a lot of flexibility.

=head2 Interface

You create a router in a C<router> block. Within that block, define resources
understood by the router with the C<resource> keyword, which takes a resource
path and a block defining its interface:

  my $router = {
      resource '/'    => sub { [[200, [], ['ok']] };
      resource '/foo' => sub { [[200, [], ['ok']] };
  };

Within a resource block, declare the HTTP methods that the resource responds
to by using one or more of the following keywords:

=over

=item C<GET>

=item C<HEAD>

=item C<POST>

=item C<PUT>

=item C<DELETE>

=item C<OPTIONS>

=item C<TRACE>

=item C<CONNECT>

=item C<PATCH>

=back

Note that if you define a C<GET> method but not a C<HEAD> method, the C<GET>
method will respond to C<HEAD> requests.

These methods should expect two arguments: the matched request (generally a
L<PSGI> C<$env> hash) and a hash of the matched data as created by
Router::Simple. For example, in a L<Plack>-powered Wiki app you might do
something like this:

  resource '/wiki/{name}' => sub {
      GET {
          my $req    = Plack::Request->new(shift);
          my $params = shift;
          my $wiki   = Wiki->lookup( $params->{name} );
          my $res    = $req->new_response;
          $res->content_type('text/html; charset=UTF-8');
          $res->body($wiki);
          return $res->finalize;
      };
  };

But of course you can abstract that into a controller or other code that the
HTTP method simply dispatches to.

If you wish the router to create an C<OPTIONS> handler for you, pass the
C<auto_options> parameter to C<router>:

    $router = router {
        resource '/blog/{year}/{month}' => sub {
            GET  { [200, [], [ $template->render({ posts => \@posts }) ] };
            POST { push @posts, new_post(shift); [200, [], ['ok']] };
        };
    } auto_options => 1;

With C<auto_options> enabled, Router::Resource will look at the methods
defined for a resource to define the C<OPTIONS> handler. In this example,
C<$router>'s C<OPTIONS> method will specify that C<GET>, C<HEAD>, and
C<OPTIONS> are valid for C</blog/{year}/{month}>.

=head2 Dispatching

Use the C<dispatch> method to have the router dispatch HTTP requests. For a
 Plack app, it looks something like this:

  sub { $router->dispatch(shift) };

The assumption is that the methods you've defined will return a
L<PSGI>-compatible array reference. When the router finds no matching resource
or method, such an array is precisely what I<it> will return. When a resource
cannot be found, it will return

  [404, [], ['not found']]

If the resource is found but the requested method is not defined, it returns
something like:

  [405, [Allow => 'GET, HEAD'], ['not allowed']]

The "Allow" header will list the methods that the requested resource I<does>
respond to.

Of course you may not want something so simple for your app. So use the
C<missing> keyword to specify a code block to handle this situation. The code
block should expect two arguments: the unmatched request C<$env> hash and a
hash describing the failure. For an unfound resource, that hash will contain:

  { code => 404, message => 'not found', headers => [] }

If a resource was found but it does not define the requested method, the hash
will look something like this:

  { code => 405, message => 'not allowed', headers => [Allow => 'GET, HEAD'] }

This is designed to make it relatively easy to create a custom response to
unfound resources and missing methods. Something like:

  missing {
      my $req    = Plack::Request->new(shift);
      my $params = shift;
      my $res    = $req->new_response($params->{code});
      $res->headers(@{ $params->{headers} });
      $res->content_type('text/html; charset=UTF-8');
      $res->body($template->show('not_found', $params));
      return $res->finalize;
  };

=begin private

XXX Document C<match> or not?

=head2 Matches

The C<distpatch> method relies on the C<match> method to find the requested
resources and the methods to execute. If you find that C<dispatch> isn't quite
what you need, you can use C<match> and do the work yourself. The C<match>
method returns a hash describing the match (or lack of match). The keys that
may be found in that hash are:

=over

=item C<code>

An HTTP status code. Possible values are 200 for a successful match, 404 when
the resource cannot be found, and 405 when the resource does not support the
requested method.

=item C<meth>

The code reference that defines the method that was found for the resource.
Always set when C<code> is 200.

=item C<data>

The data matched by Router::Simple. Undefined unless the C<code> is 200.

=item C<headers>

An array reference of headers to be used in the response. Undefined when
C<code> is 200, an empty array for 404, and containing the "Allow" header
for 405.

=back

Use the result hash to determine how to respond. An example:

  sub {
      my $env = shift;
      my $match = $router->match($env);
      if (my $meth = $match->{meth}) {
          # We have a match!
          return $meth->($env, $match->{data});
      }

      if ($match->{code} == 404) {
          return [404, $match->{headers}, ['Nothing found, look elsewhere']];
      } else {
          return [405, $match->{headers}, [
              "Sorry, but $env->{PATH_INFO}" does't respond to "
            . "$env->{REQUEST_METHOD}. Try any of these: "
            . $match->{headers}[0][1]
          ]];
      }
  };


Likely you won't need this, though, as C<dispatch> should cover the vast
majority of needs.

=end private

=head1 See Also

=over

=item *

L<Router::Simple> provides the rule syntax for Router::Resource resource paths.

=item *

L<Router::Simple::Sinatraish> provides a
L<Sinatraish|http://www.sinatrarb.com/> routing table interface. It's nice,
though perhaps a bit too magical.

=item *

L<Sinatra::Resources|http://github.com/nateware/sinatra-resources> - The Ruby
module that inspired this module.

=item *

L<Plack> is B<the> way to write your Perl web apps. Router::Resource is fully
Plack-aware.

=back

=head1 Support

This module is stored in an open L<GitHub
repository|http://github.com/theory/router-resource/>. Feel free to fork and
contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/router-resource/issues/> or by sending mail to
L<bug-Router-Resource@rt.cpan.org|mailto:bug-Router-Resource@rt.cpan.org>.

=head1 Author

David E. Wheeler <david@kineticode.com>

=head1 Acknowledgements

My thanks to the denizens of #plack for their feedback and advice on this module,
including:

=over

=item * L<Hans Dieter Pearcey (confound)|http://search.cpan.org/~hdp/>

=item * L<Florian Ragwitz (rafl)|http://search.cpan.org/~flora/>

=item * L<Paul Evans (LeoNerd)|http://search.cpan.org/~pevans/>

=item * L<Matt S Trout (mst)|http://search.cpan.org/~mstrout/>

=item * L<Tatsuhiko Miyagawa (miyagawa)|http://search.cpan.org/~miyagawa/>

=item * L<Pedro Melo (melo)|http://search.cpan.org/~melo/>

=back

=head1 Copyright and License

Copyright (c) 2010-2011 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
