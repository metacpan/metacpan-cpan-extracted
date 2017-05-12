package POE::Component::Client::opentick::FAQ;
#
#   opentick.com POE client
#
#   Frequently-Asked Questions
#
#   infi/2008
#
#   $Id:
#

use strict;
use warnings;
use vars qw($VERSION);

($VERSION) = q$Revision: 56 $ =~ /(\d+)/;

1;

__END__

=head1 NAME

POE::Component::Client::opentick::FAQ - The official FAQ for POE::Component::Client::opentick.

=head1 DESCRIPTION

This is just a Frequently-Asked Questions list.  For complete
documentation, please see L<POE::Component::Client::opentick>.

=head1 OVERVIEW-TYPE QUESTIONS

=head2 What is this module?  How do I use it?

POE::Component::Client::opentick is a POE CLIENT COMPONENT FOR ACCESSING MARKET
DATA, via the feed provided by L<http://www.opentick.com>.

It is intended to do just that: supply your own application with market
data.  The onus is on the end user (you!) to provide the supporting
framework into which this component fits, be it a graphing/monitoring/alert
system, an algorithmic trading platform, a home-built ticker system, or
whatever else you can imagine that you could use inexpensive market data
for.

Instead of threads (which are poorly implemented in Perl), this component
runs under L<POE>, a very robust, well-tested and well-supported
asynchronous event environment.  L<POE> has a bit of a learning curve, but
it is extremely versatile and useful, not only for this but for many
applications, and is generally a much better and faster solution than
Perl threading.

L<POE::Component::Client::opentick> does NOT:

=over 4

=item * directly support online trades.

=item * directly provide a built-in graphing component.

=item * contain additional utilities that are well-provided via other
modules on CPAN, that would need to be separately developed and
maintained, and which are doing just fine being maintained by their
respective authors.

=item * contain algorithms that will get you a solid gold house by the
end of the fiscal year.

Here is the documentation for L<POE>, the Perl Object Environment.

Here is an entire, official Perl site dedicated to POE: L<http://poe.perl.org>.

=back

=head2 Are there any example scripts?

Yes, there are 2 well-documented example scripts, and they are included in
the source distribution from CPAN in the examples/ directory.  You probably
already have them on your system.

You may also browse them on the web here:

L<http://search.cpan.org/src/INFIDEL/POE-Component-Client-opentick-0.20/examples/>

And the CPAN overview page here:

L<http://search.cpan.org/src/INFIDEL/POE-Component-Client-opentick-0.20/>

(Be sure to go to your correct version.)

=head2 Which interface/API should I use?  opentick.pm?  OTClient.pm?

You should use the one that you are more comfortable with.

If you are building a NEW application, have NOT used the opentick.com
official OTClient.pm library, OR wish to have the entire feature set of this
component available to you, use the base interface:

    use POE::Component::Client::opentick;

If you are migrating from opentick.com's official OTClient.pm library, or
you wish to use the somewhat simpler interface, albeit with some advanced
features made more difficult to get at (they are still available), you may
wish to use the facade interface provided by my OTClient.pm:

    use POE::Component::Client::opentick::OTClient.pm;

Full documentation for each of these below:

L<POE::Component::Client::opentick>

L<POE::Component::Client::opentick::OTClient>

=head1 SPECIFIC QUESTIONS

=head2 Why do you only accept UNIX epoch dates?

=head2 Can't you write a method to convert dates?

That is out of scope for the goal of this component, which is to
provide a CLIENT COMPONENT FOR ACCESSING MARKET DATA.  I use UNIX epoch
dates because they use 1-second resolution, which is the smallest resolution
that opentick.com provides, AND it is easy to work with and natively
supported on almost all platforms (you're not still using MS-DOS, are you?)

Also, working with dates and time is actually very complicated, much more
complex than it seems in a passing thought.  I don't want to maintain
non-core code that has no direct bearing on the purpose of being a CLIENT
COMPONENT FOR ACCESSING MARKET DATA.

A quick search on L<http://search.cpan.org/> gave me a list of 3838
results for "Date" and more than 5000 results for "Time", so it is also
well-covered territory.

Here are some of the better/more widely-used ones:

=over 4

=item * L<Date::Manip> (but read L<Date::Manip/"SHOULD I USE DATE::MANIP">)

=item * L<Date::Calc>

=item * L<Date::Simple>

=item * L<DateTime>

=item * L<Time::Format>

=item * L<Time::Tiny>

=back

=head2 How do I change the server list?  port numbers?  realtime?

All options similar to this, which change critical settings such as these,
are specified as arguments to the L<POE::Component::Client::opentick/spawn()>
constructor of opentick.pm, or overload the base class for 
L<POE::Component::Client::OTClient>.

(I may provide additional accessor methods in the future for OTClient.pm;
right now, there has been no demand yet.)

=head1 META QUESTIONS

=head2 Are you affiliated with opentick.com?

No.

=head2 Why is 'opentick' lowercase in the module name?  THAT'S NOT PERLY!

Because the logo and trademark of I<opentick> is lowercase.  This was
intentional.

=head2 Where should I send questions, complaints, cookies, money, yachts?

If you have bug reports, please use the RequestTracker at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=POE-Component-Client-opentick>.

If you have questions or comments that haven't been answered above (please actually check), I can be reached at:

Jason McManus (INFIDEL) - C<< infidel AT cpan.org >>

As the user 'infi' on the Freenode IRC Network: L<irc://irc.freenode.net/#perl>

I wouldn't mind receiving mail telling me a brief overview of what you're
using it for.

=head1 RESOURCES

=head2 Web Links

The L<POE::Component::Client::opentick> documentation.

The L<POE::Component::Client::opentick::OTClient> documentation.

The project page, L<http://search.cpan.org/~infidel/POE-Component-Client-opentick/> for this module.

The CPAN search page: L<http://search.cpan.org>.

The L<POE> documentation, L<POE::Kernel>, L<POE::Session>

L<http://poe.perl.org/> - POE's official site.

L<http://www.opentick.com/> - opentick's main site.

L<http://www.opentick.com/dokuwiki/doku.php> - opentick's documentation.

The examples/ directory of this module's distribution.

=head1 AUTHOR

Jason McManus (INFIDEL) - C<< infidel AT cpan.org >>

=head1 LICENSE

Copyright (c) Jason McManus

This module may be used, modified, and distributed under the same terms
as Perl itself.  Please see the license that came with your Perl
distribution for details.

The data from opentick.com are under an entirely separate license that
varies according to exchange rules, etc.  It is your responsibility to
follow the opentick.com and exchange license agreements with the data.

Further details are available on L<http://www.opentick.com/>.

=cut

### END ###

