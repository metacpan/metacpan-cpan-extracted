package Plack::Handler::Starwoman;
$Plack::Handler::Starwoman::VERSION = '0.001';
use strict;
use Starwoman::Server;

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub run {
    my($self, $app) = @_;

    if ($ENV{SERVER_STARTER_PORT}) {
        require Net::Server::SS::PreFork;
        @Starwoman::Server::ISA = qw(Net::Server::SS::PreFork); # Yikes.
    }

    my %nsa;
    while (my($key, $value) = each %$self) {
        $key =~ s/^net_server_// or next;
        $nsa{$key} = $value;
    }
    $self->{net_server_args} = \%nsa if %nsa;

    Starwoman::Server->new->run($app, {%$self});
}

1;

__END__

=head1 NAME

Plack::Handler::Starwoman - Plack adapter for Starwoman

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  plackup -s Starwoman

=head1 DESCRIPTION

This handler exists for the C<plackup> compatibility. Essentially,
C<plackup -s Starwoman> is equivalent to C<starwoman --preload-app>,
because the C<starwoman> executable delay loads the application by
default. See L<starwoman> for more details.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Starwoman>

=cut
