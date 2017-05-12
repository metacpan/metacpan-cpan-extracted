package RPG::Traveller::Starmap::Parsec;
use strict;
use Moose;
use RPG::Traveller::Starmap::StarGroup;

has stargroup => ( is => "rw", isa => "RPG::Traveller::Starmap::StarGroup" );
has posx      => ( is => "rw", isa => "Int" );
has posy      => ( is => "rw", isa => "Int" );

sub generate {
    my $self      = shift;
    my $stargroup = new RPG::Traveller::Starmap::Stargroup();
    $stargroup->generate;
}

# ABSTRACT:  Encapsulates a parsec for (Mega)Traveller

1;

__END__

=pod

=head1 NAME

RPG::Traveller::Starmap::Parsec - Encapsulates a parsec for (Mega)Traveller

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    use RPG::Traveller::Starmap::Parsec;
    my $parsec=new RPG::Traveller::Starmap::Parsec;
    $parsec->posx(1);
    $parsec->posy(2);
    $parsec->generate;

=head1 METHODS

=head2 posy/posx

Getter setter methods to pin the posx and posy attributes.

=head2 generate

Recursively generates all the attributes for a parsec.

=head1 SEE ALSO

=for :list *L<perl>
*L<RPG::Dice>

=head1 AUTHOR

Peter L. Berghold <peter@berghold.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Peter L. Berghold.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
