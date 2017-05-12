#
# This file is part of Pod-Weaver-PluginBundle-Apocalyptic
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Pod::Weaver::PluginBundle::Apocalyptic;
# git description: release-0.003-8-gb908959
$Pod::Weaver::PluginBundle::Apocalyptic::VERSION = '0.004';
BEGIN {
  $Pod::Weaver::PluginBundle::Apocalyptic::AUTHORITY = 'cpan:APOCAL';
}

# ABSTRACT: Let the apocalypse generate your POD!

# The plugins we use ( excluding ones bundled in podweaver )
use Pod::Weaver::Config::Assembler 4.001;	# basically sets the pod-weaver version
use Pod::Weaver::Section::SeeAlso 1.002;
use Pod::Weaver::Section::Support 1.003;
use Pod::Weaver::Section::WarrantyDisclaimer 0.111290;
use Pod::Weaver::Plugin::StopWords 1.001005;
use Pod::Weaver::Plugin::EnsureUniqueSections 0.103531;
use Pod::Elemental::Transformer::List 0.101620;
use Pod::Weaver::Section::Contributors 0.008;

sub _exp {
	Pod::Weaver::Config::Assembler->expand_package( $_[0] );
}

sub mvp_bundle_config {
	return (
		# some basics we need
		[ '@Apocalyptic/CorePrep',	_exp('@CorePrep'), {} ],

		# Move our special markers to the start of the POD
		[ '@Apocalyptic/SingleEncoding', _exp('-SingleEncoding'), {} ],
		[ '@Apocalyptic/PodCoverage',    _exp('Region'), {
			region_name	=> 'Pod::Coverage',
			allow_nonpod	=> 1,
			flatten		=> 0,
		} ],
		[ '@Apocalyptic/StopWords',	_exp('-StopWords'), {} ],

		# Start the POD!
		[ '@Apocalyptic/Name',		_exp('Name'), {} ],
		[ '@Apocalyptic/Version',	_exp('Version'), {
			format		=> 'This document describes v%v of %m - released %{LLLL dd, yyyy}d as part of %r.',
			is_verbatim	=> 1,
		} ],

		# The standard sections
		[ '@Apocalyptic/Synopsis',	_exp('Generic'), {
			header		=> 'SYNOPSIS',
		} ],
		[ '@Apocalyptic/Description',	_exp('Generic'), {
			header		=> 'DESCRIPTION',
			required	=> 1,
		} ],

		# Our subs
		[ '@Apocalyptic/Attributes',	_exp('Collect'), {
			header		=> 'ATTRIBUTES',
			command		=> 'attr',
		} ],
		[ '@Apocalyptic/Methods',	_exp('Collect'), {
			header		=> 'METHODS',
			command		=> 'method',
		} ],
		[ '@Apocalyptic/Functions',	_exp('Collect'), {
			header		=> 'FUNCTIONS',
			command		=> 'func',
		} ],
		[ '@Apocalyptic/POEvents',	_exp('Collect'), {
			header		=> 'POE Events',
			command		=> 'event',
		} ],

		# Anything that wasn't matched gets dumped here
		[ '@Apocalyptic/Leftovers',	_exp('Leftovers'), {} ],

		# The usual end of POD...
		[ '@Apocalyptic/SeeAlso',	_exp('SeeAlso'), {} ],
		[ '@Apocalyptic/Support',	_exp('Support'), {
			'irc'		=> [
				'irc.perl.org, #perl-help, Apocalypse',
				'irc.freenode.net, #perl, Apocal',
				'irc.efnet.org, #perl, Ap0cal',
			],
			'email'		=> 'APOCAL',
		} ],
		[ '@Apocalyptic/Authors',	_exp('Authors'), {} ],
		[ '@Apocalyptic/Contributors',	_exp('Contributors'), {
			'head'	=> 2,
		} ],
		[ '@Apocalyptic/ACK',		_exp('Generic'), {
			header		=> 'ACKNOWLEDGEMENTS',
		} ],
		[ '@Apocalyptic/Legal',		_exp('Legal'), {
			license_file	=> 'LICENSE',
		} ],

		# Use the GPL3 warranty disclaimer by default
		[ '@Apocalyptic/Warranty',	_exp('WarrantyDisclaimer::GPL3'), {} ],

		# Mangle the entire POD
		[ '@Apocalyptic/ListTransformer',	_exp('-Transformer'), {
			transformer	=> 'List',
		} ],
		[ '@Apocalyptic/UniqueSections',	_exp('-EnsureUniqueSections'), {} ],
	);
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse Romanov Sergey cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=for Pod::Coverage mvp_bundle_config

=head1 NAME

Pod::Weaver::PluginBundle::Apocalyptic - Let the apocalypse generate your POD!

=head1 VERSION

  This document describes v0.004 of Pod::Weaver::PluginBundle::Apocalyptic - released October 25, 2014 as part of Pod-Weaver-PluginBundle-Apocalyptic.

=head1 DESCRIPTION

In your F<weaver.ini>:

	[@Apocalyptic]

Or alternatively, in your L<Dist::Zilla> dist's F<dist.ini>:

	[PodWeaver]
	config_plugin = @Apocalyptic

This plugin bundle formats your POD and adds some sections and sets some custom options. Naturally, in order for
most of the plugins to work, you need to use this in conjunction with L<Dist::Zilla>.

It is nearly equivalent to the following in your F<weaver.ini>:

	[@CorePrep]			; setup the pod stuff
	[-SingleEncoding]		; add the =encoding command to your Pod
	[Region / Pod::Coverage]	; move any Pod::Coverage markers to the top ( =for Pod::Coverage foo bar )
	[-StopWords]			; gather our stopwords and add some extra ones via Pod::Weaver::Plugin::StopWords

	[Name]				; automatically generate the NAME section
	[Version]			; automatically generate the VERSION section
	format = This document describes v%v of %m - released %{LLLL dd, yyyy}d as part of %r.
	is_verbatim = 1

	[Generic / SYNOPSIS]		; move the SYNOPSIS section here, if it exists
	[Generic / DESCRIPTION]		; move the DESCRIPTION section here ( it is required to exist! )
	required = 1

	; get any POD marked with our special types and list them here
	[Collect / ATTRIBUTES]
	command = attr
	[Collect / METHODS]
	command = method
	[Collect / FUNCTIONS]
	command = func
	[Collect / POE Events]
	command = event

	[Leftovers]			; any other POD you use

	[SeeAlso]			; generate the SEE ALSO section via Pod::Weaver::Section::SeeAlso
	[Support]			; generate the SUPPORT section via Pod::Weaver::Section::Support ( only present in main module )
	irc = irc.perl.org, #perl-help, Apocalypse
	irc = irc.freenode.net, #perl, Apocal
	irc = irc.efnet.org, #perl, Ap0cal
	email = APOCAL
	[Authors]			; automatically generate the AUTHOR(S) section
	[Contributors]			; automatically generate the CONTRIBUTOR(S) section via Dist::Zilla::Plugin::ContributorsFromGit
	head = 2
	[Generic / ACKNOWLEDGEMENTS]	; move the ACKNOWLEDGEMENTS section here, if it exists
	[Legal]				; automatically generate the COPYRIGHT AND LICENSE section
	[WarrantyDisclaimer]		; automatically generate the DISCLAIMER OF WARRANTY section via Pod::Weaver::Section::WarrantyDisclaimer

	[-Transformer]
	transformer = List		; mangle all :list pod into proper lists via Pod::Elemental::Transformer::List
	[-EnsureUniqueSections]		; sanity check your sections to make sure they are unique via Pod::Weaver::Plugin::EnsureUniqueSections

If you need something to be configurable ( probably the Support section, ha! ) please let me know and I can add it in a future version.

Oh, the Contributors section is generated from the git history. In my case I had several email addresses that I used to commit in the past and I
became a contributor to my own project! This was easily solved by fixing the git email addresses via the '.mailmap' file:

	apoc@box:~/eclipse_ws/perl-pod-weaver-pluginbundle-apocalyptic$ cat .mailmap
	Apocalypse <APOCAL@cpan.org> <apocalypse@users.noreply.github.com>
	Apocalypse <APOCAL@cpan.org> <perl@0ne.us>

=head1 Future Plans

=head2 auto image in POD?

=begin :HTML <p><img src="http://www.perl.org/i/icons/camel.png" width="600">Perl Camel!</p>
=end :HTML

Saw that in http://search.cpan.org/~wonko/Smolder-1.51/lib/Smolder.pm

Maybe we can make a transformer to automatically do that? ( =image http://blah.com/foo.png )

<jhannah> Apocalypse: ya, right? cool and dangerous and prone to FAIL as URLs become invalid... :/
<jhannah> I'd hate to see craptons of broken images on s.c.o   :(
<Apocalypse> Yeah jhannah it would be best if you could include the image in the dist itself... but that's a problem for another day :)
<jhannah> Apocalypse: it'd be trivial to include the .jpg in the .tgz... but what's the POD markup for that? and would s.c.o. do it correctly?
<jhannah> =begin HTML is ... eep
<Apocalypse> I think you could do it via sneaky means but it's prone to breakage
<Apocalypse> i.e. include it in dist as My-Foo-Dist/misc/image.png and link to it via s.c.o's "browse dist" directory
<Apocalypse> i.e. link to http://cpansearch.perl.org/src/WONKO/Smolder-1.51/misc/image.png
<Apocalypse> I should try that sneaky tactic and see if it works =]

=end :HTML

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla|Dist::Zilla>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Pod::Weaver::PluginBundle::Apocalyptic

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Pod-Weaver-PluginBundle-Apocalyptic>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Pod-Weaver-PluginBundle-Apocalyptic>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Weaver-PluginBundle-Apocalyptic>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Pod-Weaver-PluginBundle-Apocalyptic>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Pod-Weaver-PluginBundle-Apocalyptic>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Pod-Weaver-PluginBundle-Apocalyptic>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/Pod-Weaver-PluginBundle-Apocalyptic>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/P/Pod-Weaver-PluginBundle-Apocalyptic>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Pod-Weaver-PluginBundle-Apocalyptic>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Pod::Weaver::PluginBundle::Apocalyptic>

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

Please report any bugs or feature requests by email to C<bug-pod-weaver-pluginbundle-apocalyptic at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Weaver-PluginBundle-Apocalyptic>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/apocalypse/perl-pod-weaver-pluginbundle-apocalyptic>

  git clone git://github.com/apocalypse/perl-pod-weaver-pluginbundle-apocalyptic.git

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head2 CONTRIBUTOR

=for stopwords Sergey Romanov

Sergey Romanov <complefor@rambler.ru>

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
