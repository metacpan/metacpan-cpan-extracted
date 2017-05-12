package Module::Install::StandardDocuments;

use 5.008;
use strict;
no warnings;

BEGIN {
	$Module::Install::StandardDocuments::AUTHORITY = 'cpan:TOBYINK';
	$Module::Install::StandardDocuments::VERSION   = '0.014';
};

use base 'Module::Install::Base';
our $AUTHOR_ONLY = 1;

sub clone_standard_documents
{
	my $self = shift;
	$self->admin->clone_standard_documents(@_) if $self->is_admin;
}

1;
