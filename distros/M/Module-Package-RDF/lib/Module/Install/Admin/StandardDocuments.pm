package Module::Install::Admin::StandardDocuments;

use 5.008;
use strict;
no warnings;

BEGIN {
	$Module::Install::Admin::StandardDocuments::AUTHORITY = 'cpan:TOBYINK';
	$Module::Install::Admin::StandardDocuments::VERSION   = '0.014';
};

use base 'Module::Install::Base';
our $AUTHOR_ONLY = 1;

use File::HomeDir;
use IO::All 'io';

sub clone_standard_documents
{
	my $self = shift;
	foreach ($self->_get_standard_documents)
	{
		my @file = @{ $self->_copy_standard_document($_) };
		$self->clean_files(@file) if @file;
	}
	1;
}

sub _get_standard_document_library
{
	io->catdir(
		File::HomeDir->my_home,
		'perl5',
		'standard-documents',
	);
}

sub _get_standard_documents
{
	my $io = shift->_get_standard_document_library;
	unless ($io->exists)
	{
		warn "$io does not exist!\n";
		return;
	}
	return $io->All_Files;
}

sub _copy_standard_document
{
	my ($self, $doc) = @_;
	
	my $base = $self->_get_standard_document_library;
	(my $relative = substr($doc, length $base)) =~ s{^[/\\]}{};
	$relative = io->file($relative);
	
	if ($doc->mtime < $relative->mtime)
	{
		warn "$relative is newer than $doc!\n";
		return [];
	}
	
	$doc > $relative;
	["$relative"];
}

1;
