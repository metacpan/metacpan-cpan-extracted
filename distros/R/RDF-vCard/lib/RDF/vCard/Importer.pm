package RDF::vCard::Importer;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);

use Encode qw[];
use RDF::TrineX::Functions -shortcuts;
use RDF::vCard::Entity;
use RDF::vCard::Line;
use Text::vFile::asData;

use namespace::clean;

our $VERSION = '0.012';

sub new
{
	my ($class, %options) = @_;
	my $self  = bless { %options }, $class;
	$self->init unless $self->model;
	return $self;
}

sub init
{
	my ($self, $model, %opts) = @_;
	$self->{model} = rdf_parse($model, %opts);
	return $self;
}

sub model
{
	my ($self) = @_;
	return $self->{model};
}

*TO_RDF = \&model;

sub _ua
{
	my ($self) = @_;
	$self->{ua} ||= LWP::UserAgent->new(agent => sprintf('%s/%s', __PACKAGE__, $VERSION));
	return $self->{ua};
}

sub import_file
{
	my ($self, $file, %options) = @_;
	open my $fh, "<:encoding(UTF-8)", $file;
	my $cards = Text::vFile::asData->new->parse($fh);
	close $fh;
	return $self->_process($cards, %options);
}

sub import_fh
{
	my ($self, $fh, %options) = @_;
	my $cards = Text::vFile::asData->new->parse($fh);
	return $self->_process($cards, %options);
}

sub import_url
{
	my ($self, $url) = @_;
	my $r = $self->_ua->get($url, Accept=>'text/directory;profile=vCard, text/vcard, text/x-vcard, text/directory;q=0.1');
	return unless $r->is_success;
	return $self->import_string($r->decoded_content, lang => $r->content_language);
}

sub import_string
{
	my ($self, $data, %options) = @_;
	my @lines = split /\r?\n/, $data;
	my $cards = Text::vFile::asData->new->parse_lines(@lines);
	return $self->_process($cards, %options);
}

sub _process
{
	my ($self, $cards, %options) = @_;
	
	my @Cards;
	foreach my $c (@{ $cards->{objects} })
	{
		push @Cards, $self->_process_card($c, %options);
	}
	
	return @Cards;
}

sub _process_card
{
	my ($self, $card, %options) = @_;
	my $C = RDF::vCard->new_entity( profile => $card->{type} );
	
	while (my ($prop, $vals) = each %{ $card->{properties} })
	{
		my $group;
		if ($prop =~ /^(.+)\.([^\.]+)$/) # ignore vCard 4.0 grouping construct
		{
			$prop  = $2;
			$group = $1;
		}
		
		foreach my $val (@$vals)
		{
			my $strval = $val->{value};
			
			# I wish Text::vFile::asData did this for me!
			my $structured_value = ($prop =~ /^(ADR|CATEGORIES|GEO|N|ORG)$/i)
				? $self->_extract_structure($strval)
				: RDF::vCard::Line->_unescape_value($strval);
			# Could technically extract structure for all properties,
			# but it's a waste of time, and some of the RDF::vCard::Line
			# code might cope badly.
			
			my $L = RDF::vCard::Line->new(
				property         => uc $prop,
				value            => $structured_value,
				type_parameters  => do {
					                   # force keys to uppercase
				                      my (%tp, $k, $v);
				                      $tp{uc $k} = $v while ($k, $v) = each %{$val->{param}};
											 \%tp;
				                    },
				);
			$L->type_parameters->{TYPE} = [split /,/, $L->type_parameters->{TYPE}]
				if ($L->type_parameters and $L->type_parameters->{TYPE});
			$L->type_parameters->{_GROUP} = $group
				if $group;
			$L->type_parameters->{LANG} ||= $options{lang} if defined $options{lang};
			
			$C->add($L);
		}
	}
	
	$C->add_to_model( $self->model );
	
	return $C;
}

sub _extract_structure
{
	my ($self, $string) = @_;
	my @naive_parts = split /;/, $string;
	my @parts;
	
	while (my $part = shift @naive_parts)
	{
		push @parts, $part;
		while ($parts[-1] =~ /\\$/ and $parts[-1] !~ /\\\\$/ and @naive_parts)
		{
			$parts[-1] =~ s/\\$/;/;
			$parts[-1] .= shift @naive_parts;
		}
	}
	
	my @rv;
	foreach my $part (@parts)
	{
		my @naive_subparts = split /,/, $part;
		my @subparts;

		while (my $subpart = shift @naive_subparts)
		{
			push @subparts, $subpart;
			while ($subparts[-1] =~ /\\$/ and $subparts[-1] !~ /\\\\$/ and @naive_subparts)
			{
				$subparts[-1] =~ s/\\$/,/;
				$subparts[-1] .= shift @naive_subparts;
			}
		}
		
		push @rv, [ map { RDF::vCard::Line->_unescape_value($_) } @subparts ];
	}
	return [@rv];
}

1;

__END__

=head1 NAME

RDF::vCard::Importer - import RDF data from vCard format

=head1 SYNOPSIS

 use RDF::vCard;
 use RDF::TrineShortcuts qw':all';
 
 my $importer = RDF::vCard::Importer->new;
 print $_
	foreach $importer->import_file('contacts.vcf');
 print rdf_string($importer->model => 'RDFXML');

=head1 DESCRIPTION

This module reads vCards and writes RDF.

=head2 Constructor

=over

=item * C<< new(%options) >>

Returns a new RDF::vCard::Importer object and initialises it.

The only valid option currently is B<ua> which can be set to an LWP::UserAgent
for those rare occasions that the Importer needs to fetch stuff from the Web.

=back

=head2 Methods

=over

=item * C<< init >>

Reinitialise the importer. Forgets any cards that have already been imported.

=item * C<< model >>

Return an RDF::Trine::Model containing data for all cards that have been
imported since the importer was last initialised.

=item * C<< import_file($filename, %options) >>

Imports vCard data from a file on the file system.

The data is added to the importer's model (and can be retrieved using the
C<model> method).

This function returns a list of L<RDF::vCard::Entity> objects, so it's
also possible to access the data that way.

There is currently only one supported option: C<lang> which takes an
ISO language code indicating the default language of text within the vCard
data.

=item * C<< import_fh($filehandle, %options) >>

As per C<import_file>, but operates on a file handle.

=item * C<< import_string($string, %options) >>

As per C<import_file>, but operates on vCard data in a string.

=item * C<< import_url($url) >>

As per C<import_file>, but fetches vCard data from a Web address.

Sends an HTTP Accept header of:

  text/directory;profile=vCard,
  text/vcard,
  text/x-vcard,
  text/directory;q=0.1

=back

=begin private

=item TO_RDF

=end private

=head2 vCard Input

vCard 3.0 should be supported fairly completely. Some vCard 4.0 constructs
will also work.

Much of the heavy lifting is performed by L<Text::vFile::asData>, so this
module may be affected by bugs in that distribution.

=head2 RDF Output

Output uses the newer of the 2010 revision of the W3C's vCard vocabulary
L<http://www.w3.org/Submission/vcard-rdf/>. (Note that even though this
was revised in 2010, the term URIs include "2006" in them.)

Some extensions from the namespace L<http://buzzword.org.uk/rdf/vcardx#>
are also output.

The AGENT property is currently omitted from output. This will be added
in a later version.

=head1 SEE ALSO

L<RDF::vCard>.

L<http://www.w3.org/Submission/vcard-rdf/>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

