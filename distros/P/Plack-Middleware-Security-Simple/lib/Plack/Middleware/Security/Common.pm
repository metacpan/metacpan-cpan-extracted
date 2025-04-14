package Plack::Middleware::Security::Common;

# ABSTRACT: A simple security filter for Plack with common rules.

use v5.14;

use warnings;

use parent qw( Plack::Middleware::Security::Simple Exporter::Tiny );

use Regexp::Common qw/ net /;

our @EXPORT = qw(
   archive_extensions
   backup_files
   cgi_bin
   cms_prefixes
   document_extensions
   dot_files
   exchange_prefixes
   fake_extensions
   header_injection
   ip_address_referer
   misc_extensions
   non_printable_chars
   null_or_escape
   protocol_in_path_or_referer
   require_content
   script_extensions
   script_injection
   system_dirs
   unexpected_content
   webdav_methods
   wordpress
);

our $VERSION = 'v0.12.1';



sub archive_extensions {
    my $re = qr{\.(?:bz2|iso|rar|tar|u?zip|[7glx]?z|tgz)\b};
    return (
        PATH_INFO    => $re,
        QUERY_STRING => $re,
    );
}


sub backup_files {
    return (
        misc_extensions(),
        PATH_INFO =>  qr{(?:backup|database|db|dump|localhost)\.},
    );
}


sub cgi_bin {
    my $re = qr{/cgi[_\-](?:bin|wrapper)};
    return (
        PATH_INFO    => $re,
        QUERY_STRING => $re,
    );
}


sub cms_prefixes {
    my $re = qr{/(?:docroot|drupal|ftproot|include|inetpub|joomla|laravel|lib|magento|plugin|plus|vendor|webroot|wp|wordpress|yii|zend)};
    return (
        PATH_INFO    => $re,
    );
}


sub document_extensions {
    my $re = qr{\.(?:a[bz]w|csv|docx?|e?pub|od[pst]|pdf|pptx?|one|rtf|vsd|xlsx?)\b};
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


sub exchange_prefixes {
    return (
        PATH_INFO => qr{^/+(?:ecp|owa|autodiscover)/}i,
    )
}


sub fake_extensions {
    my $re = qr{;[.](?:\w+)\b};
    return (
        PATH_INFO    => $re,
    )
}


sub header_injection {
    my $re = qr{(?:\%20HTTP/[0-9]|%0d%0a)}i;
    return (
        PATH_INFO    => $re,
    );
}



sub ip_address_referer {
    return (
        HTTP_REFERER => qr{^https?://$RE{net}{IPv4}/},
        HTTP_REFERER => qr{^https?://$RE{net}{IPv6}/},
    );
}


sub misc_extensions {
    my $re = qr{[.](?:backup|bak|bck|bkp|cfg|conf(?:ig)?|dat|ibz|in[ci]|npb|old|ps[bc]|rdg|to?ml|yml)\b};
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
    my $re = qr{\b(?:file|dns|jndi|unix|ldap|php):};
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
    my $re = qr{[.](?:as[hp]x?|axd|bat|cc?|cfm|cgi|com|csc|dll|do|exe|jspa?|lua|mvc?|php5?|p[lm]|ps[dm]?[1h]|sht?|shtml|sql)\b};
    return (
        PATH_INFO    => $re,
        QUERY_STRING => $re,
    )
}


sub script_injection {
    my $re = qr{data:(?:application|text)/(?:x-)?(?:javascript|wasm);};
    return (
        PATH_INFO    => $re,
        QUERY_STRING => $re,
    );
}


sub system_dirs {
    my $re = qr{/(?:s?adm|bin|etc|usr|var|srv|opt|__MACOSX|META-INF)/};
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

version v0.12.1

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

=head2 backup_files

This includes L</misc_extensions> plus filename suffixes associated
with backup files, e.g. F<example.com-database.zip>.

Added in v0.8.0.

=head2 cgi_bin

This blocks requests that refer to the C<cgi-bin> directory in the path
or query string, or a C<cgi_wrapper> script.

=head2 cms_prefixes

This blocks requests that refer to directories with common CMS
applications, libraries, or web servers.

Added in v0.8.0.

=head2 document_extensions

This blocks requests for file extensions associated with common document formats, e.g. Office documents or spreadsheets.

This does not include audio, video or image files.

If you provide downloads for specific files, then you may need to add exceptions for this rule based on the file type
and path.

Added in v0.9.2.

=head2 dot_files

This blocks all requests that refer to dot-files or C<..>, except for
the F</.well-known/> path.

=head2 exchange_prefixes

This blocks paths associated with Exchange servers.

=head2 fake_extensions

This blocks requests with fake extensions, usually done with image extensions, e.g.
F</some/path;.jpg>.

Added in v0.5.1.

=head2 header_injection

This blocks requests that attept to inject a header in the response. e.g.
C<GET /%20HTTP/1.1%0d%0aX-Auth:%20accepted%0d%0a>.

Any path with an HTTP protocol suffix or newline plus carriage return
will be rejected.

Added in v0.7.0.

=head2 ip_address_referer

This blocks all requests where the HTTP referer is an IP4 or IP6
address.

Added in v0.5.0.

=head2 misc_extensions

This blocks requests with miscellenious extensions in the path or
query string.

This includes common extensions and suffixes for backups, includes or
configuration files.

=head2 non_printable_chars

This blocks requests with non-printable characters in the path.

=head2 null_or_escape

This blocks requests with nulls or escape chatacters in the path or
query string.

=head2 protocol_in_path_or_referer

This blocks requests that have non-web protocols like C<file>, C<dns>,
C<jndi>, C<unix>, C<ldap> or C<php> in the path, query string or referer.

Added in v0.5.1.

=head2 require_content

This blocks POST or PUT requests with no content.

This was added in v0.4.1.

=head2 script_extensions

This blocks requests that refer to actual scripts or source code file
extension, such as C<.php> or C<.asp>.  It will also block requests
that refer to these scripts in the query string.

=head2 script_injection

This block requests that inject scripts using data-URLs.

=head2 system_dirs

This blocks requests that refer to system or metadata directories in
the path or query string.

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

=head2 Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website. Please see F<SECURITY.md> for instructions how to
report security vulnerabilities

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014,2018-2025 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
