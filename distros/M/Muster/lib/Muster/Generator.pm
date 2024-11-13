package Muster::Generator;
$Muster::Generator::VERSION = '0.92';
# ABSTRACT: Muster::Generator - generates boilerplate for muster webapp

=head1 NAME

Muster::Generator - generates boilerplate for muster webapp

=head1 VERSION

version 0.92

=cut

use Mojo::Base 'Mojolicious::Command';

=head2 init

Generate the boilerplate files.

=cut
sub init {
    my $self = shift;
    $self->generate_config_file;
    $self->generate_web_app;
}

=head2 generate_config_file

Generate a boilerplate muster.conf file

=cut
sub generate_config_file {
    shift->render_to_rel_file("muster.conf" => 'muster.conf');
}

=head2 generate_web_app

Generate a boilerplate webapp.pl file

=cut
sub generate_web_app {
    my $self = shift;
    $self->render_to_rel_file('webapp.pl' => 'webapp.pl');
    $self->chmod_rel_file('webapp.pl' => 0755);
}

1;

__DATA__

@@ muster.conf
{
    defaults => {
        title => 'Muster',
        footer => 'Muster FOOT',
        db => 'bookmarks',
    },
    hypnotoad => {
        pid_file => '/var/www/muster/muster.pid',
        listen => ['http://*:3002'],
        proxy => 1,
    },
    foil => {
        "localhost:3000" => {
            name => "morbo",
            logo_dark_url => app->url_for("/css/logos/muster_dark.png"),
            logo_light_url => app->url_for("/css/logos/muster_light.png"),
            default_theme => 'gblue2',
            navbar_host => 'localhost:3000',
            navbar_links => [qw(
                /home/
                /muster/
                )],
        },
        "localhost:3002" => {
            name => "hypnotoad",
            logo_dark_url => app->url_for("/css/logos/muster_dark.png"),
            logo_light_url => app->url_for("/css/logos/muster_light.png"),
            default_theme => 'cnblue',
            navbar_host => 'localhost:3002',
            navbar_links => [qw(
                /home/
                /muster/
                )],
        },
    },
    tables => {
        bookmarks => {
            database => '/home/foo/bookmarks.sql',
            public_dir => '/home/foo/bookmarks/contents/',
            table => 'filetable',
            columns => [qw(title url description tags linkdate)],
            default_sort => ['linkdate DESC'],
            extra_cond => '(private = "0" AND url NOT NULL AND tags GLOB "*howto*")',
            row_template => '
<li>
{?thumburl <div class="thumbnail"><img style="height:150px;" src="/db/bookmarks/view[$thumburl]" alt="[$title]"/></div>}
<div class="linkcontainer">
<span class="linktitle"><a href="{$url}">{?title [$title]!![$url]}</a></span>
<div class="linkdescription">
{?description [$description:html]}
</div>
<div class="details">{$linkdate}</div>
{?all_tags <div class="linktaglist">[$all_tags]</div>}
</div>
</li>
',
        },
    },
}

@@ webapp.pl
#!/usr/bin/env perl
use strict;
use warnings;

# Start command line interface for application
require Mojolicious::Commands;
Mojolicious::Commands->start_app('Muster');

__END__
