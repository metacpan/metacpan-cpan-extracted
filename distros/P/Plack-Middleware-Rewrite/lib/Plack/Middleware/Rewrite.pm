use 5.006;
use strict;
use warnings;

package Plack::Middleware::Rewrite;
$Plack::Middleware::Rewrite::VERSION = '2.000';
# ABSTRACT: mod_rewrite for Plack

use parent 'Plack::Middleware';

use Plack::Util::Accessor qw( request response rules );
use Plack::Request ();
use Plack::Util ();
use overload ();

sub call {
	my $self = shift;
	my ( $env ) = @_;

	my ( $app, $res, $legacy );
	my ( $rules, $modify_cb ) = ( $self->request, $self->response );

	unless ( $rules or $modify_cb ) {
		$rules = $self->rules;
		$legacy = 1;
	}

	# call rules with $_ aliased to PATH_INFO
	( $res ) = map { scalar $rules->( $env ) } $env->{'PATH_INFO'}
		if $rules;

	if ( $legacy ) {
		if    ( 'CODE'  eq ref $res ) { ( $modify_cb, $res ) = $res }
		elsif ( 'ARRAY' eq ref $res ) { undef $res if not @$res }
		elsif ( ref $res )            { undef $res }
		else {
			# upgrade scalar to response if it looks like an HTTP status
			$res = ( defined $res and $res =~ /\A[1-5][0-9][0-9]\z/ )
				? [ $res, [], [] ]
				: undef;
		}
	}
	else {
		if    ( 'CODE'  eq ref $res ) { ( $app, $res ) = $res }
		elsif ( 'ARRAY' eq ref $res ) { @$res = ( 303, [], [] ) if not @$res }
		elsif ( ref $res )            { die 'Unhandled reference type in request rewrite: ', overload::StrVal( $res ), "\n" }
		else                          { undef $res }
	}

	if ( $res ) { # external redirect, or explicit response
		push @$res, map { [] } @$res .. 2;

		if ( $res->[0] =~ /\A3[0-9][0-9]\z/ ) {
			my $dest = Plack::Util::header_get( $res->[1], 'Location' );
			if ( not $dest ) {
				$dest = Plack::Request->new( $env )->uri;
				Plack::Util::header_set( $res->[1], Location => $dest );
			}

			if ( 304 ne $res->[0] and not (
				Plack::Util::content_length( $res->[2] )
				or Plack::Util::header_exists( $res->[1], 'Content-Length' )
			) ) {
				my $href = Plack::Util::encode_html( $dest );
				Plack::Util::header_set( $res->[1], qw( Content-Type text/html ) );
				$res->[2] = [ qq'<!DOCTYPE html><title>Moved</title>This resource has moved to <a href="$href">a new address</a>.' ];
			}
		}
	}
	else { # internal redirect
		$app ||= $self->app;
		$res = $app->( $env );
	}

	return $res if not $modify_cb;
	Plack::Util::response_cb( $res, sub {
		my ( $res ) = map { $modify_cb->( $env ) } Plack::Util::headers( $_[0][1] );
		return $res if 'CODE' eq ref $res;
		return;
	} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Rewrite - mod_rewrite for Plack

=head1 VERSION

version 2.000

=head1 SYNOPSIS

 # in app.psgi
 use Plack::Builder;
 
 builder {
     enable 'Rewrite', request => sub {
         s{^/here(?=/|$)}{/there};

         return [303]
             if s{^/foo/?$}{/bar/}
             or s{^/baz/?$}{/quux/};

         return [301, [ Location => 'http://example.org/' ], []]
             if m{^/example/?$};

         return [201] if $_ eq '/favicon.ico';

         return [503] if -e '/path/to/app/maintenance.lock';

         return [200, [qw(Content-Type text/plain)], ['You found it!']]
             if $_ eq '/easter-egg';
     }, response => sub {
         $_->set( 'Content-Type', 'application/xhtml+xml' )
             if ( $_[0]{'HTTP_ACCEPT'} || '' ) =~ m{application/xhtml\+xml(?!\s*;\s*q=0)};
     };
     $app;
 };

=head1 DESCRIPTION

This middleware provides a convenient way to modify requests in flight in Plack
apps. Rewrite rules are simply written in Perl, which means everything that can
be done with mod_rewrite can be done with this middleware much more intuitively
(if in syntactically wordier ways). Its primary purpose is rewriting paths, but
almost anything is possible very easily.

=head1 CONFIGURATION OPTIONS

=head2 C<request>

Takes a reference to a function that will be called in scalar context for each
request. On call, C<$_> will be aliased to C<PATH_INFO>, so that you can easily
use regexp matches and subtitutions to examine and modify it. The L<PSGI>
environment will be passed to the function as its first and only argument.

The function may return three kinds of valid value:

=over 4

=item A plain scalar

Ignored. The value will be thrown away and any path rewriting (or any other
modifications of the PSGI environment) will take effect during the current
request cycle, invisibly to the client user agent.

=item An array reference

A L<PSGI> array response to return immediately without invoking the wrapped
PSGI application.

The array may have fewer than 3 elements, in which case it will be filled to
3E<nbsp>elements by pushing the default values: an empty body array, empty
headers array, and a 303E<nbsp>statusE<nbsp>code.

If the C<Location> header is missing from a redirect response (i.e. one with
3xxE<nbsp>statusE<nbsp>code), it will be filled in automatically from the value
left in C<PATH_INFO> by your callback. (Note that this only allows you to
redirect to URLs with the same hostname. To redirect the client to a different
host, you will have to supply a C<Location> header manually.)

=item A code reference

A PSGI application which will be called to process the request. This prevents
the wrapped application from being called.

=item Any other kind of reference

Error. An exception will be thrown.

=back

=head2 C<response>

Takes a reference to a function that will be called I<after> the request has
been processed and the response is ready to be returned.

On call, C<$_> will be aliased to a L<C<Plack::Util::headers>|Plack::Util>
object for the response, for convenient alteration of headers. Just as in
L</C<request>>, the L<PSGI> environment is passed as first and only argument.

Any return value from this function will be ignored unless it is a code
reference. In that case it will be used to filter the response body, as
documented in L<Plack::Middleware/RESPONSE CALLBACK>:

=over 4

 return sub {
     my $chunk = shift;
     return unless defined $chunk;
     $chunk =~ s/Foo/Bar/g;
     return $chunk;
 };

The callback takes one argument C<$chunk> and your callback is expected to
return the updated chunk. If the given C<$chunk> is undef, it means the stream
has reached the end, so your callback should also return undef, or return the
final chunk and return undef when called next time.

=back

=head1 LEGACY INTERFACE

The old interface uses a single attribute, C<rules>, instead of the C<request>
and C<response> pair, with a more complex set of return values, containing an
ambiguity. It is also less expressive than the new interface.

The old interface is documented here for the purposes of maintaining old code;
its use in new code is L<discouraged|perlpolicy/Terminology>. In the far future
it may get removed entirely, and in the meantime it will not gain new features.

The return value of the C<rules> callback is interpreted as follows:

=over 4

=item An array reference (with at least one element)

A regular L<PSGI> response, except that you may omit either or both the headers
and body elements. You I<may not> omit the status.

=item A scalar value that looks like an HTTP status

Like returning a reference to a one-element.

Beware: every subroutine in Perl has a return value, even if you do not return
anything explicitly. To avoid ambiguities you must return one-element arrays
instead of plain values and use an explicit C<return> at the end of your rules:

 return [201] if $_ eq '/favicon.ico';
 s{^/here(?=/|$)}{/there};
 return;

=item A code reference

Equivalent to the L</C<response>> callback in the new interface, with the same
arguments and return values.

=item Any other kind of value

Internal rewrite.

=back

=head2 Porting from the old to the new interface

There are two major incompatibilities between the interfaces:

=over 4

=item 1.

You can no longer return status codes as plain scalars, as in C<return 301>.
You B<must> now C<return [301]> (which you could before, but didn't have to).

=item 2.

Rewriting the response is no longer done by returning a C<sub>.
Instead you must use the C<response> attribute.

This may be inconvient if the function was closing over variables from the
C<rules> callback; in that case you now have to explicitly pass that state
from one callback to the other through the environment hash. However, such
code is rare, and in all other cases your code will be more readable under
the new interface.

=back

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
