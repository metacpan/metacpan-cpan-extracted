package Plack::Middleware::Debug::Template;

use strict;
use warnings;

=head1 NAME

Plack::Middleware::Debug::Template - storing profiling information
on template use.

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS
 
To activate this panel:
 
    plack_middlewares:
      Debug:
        - panels
        -
          - Template
 
Or in your app.psgi, something like:
 
    builder {
        enable 'Debug', panels => ['Template'];
        $app;
    };
 
=head1 DESCRIPTION
 
This middleware adds timers around calls to L<Template::Context/process>
to track the time spent rendering the template and the layout for the page.
 
=head1 HOOKS

Subclass this module and implement the below functions if you wish to change
its behaviour.

=head2 show_pathname

Return true if the panel should show the path name rather than the template
name, or false to have the path name in a title attribute.

=cut

sub show_pathname {}

=head2 hook_pathname

This function can alter the full template path name provided to it for display.

=cut

sub hook_pathname {}

=head2 ignore_template

If you don't want output for any particular template, test for it here.
Return true to ignore.

=cut

sub ignore_template {}

# Main code

use parent qw(Plack::Middleware::Debug::Base);
use Class::Method::Modifiers qw/install_modifier/;
use Data::Dumper;
use Text::MicroTemplate;
use Time::HiRes qw(gettimeofday tv_interval);

# A quasi-dump, that expands arrayrefs and hashrefs but doesn't try and
# include any object contents

sub _pp {
    my $t = shift;
    my $r = ref $t;
    if ($r eq 'ARRAY') {
        return [ map { _pp($_) } @$t ];
    } elsif ($r eq 'HASH') {
        return { map { $_ => _pp($t->{$_}) } keys %$t };
    } elsif ($r) {
        return $r;
    } else {
        return $t;
    }
}

# Convert the given stash into a representation that can be output
# in the debug panel

sub _stash {
    my ($self, $stash) = @_;
    local $Data::Dumper::Terse = 1;
    return {
        map {
            my $p = _pp($stash->{$_});
            $_ => ref $p ? Dumper($p) : $p
        }
        grep {
            ref $stash->{$_} ne 'CODE'
        }
        keys %$stash
    };
}

sub _diff_disp {
    my $starting_point = shift;
    return sprintf( '%.3f', tv_interval($starting_point) * 1000 );
}

my $list_template = __PACKAGE__->build_template(<<'EOTMPL');
<style>
#plDebug span.line-chart { background-color: #0af; position: absolute; top: 0; bottom: 0; display: block; }
#plDebug span.line-desc { position: relative; }
#plDebug span.line-dur { position: absolute; right: 0; }
#plDebug #pmd-template { border-collapse: separate; border-spacing: 0 1px; }
#plDebug #pmd-template td { position: relative; }
</style>
% foreach my $tmpl (@{$_[0]}) {
<h3><%= $tmpl->{title} %></h3>
% my $i;
<table id="pmd-template">
    <thead>
        <tr>
            <th width="100%">Template</th>
            <th>Time&nbsp;(ms)</th>
        </tr>
    </thead>
    <tbody>
% foreach my $line (@{$tmpl->{list}}) {
    <tr class="<%= ++$i % 2 ? 'plDebugEven' : 'plDebugOdd' %>">
        <td>
% if (defined $line->{offset_pc}) {
            <span class="line-chart" style="left: <%= $line->{offset_pc} %>%; width: <%= $line->{duration_pc} %>%"></span>
% }
            <span class="line-desc">
                <%= Text::MicroTemplate::encoded_string('&nbsp;' x 4 x $line->{depth}) %>
% if ($line->{path}) {
                <span title="<%= $line->{path} %>">
% }
                    <%= $line->{name} %>
% if ($line->{path}) {
                </span>
% }
                <%= $line->{vars} || "" %>
            </span>
        </td>
        <td>
            <%= $line->{duration} || "" %>
        </td>
    </tr>
% }
    </tbody>
</table>
<h4>Stash</h4>
<table>
    <thead>
        <tr>
            <th>Key</th>
            <th>Value</th>
        </tr>
    </thead>
    <tbody>
% foreach my $key (sort keys %{$tmpl->{stash}}) {
        <tr>
            <td><%= $key %></td>
            <td><%= $tmpl->{stash}->{$key} || "" %></td>
        </tr>
% }
    </tbody>
</table>
% }
EOTMPL

my $env_key = 'psgi.middleware.template';

our $depth = 0;
our $epoch = undef;

my %template_to_path;

# Sets up a wrapper to Template::Context's process and Template::Provider's
# _fetch, to record start/end times, variables, and the stash, and to get the
# full file path.
sub run {
    my ($pmd, $env, $panel) = @_;

    $env->{$env_key} = [];

    install_modifier 'Template::Context', 'around', 'process', sub {
        my $orig = shift;
        my $self = shift;
        my $what = shift;

        my $template =
            ref($what) eq 'ARRAY'
                ? join( ' + ', @{$what} )
                : ref($what)
                    ? $what->name
                    : $what;

        return $orig->($self, $what, @_) if $pmd->ignore_template($template);

        my $processed_data;
        my $epoch_elapsed_start;
        my $epoch_elapsed_end;
        my $now   = [gettimeofday];
        my $start = [@{$now}];
        my $env = $env->{$env_key};

        my $entry;
        if ($depth == 0) {
            $entry = { title => $template, stash => {}, list => [], total => 0 };
            push @$env, $entry;
        } else {
            $entry = $env->[-1];
        }

        my $results = { depth => $depth, name => $template };
        push @{$entry->{list}}, $results;
        DOIT: {
            local $epoch = $epoch ? $epoch : [@{$now}];
            local $depth = $depth + 1;
            $epoch_elapsed_start = _diff_disp($epoch);
            $processed_data = $orig->($self, $what, @_);
            $epoch_elapsed_end = _diff_disp($epoch);
        }
        my $level_elapsed = _diff_disp($start);
        my $vars = join ", ", map { "$_=" . $_[0]->{$_} } keys %{$_[0]};
        $results->{start} = $epoch_elapsed_start;
        $results->{end} = $epoch_elapsed_end;
        $results->{duration} = $level_elapsed;
        $results->{vars} = $vars;

        return $processed_data if $depth > 0;

        # Okay, we've finished our tree of templates now

        $entry->{total} = $results->{duration};
        my $main_start = $results->{start};
        foreach (@{$entry->{list}}) {
            next unless $_->{start};
            $_->{offset_pc} = ($_->{start} - $main_start) / $entry->{total} * 100;
            $_->{duration_pc} = ($_->{end} - $_->{start}) / $entry->{total} * 100;
            if ($pmd->show_pathname) {
                $_->{name} = $template_to_path{$_->{name}} || $_->{name};
            } else {
                $_->{path} = $template_to_path{$_->{name}};
            }
        }

        $entry->{stash} = $pmd->_stash($self->stash);

        return $processed_data;
    };
    install_modifier 'Template::Provider', 'around', '_fetch', sub {
        my $orig = shift;
        my ($tp_self, $name, $t_name) = @_;
        if (my $hooked = $pmd->hook_pathname($name)) {
            $name = $hooked;
        }
        $template_to_path{$t_name} = $name;
        return $orig->(@_);
    };

    return sub {
        my $res = shift;
        $panel->title('Templates');
        my $total = 0;
        foreach (@{$env->{$env_key}}) {
            $total += $_->{total};
        }
        $panel->nav_subtitle("$total ms") if $total;
        $panel->content($pmd->render($list_template, $env->{$env_key}));
    };
}

=head1 SUPPORT

You can look for information on GitHub at
L<https://github.com/mysociety/Plack-Middleware-Debug-Template>.

=head1 ACKNOWLEDGEMENTS

This module is based on a combination of
Plack::Middleware::Debug::Dancer::TemplateTimer and Template::Timer.

=head1 AUTHOR

Matthew Somerville, C<< <matthew at mysociety.org> >>

=head1 LICENSE AND COPYRIGHT
 
Copyright 2017 Matthew Somerville.
 
This library is free software; you can redistribute it and/or modify
it under the terms of either the GNU Public License v3, or the Artistic
License 2.0. See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
