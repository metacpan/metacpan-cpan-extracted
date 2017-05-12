package Miril::Template::HTML::Template;

use strict;
use warnings;
use autodie;

use base 'Miril::Template::Abstract';

use HTML::Template::Pluggable;
use HTML::Template::Plugin::Dot;
use File::Spec::Functions qw(catfile);
use Try::Tiny qw(try catch);
use Miril::Exception;

sub load {
	my $self = shift;
	my %options = @_;
	my $tmpl;
	
	try 
	{
		$tmpl = HTML::Template::Pluggable->new( 
			filename          => catfile($self->tmpl_path, $options{name}), 
			path              => $self->{tmpl_path},
			die_on_bad_params => 0,
			global_vars       => 1,
			case_sensitive    => 1,
		);
	} 
	catch 
	{
		Miril::Exception->throw(
			message => "Could not open template file", 
			errorvar => $_,
		);
	};

	$tmpl->param( %{ $options{params} } );
	
	my $output = $tmpl->output;
	# BOM's mess up with html, see: http://www.w3.org/International/questions/qa-utf8-bom
	# this is a hack and will probably break UTF-16 and UTF-32
	# I am not really sure why BOM's get added for UTF-8 files ...
	$output =~ s/\xEF\xBB\xBF//g;

	return $output;
}

1;

