use strict;
use warnings;
package RTx::Search::FullTextByDefault;

our $VERSION = '0.01';

=head1 NAME

RTx-Search-FullTextByDefault - Search ticket subject and content by default from RT's simple search

=head1 DESCRIPTION

RT's simple search normally only searches subjects when it finds unrecognized
terms.  It allows explicit content searching by using C<content:hola> or
C<fulltext:"hello world">.  Explicit subject searches are performed via bare
quotes (C<"hi there">) or C<subject:hello>.

This RT plugin, when installed and enabled, changes the simple search default
to search subjects and full content for any unrecognized term and all quoted
phrases without a field prefix.  Explicit subject- or content-only terms may be
prefixed to indicate such.

Note that the simple search explanation/documentation is B<not> updated to
reflect the new behaviour with this plugin installed.  There is no good
mechanism to do so in RT.

=cut

{
    use RT::Search::Simple;
    package RT::Search::Simple;
    no warnings 'redefine';

    # Search both subject and content for terms we can't classify.
    sub HandleDefault { return content => "(Subject LIKE '$_[1]' OR Content LIKE '$_[1]')"; }

    # Turn quoted strings from subject-only to subject-or-content.  Overrides the
    # default guess of subject when the term is quoted.
    our @GUESS;
    unshift @GUESS, [ 5 => sub { return "default" if $_[1] } ];
}

=head1 INSTALLATION 

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin("RTx::Search::FullTextByDefault");

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Thomas Sibley <trsibley@uw.edu>

=head1 BUGS

All bugs should be reported via email to
L<bug-RTx-Search-FullTextByDefault@rt.cpan.org|mailto:bug-RTx-Search-FullTextByDefault@rt.cpan.org>
or via the web at
L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RTx-Search-FullTextByDefault>.


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014 by Thomas Sibley

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
