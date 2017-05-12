package Template::Plugin::Textile;

use strict;
#use warnings;

use vars qw($VERSION);
$VERSION = "2.02";

use Text::Textile;

sub load { return $_[0] }
sub new  { return bless {}, $_[0] }

$Template::Filters::FILTERS->{textile}
   = sub { Text::Textile::textile($_[0]) };

1;

__END__

=head1 NAME

Template::Plugin::Textile - textile plugin for the Template Toolkit

=head1 SYNOPSIS

  [% USE Textile -%]
  [% FILTER textile %]this is _like_ *so* *cool*[% END %]

  <p>this is <em>like</em> <strong>so</strong <strong>cool</strong></p>

=head1 DESCRIPTION

This is a very thin wrapper around Text::Textile for the Template
Toolkit.  When you load the plugin, it creates a filter called C<textile>
that you can use in the normal way

  [% text = BLOCK -%]
  The "Template Toolkit":http://www.tt2.org was written by Andy Wardly.
  !http://www.perl.com/supersnail/os2002/images/small/os6_d5_5268_w2_sm.jpg!
  This image (c) Julian Cash 2002
  [%- END %]

  [% text | textile %]

Or

  [% FILTER textile %]
  Reasons to use the Template Toolkit:

  * Seperation of concerns.
  * It's written in Perl.
  * Badgers are Still Cool.
  [% END %]

=head1 BUGS

None known (it's only ten lines of code.)

Bugs (and requests for new features) can be reported to the open source
development team at Profero though the CPAN RT system:
<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-Textile>

=head1 AUTHOR

The thin wrapper code (all ten lines of it) was written by Mark Fowler
E<lt>mark@twoshortplanks.comE<gt>.

The B<Text::Textile> module that does all the work was written by Tom
Insam E<lt>tom@jerakeen.orgE<gt>, and in his own words 'All the clever
things in Text::Textile were written by Brad Choate
E<lt>http://www.bradchoate.comE<gt>'

  Copyright Profero 2003.  All rights reserved.
  Copyright Mark Fowler 2012.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Text::Textile>, L<Template>, L<Template::Plugin>, L<Template::Filters>

=cut
