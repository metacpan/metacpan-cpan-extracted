package Template::Plugin::JapanesePrefectures;
use strict;
use warnings;
our $VERSION = 0.01;

use Template::Plugin;
use base qw(Template::Plugin);
use Geography::JapanesePrefectures::Walker;

sub new {
    my $class = shift;
    my $context = shift;
    return Geography::JapanesePrefectures::Walker->new(@_);
}

=head1 NAME

Template::Plugin::JapanesePrefectures - easliy use Geography::JapanesePrefectures.

=head1 VERSION

This documentation refers to Template::Plugin::JapanesePrefectures version 0.01

=head1 SYNOPSIS

In your template:

    [% USE pref = JapanesePrefectures('euc-jp') %]
    [% FOR prefecture IN  pref.prefectures %]
        [% prefecture.name %]
    [% END %]

=head1 METHODS

=head2 new

create Geography::JapanesePrefectures::Walker's object

=head1 SEE ALSO

L<Geography::JapanesePrefectures::Walker>

=head1 AUTHOR

Atsushi Kobayashi, C<< <nekokak at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-template-plugin-japaneseprefectures at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-JapanesePrefectures>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Plugin::JapanesePrefectures

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Plugin-JapanesePrefectures>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Plugin-JapanesePrefectures>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Plugin-JapanesePrefectures>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Plugin-JapanesePrefectures>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Atsushi Kobayashi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Template::Plugin::JapanesePrefectures
