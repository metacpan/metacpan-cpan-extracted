package Template::Direct;

use strict;

=head1 NAME

Template::Direct - Creates a document page based on template/datasets

=head1 SYNOPSIS

  use Template::Direct;

  my $template = Template::Direct->new( Location => $fileName/$refName );

  my $result = $page->compile( Data => {DataSets}, Language => 'en' );

=head1 DESCRIPTION
	
  Creates, Saves and Manages templates, their languages, the publication of
  and also does some work with the template design when saving unpublished templates

=head1 METHODS

=cut

use Carp;
use Template::Direct::Page;
use Template::Direct::Data;
use Template::Direct::Directory;

our $VERSION = '1.16';
our $config;

=head2 I<$class>->new( %properties )

  Create a new template, takes the arguments:

    * Directory - Location of all files, base path.
    * Location  - Location of the template (Filename)

=cut
sub new
{
	my ($class, %p) = @_;
	if(not $p{'Directory'}) { carp "Directory is required for Document Template"; return; }
	if(not $p{'Location'}) { carp "Location is required for Document Template"; return; }
	
	my $self = bless \%p, $class;

	if(ref($p{'Directory'}) eq 'Directory') {
		$self->{'Dir'} = $p{'Directory'};
	} else {
		$self->{'Dir'} = Template::Direct::Directory->new( $p{'Directory'} );
	}

	if(not $self->{'Dir'}) {
		if(not $p{'Directory'}) {
			carp 'Template Error: Directory Required';
		} else {
			carp "Template Error: Directory does not exist '$p{'Directory'}'";
		}
		return;
	}

	return $self;
}

=head2 I<$template>->loadPage( Language => [] )

  Load a Template Page object with specific language fallbacks.
  Returns Template::Direct::Page object.

=cut
sub loadPage
{
	my ($self, %p) = @_;
	my $template = $self->load( Language => $p{'Language'} );
	return if not $template;
	my $page = Template::Direct::Page->new( $template,
		Language  => $p{'Language'},
		Directory => $self->{'Dir'} );
	return $page;
}

=head2 I<$template>->compile( $data, Language => [] )

  Short cut for loading the page with Languages and then
  Compiling that page with data. Returns final page string.

=cut
sub compile {
	my ($self, $data, %p) = @_;
	my $page = $self->loadPage(%p);
	return if not $page;
	return $page->compile($data);
}

=head2 I<$template>->load( %properties )

  Load a specific version of a template file, returns
  the template as a string.

=cut
sub load
{
	my ($self, %p) = @_;

	my $language = _suitableLanguage( $p{'Language'} );
	my $filename = $self->{'Location'}.(defined($language) ? '.'.$language : '');
	my $result = $self->{'Dir'}->loadFile( $filename, Cache => $self->{'Cache'} ? $self->{'Cache'} : 1 );
	return $result;
}

=head2 I<$template>->_suitableLanguage( Template => 'filename', Language => [] )

  Returns a suitable language to use for this template, given what exists.

=cut
sub _suitableLanguage
{
	my ($self, %p) = @_;
	my $dir = $self->{'Dir'};
	my $language = $p{'Language'};

	if(UNIVERSAL::isa($language, '')) {
		$language = [$language];
	}

	foreach my $lang (@{$language}) {
		if($dir->loadFile($p{'Template'}.".".$lang)) {
			return $lang;
		}
	}

	return;
}

=head1 AUTHOR

 Copyright, Martin Owens 2008, AGPL

=cut
1;
