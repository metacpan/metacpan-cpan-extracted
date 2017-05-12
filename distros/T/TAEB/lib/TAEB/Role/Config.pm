package TAEB::Role::Config;
use Moose::Role;

has config => (
    is  => 'rw',
    isa => 'Maybe[HashRef]',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $class = blessed $self;
        $class =~ s/^TAEB:://;
        my @config_path = split /::/, $class;
        my $config = TAEB->config->contents;
        for (@config_path) {
            if (ref $config eq 'HASH') {
                $config = $config->{lc($_)};
            }
            else {
                return;
            }
        }
        return $config;
    },
);

no Moose::Role;

1;
