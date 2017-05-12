package TPath::Function;
$TPath::Function::VERSION = '1.007';
# ABSTRACT: implements the functions in expressions such as C<//*[:abs(@foo) = 1]> and C<//*[:sqrt(@bar) == 2]>

use Moose;

with 'TPath::Numifiable';

has f => ( is => 'ro', isa => 'CodeRef', required => 1 );

has name => ( is => 'ro', isa => 'Str', required => 1 );

has arg => ( is => 'ro', isa => 'TPath::Numifiable', required => 1 );

sub to_num {
    my ( $self, $ctx ) = @_;
    return $self->f->( $self->arg->to_num($ctx) );
}

sub to_string {
    my $self = shift;
    my $s    = ':' . $self->name . '(';
    if ( $self->arg->isa('TPath::Math') ) {
        $s .= ' ' . $self->arg->to_string(1) . ' ';
    }
    else {
        $s .= $self->arg->to_string(1);
    }
    $s .= ')';
    return $s;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Function - implements the functions in expressions such as C<//*[:abs(@foo) = 1]> and C<//*[:sqrt(@bar) == 2]>

=head1 VERSION

version 1.007

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
