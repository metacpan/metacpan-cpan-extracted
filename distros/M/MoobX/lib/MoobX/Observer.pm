package MoobX::Observer;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: a MoobX object reacting to observable variable changes
$MoobX::Observer::VERSION = '0.1.0';

use 5.20.0;

use Scalar::Util 'refaddr';
use Carp;

use Moose;

use experimental 'signatures';

use overload 
    '""' => sub { $_[0]->value },
    fallback => 1;

use MooseX::MungeHas 'is_ro';

has value => ( 
    builder   => 1,
    lazy      => 1,
    predicate => 1,
    clearer   => 1,
);

after clear_value => sub($self) {
    $self->value if $self->autorun;
};

has generator => (
    required => 1,
);

has autorun => ( 
    is => 'ro', 
    trigger => sub($self,@) {
        $self->value
    }
);


sub dependencies($self) {
     map {
        $MoobX::graph->get_vertex_attribute( $_, 'info' );
        } $MoobX::graph->successors( refaddr($self) ) 
}

sub _build_value {
    my $self = shift;

    local $MoobX::WATCHING = 1;
    local @MoobX::DEPENDENCIES = @MoobX::DEPENDENCIES;

    my $new_value = $self->generator->();

    local $Carp::CarpLevel = 2;
    carp "MoobX observer doesn't observe anything"
        unless @MoobX::DEPENDENCIES;

    MoobX::dependencies_for( $self, @MoobX::DEPENDENCIES );

    return $new_value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MoobX::Observer - a MoobX object reacting to observable variable changes

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

    use MoobX;
    use MoobX::Observer;

    observable( my $foo = 'hi' );

    my $obs = MoobX::Observer->new(
        generator => sub { scalar reverse $foo } 
    );

    $foo = 'hello';

    say $obs; # prints 'olleh'

=head1 DESCRIPTION

This class implements the observer object used by L<MoobX>.

=head1 OVERLOADED OPERATIONS

MoobX::Observer objects are stringified using their C<value> attribute.

=head1 METHODS

=head2 new

    my $obs = MoobX::Observer->new(
        generator => sub { ... },
        autorun    => 1,
    );

Constructor. Accepts two arguments:

=over

=item generator

Function generating the observer value. Required.

=item autorun

If set to true, the observer will eagerly compute its value
at creation time, and recompute it as soon as a dependency changes.
Defaults to C<false>.

=back

=head2 value

Returns the currently cached observer's value.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
