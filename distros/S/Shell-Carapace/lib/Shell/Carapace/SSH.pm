package Shell::Carapace::SSH;
use Moo;

use String::ShellQuote;
use Carp;

has callback         => (is => 'rw', required => 1);
has host             => (is => 'rw', required => 1);
has ssh_options      => (is => 'rw', default => sub { {} });
has ssh              => (is => 'rw', lazy => 1, builder => 1, clearer => 1);

sub _build_ssh {
    my $self = shift;
    require Net::OpenSSH;
    my %ssh_options = $self->ssh_options ? %{ $self->ssh_options } : ();
    my $ssh = Net::OpenSSH->new($self->host, %ssh_options);
    die $ssh->error if $ssh->error;
    return $ssh;
}

# force ssh builder to run so the connection occurs during object instantiation
sub BUILD { shift->ssh }

sub reconnect {
    my $self = shift;
    $self->clear_ssh;
    $self->ssh;
}

sub run {
    my ($self, @cmd) = @_;

    $self->callback->('command', $self->_stringify(@cmd), $self->host);

    my ($pty, $pid) = $self->ssh->open2pty(@cmd);
    die $self->ssh->error if $self->ssh->error;

    while (my $line = <$pty>) {
      $line =~ s/([\r\n])$//g;
      $self->callback->('remote-output', $line, $self->host);
    }   

    waitpid($pid, 0);

    if ($? != 0) {
        $self->callback->("error", $self->_stringify(@cmd), $self->host);
        croak "cmd failed";
    }
}

sub _stringify {
    my ($self, @cmd) = @_;
    return $cmd[0] if @cmd == 1;
    return join(" ", shell_quote @cmd);
}

1;
