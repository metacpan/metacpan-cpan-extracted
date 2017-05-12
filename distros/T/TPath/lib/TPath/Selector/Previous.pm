package TPath::Selector::Previous;
$TPath::Selector::Previous::VERSION = '1.007';
# ABSTRACT: C<TPath::Selector> that implements C<:p>

use Moose;
use namespace::autoclean;


with 'TPath::Selector::Test';

# required by TPath::Selector
sub select {
    my ( $self, $ctx ) = @_;
    $ctx->previous;
}

sub to_string { return '/:p' }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Selector::Previous - C<TPath::Selector> that implements C<:p>

=head1 VERSION

version 1.007

=head1 ROLES

L<TPath::Selector::Test>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
