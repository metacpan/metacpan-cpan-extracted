package MooseX::DeclareX::MethodPrefix;

BEGIN {
	$MooseX::DeclareX::MethodPrefix::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::MethodPrefix::VERSION   = '0.009';
}

use Moose;

sub prefix_keyword {
	confess "this is an abstract base class!";
}

sub install_method {
	1;  # no-op
}

use Devel::Declare ();
use MooseX::Method::Signatures;
use Sub::Install qw/install_sub/;
use Devel::Declare::Context::Simple ();

has _dd_context => (
	is      => 'ro',
	isa     => 'Devel::Declare::Context::Simple',
	lazy    => 1,
	builder => '_build_dd_context',
	handles => qr/.*/,
);
 
has _dd_init_args => (
	is      => 'rw',
	isa     => 'HashRef',
	default => sub { +{} },
);
 
has class => (
	is       => 'ro',
	isa      => 'ClassName',
	required => 1,
);

sub handle_has { +return }

sub BUILD
{
	my $self = shift;
	my $args = shift;
	$self->_dd_init_args($args);
}
 
sub _build_dd_context
{
	my $self = shift;
	return Devel::Declare::Context::Simple::->new(
		%{ $self->_dd_init_args }
	);
}

sub import
{
	my $class = shift;
	my $setup_class = caller(0);
	$class->setup_for($setup_class);
}

sub setup_for 
{
	my ($class, $setup_class, $args) = @_;
	$args ||= {};
	
	my $kw = $class->prefix_keyword;
	
	Devel::Declare->setup_for($setup_class, {
		$kw => {
			const => sub {
				my $self = $class->new({ class => $setup_class, %{ $args } });
				$self->init(@_);
				return $self->parse;
			},
		},
	});
 
	install_sub({
		code => sub {},
		into => $setup_class,
		as   => $kw,
	});
 
	MooseX::Method::Signatures->setup_for($setup_class)
		unless $setup_class->can('method');
}
 
sub parse
{
	my $self = shift;
	my $kw = $self->prefix_keyword;
	
	$self->skip_declarator;
	$self->skipspace;

	my $remaining = substr($self->get_linestr, $self->offset);

	if ($remaining =~ m/^\s*has/s and defined $self->handle_has)
	{
		# THIS DOES NOT WORK!
		my $handler = $self->handle_has;
		$remaining =~ s/^\s*has/;$handler/;
		my $line = $self->get_linestr;
		substr($line, $self->offset) = $remaining;
		$self->set_linestr($line);
		return;
	}

	my $thing = $self->strip_name;
	
	confess "expected 'method', got '${thing}'"
		unless $thing eq 'method';

	$self->skipspace;

	my $name = $self->strip_name;
	confess "anonymous $kw methods not allowed"
		unless defined $name && length $name;

	my $pkg   = $self->get_curstash_name;
	my $proto = $self->strip_proto || '';
	my $proto_variant = MooseX::Method::Signatures::Meta::Method->wrap(
		signature    => "(${proto})",
		package_name => $pkg,
		name         => $name,
	);

	$self->inject_if_block(
		$self->scope_injector_call . $proto_variant->injectable_code,
		'sub',
	);

	$self->shadow(sub {
		my $r = $proto_variant->reify(actual_body => $_[0]);
		$self->install_method($r);
	});
}

1;
