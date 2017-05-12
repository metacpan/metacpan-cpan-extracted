# ============================================================================
package MooseX::App::Plugin::MutexGroup::Meta::Attribute;
# ============================================================================

use Moose::Role;
use namespace::autoclean;

has 'mutexgroup' => (
    is  => 'ro',
    isa => 'Str',
);

around 'cmd_tags_list' => sub {
    my $orig = shift;
    my ($self) = @_;

    my @tags = $self->$orig();

    push(@tags,'MutexGroup')
        if $self->can('mutexgroup')
        && $self->mutexgroup;

    return @tags;
};

{
    package Moose::Meta::Attribute::Custom::Trait::AppMutexGroup;

    use strict;
    use warnings;

    sub register_implementation { return 'MooseX::App::Plugin::MutexGroup::Meta::Attribute' }
}

1;
