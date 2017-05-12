package App::Tak;

use Moo;

has env => (is => 'ro', required => 1);

sub new_from_environment {
  my $class = shift;
  my %env = (
    env => { %ENV }, argv => [ @ARGV ],
    stdin => \*STDIN, stdout => \*STDOUT, stderr => \*STDERR
  );
  $class->new(env => \%env);
}

sub run {
  my ($self) = @_;
  my @argv = @{$self->env->{argv}};
  require Tak::MyScript;
  my $opt = Tak::MyScript->_parse_options(
    'config|c=s;host|h=s@;local|l!;verbose|v+;quiet|q+', \@argv
  );
  Tak::MyScript->new(
    options => $opt,
    env => { %{$self->env}, argv => \@argv }
  )->run;
}

1;
