package Object::Remote::Prompt;

use strictures 1;
use IO::Handle;
use Exporter;

our @EXPORT = qw(prompt prompt_pw);

our ($prompt, $prompt_pw);

sub _local_prompt {
  _local_prompt_core(0, @_);
}

sub _local_prompt_pw {
  _local_prompt_core(1, @_);
}

our %Prompt_Cache;

sub _local_prompt_core {
  my ($pw, $message, $default, $opts) = @_;

  if ($opts->{cache} and my $hit = $Prompt_Cache{$message}) {
    return $hit;
  }

  STDOUT->autoflush(1);

  system('stty -echo') if $pw;

  print STDOUT "${message}: ";
  chomp(my $res = <STDIN>);

  print STDOUT "\n"   if $pw;
  system('stty echo') if $pw;

  $Prompt_Cache{$message} = $res if $opts->{cache};

  return $res;
}

sub prompt {
  die "User input wanted - $_[0] - but no prompt available"
    unless $prompt;
  goto &$prompt;
}

sub prompt_pw {
  die "User input wanted - $_[0] - but no password prompt available"
    unless $prompt_pw;
  goto &$prompt_pw;
}

if (-t STDIN) {
  $prompt = \&_local_prompt;
  $prompt_pw = \&_local_prompt_pw;
}

sub set_local_prompt_command {
  ($prompt, $prompt_pw) = @_;
  return;
}

sub maybe_set_prompt_command_on {
  return unless $prompt;
  my ($conn) = @_;
  $conn->remote_sub('Object::Remote::Prompt::set_local_prompt_command')
       ->($prompt, $prompt_pw);
}

1;
