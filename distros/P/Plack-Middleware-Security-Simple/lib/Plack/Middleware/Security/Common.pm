package Plack::Middleware::Security::Common;

# ABSTRACT: A simple security filter for Plack with common rules.

use strict;
use warnings;

use parent qw( Plack::Middleware::Security::Simple Exporter::Tiny );

use Regexp::Common qw/ net /;

our @EXPORT = qw(
   archive_extensions
   cgi_bin
   dot_files
   fake_extensions
   ip_address_referer
   misc_extensions
   non_printable_chars
   null_or_escape
   protocol_in_path_or_referer
   require_content
   script_extensions
   system_dirs
   unexpected_content
   webdav_methods
   wordpress
);

our $VERSION = 'v0.6.1';



sub archive_extensions {
    my $re = qr{\.(?:iso|rar|tar|u?zip|[7glx]?z|tgz)\b};
    return (
        PATH_INFO    => $re,
        QUERY_STRING => $re,
    );
}


sub cgi_bin {
    my $re = qr{/cgi[_\-](bin|wrapper)};
    return (
        PATH_INFO    => $re,
        QUERY_STRING => $re,
    );
}


sub dot_files {
    return (
        PATH_INFO    => qr{(?:\.\./|/\.(?!well-known/))},
        QUERY_STRING => qr{\.\./},
    );
}


sub fake_extensions {
    my $re = qr{;[.](?:\w+)\b};
    return (
        PATH_INFO    => $re,
    )
}


sub ip_address_referer {
    return (
        HTTP_REFERER => qr{^https?://$RE{net}{IPv4}/},
        HTTP_REFERER => qr{^https?://$RE{net}{IPv6}/},
    );
}


sub misc_extensions {
    my $re = qr{[.](?:bak|cfg|conf|dat|inc|ini|yml)\b};
    return (
        PATH_INFO    => $re,
        QUERY_STRING => $re,
    )
}


sub non_printable_chars {
    return ( PATH_INFO => qr/[^[:print:]]/ )
}


sub null_or_escape {
    my $re = qr{\%(?:00|1b|1B)};
    return (
        REQUEST_URI  => $re,
    )
}


sub protocol_in_path_or_referer {
    my $re = qr{\b(?:file|dns|jndi|unix|ldap):};
    return (
        PATH_INFO    => $re,
        QUERY_STRING => $re,
        HTTP_REFERER => $re,
    );
}


sub require_content {
    return (
        -and => [
             REQUEST_METHOD => qr{^(?:POST|PUT)$},
             CONTENT_LENGTH => sub { !$_[0] },
        ],
    );
}


sub script_extensions {
    my $re = qr{[.](?:as[hp]x?|axd|bat|cfm|cgi|com|dll|do|exe|jspa?|lua|mvc?|php5?|p[lm]|ps[dm]?[1h]|sht?|shtml|sql)\b};
    return (
        PATH_INFO    => $re,
        QUERY_STRING => $re,
    )
}


sub system_dirs {
    my $re = qr{/(?:s?bin|etc|usr|var|srv|opt)/};
    return (
        PATH_INFO    => $re,
        QUERY_STRING => $re,
    );
}


sub unexpected_content {
    return (
        -and => [
             REQUEST_METHOD => qr{^(?:GET|HEAD|CONNECT|OPTIONS|TRACE)$},
             CONTENT_LENGTH => sub { !!$_[0] },
        ],
    );
}


sub webdav_methods {
    return ( REQUEST_METHOD =>
          qr{^(COPY|LOCK|MKCOL|MOVE|PROPFIND|PROPPATCH|UNLOCK)$} );
}


sub wordpress {
    return ( PATH_INFO => qr{\b(?:wp(-\w+)?|wordpress)\b} );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Security::Common - A simple security filter for Plack with common rules.

=head1 VERSION

version v0.6.1

=head1 SYNOPSIS

  use Plack::Builder;

  # import rules
  use Plack::Middleware::Security::Common;

  builder {

    enable "Security::Common",
        rules => [
            archive_extensions, # block .tar, .zip etc
            cgi_bin,            # block /cgi-bin
            script_extensions,  # block .php, .asp etc
            unexpected_content, # block GET with body params
            ...
        ];

   ...

  };

=head1 DESCRIPTION

This is an extension of L<Plack::Middleware::Security::Simple> that
provides common filtering rules.

Most of these rules don't directly improve the security of your web
application: they simply block common exploit scanners from getting
past the PSGI layer.

Note that they cannot block any exploits of proxies that are in front
of your PSGI application.

See L</EXPORTS> for a list of rules.

You can create exceptions to the rules by adding qualifiers, for
example, you want to block requests for archives, except in a
F</downloads> folder, you could use something like

  builder {

    enable "Security::Common",
        rules => [
           -and => [
                -notany => [ PATH_INFO => qr{^/downloads/} ],
                -any    => [ archive_extensions ],
            ],
          ...
        ];

    ...

  };

Note that the rules return an array of matches, so when qualifying
them you will need to put them in an array reference.

=head1 EXPORTS

=head2 archive_extensions

This blocks requests with common archive file extensions in the path
or query string.

=head2 cgi_bin

This blocks requests that refer to the C<cgi-bin> directory in the path
or query string, or a C<cgi_wrapper> script.

=head2 dot_files

This blocks all requests that refer to dot-files or C<..>, except for
the F</.well-known/> path.

=head2 fake_extensions

This blocks requests with fake extensions, usually done with image extensions, e.g.
F</some/path;.jpg>.

Added in v0.5.1.

=head2 ip_address_referer

This blocks all requests where the HTTP referer is an IP4 or IP6
address.

Added in v0.5.0.

=head2 misc_extensions

This blocks requests with miscellenious extensions in the path or
query string.

This includes common extensions for backups, includes or configuration
files.

=head2 non_printable_chars

This blocks requests with non-printable characters in the path.

=head2 null_or_escape

This blocks requests with nulls or escape chatacters in the path or
query string.

=head2 protocol_in_path_or_referer

This blocks requests that have non-web protocols like C<file>, C<dns>,
C<jndi>, C<unix> or C<ldap> in the path, query string or referer.

Added in v0.5.1.

=head2 require_content

This blocks POST or PUT requests with no content.

This was added in v0.4.1.

=head2 script_extensions

This blocks requests that refer to actual scripts, file file
extension, such as C<.php> or C<.asp>.  It will also block requests
that refer to these scripts in the query string.

=head2 system_dirs

This blocks requests that refer to system directories in the path or
query string.

=head2 unexpected_content

This blocks requests with content bodies using methods that don't
normally have content bodies, such as GET or HEAD.

Note that web sites which do not differentiate between query and body
parameters can be caught out by this. An attacker can hit these
website with GET requests that have parameters that exploit security
holes in the request body.  The request would appear as a normal GET
request in most logs.

=head2 webdav_methods

This blocks requests using WebDAV-related methods.

=head2 wordpress

This blocks requests for WordPress-related pages.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Plack-Middleware-Security-Simple>
and may be cloned from L<git://github.com/robrwo/Plack-Middleware-Security-Simple.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Plack-Middleware-Security-Simple/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

Suggestions for new rules or improving the existing rules are welcome.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014,2018-2022 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
