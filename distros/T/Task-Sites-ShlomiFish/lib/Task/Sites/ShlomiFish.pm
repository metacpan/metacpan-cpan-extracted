package Task::Sites::ShlomiFish;

use warnings;
use strict;

use 5.008;

=head1 NAME

Task::Sites::ShlomiFish - Specifications for modules needed for building www.shlomifish.org , whose sources are publically available, and which serves as examples for several technologies.

=cut

our $VERSION = '0.0212';

=head1 DESCRIPTION

Shlomi Fish maintains a homesite at L<http://www.shlomifish.org/>. Installing
this task from CPAN will install all of the CPAN modules that are required
to build it.

The sources of this web-site are available in a public version control
repository with detailed building instructions:

L<http://www.shlomifish.org/meta/site-source/>

This site serves as an example for the Latemp static site generator
( L<http://web-cpan.shlomifish.org/latemp/> ) and for other open-source
technologies such as some of my XML-Grammar-* modules.

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at iglu.org.il> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-task-sites-shlomifish at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task-Sites-ShlomiFish>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 DEFENSE OF THE MOTIVATION FOR THIS MODULE

I received a lot of heat for maintaining this task on CPAN, which I feel
is unjustified. Part of the reason was that I did not make the justification
for it clear in the first versions I uploaded, so here it is.

First of all, I should note that the source code of my site is public, and I
give detailed installation instructions here:

L<http://www.shlomifish.org/meta/site-source/>

So people who are interested may wish to download the site's sources, play with
them and learn from them.

Furthermore, the sources of my site serve as a sophisticated example for Latemp
( L<http://web-cpan.shlomifish.org/latemp/> ), Website Meta Language (
L<http://thewml.org/> ) and other technologies. So there is some public
motivation to make installing its CPAN dependencies as easy as possible.

I'm sorry that I have not made all these facts clear in the module's
documentation, but I still feel that all the heat I received was uncalled for.

After I said that, let me note that it is my opinion that if we don't want to
have CPAN "contaminated" with modules that are of little public use, then we
should implement a secondary sources mechanism in CPANPLUS.pm which will allow
configuring remote sources with their own indices, which will provide different
packages to what CPAN provides. Such mechanism will also allow organisations to
set up repositories for their own private use.

Last time I raised the idea, someone objected and nothing was done to take it
forward. I'm willing to work on implementing it myself assuming there's enough
interest and that I'll know my effort will not go to waste.

Now regarding the fact that this module wastes space on CPAN. Looking at my
CPAN directory, I see that the tar.gz of version 0.0201 of it occupies
2.1 KB. What a disaster! Seriously now, it occupies much less space than
"XML-Grammar-ProductSyndication" which takes 159KB, from "XML-RSS" which
takes 99 KB, from "Test-Run" which takes 83 KB, and from most of my other
modules. Obviously, there's some extra overhead in indexing and in displaying
on search engines, but taking it into proportion, it's not a burden on CPAN.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Task::Sites::ShlomiFish

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Task-Sites-ShlomiFish>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Task-Sites-ShlomiFish>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Sites-ShlomiFish>

=item * Search CPAN

L<http://search.cpan.org/dist/Task-Sites-ShlomiFish>

=back

=head1 ACKNOWLEDGEMENTS

=head1 SEE ALSO

L<Task> , L<Task::Latemp>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish.

This program is released under the X11 License:

L<http://www.opensource.org/licenses/mit-license.php>

=cut

1;

