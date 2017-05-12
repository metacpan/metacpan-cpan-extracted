#
# This file is part of Pod-Weaver-Section-Support
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Pod::Weaver::Section::Support;
# git description: release-1.006-3-g691fd83
$Pod::Weaver::Section::Support::VERSION = '1.007';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Add a SUPPORT section to your POD

use Moose 1.03;
use Moose::Autobox 0.10;

with 'Pod::Weaver::Role::Section' => { -version => '3.100710' };

sub mvp_multivalue_args { qw( websites irc bugs_content email_content irc_content repository_content websites_content ) }

#pod =attr all_modules
#pod
#pod Enable this if you want to add the SUPPORT section to all the modules in a dist, not only the main one.
#pod
#pod The default is false.
#pod
#pod =cut

has all_modules => (
	is => 'ro',
	isa => 'Bool',
	default => 0,
);

#pod =attr perldoc
#pod
#pod Specify if you want the paragraph explaining about perldoc to be displayed or not.
#pod
#pod The default is true.
#pod
#pod =cut

has perldoc => (
	is => 'ro',
	isa => 'Bool',
	default => 1,
);

#pod =attr bugs
#pod
#pod Specify the bugtracker you want to use. You can use the CPAN RT tracker or your own, specified in the metadata.
#pod
#pod Valid options are: "rt", "metadata", or "none"
#pod
#pod If you pick the "rt" option, this module will generate a predefined block of text explaining how to use the RT system.
#pod
#pod If you pick the "metadata" option, this module will check the L<Dist::Zilla> metadata for the bugtracker to display. Be sure
#pod to verify that your metadata contains both 'web' and 'mailto' keys if you want to use them in the content!
#pod
#pod The default is "rt".
#pod
#pod =cut

{
	use Moose::Util::TypeConstraints 1.01;

	has bugs => (
		is => 'ro',
		isa => enum( [ qw( rt metadata none ) ] ),
		default => 'rt',
	);

	no Moose::Util::TypeConstraints;
}

#pod =attr bugs_content
#pod
#pod Specify the content for the bugs section.
#pod
#pod Please put the "{EMAIL}" and "{WEB}" placeholders somewhere!
#pod
#pod The default is a sufficient explanation (see L</SUPPORT>).
#pod
#pod =cut

has bugs_content => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub {
		[ <<'EOPOD',
Please report any bugs or feature requests by email to {EMAIL}, or through
the web interface at {WEB}. You will be automatically notified of any
progress on the request by the system.
EOPOD
		];
	},
);

#pod =attr websites
#pod
#pod Specify what website links you want to see. This is an array, and you can pick any combination. You can also
#pod specify it as a comma-delimited string. The ordering of the options are important, as they are reflected in
#pod the final POD.
#pod
#pod Valid options are: "none", "metacpan", "search", "rt", "anno", "ratings", "forum", "kwalitee", "testers", "testmatrix", "deps" and "all".
#pod
#pod The default is "all".
#pod
#pod 	# Where the links go to:
#pod 	metacpan	- http://metacpan.org/release/$dist
#pod 	search		- http://search.cpan.org/dist/$dist
#pod 	rt		- https://rt.cpan.org/Public/Dist/Display.html?Name=$dist
#pod 	anno		- http://annocpan.org/dist/$dist
#pod 	ratings		- http://cpanratings.perl.org/d/$dist
#pod 	forum		- http://cpanforum.com/dist/$dist
#pod 	kwalitee	- http://cpants.perl.org/dist/$dist
#pod 	testers		- http://cpantesters.org/distro/$first_char/$dist
#pod 	testmatrix	- http://matrix.cpantesters.org/?dist=$dist
#pod 	deps		- http://deps.cpantesters.org/?module=$module
#pod
#pod 	# in weaver.ini
#pod 	[Support]
#pod 	websites = search
#pod 	websites = forum
#pod 	websites = testers , testmatrix
#pod
#pod P.S. If you know other websites that I should include here, please let me know!
#pod
#pod =cut

# TODO how do I Moosify this into a fancy type system where it coerces from CSV strings and bla bla?
has websites => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub { [ 'all' ] },
);

#pod =attr websites_content
#pod
#pod Specify the content to be displayed before the website list.
#pod
#pod The default is a sufficient explanation (see L</SUPPORT>).
#pod
#pod =cut

has websites_content => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub {
		[ <<'EOPOD',
The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.
EOPOD
		];
	},
);

#pod =attr irc
#pod
#pod Specify an IRC server/channel/nick for online support. You can specify as many networks/channels as you want.
#pod The ordering of the options are important, as they are reflected in the final POD.
#pod
#pod You specify a network, then a list of channels/nicks to ask for support. There are two ways to format the string:
#pod
#pod 	servername.com,#room,nick
#pod 	irc://servername.com/#room
#pod
#pod The default is none.
#pod
#pod 	# in weaver.ini
#pod 	[Support]
#pod 	irc = irc.home.org, #support, supportbot
#pod 	irc = irc.acme.com, #acmecorp, #acmehelp, #acmenewbies
#pod
#pod You can also add the irc information in the distribution metadata via L<Dist::Zilla::Plugin::Metadata>.
#pod The key is 'x_IRC' but you have to use the irc:// format to retain compatibility with the rest of the ecosystem.
#pod
#pod 	# in dist.ini
#pod 	[Metadata]
#pod 	x_IRC = irc://irc.perl.org/#perl
#pod
#pod =cut

has irc => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub { [ ] },
);

#pod =attr irc_content
#pod
#pod Specify the content to be displayed before the irc network/channel list.
#pod
#pod The default is a sufficient explanation (see L</SUPPORT>).
#pod
#pod =cut

has irc_content => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub {
		[ <<'EOPOD',
You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:
EOPOD
		];
	},
);

#pod =attr repository_link
#pod
#pod Specify which url to use when composing the external link.
#pod The value corresponds to the repository meta resources (for dzil v3 with CPAN Meta v2).
#pod
#pod Valid options are: "url", "web", "both", or "none".
#pod
#pod "both" will include links to both the "url" and "web" in separate POD paragraphs.
#pod
#pod "none" will skip the repository item entirely.
#pod
#pod The default is "both".
#pod
#pod An error will be thrown if a specified link is not found
#pod because if you said that you wanted it you probably expect it to be there.
#pod
#pod =cut

{
	use Moose::Util::TypeConstraints 1.01;

	has repository_link => (
		is => 'ro',
		isa => enum( [ qw( both none url web ) ] ),
		default => 'both',
	);

	no Moose::Util::TypeConstraints;
}

#pod =attr repository_content
#pod
#pod Specify the content to be displayed before the link to the source code repository.
#pod
#pod The default is a sufficient explanation (see L</SUPPORT>).
#pod
#pod =cut

has repository_content => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub {
		[ <<'EOPOD',
The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)
EOPOD
		];
	},
);

#pod =attr email
#pod
#pod Specify an email address here so users can contact you directly for help.
#pod
#pod If you supply a string without '@' in it, we assume it is a PAUSE id and mangle it into 'USER at cpan.org'.
#pod
#pod The default is none.
#pod
#pod =cut

has email => (
	is => 'ro',
	isa => 'Maybe[Str]',
	default => undef,
);

#pod =attr email_content
#pod
#pod Specify the content for the email section.
#pod
#pod Please put the "{EMAIL}" placeholder somewhere!
#pod
#pod The default is a sufficient explanation ( see L</SUPPORT>).
#pod
#pod =cut

has email_content => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub {
		[ <<'EOPOD',
You can email the author of this module at {EMAIL} asking for help with any problems you have.
EOPOD
		];
	},
);

sub weave_section {
	## no critic ( ProhibitAccessOfPrivateData )
	my ($self, $document, $input) = @_;

	my $zilla = $input->{zilla} or die 'Please use Dist::Zilla with this module!';

	# Is this the main module POD?
	if ( ! $self->all_modules ) {
		return if $zilla->main_module->name ne $input->{filename};
	}

	$document->children->push(
		# Add the stopwords so the spell checker won't complain!
		# TODO make this smarter so it loads only the stopwords we need for specific sections... ohwell
		Pod::Elemental::Element::Pod5::Region->new( {
			format_name => 'stopwords',
			is_pod => 1,
			content => '',
			children => [
				Pod::Elemental::Element::Pod5::Ordinary->new( {
					content => join( " ", qw( cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan ) ),
				} ),
			],
		} ),
		Pod::Elemental::Element::Nested->new( {
			command => 'head1',
			content => 'SUPPORT',
			children => [
				$self->_add_perldoc( $zilla ),
				$self->_add_websites( $zilla ),
				$self->_add_email( $zilla ),
				$self->_add_irc( $zilla ),
				$self->_add_bugs( $zilla, $input->{'distmeta'} ),
				$self->_add_repo( $zilla ),
			],
		} ),
	);
}

sub _add_email {
	my $self = shift;

	# Do we have anything to do?
	return () if ! defined $self->email;

	# pause id for email?
	my $address = $self->email;
	if ( $address !~ /\@/ ) {
		$address = 'C<' . uc( $address ) . ' at cpan.org>';
	} else {
		$address = "C<$address>";
	}

	my $content = join( "\n", @{ $self->email_content } );
	$content =~ s/\{EMAIL\}/$address/;

	return Pod::Elemental::Element::Nested->new( {
		command => 'head2',
		content => 'Email',
		children => [
			Pod::Elemental::Element::Pod5::Ordinary->new( {
				content => $content,
			} ),
		],
	} );
}

sub _add_bugs {
	my( $self, $zilla, $distmeta ) = @_;

	# Do we have anything to do?
	return () if $self->bugs eq 'none';

	# Which kind of text should we display?
	my $text = join( "\n", @{ $self->bugs_content } );
	if ( $self->bugs eq 'rt' ) {
		my $dist = $zilla->name;
		my $mailto = "C<bug-" . lc( $dist ) . " at rt.cpan.org>";
		my $web = "L<https://rt.cpan.org/Public/Bug/Report.html?Queue=$dist>";

		$text =~ s/\{WEB\}/$web/;
		$text =~ s/\{EMAIL\}/$mailto/;
	} else {
		# code copied from Pod::Weaver::Section::Bugs, thanks RJBS!
		$self->log_fatal( 'No bugtracker in metadata!' ) unless exists $distmeta->{resources}{bugtracker};
		my $bugtracker = $distmeta->{resources}{bugtracker};
		my( $web, $mailto ) = @{$bugtracker}{qw/web mailto/};
		$self->log_fatal( 'No bugtracker in metadata!' ) unless defined $web || defined $mailto;

		$text =~ s/\{WEB\}/L\<$web\>/ if defined $web;
		$text =~ s/\{EMAIL\}/C\<$mailto\>/ if defined $mailto;

		# sanity check the content
		if ( $text =~ /\{WEB\}/ ) {
			$self->log_fatal( "The metadata doesn't have a website for the bugtracker but you specified it in the bugs_content!" );
		}
		if ( $text =~ /\{EMAIL\}/ ) {
			$self->log_fatal( "The metadata doesn't have an email for the bugtracker but you specified it in the bugs_content!" );
		}
	}

	return Pod::Elemental::Element::Nested->new( {
		command => 'head2',
		content => 'Bugs / Feature Requests',
		children => [
			Pod::Elemental::Element::Pod5::Ordinary->new( {
				content => $text,
			} ),
		],
	} );
}

sub _add_perldoc {
	my( $self, $zilla ) = @_;

	# Do we have anything to do?
	return () if ! $self->perldoc;

	# Don't use $zilla->name as some dists' name is different from the actual module...
	# TODO what if user specified $self->all_modules( 1 )? should this use the current filename?
	my $main_module = $zilla->main_module->name;
	$main_module =~ s|^lib/||i;
	$main_module =~ s/\.pm$//;
	$main_module =~ s|/|::|g;

	# TODO add language detection as per RT#63726

	return Pod::Elemental::Element::Nested->new( {
		command => 'head2',
		content => 'Perldoc',
		children => [
			Pod::Elemental::Element::Pod5::Ordinary->new( {
			content => <<'EOPOD',
You can find documentation for this module with the perldoc command.
EOPOD

			} ),
			Pod::Elemental::Element::Pod5::Verbatim->new( {
				content => "  perldoc $main_module",
			} ),
		],
	} );
}

sub _add_irc {
	my $self = shift;
	my $zilla = shift;

	my @irc;

	# thanks to https://metacpan.org/about/metadata for the info!
	if ( scalar @{ $self->irc } ) {
		$self->log( 'IRC was set twice: in the metadata and in this plugin, overriding the metadata!' ) if exists $zilla->distmeta->{'x_IRC'};
		@irc = @{ $self->irc };
	} elsif ( exists $zilla->distmeta->{'x_IRC'} ) {
		my $x_irc = $zilla->distmeta->{'x_IRC'};
		if ( ref $x_irc ) { # handle the newer url/web nested spec
			$x_irc = $x_irc->{'url'};
		}
		if ( $x_irc =~ m|^irc://([^/]+)/(.+)$| ) {
			push( @irc, "$1,$2" );
		} else {
			$self->log( "Error: the IRC metadata needs to be in the proper format: 'irc://servername.com/#room' but yours was: $x_irc" );
			return ();
		}
	} else {
		return ();
	}

	my @networks;
	foreach my $entry ( @irc ) {
		my( $net, @chans, @nicks );
		if ( $entry =~ m|^irc://([^/]+)/(.+)$| ) {
			$net = $1;
			push( @chans, $2 );
		} else {
			# Split it into fields
			my @data = split( /\,/, $entry );
			$_ =~ s/^\s+//g for @data;
			$_ =~ s/\s+$//g for @data;

			# Add the network data!
			$net = shift @data;
			foreach my $e ( @data ) {
				if ( $e =~ /^\#/ ) {
					push( @chans, $e );
				} else {
					push( @nicks, $e );
				}
			}
		}

		my $text = "You can connect to the server at '$net'";
		if ( @chans ) {
			if ( @chans > 1 ) {
				$text .= " and join those channels: ";
				$text .= join( ' , ', @chans );
			} else {
				$text .= " and join this channel: $chans[0]";
			}
		}
		if ( @nicks ) {
			if ( @chans ) {
				$text .= " then";
			} else {
				$text .= " and";
			}

			if ( @nicks > 1 ) {
				$text .= " talk to those people for help: ";
				$text .= join( ' , ', @nicks );
			} else {
				$text .= " talk to this person for help: $nicks[0]";
			}
		}
		if ( ! @nicks ) {
			$text .= " to get help";
		}
		$text .= '.';

		push( @networks, _make_item( $net, $text ) );
	}

	return Pod::Elemental::Element::Nested->new( {
		command => 'head2',
		content => 'Internet Relay Chat',
		children => [
			Pod::Elemental::Element::Pod5::Ordinary->new( {
				content => join( "\n", @{ $self->irc_content } ),
			} ),
			Pod::Elemental::Element::Nested->new( {
				command => 'over',
				content => '4',
				children => [
					@networks,
					Pod::Elemental::Element::Pod5::Command->new( {
						command => 'back',
						content => '',
					} ),
				],
			} ),
		],
	} );
}

sub _add_repo {
	my( $self, $zilla ) = @_;

	# Do we have anything to do?
	return () if $self->repository_link eq 'none';

	my $repo;
	if ( exists $zilla->distmeta->{resources}{repository} ) {
		$repo = $zilla->distmeta->{resources}{repository};
	} else {
		$self->log_fatal( [
			"Repository information in meta.resources.repository is missing and you wanted: %s",
			$self->repository_link eq 'both' ? 'both (web and url)' : $self->repository_link,
		] );
	}

	my $text = join( "\n", @{ $self->repository_content } );
	$text .= "\n"; # for the links to be appended

	# for dzil v3 with CPAN Meta v2
	if ( ref $repo ) {
		# add the web url?
		if ( $self->repository_link eq 'web' or $self->repository_link eq 'both' ) {
			if ( exists $repo->{web} ) {
				$text .= 'L<' . $repo->{web} . ">";
			} else {
				$self->log_fatal("Expected to find 'web' repository link but it is missing in the metadata!");
			}
		}

		if ( $self->repository_link eq 'url' or $self->repository_link eq 'both' ) {
			if ( ! exists $repo->{url} ) {
				$self->log_fatal("Expected to find 'url' repository link but it is missing in the metadata!");
			}

			if ( $self->repository_link eq 'both' ) {
				$text .= "\n\n";
			}

			# do we have a type?
			$text .= '  ';
			if ( exists $repo->{type} ) {
				# list of repo types taken from Dist::Zilla::Plugin::Repository v0.16
				if ( $repo->{type} eq 'git' ) {
					$text .= 'git clone';
				} elsif ( $repo->{type} eq 'svn' ) {
					$text .= 'svn checkout';
				} elsif ( $repo->{type} eq 'darcs' ) {
					$text .= 'darcs get';
				} elsif ( $repo->{type} eq 'hg' ) {
					$text .= 'hg clone';
				} else {
					# TODO add support for other formats? cvs/bzr? they're not in DZP::Repository...
				}

				$text .= ' ' . $repo->{url};
			} else {
				$text .= $repo->{url};
			}
		}
	} else {
		$self->log_warning("You need to update Dist::Zilla::Plugin::Repository to at least v0.15 for the correct metadata!");
		$text .= "L<$repo>";
	}

	return Pod::Elemental::Element::Nested->new( {
		command => 'head2',
		content => 'Source Code',
		children => [
			Pod::Elemental::Element::Pod5::Ordinary->new( {
				content => $text,
			} ),
		],
	} );
}

sub _add_websites {
	my( $self, $zilla ) = @_;

	# Do we have anything to do?
	return () if ! scalar @{ $self->websites };
	return () if grep { $_ eq 'none' } @{ $self->websites }; ## no critic ( BuiltinFunctions::ProhibitBooleanGrep )

	# explode CSV lists
	my @newlist;
	foreach my $w ( @{ $self->websites } ) {
		if ( $w =~ /,/ ) {
			my @list = split( /\,/, $w );
			$_ =~ s/^\s+//g for @list;
			$_ =~ s/\s+$//g for @list;
			push( @newlist, @list );
		} else {
			$w =~ s/^\s+//g;
                        $w =~ s/\s+$//g;
			push( @newlist, $w );
		}
	}
	@{ $self->websites } = @newlist;

	# sanity check
	foreach my $type ( @{ $self->websites } ) {
		if ( $type !~ /^(?:metacpan|search|rt|anno|ratings|forum|kwalitee|testers|testmatrix|deps|all)$/i ) {
			$self->log_fatal( "Unknown website type: $type" );
		}
	}

	# Set the default ordering for "all"
	if ( grep { $_ eq 'all' } @{ $self->websites } ) { ## no critic ( BuiltinFunctions::ProhibitBooleanGrep )
		@{ $self->websites } = qw( metacpan search rt anno ratings forum kwalitee testers testmatrix deps );
	}

	# Make the website links!
	my @links;
	my %seen_type;
	foreach my $type ( @{ $self->websites } ) {
		next if $seen_type{$type}++;
		$type = '_add_websites_' . $type;
		my $main_module = $zilla->main_module->name;
		$main_module =~ s|^lib/||i;
		$main_module =~ s/\.pm$//;
		$main_module =~ s|/|::|g;

		# TODO I'm too lazy to build a proper dispatch table...
		no strict 'refs';
		push( @links, &$type( $zilla->name, $main_module ) );
	}

	return Pod::Elemental::Element::Nested->new( {
		command => 'head2',
		content => 'Websites',
		children => [
			Pod::Elemental::Element::Pod5::Ordinary->new( {
				content => join( "\n", @{ $self->websites_content } ),
			} ),
			Pod::Elemental::Element::Nested->new( {
				command => 'over',
				content => '4',
				children => [
					@links,
					Pod::Elemental::Element::Pod5::Command->new( {
						command => 'back',
						content => '',
					} ),
				],
			} ),
		],
	} );
}

sub _add_websites_metacpan {
	my $dist = shift;

	return _make_item( 'MetaCPAN', <<"EOF" );
A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/$dist>
EOF
}

sub _add_websites_search {
	my $dist = shift;

	return _make_item( 'Search CPAN', <<"EOF" );
The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/$dist>
EOF
}

sub _add_websites_rt {
	my $dist = shift;

	return _make_item( "RT: CPAN's Bug Tracker", <<"EOF" );
The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=$dist>
EOF
}

sub _add_websites_anno {
	my $dist = shift;

	return _make_item( 'AnnoCPAN', <<"EOF" );
The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/$dist>
EOF
}

sub _add_websites_ratings {
	my $dist = shift;

	return _make_item( 'CPAN Ratings', <<"EOF" );
The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/$dist>
EOF
}

sub _add_websites_forum {
	my $dist = shift;

	return _make_item( 'CPAN Forum', <<"EOF" );
The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/$dist>
EOF
}

sub _add_websites_kwalitee {
	my $dist = shift;

	return _make_item( 'CPANTS', <<"EOF" );
The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/$dist>
EOF
}

sub _add_websites_testers {
	my $dist = shift;

	my $first_char = substr( $dist, 0, 1 );

	return _make_item( 'CPAN Testers', <<"EOF" );
The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/$first_char/$dist>
EOF
}

sub _add_websites_testmatrix {
	my $dist = shift;

	return _make_item( 'CPAN Testers Matrix', <<"EOF" );
The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=$dist>
EOF
}

sub _add_websites_deps {
	my $module = $_[1];

	return _make_item( 'CPAN Testers Dependencies', <<"EOF" );
The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=$module>
EOF
}

sub _make_item {
	my( $title, $contents ) = @_;

	my $str = $title;
	if ( defined $contents ) {
		$str .= "\n\n$contents";
	}

	return Pod::Elemental::Element::Nested->new( {
		command => 'item',
		content => '*',
		children => [
			Pod::Elemental::Element::Pod5::Ordinary->new( {
				content => $str,
			} ),
		],
	} );
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee
diff irc mailto metadata placeholders metacpan dist dzil repo

=for Pod::Coverage weave_section mvp_multivalue_args

=head1 NAME

Pod::Weaver::Section::Support - Add a SUPPORT section to your POD

=head1 VERSION

  This document describes v1.007 of Pod::Weaver::Section::Support - released November 04, 2014 as part of Pod-Weaver-Section-Support.

=head1 DESCRIPTION

This section plugin will produce a hunk of pod that lists the various ways to get support
for this module. It will do this only if it is being built with L<Dist::Zilla>
because it needs the data from the dzil object.

If you have L<Dist::Zilla::Plugin::Repository> enabled in your F<dist.ini>, be sure to check the
repository_link attribute!

This is added B<ONLY> to the main module's POD, because it would be a waste of space to add it to all
modules in the dist.

For an example of what the hunk looks like, look at the L</SUPPORT> section in this POD :)

=head1 ATTRIBUTES

=head2 all_modules

Enable this if you want to add the SUPPORT section to all the modules in a dist, not only the main one.

The default is false.

=head2 perldoc

Specify if you want the paragraph explaining about perldoc to be displayed or not.

The default is true.

=head2 bugs

Specify the bugtracker you want to use. You can use the CPAN RT tracker or your own, specified in the metadata.

Valid options are: "rt", "metadata", or "none"

If you pick the "rt" option, this module will generate a predefined block of text explaining how to use the RT system.

If you pick the "metadata" option, this module will check the L<Dist::Zilla> metadata for the bugtracker to display. Be sure
to verify that your metadata contains both 'web' and 'mailto' keys if you want to use them in the content!

The default is "rt".

=head2 bugs_content

Specify the content for the bugs section.

Please put the "{EMAIL}" and "{WEB}" placeholders somewhere!

The default is a sufficient explanation (see L</SUPPORT>).

=head2 websites

Specify what website links you want to see. This is an array, and you can pick any combination. You can also
specify it as a comma-delimited string. The ordering of the options are important, as they are reflected in
the final POD.

Valid options are: "none", "metacpan", "search", "rt", "anno", "ratings", "forum", "kwalitee", "testers", "testmatrix", "deps" and "all".

The default is "all".

	# Where the links go to:
	metacpan	- http://metacpan.org/release/$dist
	search		- http://search.cpan.org/dist/$dist
	rt		- https://rt.cpan.org/Public/Dist/Display.html?Name=$dist
	anno		- http://annocpan.org/dist/$dist
	ratings		- http://cpanratings.perl.org/d/$dist
	forum		- http://cpanforum.com/dist/$dist
	kwalitee	- http://cpants.perl.org/dist/$dist
	testers		- http://cpantesters.org/distro/$first_char/$dist
	testmatrix	- http://matrix.cpantesters.org/?dist=$dist
	deps		- http://deps.cpantesters.org/?module=$module

	# in weaver.ini
	[Support]
	websites = search
	websites = forum
	websites = testers , testmatrix

P.S. If you know other websites that I should include here, please let me know!

=head2 websites_content

Specify the content to be displayed before the website list.

The default is a sufficient explanation (see L</SUPPORT>).

=head2 irc

Specify an IRC server/channel/nick for online support. You can specify as many networks/channels as you want.
The ordering of the options are important, as they are reflected in the final POD.

You specify a network, then a list of channels/nicks to ask for support. There are two ways to format the string:

	servername.com,#room,nick
	irc://servername.com/#room

The default is none.

	# in weaver.ini
	[Support]
	irc = irc.home.org, #support, supportbot
	irc = irc.acme.com, #acmecorp, #acmehelp, #acmenewbies

You can also add the irc information in the distribution metadata via L<Dist::Zilla::Plugin::Metadata>.
The key is 'x_IRC' but you have to use the irc:// format to retain compatibility with the rest of the ecosystem.

	# in dist.ini
	[Metadata]
	x_IRC = irc://irc.perl.org/#perl

=head2 irc_content

Specify the content to be displayed before the irc network/channel list.

The default is a sufficient explanation (see L</SUPPORT>).

=head2 repository_link

Specify which url to use when composing the external link.
The value corresponds to the repository meta resources (for dzil v3 with CPAN Meta v2).

Valid options are: "url", "web", "both", or "none".

"both" will include links to both the "url" and "web" in separate POD paragraphs.

"none" will skip the repository item entirely.

The default is "both".

An error will be thrown if a specified link is not found
because if you said that you wanted it you probably expect it to be there.

=head2 repository_content

Specify the content to be displayed before the link to the source code repository.

The default is a sufficient explanation (see L</SUPPORT>).

=head2 email

Specify an email address here so users can contact you directly for help.

If you supply a string without '@' in it, we assume it is a PAUSE id and mangle it into 'USER at cpan.org'.

The default is none.

=head2 email_content

Specify the content for the email section.

Please put the "{EMAIL}" placeholder somewhere!

The default is a sufficient explanation ( see L</SUPPORT>).

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Pod::Weaver::Section::Support

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Pod-Weaver-Section-Support>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Pod-Weaver-Section-Support>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Weaver-Section-Support>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Pod-Weaver-Section-Support>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Pod-Weaver-Section-Support>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Pod-Weaver-Section-Support>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/overview/Pod-Weaver-Section-Support>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/P/Pod-Weaver-Section-Support>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Pod-Weaver-Section-Support>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Pod::Weaver::Section::Support>

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

Please report any bugs or feature requests by email to C<bug-pod-weaver-section-support at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Weaver-Section-Support>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/apocalypse/perl-pod-weaver-section-support>

  git clone https://github.com/apocalypse/perl-pod-weaver-section-support.git

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head2 CONTRIBUTORS

=for stopwords Alex Peters Kent Fredric Randy Stauner

=over 4

=item *

Alex Peters <lxp@cpan.org>

=item *

Kent Fredric <kentfredric@gmail.com>

=item *

Randy Stauner <randy@magnificent-tears.com>

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
