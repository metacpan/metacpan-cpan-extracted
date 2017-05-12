use Test;
BEGIN { plan tests => 4 }
use Pod::SAX;
use XML::SAX::Writer;

my $output = '';
my $p = Pod::SAX->new(
            Handler => XML::SAX::Writer->new(
                Output => \$output
                )
            );

ok($p);
my $str = join('', <DATA>);
ok($str, qr/=head1/s, "Read DATA ok");
$p->parse_string($str);
ok($output);
print "$output\n";
ok($output, qr/<pod>.*<\/pod>/s, "Matches basic pod outline");

__DATA__

=head1 Play Pen

Here you can experiment with POD markup in a Wiki.

Things you can do:

=over 4

=item Bulleted

=item Lists

=back

=over 4

=item 1 Numbered

=item 2 Lists

=back

Some B<bold> and I<italic> text.

  Some verbatim
  text that
  you can use for
  source code examples.

Or you can add a L<link|PlayPenLink> to create a new editable page.

This is a L<new link|YetAnotherPage> to another page.


Please have fun, be nice, and remember your manners ;-)


=head1 Links

for more information on the POD format, and using POD, consult

L<http://www.perldoc.com/perl5.6.1/pod/perlpod.html>

or, a French translation at

L<http://www.mongueurs.net/perlfr/perlpod.html>

=cut

=head1 I want letters

=over 18

=item A Come on over

..so we can I<paaarty>.

=back

=over 21

=item B Come on over

..so we can I<paaartay> B<hard>

=item C Come on over

..so we can I<paaartay> B<even harder>

=back

=head1 I'm listening to Bagpipe Music...

and wondering if something like this could be used at my site
to publishing all the documentation my programmers are supposed
to be putting in their code :)

The only problem is that POD doesn't like to work with indents so much.
Maybe that will all be fixed in Perl6 :)

Thanks Matt!

I<<< I'm not sure what the problem with "indents" are. In POD, you can indent
a section of text using =over ... =back. It's semantically equivalent to
the HTML <blockquoteE<gt> tag. >>>

=cut

=head2 WikiFeatureRequests

=over 4

=item Should WikiWords work without the LE<lt>...|...E<gt> syntax?

I.e. automatically create links. Or is this exclusivly a L<POD|PlainOldDocumentation> system?

=item How about L<RevisionControl>?

So that it's possible to see who made any changes. (Of course, we'd need a notion of L<Users|WikiUsers>.)

=item How about L<links|HowToMakeLinks> in item lists?

They seem to work....

=item Access to configuration files

So that we can edit the XSP/XSL stylesheets, CSS files and perhaps htaccess/htpasswd files?

=item How about a "Preview mode"

...so we can have a look at our contributions before they are commited?

=back

=head1 Do L<links in titles|HowToMakeLinks> work?

(I certainly hope so.)

=over 4

=item Mayme showing documents that aren't created yet...

...allready when you create a new WikiWordLink L<Questionmark|WikiWordLink> ?

(by the way, a LE<lt>?|WikiWordLinkE<gt> creates a server error!)

=back


=cut