use MooseX::Declare;
use MooseX::Declare::Context::WithOptions::Patch::Extensible;
use Test::More tests => 5;

{
	package Local::Declare::Syntax::HavingApplication;
	use Moose::Role;
	
	sub add_having_option_customizations
	{
		my ($self, $ctx, $package, $attribs) = @_;
		my @code_parts;
		push @code_parts, sprintf(
			"has [%s] => (is => q/rw/, isa => q/Str/)\n",
			join ', ',
				map { "q/$_/" }
				@{ ref $attribs ? $attribs : [$attribs] }
			);
		$ctx->add_scope_code_parts(@code_parts);
		return 1;
	}
}

BEGIN {
	use Moose::Util qw/apply_all_roles/;
	apply_all_roles('MooseX::Declare::Syntax::Keyword::Class',
		'Local::Declare::Syntax::HavingApplication');
	
	MooseX::Declare::Context::WithOptions->meta->add_around_method_modifier(
		allowed_option_names => sub
			{
				my ($orig, $self, $x) = @_;
				if ($x)
				{
					push @$x, 'having';
					return $self->$orig($x);
				}
				else
				{
					$x = $self->$orig();
					push @$x, 'having';
					return $x;
				}
			}
		);
}

class Local::MyClass
	having foo
	having bar
{
	has baz => (is => 'rw', isa => 'Str');
}

can_ok('Local::MyClass', 'new');

my $obj = Local::MyClass->new;
can_ok($obj, 'foo');
can_ok($obj, 'baz');
can_ok($obj, 'bar');
ok(!$obj->can('bat'), "Local::MyClass->can't('bat')");

