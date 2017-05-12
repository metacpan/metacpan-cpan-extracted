package Plack::Debugger::Panel::DBIC::QueryLog;

use 5.006;
use strict;
use warnings;

use parent 'Plack::Debugger::Panel';
use Plack::Middleware::DBIC::QueryLog;
use Text::MicroTemplate;

=head1 NAME

Plack::Debugger::Panel::DBIC::QueryLog - DBIC query log panel for Plack::Debugger

=head1 VERSION

Version 0.002

=cut

our $VERSION = '0.002';

my $_template = join( '', <DATA> );

sub new {
    my $class = shift;
    my %args = @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    $args{title}     ||= 'DBIC::QueryLog';
    $args{formatter} ||= 'pass_through';

    $args{querylog_analyzer_class} ||= 'DBIx::Class::QueryLog::Analyzer';
    $args{sqla_tree_args}          ||= +{ profile => 'html' };
    $args{sqla_tree_class}         ||= 'SQL::Abstract::Tree';

    $args{'after'} = sub {
        my ( $self, $env, $resp ) = @_;

        my $querylog       = $self->find_or_create_querylog($env);
        my $analyzer       = $self->querylog_analyzer_for($querylog);
        my @sorted_queries = @{ $analyzer->get_sorted_queries || [] };

        if (@sorted_queries) {
            my %args = (
                count          => $querylog->count,
                elapsed_time   => $querylog->time_elapsed,
                sorted_queries => [@sorted_queries],
                sql_formatter  => sub { $self->sqla_tree->format(@_) },
            );

            $self->set_subtitle(
                sprintf( 'Total Time: %.6f', $args{elapsed_time} ) );

            my $result = $self->template->(%args);
            $self->set_result("$result");
        }
        else {
            $self->set_subtitle("No SQL");
            $self->set_result("No DBIC log information");
        }
    };

    my $self = $class->SUPER::new( \%args );

    $self->{querylog_analyzer_class} = $args{querylog_analyzer_class};
    $self->{querylog_args}           = $args{querylog_args};
    $self->{querylog_class}          = $args{querylog_class};
    $self->{sqla_tree_args}          = $args{sqla_tree_args};
    $self->{sqla_tree_class}         = $args{sqla_tree_class};

    return $self;
}

sub find_or_create_querylog {
    my ( $self, $env ) = @_;
    Plack::Middleware::DBIC::QueryLog->get_querylog_from_env($env) || do {
        my %args = map { $_ => $self->{$_} } grep { $self->{$_} }
          qw(querylog_class querylog_args);

        Plack::Middleware::DBIC::QueryLog->new(%args)
          ->find_or_create_querylog_in($env);
    };
}

sub querylog_analyzer_for {
    my ( $self, $ql ) = @_;
    Plack::Util::load_class( $self->{querylog_analyzer_class} )
      ->new( { querylog => $ql } );
}

sub sqla_tree {
    my $self = shift;
    if ( !defined $self->{sqla_tree} ) {
        $self->{sqla_tree} = Plack::Util::load_class( $self->{sqla_tree_class} )
          ->new( $self->{sqla_tree_args} );
    }
    return $self->{sqla_tree};
}

sub template {
    my $self = shift;
    if ( !defined $self->{_template} ) {
        $self->{_template} = Text::MicroTemplate->new(
            template   => $_template,
            tag_start  => '<%',
            tag_end    => '%>',
            line_start => '%',
        )->build_mt;
    }

    #close DATA;
    return $self->{_template};
}

=head1 SYNOPSIS

Adds a debug panel and querylog object for logging DBIx::Class queries.

Has support for L<Catalyst> via a
L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog> compatible trait,
L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack>.

    use Plack::Builder;
 
    use JSON;
 
    use Plack::Debugger;
    use Plack::Debugger::Storage;
 
    use Plack::App::Debugger;
 
    use Plack::Debugger::Panel::DBIC::QueryLog;
    use ... # other Panels

    use DBICx::Sugar qw/schema/;
    use MyApp;  # your PSGI app (Dancer2 perhaps)

    # create middleware wrapper
    my $mw = sub {
        my $app = shift;
        sub {
            my $env = shift;
            my $querylog =
            Plack::Middleware::DBIC::QueryLog->get_querylog_from_env($env);
            my $cloned_schema = schema->clone;
            $cloned_schema->storage->debug(1);
            $cloned_schema->storage->debugobj($querylog);
            my $res = $app->($env);
            return $res;
        };
    };

    # wrap your app
    my $app = $mw->( MyApp->to_app );
 
    my $debugger = Plack::Debugger->new(
        storage => Plack::Debugger::Storage->new(
            data_dir     => '/tmp/debugger_panel',
            serializer   => sub { encode_json( shift ) },
            deserializer => sub { decode_json( shift ) },
            filename_fmt => "%s.json",
        ),
        panels => [
            Plack::Debugger::Panel::DBIC::QueryLog->new,     
            # ... other Panels
        ]
    );
 
    my $debugger_app = Plack::App::Debugger->new( debugger => $debugger );
 
    builder {
        mount $debugger_app->base_url => $debugger_app->to_app;
    
        mount '/' => builder {
            enable $debugger_app->make_injector_middleware;
            enable $debugger->make_collector_middleware;
            $app;
        }
    };

=head1 DESCRIPTION

This module provides a DBIC QueryLog panel for L<Plack::Debugger> with
query alaysis performed by L<DBIx::Class::QueryLog::Analyzer> (by default).

For full details of how to setup L<Catalyst> to use this panel and also for
a full background of the design of this module see
L<https://metacpan.org/pod/Plack::Middleware::Debug::DBIC::QueryLog>
which this module steals heavily from.

=head1 BUGS

Nowhere near enough docs and no tests so expect something to break somewhere.

This is currently 'works for me' quality.

Please report bugs via:

L<https://github.com/SysPete/Plack-Debugger-Panel-DBIC-QueryLog/issues>

=head1 SEE ALSO

L<Plack::Debugger>, L<Plack::Middleware::Debug::DBIC::QueryLog>,
L<Dancer2::Plugin::Debugger::Panel::DBIC::QueryLog>.

=head1 ACKNOWLEDGEMENTS

John Napiorkowski, C<< <jjnapiork@cpan.org> >> for L<Plack::Middleware::Debug::DBIC::QueryLog> from which most of this module was stolen.

=head1 AUTHOR

Peter Mottram (SysPete), C<< <peter at sysnix.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Peter Mottram (SysPete).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

__DATA__
% my (%args) = @_;
<style>
#plack-debugger .select { color:red }
#plack-debugger .insert-into { color:red }
#plack-debugger .delete-from { color:red }
#plack-debugger .where { color:green }
#plack-debugger .join { color:blue }
#plack-debugger .on { color:DodgerBlue  }
#plack-debugger .from { color:purple }
#plack-debugger .order-by { color:DarkCyan }
#plack-debugger .placeholder { color:gray }
</style>
<div>
  <br/>
  <p>
    <ul>
      <li>Total Queries Run: <b><%= $args{count} %></b></li>
      <li>Total SQL Statement Time: <b><%= sprintf('%.6f', $args{elapsed_time}) %> seconds</b></li>
      <li>Average Time per Statement: <b><%= sprintf('%.6f', ($args{elapsed_time} / $args{count})) %> seconds</b></li>
    </ul>
  </p>
  <table id="box-table-a">
    <thead class="query_header">
      <tr>
        <th style="padding-left:4px">Time</th>
        <th style="padding-left:15px; padding-right:15px">Percent</th>
        <th>SQL Statements</th>
      </tr>
    </thead>
    <tbody>
% my $even = 1;
% for my $q (@{$args{sorted_queries}}) {
%   my $tree_info = Text::MicroTemplate::encoded_string($args{sql_formatter}->($q->sql, $q->params));
       <tr <%= $even ? "class=plDebugOdd":"plDebugEven" %> >
        <td style="padding-left:8px"><%= sprintf('%.7f', $q->time_elapsed) %></td>
        <td style="padding-left:21px"><%= sprintf('%.2f', (($q->time_elapsed / $args{elapsed_time}) * 100)) %>%</td>
        <td style="padding-left:6px; padding-bottom:6px"><%= $tree_info %></td>
      </tr>
% $even = $even ? 0:1;
% }
    </tbody>
  </table>
</div>
<br/>
