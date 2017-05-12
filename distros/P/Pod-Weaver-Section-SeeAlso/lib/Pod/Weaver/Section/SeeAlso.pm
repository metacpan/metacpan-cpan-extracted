#
# This file is part of Pod-Weaver-Section-SeeAlso
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Pod::Weaver::Section::SeeAlso;
# git description: release-1.002-10-g1fda35c
$Pod::Weaver::Section::SeeAlso::VERSION = '1.003';
BEGIN {
  $Pod::Weaver::Section::SeeAlso::AUTHORITY = 'cpan:APOCAL';
}

# ABSTRACT: add a SEE ALSO pod section

use Moose 1.03;
use Moose::Autobox 0.10;

with 'Pod::Weaver::Role::Section' => { -version => '3.100710' };

sub mvp_multivalue_args { qw( links ) }

#pod =attr add_main_link
#pod
#pod A boolean value controlling whether the link back to the main module should be
#pod added in the submodules.
#pod
#pod Defaults to true.
#pod
#pod =cut

has add_main_link => (
	is => 'ro',
	isa => 'Bool',
	default => 1,
);

#pod =attr header
#pod
#pod Specify the content to be displayed before the list of links is shown.
#pod
#pod The default is a sufficient explanation (see L</SEE ALSO>).
#pod
#pod =cut

has header => (
	is => 'ro',
	isa => 'Str',
	default => <<'EOPOD',
Please see those modules/websites for more information related to this module.
EOPOD

);

#pod =attr links
#pod
#pod Specify a list of links you want to add to the SEE ALSO section.
#pod
#pod You can either specify it like this: "Moose" or do it in POD format: "L<Moose>". This
#pod module will automatically add the proper POD formatting if it is missing.
#pod
#pod The default is an empty list.
#pod
#pod =cut

has links => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub { [ ] },
);

sub weave_section {
	## no critic ( ProhibitAccessOfPrivateData )
	my ($self, $document, $input) = @_;

	my $zilla = $input->{'zilla'} or die 'Please use Dist::Zilla with this module!';

	# find the main module's name
	my $main = $zilla->main_module->name;
	my $is_main = $main eq $input->{'filename'} ? 1 : 0;
	$main =~ s|^lib/||;
	$main =~ s/\.pm$//;
	$main =~ s|/|::|g;

	# Is the SEE ALSO section already in the POD?
	my $see_also;
	foreach my $i ( 0 .. $#{ $input->{'pod_document'}->children } ) {
		my $para = $input->{'pod_document'}->children->[$i];
		next unless $para->isa('Pod::Elemental::Element::Nested')
			and $para->command eq 'head1'
			and $para->content =~ /^SEE\s+ALSO/s;	# catches both "head1 SEE ALSO\n\nL<baz>" and "head1 SEE ALSO\nL<baz>" format

		$see_also = $para;
		splice( @{ $input->{'pod_document'}->children }, $i, 1 );
		last;
	}

	my @links;
	if ( defined $see_also ) {
		# Transform it into a proper list
		foreach my $child ( @{ $see_also->children } ) {
			if ( $child->isa( 'Pod::Elemental::Element::Pod5::Ordinary' ) ) {
				foreach my $l ( split /\n/, $child->content ) {
					chomp $l;
					next if ! length $l;
					push( @links, $l );
				}
			} else {
				die 'Unknown POD in SEE ALSO: ' . ref( $child );
			}
		}

		# Sometimes the links are in the content!
		if ( $see_also->content =~ /^SEE\s+ALSO\s+(.+)$/s ) {
			foreach my $l ( split /\n/, $1 ) {
				chomp $l;
				next if ! length $l;
				push( @links, $l );
			}
		}
	}
	if ( $self->add_main_link and ! $is_main ) {
		unshift( @links, $main );
	}

	# Add links specified in the document
	# Code copied from Pod::Weaver::Section::Name, thanks RJBS!
	my (@extra) = ($input->{'ppi_document'}->serialize =~ /^\s*#+\s*SEE\s*ALSO\s*:\s*(.+)$/mg);
	foreach my $l ( @extra ) {
		# get the list!
		my @data = split( /\,/, $l );
		$_ =~ s/^\s+//g for @data;
		$_ =~ s/\s+$//g for @data;
		push( @links, $_ ) for @data;
	}

	# Add extra links
	push( @links, $_ ) for @{ $self->links };

	if ( @links ) {
		$document->children->push(
			Pod::Elemental::Element::Nested->new( {
				command => 'head1',
				content => 'SEE ALSO',
				children => [
					Pod::Elemental::Element::Pod5::Ordinary->new( {
						content => $self->header,
					} ),
					# I could have used the list transformer but rjbs said it's more sane to generate it myself :)
					Pod::Elemental::Element::Nested->new( {
						command => 'over',
						content => '4',
						children => [
							( map { _make_item( $_ ) } @links ),
							Pod::Elemental::Element::Pod5::Command->new( {
								command => 'back',
								content => '',
							} ),
						],
					} ),
				],
			} ),
		);
	}
}

sub _make_item {
	my( $link ) = @_;

	# Is it proper POD?
	if ( $link !~ /^L\<.+\>$/ ) {
		# include the link text so we satisfy Perl::Critic::Policy::Documentation::RequirePodLinksIncludeText
		$link = 'L<' . $link . '|' . $link . '>';
	}

	return Pod::Elemental::Element::Nested->new( {
		command => 'item',
		content => '*',
		children => [
			Pod::Elemental::Element::Pod5::Ordinary->new( {
				content => $link,
			} ),
		],
	} );
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse Adam Fish Lesperance Shlomi cpan testmatrix url annocpan anno
bugtracker rt cpants kwalitee diff irc mailto metadata placeholders
metacpan dist dzil

=for Pod::Coverage weave_section mvp_multivalue_args

=head1 NAME

Pod::Weaver::Section::SeeAlso - add a SEE ALSO pod section

=head1 VERSION

  This document describes v1.003 of Pod::Weaver::Section::SeeAlso - released October 25, 2014 as part of Pod-Weaver-Section-SeeAlso.

=head1 DESCRIPTION

This section plugin will produce a hunk of pod that references the main module of a dist
from its submodules, and adds any other text already present in the POD. It will do this
only if it is being built with L<Dist::Zilla>, because it needs the data from the dzil object.

In the main module, this section plugin just transforms the links into a proper list. In the
submodules, it also adds the link to the main module.

For an example of what the hunk looks like, look at the L</SEE ALSO> section in this POD :)

WARNING: Please do not put any POD commands in your SEE ALSO section!

What you should do when you want to add extra links is:

	=head1 SEE ALSO
	Foo::Bar
	Bar::Baz
	www.cpan.org

And this module will automatically convert it into:

	=head1 SEE ALSO
	=over 4
	=item *
	L<Main::Module>
	=item *
	L<Foo::Bar>
	=item *
	L<Bar::Baz>
	=item *
	L<www.cpan.org>
	=back

You can specify more links by using the "links" attribute, or by specifying it as a comment. The
format of the comment is:

	# SEEALSO: Foo::Bar, Module::Nice::Foo, www.foo.com

The way the links are ordered is: POD in the module, links attribute, comment links.

=head1 ATTRIBUTES

=head2 add_main_link

A boolean value controlling whether the link back to the main module should be
added in the submodules.

Defaults to true.

=head2 header

Specify the content to be displayed before the list of links is shown.

The default is a sufficient explanation (see L</SEE ALSO>).

=head2 links

Specify a list of links you want to add to the SEE ALSO section.

You can either specify it like this: "Moose" or do it in POD format: "L<Moose>". This
module will automatically add the proper POD formatting if it is missing.

The default is an empty list.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Pod::Weaver|Pod::Weaver>

=item *

L<Dist::Zilla|Dist::Zilla>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Pod::Weaver::Section::SeeAlso

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Pod-Weaver-Section-SeeAlso>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Pod-Weaver-Section-SeeAlso>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Weaver-Section-SeeAlso>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Pod-Weaver-Section-SeeAlso>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Pod-Weaver-Section-SeeAlso>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Pod-Weaver-Section-SeeAlso>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/Pod-Weaver-Section-SeeAlso>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/P/Pod-Weaver-Section-SeeAlso>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Pod-Weaver-Section-SeeAlso>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Pod::Weaver::Section::SeeAlso>

=back

=head2 Email

You can email the author of this module at C<APOCAL at cpan.org> asking for help with any problems you have.

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #perl-help then talk to this person for help: Apocalypse.

=item *

irc.freenode.net

You can connect to the server at 'irc.freenode.net' and join this channel: #perl then talk to this person for help: Apocal.

=item *

irc.efnet.org

You can connect to the server at 'irc.efnet.org' and join this channel: #perl then talk to this person for help: Ap0cal.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-pod-weaver-section-seealso at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Weaver-Section-SeeAlso>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/apocalypse/perl-pod-weaver-section-seealso>

  git clone git://github.com/apocalypse/perl-pod-weaver-section-seealso.git

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head2 CONTRIBUTORS

=for stopwords Adam Lesperance Shlomi Fish

=over 4

=item *

Adam Lesperance <lespea@gmail.com>

=item *

Shlomi Fish <shlomif@shlomifish.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
