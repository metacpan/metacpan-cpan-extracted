package Mojolicious::Command::static;
use Mojo::Base 'Mojolicious::Command';

# This command is a copy of Mojolicious::Command::daemon

use Mojo::File 'path';
use Mojo::Server::Daemon;
use Mojo::Util qw(decamelize getopt);

use File::Basename;
use List::MoreUtils 'uniq';

# Since this is generally a temporary execution to easily setup a file
# transfer, allow extremely large files;
use constant MAX_SIZE => $ENV{STATIC_MAXSIZE} || 10_000_000_000;

our $VERSION = '0.03';

has description => 'Quickly serve static files';
has usage => sub { shift->extract_usage };

sub run {
  my ($self, @args) = @_;

  my $daemon = Mojo::Server::Daemon->new(app => Mojolicious->new);
  getopt \@args,
    'b|backlog=i'  => sub { $daemon->backlog($_[1]) },
    'c|clients=i'  => sub { $daemon->max_clients($_[1]) },
    'i|inactivity-timeout=i' => sub { $daemon->inactivity_timeout($_[1]) },
    'l|listen=s'   => \my @listen,
    'p|proxy'      => sub { $daemon->reverse_proxy(1) },
    'r|requests=i' => sub { $daemon->max_requests($_[1]) },
    'd|default=s'  => \my $default;

  push @{$daemon->app->renderer->classes}, __PACKAGE__;

  my $app = $daemon->app;
  my $config = $app->plugin(Config => {default => {}});
  $app->log->debug("Adding plugin $_") and
  $app->plugin($_ => $config->{decamelize($_)} || ())
    for split /,/, $ENV{MOJOLICIOUS_PLUGINS} // '';

  # Add all the paths and paths of filenames specified on the command line
  $app->static->paths(_static_paths(@args));

  $app->max_request_size(MAX_SIZE);

  # Build an index of the available specified files
  my @files = _get_files($default, @args);
  $app->log->info(sprintf '%d files', $#files+1);
  if ( $default ) {
    $app->log->info("index $default");
    $app->routes->get('/')
                ->to(cb => sub { shift->reply->static($default) })
                ->name('index');
  } else {
    $app->log->info('index directory listing');
    $app->routes->get('/')
                ->to(files => \@files)
                ->name('index');
  }

  # Log requests for static files
  $app->hook(after_static => sub {
    my $c = shift;
    $c->log->info(sprintf 'GET %s', $c->req->url->path);
  });

  $daemon->listen(\@listen) if @listen;
  $daemon->run;
}

sub _get_files {
  my @files;
  foreach my $path ( map { path($_) } grep { $_ && -e $_ } @_ ) {
    if ( -d $path ) {
      $path->list_tree->each(sub{
        push @files, $_->to_rel($path);
      });
    } else {
      push @files, $path;
    }
  }
  return @files;
}

sub _static_paths {
  [uniq grep { -d $_ } map { -f $_ ? dirname $_ : $_ } @_]
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::static - Quickly serve static files

=head1 SYNOPSIS

  Usage: APPLICATION static [OPTIONS] dir1 dir2 ... file1 file2 ...

    ./myapp.pl static .
    ./myapp.pl static -d file2 -l http://*:8080 .

  Options:
    -b, --backlog <size>                 Listen backlog size, defaults to
                                         SOMAXCONN
    -c, --clients <number>               Maximum number of concurrent
                                         connections, defaults to 1000
    -d, --default <file>                 Default file to respond with (like
                                         index.html). Defaults to directory
                                         index listing.
    -h, --help                           Show this summary of available options
        --home <path>                    Path to home directory of your
                                         application, defaults to the value of
                                         MOJO_HOME or auto-detection
    -i, --inactivity-timeout <seconds>   Inactivity timeout, defaults to the
                                         value of MOJO_INACTIVITY_TIMEOUT or 15
    -l, --listen <location>              One or more locations you want to
                                         listen on, defaults to the value of
                                         MOJO_LISTEN or "http://*:3000"
    -m, --mode <name>                    Operating mode for your application,
                                         defaults to the value of
                                         MOJO_MODE/PLACK_ENV or "development"
    -p, --proxy                          Activate reverse proxy support,
                                         defaults to the value of
                                         MOJO_REVERSE_PROXY
    -r, --requests <number>              Maximum number of requests per
                                         keep-alive connection, defaults to 100
                                         
=head1 DESCRIPTION

L<Mojolicious::Command::static> quickly serves static files

Serves files from the current directory as well as those specified on the
command line. If no default file is specified, a directory index will be built.

The maximum file size can be specified by the STATIC_MAXSIZE environment
variable, or 10G by default.

=head1 ATTRIBUTES

L<Mojolicious::Command::static> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $static->description;
  $static         = $static->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $static->usage;
  $routes   = $static->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::static> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $static->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut

__DATA__
@@ index.html.ep
<p>List of static files available for download</p>
% foreach ( @$files ) {
  <a href="/<%= url_for $_ %>"><%= $_ %></a><br />
% }
