package Sledge::Plugin::DebugMessage;
use strict;
use warnings;
our $VERSION = '0.04';

use Jcode;
use Data::Dumper;
use Template;

our $LOG_SIZE = 20;
our $TEMPLATE = <<'EOF';
    <div style="font-weight:bold;background-color:#ffccff;text-align:left;left-margin:3px">
        <h2>debug message</h2>
        <div style="color:red">
            [%- FOR v IN pages.session.param('_debug_msg') %]
            [% v.replace("\n", "") | html %]<br />
            [%- END %]
        </div>
        <h2>tmpl</h2>
        <table style="color:green;text-align:left">
            [%- FOR v IN pages.tmpl.param() %]
            <tr><th>[% v | html %]</th><td>[% pages.tmpl.param(v) | html %]</td></tr>
            [%- END %]
        </table>
        <h2>r</h2>
        <table style="color:magenta;text-align:left">
            [%- FOR v IN pages.r.param() %]
            <tr><th>[% v | html %]</th><td>[% pages.r.param(v) | html %]</td></tr>
            [%- END %]
        </table>
        <h2>session</h2>
        <table style="color:blue;text-align:left">
            [%- FOR v IN pages.session.param() %]
            <tr><th>[% v | html %]</th><td>[% pages.session.param(v) | html %]</td></tr>
            [%- END %]
        </table>
        <h2>last_mail</h2>
        <pre>[% last_mail | html %]</pre>
    </div></body>
EOF

sub import {
    my $class = shift;
    my $pkg   = caller;

    $pkg->register_hook(BEFORE_OUTPUT => sub {
        my $self = shift;
        if ($self->debug_level) {
            $self->add_filter(sub {
                $class->_debug_message_filter(@_);
            });
        }
    });

    no strict 'refs';
    *{"$pkg\::debug"} = \&debug;
}

sub debug {
    my $self = shift;
    my $msg  = shift;

    if ($self->debug_level) {
        my ($package, $filename, $line) = caller(0);
        my $page = $self->page || 'index';
        my $dumped = Dumper(@_);
        my $dbg_line = "$page, $package($line) : $msg : $dumped";
        if ($self->session) {
            $self->session->param(
                '_debug_msg' => [(
                    $dbg_line,
                    @{$self->session->param('_debug_msg') || []},
                )[0..$LOG_SIZE]]
            );
        }
    }
}

sub _debug_message_filter {
    my ($self, $pages, $content) = @_;

    my $last_mail = $pages->session ? Jcode->new($pages->session->param('last_mail') || '', 'jis')->euc : '';

    my $tt = Template->new;
    $tt->process(\$TEMPLATE, {pages => $pages, last_mail => $last_mail}, \my $out);
    $content =~ s{</body>}{$out};

    return $content;
}

1;
__END__

=head1 NAME

Sledge::Plugin::DebugMessage - show the debug message

=head1 SYNOPSIS

    package Your::Pages;
    use Sledge::Plugin::DebugMessage;

=head1 DESCRIPTION

Sledge::Plugin::DebugMessage is debug utility for Sledge.

You can see the request, template parameters, session parameters,
and any debug messages, in your HTML footer.

=head1 METHODS

=head2 debug

    $a->debug('USER' => $user);

set the debug message.

=head1 AUTHOR

MATSUNO Tokuhiro E<lt>tokuhirom@gmail.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Bundle::Sledge>, L<Sledge::Plugin::DebugScreen>

=cut
