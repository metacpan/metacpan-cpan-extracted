package Mojolicious::Plugin::SaveRequest;

use Mojo::Base 'Mojolicious::Plugin';

use IO::File;
use POSIX 'strftime';
use Time::HiRes;

our $VERSION = '0.04';

sub register {
    my ($self, $app) = @_;

    $app->routes->add_condition(save => \&_save);
}

sub _save {
    my ($r, $c, $conf, $state_dir) = @_;
    
    my $abs_path = $c->app->home->abs_path;
    my $now = POSIX::strftime("%Y-%d-%m", localtime(time));

    my $path = "$abs_path/$state_dir/$now";
    if (!-d $path) {
        mkdir($path) or return 1;;
    }

    my $t0 = join(".", Time::HiRes::gettimeofday());

    my $handle = IO::File->new();
    my $count = 0;
    my $name = sprintf("$path/go.%s.%d.%08d.pl", $t0, $$, $count);
    until ($handle->open($name, O_CREAT | O_EXCL | O_RDWR)) {
        ++$count;
        if (1_000_000 <= $count) {
            die("Too many open attempts");
        }
        $name = sprintf("$path/go.%s.%d.%08d.pl", $t0, $$, $count);
    }

    print($handle "\#\!$^X\n\n");

    my $req = $c->req;
    my $headers = $req->headers->to_hash;

    print($handle "my \%headers = (\n");
    foreach my $header (sort keys %{ $headers }) {
        print($handle "\tqq($header) => qq($$headers{$header}),\n");
    }
    print($handle ");\n\n");

    print($handle "my \$h = join(\"-H \", map({ \"\$_:\$headers{\$_}\" } keys \%headers));\n\n");

    print($handle "my \$method = '" . $req->method  . "';\n");
    print($handle "my \$query_params = '" . $req->query_params  . "';\n");
    print($handle "my \$url = '" . $req->url->to_string  . "';\n");
    print($handle "my \$body = '" . $req->body  . "';\n");
    print($handle "\n");

    print($handle qq(die("Need a Mojo script as first argument.") unless -x \$ARGV[0];\n\n));
    print($handle qq(my \@runme = (shift(\@ARGV));\n));
    print($handle qq(\@runme = (\$^X, "-d", \@runme) if "-d" eq \$ARGV[0];\n));
    print($handle "\n");

    print($handle qq(my \@exec = (
        \@runme, 
        "get",
        "-v",
        "-M",
        \$method,
        "-c",
        \$body,
        map({ ("-H", \"\$_:\$headers{\$_}\") } keys \%headers),
        \$url
    );\n));

    print($handle qq(print("exec: " . join(" ", \@exec), "\\n");\n));
    print($handle qq(exec(\@exec);\n));
    

    close($handle);

    $c->app->log->debug("SaveRequest: $name");

    return 1;
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::SaveRequest - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('SaveRequest');

  # Mojolicious::Lite
  plugin 'SaveRequest';

  # Save request state to $dir (relative to the absolute path of your app)
  get '/' => (save => $dir) => sub {...};
  $r->get('/')->over(save => $dir)->to(controller => 'Index', action => 'slash');

=head1 DESCRIPTION

L<Mojolicious::Plugin::SaveRequest> is a L<Mojolicious> plugin.

It saves the state of a request in a script that can be executed from
the command-line at a later date.  In addition, the debugger can be used
to step through a request.

For example, run a saved request try:

    /opt/perl state/2013-15-06/go.1371309475.241402.30552.00000000.pl script/the_app

=head1 METHODS

L<Mojolicious::Plugin::SaveRequest> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
