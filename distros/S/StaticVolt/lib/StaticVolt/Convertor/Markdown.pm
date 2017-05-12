# ABSTRACT: StaticVolt convertor for markdown

package StaticVolt::Convertor::Markdown;
{
  $StaticVolt::Convertor::Markdown::VERSION = '1.00';
}

use strict;
use warnings;

use base qw( StaticVolt::Convertor );

use Text::Markdown qw( markdown );

sub convert {
    my $content = shift;
    return markdown $content;
}

__PACKAGE__->register(qw/ markdown md mkd /);

1;

__END__

=pod

=head1 NAME

StaticVolt::Convertor::Markdown - StaticVolt convertor for markdown

=head1 VERSION

version 1.00

=head1 Registered Extensions

=over 4

=item * C<markdown>

=item * C<md>

=item * C<mkd>

=back

=head1 AUTHOR

Alan Haggai Alavi <haggai@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Alan Haggai Alavi.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
