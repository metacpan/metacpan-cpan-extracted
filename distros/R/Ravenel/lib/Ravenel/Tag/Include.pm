package Ravenel::Tag::Include;

use base 'Ravenel::Tag';
use fields qw( docroot ravenel_document );

use strict;
use Carp qw(cluck confess);
use Ravenel::Document;
use Data::Dumper;

sub new {
	my Ravenel::Tag::Include $self = shift;
	my $option                     = shift;
	my Ravenel::Document $document = shift;

	unless ( ref($self) ) {
		$self = fields::new($self);
		$self->SUPER::new($option);

		$self->{'ravenel_document'} = $document;
		$self->{'docroot'}          = $document->{'docroot'};
		$self->{'dynamic'}          = 1;
	}

	return $self;
}

sub expand {
	my Ravenel::Tag::Include $self = shift;

	if ( not $self->{'expanded'} ) {
		my $filename;
		if ( -f $self->{'arguments'}->{'file'} ) {
			$filename = $self->{'arguments'}->{'file'};
		} else {
			confess("Docroot not defined when making an include with a relative path: $self->{'tag_inner'}") if ( not $self->{'docroot'} );
			if ( -f $self->{'docroot'} . $self->{'arguments'}->{'file'} ) {
				$filename = $self->{'docroot'} . $self->{'arguments'}->{'file'};
			} else {
				#print "f = $self->{'arguments'}->{'file'}, docroot=$self->{'docroot'}\n";
				confess("File not found in include tag ($self->{'tag_inner'})\n");
			}
		}

		open(F, $filename);
		$self->{'expanded'} = do { local $/; <F> };
		close F;
	}

	my Ravenel::Document $doc = $self->{'ravenel_document'};
	substr(
		$doc->{'document'},
		$self->{'start_pos'},
		$self->{'end_pos'} - $self->{'start_pos'} + length($doc->{'prefix'}) - 1,
		$self->{'expanded'},
	);

	return $self->{'expanded'};
}

1;
