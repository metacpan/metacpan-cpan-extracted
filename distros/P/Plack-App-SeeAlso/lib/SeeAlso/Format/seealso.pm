package SeeAlso::Format::seealso;
$SeeAlso::Format::seealso::VERSION = '0.14';
#ABSTRACT: SeeAlso response format
use strict;
use warnings;

use base 'SeeAlso::Format';

sub type { 'text/javascript' }

sub psgi {
    my ($self, $result) = @_;
    my $json = JSON->new->encode( $result );
    return [ 200, [ "Content-Type" => $self->type ], [ $json ] ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SeeAlso::Format::seealso - SeeAlso response format

=head1 VERSION

version 0.14

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
