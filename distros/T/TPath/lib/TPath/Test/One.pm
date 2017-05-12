package TPath::Test::One;
$TPath::Test::One::VERSION = '1.007';
# ABSTRACT: implements logical function of tests which returns true iff only one test is true


use Moose;

with 'TPath::Test::Compound';

# required by TPath::Test
sub test {
    my ( $self, $ctx ) = @_;
    my $count = 0;
    for my $t ( @{ $self->tests } ) {
        if ( $t->test($ctx) ) {
            return 0 if $count;
            $count++;
        }
    }
    return $count;
}

sub to_string {
    my $self = shift;
    return $self->_compound_to_string(';');
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Test::One - implements logical function of tests which returns true iff only one test is true

=head1 VERSION

version 1.007

=head1 DESCRIPTION

For use by compiled TPath expressions. Not for external consumption.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
