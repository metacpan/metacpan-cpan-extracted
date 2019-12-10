package RDF::DOAP::Project;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.104';

use Moose;
extends qw(RDF::DOAP::Resource);

use RDF::DOAP::Person;
use RDF::DOAP::Version;
use RDF::DOAP::Repository;
use RDF::DOAP::Types -types;
use RDF::DOAP::Utils -traits;

use RDF::Trine::Namespace qw(rdf rdfs owl xsd);
my $doap = 'RDF::Trine::Namespace'->new('http://usefulinc.com/ns/doap#');

has $_ => (
	traits     => [ WithURI ],
	is         => 'ro',
	isa        => String,
	coerce     => 1,
	uri        => do { (my $x = $_) =~ s/_/-/g; $doap->$x },
) for qw(name shortdesc created description programming_language os );

has release => (
	traits     => [ WithURI ],
	is         => 'ro',
	isa        => ArrayRef[Version],
	coerce     => 1,
	uri        => $doap->release,
	multi      => 1,
);

has $_ => (
	traits     => [ WithURI, Gathering ],
	is         => 'ro',
	isa        => ArrayRef[Person],
	coerce     => 1,
	multi      => 1,
	uri        => $doap->$_,
	gather_as  => ['maintainer'],
) for qw( maintainer );

has $_ => (
	traits     => [ WithURI, Gathering ],
	is         => 'ro',
	isa        => ArrayRef[Person],
	coerce     => 1,
	multi      => 1,
	uri        => $doap->$_,
	gather_as  => ['contributor'],
) for qw( developer documenter );

has $_ => (
	traits     => [ WithURI, Gathering ],
	is         => 'ro',
	isa        => ArrayRef[Person],
	coerce     => 1,
	multi      => 1,
	uri        => $doap->$_,
	gather_as  => ['thanks'],
) for qw( translator tester helper );

has $_ => (
	traits     => [ WithURI ],
	is         => 'ro',
	isa        => Identifier,
	coerce     => 1,
	uri        => do { (my $x = $_) =~ s/_/-/g; $doap->$x },
) for qw( wiki bug_database mailing_list download_page );

has $_ => (
	traits     => [ WithURI ],
	is         => 'ro',
	isa        => ArrayRef[Identifier],
	coerce     => 1,
	uri        => do { (my $x = $_) =~ s/_/-/g; $doap->$x },
	multi      => 1,
) for qw( homepage old_homepage license download_mirror screenshots category support_forum developer_forum );

has repository => (
	traits     => [ WithURI ],
	is         => 'ro',
	isa        => ArrayRef[Repository],
	coerce     => 1,
	multi      => 1,
	uri        => $doap->repository,
);

around homepage => sub {
	my ($orig, $self, @args) = (shift, shift, @_);
	if (@args) {
		return $self->$orig(@args);
	}
	else {
		return [
			# de-prioritize metacpan links
			sort {
				("$a" =~ /metacpan/ && "$b" =~ /metacpan/) ? ("$a" cmp "$b") :
				("$a" =~ /metacpan/)                       ?  1              :
				("$b" =~ /metacpan/)                       ? -1              : ("$a" cmp "$b")
			} @{ $self->$orig() }
		];
	}
};

sub rdf_load_all
{
	my $class = shift;
	my ($model) = @_;
	map $class->rdf_load($_, $model), $model->subjects($rdf->type, $doap->Project);
}

sub gather_all_maintainers
{
	require RDF::DOAP::Utils;
	my $self = shift;
	RDF::DOAP::Utils::gather_objects($self, 'maintainer');
}

sub gather_all_contributors
{
	require RDF::DOAP::Utils;
	my $self = shift;
	RDF::DOAP::Utils::gather_objects($self, 'contributor');
}

sub gather_all_thanks
{
	require RDF::DOAP::Utils;
	my $self = shift;
	RDF::DOAP::Utils::gather_objects($self, 'thanks');
}

sub sorted_releases
{
	my $self = shift;
	my @rels = sort {
		($a->revision  and $b->revision  and version->parse($a->revision) cmp version->parse($b->revision)) or
		($a->issued    and $b->issued    and $a->issued cmp $b->issued) or
		($a->rdf_about and $b->rdf_about and $a->rdf_about->as_ntriples cmp $b->rdf_about->as_ntriples)
	} @{$self->release};
	return \@rels;
}

sub changelog
{
	my $self = shift;
	
	my @releases = @{ $self->sorted_releases };
	my @filtered_releases;
	while (@releases) {
		my $next = shift @releases;
		if (@releases) {
			my $found_catchup = undef;
			for my $i (reverse(0 .. $#releases)) {
				for my $cs (@{ $releases[$i]->changesets || [] }) {
					if ($cs->has_versus and $cs->versus->revision eq $next->revision) {
						$found_catchup = $i;
					}
				}
			}
			if ($found_catchup) {
				my @intermediates = splice(@releases, 0, $found_catchup);
				push @filtered_releases, $next->changelog_section;
				push @filtered_releases, map $_->_changelog_section_header, @intermediates;
			}
			else {
				push @filtered_releases, $next->changelog_section;
			}
		}
		else {
			push @filtered_releases, $next->changelog_section;
		}
	}
	
	return join "\n",
		$self->_changelog_header,
		reverse @filtered_releases;
}

sub _changelog_header
{
	my $self = shift;
	my @lines = (
		$self->name,
		("=" x length($self->name)),
		"",
	);
	push @lines, sprintf('%-14s%s', "$_->[0]:", $_->[1])
		for grep defined($_->[1]), (
			["Created" => $self->created],
			map(["Home page"=>$_], @{$self->homepage||[]}),
			["Bug tracker" => $self->bug_database],
			["Wiki" => $self->wiki],
			["Mailing list" => $self->mailing_list],
			map(["Maintainer"=>$_->to_string], @{$self->maintainer||[]}),
		);
	return join("\n", @lines)."\n";
}

1;
