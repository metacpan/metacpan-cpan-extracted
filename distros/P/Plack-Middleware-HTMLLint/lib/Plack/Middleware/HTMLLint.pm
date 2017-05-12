package Plack::Middleware::HTMLLint;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.03';

use parent qw/ Plack::Middleware /;

use constant +{
    PSGI_STATUS  => 0,
    PSGI_HEADER  => 1,
    PSGI_BODY    => 2,
};

use constant +{
    SYNTAX_HTML5 => 'html5',
    SYNTAX_HTML4 => 'html4',
    SYNTAX_XHTML => 'xhtml',
};

use Plack::Util;
use Plack::Util::Accessor qw/error2html/;
use HTML::Lint;
use HTML::Escape qw/escape_html/;

sub prepare_app {
    my $self = shift;
    unless ($self->error2html) {
        $self->error2html(sub {
            my @errors = @_;

            my @error_html;
            push @error_html => '<div style="border: double 3px; background-color: rgba(255, 0, 0, 0.2); margin: 3px; padding: 2px;">';
            push @error_html => '<h4 style="color: red">HTML&nbsp;Error</h4>';
            push @error_html => '<dl>';
            foreach my $error (@errors) {
                push @error_html => '<dt style="margin-left: 0.25em">', escape_html($error->errcode), '</dt>';
                push @error_html => '<dd style="padding-top: 0.25em; border-bottom: 1px solid #cccc00">', escape_html($error->as_string), '</dd>';
            }
            push @error_html => '</dl>';

            push @error_html => '</div>';

            return join '', @error_html;
        });
    }
}

sub call {
    my($self, $env) = @_;

    return $self->response_cb($self->app->($env), sub {
        my $res = shift;
        my $content_type = Plack::Util::header_get($res->[PSGI_HEADER], 'Content-Type') || '';

        if ($content_type =~ m{^(?:text/x?html|application/xhtml\+xml)\b}io) {# HTML/XHTML
            my $do_lint = sub {
                my $content = shift;

                my $syntax = ($content =~ /^<!DOCTYPE html>$/imo)                             ? SYNTAX_HTML5:
                             ($content_type =~ m{^(?:text/xhtml|application/xhtml\+xml)\b}io) ? SYNTAX_XHTML:
                             SYNTAX_HTML4;

                if (my @errors = $self->html_lint($syntax => $content)) {
                    return $self->error2html->(@errors);
                }
                else {
                    return '';
                }
            };

            if ($res->[PSGI_BODY]) {
                my $content = '';
                Plack::Util::foreach($res->[PSGI_BODY] => sub { $content .= $_[0] });
                if (my $error_html = $do_lint->($content)) {
                    unless ($content =~ s{<body([^>]*)>}{<body$1>$error_html}i) {
                        ## fallback
                        $content .= $error_html;
                    }
                    $res->[PSGI_BODY] = [$content];
                }
            }
            else {
                # XXX: It has become increasingly complex not to block the stream as possible.
                my $buffer           = '';
                my $html_last_buffer = '';
                my $end_of_html_body = 0;
                my $do_lint_finished = 0;
                return sub {
                    my $body_chunk = shift;
                    if (defined $body_chunk) {
                        $buffer .= $body_chunk;
                        if ($end_of_html_body || $body_chunk =~ m{</body>}io) {
                            $end_of_html_body = 1;
                            $html_last_buffer .= $body_chunk;
                            return '';
                        }
                        else {
                            return $body_chunk;
                        }
                    }
                    else {
                        if ($do_lint_finished) {
                            return;
                        }
                        else {
                            my $error_html = $do_lint->($buffer);
                            if ($error_html) {
                                unless ($html_last_buffer =~ s{</body>}{$error_html</body>}i) {
                                    ## fallback
                                    $html_last_buffer = $error_html . $html_last_buffer;
                                }
                            }

                            $do_lint_finished = 1;
                            return $html_last_buffer;
                        }
                    }
                };
            }
        }

        return;
    });
}

sub html_lint {
    my($self, $syntax, $content) = @_;

    my $lint = HTML::Lint->new;
    $lint->parse($content);
    $lint->eof;

    return $lint->errors;
}

1;
__END__

=head1 NAME

Plack::Middleware::HTMLLint - check syntax with HTML::Lint for PSGI application's response HTML

=head1 VERSION

This document describes Plack::Middleware::HTMLLint version 0.03.

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable_if { $ENV{PLACK_ENV} eq 'development' } 'HTMLLint';
        sub {
            my $env = shift;
            # ...
            return [
                200,
                ['Content-Type' => 'text/plain'],
                ['<html><head>...']
            ];
        };
    };

=head1 DESCRIPTION

This module check syntax with HTML::Lint for PSGI application's response HTML.
to assist you to discover the HTML syntax errors during the development of Web applications.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Plack::Middleware> L<Plack::Middleware::HTMLLint::Pluggable> L<HTML::Lint> L<HTML::Lint::Pluggable>

=head1 AUTHOR

Kenta Sato E<lt>karupa@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, Kenta Sato. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
