package Mojolicious::Command::generate::resources;
use Mojo::Base 'Mojolicious::Command', -signatures;

use Mojo::Util qw(class_to_path decamelize camelize);
use Getopt::Long qw(GetOptionsFromArray :config auto_abbrev
  gnu_compat no_ignore_case);
File::Spec::Functions->import(qw(catfile catdir));

our $AUTHORITY = 'cpan:BEROV';
our $VERSION   = '0.05';

has args => sub { {} };
has description     => 'Generate resources from database for your application';
has usage           => sub { shift->extract_usage };
has _templates_path => '';
has '_db_helper';

has routes => sub {
  $_[0]->{routes} = [];
  foreach my $t (@{$_[0]->args->{tables}}) {
    my $controller = camelize($t);
    my $route      = decamelize($controller);
    push @{$_[0]->{routes}},
      {
       route => "/$route",
       via   => ['GET'],
       to    => "$route#index",
       name  => "home_$route"
      },
      {
       route => "/$route/create",
       via   => ['GET'],
       to    => "$route#create",
       name  => "create_$route",
      },
      {
       route => "/$route/:id",
       via   => ['GET'],
       to    => "$route#show",
       name  => "show_$route"
      },
      {
       route => "/$route",
       via   => ['POST'],
       to    => "$route#store",
       name  => "store_$route",
      },
      {
       route => "/$route/:id/edit",
       via   => ['GET'],
       to    => "$route#edit",
       name  => "edit_$route"
      },
      {
       route => "/$route/:id",
       via   => ['PUT'],
       to    => "$route#update",
       name  => "update_$route"
      },
      {
       route => "/$route/:id",
       via   => ['DELETE'],
       to    => "$route#remove",
       name  => "remove_$route"
      };
  }
  return $_[0]->{routes};
};

my $_начевамъ = sub {
  my ($азъ, @args) = @_;
  return $азъ if $азъ->{_initialised};
  my $args = $азъ->args({tables => []})->args;

  GetOptionsFromArray(
    \@args,
    'C|controller_namespace=s' => \$args->{controller_namespace},
    'L|lib=s'                  => \$args->{lib},
    'M|model_namespace=s'      => \$args->{model_namespace},

    # TODO: 'O|overwrite'              => \$args->{overwrite},
    'T|templates_root=s' => \$args->{templates_root},
    't|tables=s@'        => \$args->{tables},
    'H|home_dir=s'       => \$args->{home_dir},
                     );

  @{$args->{tables}} = split(/\s*?\,\s*?/, join(',', @{$args->{tables}}));
  Carp::croak $азъ->usage unless scalar @{$args->{tables}};

  my $app = $азъ->app;
  $args->{controller_namespace} //= $app->routes->namespaces->[0];
  $args->{model_namespace}      //= ref($app) . '::Model';
  $args->{home_dir}             //= $app->home;
  $args->{lib}                  //= catdir($args->{home_dir}, 'lib');
  $args->{templates_root}       //= $app->renderer->paths->[0];

  # Find templates.
  # TODO: Look into renderer->paths for user-defined/modified templates
  for my $path (@INC) {
    my $templates_path
      = catdir($path, 'Mojolicious/resources/templates/mojo/command/resources');
    if (-d $templates_path) {
      $азъ->_templates_path($templates_path);
      last;
    }
  }

  # Find the used database helper. One of sqlite, pg, mysql
  my @db_helpers = qw(sqlite pg mysql);
  for (@db_helpers) {
    if ($app->renderer->get_helper($_)) {
      $азъ->_db_helper($_);
      last;
    }
  }
  if (!$азъ->_db_helper) {
    die <<'MSG';
Guessing the used database wrapper helper failed. One of (@db_helpers) is
required. This application does not use any of the supported database helpers.
One of Mojo::Pg, Mojo::mysql or Mojo::SQLite must be used to generate models.
Aborting!..
MSG
  }

  $азъ->{_initialised} = 1;

  return $азъ;
};


sub run {
  my ($self) = shift->$_начевамъ(@_);
  my $args   = $self->args;
  my $app    = $self->app;

  my $wrapper_helpers = '';
  my $tmpls_path      = $self->_templates_path;
  for my $t (@{$args->{tables}}) {

    my $class_name = camelize($t);

    # Models
    my $mclass        = "$args->{model_namespace}::$class_name";
    my $m_file        = catfile($args->{lib}, class_to_path($mclass));
    my $table_columns = $self->_get_table_columns($t);
    my $template_args = {
                         %$args,
                         class     => $mclass,
                         t         => lc $t,
                         db_helper => $self->_db_helper,
                         columns   => $table_columns,
                        };
    my $tmpl_file = catfile($tmpls_path, 'm_class.ep');
    $self->render_template_to_file($tmpl_file, $m_file, $template_args);

    # Controllers
    my $class = "$args->{controller_namespace}::$class_name";
    my $c_file = catfile($args->{lib}, class_to_path($class));
    $template_args
      = {%$args, class => $class, t => lc $t, columns => $table_columns};
    $tmpl_file = catfile($tmpls_path, 'c_class.ep');
    $self->render_template_to_file($tmpl_file, $c_file, $template_args);

    # Templates
    my $template_dir  = decamelize($class_name);
    my $template_root = $args->{templates_root};

    my @views = qw(index create show edit _form);
    for my $v (@views) {
      my $t_file = catfile($template_root, $template_dir, $v . '.html.ep');
      my $tmpl_file = catfile($tmpls_path, $v . '.html.ep');
      $self->render_template_to_file($tmpl_file, $t_file, $template_args);
    }

    # Helpers
    $template_args
      = {%$args, t => lc $t, db_helper => $self->_db_helper, class => $mclass};
    $tmpl_file = catfile($tmpls_path, 'helper.ep');
    $wrapper_helpers
      .= Mojo::Template->new->render_file($tmpl_file, $template_args);
  }    # end foreach tables

  # Routes
  my $template_args
    = {%$args, helpers => $wrapper_helpers, routes => $self->routes};
  my $tmpl_file = catfile($tmpls_path,       'TODO.ep');
  my $todo_file = catfile($args->{home_dir}, 'TODO');
  $self->render_template_to_file($tmpl_file, $todo_file, $template_args);
  return $self;
}

# Returns an array reference of columns from the table
sub _get_table_columns ($self, $table) {
  state $db_helper = $self->_db_helper;
  my $col_info
    = $self->app->$db_helper->db->dbh->column_info(undef, undef, $table, '%')
    ->fetchall_arrayref({});
  my @columns = map { $_->{COLUMN_NAME} } @$col_info;
  return \@columns;
}

sub render_template_to_file {
  my ($self, $filename, $path) = (shift, shift, shift);
  my $out = Mojo::Template->new->render_file($filename, @_);
  return $self->write_file($path, $out);
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::generate::resources - Resources from database for your application

=head1 SYNOPSIS

  Usage: APPLICATION generate resources [OPTIONS]

    my_app.pl generate help resources # help with all available options
    my_app.pl generate resources --tables users,groups


=head1 DESCRIPTION

I<This is an early release.>
L<Mojolicious::Command::generate::resources> generates directory structure for
a fully functional
L<MVC|Mojolicious::Guides::Growing/"Model View Controller">
L<set of files|Mojolicious::Guides::Growing/"REpresentational State Transfer">,
and L<routes|Mojolicious::Guides::Routing>
based on existing tables in your application's database. 

This tool's purpose is to promote
L<RAD|http://en.wikipedia.org/wiki/Rapid_application_development> by generating
the boilerplate code for model (M), templates (V) and controller (C) and help
programmers to quickly create well structured, fully functional applications.
It assumes that you already have tables created in a database and you just want
to generate
L<CRUD|https://en.wikipedia.org/wiki/Create,_read,_update_and_delete> actions
for them.

In the generated actions you will find eventually working code for reading,
creating, updating and deleting records from the tables you specified on the
command-line. The generated code is just boilerplate to give you a jump start,
so you can concentrate on writing your business-specific code. It is assumed
that you will modify the generated code to suit your specific needs. All the
generated code is produced from templates which you also can put in your
application renderer's path and modify to your taste.

The command expects to find and will use one of the commonly used helpers
C<pg>, C<mysql> C<sqlite>. The supported wrappers are respectively L<Mojo::Pg>,
L<Mojo::mysql> and L<Mojo::SQLite>.

=head1 OPTIONS

Below are the options this command accepts, described in Getopt::Long notation.
Both short and long variants are shown as well as the types of values they
accept. All of them, beside C<--tables>, are guessed from your application and
usually do not need to be specified.


=head2 C|controller_namespace=s

Optional. The namespace for the controller classes to be generated. Defaults to
C<app-E<gt>routes-E<gt>namespaces-E<gt>[0]>, usually L<MyApp::Controller>, where
MyApp is the name of your application. If you decide to use another namespace
for the controllers, do not forget to add it to the list
C<app-E<gt>routes-E<gt>namespaces> in C<myapp.conf> or your plugin
configuration file. Here is an example.

  # Setting the Controller class from which all controllers must inherit.
  # See /perldoc/Mojolicious/#controller_class
  # See /perldoc/Mojolicious/Guides/Growing#Controller-class
  app->controller_class('MyApp::C');

  # Namespace(s) to load controllers from
  # See /perldoc/Mojolicious#routes
  app->routes->namespaces(['MyApp::C']);

=head2 H|home_dir=s

Optional. Defaults to C<app-E<gt>home> (which is MyApp home directory). Used to
set the root directory to which the files will be dumped.

=head2 L|lib=s

Optional. Defaults to C<app-E<gt>home/lib> (relative to the C<--home_dir>
directory). If you installed L<MyApp> in some custom path and you wish to
generate your controllers into e.g. C<site_lib>, set this option.

=head2 M|model_namespace=s

Optional. The namespace for the model classes to be generated. Defaults to
L<MyApp::Model>.

=head2 T|templates_root=s

Optional. Defaults to C<app-E<gt>renderer-E<gt>paths-E<gt>[0]>. This is usually
C<app-E<gt>home/templates> directory. If you want to use another directory, do
not forget to add it to the C<app-E<gt>renderer-E<gt>paths> list in your
configuration file. Here is how to add a new directory to
C<app-E<gt>renderer-E<gt>paths> in C<myapp.conf>.

    # Application/site specific templates
    # See /perldoc/Mojolicious/Renderer#paths
    unshift @{app->renderer->paths}, $home->rel_file('site_templates');

=head2 t|tables=s@

Mandatory. List of tables separated by commas for which controllers should be generated.


=head1 SUPPORT

Please report bugs, contribute and make merge requests on
L<Github|https://github.com/kberov/Mojolicious-Command-generate-resources>.

=head1 ATTRIBUTES

L<Mojolicious::Command::generate::resources> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 args

Used for storing arguments from the commandline template.

  my $args = $self->args;

=head2 description

  my $description = $command->description;
  $command        = $command->description('Foo!');

Short description of this command, used for the commands list.

=head2 routes

  $self->routes();

Returns an ARRAY reference containing routes, prepared after
C<$self-E<gt>args-E<gt>{tables}>. Suggested Perl code for the routes is dumped
in a file named TODO in C<--homedir> so you can copy and paste into your
application code.

=head2 usage

  my $usage = $command->usage;
  $command  = $command->usage('Foo!');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::generate::resources> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  Mojolicious::Command::generate::resources->new(app=>$app)->run(@ARGV);

Run this command.

=head1 TODO

The work on the features may not go in the same order specified here. Some
parts may be fully implemented while others may be left for later.

    - Improve documentation. Tests.
    - Tests for templates (views).
    - Tests for model classes.
    - Test the generated routes.
    - Implement generation of Open API specification out from
      tables' metadata. More tests.

=head1 AUTHOR

    Красимир Беров
    CPAN ID: BEROV
    berov@cpan.org
    http://i-can.eu

=head1 COPYRIGHT

This program is free software licensed under

  Artistic License 2.0

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Mojolicious::Command::generate>,
L<Mojolicious::Command>,
L<Mojolicious>,
L<Perl|https://www.perl.org/>.

=cut

