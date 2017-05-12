package MooseX::Orochi::Meta::Class;
use Moose::Role;
use namespace::clean -except => qw(meta);

has bind_path => (
    is => 'rw',
    isa => 'Str'
);

has bind_injection => (
    is => 'rw',
    does => 'Orochi::Injection',
);

has injections => (
    traits => ['Hash'],
    is => 'rw',
    isa => 'HashRef',
    handles => {
        add_injection => 'set',
    }
);

1;