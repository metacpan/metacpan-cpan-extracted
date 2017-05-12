package RDF::DOAP::Version;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.012';

use Moose;
extends qw(RDF::DOAP::Resource);

use RDF::DOAP::ChangeSet;
use RDF::DOAP::Change;
use RDF::DOAP::Person;
use RDF::DOAP::Types -types;
use RDF::DOAP::Utils -traits;
use List::MoreUtils qw(uniq);
use Text::Wrap qw(wrap);

use RDF::Trine::Namespace qw(rdf rdfs owl xsd);
my $doap = 'RDF::Trine::Namespace'->new('http://usefulinc.com/ns/doap#');
my $dc   = 'RDF::Trine::Namespace'->new('http://purl.org/dc/terms/');
my $dcs  = 'RDF::Trine::Namespace'->new('http://ontologi.es/doap-changeset#');

has $_ => (
	traits     => [ WithURI ],
	is         => 'ro',
	isa        => String,
	coerce     => 1,
	uri        => $doap->$_,
) for qw( revision name branch );

has issued => (
	traits     => [ WithURI ],
	is         => 'ro',
	isa        => String,
	coerce     => 1,
	uri        => $dc->issued,
);

has changesets => (
	traits     => [ WithURI ],
	is         => 'ro',
	isa        => ArrayRef[ChangeSet],
	coerce     => 1,
	uri        => $dcs->changeset,
	multi      => 1,
	trigger    => sub { $_[0]->clear_changes },
);

has changes => (
	is         => 'ro',
	isa        => ArrayRef[Change],
	coerce     => 1,
	lazy       => 1,
	builder    => '_build_changes',
	clearer    => 'clear_changes',
);

has released_by => (
	traits     => [ WithURI, Gathering ],
	is         => 'ro',
	isa        => Person,
	coerce     => 1,
	uri        => $dcs->uri('released-by'),
	gather_as  => ['maintainer'],
);

has _changelog_subsections => (
	is         => 'ro',
	isa        => ArrayRef[ArrayRef],
	lazy       => 1,
	builder    => '_build_changelog_subsections',
);

sub _build_changes
{
	my $self = shift;
	[ map { @{$_->items} } @{$self->changesets || []} ];
}

sub changelog_section
{
	my $self = shift;
	
	my @ss = @{ $self->_changelog_subsections };
	
	if (@ss == 1 and $ss[0][0] eq 'Other')
	{
		# If there's only an "Other" section, then avoid
		# printing a section header for it.
		return join(
			"\n",
			$self->_changelog_section_header,
			map {
				my ($head, @lines) = @$_;
				(sort(@lines), '');
			} @ss,
		);
	}
	
	return join(
		"\n",
		$self->_changelog_section_header,
		map {
			my ($head, @lines) = @$_;
			(" [ $head ]", sort(@lines), '');
		} @ss,
	);
}

sub _changelog_section_header
{
	my $self = shift;
	return join(
		"\t",
		grep(
			defined,
			$self->revision,
			($self->issued // 'Unknown'),
			($self->name // $self->label),
		),
	) . "\n";
}

sub _subsection_order
{
	my $self = shift;
	uniq(map $_->[1], $self->_subsection_classification);
}

sub _subsection_classification
{
	(
		[$dcs->SecurityFix        => 'SECURITY', 'Fix'],
		[$dcs->SecurityRegression => 'SECURITY', 'Regression'],
		[$dcs->BackCompat         => 'BACK COMPAT'],
		[$dcs->Regression         => 'REGRESSIONS'],
		[$dcs->Bugfix             => 'Bug Fixes'],
		[$dcs->Documentation      => 'Documentation'],
		[$dcs->Tests              => 'Test Suite'],
		[$dcs->Packaging          => 'Packaging'],
		[$dcs->Addition           => 'Other', 'Added'],
		[$dcs->Removal            => 'Other', 'Removed'],
		[$dcs->Update             => 'Other', 'Updated'],
		[$dcs->Change             => 'Other'],
	);
}

sub _build_changelog_subsections
{
	my $self = shift;
	
	my %sections;
	my @classifications = $self->_subsection_classification;
	
	for my $ch (@{ $self->changes })
	{
		my $found_section;
		for my $class (@classifications)
		{
			my ($type, $section, $tag) = @$class;
			if ( $ch->isa($type) )
			{
				my $text = join "\n", $ch->changelog_lines(1);
				$text = "$tag: $text" if $tag;
				push @{ $sections{$section} }, wrap(" - ", "   ", $text);
				$found_section++;
				last;
			}
		}
		unless ($found_section)
		{
			my $text = join "\n", $ch->changelog_lines(1);
			push @{ $sections{Other} }, wrap(" - ", "   ", $text);
		}
	}
	
	return [
		map { exists($sections{$_}) ? [$_, @{$sections{$_}}] : (); }
		$self->_subsection_order
	];
}

1;
