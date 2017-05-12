# ABSTRACT: StaticVolt convertor for textile

package StaticVolt::Convertor::Textile;
{
  $StaticVolt::Convertor::Textile::VERSION = '1.00';
}

use strict;
use warnings;

use base qw( StaticVolt::Convertor );

use Text::Textile qw( textile );

sub convert {
    my $content = shift;
    return textile $content;
}

__PACKAGE__->register(qw/ textile /);

1;

__END__

=pod

=head1 NAME

StaticVolt::Convertor::Textile - StaticVolt convertor for textile

=head1 VERSION

version 1.00

=head1 Registered Extensions

=over 4

=item * C<textile>

=back

=head1 AUTHOR

Alan Haggai Alavi <haggai@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Alan Haggai Alavi.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
