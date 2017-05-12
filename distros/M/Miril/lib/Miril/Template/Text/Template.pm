package Miril::Template::Text::Template;

use strict;
use warnings;
use autodie;

use base 'Miril::Template::Abstract';

use Text::Template;
use File::Spec::Functions qw(catfile);
use Try::Tiny qw(try catch);
use Miril::Exception;

sub load {
	my $self = shift;
	my %options = @_;

	my $tmpl;
	
	try 
	{
		$tmpl = Text::Template->new( TYPE => 'FILE', SOURCE => catfile($self->tmpl_path, $options{name}) );
	} 
	catch 
	{
		Miril::Exception->throw(
			message => "Could not open template file",
			errorvar => $_,
		);
	};

	return $tmpl->fill_in( HASH => $options{params} );
}

1;
