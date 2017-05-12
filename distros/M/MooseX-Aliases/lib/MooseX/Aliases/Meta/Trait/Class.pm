package MooseX::Aliases::Meta::Trait::Class;
BEGIN {
  $MooseX::Aliases::Meta::Trait::Class::AUTHORITY = 'cpan:DOY';
}
{
  $MooseX::Aliases::Meta::Trait::Class::VERSION = '0.11';
}
use Moose::Role;

around _inline_slot_initializer => sub {
    my $orig = shift;
    my $self = shift;
    my ($attr, $index) = @_;

    my @orig_source = $self->$orig(@_);
    return @orig_source
        # only run on aliased attributes
        unless $attr->meta->can('does_role')
            && $attr->meta->does_role('MooseX::Aliases::Meta::Trait::Attribute');
    return @orig_source
        # don't run if we haven't set any aliases
        # don't run if init_arg is explicitly undef
        unless $attr->has_alias && $attr->has_init_arg;

    my $init_arg = $attr->init_arg;

    return (
        'if (my @aliases = grep { exists $params->{$_} } (qw('
          . join(' ', @{ $attr->alias }) . '))) {',
            'if (exists $params->{' . $init_arg . '}) {',
                'push @aliases, \'' . $init_arg . '\';',
            '}',
            'if (@aliases > 1) {',
                $self->_inline_throw_error(
                    '"Conflicting init_args: (" . join(", ", @aliases) . ")"',
                ) . ';',
            '}',
            '$params->{' . $init_arg . '} = delete $params->{$aliases[0]};',
        '}',
        @orig_source,
    );
};

no Moose::Role;

=for Pod::Coverage

=cut

1;
