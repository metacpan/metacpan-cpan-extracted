package Net::RCON::Minecraft::Response;

# Minecraft command response

use 5.008;
use Mouse;
use Mouse::Util::TypeConstraints;
use Term::ANSIColor;
use Carp;
no warnings 'uninitialized';

our $VERSION = '0.01';

use overload q("") => sub { shift->plain },
              '++' => sub { $_[0] = $_[0]->plain + 1 },
              '--' => sub { $_[0] = $_[0]->plain - 1 },
              fallback => 1;

# Minecraft -> ANSI color map
my %COLOR = map { $_->[1] => color($_->[0]) } (
    [black        => '0'], [blue           => '1'], [green        => '2'],
    [cyan         => '3'], [red            => '4'], [magenta      => '5'],
    [yellow       => '6'], [white          => '7'], [bright_black => '8'],
    [bright_blue  => '9'], [bright_green   => 'a'], [bright_cyan  => 'b'],
    [bright_red   => 'c'], [bright_magenta => 'd'], [yellow       => 'e'],
    [bright_white => 'f'],
    [bold         => 'l'], [concealed      => 'm'], [underline    => 'n'],
    [reverse      => 'o'], [reset          => 'r'],
);

has id    => ( is => 'ro', isa => 'Int' );

has raw   => ( is => 'ro', isa => 'Str' );

has plain => ( is => 'ro', isa => 'Str', lazy => 1, default => sub {
    my $raw = $_[0]->raw;
    $raw =~ s/\x{00A7}.//g;
    $raw;
});

has ansi  => ( is => 'ro', isa => 'Str', lazy => 1, default => sub {
    local $_ = $_[0]->raw;
    s/\x{00A7}(.)/$COLOR{$1}/g;
    $_ . $COLOR{r};
});

__PACKAGE__->meta->make_immutable();
