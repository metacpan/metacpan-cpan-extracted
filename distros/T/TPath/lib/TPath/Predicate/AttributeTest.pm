package TPath::Predicate::AttributeTest;
$TPath::Predicate::AttributeTest::VERSION = '1.007';
# ABSTRACT: implements the C<[@foo = 1]> in C<//a/b[@foo = 1]>


use Moose;
use TPath::TypeConstraints;


with 'TPath::Predicate';


has at => ( is => 'ro', isa => 'TPath::AttributeTest', required => 1 );

sub filter {
    my ( $self, $c ) = @_;
    return grep { $self->at->test($_) } @$c;
}

sub to_string {
    $_[0]->at->to_string;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Predicate::AttributeTest - implements the C<[@foo = 1]> in C<//a/b[@foo = 1]>

=head1 VERSION

version 1.007

=head1 DESCRIPTION

The object that selects the correct member of collection based whether they pass a particular attribute test.

=head1 ATTRIBUTES

=head2 at

The L<TPath::AttributeTest> selected items must pass.

=head1 ROLES

L<TPath::Predicate>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
