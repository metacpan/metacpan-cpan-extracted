package TAEB::Interface::SSH;
use TAEB::OO;

use constant ping_wait => .3;

=head1 NAME

TAEB::Interface::SSH - how TAEB talks to /dev/null

=cut

extends 'TAEB::Interface::Local';

has server => (
    is      => 'ro',
    isa     => 'Str',
    default => 'devnull.kraln.com',
);

has account => (
    is  => 'ro',
    isa => 'Str',
);

has password => (
    is  => 'ro',
    isa => 'Str',
);

sub _build_pty {
    my $self = shift;

    TAEB->log->interface("Connecting to " . $self->server . ".");

    my $pty = IO::Pty::Easy->new;
    $pty->spawn('ssh', $self->server, '-l', $self->account);

    alarm 20;
    eval {
        local $SIG{ALRM} = sub { die "timeout" };

        my $output = '';
        while (1) {
            $output .= $pty->read(0) || '';
            if ($output =~ /password/) {
                alarm 0;
                last;
            }
        }
    };

    die "Died ($@) while waiting for password prompt.\n" if $@;

    $pty->write($self->password . "\n\n", 0);

    TAEB->log->interface("Connected to " . $self->server . ".");

    return $pty;
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

