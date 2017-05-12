package Plack::Middleware::XSLT;
{
  $Plack::Middleware::XSLT::VERSION = '0.30';
}
use strict;
use warnings;

# ABSTRACT: XSLT transformations with Plack

use parent 'Plack::Middleware';

use File::Spec;
use Plack::Util;
use Plack::Util::Accessor qw(cache path parser_options);
use Try::Tiny;
use XML::LibXML 1.62;
use XML::LibXSLT 1.62;

my ($parser, $xslt);

sub call {
    my ($self, $env) = @_;

    my $res = $self->app->($env);

    Plack::Util::response_cb($res, sub {
        my $res = shift;

        my $xsl_file = $env->{'xslt.style'};
        return if !defined($xsl_file) || $xsl_file eq '';

        if (!$xslt) {
            if ($self->cache) {
                require XML::LibXSLT::Cache;
                $xslt = XML::LibXSLT::Cache->new;
            }
            else {
                $xslt = XML::LibXSLT->new;
            }
        }

        my $path = $self->path;
        $xsl_file = File::Spec->catfile($path, $xsl_file)
            if defined($path) && !File::Spec->file_name_is_absolute($xsl_file);

        my $stylesheet = $xslt->parse_stylesheet_file($xsl_file);
        my $media_type = $stylesheet->media_type();
        my $encoding   = $stylesheet->output_encoding();

        my $headers = Plack::Util::headers($res->[1]);
        $headers->remove('Content-Encoding');
        $headers->remove('Transfer-Encoding');
        $headers->set('Content-Type', "$media_type; charset=$encoding");

        if ($res->[2]) {
            my ($output, $error) = $self->_xform($stylesheet, $res->[2]);

            if (defined($error)) {
                # Try to convert error to HTTP response.

                my ($status, $message);

                for my $line (split(/\n/, $error)) {
                    if ($line =~ /^(\d\d\d)(?:\s+(.*))?\z/) {
                        $status  = $1;
                        $message = defined($2) ? $2 : '';
                        last;
                    }
                }

                die($error) if !defined($status);

                $res->[0] = $status;
                $headers->set('Content-Type', 'text/plain');
                $headers->set('Content-Length', length($message));
                $res->[2] = [ $message ];
            }
            else {
                $headers->set('Content-Length', length($output));
                $res->[2] = [ $output ];
            }
        }
        else {
            # PSGI streaming

            my ($done, @chunks);

            return sub {
                my $chunk = shift;

                return undef if $done;

                if (defined($chunk)) {
                    push(@chunks, $chunk);
                    return '';
                }
                else {
                    $done = 1;
                    my ($output, $error) =
                        $self->_xform($stylesheet, \@chunks);
                    die($error) if defined($error);
                    return $output;
                }
            }
        }
    });
}

sub _xform {
    my ($self, $stylesheet, $body) = @_;

    if (!$parser) {
        my $options = $self->parser_options;
        $parser = $options
                ? XML::LibXML->new($options)
                : XML::LibXML->new;
    }

    my ($doc, $output, $error);

    if (ref($body) eq 'ARRAY') {
        $doc = $parser->parse_string(join('', @$body));
    }
    else {
        $doc = $parser->parse_fh($body);
    }

    my $result = try {
        $stylesheet->transform($doc) or die("XSLT transform failed: $!");
    }
    catch {
        $error = defined($_) ? $_ : 'Unknown error';
        undef;
    };

    $output = $stylesheet->output_as_bytes($result)
        if $result;

    return ($output, $error);
}

sub _cache_hits {
    my $self = shift;

    return $xslt->cache_hits
        if $xslt && $xslt->isa('XML::LibXSLT::Cache');

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::XSLT - XSLT transformations with Plack

=head1 VERSION

version 0.30

=head1 SYNOPSIS

    # in your .psgi

    enable 'XSLT';

    # in your app

    $env->{'xslt.style'} = 'stylesheet.xsl';

    return [ 200, $headers, [ $xml ] ];

=head1 DESCRIPTION

Plack::Middleware::XSLT converts XML response bodies to HTML, XML, or text
using XML::LibXSLT. The XSLT stylesheet is specified by the environment
variable 'xslt.style'. If this variable is undefined or empty, the response
is not altered. This rather crude mechanism might be enhanced in the future.

The Content-Type header is set according to xsl:output. Content-Length is
adjusted.

=head1 CONFIGURATION

=over 4

=item cache

    enable 'XSLT', cache => 1;

Enables caching of XSLT stylesheets. Defaults to false.

=item path

    enable 'XSLT', path => 'path/to/xsl/files';

Sets a path that will be prepended if xslt.style contains a relative path.
Defaults to the current directory.

=item parser_options

    enable 'XSLT', parser_options => \%options;

Options that will be passed to the XML parser when parsing the input
document. See L<XML::LibXML::Parser/"PARSER OPTIONS">.

=back

=head1 CREATING HTTP ERRORS WITH XSL:MESSAGE

If the transform exits via C<<xsl:message terminate="yes">> and the
message contains a line starting with a three-digit HTTP response status
code and an optional message, a corresponding HTTP error response is
created. For example:

    <xsl:message terminate="yes">404 Not found</xsl:message>

=head1 AUTHOR

Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
