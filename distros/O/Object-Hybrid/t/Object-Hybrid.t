

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Object-Hybrid.t'

use strict;

BEGIN { $^W = 0; } 

use Test::More;
my  $use_autobox;
BEGIN {	
	$use_autobox = eval{ require autobox };
	plan tests => 909 + ($use_autobox && 6 ); 
} # allows to calcualte tests plan, if SKIP cannot be used instead

BEGIN { use_ok('Object::Hybrid', qw(promote)) };

{
	package Object::Hybrid::StdHash2;
	new     Object::Hybrid {}; # this should load Object::Hybrid::HASH
}

{
	package Object::Hybrid::StdHash;

	Object::Hybrid->methods(
		TIEHASH  => sub { bless {}, $_[0] },
		STORE    => sub { $_[0]->{$_[1]} = $_[2] },
		FETCH    => sub { $_[0]->{$_[1]} },
		FIRSTKEY => sub { my $a = scalar keys %{$_[0]}; each %{$_[0]} },
		NEXTKEY  => sub { each %{$_[0]} },
		EXISTS   => sub { exists $_[0]->{$_[1]} },
		DELETE   => sub { delete $_[0]->{$_[1]} },
		CLEAR    => sub { %{$_[0]} = () },
		SCALAR   => sub { scalar %{$_[0]} },
	);
}

{
	# use overload to implement "backdoor state" somewhat similar to that of Tie::ExtraHash (currently there are no tests for backdoor state itself)...
	package Object::Hybrid::ExtraHash;
	       @Object::Hybrid::ExtraHash::ISA 
	     = 'Object::Hybrid::StdHash';
	use overload '%{}' => 'self', fallback => 1;

	Object::Hybrid->methods(
		self     => sub { 
			my $back = ref $_[0];
			bless $_[0], 'NO_OVERLOAD';
			my $return = \%{$_[0]->{HASH}}; 
			bless $_[0], $back;
			return $return
		},
	);
}

{
	package Tie::StdHash;
	# @ISA = qw(Tie::Hash);         # would inherit new() only

	sub TIEHASH  { bless {}, $_[0] }
	sub STORE    { $_[0]->{$_[1]} = $_[2] }
	sub FETCH    { $_[0]->{$_[1]} }
	sub FIRSTKEY { my $a = scalar keys %{$_[0]}; each %{$_[0]} }
	sub NEXTKEY  { each %{$_[0]} }
	sub EXISTS   { exists $_[0]->{$_[1]} }
	sub DELETE   { delete $_[0]->{$_[1]} }
	sub CLEAR    { %{$_[0]} = () }
	sub SCALAR   { scalar %{$_[0]} }

	package Tie::ExtraHash;

	sub TIEHASH  { my $p = shift; bless [{}, @_], $p }
	sub STORE    { $_[0][0]{$_[1]} = $_[2] }
	sub FETCH    { $_[0][0]{$_[1]} }
	sub FIRSTKEY { my $a = scalar keys %{$_[0][0]}; each %{$_[0][0]} }
	sub NEXTKEY  { each %{$_[0][0]} }
	sub EXISTS   { exists $_[0][0]->{$_[1]} }
	sub DELETE   { delete $_[0][0]->{$_[1]} }
	sub CLEAR    { %{$_[0][0]} = () }
	sub SCALAR   { scalar %{$_[0][0]} }

	1;
}

{
	package Tie::Handle;

	use 5.006_001;
	our $VERSION = '4.1';

	use Carp;
	use warnings::register;

	sub new {
		my $pkg = shift;
		$pkg->TIEHANDLE(@_);
	}

	# "Grandfather" the new, a la Tie::Hash

	sub TIEHANDLE {
		my $pkg = shift;
		if (defined &{"{$pkg}::new"}) {
			warnings::warnif("WARNING: calling ${pkg}->new since ${pkg}->TIEHANDLE i
	s missing");
			$pkg->new(@_);
		}
		else {
			croak "$pkg doesn't define a TIEHANDLE method";
		}
	}

	sub PRINT {
		my $self = shift;
		if($self->can('WRITE') != \&WRITE) {
			my $buf = join(defined $, ? $, : "",@_);
			$buf .= $\ if defined $\;
			$self->WRITE($buf,length($buf),0);
		}
		else {
			croak ref($self)," doesn't define a PRINT method";
		}
	}

	sub PRINTF {
		my $self = shift;

		if($self->can('WRITE') != \&WRITE) {
			my $buf = sprintf(shift,@_);
			$self->WRITE($buf,length($buf),0);
		}
		else {
			croak ref($self)," doesn't define a PRINTF method";
		}
	}

	sub READLINE {
		my $pkg = ref $_[0];
		croak "$pkg doesn't define a READLINE method";
	}

	sub GETC {
		my $self = shift;

		if($self->can('READ') != \&READ) {
			my $buf;
			$self->READ($buf,1);
			return $buf;
		}
		else {
			croak ref($self)," doesn't define a GETC method";
		}
	}

	sub READ {
		my $pkg = ref $_[0];
		croak "$pkg doesn't define a READ method";
	}

	sub WRITE {
		my $pkg = ref $_[0];
		croak "$pkg doesn't define a WRITE method";
	}

	sub CLOSE {
		my $pkg = ref $_[0];
		croak "$pkg doesn't define a CLOSE method";
	}

	package Tie::StdHandle;
	our @ISA = 'Tie::Handle';
	use Carp;

	sub TIEHANDLE
	{
	 my $class = shift;
	 my $fh    = \do { local *HANDLE};
	 bless $fh,$class;
	 $fh->OPEN(@_) if (@_);
	 return $fh;
	}

	sub EOF     { eof($_[0]) }
	sub TELL    { tell($_[0]) }
	sub FILENO  { fileno($_[0]) }
	sub SEEK    { seek($_[0],$_[1],$_[2]) }
	sub CLOSE   { close($_[0]) }
	sub BINMODE { binmode($_[0]) }

	sub OPEN
	{
	 $_[0]->CLOSE if defined($_[0]->FILENO);
	 @_ == 2 ? open($_[0], $_[1]) : open($_[0], $_[1], $_[2]);
	}

	sub READ     { read($_[0],$_[1],$_[2]) }
	sub READLINE { my $fh = $_[0]; <$fh> }
	sub GETC     { getc($_[0]) }

	sub WRITE
	{
	 my $fh = $_[0];
	 print $fh substr($_[1],0,$_[2])
	}

	1;
}

my  @hybrid_class 
= ( 'Object::Hybrid::StdHash'
,   'Object::Hybrid::StdHash2'
,   'Object::Hybrid::ExtraHash' );

my  @tieclass 
= ( 'Tie::StdHash'
,   'Tie::ExtraHash' );

sub test_hash {
	my $promote = $_[0];

	foreach my $hybrid_class (@hybrid_class) {
		my $hybrid_class_frontal  =  Object::Hybrid->frontclass_name($hybrid_class, 'HASH');
		my $default_class_frontal =  Object::Hybrid->HASH_UNTIED;

		my $primitive = {}; 
		is(ref $promote->($primitive), $default_class_frontal); # makes %$primitive a hybrid
		is(ref            $primitive,  $default_class_frontal);
		  %$primitive =(foo =>       'bar'); # AFTER tie(), anything before will be ignored
		is($primitive->{foo},        'bar');
		ok($primitive->can('fetch'));
		ok($primitive->can('FETCH'));
		ok(Object::Hybrid->is($primitive));
		is($primitive->FETCH('foo'), 'bar');

		# testing "fail-safe" compartibility feature...
		{
			local $Object::Hybrid::Portable = 1;
			ok(  !$primitive->non_existing_method);
			eval{ $primitive->NON_EXISTING_METHOD };
			ok($@);
		}

		$primitive = {}; 

		is(ref $promote->($primitive, $hybrid_class),  $hybrid_class_frontal); # makes %$primitive a hybrid
		is(ref            $primitive                ,  $hybrid_class_frontal);
		  %$primitive =(foo =>       'bar'); # AFTER tie(), anything before will be ignored
		is($primitive->{foo},        'bar');
		ok($primitive->can('fetch'));
		ok($primitive->can('FETCH'));
		ok($primitive->isa($hybrid_class));
		is($primitive->FETCH('foo'), 'bar');

		$primitive = {}; 
					 %$primitive =(foo =>       'bar'); # AFTER tie(), anything before will be ignored
		is(           $primitive->{foo},        'bar');
		ok( not eval{ $primitive->FETCH('foo') } ); # not yet
		is(     tied(%$primitive), tied(%{$promote->($primitive, tieable => 1)}) ); # both not tied()
		is(     tied(%$primitive), tied(%{$promote->($primitive, tieable => 1)}) ); # $promote->() is idempotent
		ok( Object::Hybrid->is($primitive) );
					 %$primitive =(foo =>       'bar'); # AFTER tie(), anything before will be ignored
		ok(           $primitive->can('fetch'));
		ok(           $primitive->can('FETCH') );
		ok( Object::Hybrid->is($primitive));
		is(           $primitive->FETCH('foo'), 'bar');
		is(           $primitive->{foo},        'bar');

		foreach my $tieclass (@tieclass) {

			$primitive = {}; 
			tie(         %$primitive, $tieclass);
						 %$primitive =(foo =>       'bar'); # AFTER tie(), anything before will be ignored
			is(           $primitive->{foo},        'bar');
			ok( not eval{ $primitive->FETCH('foo') } ); # not yet
			is(     tied(%$primitive), tied(%{$promote->($primitive)}) );  # NEVER re-ties
			is(     tied(%$primitive), tied(%{$promote->($primitive)}) ); # $promote->() is idempotent
			is(       ref($primitive), Object::Hybrid->HASH_STATIC);
						 %$primitive =(foo =>       'bar'); # AFTER tie(), anything before will be ignored
			is(           $primitive->FETCH('foo'), 'bar');
			ok(           $primitive->can('fetch')); # this time check after FETCH() call...
			ok(           $primitive->can('FETCH') );
			ok( Object::Hybrid->is($primitive));
			is(           $primitive->{foo},        'bar');

			$primitive = {}; 
			tie(         %$primitive, $tieclass);
						 %$primitive =(foo =>       'bar'); # AFTER tie(), anything before will be ignored
			is(           $primitive->{foo},        'bar');
			ok( not eval{ $primitive->FETCH('foo') } ); # not yet
			is(     tied(%$primitive), tied(%{$promote->($primitive, tieable => 1)}) );  # NEVER re-ties
			is(     tied(%$primitive), tied(%{$promote->($primitive, tieable => 1)}) ); # $promote->() is idempotent
			is(       ref($primitive), Object::Hybrid->HASH_STATIC);
						 %$primitive =(foo =>       'bar'); # AFTER tie(), anything before will be ignored
			is(           $primitive->FETCH('foo'), 'bar');
			ok(           $primitive->can('fetch')); # this time check after FETCH() call...
			ok(           $primitive->can('FETCH') );
			ok( Object::Hybrid->is($primitive));
			is(           $primitive->{foo},        'bar');

			$primitive = {}; 
						 %$primitive =(foo =>       'bar'); # AFTER tie(), anything before will be ignored
			is(           $primitive->{foo},        'bar');
			ok( not eval{ $primitive->FETCH('foo') } ); # not yet
			Object::Hybrid->tie($primitive, $tieclass);
			is(       ref($primitive), Object::Hybrid->HASH_STATIC);
						 %$primitive =(foo =>       'bar'); # AFTER tie(), anything before will be ignored
			is(           $primitive->FETCH('foo'), 'bar');
			ok(           $primitive->can('fetch')); # this time check after FETCH() call...
			ok(           $primitive->can('FETCH') );
			ok( Object::Hybrid->is($primitive));
			is(           $primitive->{foo},        'bar');

			$primitive = {}; 
			tie(         %$primitive, $tieclass);
						 %$primitive =(foo =>       'bar'); # AFTER tie(), anything before will be ignored
			is(           $primitive->{foo},        'bar');
			ok( not eval{ $primitive->FETCH('foo') } ); # not yet
			ok(     tied(%$primitive) eq tied(%{$promote->($primitive, $hybrid_class)})   # NEVER re-ties
			or                     overload::Overloaded($primitive)); # implicitly untie()s - overload bug
			ok(     tied(%$primitive) eq tied(%{$promote->($primitive, $hybrid_class)})  # $promote->() is idempotent
			or                     overload::Overloaded($primitive)); # implicitly untie()s - overload bug
			ok( ref(tied(%$primitive)) eq $tieclass	
			or                     overload::Overloaded($primitive)); # implicitly untie()s - overload bug
						 %$primitive =(foo =>       'bar'); # AFTER tie(), anything before will be ignored
			ok(           $primitive->can('fetch'));
			ok(           $primitive->can('FETCH') );
			ok(           $primitive->isa($hybrid_class));
			is(           $primitive->FETCH('foo'), 'bar');
			is(           $primitive->{foo},        'bar');

		}
	}
}

test_hash(sub{ goto &promote });
test_hash(sub{ unshift @_, 'Object::Hybrid'; goto &{ $_[0]->can('new') } });

sub file_size { 
	my  ($file, $FH) = @_;
	ref $file eq 'SCALAR' ? length $$file # -s not work on (open() to) scalar handles
	:   $FH && defined fileno $FH ?     -s $FH->self 
	:                           -s $file;
}

sub file_slurp { 
	my  ($file, $FH) = @_;
	if (ref $file eq 'SCALAR') { return $$file }
	else { 
		$FH && defined fileno $FH
		or open $FH, '<', $file
		or  diag("Can't open() $file")
		, return "Can't open() $file";

		(my $pos = tell($FH)) >= 0 
		or  diag("Can't tell() $file")
		, return "Can't tell() $file";

		seek($FH, 0, 0);
		local $/;
		my $slurp = <$FH>;
		seek($FH, $pos, 0); 
		return $slurp
	}
}

use Fcntl;

my $test_filehandle = 69;
sub test_filehandle {

	my ($file, $FH, $promoclass) = @_;
	promote(   $FH, $promoclass||() );

	ok(     OPEN $FH '+>>' => $file );
	ok( ref $file eq 'SCALAR' 
	?      (OPEN $FH '+>'  => $file) 
	:   (SYSOPEN $FH $file, &Fcntl::O_RDWR|&Fcntl::O_TRUNC|&Fcntl::O_CREAT) );
	ok(  BINMODE $FH );
	#ok(    STAT $FH ); # not work on (open() to) scalar handles
	ok(    PRINT $FH  "Hello world" );
	is( file_slurp($file, $FH), "Hello world" );
	is(     TELL $FH, 11);
	is( file_size( $file, $FH), 11 ); 
	ok(     SEEK $FH 0, 0 );
	#ok(TRUNCATE $FH 0); # not work on (open() to) scalar handles
	ok(     OPEN $FH '+>'  => $file ); #flush
	ok(   PRINTF $FH  "Hello %d\n world", 1234);
	is( file_slurp($file, $FH), "Hello 1234\n world" );
	ok(     SEEK $FH 0, 0 );
	is( READLINE $FH, "Hello 1234\n" );
	ok(  not EOF $FH );
	is(  GETC $FH, ' ');
	ok(     READ $FH (my $slurp), 5 );
	is(       $slurp, 'world' );
	ok(      EOF $FH );
	ok(     SEEK $FH 0, 0 ); # ?
	#ok(    READ $FH $slurp, -s $FH->SELF  );      
	ok(     READ $FH $slurp, file_size( $file, $FH)  );
	is(       $slurp, "Hello 1234\n world" );
	#is(  ( READ $FH $slurp, -s $FH->SELF  ), 0 ); 
	is(   ( READ $FH $slurp, file_size( $file, $FH)  ), 0 );
	ok(      EOF $FH );
	ok(    CLOSE $FH );

	# Exactly same as bove, but with lowercased functions instead of indirect method notation...
	# It can be seen that, unlike above and below, this coding style cannot be kept consistent as it is affected by tiehandle implementation gaps - cannot uses sysopen() (and a few other functions) on tiehandle...
	ok( ref $file eq  'SCALAR' 
	?      (open $FH, '+>>' => $file) 
	:   (SYSOPEN $FH  $file, &Fcntl::O_RDWR|&Fcntl::O_CREAT) ); # perltie bug: cannot uses sysopen() on tiehandle
	ok(     open $FH, '+>'  => $file );
	ok(  binmode $FH );
	#ok(    stat $FH ); # not work on (open() to) scalar handles
	ok(    print $FH  "Hello world" );
	is( file_slurp($file, $FH), "Hello world" );
	is(     tell $FH, 11);
	is( file_size( $file, $FH), 11);
	#is(       -s $FH->SELF, 11 ); 
	ok(     seek $FH, 0, 0 );
	#ok(truncate $FH 0); # not work on (open() to) scalar handles
	ok(     open $FH, '+>'  => $file ); #flush
	ok(   printf $FH  "Hello %d\n world", 1234);
	is( file_slurp($file, $FH), "Hello 1234\n world" );
	ok(     seek $FH, 0, 0 );
	is( readline $FH, "Hello 1234\n" );
	ok(  not eof $FH );
	is(  getc $FH, ' ');
	ok(     read $FH, (my $slurp), 5 );
	is(       $slurp, 'world' );
	ok(      eof $FH );
	ok(     seek $FH, 0, 0 ); # ?
	#ok(    READ $FH $slurp, -s $FH->SELF  );      
	ok(     read $FH, $slurp, file_size( $file, $FH)  );
	is(       $slurp, "Hello 1234\n world" );
	#is(  ( read $FH, $slurp, -s $FH->SELF  ), 0 ); 
	is(   ( read $FH, $slurp, file_size( $file, $FH)  ), 0 );
	ok(      eof $FH );
	ok(    close $FH );

	# Exactly same as bove, but with lowercased direct method call notation...
	ok(     $FH->open( '+>>' => $file) );
	ok( ref $file eq 'SCALAR' 
	?       $FH->open( '+>'  => $file) 
	:       $FH->sysopen($file, &Fcntl::O_RDWR|&Fcntl::O_TRUNC|&Fcntl::O_CREAT) );
	ok(     $FH->binmode );
	#ok(    $FH->stat() ); # not work on (open() to) scalar handles
	ok(     $FH->print("Hello world") );
	is( file_slurp($file, $FH), "Hello world" );
	is(     $FH->tell, 11);
	is( file_size( $file, $FH), 11);
	#is( -s $FH->just, 11 ); 
	ok(     $FH->seek(0, 0) );
	#ok($FH->truncate( 0); # not work on (open() to) scalar handles
	ok(     $FH->open('+>'  => $file) ); #flush
	ok(     $FH->printf("Hello %d\n world", 1234) );
	is( file_slurp($file, $FH), "Hello 1234\n world" );
	ok(     $FH->seek(0, 0) );
	is(     $FH->readline, "Hello 1234\n" );
	ok( not $FH->eof );
	is(     $FH->getc, ' ' );
	ok(     $FH->read(my $slurp, 5) );
	is( $slurp, 'world' );
	ok(     $FH->eof );
	ok(     $FH->seek(0, 0) ); # ?
	#ok(    $FH->READ( $slurp, -s $FH->just  );      
	ok(     $FH->read($slurp, file_size( $file, $FH))  );
	is( $slurp, "Hello 1234\n world" );
	#is(  ( $FH->read( $slurp, -s $FH->just  ), 0 ); 
	is(   ( $FH->read($slurp, file_size( $file, $FH))  ), 0 );
	ok(     $FH->eof );
	ok(     $FH->close );

	# testing "fail-safe" compartibility feature: no FETCH() is defined for filehandles...
	ok(  !$FH->call('fetch') );
	eval{ $FH->FETCH(); };
	ok($@);

}

my (
$file,   $file_scalar);
$file = \$file_scalar;
SKIP: { 
	skip "No scalar-handles", $test_filehandle 
	unless eval{ open my $fh, '>', $file };
	test_filehandle($file, \*PLAIN_FH);
};

$file = 'test.tmp';
SKIP: { 
	skip "No scalar-handles", $test_filehandle 
	unless eval{ open my $fh, '>', $file };
	test_filehandle($file, \*PLAIN_FH);
};

$file = \$file_scalar;
SKIP: { 
	skip "Cannot find Tie::StdHandle", $test_filehandle 
	unless eval { open my $fh, '>', $file } ;

	tie *TIED_FH, 'Tie::StdHandle';
	test_filehandle($file, \*TIED_FH);
}

$file = 'test.tmp';
SKIP: { 
	skip "Cannot find Tie::StdHandle", $test_filehandle 
	unless eval { open my $fh, '>', $file } ;

	tie *TIED_FH2, 'Tie::StdHandle'; 
	test_filehandle($file, \*TIED_FH2);
}

$use_autobox and eval <<'CODE', (!$@ || die $@);

$a = { foo => 'bar' };
{
	use Object::Hybrid 'autopromote';
	ok({foo => 'bar'}->FETCH('foo'), 'bar');
	ok(            $a->fetch('foo'), 'bar');
}   ok(            $a->fetch('foo'), 'bar'); # beyond block scope

$a = { foo => 'bar' };
{
	use Object::Hybrid 'autobox';
	ok({foo => 'bar'}->FETCH('foo'), 'bar');
	ok(            $a->fetch('foo'), 'bar');
}   eval{          $a->fetch('foo')       }; # beyond block scope
ok($@);

CODE

