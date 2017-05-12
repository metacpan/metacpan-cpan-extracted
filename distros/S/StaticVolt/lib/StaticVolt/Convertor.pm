# ABSTRACT: Base class for StaticVolt convertors

package StaticVolt::Convertor;
{
  $StaticVolt::Convertor::VERSION = '1.00';
}

use strict;
use warnings;

my %convertor;

sub has_convertor {
    my ( $self, $extension ) = @_;

    if ( exists $convertor{$extension} ) {
        return 1;
    }
    return;
}

sub convert {
    my ( $self, $content, $extension ) = @_;

    no strict 'refs';
    return &{"${convertor{$extension}}::convert"}($content);
}

sub register {
    my ( $class, @extensions ) = @_;

    for my $extension (@extensions) {
        $convertor{$extension} = $class;
    }
}

1;

__END__

=pod

=head1 NAME

StaticVolt::Convertor - Base class for StaticVolt convertors

=head1 VERSION

version 1.00

=head1 METHODS

=head2 C<has_convertor>

Accepts a filename extension and returns a boolean result which indicates
whether the particular extension has a registered convertor or not.

=head2 C<convert>

Accepts content and filename extension as the parametres. Returns HTML after
converting the content using the convertor registered for that extension.

=head1 FUNCTIONS

=head2 C<register>

Accepts a list of filename extensions and registers a convertor for each
extension.

=head1 AUTHOR

Alan Haggai Alavi <haggai@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Alan Haggai Alavi.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
