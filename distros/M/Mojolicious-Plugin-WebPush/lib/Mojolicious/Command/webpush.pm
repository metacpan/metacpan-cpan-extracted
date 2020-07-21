package Mojolicious::Command::webpush;
use Mojo::Base 'Mojolicious::Command';
use Mojo::JSON qw(encode_json decode_json);
use Crypt::PK::ECC;

my %COMMAND2JSON = (
  create => [ 1 ],
);
my %COMMAND2CB = (
  keygen => \&_keygen,
);

has description => q{Manage your app's web-push};
has usage       => sub { shift->extract_usage };

sub _keygen {
  print STDOUT Crypt::PK::ECC->new->generate_key('prime256v1')
    ->export_key_pem('private');
}

sub _promisify {
  my ($app, $cmd) = @_;
  sub {
    my (undef, @args) = @_;
    my @res = eval { $app->$cmd(@args) };
    $@ ? Mojo::Promise->reject($@) : Mojo::Promise->resolve(@res);
  };
}

sub run {
  my ($self, $cmd, @args) = @_;
  return print STDOUT $self->usage if !$cmd;
  return $COMMAND2CB{$cmd}->($self, @args) if $COMMAND2CB{$cmd};
  $args[$_] = decode_json($args[$_]) for @{ $COMMAND2JSON{$cmd} || [] };
  $cmd .= "_p";
  $self->app->webpush->$cmd(@args)->then(
    sub { print STDOUT encode_json(@_), "\n" },
    sub { print STDERR @_, "\n" },
  )->wait;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::webpush - Manage your app's web-push

=head1 SYNOPSIS

  Usage: APPLICATION webpush COMMAND [OPTIONS]

    ./myapp.pl webpush create <USERID> <JSON>
    ./myapp.pl webpush read <USERID>
    ./myapp.pl webpush delete <USERID>
    ./myapp.pl webpush keygen > webpush_private_key.pem

  Options:
    -h, --help          Show this summary of available options
        --home <path>   Path to home directory of your application, defaults to
                        the value of MOJO_HOME or auto-detection
    -m, --mode <name>   Operating mode for your application, defaults to the
                        value of MOJO_MODE/PLACK_ENV or "development"

=head1 DESCRIPTION

L<Mojolicious::Command::webpush> manages your application's web-push
information. It gives a command-line interface to the relevant helpers
in L<Mojolicious::Plugin::WebPush/HELPERS>.

The C<keygen> command prints a PEM-encoded L<Crypt::PK::ECC/generate_key>
C<prime256v1> result.

=head1 ATTRIBUTES

L<Mojolicious::Command::webpush> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head1 METHODS

L<Mojolicious::Command::webpush> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head1 SEE ALSO

L<Mojolicious::Plugin::WebPush>

=cut
