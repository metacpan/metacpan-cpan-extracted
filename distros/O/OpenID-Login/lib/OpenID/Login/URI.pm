package OpenID::Login::URI;
{
  $OpenID::Login::URI::VERSION = '0.1.2';
}

# ABSTRACT: OpenID Identifier validation and encoding for OpenID::Login.

use strict;

use URI;
use List::MoreUtils qw(none any);

sub _build_url_regexp {
    my $class         = shift;
    my $digit         = q{[0-9]};
    my $upalpha       = q{[A-Z]};
    my $lowalpha      = q{[a-z]};
    my $alpha         = qq{(?:$lowalpha|$upalpha)};
    my $alphanum      = qq{(?:$alpha|$digit)};
    my $hex           = qq{(?:$digit|[A-Fa-f])};
    my $escaped       = qq{%$hex$hex};
    my $mark          = q{[-_.!~*'()]};
    my $unreserved    = qq{(?:$alphanum|$mark)};
    my $reserved      = q{[;/?:@&=+$,]};
    my $uric          = qq{(?:$reserved|$unreserved|$escaped)};
    my $query         = qq{$uric*};
    my $pchar         = qq{(?:$unreserved|$escaped|} . q{[:@&=+$,])};
    my $param         = qq{$pchar*};
    my $segment       = qq{$pchar*(?:;$param)*};
    my $path_segments = qq{$segment(?:/$segment)*};
    my $abs_path      = qq{/$path_segments};
    my $port          = qq{$digit*};
    my $IPv4address   = qq{$digit+\\.$digit+\\.$digit+\\.$digit+};
    my $toplabel      = qq{(?:$alpha|$alpha(?:$alphanum|-)*$alphanum)};
    my $domainlabel   = qq{(?:$alphanum|$alphanum(?:$alphanum|-)*$alphanum)};
    my $hostname      = qq{(?:$domainlabel\\.)*$toplabel\\.?};
    my $host          = qq{(?:$hostname|$IPv4address)};
    my $fragment      = qq{$uric*};
    my $pattern       = qq{https?://$host(?::$port)?(?:$abs_path(?:\\?$query)?)?(?:#$fragment)?};
    return $pattern;
}

my $REGEX = __PACKAGE__->_build_url_regexp();


sub is_uri {
    my $class = shift;
    my $uri   = shift;
    return $uri =~ /^$REGEX$/o;
}


sub normalize {
    my $class = shift;
    my $uri   = shift;

    my $u = URI->new($uri);
    return unless $u->scheme;
    return if ( none { $_ eq $u->scheme } qw(http https) );
    return unless $u->can('host') && $u->host;

    my $path = $class->_remove_dot_segments( $u->path );
    $path = '/' if length($path) == 0;
    $u->path($path);

    my $u_str = $u->canonical->as_string;
    $u_str =~ s/(%[a-fA-F0-9]{2})/uc $class->_encode($1)/eg;
    return $u_str;
}

sub _encode {
    my ( $class, $u ) = @_;
    my $num = substr( $u, 1 );
    my $packed = pack( 'H*', $num );
    return $packed =~ /[A-Za-z0-9._~-]/ ? $packed : $u;
}

sub _remove_dot_segments {
    my ( $class, $path ) = @_;
    my @result_segments;
    while ( length($path) > 0 ) {
        if ( $path =~ m!^\.\./! ) {
            $path = substr( $path, 3 );
        } elsif ( $path =~ m!^\./! ) {
            $path = substr( $path, 2 );
        } elsif ( $path =~ m!^/\./! ) {
            $path = substr( $path, 2 );
        } elsif ( $path eq q{/.} ) {
            $path = q{/};
        } elsif ( $path =~ m!^/\.\./! ) {
            $path = substr( $path, 3 );
            pop(@result_segments) if @result_segments > 0;
        } elsif ( $path eq q{/..} ) {
            $path = q{/};
            pop(@result_segments) if @result_segments > 0;
        } elsif ( $path eq q{..} || $path eq q{.} ) {
            $path = q{};
        } else {
            my $i = 0;
            $i = 1 if substr( $path, 0, 1 ) eq q{/};
            $i = index( $path, q{/}, $i );
            $i = length($path) unless $i >= 0;
            push( @result_segments, substr( $path, 0, $i ) );
            $path = substr( $path, $i );
        }
    }
    return join( '', @result_segments );
}

1;



=pod

=head1 NAME

OpenID::Login::URI - OpenID Identifier validation and encoding for OpenID::Login.

=head1 VERSION

version 0.1.2

=head1 METHODS

=head2 is_uri

Determines if supplied parameter is an uri.

=head2 normalize

Normalizes and encodes an supplied uri if necessary.

=head1 AUTHOR

Holger Eiboeck <realholgi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Holger Eiboeck.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
