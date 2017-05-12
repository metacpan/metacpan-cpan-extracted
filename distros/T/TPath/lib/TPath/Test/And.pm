package TPath::Test::And;
$TPath::Test::And::VERSION = '1.007';
# ABSTRACT: implements logical conjunction of tests


use Moose;


with 'TPath::Test::Compound';

# required by TPath::Test
sub test {
    my ( $self, $ctx ) = @_;
    for my $t ( @{ $self->tests } ) {
        return 0 unless $t->test($ctx);
    }
    return 1;
}

sub to_string {
    my $self = shift;
    return $self->_compound_to_string('&');
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Test::And - implements logical conjunction of tests

=head1 VERSION

version 1.007

=head1 DESCRIPTION

For use by compiled TPath expressions. Not for external consumption.

=head1 ROLES

L<TPath::Test::Compound>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
