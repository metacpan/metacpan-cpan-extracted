package Mojolicious::Plugin::ConsoleLogger;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream;
use Mojo::JSON qw(decode_json encode_json);

our $VERSION = 0.06;

has logs => sub {
  return {
    fatal => [],
    info  => [],
    debug => [],
    error => [],
  };
};

sub register {
  my ($plugin, $app) = @_;

  # override Mojo::Log->log
  no strict 'refs';
  my $stash = \%{"Mojo::Log::"};
  
  # Mojolicious 6 renames Mojo::Log::log to Mojo::Log::_log
  my $logsub = (defined &Mojo::Log::_log) ? "_log" : "log";
  my $orig  = delete $stash->{$logsub};

  *{"Mojo::Log::$logsub"} = sub {
    push @{$plugin->logs->{$_[1]}} => $_[-1];

    # Original Mojo::Log->log
    $orig->(@_);
  };

  $app->hook(
    after_dispatch => sub {
      my $self = shift;
      # Patched Nov 23, 2014 to work with JSON
      return if $self->res->headers->content_type eq 'application/json';
      my $logs = $plugin->logs;

      # Leave static content untouched
      return if $self->stash('mojo.static');

      # Do not allow if not development mode
      return if $self->app->mode ne 'development';

      my $str = "\n<!-- Mojolicious logging -->\n<script>\n"
        . "if (window.console) {";

      # Config, Session
      for (qw/ config session /) {
        $str .= "\nconsole.group(\"$_\");";
        $str .= "\n" . _format_msg($self->$_);
        $str .= "\nconsole.groupEnd(\"$_\");";
      }

      # Stash
      $str .= "\nconsole.group(\"stash\");";

      # Remove mojo.* and config keys
      my @ok_keys = grep !/^(?:mojo\.|config$)/ => keys %{$self->stash};
      $str .= "\n" . _format_msg({map { $_ => $self->stash($_) } @ok_keys});

      $str .= "\nconsole.groupEnd(\"stash\");\n";

      # Logs: fatal, info, debug, error
      for (sort keys %$logs) {
        next if !@{$logs->{$_}};
        $str .= "\nconsole.group(\"$_\");";
        $str .= "\n" . _format_msg($_) for splice @{$logs->{$_}};
        $str .= "\nconsole.groupEnd(\"$_\");\n";
      }

      $str .= "}</script>\n";

      $self->res->body($self->res->body . $str);
    }
  );
}

sub _format_msg {
  my $msg = shift;

  return ref($msg)
    ? "console.log(" . encode_json($msg) . "); "
    : "console.log(" . Mojo::ByteStream->new($msg)->quote . "); ";
}

1;

=head1 NAME

Mojolicious::Plugin::ConsoleLogger - Console logging in your browser

=head1 DESCRIPTION

L<Mojolicious::Plugin::ConsoleLogger> pushes Mojolicious session, stash, config, and log messages to the browser's console tool.

* Logging operates only in development mode.

=head1 USAGE

    use Mojolicious::Lite;

    plugin 'ConsoleLogger';

    get '/' => sub {

        app->log->debug("Here I am!");
        app->log->error("This is bad");
        app->log->fatal("This is really bad");
        app->log->info("This isn't bad at all");
        app->log->info({json => 'structure'});

        shift->render(text => 'Ahm in ur browzers, logginz ur console');
    };

    app->start;

=head1 METHODS

L<Mojolicious::Plugin::ConsoleLogger> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

    $plugin->register;

Register condition in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>

=head1 DEVELOPMENT

L<http://github.com/tempire/mojolicious-plugin-consolelogger>

=head1 VERSION

0.06

=head1 CREDITS

Implementation stolen from L<Plack::Middleware::ConsoleLogger>

=head1 AUTHORS

Glen Hinkle tempire@cpan.org

Andrew Kirkpatrick

Zhenyi Zhou

=cut
