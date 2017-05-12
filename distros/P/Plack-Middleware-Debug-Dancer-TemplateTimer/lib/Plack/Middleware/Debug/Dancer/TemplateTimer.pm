package Plack::Middleware::Debug::Dancer::TemplateTimer;

=head1 NAME

Plack::Middleware::Debug::Dancer::TemplateTimer - Template and layout rendering timer for Dancer

=head1 VERSION

0.001

=cut

our $VERSION = '0.001';

use strict;
use warnings;
use parent qw(Plack::Middleware::Debug::Base);
use Class::Method::Modifiers qw/install_modifier/;
use Time::HiRes qw/gettimeofday tv_interval/;

use Dancer;

my $env_key = 'debug.dancer.templatetimer';

sub prepare_app {

    install_modifier 'Dancer::Template::Abstract', 'around', 'layout', sub {
        my $orig  = shift;
        my $start = [gettimeofday];
        my $ret   = $orig->(@_);
        my $end   = [gettimeofday];
        Dancer::SharedData->request->env->{$env_key}->{layout} +=
          tv_interval( $start, $end );
        return $ret;
    };

    install_modifier 'Dancer::Template::Abstract', 'around', 'render', sub {
        my $orig  = shift;
        my $start = [gettimeofday];
        my $ret   = $orig->(@_);
        my $end   = [gettimeofday];
        Dancer::SharedData->request->env->{$env_key}->{template} +=
          tv_interval( $start, $end );
        return $ret;
    };
}

my $list_template_dumped = __PACKAGE__->build_template(<<'EOTMPL');
<table>
    <thead>
        <tr>
            <th>Key</th>
            <th>Value</th>
        </tr>
    </thead>
    <tbody>
% my $i;
% foreach my $key (qw| template layout total |) {
%     next unless defined $_[0]->{vars}->{$key};
        <tr>
            <td><%= $key %></td>
            <td><%= $_[0]->{vars}->{$key} %></td>
        </tr>
% }
    </tbody>
</table>
EOTMPL

sub run {
    my ( $self, $env, $panel ) = @_;
 
    return sub {
        my $res = shift;
        $panel->title('Dancer::TemplateTimer');
        my %vars = %{ $env->{$env_key} || {} };
        foreach my $key ( keys %vars ) {
            $vars{total} += $vars{$key};
        }
        if ( $vars{total} ) {
            $panel->nav_subtitle($vars{total});
        }
        $panel->content(
            $self->render( $list_template_dumped, { vars => \%vars } ) );
    };
}

1;

__END__
=pod

=head1 SYNOPSIS

To activate this panel:

    plack_middlewares:
      Debug:
        - panels
        -
          - Dancer::TemplateTimer

Or by manually creating an app.psgi, that might contain:

    builder {
        enable 'Debug', panels => ['Dancer::TemplateTimer'];
        $app;
    };

=head1 DESCRIPTION

This middleware adds timers around calls to L<Dancer::Template::Abstract/render>
and L<Dancer::Template::Abstract/layout> to track the time spent rendering
the template and the layout for the page.

This module uses L<Class::Method::Modifiers/install_modifier> rather than
adding hooks since we want to be sure we are only timing the template engine
and not other code inside hooks.

=head1 AUTHOR

Peter Mottram (SysPete), C<< <peter at sysnix.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Peter Mottram (SysPete).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
