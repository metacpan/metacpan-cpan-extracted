package MooseX::DeclareX::Plugin::std_constants;

BEGIN {
	$MooseX::DeclareX::Plugin::std_constants::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Plugin::std_constants::VERSION   = '0.009';
}

use Moose;
with 'MooseX::DeclareX::Plugin';

use MooseX::Declare ();
use Moose::Util ();

sub plugin_setup
{
	my ($class, $kw) = @_;

	$kw->meta->add_after_method_modifier(
		add_namespace_customizations => sub {
			my ($self, $ctx, $package) = @_;
			$ctx->add_preamble_code_parts('use constant { read_only => "ro", read_write => "rw", true => !!1, false => !!0 }');
		},
	);
}

1;

