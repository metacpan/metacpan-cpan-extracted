package TAP::Runner::Option;
{
  $TAP::Runner::Option::VERSION = '0.005';
}
# ABSTRACT: Option object
use Moose;
use Moose::Util::TypeConstraints;

subtype 'ArrayRef::' . __PACKAGE__,
    as 'ArrayRef[' . __PACKAGE__ . ']';

coerce 'ArrayRef::' . __PACKAGE__,
    from 'ArrayRef[HashRef]',
    via { [ map { __PACKAGE__->new($_) } @{$_} ] };

has name          => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
);

has values        => (
    is            => 'ro',
    isa           => 'ArrayRef[Str]',
    required      => 1,
);

has multiple      => (
    is            => 'ro',
    isa           => 'Bool',
    default       => 0,
);

has parallel      => (
    is            => 'ro',
    isa           => 'Bool',
    default       => 0,
);

sub get_values_array {
    my $self = shift;

    [ map { [ $self->name, $_ ] } @{ $self->values } ];
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

TAP::Runner::Option - Option object

=head1 VERSION

version 0.005

=head1 DESCRIPTION

Object used for L<TAP::Runner::Test> options

=head1 MOOSE SUBTYPES

=head2 ArrayRef::TAP::Runner::Option

Coerce ArrayRef[HashRef] to ArrayRef[TAP::Runner::Test] Used b L<TAP::Runner::Test>

=head1 ATTRIBUTES

=head2 name Str

Option name

=head2 values ArrayRef[Str]

Array of option values

=head2 multiple Bool

If option multiple ( default not ) so for each option value will be new test
with this value

    Example:
    For option { name => '--opt_exampl', values => [ 1, 2 ], multiple => 1 }
    will run to tests, with diferrent optoins:
    t/test.t --opt_exampl 1
    t/test.t --opt_exampl 2

=head2 parallel Bool

If option should run in parallel. Run in parallel can be just multiple option.

=head1 METHODS

=head2 get_values_array

Build array used for cartesian multiplication

    Example: [ [ opt_name, opt_val1 ], [ opt_name1, opt_val2 ] ]

=head1 AUTHOR

Pavel R3VoLuT1OneR Zhytomirsky <r3volut1oner@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Pavel R3VoLuT1OneR Zhytomirsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
