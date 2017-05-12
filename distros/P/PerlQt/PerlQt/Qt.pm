package Qt::base;
use strict;

sub this () {}

sub new {
    no strict 'refs';
    my $t = this;
    shift->NEW(@_);
    my $ret = this;
    Qt::_internal::setThis($t);
    return $ret;
}

package Qt::base::_overload;
use strict;

no strict 'refs';
use overload
    "fallback" => 1,
    "==" => "Qt::base::_overload::op_equal",
    "!=" => "Qt::base::_overload::op_not_equal",
    "+=" => "Qt::base::_overload::op_plus_equal",
    "-=" => "Qt::base::_overload::op_minus_equal",
    "*=" => "Qt::base::_overload::op_mul_equal",
    "/=" => "Qt::base::_overload::op_div_equal",
    ">>" => "Qt::base::_overload::op_shift_right",
    "<<" => "Qt::base::_overload::op_shift_left",
    "<=" => "Qt::base::_overload::op_lesser_equal",
    ">=" => "Qt::base::_overload::op_greater_equal",
    "^=" => "Qt::base::_overload::op_xor_equal",
    "|=" => "Qt::base::_overload::op_or_equal",
    ">"  => "Qt::base::_overload::op_greater",
    "<"  => "Qt::base::_overload::op_lesser",
    "+"  => "Qt::base::_overload::op_plus",
    "-"  => "Qt::base::_overload::op_minus",
    "*"  => "Qt::base::_overload::op_mul",
    "/"  => "Qt::base::_overload::op_div",
    "^"  => "Qt::base::_overload::op_xor",
    "|"  => "Qt::base::_overload::op_or",
    "--" => "Qt::base::_overload::op_decrement",
    "++" => "Qt::base::_overload::op_increment",
    "neg"=> "Qt::base::_overload::op_negate";

sub op_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator==';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator==';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret
}

sub op_not_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator!=';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator!=';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret
}

sub op_plus_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator+=';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return ($_[2] ? $_[1] : $_[0]) unless $err = $@;
    my $ret;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator+=';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret
}

sub op_minus_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator-=';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return ($_[2] ? $_[1] : $_[0]) unless $err = $@;
    my $ret;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator-=';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@; 
    $ret
}

sub op_mul_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator*=';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return ($_[2] ? $_[1] : $_[0]) unless $err = $@;
    my $ret;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator*=';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@; 
    $ret
}

sub op_div_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator/=';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return ($_[2] ? $_[1] : $_[0]) unless $err = $@;
    my $ret;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator/=';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@; 
    $ret
}

sub op_shift_right {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator>>';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator>>';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret    
}

sub op_shift_left {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator<<';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator<<';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret
}

sub op_lesser_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator<=';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return ($_[2] ? $_[1] : $_[0]) unless $err = $@;
    $Qt::_internal::strictArgMatch = 0;
    my $ret;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator<=';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@; 
    $ret
}

sub op_greater_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator>=';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return ($_[2] ? $_[1] : $_[0]) unless $err = $@;
    my $ret;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator>=';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@; 
    $ret
}

sub op_xor_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator^=';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return ($_[2] ? $_[1] : $_[0]) unless $err = $@;
    my $ret;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator^=';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@; 
    $ret
}

sub op_or_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator|=';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return ($_[2] ? $_[1] : $_[0]) unless $err = $@;
    my $ret;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator|=';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@; 
    $ret
}

sub op_greater {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator>';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator>';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret    
}

sub op_lesser {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator<';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator<';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret    
}

sub op_plus {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator+';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator+';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret    
}

sub op_minus {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator-';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator-';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret    
}

sub op_mul {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator*';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator*';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret     
}

sub op_div {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator/';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator/';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret     
}

sub op_negate {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator-';
    my $autoload = ref($_[0])."::AUTOLOAD";
    my ($ret, $err);
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $ret = $autoload->($_[0]) };
    $Qt::_internal::strictArgMatch = 0;
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator-';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload($_[0]) };
    die $err.$@ if $@;
    $ret
}

sub op_xor {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator^';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator^';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret    
}

sub op_or {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator|';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    $Qt::_internal::strictArgMatch = 0;
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator|';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret    
}

sub op_increment {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator++';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $autoload->($_[0]) };
    $Qt::_internal::strictArgMatch = 0;
    return $_[0] unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator++';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; &$autoload($_[0]) };
    die $err.$@ if $@; 
    $_[0]
}

sub op_decrement {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator--';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    $Qt::_internal::strictArgMatch = 1;
    eval { local $SIG{'__DIE__'}; $autoload->($_[0]) };
    $Qt::_internal::strictArgMatch = 0;
    return $_[0] unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator--';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; &$autoload($_[0]) };
    die $err.$@ if $@;
    $_[0]
}

package Qt::_internal;

use strict;
use Qt::debug();

our $Classes;
our %CppName;
our @IdClass;

our @PersistentObjects;   # objects which need a "permanent" reference in Perl
our @sigslots;
our $strictArgMatch = 0;

sub this () {}


sub init_class {
    no strict 'refs';
    my $c = shift;
    my $class = $c;
    $class =~ s/^Q(?=[A-Z])/Qt::/;
    my $classId = Qt::_internal::idClass($c);
    insert_pclassid($class, $classId);

    $IdClass[$classId] = $class;
    $CppName{$class} = $c;
    Qt::_internal::installautoload("$class");
    {
	package Qt::AutoLoad;   # this package holds $AUTOLOAD
	my $closure = \&{ "$class\::_UTOLOAD" };
	*{ $class . "::AUTOLOAD" } =  sub{ &$closure };
    }

    my @isa = Qt::_internal::getIsa($classId);
    for my $super (@isa) {
	$super =~ s/^Q(?=[A-Z])/Qt::/;
    }
    # the general base class is Qt::base.
    # implicit new(@_) calls are forwarded there.
    @isa = ("Qt::base") unless @isa;
    *{ "$class\::ISA" } = \@isa;

    Qt::_internal::installautoload(" $class");
    {
	package Qt::AutoLoad;
	# do lookup at compile-time
	my $autosub = \&{ " $class\::_UTOLOAD" };
	*{ " $class\::AUTOLOAD" } = sub { &$autosub };
    }

    *{ " $class\::ISA" } = ["Qt::base::_overload"];

    *{ "$class\::NEW" } = sub {
	my $class = shift;
	$Qt::AutoLoad::AUTOLOAD = "$class\::$c";
	my $autoload = " $class\::_UTOLOAD";
        {
            no warnings;
            # the next line triggers a warning on SuSE's Perl 5.6.1 (?)
	    setThis(bless &$autoload, " $class");
        }
        setAllocated(this, 1);
	mapObject(this);
    } unless defined &{"$class\::NEW"};

    *{ $class } = sub {
	$class->new(@_);
    } unless defined &{ $class };
}

sub argmatch {
    my $methods = shift;
    my $args = shift;
    my $i = shift;
    my %match;
    my $argtype = getSVt($args->[$i]);
    for my $methix(0..$#$methods) {
	my $method = $$methods[$methix];
	my $typename = getTypeNameOfArg($method, $i);
	if($argtype eq 'i') {
	    if($typename =~ /^(?:bool|(?:(?:un)?signed )?(?:int|long)|uint)[*&]?$/) {
		$match{$method} = [0,$methix];
	    }
	} elsif($argtype eq 'n') {
	    if($typename =~ /^(?:float|double)$/) {
		$match{$method} = [0,$methix];
	    }
	} elsif($argtype eq 's') {
	    if($typename =~ /^(?:(?:const )?u?char\*|(?:const )?(?:(Q(C?)String)|QByteArray)[*&]?)$/) {
		# the below read as: is it a (Q(C)String) ? ->priority 1
		# is it a (QString)  ? -> priority 2
		# neither: normal priority
		# Watch the capturing parens vs. non-capturing (?:)
		$match{$method}[0] = defined $2 && $2 ? 1 : ( defined $1 ? 2 : 0 );
		$match{$method}[1] = $methix
	    }
	} elsif($argtype eq 'a') {
            # FIXME: shouldn't be hardcoded. Installed handlers should tell what perl type they expect.
            if($typename =~ /^(?:
                                const\ QCOORD\*|
                                (?:const\ )?
                                (?:
                                  Q(?:String|Widget|Object|FileInfo|CanvasItem)List[\*&]?|
                                  QValueList<int>[\*&]?|
                                  QPtrList<Q(?:Tab|ToolBar|DockWindow|NetworkOperation)>|
                                  QRgb\*|
                                  char\*\*
                                )
                              )$/x) {
                $match{$method} = [0,$methix];
            }
	} elsif($argtype eq 'r' or $argtype eq 'U') {
	    $match{$method} = [0,$methix];
	} else {
	    my $t = $typename;
	    $t =~ s/^const\s+//;
	    $t =~ s/(?<=\w)[&*]$//;
	    my $isa = classIsa($argtype, $t);
	    if($isa != -1) {
		$match{$method} = [-$isa,$methix];
	    }
	}
    }
    return sort { $match{$b}[0] <=> $match{$a}[0] or $match{$a}[1] <=> $match{$b}[1] } keys %match;
}

sub objmatch {
    my $method = shift;
    my $args = shift;
    for my $i(0..$#$args) {
	my $argtype = getSVt($$args[$i]);
	my $t = getTypeNameOfArg($method, $i);
	next if length $argtype == 1;
	$t =~ s/^const\s+//;
	$t =~ s/(?<=\w)[&*]$//;
	return 0 unless classIsa($argtype, $t) != -1;
    }
    1;
}

sub do_autoload {
    my $package = pop;
    my $method = pop;
    my $classId = pop;

    my $class = $CppName{$IdClass[$classId]};
    my @methods = ($method);
    for my $arg (@_) {
	unless(defined $arg) {
	    @methods = map { $_ . '?', $_ . '#', $_ . '$' } @methods;
	} elsif(isObject($arg)) {
	    @methods = map { $_ . '#' } @methods;
	} elsif(ref $arg) {
	    @methods = map { $_ . '?' } @methods;
	} else {
	    @methods = map { $_ . '$' } @methods;
	}
    }
    my @methodids = map { findMethod($class, $_) } @methods;
#   @methodids = map { findMethod('QGlobalSpace', $_) } @methods 
#			if (!@methodids and $withObject || $class eq 'Qt');

    if(@methodids > 1) {
	# ghetto method resolution
	my $count = scalar @_;
	for my $i (0..$count-1) {
	    my @matching = argmatch(\@methodids, \@_, $i);
	    @methodids = @matching if @matching or $strictArgMatch;
	}
        do {
            my $c = ($method eq $class)? 4:2;
            warn "Ambiguous method call for :\n".
                "\t${class}::${method}(".catArguments(\@_).")".
             ((debug() && (debug() & $Qt::debug::channel{'verbose'})) ?
             "\nCandidates are:\n".dumpCandidates(\@methodids).
             "\nTaking first one...\nat " : "").
             (caller($c))[1]." line ".(caller($c))[2].".\n"
        } if debug() && @methodids > 1 && (debug() & $Qt::debug::channel{'ambiguous'});

    }
    elsif( @methodids == 1 and @_ ) {
	@methodids = () unless objmatch($methodids[0], \@_)
    }
    unless(@methodids) {
	if(@_) {
	    @methodids = findMethod($class, $method);
	    do {
                do {
                    my $c = ($method eq $class)? 4:2;
                    warn "Lookup for ${class}::${method}(".catArguments(\@_).
                         ")\ndid not yeld any result.\n".
                         ((debug() && (debug() & $Qt::debug::channel{'verbose'})) ?
                         "Might be a call for an enumerated value (enum).\n":"").
                         "Trying ${class}::${method}() with no arguments\nat ".
                         (caller($c))[1]." line ".(caller($c))[2].".\n"
                } if debug() && @_ > 1 && (debug() & $Qt::debug::channel{'ambiguous'});
                @_ = ()
            } if @methodids;
	}
	do{
            my $verbose = "";
            if(debug() && (debug() & $Qt::debug::channel{'verbose'})) {
                my $alt = findAllMethods( $classId );
                getAllParents($classId, \my @sup);
                for my $s(@sup)
                {
                    my $h = findAllMethods( $s );
                    map { $alt->{$_} = $h->{$_} } keys %$h
                }
                my $pat1 = my $pat2 = $method;
                my @near = ();
                while(!@near && length($pat1)>2) {
                    @near = map { /$pat1|$pat2/i ? @{ $$alt{$_} }:() } sort keys %$alt;
                    chop $pat1;
                    substr($pat2,-1,1)= "";
                }
                $verbose = @near ? ("\nCloser candidates are :\n".dumpCandidates(\@near)) :
                                    "\nNo close candidate found.\n";
            }
            my $c = ($method eq $class)? 4:2;

            die "--- No method to call for :\n\t${class}::${method}(".
            catArguments(\@_).")".$verbose."\nat ".(caller($c))[1].
            " line ".(caller($c))[2].".\n";
          } unless @methodids;
    }
    setCurrentMethod($methodids[0]);
    return 1;
}

sub init {
    no warnings;
    installthis(__PACKAGE__);
    installthis("Qt::base");
    $Classes = getClassList();
    for my $c (@$Classes) {
	init_class($c);
    }
}

sub splitUnnested {
        my $string = shift;
        my(%open) = (
            '[' => ']',
            '(' => ')',
            '<' => '>',
            '{' => '}',
        );
        my(%close) = reverse %open;
        my @ret;
        my $depth = 0;
        my $start = 0;
        $string =~ tr/"'//;
        while($string =~ /([][}{)(><,])/g) {
            my $c = $1;
            if(!$depth and $c eq ',') {
                my $len = pos($string) - $start - 1;
                my $ret = substr($string, $start, $len);
                $ret =~ s/^\s*(.*?)\s*$/$1/;
                push @ret, $ret;
                $start = pos($string);
            } elsif($open{$c}) {
                $depth++;
            } elsif($close{$c}) {
                $depth--;
            }
        }
        my $subs = substr($string, $start);
        $subs =~ s/^\s*(.*?)\s*$/$1/;
        push @ret, $subs if ($subs);
        return @ret;
}

sub getSubName
{
    my $glob = getGV( shift );
    return ( $glob =~ /^.*::(.*)$/ )[0];
}

sub Qt::Application::NEW {
    my $class = shift;
    my $argv = shift;
    unshift @$argv, $0;
    my $count = scalar @$argv;
    setThis( bless Qt::Application::QApplication($count, $argv, @_), " $class" );
    mapObject(this);
    setAllocated(this, 1);
    setqapp(this);
    shift @$argv;
}

sub Qt::Image::NEW {
    no strict 'refs';
    # another ugly hack, whee
    my $class = shift;
    if(@_ == 6) {
	my $colortable = $_[4];
	my $numColors = (ref $colortable eq 'ARRAY') ? @$colortable : 0;
	splice(@_, 5, 0, $numColors);
    }

    # FIXME: this is evil
    $Qt::AutoLoad::AUTOLOAD = 'Qt::Image::QImage';
    my $autoload = " Qt::Image::_UTOLOAD";
    dontRecurse();
    setThis( $autoload->(@_) );
    setAllocated(this, 1);
}

sub makeMetaData {
    my $data = shift;
    my @tbl;
    for my $entry (@$data) {
	my @params;
	my $argcnt = scalar @{ $entry->{arguments} };
	for my $arg (@{ $entry->{arguments} }) {
	    push @params, make_QUParameter($arg->{name}, $arg->{type}, 0, 1);
	}
	my $method = make_QUMethod($entry->{name}, \@params);
	push @tbl, make_QMetaData($entry->{prototype}, $method);
    }
    my $count = scalar @tbl;
    my $metadata = make_QMetaData_tbl(\@tbl);
    return ($metadata, $count);
}

# This is the key function for signal/slots...
# All META hash entries have been defined by /lib/Qt/slots.pm and /lib/Qt/signals.pm
# Thereafter, /lib/Qt/isa.pm build the MetaObject by calling this function
# Here is the structure of the META hash:
# META { 'slot' => { $slotname-1 => { name      =>  $slotname-1,
#                                     arguments => xxx,
#                                     prototype => xxx,
#                                     returns   => xxx,
#                                     method    => xxx,
#                                     index     => <index in 'slots' array>,
#                                     mocargs   => xxx,
#                                     argcnt    => xxx },
#                     ... ,
#                    $slotname-n => ...
#                  },
#       'slots' => [ slot1-hash, slot2-hash...slot-n-hash ],
#       'signal' => ibidem,
#       'signals' => ibidem,
#       'superClass' => ["classname1", .."classname-n"] # inherited
#     }

sub getMetaObject {
    no strict 'refs';
    my $class = shift;
    my $meta = \%{ $class . '::META' };
    return $meta->{object} if $meta->{object} and !$meta->{changed};
    updateSigSlots() if( @sigslots );
    inheritSuperSigSlots($class);
    my($slot_tbl, $slot_tbl_count) = makeMetaData($meta->{slots});
    my($signal_tbl, $signal_tbl_count) = makeMetaData($meta->{signals});
    $meta->{object} = make_metaObject($class, Qt::this()->staticMetaObject,
		$slot_tbl, $slot_tbl_count,
		$signal_tbl, $signal_tbl_count);
    $meta->{changed} = 0;
    return $meta->{object};
}

sub updateSigSlots
{
    require Qt::signals;
    require Qt::slots;
    for my $i (@sigslots) {
        no strict 'refs';
        my $mod = "Qt::" . lc($$i[0]) . ( substr($$i[0], 0, 1) eq 'S' ? 's' : '' ) . "::import";
        $mod->( $$i[1], getSubName($$i[2]) => $$i[3] );
    }
    @sigslots = ();
}

sub inheritSuperSigSlots {
    no strict 'refs';
    my $class = shift;
    my $meta = \%{ $class . '::META' };
    if(defined $meta->{'superClass'} && @{ $meta->{'superClass'} }) {
        for my $super(@{$meta->{'superClass'}}) {
            inheritSuperSigSlots($super);
            for my $ssn(keys %{${$super.'::META'}{slot}}) {
               if(!exists $meta->{slot}->{"$ssn"}) {
                   my %ss = %{${$super.'::META'}{slot}{$ssn}};
                   push @{$meta->{slots}}, \%ss;
                   $meta->{slot}->{$ssn} = \%ss;
                   $ss{index} = $#{ $meta->{slots} };
               }
            }
            for my $ssn(keys %{${$super.'::META'}{signal}}) {
               if(!exists $meta->{signal}->{"$ssn"}) {
                   my %ss = %{${$super.'::META'}{signal}{$ssn}};
                   push @{$meta->{signals}}, \%ss;
                   $meta->{signal}->{$ssn} = \%ss;
                   $ss{index} = $#{ $meta->{signals} };
                   Qt::_internal::installsignal("$class\::$ssn");
               }
            }
            Qt::_internal::installqt_invoke($class . '::qt_invoke')
                if( !defined &{ $class. '::qt_invoke' } && exists $meta->{slots} && @{ $meta->{slots} });
            Qt::_internal::installqt_invoke($class . '::qt_emit')
                if( !defined &{ $class. '::qt_emit' } && exists $meta->{signals} && @{ $meta->{signals} });
        }
    }
}

sub getAllParents
{
   my $classId = shift;
   my $res = shift;
   my @classes = Qt::_internal::getIsa( $classId );
   for my $s( @classes )
   {
       my $c = Qt::_internal::idClass($s);
       push @{ $res }, $c;
       getAllParents($c, $res)
   }
}

sub Qt::PointArray::setPoints {
    my $points = $_[0];
    no strict 'refs';
    # what a horrible, horrible way to do this
    $Qt::AutoLoad::AUTOLOAD = 'Qt::PointArray::setPoints';
    my $autoload = " Qt::PointArray::_UTOLOAD";
    dontRecurse();
    $autoload->(scalar(@$points)/2, $points);
}

sub Qt::GridLayout::addMultiCellLayout {
    # yet another hack. Turnaround for a bug in Qt < 3.1
    # (addMultiCellLayout doesn't reparent its QLayout argument)
    no strict 'refs';
    if(!defined $_[0]->{'has been hidden'})
    {
        push @{ this()->{'hidden children'} }, $_[0];
        $_[0]->{'has been hidden'} = 1;
    }
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GridLayout::addMultiCellLayout';
    my $autoload = " Qt::GridLayout::_UTOLOAD";
    dontRecurse();
    $autoload->(@_);
}

package Qt::Object;
use strict;

sub  MODIFY_CODE_ATTRIBUTES
{
    package Qt::_internal;
    my ($package, $coderef, @attrs ) = @_;
    my @reject;
    foreach my $attr( @attrs )
    {
        if( $attr !~ /^ (SIGNAL|SLOT|DCOP) \(( .* )\) $/x )
        {
             push @reject, $attr;
             next;
        }
        push @sigslots,
             [ $1, $package, $coderef, [ splitUnnested( $2 ) ] ];
    }
    if( @sigslots )
    {
        no strict 'refs';
        my $meta = \%{ $package . '::META' };
        $meta->{ 'changed' } = 1;
    }
    return @reject;
}

package Qt;

use 5.006;
use strict;
use warnings;
use XSLoader;

require Exporter;

our $VERSION = '3.008';

our @EXPORT = qw(&SIGNAL &SLOT &CAST &emit &min &max);

XSLoader::load 'Qt', $VERSION;

# try to avoid KDE's buggy malloc
# only works for --enable-fast-malloc,
# not when --enable-fast-malloc=full
$ENV{'KDE_MALLOC'} = 0;

Qt::_internal::init();

# In general, I'm not a fan of prototypes.
# However, I'm also not a fan of parentheses

sub SIGNAL ($) { '2' . $_[0] }
sub SLOT ($) { '1' . $_[0] }
sub CAST ($$) { bless $_[0], " $_[1]" }
sub emit (@) { pop @_ }
sub min ($$) { $_[0] < $_[1] ? $_[0] : $_[1] }
sub max ($$) { $_[0] > $_[1] ? $_[0] : $_[1] }

sub import { goto &Exporter::import }

sub Qt::base::ON_DESTROY { 0 };

sub Qt::Object::ON_DESTROY
{
    package Qt::_internal;
    my $parent = this()->parent;
    if( $parent )
    {
        ${ $parent->{"hidden children"} } { sv_to_ptr(this()) } = this();
        this()->{"has been hidden"} = 1;
        return 1
    }
    return 0
}

sub Qt::Application::ON_DESTROY { 0 }

# we need to solve an ambiguity for Q*Items: they aren't QObjects,
# and are meant to be created on the heap / destroyed manually.
# On the one hand, we don't want to delete them if they are still owned by a QObject hierarchy
# but on the other hand, what can we do if the user DOES need to destroy them?
#
# So the solution adopted here is to use the takeItem() method when it exists
# to lower the refcount and allow explicit destruction/removal.

sub Qt::ListViewItem::ON_DESTROY {
    package Qt::_internal;
    my $parent = this()->listView();
    if( $parent )
    {
        ${ $parent->{"hidden children"} } { sv_to_ptr(this) } = this();
        this()->{"has been hidden"} = 1;
        setAllocated( this(), 0 );
        return 1
    }
    setAllocated( this(), 1 );
    return 0
}

sub Qt::ListViewItem::takeItem
{
    package Qt::_internal;
    delete ${ this()->{"hidden children"} } { sv_to_ptr($_[0]) };
    delete $_[0]->{"has been hidden"};
    setAllocated( $_[0], 1 );
    no strict 'refs';
    $Qt::AutoLoad::AUTOLOAD = 'Qt::ListViewItem::takeItem';
    my $autoload = " Qt::ListViewItem::_UTOLOAD";
    dontRecurse();
    $autoload->( $_[0] );
}

sub Qt::ListView::takeItem
{
    package Qt::_internal;
    delete ${ this()->{"hidden children"} } { sv_to_ptr($_[0]) };
    delete $_[0]->{"has been hidden"};
    setAllocated( $_[0], 1 );
    no strict 'refs';
    $Qt::AutoLoad::AUTOLOAD = 'Qt::ListView::takeItem';
    my $autoload = " Qt::ListView::_UTOLOAD";
    dontRecurse();
    $autoload->( $_[0] );
}

sub Qt::IconViewItem::ON_DESTROY
{
    package Qt::_internal;
    my $parent = this()->iconView;
    if( $parent )
    {
        ${ $parent->{"hidden children"} } { sv_to_ptr(this()) } = this();
        this()->{"has been hidden"} = 1;
        setAllocated( this(), 0 );
        return 1
    }
    setAllocated( this(), 1 );
    return 0
}

sub Qt::IconView::takeItem
{
    package Qt::_internal;
    delete ${ this()->{"hidden children"} } { sv_to_ptr($_[0]) };
    delete $_[0]->{"has been hidden"};
    setAllocated( $_[0], 1 );
    no strict 'refs';
    $Qt::AutoLoad::AUTOLOAD = 'Qt::IconView::takeItem';
    my $autoload = " Qt::IconView::_UTOLOAD";
    Qt::_internal::dontRecurse();
    $autoload->( $_[0] );
}


sub Qt::ListBoxItem::ON_DESTROY
{
    package Qt::_internal;
    my $parent = this()->listBox();
    if( $parent )
    {
        ${ $parent->{"hidden children"} } { sv_to_ptr(this()) } = this();
        this()->{"has been hidden"} = 1;
        setAllocated( this(), 0 );
        return 1
    }
    setAllocated( this(), 1 );
    return 0
}

sub Qt::ListBox::takeItem
{
    # Unfortunately, takeItem() won't reset the Item's listBox() pointer to 0.
    # That's a Qt bug (I reported it and it got fixed as of Qt 3.2b2)
    package Qt::_internal;
    delete ${ this()->{"hidden children"} } { sv_to_ptr($_[0]) };
    delete $_[0]->{"has been hidden"};
    setAllocated( $_[0], 1 );
    no strict 'refs';
    $Qt::Autoload::AUTOLOAD = 'Qt::ListBox::takeItem';
    my $autoload = " Qt::ListBox::_UTOLOAD";
    dontRecurse();
    $autoload->( $_[0] );
}

sub Qt::TableItem::ON_DESTROY
{
    package Qt::_internal;
    my $parent = this()->table;
    if( $parent )
    {
        ${ $parent->{"hidden children"} } { sv_to_ptr(this()) } = this();
        this()->{"has been hidden"} = 1;
        setAllocated( this(), 0 );
        return 1
    }
    setAllocated( this(), 1 );
    return 0
}

sub Qt::Table::takeItem
{
    package Qt::_internal;
    delete ${ this()->{"hidden children"} } { sv_to_ptr($_[0]) };
    delete $_[0]->{"has been hidden"};
    setAllocated( $_[0], 1 );
    no strict 'refs';
    $Qt::AutoLoad::AUTOLOAD = 'Qt::Table::takeItem';
    my $autoload = " Qt::Table::_UTOLOAD";
    dontRecurse();
    $autoload->( $_[0] );
}

sub Qt::LayoutItem::ON_DESTROY
{
    package Qt::_internal;
    my $parent = this()->widget() || this()->layout();
    if( $parent )
    {
        ${ $parent->{"hidden children"} } { sv_to_ptr(this()) } = this();
    }
    else # a SpacerItem...
    {
        push @PersistentObjects, this();
    }
    this()->{"has been hidden"} = 1;
    setAllocated( this(), 0 );
    return 1
}

sub Qt::Layout::ON_DESTROY
{
    package Qt::_internal;
    my $parent = this()->mainWidget() || this()->parent();
    if( $parent )
    {
        ${ $parent->{"hidden children"} } { sv_to_ptr(this()) } = this();
        this()->{"has been hidden"} = 1;
        return 1
    }
    return 0
}

sub Qt::StyleSheetItem::ON_DESTROY
{
    package Qt::_internal;
    my $parent = this()->styleSheet();
    if( $parent )
    {
        ${ $parent->{"hidden children"} } { sv_to_ptr(this()) } = this();
        this()->{"has been hidden"} = 1;
        setAllocated( this(), 0 );
        return 1
    }
    setAllocated( this(), 1 );
    return 0
}

sub Qt::SqlCursor::ON_DESTROY
{
    package Qt::_internal;
    push @PersistentObjects, this();
    this()->{"has been hidden"} = 1;
    setAllocated( this(), 0 );
    return 1
}

1;
