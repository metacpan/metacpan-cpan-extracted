package Template::Provider::Markdown;
use 5.008;
use warnings;
use strict;
use Text::Markdown 'markdown';

use base qw( Template::Provider );

=head1 NAME

Template::Provider::Markdown - Markdown as template body, no HTML.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

This module import Markdown syntax as the body of template. You don't live
with HTML anymore.

    use Template;
    use Template::Provider::Markdown;
    my $tt = Template->new(
        LOAD_TEMPLATES => [ Template::Provider::Markdown->new ]
    );
    my $template = 'My name is [% author %]';
    print $tt->process(\$template, { author => "Charlie" });

    <p>My name is Charlie</p>

=head1 FUNCTIONS

=head2 _load()

This function is the entry point as a Template::Provider.  You shouldn't call
any functions in this module, but rather just use this module as the way in
SYNOPSIS.

=cut

sub _load {
    my $self = shift;
    my ($data, $error) = $self->SUPER::_load(@_);

    $data->{text} = markdown($data->{text});

    return ($data, $error);
}

=head1 AUTHOR

Kang-min Liu, C<< <gugod at gugod.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-template-provider-markdown at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Provider-Markdown>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Provider::Markdown

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Provider-Markdown>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Provider-Markdown>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Provider-Markdown>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Provider-Markdown>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006,2007,2008,2009 Kang-min Liu, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Template::Provider::Markdown

