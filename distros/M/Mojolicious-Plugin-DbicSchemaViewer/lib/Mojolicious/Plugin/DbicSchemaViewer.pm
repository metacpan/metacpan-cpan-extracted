use strict;
use warnings;

package Mojolicious::Plugin::DbicSchemaViewer;

# ABSTRACT: Viewer for DBIx::Class schema definitions
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0200';

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Home;
use File::ShareDir 'dist_dir';
use Path::Tiny;
use Data::Dump::Streamer;
use Safe::Isa;
use DateTime::Tiny;
use PerlX::Maybe;
use List::Util qw/none/;
use DBIx::Class::Visualizer;

use experimental qw/signatures postderef/;

has schemas => sub { +{} };
has allowed_schemas => sub { [] };

sub register($self, $app, $conf) {
    $app->plugin('BootstrapHelpers');

    # Check configuration
    if(exists $conf->{'router'} && exists $conf->{'condition'}) {
        my $exception = "Can't use both 'router' and 'condition' in M::P::DbicSchemaViewer";
        $app->log->fatal($exception);
        $app->reply->exception($exception);
        return;
    }
    # Preload all (if any) allowed schemas
    if(exists $conf->{'allowed_schemas'} && scalar $conf->{'allowed_schemas'}->@*) {
        $self->allowed_schemas->@* = $conf->{'allowed_schemas'}->@*;

        for my $allowed ($self->allowed_schemas->@*) {
            if(eval "require $allowed") {
                $self->schemas->{ $allowed } = $allowed->connect;
            }
        }
    }

    # set MOJO_DBIC_SCHEMA_VIEWER_LOCAL to a true value to use the template in the distribution
    # rather than those installed
    my $dirroot = $ENV{'MOJO_DBIC_SCHEMA_VIEWER_LOCAL'} ? path(Mojo::Home->new->rel_dir('share'))
                                                        : path(dist_dir('Mojolicious-Plugin-DbicSchemaViewer'))
                                                        ;


    # add our template directory
    my $template_dir = $dirroot->child('templates');

    if($template_dir->is_dir) {
        push $app->renderer->paths->@* => $template_dir->realpath;
        $app->log->debug(sprintf '[M::P::DbicSchemaViewer] Adds %s to renderer paths', $template_dir->stringify);
    }

    my $router = exists $conf->{'router'}    ?  $conf->{'router'}
               : exists $conf->{'condition'} ?  $app->routes->over($conf->{'condition'})
               :                                $app->routes
               ;

    my $url = $conf->{'url'} || 'dbic-schema-viewer';

    push @{ $app->static->paths }, $dirroot->child('public')->stringify;


    # Routes
    my $base = $router->get($url);

    # home / schema
    $base->get('/:schema')->to(cb => sub ($c) {
        my $schema = $self->get_schema($app, $c);

        if(!defined $schema) {
            $c->flash(bad_schema => 1);
            $c->redirect_to('home');
            return;
        }

        $self->render($c, 'overview', db => $self->schema_info($schema), title => ref $schema);
    })->name('overview');

    # visualizer
    $base->get('visualizer/:schema')->to(cb => sub ($c) {
        my $schema = $self->get_schema($app, $c);
        if(!defined $schema) {
            $c->flash(bad_schema => 1);
            $c->redirect_to('home');
            return;
        }

        my(%wanted_result_source_names, %skip_result_source_names);

        if($c->param('wanted_result_source_names')) {
            my $wanted_result_source_names = [split /,/ => $c->param('wanted_result_source_names')];
            %wanted_result_source_names = scalar $wanted_result_source_names->@* ? (wanted_result_source_names => $wanted_result_source_names) : ();
        }
        if($c->param('skip_result_source_names')) {
            my $skip_result_source_names = [split /,/ => $c->param('skip_result_source_names')];
            %skip_result_source_names = scalar $skip_result_source_names->@* ? (skip_result_source_names => $skip_result_source_names) : ();
        }

        $self->render($c, 'visualizer',
            title => ref $schema,
            svg => DBIx::Class::Visualizer->new(
                      schema => $schema,
                      %wanted_result_source_names,
                      %skip_result_source_names,
                maybe degrees_of_separation => $c->param('degrees_of_separation'),
                maybe only_keys => $c->param('only_keys'),
            )->transformed_svg
        );
    })->name('visualizer');

    # Reconnect all schemas, useful when schemas are updated.
    $base->get('refresh/:schema/:destination')->to(cb => sub ($c) {
        foreach my $schema (keys $self->schemas->%*)  {
            if(eval "require $schema") {
                $c->app->log->debug(qq{M::P::DbicSchemaViewer reconnects with $schema});
                $self->schemas->{ $schema } = $schema->connect;
            }
        }
        $c->redirect_to($c->param('destination'));
    })->name('refresh');

    # home
    $base->get('/')->to(cb => sub ($c) {
        $c->redirect_to('overview', schema => $c->param('schema')) && return if $c->param('schema');
        $self->render($c, 'home', title => 'Home', bad_schema => $c->param('bad_schema'));
    })->name('home');

}

sub render($self, $c, $template, @args) {
    my %layout = (layout => 'plugin-dbic-schema-viewer-default');
    $c->render(%layout, template => "viewer/$template", @args, all_schemas => $self->schemas);
}

sub get_schema {
    my $self = shift;
    my $app = shift;
    my $c = shift;

    my $schema;
    if($c->param('schema')) {
        if(scalar $self->allowed_schemas->@* && (none { $c->param('schema') eq $_ } $self->allowed_schemas->@*)) {
            $app->log->warn($c->param('schema') . ' is not in the list of allowed schemas');
        }
        if(exists $self->schemas->{ $c->param('schema') }) {
            return $self->schemas->{ $c->param('schema') };
        }
        elsif(eval "require @{[ $c->param('schema') ]}") {
            $schema = ($c->param('schema'))->connect;
        }
        else {
            $app->log->warn("Could not load @{[ $c->param('schema') ]}");
        }
    }
    else {
        $app->log->warn(q{M::P::DbicSchemaViewer is missing mandatory 'schema' parameter.});
        return;
    }

    if($schema->$_isa('DBIx::Class::Schema')) {
        $self->schemas->{ $c->param('schema') } = $schema;
    }
    else {
        $app->log->warn("'schema' must be an DBIx::Class::Schema instance in M::P::DbicSchemaViewer, @{[ $c->param('schema') ]} is not");
        return;
    }
    return $schema;
}
sub schema_info($self, $schema) {

    my $db = { sources => [] };

    # put View:: result sources last
    my @sorted_sources = sort grep { !/^View::/ } $schema->sources;
    push @sorted_sources => sort grep { /^View::/ } $schema->sources;

    foreach my $source_name (@sorted_sources) {
        my $rs = $schema->resultset($source_name)->result_source;

        my $uniques = {};
        my %unique_constraints = $rs->unique_constraints;

        foreach my $unique_constraint (keys %unique_constraints) {
            foreach my $column ($unique_constraints{ $unique_constraint }->@*) {
                if(!exists $uniques->{ $column }) {
                    $uniques->{ $column } = [];
                }
                push $uniques->{ $column }->@* => $unique_constraint;
            }
        }
        my $clean_name = lc $source_name =~ s{::}{_}gr;

        my $source = {
            name => $source_name,
            clean_name => $clean_name,
            primary_columns => [$rs->primary_columns],
            unique_constraints => [$rs->unique_constraints],
            uniques => $uniques,
            columns_info => [],
            relationships => [],
        };

        foreach my $column_name ($rs->columns) {
            my $column_info = { $rs->column_info($column_name)->%* };
            my $data_type = delete $column_info->{'data_type'};
            $data_type = $column_info->{'is_enum'} && scalar $column_info->{'extra'}{'list'}->@* ? "enum/$data_type" : $data_type;

            push $source->{'columns'}->@* => {
                name => $column_name,
                $column_info->%*,
                data_type => $data_type,
            };
        }

        foreach my $relation_name (sort $rs->relationships) {
            my $relation = $rs->relationship_info($relation_name);
            my $class_name = $relation->{'class'} =~ s{^.*?::Result::}{}r;

            my $condition;
            # simple one column to one column relation: this_result_id => relation_name.that_result_id
            if(ref $relation->{'cond'} eq 'HASH' && scalar keys $relation->{'cond'}->%* == 1) {
                my @cleaned_condition = ((values $relation->{'cond'}->%*)[0] =~ s{^self\.}{}rx);
                push @cleaned_condition => (keys $relation->{'cond'}->%*)[0] =~ s{^foreign(?=\.)}{$relation_name}rx;
                $condition = join ' => ', @cleaned_condition;
            }
            # more complicated relation: dump relation to text and remove boilerplate
            else {
                $condition = Dump($relation->{'cond'})->Out;

                # cleanup the dump
                $condition =~ s{^.*?\{}{\{};
                $condition =~ s{\n\s*?package .*?\n}{\n};
                $condition =~ s{\n\s*?BEGIN.*?\n}{\n};
                $condition =~ s{\n\s*?use strict.*?\n}{\n}g;
                $condition =~ s{\n\s*?use feature.*?\n}{\n}g;
                $condition =~ s{\n\s*?no feature.*?\n}{\n}g;
                $condition =~ s{\n\s{3,}\}}{\n\}};
                $condition =~ s{\n\s{8,8}}{\n    }g;
            }

            my $on_cascade = [ sort map { $_ =~ s{^cascade_}{}rm } grep { m/^cascade/ && $relation->{'attrs'}{ $_ } } keys $relation->{'attrs'}->%* ];

            # do not reorder
            my $relation_type = $relation->{'attrs'}{'accessor'} eq 'multi' ? 'has_many'
                              : $relation->{'attrs'}{'is_depends_on'}       ? 'belongs_to'
                              : exists $relation->{'attrs'}{'join_type'}    ? 'might_have'
                              :                                               'has_one'
                              ;

            push $source->{'relationships'}->@* => {
                name => $relation_name,
                class_name => $class_name,
                clean_name => lc $class_name =~ s{::}{_}rg,
                condition => $condition,
                on_cascade => $on_cascade,
                $relation->%*,
                relation_type => $relation_type,
                has_reverse_relation => keys $rs->reverse_relationship_info($relation_name)->%* ? 1 : 0,
            };
        }

        push $db->{'sources'}->@* => $source;
    }
    return $db;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::DbicSchemaViewer - Viewer for DBIx::Class schema definitions



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.20+-blue.svg" alt="Requires Perl 5.20+" />
<a href="https://travis-ci.org/Csson/p5-Mojolicious-Plugin-DbicSchemaViewer"><img src="https://api.travis-ci.org/Csson/p5-Mojolicious-Plugin-DbicSchemaViewer.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/Mojolicious-Plugin-DbicSchemaViewer-0.0200"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/Mojolicious-Plugin-DbicSchemaViewer/0.0200" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Mojolicious-Plugin-DbicSchemaViewer%200.0200"><img src="http://badgedepot.code301.com/badge/cpantesters/Mojolicious-Plugin-DbicSchemaViewer/0.0200" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-59.0%-red.svg" alt="coverage 59.0%" />
</p>

=end html

=head1 VERSION

Version 0.0200, released 2016-09-20.

=head1 SYNOPSIS

    $self->plugin(DbicSchemaViewer => {
        schema => Your::Schema->connect(...),
    });

=head1 DESCRIPTION

This plugin is a definition viewer for L<DBIx::Class> schemas. It currently offers two different views on the schema:

=over 4

=item *

It lists all result sources with column definitions and and their relationships in table form.

=item *

It uses  L<DBIx::Class::Visualizer> to generate an entity-relationship model.

=back

=head2 Configuration

The following settings are available. It is recommended to use either L</router> or L</condition> to place the viewer behind some kind of authorization check.

=head3 allowed_schemas

An optional array reference consisting of schema classes. If set, only these classes are available for viewing.

If not set, all findable schema classes can be viewed.

=head3 url

Optional.

By default, the viewer is located at C</dbic-schema-viewer>.

    $self->plugin(DbicSchemaViewer => {
        url => '/the-schema',
        schema => Your::Schema->connect(...),
    });

The viewer is instead located at C</the-schema>.

Note that the CSS and Javascript files are served under C</dbic-schema-viewer> regardless of this setting.

=head3 router

Optional. Can not be used together with L</condition>.

Use this when you which to place the viewer behind an C<under> route:

    my $secure = $app->routes->under('/secure' => sub {
        my $c = shift;
        return defined $c->session('logged_in') ? 1 : 0;
    });

    $self->plugin(DbicSchemaViewer => {
        router => $secure,
        schema => Your::Schema->connect(...),
    });

Now the viewer is located at C</secure/dbic-schema-viewer> (if the check is successful).

=head3 condition

Optional. Can not be used together with L</router>.

Use this when you have a named condition you which to place the viewer behind:

    $self->routes->add_condition(random => sub { return !int rand 4 });

    $self->plugin(DbicSchemaViewer => {
        condition => 'random',
        schema => Your::Schema->connect(...),
    });

=head1 DEMO

There is a demo available at L<http://dsv.code301.com/MadeUp::Book::Schema>. Don't miss the help page for instructions.

=head1 SEE ALSO

=over 4

=item *

C<dbic-schema-viewer> - a small application (in C</bin>) for running this plugin standalone.

=item *

L<DBIx::Class::Visualizer>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Mojolicious-Plugin-DbicSchemaViewer>

=head1 HOMEPAGE

L<https://metacpan.org/release/Mojolicious-Plugin-DbicSchemaViewer>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
