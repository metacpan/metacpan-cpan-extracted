package MooseX::DeclareX::Plugin::types;

BEGIN {
	$MooseX::DeclareX::Plugin::types::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Plugin::types::VERSION   = '0.009';
}

use Moose;
with 'MooseX::DeclareX::Plugin';

use MooseX::Declare ();
use Moose::Util ();
use Data::OptList;

sub plugin_setup
{
	my ($class, $kw, $opt) = @_;
	$opt = Data::OptList::mkopt($opt);
	
	my @codeparts = map {
		my ($module, $terms) = @$_;
		$module =~ s/^-/MooseX::Types::/;
		$terms ||= ['-all'];
		sprintf('use %s qw(%s)', $module, join q[ ], @$terms);
	} @$opt;

	$kw->meta->add_after_method_modifier(
		add_namespace_customizations => sub {
			my ($self, $ctx, $package) = @_;
			$ctx->add_preamble_code_parts(@codeparts);
		},
	);
}

1;

