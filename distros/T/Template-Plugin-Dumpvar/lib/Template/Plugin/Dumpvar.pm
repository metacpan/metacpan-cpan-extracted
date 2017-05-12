package Template::Plugin::Dumpvar;

=pod

=head1 NAME

Template::Plugin::Dumpvar - Dump template data in the same style as the
debugger

=head1 SYNOPSIS

  [% USE Dumpvar %]
  
  [% Dumpvar.dump(this) %]
  [% Dumpvar.dump_html(theother) %]

=head1 DESCRIPTION

When dumping data in templates, the obvious first choice is to use the
L<Data::Dumper> plugin L<Template::Plugin::Dumper>. But personally, I think
the layout is ugly and hard to read. It's designed to be parsed back in by
perl, not to necesarily be easy on the eye.

The dump style used in the debugger, however, IS designed to be easier on
the eye. The dumpvar.pl script it uses to do this has been cloned for general
use as L<Devel::Dumpvar>. This module is a drop in replacement for
Template::Plugin::Dumper that uses Devel::Dumpvar in place of Data::Dumper.

The only difference is that this module only dumps one scalar, reference, or
object at a time.

=head1 METHODS

=cut

use 5.005;
use strict;
use Devel::Dumpvar ();
use base 'Template::Plugin';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.03';
}





#####################################################################
# Constructor

sub new {
	my $class = ref $_[0] || $_[0];
	bless {
		Dumpvar => Devel::Dumpvar->new( to => 'return' ),
	}, $class;
}

=pod

=head2 dump $something

Dumps a single structure via L<Devel::Dumpvar>. Does not escape for HTML.

=cut

sub dump {
	$_[0]->{Dumpvar}->dump( $_[1] );
}

=pod

=head2 dump_html $something

As above, but also escapes and formats for HTML

=cut

sub dump_html {
	$_ = $_[0]->dump($_[1]) or return $_;

	# Escape for HTML
	s/&/&amp;/g;
	s/</&lt;/g;
	s/>/&gt;/g;
	s/\n/<br>\n/g;

	$_;
}

1;

=pod

=head1 SUPPORT

Bugs should be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-Dumpvar>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
