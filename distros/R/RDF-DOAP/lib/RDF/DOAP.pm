use 5.010;
use strict;
use warnings;

package RDF::DOAP;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.012';

use Moose;
extends 'RDF::DOAP::Resource';

use RDF::Trine;
use RDF::DOAP::Project;
use RDF::DOAP::Types -types;

use RDF::Trine::Namespace qw(rdf rdfs owl xsd);
my $doap = 'RDF::Trine::Namespace'->new('http://usefulinc.com/ns/doap#');

has projects => (
	is         => 'ro',
	isa        => ArrayRef[Project],
	default    => sub { [] },
	coerce     => 1,
	init_arg   => '_projects',
);

sub from_url
{
	require RDF::Trine;
	
	my $class = shift;
	my ($url) = @_;
	
	my $model = 'RDF::Trine::Model'->new;
	'RDF::Trine::Parser'->parse_url_into_model("$url", $model);
	
	return $class->from_model($model, { rdf_about => $url });
}

sub from_file
{
	require RDF::Trine;
	
	my $class = shift;
	my ($fh, $base) = @_;
	$base //= 'http://localhost/';
	
	my $model = 'RDF::Trine::Model'->new;
	'RDF::Trine::Parser'->parse_file_into_model($base, $fh, $model);
	
	return $class->from_model($model);
}

sub from_model
{
	my $class = shift;
	my ($model, $args) = @_;
	
	# required for coercion to work!
	local $RDF::DOAP::Resource::MODEL = $model;
	
	$class->new(
		%{ $args || {} },
		rdf_model => $model,
		_projects => [ $model->subjects($rdf->type, $doap->Project) ],
	);
}

sub project
{
	my $self = shift;
	
	my @projects = @{$self->projects};
	return $projects[0] if @projects <= 1;
	
	my @sorted =
		map $_->[0],
		sort { $b->[1] <=> $a->[1] }
		map [
			$_,
			$_->has_rdf_model && $_->has_rdf_about
				? $_->rdf_model->count_statements($_->rdf_about, undef, undef)
				: 0
		], @projects;
	
	return $sorted[0];
}

1;

__END__

=pod

=encoding utf-8

=begin stopwords

rdfs:Resource
doap:Project
doap:Repository
foaf:Person
doap:Version
dcs:ChangeSet
dcs:Change
dbug:Issue

=end stopwords

=head1 NAME

RDF::DOAP - an object-oriented interface for DOAP (Description of a Project) data

=head1 SYNOPSIS

   use feature 'say';
   use RDF::DOAP;
   
   my $url  = 'http://api.metacpan.org/source/DOY/Moose-2.0604/doap.rdf';
   my $doap = 'RDF::DOAP'->from_url($url);
   my $proj = $doap->project;
   
   say $proj->name;       # "Moose"
   
   say $_->name
      for @{ $proj->maintainer };

=head1 DESCRIPTION

A little sparsely documented right now.

The RDF::DOAP class itself is mostly a wrapper for parsing RDF
and building objects. Most of the interesting stuff is in the
L</Bundled Classes>.

=head2 Constructors

=over

=item C<< new(%attrs) >>

You don't want to use this.

=item C<< from_url($url) >>

Parse the RDF at the given URL and construct an RDF::DOAP object.

=item C<< from_file($fh, $base) >>

Parse a file handle or file name. A base URL may be provided for
resolving relative URI references; if omitted the base is assumed
to be C<< http://localhost/ >> which is almost certainly wrong.

=item C<< from_model($model) >>

Read DOAP from an existing L<RDF::Trine::Model>.

=back

=head2 Attributes

=over

=item C<< projects >>

An arrayref; the list of software projects found in the input data.
This cannot be provided in the constructor.

=back

=head2 Methods

=over

=item C<< project >>

If C<< projects >> contains only one project, returns it.

Otherwise, tries to guess which of the projects the input data was
mostly trying to describe.

=back

=head2 Bundled Classes

Within each of these classes, the attributes correspond roughly to
the properties defined for them in the DOAP schema; however hyphens
in property URIs become underscores in attribute names.

=over

=item B<< L<RDF::DOAP::Resource> >>

Correponds roughly to the I<< rdfs:Resource >> class, excluding
literals.

=item B<< L<RDF::DOAP::Project> >>

Correponds to I<< doap:Project >>.

=item B<< L<RDF::DOAP::Repository> >>

Correponds to I<< doap:Repository >>.

=item B<< L<RDF::DOAP::Person> >>

Correponds to I<< foaf:Person >>.

=item B<< L<RDF::DOAP::Version> >>

Correponds to I<< doap:Version >>.

=item B<< L<RDF::DOAP::ChangeSet> >>

Correponds to I<< dcs:ChangeSet >>.

=item B<< L<RDF::DOAP::Change> >>

Correponds to I<< dcs:Change >>.

=item B<< L<RDF::DOAP::Issue> >>

Correponds to I<< dbug:Issue >>.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=RDF-DOAP>.

=head1 SEE ALSO

=over

=item *

Edd Dumbill's series of articles on DOAP's design:
L<part 1|http://www.ibm.com/developerworks/xml/library/x-osproj/>,
L<part 2|http://www.ibm.com/developerworks/xml/library/x-osproj2/>,
L<part 3|http://www.ibm.com/developerworks/xml/library/x-osproj4/> and
L<part 4|http://www.ibm.com/developerworks/xml/library/x-osproj3/>

=item *

L<The DOAP Schema|http://usefulinc.com/ns/doap#>.

=item *

L<The DOAP Change Sets Schema|http://ontologi.es/doap-changeset#>.

=item *

L<The DOAP Bugs Schema|http://ontologi.es/doap-bugs#>.

=back

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

