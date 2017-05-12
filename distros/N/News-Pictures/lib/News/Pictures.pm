package News::Pictures;

use warnings;
#use strict;

use News::Pictures::editnews; 
editnews();
=head1 NAME

News::Pictures - The great new News::Pictures!

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';


=head1 SYNOPSIS

News::Pictures is a package which allows to search photographs in a forum, to show them 
        and possibly to save them

    use News::Pictures;

    my $foo = News::Pictures->new();
    ...


=head1 FUNCTIONS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Christian Guine, C<< <c.guine at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-news-pictures at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=News-Pictures>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

Dependance: Tk, Tk::JPEG, IO::File, Convert::UU, Net::NNTP::Client


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc News::Pictures


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=News-Pictures>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/News-Pictures>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/News-Pictures>

=item * Search CPAN

L<http://search.cpan.org/dist/News-Pictures/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Christian Guine, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of News::Pictures