package Plack::Middleware::WOVN;
use strict;
use warnings;
use utf8;
use parent 'Plack::Middleware';

our $VERSION = '0.09';

require bytes;

use HTML::HTML5::Parser;
use HTML::HTML5::Writer;
use Mojo::URL;
use Plack::Util;
use Plack::Util::Accessor qw( settings );
use URI::Escape;
use XML::LibXML;

use Plack::Middleware::WOVN::Headers;
use Plack::Middleware::WOVN::Lang;
use Plack::Middleware::WOVN::Store;

our $STORE;

sub prepare_app {
    my $self = shift;
    $STORE = Plack::Middleware::WOVN::Store->new(
        { settings => $self->settings } );
}

sub call {
    my ( $self, $env ) = @_;

    unless ( $STORE->is_valid_settings ) {
        return $self->app->($env);
    }

    my $headers
        = Plack::Middleware::WOVN::Headers->new( $env, $STORE->settings );
    if (   $STORE->settings->{test_mode}
        && $STORE->settings->{test_url} ne $headers->url )
    {
        return $self->app->($env);
    }

    if ( $headers->path_lang eq $STORE->settings->{default_lang} ) {
        my $redirect_headers
            = $headers->redirect( $STORE->settings->{default_lang} );
        return [ 307, [%$redirect_headers], [''] ];
    }
    my $lang = $headers->lang_code;

    my $res = $self->app->( $headers->request_out );
    Plack::Util::response_cb(
        $res,
        sub {
            my $res = shift;

            sub {
                my $body_chunk  = shift or return;
                my $status      = $res->[0];
                my $res_headers = $res->[1];

                if ((   Plack::Util::header_get( $res_headers,
                            'Content-Type' )
                        || ''
                    ) =~ /html/
                    )
                {
                    my $values = $STORE->get_values( $headers->redis_url );
                    my $url    = {
                        protocol => $headers->protocol,
                        host     => $headers->host,
                        pathname => $headers->pathname,
                    };
                    $body_chunk
                        = switch_lang( $body_chunk, $values, $url, $lang,
                        $headers )
                        unless $status =~ /^1|302/;
                }

                Plack::Util::header_set( $res_headers, 'Content-Length',
                    bytes::length $body_chunk );

                $body_chunk;
            };
        }
    );
}

sub add_lang_code {
    my ( $href, $pattern, $lang, $headers ) = @_;
    return $href if $href =~ /^(#.*)?$/;

    my $new_href = $href;
    my $lc_lang  = lc $lang;

    if ( $href && lc($href) =~ /^(https?:)?\/\// ) {
        my $uri = eval { Mojo::URL->new($href) } or return $new_href;

        if ( lc $uri->host eq lc $headers->host ) {
            if ( $pattern eq 'subdomain' ) {
                my $sub_d = $href =~ /\/\/([^\.]*)\./ ? $1 : '';
                my $sub_code
                    = Plack::Middleware::WOVN::Lang->get_code($sub_d);
                if ( $sub_code && lc $sub_code eq $lc_lang ) {
                    $new_href =~ s/$lang/$lc_lang/i;
                }
                else {
                    $new_href =~ s/(\/\/)([^\.]*)/$1$lc_lang\.$2/;
                }
            }
            elsif ( $pattern eq 'query' ) {
                if ( $href =~ /\?/ ) {
                    $new_href = "$href&wovn=$lang";
                }
                else {
                    $new_href = "$href?wovn=$lang";
                }
            }
            else {
                $new_href =~ s/([^\.]*\.[^\/]*)(\/|$)/$1$lang/;
            }
        }
    }
    elsif ($href) {
        if ( $pattern eq 'subdomain' ) {
            my $lang_url
                = $headers->protocol . '://'
                . $lc_lang . '.'
                . $headers->host;
            my $current_dir = $headers->pathname;
            $current_dir =~ s/[^\/]*\.[^\.]{2,6}$//;
            if ( $href =~ /^\.\..*$/ ) {
                $new_href =~ s/^(\.\.\/)+//;
                $new_href = $lang_url . '/' . $new_href;
            }
            elsif ( $href =~ /^\..*$/ ) {
                $new_href =~ s/^(\.\/)+//;
                $new_href = $lang_url . $current_dir . '/' . $new_href;
            }
            elsif ( $href =~ /^\/.*$/ ) {
                $new_href = $lang_url . $href;
            }
            else {
                $new_href = $lang_url . $current_dir . '/' . $href;
            }
        }
        elsif ( $pattern eq 'query' ) {
            if ( $href =~ /\?/ ) {
                $new_href = "$href&wovn=$lang";
            }
            else {
                $new_href = "$href?wovn=$lang";
            }
        }
        else {
            if ( $href =~ /^\// ) {
                $new_href = '/' . $lang . $href;
            }
            else {
                my $current_dir = $headers->pathname;
                $current_dir =~ s/[^\/]*\.[^\.]{2,6}$//;
                $new_href = '/' . $lang . $current_dir . $href;
            }
        }
    }

    $new_href;
}

sub check_wovn_ignore {
    my $node = shift;
    if ( !$node->isa('XML::LibXML::Text') ) {
        if ( defined $node->getAttribute('wovn-ignore') ) {
            $node->setAttribute( 'wovn-ignore', '' )
                if $node->getAttribute('wovn-ignore') eq 'wovn-ignore';
            return 1;
        }
        elsif ( $node->nodeName eq 'html' ) {
            return 0;
        }
    }
    if ( !$node->getParentNode ) {
        return 0;
    }
    check_wovn_ignore( $node->getParentNode );
}

sub switch_lang {
    my ( $body, $values, $url, $lang, $headers ) = @_;
    $lang ||= $STORE->settings->{'default_lang'};
    $lang = Plack::Middleware::WOVN::Lang->get_code($lang);
    my $text_index     = $values->{text_vals}      || {};
    my $src_index      = $values->{img_vals}       || {};
    my $img_src_prefix = $values->{img_src_prefix} || '';
    my $string_index   = {};

    my $tree = HTML::HTML5::Parser->load_html( string => $body );
    $tree->setEncoding('UTF-8');

    my $writer = HTML::HTML5::Writer->new(
        quote_attributes => 1,
        voids            => 1,
        start_tags       => 1,
        end_tags         => 1
    );

    if ( $tree->documentElement->hasAttribute('wovn-ignore') ) {
        $body =~ s/href="([^"]*)"/"href=\"".uri_unescape($1)."\""/eg;
        return $body;
    }

    if ( $lang ne $STORE->settings->{default_lang} ) {
        for my $node ( $tree->findnodes("//*[local-name()='a']") ) {
            next if check_wovn_ignore($node);
            my $href = $node->getAttribute('href');
            my $new_href
                = add_lang_code( $href, $STORE->settings->{url_pattern},
                $lang, $headers );
            $node->setAttribute( 'href', $new_href );
        }
    }

    for my $node ( $tree->findnodes('//text()') ) {
        next if check_wovn_ignore($node);
        my $node_text = $node->getValue;
        $node_text =~ s/^\s+|\s+$//g;
        if (   $text_index->{$node_text}
            && $text_index->{$node_text}{$lang}
            && @{ $text_index->{$node_text}{$lang} } )
        {
            my $data    = $text_index->{$node_text}{$lang}[0]{data};
            my $content = $node->getValue;
            $content =~ s/^(\s*)[\S\s]*(\s*)$/$1$data$2/g;
            $node->setData($content);
        }
    }

    for my $node ( $tree->findnodes("//*[local-name()='meta']") ) {
        next if check_wovn_ignore($node);
        next
            if ( $node->getAttribute('name')
            || $node->getAttribute('property')
            || '' )
            !~ /^(description|title|og:title|og:description|twitter:title|twitter:description)$/;

        my $node_content = $node->getAttribute('content');
        $node_content =~ s/^\s+\|\s+$//g;
        if (   $text_index->{$node_content}
            && $text_index->{$node_content}{$lang}
            && @{ $text_index->{$node_content}{$lang} } )
        {
            my $data    = $text_index->{$node_content}{$lang}[0]{data};
            my $content = $node->getAttribute('content');
            $content =~ s/^(\s*)[\S\s]*(\s*)$/$1$data$2/g;
            $node->setAttribute( 'content', $content );
        }
    }

    for my $node ( $tree->findnodes("//*[local-name()='img']") ) {
        next if check_wovn_ignore($node);
        if ( lc( $writer->element($node) ) =~ /src=['"]([^'"]*)['"]/ ) {
            my $src = $1;
            if ( $src !~ /:\/\// ) {
                if ( $src =~ /^\// ) {
                    $src = $url->{protocol} . '://' . $url->{host} . $src;
                }
                else {
                    $src
                        = $url->{protocol} . '://'
                        . $url->{host}
                        . $url->{path}
                        . $src;
                }
            }

            if (   $src_index->{$src}
                && $src_index->{$src}{$lang}
                && @{ $src_index->{$src}{$lang} } )
            {
                $node->setAttribute( 'src',
                    $img_src_prefix . $src_index->{$src}{$lang}[0]{data} );
            }
        }
        if ( my $alt = $node->getAttribute('alt') ) {
            $alt =~ s/^\s+|\s+$//g;
            if (   $text_index->{$alt}
                && $text_index->{$alt}{$lang}
                && @{ $text_index->{$alt}{$lang} } )
            {
                my $data = $text_index->{$alt}{$lang}[0]{data};
                $alt =~ s/^(\s*)[\S\s]*(\s*)$/$1$data$2/g;
                $node->setAttribute( 'alt', $alt );
            }
        }
    }

    for my $node ( $tree->findnodes("//*[local-name()='script']") ) {
        if (   $node->getAttribute('src')
            && $node->getAttribute('src')
            =~ /\/\/j.(dev-)?wovn.io(:3000)?\// )
        {
            $node->getParentNode->removeChild($node);
        }
    }

    my ($parent_node) = $tree->getElementsByTagName('head');
    ($parent_node) = $tree->getElementByTagName('body') unless $parent_node;
    $parent_node = $tree->doucmentElement unless $parent_node;

    {
        my $insert_node = XML::LibXML::Element->new('script');
        $insert_node->setAttribute( 'src',   '//j.wovn.io/1' );
        $insert_node->setAttribute( 'async', 'true' );
        my $data_wovnio
            = 'key='
            . $STORE->settings->{user_token}
            . '&backend=true&currentLang='
            . $lang
            . '&defaultLang='
            . $STORE->settings->{default_lang}
            . '&urlPattern='
            . $STORE->settings->{url_pattern}
            . '&version='
            . $VERSION;
        $insert_node->setAttribute( 'data-wovnio', $data_wovnio );
        $insert_node->appendText(' ');
        $parent_node->insertBefore( $insert_node, $parent_node->firstChild );
    }

    for my $l ( get_langs($values) ) {
        my $insert_node = XML::LibXML::Element->new('link');
        $insert_node->setAttribute( 'rel',      'alternate' );
        $insert_node->setAttribute( 'hreflang', $l );
        $insert_node->setAttribute( 'href', $headers->redirect_location($l) );
        $parent_node->appendChild($insert_node);
    }

    my $html = $tree->documentElement;
    $html->setAttribute( 'lang', $lang ) if $html;

    my $new_body = $writer->document($tree);
    $new_body =~ s/href="([^"]*)"/'href="'.uri_unescape($1).'"'/eg;

    $new_body;
}

sub get_langs {
    my $values = shift;
    my %langs;
    my %merged
        = ( %{ $values->{text_vals} || {} }, %{ $values->{img_vals} || {} } );
    for my $index ( values %merged ) {
        for my $key ( keys %{ $index || {} } ) {
            $langs{$key} = 1;
        }
    }
    keys %langs;
}

1;

__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::WOVN - Translates PSGI application by using WOVN.io.

=head1 SYNOPSYS

  use Plack::Builder;

  builder {
    'WOVN',
      settings => {
        user_token => 'token',
        secret_key => 'sectet',
      };
    $app;
  };

=head1 DESCRIPTION

This is a Plack Middleware component for translating PSGI application by using WOVN.io.
Before using this middleware, you must sign up and configure WOVN.io.

This is a port of wovnjava (https://github.com/wovnio/wovnjava).

=head1 SETTINGS

=head2 user_token

User token of your WOVN.io account. This value is required.

=head2 secret_key

This value will be used in the future. But this value is required.

=head2 url_pattern

URL rewriting pattern of translated page.

=over 4

=item * path (default)

  original: http://example.com/

  translated: http://example.com/ja/

=item * subdomain

  original: http://example.com/

  translated: http://ja.exmple.com/

=item * query

  original: http://example.com/

  translated: http://example.com/?wovn=ja

=back

=head2 url_pattern_reg

This value is coufigured by url_pattern. You don't have to configure this value.

=head2 query

Filters query parameters when rewriting URL. Default values is []. (Do not filter query)

=head2 api_url

URL of WOVN.io API. Default value is "https://api.wovn.io/v0/values".

=head2 default_lang

Default language of web application. Default value is "en".

=head2 supported_langs

This value will be used in the future. Default value is ["en"].

=head2 test_mode

When "on" or "1" is set to "test_mode", this middleware translates only the page whose url is "test_url".
Default value is "0".

=head2 test_url

Default value is not set.

=head1 LICENSE

MIT License

Copyright (c) 2016 Minimal Technologies, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=head1 AUTHOR

Masahiro Iuchi

=cut
