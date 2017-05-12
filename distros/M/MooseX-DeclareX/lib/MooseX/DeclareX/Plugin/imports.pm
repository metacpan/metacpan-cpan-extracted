package MooseX::DeclareX::Plugin::imports;

BEGIN {
	$MooseX::DeclareX::Plugin::imports::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Plugin::imports::VERSION   = '0.009';
}

use Moose;
with 'MooseX::DeclareX::Plugin';

use MooseX::Declare ();
use Moose::Util ();
use Data::OptList;
use Data::Dumper;

sub plugin_setup
{
	my ($class, $kw, $opt) = @_;
	$opt = Data::OptList::mkopt($opt);
	
	local $Data::Dumper::Terse  = 1;
	local $Data::Dumper::Indent = 0;
	my @codeparts = map {
		my ($module, $terms) = @$_;
		$terms = [] unless defined $terms;
		confess "parameters for $module must be an arrayref"
			unless ref $terms eq 'ARRAY';
		sprintf('use %s @{%s}', $module, Dumper $terms);
	} @$opt;

	$kw->meta->add_after_method_modifier(
		add_namespace_customizations => sub {
			my ($self, $ctx, $package) = @_;
			$ctx->add_preamble_code_parts(@codeparts);
		},
	);
}

1;

