package Ruby;

use 5.008_001;

use strict;
use warnings;

use Carp ();
use XSLoader ();

our $VERSION = '0.07';

XSLoader::load(__PACKAGE__, $VERSION);

sub true ();
sub false();
sub nil  ();

# export to default
our @EXPORT = qw(
	true
	false
	nil

	puts
	p

	rubyify

	rb_require
	rb_eval
);
our @EXPORT_OK = qw(
	ruby_run

	rb_c
	rb_m
	rb_e
	rb_const

	rb_inspect
	rb_basic_inspect
);

our %EXPORT_COMMANDS = (
	-function  => \&_export_symbol,
	-variable  => \&_export_symbol,
	-alias     => \&_alias,

	-class     => \&_export_class,
	-module    => \&_export_class,

	-require   => \&_require,
	-eval      => \&_eval,

	-literal    => \&_literal,
	-no_literal => \&_no_literal,
	-autobox    => \&_autobox,
	-no_autobox => \&_no_autobox,

	-all       => \&_all,

	-base      => \&_base,
);

my %CORE; # registory of Ruby's core functions
@CORE{ @EXPORT }    = ();
@CORE{ @EXPORT_OK } = ();

push @EXPORT,  ['$!' => '$rb_errinfo'];


sub import{
	my $class  = shift;
	my @caller = (caller);

	return _export_symbol(\@caller, ':DEFAULT') unless @_;

	my $cmd = '-function';
	my @args;
	for(my $i = 0; $i < @_; $i++){
		if($_[$i] =~ /^-/){
			$cmd = $_[$i];
		}
		else{
			push @args, $_[$i];
		}
		if($i == $#_ or $_[$i+1] =~ /^-/){
			my $f = $EXPORT_COMMANDS{$cmd}
				or Carp::croak(qq{Undefined import command "$cmd"});

			$f->(\@caller, @args);
			@args = ();
		}
	}
	1;
}

sub _export_symbol{
	my $caller = shift;
	my $pkg    = $caller->[0];

	foreach my $arg(map{ $_ eq ':DEFAULT' ? @EXPORT : $_ } @_){
		my($sym, $as) = ref($arg) eq 'ARRAY' ? (@$arg) : ($arg, $arg);
		$as = $sym unless defined $as;

		if($as =~ s/^\$//){ # global variable?
			if($as !~ /::/){
				$as = $pkg . "::" . $as;
			}

			no strict 'refs';

			my $ref = \${$as};
			rb_install_global_variable($$ref, $sym);

			*{$as} = $ref; # export variable (c.f. var.pm)
		}
		else{
			my($proto, $proto2);
			if($sym =~ s/\((.*)\)$//){
				$proto = $1;
			}
			if($as =~ s/\((.*)\)$//){
				$proto2 = $1;
			}

			if(defined($proto) or defined($proto2)){
				if( (defined($proto) and defined($proto2)) and ($proto ne $proto2) ){
					Carp::croak("Prototype mismatch: ($proto) vs ($proto2)");
				}
				elsif(not defined($proto)){
					$proto = $proto2;
				}
			}

			if($as !~ /::/){
				$as = $pkg . "::" . $as;
			}

			if(exists($CORE{$sym})){
				if(defined($proto)){
					Carp::croak("Cannot set any prototype to the core function $sym");
				}
				no strict 'refs';
				*{$as} = \&{"Ruby::$sym"};
			}

			else{
				no warnings 'redefine';
				rb_install_function($as, $sym, $proto);
			}
		}
	}
}

sub _export_class
{
	my $caller = shift;

	foreach my $arg(@_){

		if($arg eq ':ALL'){
			rb_c('ObjectSpace')->each_object(rb_c('Module'), sub{
				rb_install_class($_[0], $_[0]);
			});
		}
		else{
			my($class, $as) = ref($arg) eq 'ARRAY' ? (@$arg) : ($arg, $arg);

			rb_install_class($as, $class);
		}
	}
}

sub _eval{
	my $caller = shift;

	rb_eval($_[0], @$caller);
}

sub _require{
	my $caller = shift;

	rb_require($_) for @_;
}

sub _literal{
	shift;
	require Ruby::literal;
	Ruby::literal->import(@_);
}
sub _no_literal{
	shift;
	require Ruby::literal;
	Ruby::literal->unimport(@_);
}
sub _autobox{
	shift;
	require Ruby::autobox;
	Ruby::autobox->import(@_);
}
sub _no_autobox{
	shift;
	require Ruby::autobox;
	Ruby::autobox->unimport(@_);
}

sub _all{
	my $caller = shift;

	Carp::croak('Too many arguments for -all command') if @_;

	_export_symbol($caller, ':DEFAULT');
	_export_class ($caller, ':ALL');
	_literal      ($caller);
}

sub _base{
	Carp::corak('Too few arguments for -base command')  if @_ < 2;
	Carp::croak('Too many arguments for -base command') if @_ > 2;

	my($caller, $base) = @_;

	rb_define_class($caller->[0], $base);
	rb_install_class($caller->[0], $caller->[0]);
}

sub _alias{
	my($class, $arg) = @_;

	my($alias, $orig) = @{$arg};

	rb_install_method("Ruby::Object::$alias", $orig);
}


sub rb_const(*){
	my $name = shift;
	my $class;

	$name =~ s/^(.*):://;

	$class = rb_c($1 ? $1 : 'Object');

	$class->const_get($name);
}

sub rb_inspect{
	require Ruby::Inspect;
	goto &Ruby::Inspect::rb_inspect;
}
sub rb_basic_inspect{
	require Ruby::Inspect;
	goto &Ruby::Inspect::rb_basic_inspect;
}

package Ruby::Object;

use overload
	fallback => 1,

	'='    => 'clone', # copy constructor

	'""'   => 'stringify',
	'0+'   => 'numify',
	'bool' => 'boolify',

	'%{}'  => 'hashify',
	'&{}'  => 'codify',

	# The rest of operators are registered in bootstrap.
;

sub codify{
	my $proc = shift;
	return sub{ $proc->call(@_) };
}

sub inspect; # pre-definition for p()

sub AUTOLOAD
{
	our($AUTOLOAD);

	my $ruby_name = do{ no strict 'refs'; *{$AUTOLOAD}{NAME} };

	my $xs = Ruby::rb_install_method($AUTOLOAD, $ruby_name);

	# Don't goto &$xs
	&$xs;
}

1;
