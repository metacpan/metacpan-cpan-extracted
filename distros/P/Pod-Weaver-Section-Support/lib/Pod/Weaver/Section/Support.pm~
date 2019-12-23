package Pod::Weaver::Section::Support;

# ABSTRACT: Add a SUPPORT section to your POD

use Moose 1.03;
use PPIx::DocumentName;

with 'Pod::Weaver::Role::Section' => { -version => '3.100710' };

sub mvp_multivalue_args { qw( websites irc bugs_content email_content irc_content repository_content websites_content ) }

=head1 NAME

Pod::Weaver::Section::Support - Add a SUPPORT section to your POD

=attr all_modules

Enable this if you want to add the SUPPORT section to all the modules in a dist, not only the main one.

The default is false.

=cut

has all_modules => (
	is => 'ro',
	isa => 'Bool',
	default => 0,
);

=attr perldoc

Specify if you want the paragraph explaining about perldoc to be displayed or not.

The default is true.

=cut

has perldoc => (
	is => 'ro',
	isa => 'Bool',
	default => 1,
);

=attr bugs

Specify the bugtracker you want to use. You can use the CPAN RT tracker or your own, specified in the metadata.

Valid options are: "rt", "metadata", or "none"

If you pick the "rt" option, this module will generate a predefined block of text explaining how to use the RT system.

If you pick the "metadata" option, this module will check the L<Dist::Zilla> metadata for the bugtracker to display. Be sure
to verify that your metadata contains both 'web' and 'mailto' keys if you want to use them in the content!

The default is "rt".

=cut

{
	use Moose::Util::TypeConstraints 1.01;

	has bugs => (
		is => 'ro',
		isa => enum( [ qw( rt metadata none ) ] ),
		default => 'rt',
	);

	no Moose::Util::TypeConstraints;
}

=attr bugs_content

Specify the content for the bugs section.

Please put the "{EMAIL}" and "{WEB}" placeholders somewhere!

The default is a sufficient explanation (see L</SUPPORT>).

=cut

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

=attr websites

Specify what website links you want to see. This is an array, and you can pick any combination. You can also
specify it as a comma-delimited string. The ordering of the options are important, as they are reflected in
the final POD.

Valid options are: "none", "metacpan", "search", "rt", "ratings", "kwalitee", "testers", "testmatrix", "deps" and "all".

The default is "all".

	# Where the links go to:
	metacpan	- https://metacpan.org/release/$dist
	search		- http://search.cpan.org/dist/$dist
	rt		- https://rt.cpan.org/Public/Dist/Display.html?Name=$dist
	ratings		- http://cpanratings.perl.org/d/$dist
	kwalitee	- http://cpants.perl.org/dist/$dist
	testers		- http://cpantesters.org/distro/$first_char/$dist
	testmatrix	- http://matrix.cpantesters.org/?dist=$dist
	deps		- http://deps.cpantesters.org/?module=$module

	# in weaver.ini
	[Support]
	websites = search
	websites = metacpan
	websites = testers , testmatrix

P.S. If you know other websites that I should include here, please let me know!

=cut

# TODO how do I Moosify this into a fancy type system where it coerces from CSV strings and bla bla?
has websites => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub { [ 'all' ] },
);

=attr websites_content

Specify the content to be displayed before the website list.

The default is a sufficient explanation (see L</SUPPORT>).

=cut

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

=attr irc

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

=cut

has irc => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub { [ ] },
);

=attr irc_content

Specify the content to be displayed before the irc network/channel list.

The default is a sufficient explanation (see L</SUPPORT>).

=cut

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

=attr repository_link

Specify which url to use when composing the external link.
The value corresponds to the repository meta resources (for dzil v3 with CPAN Meta v2).

Valid options are: "url", "web", "both", or "none".

"both" will include links to both the "url" and "web" in separate POD paragraphs.

"none" will skip the repository item entirely.

The default is "both".

An error will be thrown if a specified link is not found
because if you said that you wanted it you probably expect it to be there.

=cut

{
	use Moose::Util::TypeConstraints 1.01;

	has repository_link => (
		is => 'ro',
		isa => enum( [ qw( both none url web ) ] ),
		default => 'both',
	);

	no Moose::Util::TypeConstraints;
}

=attr repository_content

Specify the content to be displayed before the link to the source code repository.

The default is a sufficient explanation (see L</SUPPORT>).

=cut

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

=attr email

Specify an email address here so users can contact you directly for help.

If you supply a string without '@' in it, we assume it is a PAUSE id and mangle it into 'USER at cpan.org'.

The default is none.

=cut

has email => (
	is => 'ro',
	isa => 'Maybe[Str]',
	default => undef,
);

=attr email_content

Specify the content for the email section.

Please put the "{EMAIL}" placeholder somewhere!

The default is a sufficient explanation ( see L</SUPPORT>).

=cut

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

	# Add the stopwords so the spell checker won't complain!
	# TODO make this smarter so it loads only the stopwords we need for specific sections... ohwell
	push @{ $document->children }, Pod::Elemental::Element::Pod5::Region->new( {
			format_name => 'stopwords',
			is_pod => 1,
			content => '',
			children => [
				Pod::Elemental::Element::Pod5::Ordinary->new( {
					content => join( " ", qw( cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan ) ),
				} ),
			],
	} ),
	Pod::Elemental::Element::Nested->new( {
			command => 'head1',
			content => 'SUPPORT',
			children => [
				$self->_add_perldoc( $input->{ppi_document} ),
				$self->_add_websites( $zilla ),
				$self->_add_email( $zilla ),
				$self->_add_irc( $zilla ),
				$self->_add_bugs( $zilla, $input->{'distmeta'} ),
				$self->_add_repo( $zilla ),
			],
	} );
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
	my( $self, $ppi_doc ) = @_;

	# Do we have anything to do?
	return () if ! $self->perldoc;

	# Get the name for the module
	my $module = PPIx::DocumentName->extract( $ppi_doc );

    # Avoid trailing space and an empty directive
	return () if ! length $module;

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
				content => "  perldoc $module",
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
		if ( $type !~ /^(?:metacpan|search|rt|ratings|kwalitee|testers|testmatrix|deps|all)$/i ) {
			$self->log_fatal( "Unknown website type: $type" );
		}
	}

	# Set the default ordering for "all"
	if ( grep { $_ eq 'all' } @{ $self->websites } ) { ## no critic ( BuiltinFunctions::ProhibitBooleanGrep )
		@{ $self->websites } = qw( metacpan search rt ratings kwalitee testers testmatrix deps );
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

L<https://metacpan.org/release/$dist>
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

sub _add_websites_ratings {
	my $dist = shift;

	return _make_item( 'CPAN Ratings', <<"EOF" );
The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/$dist>
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
The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

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

=pod

=for stopwords dist dzil repo

=for Pod::Coverage weave_section mvp_multivalue_args

=head1 DESCRIPTION

This section plugin will produce a hunk of pod that lists the various ways to get support
for this module. It will do this only if it is being built with L<Dist::Zilla>
because it needs the data from the dzil object.

If you have L<Dist::Zilla::Plugin::Repository> enabled in your F<dist.ini>, be sure to check the
repository_link attribute!

This is added B<ONLY> to the main module's POD, because it would be a waste of space to add it to all
modules in the dist.

For an example of what the hunk looks like, look at the L</SUPPORT> section in this POD :)

=cut
