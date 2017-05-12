use 5.010;

# ABSTRACT: The method metarole

package MooseX::Params::Meta::Method;
{
  $MooseX::Params::Meta::Method::VERSION = '0.010';
}

use Moose;
use List::Util qw(max);

extends 'Moose::Meta::Method';

has 'parameters' =>
(
    is        => 'rw',
    isa       => 'HashRef',
    traits    => ['Hash'],
    predicate => 'has_parameters',
    handles   =>
    {
        all_parameters => 'values',
        add_parameter  => 'set',
        get_parameter  => 'get',
        get_parameters => 'get',
    },
);

has 'index_offset' =>
(
    is      => 'ro',
    isa     => 'Int',
    default => 1,
);

has 'buildargs' =>
(
    is  => 'rw',
    isa => 'Str',
);

has 'checkargs' =>
(
    is  => 'rw',
    isa => 'Str',
);

has 'returns' =>
(
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_return_value_constraint',
);

has 'returns_scalar' =>
(
    is        => 'rw',
    isa       => 'Str',
);

has '_delayed' =>
(
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
);

has '_execute' =>
(
    is  => 'ro',
    isa => 'Str',
);

sub _validate_parameters
{
    my ($self, %parameters) = @_;
}

sub _convert_argv_to_hash
{
    my ($self, @argv) = @_;

    my (%parameters, %argv);

    my @positional = grep { $_->type eq 'positional' } $self->get_parameters;
    my @named      = grep { $_->type eq 'named'      } $self->get_parameters;

    my $last_positional_index = max map { $_->index } @positional;
    my $first_named_index = $last_positional_index + 1;
    my $last_argv_index = $#argv;

    if ( $last_positional_index >= $last_argv_index )
    {
        @positional = grep { $_->index <= $last_argv_index } @positional;

    }
    else
    {
        my @extra = @argv[$first_named_index .. $last_argv_index];

        if (@named)
        {
            %argv = @extra;

            foreach my $name ( map { $_->name } @named )
            {
                $parameters{$name} = delete $argv{$name} if exists $argv{$name};
            }
            $parameters{'__!extra'} = \(%argv);
        }
        else
        {
            $parameters{'__!extra'} = \@extra;
        }
    }

    $parameters{$_->name} = $argv[$_->index] for @positional;

    return %parameters;
}

1;

__END__
=pod

=for :stopwords Peter Shangov TODO invocant isa metaroles metarole multimethods sourcecode
backwards buildargs checkargs slurpy preprocess

=head1 NAME

MooseX::Params::Meta::Method - The method metarole

=head1 VERSION

version 0.010

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

