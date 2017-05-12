package MooseX::Params::Magic::Data;
{
  $MooseX::Params::Magic::Data::VERSION = '0.010';
}

# ABSTRACT: Base class for wizard data object

use 5.010;
use Moose;

has 'parameters' =>
(
    is       => 'ro',
    isa      => 'HashRef[MooseX::Params::Meta::Parameter]',
    required => 1,
    traits   => [qw(Hash)],
    handles  => {
        get_parameter      => 'get',
        all_parameters     => 'elements',
        allowed_parameters => 'keys',

    },
);

has 'lazy' =>
(
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
    lazy     => 1,
    builder  => '_build_lazy',
    traits   => [qw(Array)],
    handles  => { lazy_parameters => 'elements' }
);

has 'self' =>
(
    is => 'ro',
);

has 'wrapper' =>
(
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
    traits   => [qw(Code)],
    handles  => { wrap => 'execute' },
);

has 'package' =>
(
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _build_lazy
{
    my $self = shift;
    my @lazy = map { $_->name } grep { $_->lazy } $self->all_parameters;
    return \@lazy;
}

no Moose;

1;

__END__
=pod

=for :stopwords Peter Shangov TODO invocant isa metaroles metarole multimethods sourcecode
backwards buildargs checkargs slurpy preprocess

=head1 NAME

MooseX::Params::Magic::Data - Base class for wizard data object

=head1 VERSION

version 0.010

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

