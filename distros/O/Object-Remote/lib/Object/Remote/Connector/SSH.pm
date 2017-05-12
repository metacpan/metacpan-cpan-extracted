package Object::Remote::Connector::SSH;

use Object::Remote::ModuleSender;
use Object::Remote::Handle;
use String::ShellQuote;
use Moo;

with 'Object::Remote::Role::Connector::PerlInterpreter';

has ssh_to => (is => 'ro', required => 1);

has ssh_perl_command => (is => 'lazy');

has ssh_options => (is => 'ro', default => sub { [ '-A' ] });

has ssh_command => (is => 'ro', default => sub { 'ssh' });

sub _build_ssh_perl_command {
  my ($self) = @_;
  my $perl_command = $self->perl_command;

  return [
    do { my $c = $self->ssh_command; ref($c) ? @$c : $c },
    @{$self->ssh_options}, $self->ssh_to,
    shell_quote(@$perl_command),
  ];
}

sub final_perl_command { shift->ssh_perl_command }

no warnings 'once';

push @Object::Remote::Connection::Guess, sub {
  for ($_[0]) {
    # 0-9 a-z _ - first char, those or . subsequent - hostnamish
    if (defined and !ref and /^(?:.*?\@)?[\w\-][\w\-\.]/) {
      my $host = shift(@_);
      return __PACKAGE__->new(@_, ssh_to => $host);
    }
  }
  return;
};

1;
