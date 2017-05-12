#line 1
package Module::Install::RDF;

use 5.005;
use base qw(Module::Install::Base);
use strict;

our $VERSION = '0.009';
our $AUTHOR_ONLY = 1;

sub rdf_metadata
{
	my $self = shift;
	$self->admin->rdf_metadata(@_) if $self->is_admin;
}

sub write_meta_ttl
{
	my $self = shift;
	my $file = shift || "META.ttl";
	$self->admin->write_meta_ttl($file) if $self->is_admin;
	$self->clean_files($file);
}

1;

__END__
#line 76
