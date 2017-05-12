package Plack::Middleware::Debug::DBIC::QueryLog;

use Moo;
use Text::MicroTemplate;
use Plack::Middleware::DBIC::QueryLog;
use 5.008008;

extends 'Plack::Middleware::Debug::Base';

our $VERSION = '0.09';

has 'sqla_tree_class' => (
  is => 'ro',
  default => sub {'SQL::Abstract::Tree'},
);

has 'sqla_tree_args' => (
  is => 'ro',
  default => sub { +{profile => 'html'} },
);

has 'sqla_tree' => (
  is => 'ro',
  lazy => 1,
  builder => '_build_sqla_tree',
);

sub _build_sqla_tree {
  Plack::Util::load_class($_[0]->sqla_tree_class)
    ->new($_[0]->sqla_tree_args);
}

has 'querylog_class' => ( is => 'ro' );
has 'querylog_args' => ( is => 'ro' );

has template => (
  is => 'ro',
  builder => '_build_template',
);

sub _build_template {
  __PACKAGE__->build_template(join '', <DATA>);
}

has 'querylog_analyzer_class' => (
  is => 'ro',
  default => sub { 'DBIx::Class::QueryLog::Analyzer' },
);

sub querylog_analyzer_for {
  my ($self, $ql) = @_;
  Plack::Util::load_class($_[0]->querylog_analyzer_class)
    ->new({querylog => $ql});
}

sub find_or_create_querylog {
  my ($self, $env) = @_;
  Plack::Middleware::DBIC::QueryLog->get_querylog_from_env($env) || do {
    my %args = map { $_ => $self->$_ } grep { $self->$_ }
      qw(querylog_class querylog_args);

    Plack::Middleware::DBIC::QueryLog->new(%args)
      ->find_or_create_querylog_in($env);
  };
}

sub run {
  my ($self, $env, $panel) = @_;
  my $querylog = $self->find_or_create_querylog($env);
  $panel->title('DBIC::QueryLog');

  return sub {
    my $analyzer = $self->querylog_analyzer_for($querylog);
    my @sorted_queries = @{$analyzer->get_sorted_queries||[]};

    if(@sorted_queries) {
      my %args = (
        count => $querylog->count,
        elapsed_time => $querylog->time_elapsed,
        sorted_queries => [@sorted_queries],
        sql_formatter => sub { $self->sqla_tree->format(@_) },
      );
      $panel->nav_subtitle(sprintf('Total Time: %.6f', $args{elapsed_time}));
      $panel->content($self->template->(%args));
    } else {
      $panel->nav_subtitle("No SQL");
      $panel->content("No DBIC log information");
    }
  };
}

=head1 NAME

Plack::Middleware::Debug::DBIC::QueryLog - DBIC Query Log and Query Analyzer

=head1 SYNOPSIS

Adds a debug panel and querylog object for logging L<DBIx::Class> queries.  Has
support for L<Catalyst> via a L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog>
compatible trait, L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack>.

    use Plack::Builder;

    my $app = ...; ## Build your Plack App

    builder {
      enable 'Debug', panels =>['DBIC::QueryLog'];
      $app;
    };

And in you L<Catalyst> application, if you are also using
L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack>

    package MyApp::Web::Model::Schema;
    use Moose;
    extends 'Catalyst::Model::DBIC::Schema';

    __PACKAGE__->config({
      schema_class => 'MyApp::Schema',
      traits => ['QueryLog::AdoptPlack'],
      ## .. rest of configuration
    });

=head1 DESCRIPTION

L<DBIx::Class::QueryLog> is a tool in the L<DBIx::Class> software ecosystem
which benchmarks queries.  It lets you log the SQL that L<DBIx::Class>
is generating, along with bind variables and timestamps.  You can then pass
the querylog object to an analyzer (such as L<DBIx::Class::QueryLog::Analyzer>)
to generate sorted statistics for all the queries between certain log points.

Query logging in L<Catalyst> is supported for L<DBIx::Class> via a trait for
L<Catalyst::Model::DBIC::Schema> called
L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog>.  This trait will
log all the SQL used by L<DBIx::Class> for a given request cycle.  This is very
useful since it can help you identify troublesome or bottlenecking queries.

However, L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog> does not provide
out of the box outputting of your analyzed query logs.  Usually you need to
add a bit of templating work to the bottom of your webpage footer, or dump the
output to the logs.  We'd like to provide a lower ceremony experience.

Additionally, it would be nice if we could provide this functionality for all
L<Plack> based applications, not just L<Catalyst>.  Ideally we'd play nice with
L<Plack::Middleware::Debug> so that the table of our querylog would appear as
a neat Plack based Debug panel.  This bit of middleware provides that function.

Basically we create a new instance of L<DBIx::Class::QueryLog> and place it
into C<< $env->{'plack.middleware.dbic.querylog'} >> (We use the underlying
features in L<Plack::Middleware::DBIC::QueryLog>) so that it is accessible by
all applications running inside of L<Plack>.  You need to 'tell' your application's
instance of L<DBIx::Class> to use this C<$env> key and make sure you set
L<DBIx::Class>'s debug object correctly.  The officially supported interface for
this in via the supporting class L<Plack::Middleware::DBIC::QueryLog>:

    use Plack::Middleware::DBIC::QueryLog;

    my $querylog = Plack::Middleware::DBIC::QueryLog->get_querylog_from_env($env);
    my $cloned_schema = $schema->clone;
    $cloned_schema->storage->debug(1);
    $cloned_schema->storage->debugobj($querylog);

In this example C<$env> is a L<Plack> environment, typically passed into your PSGI
compliant application and C<$schema> is an instance of L<DBIx::Class::Schema>

We clone C<$schema> to avoid associating the querylog with the global, persistant
DBIC schema object.

Then you need to enable the Debug panel, as in the L<\SYNOPSIS>.  That way when
you view the debug panel, we have SQL to review.

There's an application in '/example' you can review for help.  However, if you
are using L<Catalyst> and a modern L<Catalyst::Model::DBIC::Schema> you can use
the trait L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack>,
which is compatible with L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog>.

If you want a querylog but don't want or need the L<Plack> debug panel, you
should take a look at L<Plack::Middleware::DBIC::QueryLog>.

See the L</SYNOPSIS> example for more details.

=head1 OPTIONS

This debug panel defines the following options.

=head2 querylog_class

This is the class which is used to build the C<querylog> unless one is already
defined.  It defaults to L<DBIx::Class::QueryLog>.  You should probably leave
this alone unless you need to subclass or augment L<DBIx::Class::QueryLog>.

If the class name you pass has not already been included (via C<use> or
C<require>) we will automatically try to C<require> it.

=head2 querylog_args

Takes a HashRef which is passed to L<DBIx::Class::QueryLog> at construction.

=head1 SEE ALSO

L<Plack::Middleware::Debug>, L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog>,
L<Catalyst::Model::DBIC::Schema>, L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack>

=head1 AUTHOR

John Napiorkowski, C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2011 John Napiorkowski

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__DATA__
% my (%args) = @_;
<style>
  #plDebug .select { color:red }
  #plDebug .insert-into { color:red }
  #plDebug .delete-from { color:red }
  #plDebug .where { color:green }
  #plDebug .join { color:blue }
  #plDebug .on { color:DodgerBlue  }
  #plDebug .from { color:purple }
  #plDebug .order-by { color:DarkCyan }
  #plDebug .placeholder { color:gray }
</style>
<div>
  <br/>
  <p>
    <ul>
      <li>Total Queries Ran: <b><%= $args{count} %></b></li>
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


