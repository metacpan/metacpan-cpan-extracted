# ============================================================================
package MooseX::App::Plugin::Depends::Meta::Attribute;
# ============================================================================

use Moose::Role;
use namespace::autoclean;

has 'depends' => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

around 'cmd_tags_list' => sub {
    my $orig = shift;
    my ($self) = @_;

    my @tags = $self->$orig();

    push(@tags,'Depends')
        if $self->can('depends')
        && $self->depends;

    return @tags;
};

{
    package Moose::Meta::Attribute::Custom::Trait::AppDepends;

    use strict;
    use warnings;

    sub register_implementation { return 'MooseX::App::Plugin::Depends::Meta::Attribute' }
}

1;
