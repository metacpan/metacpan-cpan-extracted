package Sledge::Plugin::DebugScreen;
use strict;
use warnings;
our $VERSION = '0.08';
use 5.008001;

use Template;
use Devel::StackTrace;
use IO::File;

{
    package Sledge::Exception::StackTrace;
    sub print_context {
        my $self = shift;
        my($file, $linenum) = ($self->file, $self->line);
        my $code;
        if (-f $file) {
            my $start = $linenum - 3;
            my $end   = $linenum + 3;
            $start = $start < 1 ? 1 : $start;
            if (my $fh = IO::File->new($file, 'r')) {
                my $cur_line = 0;
                while (my $line = <$fh>) {
                    ++$cur_line;
                    last if $cur_line > $end;
                    next if $cur_line < $start;
                    my @tag = $cur_line == $linenum ? qw(<b> </b>) : ('', '');
                    $code .= sprintf(
                        '%s%5d: %s%s',
                            $tag[0], $cur_line, $self->_html_escape($line), $tag[1],
                    );
                }
            }
        }
        return $code;
    }

    sub _html_escape {
        my ($self, $str) = @_;
        $str =~ s/&/&amp;/g;
        $str =~ s/</&lt;/g;
        $str =~ s/>/&gt;/g;
        $str =~ s/"/&quot;/g;
        return $str;
    }
}

our $TEMPLATE = q{
<?xml version="1.0" encoding="euc-jp"?>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja-JP" lang="ja-JP">
    <head>
        <title>Error in [% title | html %]</title>
        <style type="text/css">
            body {
                font-family: "Bitstream Vera Sans", "Trebuchet MS", Verdana,
                            Tahoma, Arial, helvetica, sans-serif;
                color: #000;
                background-color: #F5131A;
                margin: 0px;
                padding: 0px;
            }
            :link, :link:hover, :visited, :visited:hover {
                color: #000;
            }
            div.box {
                position: relative;
                background-color: #fff;
                border: 1px solid #aaa;
                padding: 4px;
                margin: 10px;
                -moz-border-radius: 10px;
            }
            div.infos {
                background-color: #fff;
                border: 3px solid #FBEE1A;
                padding: 8px;
                margin: 4px;
                margin-bottom: 10px;
                -moz-border-radius: 10px;
            }
            h1 {
                margin: 0;
            }
            h2 {
                margin-top: 0;
                margin-bottom: 10px;
                font-size: medium;
                font-weight: bold;
                text-decoration: underline;
            }
            div.url {
                font-size: x-small;
            }
            pre {
                font-size: .8em;
                line-height: 120%;
                font-family: 'Courier New', Courier, monospace;
                background-color: #fee;
                color: #333;
                border: 1px dotted #000;
                padding: 5px;
                margin: 8px;
                width: 90%;
            }
            pre b {
                font-weight: bold;
                color: #000;
                background-color: #f99;
            }
        </style>
    </head>
    <body>
        <div class="box">
            <h1>[% title | html %]</h1>

            <div class="url">[% pages.current_url | html %]</div>

            <div class="infos">
                [% desc | html %]<br />
            </div>

            <div class="infos">
                <h2>StackTrace</h2>
                <table>
                    <tr>
                        <th>Package</th>
                        <th>Line   </th>
                        <th>File   </th>
                    </tr>
                    [% FOR s IN stacktrace -%]
                        <tr>
                            <td>[% s.pkg  | html %]</td>
                            <td>[% s.line | html %]</td>
                            <td>[% s.file | html %]</td>
                        </tr>
                        <tr>
                            <td colspan="3"><pre>[% s.print_context %]</pre></td>
                        </tr>
                    [%- END %]
                </table>
            </div>
        </div>
    </body>
</html>
};

sub import {
    my $self = shift;
    my $pkg  = caller;

    no strict 'refs';

    {
        my $super = $pkg->can('dispatch');
        *{"$pkg\::dispatch"} = sub {
            my $self = shift;
            local $SIG{__DIE__} = sub {
                $self->{__stacktrace} = [map {Sledge::Exception::StackTrace->new(
                    file => $_->filename, line => $_->line, pkg => $_->package,
                )} Devel::StackTrace->new->frames ];
                die @_; # rethrow
            };
            $self->$super(@_);
        };
    }

    *{"$pkg\::handle_exception"} = \&_handle_exception;
}

sub _handle_exception {
    my ($self, $E) = @_;

    return if $self->finished;

    if ($self->debug_level) {
        warn $E;

        my $vars = {
            title => ref $self || $self,
            desc  => "$E",
            pages => $self,
        };

        if (ref $E and $E->can('stacktrace')) {
            $vars->{stacktrace} = $E->stacktrace;
        } else {
            $vars->{stacktrace} = $self->{__stacktrace};
            shift @{$vars->{stacktrace}};
        }

        my $tmpl = Template->new;
        my $output;
        $tmpl->process(\$TEMPLATE,  $vars, \$output);

        $self->r->content_type('text/html');
        $self->set_content_length(length $output);
        $self->r->status($self->SERVER_ERROR);
        $self->send_http_header;
        $self->r->print($output);
        $self->finished(1);
    } else {
        die $E;
    }
}

1;
__END__

=head1 NAME

Sledge::Plugin::DebugScreen - show the debug screen if crashed

=head1 SYNOPSIS

    package Your::Pages;
    use Sledge::Plugin::DebugScreen;
    sub debug_level {
        return $ENV{'DEBUG_MODE'} ? 1 : 0;
    }

=head1 DESCRIPTION

This plugin shows the debug screen if crashed, like Catalyst.
The debug screen is only showing debug mode.

Screen image: L<http://image.blog.livedoor.jp/nipotan/imgs/a/2/a2b67309.jpg>

=head1 AUTHOR

    MATSUNO Tokuhiro <tokuhirom@gmail.com>
    Koichi Taniguchi <taniguchi@livedoor.jp>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 THANKS TO

Jiro Nishiguchi.

=head1 TODO

more tests.

=head1 DEPENDENCIES

L<Template>, L<Bundle::Sledge>, L<Devel::StackTrace>

=head1 SEE ALSO

L<Catalyst::Plugin::StackTrace>

=cut
