#!/usr/bin/env perl

use strict;
use warnings;

package Example;

use base qw(Plack::Component::Tags::HTML);

use Data::HTML::Footer;
use Tags::HTML::Table::View;
use Tags::HTML::Footer;

sub _cleanup {
        my ($self, $env) = @_;

        $self->{'_tags_table'}->cleanup;
        $self->{'_tags_footer'}->cleanup;

        return;
}

sub _css {
        my ($self, $env) = @_;

        $self->{'_tags_table'}->process_css;
        $self->{'_tags_footer'}->process_css;

        return;
}

sub _prepare_app {
        my $self = shift;

        $self->SUPER::_prepare_app();

        my %p = (
                'css' => $self->{'css'},
                'tags' => $self->{'tags'},
        );
        $self->{'_tags_table'} = Tags::HTML::Table::View->new(%p);
        $self->{'_tags_footer'} = Tags::HTML::Footer->new(%p);

        # Data object for footer.
        $self->{'_footer_data'} = Data::HTML::Footer->new(
                'author' => 'John',
                'author_url' => 'https://example.com',
                'copyright_years' => '2022-2024',
                'height' => '40px',
                'version' => '0.07',
                'version_url' => '/changes',
        );

        # Data for table.
        $self->{'_table_data'} = [
                ['name', 'surname'],
                ['John', 'Wick'],
                ['Jan', 'Novak'],
        ];

        return;
}

sub _process_actions {
        my ($self, $env) = @_;

        # Init.
        $self->{'_tags_footer'}->init($self->{'_footer_data'});
        $self->{'_tags_table'}->init($self->{'_table_data'}, 'no data');

        return;
}

sub _tags_middle {
        my ($self, $env) = @_;

        $self->{'tags'}->put(
                ['b', 'div'],
                ['a', 'id', '#main'],
        );
        $self->{'_tags_table'}->process;
        $self->{'tags'}->put(
                ['e', 'div'],
        );

        $self->{'_tags_footer'}->process;

        return;
}

package main;

use CSS::Struct::Output::Indent;
use Plack::Runner;
use Tags::Output::Indent;

my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new(
        'xml' => 1,
        'preserved' => ['style'],
);
my $app = Example->new(
        'css' => $css,
        'tags' => $tags,
)->to_app;
Plack::Runner->new->run($app);

# Output screenshot is in images/ directory.