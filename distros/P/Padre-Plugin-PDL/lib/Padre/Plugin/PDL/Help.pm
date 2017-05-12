package Padre::Plugin::PDL::Help;

use 5.008;
use strict;
use warnings;

# For Perl 6 documentation support
use Padre::Help ();

our $VERSION = '0.05';

our @ISA = 'Padre::Help';

#
# Initialize help
#
sub help_init {
	my $self = shift;

	# Workaround to get Perl + PDL help. Also, we'll need this so we can clean
	# out things from the PDL help list that are already covered by Perl's
	# normal help facilities.
	require Padre::Document::Perl::Help;
	$self->{p5_help} = Padre::Document::Perl::Help->new;
	$self->{p5_help}->help_init;

	require Padre::Plugin::PDL::Util;
	my $pdldoc = Padre::Plugin::PDL::Util::get_pdldoc();
	if ( defined $pdldoc ) {
		$self->{pdldoc}      = $pdldoc;
		$self->{pdldoc_hash} = $pdldoc->gethash;
	}
}

#
# Renders the help topic content
#
sub help_render {
	my $self  = shift;
	my $topic = shift;

	my ( $html, $location );
	my $pdldoc_hash = $self->{pdldoc_hash};
	if ( defined $pdldoc_hash && exists $pdldoc_hash->{$topic} ) {
		require Padre::Pod2HTML;

		# We have two possibilities: the $topic can either be a module,
		# or it can be a function. If the latter, we extract its pod
		# from the database.
		# If the former, just pull the pod from the file. We distinguish
		# between them by noting that functions have a Module key,
		# whereas modules (ironically) don't.
		if ( exists $pdldoc_hash->{$topic}->{Module} ) {

			# Get the pod docs from the docs database:
			my $pod_handler = StrHandle->new; # defined in PDL::Doc
			$self->{pdldoc}->funcdocs( $topic, $pod_handler );

			# Convert them to HTML
			$html = Padre::Pod2HTML->pod2html( $pod_handler->text );

			# Replace the filename in the "docs from" section with
			# the module name
			my $module_name = $pdldoc_hash->{$topic}{Module};
			$html =~ s{Docs from .*\.pm}
				{Docs from <a href="perldoc:$module_name">$module_name<\/a>};
		} else {
			$html = Padre::Pod2HTML->file2html( $pdldoc_hash->{$topic}->{File} );
		}

		$location = $topic;
	} else {
		( $html, $location ) = $self->{p5_help}->help_render($topic);
	}

	return ( $html, $location );
}

#
# Returns the help topic list
#
sub help_list {
	my $self = shift;

	# Return a unique sorted index
	my @index = keys %{ $self->{pdldoc_hash} };

	# Add Perl 5 help index to PDL
	push @index, @{ $self->{p5_help}->help_list };

	# Make sure things are only listed once:
	my %seen = ();
	my @unique_sorted_index = sort grep { !$seen{$_}++ } @index;
	return \@unique_sorted_index;
}

1;

__END__

=head1 NAME

Padre::Plugin::PDL::Help - PDL help provider for Padre

=head1 DESCRIPTION

PDL Help index is built here and rendered.
