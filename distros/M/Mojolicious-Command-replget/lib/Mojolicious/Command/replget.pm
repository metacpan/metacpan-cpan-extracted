package Mojolicious::Command::replget;
use Mojo::Base 'Mojolicious::Command';

our $VERSION = '0.01';
$VERSION = eval $VERSION;

use Mojo::DOM;
use Mojo::IOLoop;
use Mojo::JSON qw(encode_json j);
use Mojo::JSON::Pointer;
use Mojo::UserAgent;
use Mojo::Util qw(decode encode getopt);
use Scalar::Util 'weaken';

has description => 'Perform HTTP requests in a REPL';
has usage => sub { shift->extract_usage };

sub run {
  my ($self) = @_;

  my $ua = Mojo::UserAgent->new(ioloop => Mojo::IOLoop->singleton);
  while ( 1 ) {
    print "\nreplget> ";
    chomp(my $stdin = <STDIN>);
    my @args = split / +/, $stdin;
    getopt \@args,
      'C|charset=s'            => \my $charset,
      'c|content=s'            => \(my $content = ''),
      'H|header=s'             => \my @headers,
      'i|inactivity-timeout=i' => sub { $ua->inactivity_timeout($_[1]) },
      'M|method=s'             => \(my $method = 'GET'),
      'o|connect-timeout=i'    => sub { $ua->connect_timeout($_[1]) },
      'r|redirect'             => \my $redirect,
      'S|response-size=i'      => sub { $ua->max_response_size($_[1]) },
      'v|verbose'              => \my $verbose;

    @args = map { decode 'UTF-8', $_ } @args;
    $self->usage and next unless my $url = shift @args;
    my $selector = shift @args;

    # Parse header pairs
    my %headers = map { /^\s*([^:]+)\s*:\s*(.*+)$/ ? ($1, $2) : () } @headers;

    # Detect proxy for absolute URLs
    $url !~ m!^/! ? $ua->proxy->detect : $ua->server->app($self->app);
    $ua->max_redirects(10) if $redirect;

    my $buffer = '';
    $ua->on(
      start => sub {
        my ($ua, $tx) = @_;

        # Verbose
        weaken $tx;
        $tx->res->content->on(
          body => sub { warn _header($tx->req), _header($tx->res) })
          if $verbose;

        # Stream content (ignore redirects)
        $tx->res->content->unsubscribe('read')->on(
          read => sub {
            return if $redirect && $tx->res->is_redirect;
            defined $selector ? ($buffer .= pop) : print pop;
          }
        );
      }
    );

    # Switch to verbose for HEAD requests
    $verbose = 1 if $method eq 'HEAD';
    STDOUT->autoflush(1);
    my $tx = $ua->start($ua->build_tx($method, $url, \%headers, $content));
    my $res = $tx->result;

    # JSON Pointer
    next unless defined $selector;
    _json($buffer, $selector) and next if !length $selector || $selector =~ m!^/!;

    # Selector
    $charset //= $res->content->charset || $res->default_charset;
    _select($buffer, $selector, $charset, @args);
  }
}

sub _header { $_[0]->build_start_line, $_[0]->headers->to_string, "\n\n" }

sub _json {
  return unless my $data = j(shift);
  return unless defined($data = Mojo::JSON::Pointer->new($data)->get(shift));
  return _say($data) unless ref $data eq 'HASH' || ref $data eq 'ARRAY';
  say encode_json($data);
}

sub _say { length && say encode('UTF-8', $_) for @_ }

sub _select {
  my ($buffer, $selector, $charset, @args) = @_;

  # Keep a strong reference to the root
  $buffer = decode($charset, $buffer) // $buffer if $charset;
  my $dom     = Mojo::DOM->new($buffer);
  my $results = $dom->find($selector);

  while (defined(my $command = shift @args)) {

    # Number
    ($results = $results->slice($command)) and next if $command =~ /^\d+$/;

    # Text
    return _say($results->map('text')->each) if $command eq 'text';

    # All text
    return _say($results->map('all_text')->each) if $command eq 'all';

    # Attribute
    return _say($results->map(attr => $args[0] // '')->each)
      if $command eq 'attr';

    # Unknown
    die qq{Unknown command "$command".\n};
  }

  _say($results->each);
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::replget - Get command in a REPL

=head1 SYNOPSIS

  Usage: APPLICATION replget
  
  replget> [OPTIONS] URL [SELECTOR|JSON-POINTER] [COMMANDS]

    ./myapp.pl replget
    
    replget> /
    replget -H 'Accept: text/html' /hello.html 'head > title' text
    replget //sri:secr3t@/secrets.json /1/content
    replget mojolicious.org
    replget -v -r -o 25 -i 50 google.com
    replget -v -H 'Host: mojolicious.org' -H 'Accept: */*' mojolicious.org
    replget -M POST -H 'Content-Type: text/trololo' -c 'trololo' perl.org
    replget mojolicious.org 'head > title' text
    replget mojolicious.org .footer all
    replget mojolicious.org a attr href
    replget mojolicious.org '*' attr id
    replget mojolicious.org 'h1, h2, h3' 3 text
    replget https://api.metacpan.org/v0/author/SRI /name
    replget -H 'Host: example.com' http+unix://%2Ftmp%2Fmyapp.sock/index.html

  Options:
    -C, --charset <charset>              Charset of HTML/XML content, defaults
                                         to auto-detection
    -c, --content <content>              Content to send with request
    -H, --header <name:value>            Additional HTTP header
    -h, --help                           Show this summary of available options
        --home <path>                    Path to home directory of your
                                         application, defaults to the value of
                                         MOJO_HOME or auto-detection
    -i, --inactivity-timeout <seconds>   Inactivity timeout, defaults to the
                                         value of MOJO_INACTIVITY_TIMEOUT or 20
    -M, --method <method>                HTTP method to use, defaults to "GET"
    -m, --mode <name>                    Operating mode for your application,
                                         defaults to the value of
                                         MOJO_MODE/PLACK_ENV or "development"
    -o, --connect-timeout <seconds>      Connect timeout, defaults to the value
                                         of MOJO_CONNECT_TIMEOUT or 10
    -r, --redirect                       Follow up to 10 redirects
    -S, --response-size <size>           Maximum response size in bytes,
                                         defaults to 2147483648 (2GB)
    -v, --verbose                        Print request and response headers to
                                         STDERR

=head1 DESCRIPTION

L<Mojolicious::Command::replget> is a command line interface for
L<Mojo::UserAgent> in a REPL.

=head1 ATTRIBUTES

L<Mojolicious::Command::replget> performs requests to remote hosts or local
applications.

=head2 description

  my $description = $replget->description;
  $replget        = $replget->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $replget->usage;
  $replget  = $replget->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::replget> inherits all methods from L<Mojolicious::Command>
and implements the following new ones.

=head2 run

  $get->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
