package RT::Extension::Drafts;

use warnings;
use strict;

=head1 NAME

RT::Extension::Drafts - Allow to save/load drafts in ticket replies/comments

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

This RT Extension allow users to save a reply/comment as a draft for the
current ticket and load it again later.

=head1 AUTHOR

Emmanuel Lacour, C<< <elacour at home-dn.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rt-extension-Drafts at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RT-Extension-Drafts>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RT::Extension::Drafts


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RT-Extension-Drafts>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RT-Extension-Drafts>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RT-Extension-Drafts>

=item * Search CPAN

L<http://search.cpan.org/dist/RT-Extension-Drafts>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2011-2018 Emmanuel Lacour, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Request Tracker (RT) is Copyright Best Practical Solutions, LLC.

=cut

# User overridable options
$RT::Config::META{AutoSaveDraftPeriod} = {
    Section         => 'Ticket composition',
    Overridable     => 1,
    SortOrder       => 20,
    Widget          => '/Widgets/Form/Integer',
    WidgetArguments => {
        Description => 'Period (in seconds) to automatically save a response/comment draft'
    },
};

1; # End of RT::Extension::Drafts
