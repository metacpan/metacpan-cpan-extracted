## no critic (RequireUseStrict)
package Plack::VCR::Interaction;
$Plack::VCR::Interaction::VERSION = '0.06';
## use critic (RequireUseStrict)
use strict;
use warnings;

use Plack::Util::Accessor qw/request/;

sub new {
    my ( $class, %opts ) = @_;

    return bless \%opts, $class;
}

1;

# ABSTRACT: Represents a single HTTP interaction

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::VCR::Interaction - Represents a single HTTP interaction

=head1 VERSION

version 0.06

=head1 DESCRIPTION

Retrieved from L<Plack::VCR/next>; objects of this
class currently only contain an L<HTTP::Request>.

=head1 METHODS

=head2 request

Returns the L<HTTP::Request> for this interaction.

=head1 SEE ALSO

L<Plack::VCR>

=begin comment

=over

=item new

=back

=end comment

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/hoelzro/plack-middleware-recorder/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
