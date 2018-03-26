use 5.006; use strict; use warnings;

package Plack::Middleware::RedirectSSL;
$Plack::Middleware::RedirectSSL::VERSION = '1.300';
# ABSTRACT: force all requests to use in-/secure connections

use parent 'Plack::Middleware';

use Plack::Util ();
use Plack::Util::Accessor qw( ssl hsts_header );
use Plack::Request ();

#                               seconds  minutes  hours   days  weeks
sub DEFAULT_STS_MAXAGE     () {      60  *    60  *  24  *   7  *  26 }
sub MIN_STS_PRELOAD_MAXAGE () {      60  *    60  *  24  * 365        }

sub call {
	my ( $self, $env ) = ( shift, @_ );

	my $do_ssl = $self->ssl ? 1 : 0;
	my $is_ssl = ( 'https' eq $env->{'psgi.url_scheme'} ) ? 1 : 0;

	if ( $is_ssl xor $do_ssl ) {
		my $m = $env->{'REQUEST_METHOD'};
		return [ 400, [qw( Content-Type text/plain )], [ 'Bad Request' ] ]
			if 'GET' ne $m and 'HEAD' ne $m;
		my $uri = Plack::Request->new( $env )->uri;
		$uri->scheme( $do_ssl ? 'https' : 'http' );
		return [ 301, [ Location => $uri ], [] ];
	}

	my $res = $self->app->( $env );

	return $res unless $is_ssl and my $hsts = $self->hsts_header;

	Plack::Util::response_cb( $res, sub {
		Plack::Util::header_set( $_[0][1], 'Strict-Transport-Security', $hsts );
	} );
}

sub hsts_policy {
	my ( $self, $policy ) = ( shift, @_ );
	return $self->{'hsts_policy'} unless @_;
	$self->hsts_header( render_sts_policy( $policy ) );
	$self->{'hsts'} = $policy ? $policy->{'max_age'} || '00' : 0; # legacy compat
	$self->{'hsts_policy'} = $policy;
}

sub hsts {
	my ( $self, $value ) = ( shift, @_ );
	return $self->{'hsts'} unless @_;
	$self->hsts_policy( ( $value or not defined $value )
		? { ( map %$_, $self->{'hsts_policy'} || () ), max_age => $value }
		: undef
	);
	$self->{'hsts'} = $value;
}

sub new {
	my $self = shift->SUPER::new( @_ );
	$self->ssl(1) if not defined $self->ssl;
	if    ( exists $self->{'hsts_policy'} ) { $self->hsts_policy( $self->{'hsts_policy'} ) }
	elsif ( exists $self->{'hsts'}        ) { $self->hsts       ( $self->{'hsts'} ) }
	elsif ( not $self->hsts_header        ) { $self->hsts_policy( {} ) }
	$self;
}

########################################################################

sub _callsite () { my $i; while ( my ( $p, $f, $l ) = caller ++$i ) { return " at $f line $l.\n" if __PACKAGE__ ne $p } '' }

sub render_sts_policy {
	my ( $opt ) = @_;

	die 'HSTS policy must be a single undef value or hash ref', _callsite
		if 1 != @_ or defined $opt and 'HASH' ne ref $opt;

	return undef if not defined $opt;

	my @directive = qw( max_age include_subdomains preload );

	{
		my %known = map +( $_, 1 ), @directive;
		my $unknown = join ', ', map "'$_'", sort grep !$known{ $_ }, keys %$opt;
		die "HSTS policy contains unknown directive(s) $unknown", _callsite if $unknown;
	}

	my ( $max_age, $include_subdomains, $preload ) = @$opt{ @directive };

	$max_age = defined $max_age
		? do { no warnings 'numeric'; int $max_age }
		: $preload ? MIN_STS_PRELOAD_MAXAGE : DEFAULT_STS_MAXAGE;

	die 'HSTS max_age 0 conflicts with setting other directives', _callsite
		if 0 == $max_age and ( $include_subdomains or $preload );

	if ( $preload ) {
		$include_subdomains = 1 unless defined $include_subdomains;
		die 'HSTS preload conflicts with disabled include_subdomains', _callsite unless $include_subdomains;
		die "HSTS preload requires longer max_age (got $max_age; minimum ".MIN_STS_PRELOAD_MAXAGE.')', _callsite
			if MIN_STS_PRELOAD_MAXAGE > $max_age;
	}

	# expose computed values back to the caller
	@$opt{ @directive } = ( $max_age, !!$include_subdomains, !!$preload );

	join '; ', "max-age=$max_age", ('includeSubDomains') x !!$include_subdomains, ('preload') x !!$preload;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::RedirectSSL - force all requests to use in-/secure connections

=head1 VERSION

version 1.300

=head1 SYNOPSIS

 # in app.psgi
 use Plack::Builder;
 
 builder {
     enable 'RedirectSSL';
     $app;
 };

=head1 DESCRIPTION

This middleware intercepts requests using either the C<http> or C<https> scheme
and redirects them to the same URI under respective other scheme.

=head1 CONFIGURATION OPTIONS

=over 4

=item C<ssl>

Specifies the direction of redirects. If true or not specified, requests using
C<http> will be redirected to C<https>. If false, requests using C<https> will
be redirected to plain C<http>.

=item C<hsts_header>

Specifies an arbitrary string value for the C<Strict-Transport-Security> header.
If false, no such header will be sent.

=item C<hsts_policy>

Specifies a value to pass to C<L</render_sts_policy>>
and updates the C<hsts_header> option with the returned value.

Defaults to an HSTS policy with default values.

=item C<hsts>

Use of this option is L<discouraged|perlpolicy/discouraged>.

Specifies a C<max-age> value for the current HSTS policy (preserving all other directives)
or creates a new one (containing no other directives)
and updates the C<hsts_header> option to reflect it.
If undef, sets a C<hsts_header> to a C<max-age> of 26E<nbsp>weeks.
If otherwise false, sets C<hsts_header> to C<undef>.
(If you really want a C<max-age> value of 0, use C<'00'>, C<'0E0'> or C<'0 but true'>.)

=back

=head1 FUNCTIONS

=head2 C<render_sts_policy>

Takes either a hash reference containing an HSTS policy or C<undef>,
and returns the corresponding C<Strict-Transport-Security> header value.
As a side effect, validates the policy and
updates the hash with the ultimate value of every directive after computing defaults.

The following directives are supported:

=over 4

=item C<max_age>

Integer value for the C<max-age> directive.

If missing or undefined, it will normally default to 26E<nbsp>weeks.

But if the C<preload> directive is true, it will default to 365E<nbsp>days
and may not be set to any smaller value.

If 0 (which unpublishes a previous HSTS policy), no other directives may be set.

=item C<include_subdomains>

Boolean; whether to include the C<includeSubDomains> directive.

If missing or undefined, it will normally default to false.

But if the C<preload> directive is true, it will defaults to true
and may not be set to false.

=item C<preload>

Boolean; whether to include the C<preload> directive.

=back

=head1 SEE ALSO

=over 4

=item *

L<RFCE<nbsp>6797, I<HTTP Strict Transport Security>|http://tools.ietf.org/html/rfc6797>

=item *

L<HSTS preload list|https://hstspreload.org/>

=back

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
