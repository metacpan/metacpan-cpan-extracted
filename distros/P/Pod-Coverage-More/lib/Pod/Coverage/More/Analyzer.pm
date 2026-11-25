# ABSTRACT: Infer arguments, return values and termination of subs from their compiled op trees
# PODNAME: Pod::Coverage::More::Analyzer

package Pod::Coverage::More::Analyzer 0.003;

use 5.036;
use warnings FATAL => q{all};
use re q{/xsaa};

use B               ();
use List::Util      qw{any};
use Module::Runtime qw{require_module module_notional_filename};
use Package::Stash;

use Pod::Coverage::More::Declared;
use Pod::Coverage::More::Types qw{type_of_value type_of_usage type_named};
use Scalar::Util               qw{blessed};

# The pad and SV helpers return an explicit undef because their callers put them in hash constructors,
# where a bare return would give an empty list and shift every pair after it.


# Lowest perl version of each version set, highest first.
our @BACKENDS = (
    [ 5.044 => 'Pod::Coverage::More::Analyzer::Perl5_44' ],
    [ 5.038 => 'Pod::Coverage::More::Analyzer::Perl5_38' ],
    [ 5.036 => 'Pod::Coverage::More::Analyzer::Perl5_36' ],
);

# The ops whose names say what kind of value they read or produce.
our %NUMERIC_OPS = map { $_ => 1 } qw{
  add subtract multiply divide modulo pow negate abs int sqrt
  lt gt le ge eq ne ncmp preinc predec postinc postdec
  i_add i_subtract i_multiply i_divide i_modulo i_negate
  i_lt i_gt i_le i_ge i_eq i_ne i_ncmp i_preinc i_predec i_postinc i_postdec
};
our %STRING_OPS = map { $_ => 1 } qw{
  concat multiconcat seq sne slt sgt sle sge scmp
  lc uc lcfirst ucfirst length substr index rindex match subst split
};
our %TERMINATORS = map { $_ => 1 } qw{
  CORE::GLOBAL::die CORE::GLOBAL::exit
  Carp::croak Carp::confess
  POSIX::_exit
};

# Methods that die by their contract: an exception class's throw, and the fatal level of a logger, as
# Log::Dispatchouli and so Dist::Zilla's log_fatal, and Log::Log4perl's logdie, logcroak and logconfess.
our %TERMINATING_METHODS = map { $_ => 1 } qw{throw log_fatal logdie logcroak logconfess};
our %BOOLEAN_OPS         = map { $_ => 1 } qw{
  not defined exists
  lt gt le ge eq ne i_lt i_gt i_le i_ge i_eq i_ne
  slt sgt sle sge seq sne
};

# The ops whose result is always a whole number.
our %INTEGER_OPS = map { $_ => 1 } qw{
  index rindex scmp time
  i_add i_subtract i_multiply i_divide i_modulo i_negate i_ncmp
};

# The ops whose result is a whole number or undef: length of undef, and <=> of NaN.
our %MAYBE_INTEGER_OPS = map { $_ => 1 } qw{length ncmp};

# The classes that the numbers of the scope of each bignum pragma are, by its key in %^H.
our %BIG_CLASSES = (
    bigint   => ['Math::BigInt'],
    bignum   => [ 'Math::BigInt', 'Math::BigFloat' ],
    bigrat   => ['Math::BigRat'],
    bigfloat => ['Math::BigFloat'],
);
our %NUMBER_OPS = map { $_ => 1 } qw{
  add subtract multiply divide modulo pow negate abs int sqrt ncmp scmp
  i_add i_subtract i_multiply i_divide i_modulo i_negate i_ncmp
  length index rindex time
};
our %STRING_RESULT_OPS = map { $_ => 1 } qw{
  concat multiconcat stringify join sprintf lc uc lcfirst ucfirst substr ref
};
our %LIST_OPS            = map { $_ => 1 } qw{ sort grepwhile mapwhile keys values reverse split };
our $HELEM               = B::opnumber(q{helem});
our @HASH_MDEREF_ACTIONS = (
    B::MDEREF_HV_pop_rv2hv_helem(),          B::MDEREF_HV_gvsv_vivify_rv2hv_helem(),
    B::MDEREF_HV_padsv_vivify_rv2hv_helem(), B::MDEREF_HV_vivify_rv2hv_helem(),
    B::MDEREF_HV_padhv_helem(),              B::MDEREF_HV_gvhv_helem(),
);


# An analyzer of the subclass that handles the running perl.
# @returns Object  the analyzer, an instance of that subclass
# @throws  when the running perl is older than the oldest supported version set
# @example my $analyzer = Pod::Coverage::More::Analyzer->new;
sub new {
    my ($class) = @_;
    my $backend = $class eq __PACKAGE__ ? backend_for($]) : $class;
    require_module($backend) if $backend ne $class;
    return bless( {}, $backend );
}

# The subclass that handles the perl C<version>.
# @param   version  Num  in the numeric form of C<$]>
# @returns Str  the name of the subclass
# @throws  when no subclass handles the version
# @example my $backend = Pod::Coverage::More::Analyzer::backend_for($]);
sub backend_for {
    my ($version) = @_;
    foreach my $backend (@BACKENDS) {
        return $backend->[1] if $version >= $backend->[0];
    }
    die "Perl $version is not supported, the oldest supported perl is $BACKENDS[-1][0]\n";
}

# The records of the subs that C<package> defines, as C<analyze_sub> returns them.
# The package must be loaded already.  Subs that it imported from another package are left out.
#
# When a class builder or a signature module declares a sub, as L<Pod::Coverage::More::Declared> reads it,
# its record also has C<declared>: that declaration, with C<wrapped> in place of its C<body>,
# and each parameter that a declared one matches has C<declared>, the declared L<Type::Tiny> constraint.
# The record of a sub that only wraps the code that does the work describes that code.
# @param   package  Str  the name of the package
# @returns HashRef  from the name of each sub to its record
# @example my $records = $analyzer->analyze_package('Pod::Coverage::More');
sub analyze_package {
    my ( $self, $package ) = @_;

    my $stash = Package::Stash->new($package);
    my %code;
    foreach my $name ( $stash->list_all_symbols(q{CODE}) ) {
        my $code = $stash->get_symbol("&$name");
        $code{$name} = $code if _defined_in( B::svref_2object($code) ) eq $package;
    }

    my $declared = Pod::Coverage::More::Declared->declarations_for( $package, [ sort keys %code ] );
    my %subs;
    foreach my $name ( sort keys %code ) {
        my $declaration = $declared->{$name};
        my $body        = $declaration ? $declaration->{body} : undef;
        $subs{$name} = $self->analyze_sub( $body // $code{$name}, $name, $package );
        _attach_declaration( $subs{$name}, $declaration ) if $declaration;
    }
    return \%subs;
}

# Records DECLARATION on the record REC, and the declared type of each parameter on the parameter that it matches:
# by name, or else by position.  The invocant is never matched, because a class builder and the code number it differently.
sub _attach_declaration {
    my ( $rec, $declaration ) = @_;
    my %declared = %$declaration;
    $declared{wrapped} = delete( $declared{body} ) ? 1 : 0;
    $rec->{declared} = \%declared;

    foreach my $param ( @{ $rec->{params} } ) {
        foreach my $candidate ( @{ $declaration->{params} } ) {
            next if $candidate->{invocant} || !$candidate->{type};
            my $by_name     = defined $candidate->{name}  && defined $param->{name}      && $candidate->{name} eq $param->{name};
            my $by_position = !defined $candidate->{name} && defined $candidate->{index} && $candidate->{index} == $param->{index};
            next if !$by_name && !$by_position;
            $param->{declared}    = $candidate->{type};
            $param->{declared_by} = $declaration->{via};
            last;
        }
    }
    return;
}


# The record of what the op tree of C<code> shows, as RECORDS describes it.
# @param   code     CodeRef  the sub
# @param   name     Str      the name of the sub
# @param   package  Str      the package that the sub belongs to
# @returns HashRef  the record
# @example my $record = $analyzer->analyze_sub( \&Pod::Coverage::More::coverage, 'coverage', 'Pod::Coverage::More' );
sub analyze_sub {
    my ( $self, $code, $name, $package ) = @_;

    my $cv  = B::svref_2object($code);
    my %rec = (
        name       => $name,
        package    => $package,
        file       => $cv->FILE,
        generated  => _is_generated( $cv, $name, $package ),
        method     => 0,
        signature  => 0,
        reads_args => 0,
        params     => [],
        usage      => {},
        returns    => [],
        dies       => [],
    );

    if ( $cv->CvFLAGS & B::CVf_CONST ) {
        $rec{kind}  = 'constant';
        $rec{value} = $code->();
        my $returned = _sv_evidence( B::svref_2object( \$rec{value} ) );
        push @{ $rec{returns} }, { %$returned, constraint => type_of_value($returned) };
        return \%rec;
    }
    if ( $cv->XSUB ) {
        $rec{kind} = 'xs';
        return \%rec;
    }
    $rec{kind} = 'perl';

    # The state of one walk lives on a copy of the analyzer, which shares its caches.
    $self->{handlers}    //= $self->op_handlers;
    $self->{classifiers} //= $self->op_classifiers;
    my $walker = bless {
        %$self,
        cv        => $cv,
        rec       => \%rec,
        shifted   => 0,
        consumed  => {},
        line_of   => {},
        line      => undef,
        signature => undef,
        checkers  => {},
        guards    => {},
        big       => undef,
        big_of    => {},
      },
      ref $self;

    $walker->_walk( $cv->ROOT, [] );
    push @{ $rec{returns} }, map { +{ %$_, implicit => 1 } } $walker->_implicit_returns( $cv->ROOT );
    $walker->finish_sub( \%rec );

    # A class taken from the invocant is the package or a subclass, and an object of either is an instance of the package.
    my ($invocant) = grep { $_->{index} == 0 && defined $_->{name} } @{ $rec{params} };
    foreach my $returned ( @{ $rec{returns} } ) {
        $returned->{class} //= $package
          if $invocant && $returned->{type} eq 'object' && ( $returned->{class_from} // q{} ) eq $invocant->{name};
        $returned->{constraint} = type_of_value($returned);
    }
    @{ $rec{params} } = sort { $a->{index} <=> $b->{index} } @{ $rec{params} };
    foreach my $param ( @{ $rec{params} } ) {
        next unless defined $param->{name};
        my $keys = $rec{usage}{ $param->{name} }{keys};
        $param->{keys}     = [@$keys] if $keys;
        $param->{inferred} = type_of_usage( $rec{usage}{ $param->{name} } || {} );
        if ( my $guard = $walker->{guards}{ $param->{name} } ) {
            $param->{declared}    = $guard->{type};
            $param->{declared_by} = $guard->{by};
        }
    }
    return \%rec;
}

# Called once the op tree of a sub was walked, before the parameters are sorted.
# Subclasses override it to add what only the whole tree shows.  The default does nothing.
# @param   record  HashRef  the record of the sub, as RECORDS describes it
# @returns nothing
# @example $walker->finish_sub( \%record );
sub finish_sub {
    return;
}

# The methods that the walk calls for each op, with the op and the ARRAYREF of its ancestors, nearest last.
# Subclasses add the ops of their version set to what this returns.
# @returns HashRef  from the name of each op to the name of its method
# @example my $handlers = $analyzer->op_handlers;
sub op_handlers {
    return {
        nextstate  => \&_on_cop,
        dbstate    => \&_on_cop,
        sassign    => \&_on_sassign,
        aassign    => \&_on_aassign,
        shift      => \&_on_shift,
        aelemfast  => \&_on_aelemfast,
        padsv      => \&_on_pad,
        padav      => \&_on_pad,
        padhv      => \&_on_pad,
        rv2av      => \&_on_rv2av,
        multideref => \&_on_multideref,
        helem      => \&_on_helem,
        exists     => \&_on_exists,
        delete     => \&_on_exists,
        entersub   => \&_on_entersub,
        return     => \&_on_return,
        die        => \&_on_die,
        exit       => \&_on_die,
    };
}

# The methods that C<classify> calls for some ops, ahead of its own rules.
# Subclasses add the value-producing ops of their version set here, as they add walk handlers in C<op_handlers>.
# The default has none.
# @returns HashRef  from the name of each op to the name of its method
# @example my $classifiers = $analyzer->op_classifiers;
sub op_classifiers {
    return {};
}

# The kids of C<op>, in order, for the handlers of subclasses.
# @param   op  B::OP  the op
# @returns the kids, as a list of B::OP objects
# @example my @kids = $self->op_kids($op);
sub op_kids {
    my ( undef, $op ) = @_;
    return _kids($op);
}

# Whether something other than the source of PACKAGE wrote the sub: a closure installed under another name,
# a string eval, or a sub compiled in another file, as a class builder compiles accessors.
sub _is_generated {
    my ( $cv, $name, $package ) = @_;
    return 1 if $cv->GV->NAME ne $name || $cv->FILE =~ m/\A\(eval/;
    my $own = $INC{ module_notional_filename($package) };
    return ( defined $own && $cv->FILE ne $own ) ? 1 : 0;
}

# The package the sub was compiled in, as opposed to the one it was imported into.
sub _defined_in {
    my ($cv) = @_;
    my $gv = $cv->GV;
    return '' if B::class($gv) ne 'GV';
    return $gv->STASH->NAME;
}

# These subs walk an op tree, which is as deep as the nesting of the source, and so recursion is their natural form.
## no critic (Subroutines::ProhibitTailRecursion)

sub _walk {
    my ( $self, $op, $ancestors ) = @_;
    return if !$$op;

    $self->{line_of}{$$op} = $self->{line};
    $self->{big_of}{$$op}  = $self->{big};

    my $handler = $self->{handlers}{ $op->name };
    $self->$handler( $op, $ancestors ) if $handler;

    my @kids = $self->op_kids($op);
    return unless @kids;
    push @$ancestors, $op;
    foreach my $kid (@kids) {
        $self->_walk( $kid, $ancestors );
    }
    pop @$ancestors;
    return;
}

# The values a sub returns when control reaches its end without a return statement.
sub _last_values {
    my ( $self, $op ) = @_;
    return () if !$op || !$$op;
    my $name = $op->name;

    if ( $name eq 'lineseq' || $name eq 'scope' || $name eq 'leave' || $name eq 'null' ) {
        my @kids;
        foreach my $kid ( _significant_kids($op) ) {
            push @kids, $kid unless $kid->name eq 'nextstate' || $kid->name eq 'dbstate' || $kid->name eq 'enter';
        }
        return ()                   if !@kids && $name ne 'null';
        return $self->classify($op) if !@kids;

        # A null op that wraps one expression is that expression.
        return $self->_last_values( $kids[-1] ) if $name ne 'null' || @kids == 1;
        return $self->classify($op);
    }
    if ( $name eq 'cond_expr' ) {
        my $line = $self->{line_of}{$$op};
        my @values;
        foreach my $branch ( ( _branches($op) )[ 1, 2 ] ) {
            push @values, _is_empty_list($branch) ? { type => 'empty', line => $line } : $self->_last_values($branch);
        }
        return @values;
    }
    if ( $name eq 'and' || $name eq 'or' || $name eq 'dor' ) {

        # if (COND) { BODY } without an else: COND's value when the body does not run.
        my ( $cond, $body ) = _kids($op);
        return ( $self->classify($cond), $self->_last_values($body) );
    }
    return () if $name eq 'return' || $name eq 'die' || $name eq 'exit' || $name eq 'stub';

    my $line = $self->{line_of}{$$op};
    return ( { type => 'unknown', op => 'loop', line => $line } ) if $name eq 'leaveloop';
    return map { +{ %$_, line => $line } } $self->classify($op);
}

# The evidence that C<op>, an op that produces a value, gives about that value.
# It is one HASHREF per alternative, because an expression such as C<COND ? A : B> has more than one.
#
# The C<type> of each is one of C<undef>, C<empty>, C<number>, C<string>, C<boolean>, C<hashref>, C<arrayref>, C<coderef>, C<ref>,
# C<object>, C<variable>, C<call>, C<method>, C<list>, C<context> or C<unknown>.
# @param   op  B::OP  the op that produces the value
# @returns the evidence, as a list of HASHREFs
# @example my @evidence = $self->classify($op);
sub classify {
    my ( $self, $op ) = @_;
    return { type => 'empty' } if _is_empty_list($op);
    $op = _unwrap($op);
    my $name = $op->name;

    my $classifier = $self->{classifiers}{$name};
    return $self->$classifier($op) if $classifier;

    return _sv_evidence( $self->_const_sv($op) ) if $name eq 'const';
    return { type => 'undef' }    if $name eq 'undef';
    return { type => 'hashref' }  if $name eq 'anonhash';
    return { type => 'arrayref' } if $name eq 'anonlist';
    return { type => 'coderef' }  if $name eq 'anoncode';
    return { type => 'context' }  if $name eq 'wantarray';

    return $self->_classify_refgen($op) if $name eq 'srefgen' || $name eq 'refgen';
    return $self->_classify_bless($op)  if $name eq 'bless';

    if ( $name eq 'scalar' ) {
        my ($kid) = _significant_kids($op);
        return { type => 'unknown', op => $name } if !$kid;
        my $kname = _unwrap($kid)->name;
        return { type => 'number', integer => 1 } if $kname eq 'padav' || $kname eq 'rv2av';
        return $self->classify($kid);
    }
    if ( $name eq 'padsv' || $name eq 'padav' || $name eq 'padhv' ) {
        return { type => 'variable', name => $self->_padname( $op->targ ) };
    }
    if ( $name eq 'sassign' ) {
        my ($value) = _kids($op);
        return $self->classify($value);
    }
    if ( $name eq 'cond_expr' ) {
        my ( $cond, $then, $else ) = _branches($op);

        # wantarray ? LIST : SCALAR says which value goes with which context.
        if ( _unwrap($cond)->name eq 'wantarray' ) {
            return (
                ( map { +{ %$_, context => 'list' } } $self->classify($then) ),
                ( map { +{ %$_, context => 'scalar' } } $self->classify($else) ),
            );
        }
        return ( $self->classify($then), $self->classify($else) );
    }
    if ( $name eq 'or' || $name eq 'dor' || $name eq 'and' ) {
        my @evidence;
        foreach my $kid ( _kids($op) ) {
            push @evidence, $self->classify($kid);
        }
        return @evidence;
    }
    if ( $name eq 'entersub' ) {
        my ($target) = $self->_call_target($op);
        return $target // { type => 'call' };
    }
    return _weak( { type => 'boolean' } ) if $BOOLEAN_OPS{$name};
    if ( $NUMBER_OPS{$name} ) {

        # A return statement classifies its value before the walk reaches it, in the scope of the statement.
        my $big = exists $self->{big_of}{$$op} ? $self->{big_of}{$$op} : $self->{big};
        return { type => 'object', classes => $big, weak => 1 }              if $big;
        return _weak( { type => 'number', integer => 1 } )                   if $INTEGER_OPS{$name};
        return _weak( { type => 'number', integer => 1, maybe_undef => 1 } ) if $MAYBE_INTEGER_OPS{$name};
        return _weak( { type => 'number' } );
    }
    return _weak( { type => 'string' } ) if $STRING_RESULT_OPS{$name};
    return { type => 'list' } if $LIST_OPS{$name};
    return { type => 'unknown', op => $name };
}

## use critic

sub _kids {
    my ($op) = @_;
    return () unless $op->flags & B::OPf_KIDS;
    my @kids;
    for ( my $kid = $op->first; $$kid; $kid = $kid->sibling ) {
        push @kids, $kid;
        last unless $kid->moresib;
    }
    return @kids;
}

# The condition and the two branches of COND ? THEN : ELSE.  Perl leaves a branch that is an empty list out of the
# op tree, so a missing branch comes back as undef: the one left is THEN when the jump of the op lands in it.
sub _branches {
    my ($op) = @_;
    my ( $cond, @branches ) = _kids($op);
    return ( $cond, @branches ) if @branches != 1;
    return ( $cond, $branches[0], undef ) if _holds( $branches[0], $op->other );
    return ( $cond, undef, $branches[0] );
}

# Whether OP is an empty list: a branch that perl left out of the op tree, as 5.44 does with the () of a ternary,
# or the stub op that older perls compile it to.
sub _is_empty_list {
    my ($op) = @_;
    return !$op || $op->name eq 'stub';
}

# Whether TARGET is OP or an op under it.
sub _holds {
    my ( $op, $target ) = @_;
    my @ops = ($op);
    while ( my $next = shift @ops ) {
        return 1 if $$next == $$target;
        push @ops, _kids($next);
    }
    return 0;
}

# Kids that do something, as opposed to list markers and optimized-away ops.
sub _significant_kids {
    my ($op) = @_;
    my @significant;
    foreach my $kid ( _kids($op) ) {
        my $name = $kid->name;
        next if $name eq 'pushmark' || $name eq 'padrange';
        next if $name eq 'null' && !( $kid->flags & B::OPf_KIDS );
        push @significant, $kid;
    }
    return @significant;
}

# Unwrap ex-list and similar null ops that have one kid.
sub _unwrap {
    my ($op) = @_;
    while ( $op->name eq 'null' ) {
        my @kids = _significant_kids($op);
        last if @kids != 1;
        $op = $kids[0];
    }
    return $op;
}

sub _padname {
    my ( $self, $targ ) = @_;
    return undef if !$targ;
    my $padname = $self->{cv}->PADLIST->ARRAYelt(0)->ARRAYelt($targ);
    return undef if !$padname || B::class($padname) eq 'SPECIAL';
    return $padname->PVX;
}

sub _padval {
    my ( $self, $index ) = @_;
    return $self->{cv}->PADLIST->ARRAYelt(1)->ARRAYelt($index);
}

# Under threaded perls, GVs and constants live in the pad instead of the op.
sub _gv {
    my ( $self, $op ) = @_;
    return B::class($op) eq 'PADOP' ? $self->_padval( $op->padix ) : $op->gv;
}

sub _const_sv {
    my ( $self, $op ) = @_;
    my $sv = $op->sv;
    $sv = $self->_padval( $op->targ ) unless $$sv;
    return $sv;
}

sub _sv_value {
    my ($sv) = @_;
    my $class = B::class($sv);
    return undef if $class eq 'SPECIAL' || $class eq 'NULL';
    my $flags = $sv->FLAGS;
    return $sv->PV if $flags & B::SVf_POK;
    return $sv->NV if $flags & B::SVf_NOK;
    return $sv->IV if $flags & B::SVf_IOK;
    return undef;
}

sub _sv_evidence {
    my ($sv) = @_;
    my $class = B::class($sv);
    return { type => 'undef' } if $class eq 'SPECIAL' || $class eq 'NULL';
    my $flags = $sv->FLAGS;
    return _reference_evidence( $sv->RV ) if $flags & B::SVf_ROK;
    return { type => 'string', value => $sv->PV }        if $flags & B::SVf_POK;
    return { type => 'number', value => _sv_value($sv) } if $flags & ( B::SVf_IOK | B::SVf_NOK );
    return { type => 'undef' };
}

# The result of an operator is only probable: an operand of a class that overloads the operator,
# such as Math::GMP, makes it an object of that class.  So its EVIDENCE is weak.
sub _weak {
    my ($evidence) = @_;
    return { %$evidence, weak => 1 };
}

# A constant that holds a reference, as use bigint makes of every numeric literal, or use constant of a list.
sub _reference_evidence {
    my ($referent) = @_;
    return { type => 'object', class => $referent->SvSTASH->NAME } if $referent->FLAGS & B::SVs_OBJECT;
    my $class = B::class($referent);
    return { type => 'arrayref' } if $class eq 'AV';
    return { type => 'hashref' }  if $class eq 'HV';
    return { type => 'coderef' }  if $class eq 'CV';
    return { type => 'ref' };
}

sub _fullname {
    my ($gv) = @_;
    return undef if B::class($gv) ne 'GV';
    return $gv->STASH->NAME . '::' . $gv->NAME;
}

# The name of the sub a call goes to, where it was defined rather than where it was imported to,
# so that an imported croak reads as Carp::croak.
sub _sub_fullname {
    my ($gv) = @_;
    return undef if B::class($gv) ne 'GV';
    my $cv = $gv->CV;
    if ( $$cv && B::class($cv) eq 'CV' ) {
        my $origin = $cv->GV;
        return _fullname($origin) if B::class($origin) eq 'GV' && $origin->NAME ne '__ANON__';
    }
    return _fullname($gv);
}

sub _is_args_array {
    my ( $self, $op ) = @_;
    $op = _unwrap($op);
    return 0 unless $op->name eq 'rv2av';
    my ($gvop) = _kids($op);
    return 0 unless $gvop && $gvop->name eq 'gv';
    my $gv = $self->_gv($gvop);
    return ( _fullname($gv) // '' ) eq 'main::_';
}

# A shift or pop of @_.  With no argument, the op has no kids at all.
sub _is_args_shift {
    my ( $self, $op ) = @_;
    $op = _unwrap($op);
    return 0 unless $op->name eq 'shift';
    my @kids = _kids($op);
    return 1 if !@kids;
    return $self->_is_args_array( $kids[0] );
}

sub _usage_of {
    my ( $self, $var ) = @_;
    return $self->{rec}{usage}{$var} //= {};
}

sub _add_param {
    my ( $self, %param ) = @_;
    my $params = $self->{rec}{params};
    return if defined $param{name}  && any { ( $_->{name} // '' ) eq $param{name} } @$params;
    return if !defined $param{name} && any { $_->{index} == $param{index} } @$params;
    $param{slurpy} //= ( defined $param{name} && $param{name} =~ m/\A[@%]/ ) ? 1 : 0;
    push @$params, \%param;
    return;
}

sub _on_cop {
    my ( $self, $op ) = @_;
    $self->{line} = $op->line;
    $self->{rec}{line} //= $op->line;

    my $hints = $op->hints_hash->HASH;
    my ($pragma) = grep { $hints->{$_} } sort keys %BIG_CLASSES;
    $self->{big} = $pragma ? $BIG_CLASSES{$pragma} : undef;
    return;
}

sub _assign_from_args {
    my ( $self, $value, $target_name ) = @_;
    $value = _unwrap($value);
    if ( $self->_is_args_shift($value) ) {
        $self->{consumed}{$$value} = 1;
        $self->_add_param( name => $target_name, index => $self->{shifted}++, source => 'shift' );
    }
    elsif ( $value->name eq 'aelemfast' && $self->_is_args_elem($value) ) {
        $self->{consumed}{$$value} = 1;
        $self->_add_param( name => $target_name, index => _elem_index($value), source => 'element' );
    }
    elsif ( my ( $elem, $default, $mode ) = $self->_defaulted_elem($value) ) {
        $self->{consumed}{$$elem} = 1;
        $self->_add_param(
            name     => $target_name,
            index    => _elem_index($elem),
            source   => 'element',
            optional => 1,
            default  => { mode => $mode, value => [ $self->classify($default) ] },
        );
    }
    return;
}

# $_[N] with a default: @_ > N ? $_[N] : DEFAULT, as Method::Signatures and hand-written code say it, or $_[N] // DEFAULT.
# Returns the element, the default, and how the default applies, or nothing.
sub _defaulted_elem {
    my ( $self, $op ) = @_;
    my $name = $op->name;
    if ( $name eq 'cond_expr' ) {
        my ( undef, $then, $else ) = _branches($op);
        $then = _unwrap($then) if $then;
        return ( $then, $else, q{=} ) if $then && $then->name eq 'aelemfast' && $self->_is_args_elem($then);
    }
    if ( $name eq 'dor' || $name eq 'or' ) {
        my ( $left, $right ) = _kids($op);
        $left = _unwrap($left);
        return ( $left, $right, $name eq 'dor' ? q{//=} : q{||=} ) if $left->name eq 'aelemfast' && $self->_is_args_elem($left);
    }
    return;
}

# The assignment of one value to a lexical scalar: the value is the first kid, and the target the last.
sub _on_sassign {
    my ( $self, $op ) = @_;
    my @kids = _kids($op);
    return if @kids != 2;
    my $target = _unwrap( $kids[1] );
    return unless $target->name eq 'padsv';
    $self->_assign_from_args( $kids[0], $self->_padname( $target->targ ) );
    return;
}

# A list assignment to lexicals, from @_ or from one shift of it.
sub _on_aassign {
    my ( $self, $op )  = @_;
    my ( $rhs,  $lhs ) = _kids($op);
    return unless $rhs && $lhs;

    my @values = _significant_kids($rhs);
    my @targets;
    foreach my $kid ( _significant_kids($lhs) ) {
        push @targets, $kid if $kid->name =~ m/\Apad[ash]v\z/;
    }
    return if @values != 1 || !@targets;

    if ( $self->_is_args_array( $values[0] ) ) {
        foreach my $target (@targets) {
            my $name = $self->_padname( $target->targ );
            if ( $target->name eq 'padsv' ) {
                $self->_add_param( name => $name, index => $self->{shifted}++, source => 'list' );
            }
            else {
                $self->_add_param( name => $name, index => $self->{shifted}, source => 'list' );
                last;
            }
        }
    }
    elsif ( $self->_is_args_shift( $values[0] ) ) {
        $self->{consumed}{ ${ _unwrap( $values[0] ) } } = 1;
        $self->_add_param( name => $self->_padname( $targets[0]->targ ), index => $self->{shifted}++, source => 'shift' );
    }
    elsif ( my $checked = $self->_checked_call( $values[0] ) ) {
        my @types = @{ $checked->{types} };
        foreach my $target (@targets) {
            my $name = $self->_padname( $target->targ );
            if ( $target->name ne 'padsv' ) {
                $self->_add_param( name => $name, index => $self->{shifted}, source => 'checked' );
                last;
            }
            my $type = shift @types;
            $self->_add_param(
                name   => $name,
                index  => $self->{shifted}++,
                source => 'checked',
                $type ? ( declared => $type, declared_by => $checked->{by} ) : (),
            );
        }
    }
    return;
}

# A call that checks the arguments of the sub, such as $check->(@_), validate(\@_, ...) or validate_pos(@_, ...):
# returns the types it checks them against, by position, as far as the op tree shows them, or nothing when OP is no such call.
sub _checked_call {
    my ( $self, $op ) = @_;
    $op = _unwrap($op);
    return if $op->name ne 'entersub';
    my ( $target, $args ) = $self->_call_target($op);
    my @rest = @$args;
    my $receives_args;
    while ( my $arg = shift @rest ) {
        my $value = _unwrap($arg);
        $value = _unwrap( ( _kids($value) )[0] ) if $value->name eq 'srefgen' && _kids($value);
        next if !$self->_is_args_array($value);
        $receives_args = 1;
        last;
    }
    return if !$receives_args;

    if ( ( $target->{function} // q{} ) eq 'Type::Params::validate' ) {
        return { types => $self->_try_static_values( \@rest ), by => 'Type::Params' };
    }
    my $checker = defined $target->{coderef} ? $self->{checkers}{ $target->{coderef} } : undef;
    return { types => [ @{ $checker // [] } ], by => 'Type::Params' };
}

# The value that OP builds from constants and calls to the type functions of a Type::Library, as in Optional[Str].
# Dies when OP builds anything else.
# It walks the op tree of one expression, and so recursion is its natural form.
## no critic (Subroutines::ProhibitTailRecursion)
sub _static_value {
    my ( $self, $op ) = @_;
    $op = _unwrap($op);
    my $name = $op->name;
    return _sv_value( $self->_const_sv($op) ) if $name eq 'const';
    if ( $name eq 'anonlist' ) {
        my @values;
        foreach my $kid ( _significant_kids($op) ) {
            push @values, $self->_static_value($kid);
        }
        return \@values;
    }
    if ( $name eq 'entersub' ) {
        my ( $target,  $args ) = $self->_call_target($op);
        my ( $library, $type ) = ( $target->{function} // q{} ) =~ m/\A(.+)::(\w+)\z/;
        die "not a type\n"               if !$type || !_is_type_library($library) || !$library->has_type($type);
        return $library->get_type($type) if !@$args;
        my @values;
        foreach my $arg (@$args) {
            push @values, $self->_static_value($arg);
        }
        return $library->can($type)->(@values);
    }
    die "not a static value\n";
}
## use critic

# The value of _static_value, or undef when OP builds anything else.
sub _try_static_value {
    my ( $self, $op ) = @_;
    my $value;
    return eval { $value = $self->_static_value($op); 1 } ? $value : undef;
}

# The values of _try_static_value for each op of the ARRAYREF OPS.
sub _try_static_values {
    my ( $self, $ops ) = @_;
    my @values;
    foreach my $op (@$ops) {
        push @values, $self->_try_static_value($op);
    }
    return \@values;
}

sub _is_type_library {
    my ($package) = @_;
    my $is;
    return eval { $is = $package->isa('Type::Library'); 1 } ? $is : 0;
}

# Records the types that compile() of Type::Params returns a checker for, under the variable the checker is assigned to.
sub _note_checker {
    my ( $self, $args, $ancestors ) = @_;
    my $parent = $ancestors->[-1] // return;
    my $var;
    $var = $self->_padname( $parent->targ ) if $parent->name eq 'padsv_store';
    if ( $parent->name eq 'sassign' ) {
        my ( undef, $target ) = _kids($parent);
        $target = _unwrap($target);
        $var    = $self->_padname( $target->targ ) if $target->name eq 'padsv';
    }
    return if !defined $var;
    $self->{checkers}{$var} = $self->_try_static_values($args);
    return;
}

our %GUARD_METHODS = map { $_ => 1 } qw{assert_valid assert_return check};

# Records the type that a guard checks a variable against: is_X($var) and assert_X($var) of a Type::Library,
# TYPE->assert_valid($var) and its kind, and the type_error() calls that Method::Signatures compiles.
sub _note_guard {
    my ( $self, $target, $args ) = @_;
    my ( $type, $checked, $by );

    if ( defined $target->{function} ) {
        my ( $library, $guard ) = $target->{function} =~ m/\A(.+)::(?:assert|is)_(\w+)\z/;
        return if !$guard || !_is_type_library($library) || !$library->has_type($guard);
        ( $type, $checked, $by ) = ( $library->get_type($guard), $args->[0], 'Type::Tiny' );
    }
    elsif ( $target->{type} eq 'method' && defined $target->{method} ) {
        my $invocant = $args->[0] // return;
        if ( $GUARD_METHODS{ $target->{method} } ) {
            $type = $self->_try_static_value($invocant);
            ( $checked, $by ) = ( $args->[1], 'Type::Tiny' );
        }
        elsif ( $target->{method} eq 'type_error' && ( $self->_try_static_value($invocant) // q{} ) eq 'Method::Signatures' ) {
            my $name = $self->_try_static_value( $args->[1] );
            $type = type_named($name);
            ( $checked, $by ) = ( $args->[2], 'Method::Signatures' );
        }
    }
    return if !$type || !blessed($type) || !$checked;
    $checked = _unwrap($checked);
    return if $checked->name ne 'padsv';
    my $var = $self->_padname( $checked->targ ) // return;
    $self->{guards}{$var} = { type => $type, by => $by };
    return;
}

# Any use of @_, as a sub that only passes it on makes.
sub _on_rv2av {
    my ( $self, $op ) = @_;
    $self->{rec}{reads_args} = 1 if $self->_is_args_array($op);
    return;
}

# A shift of @_ that is not assigned to a variable, as in shift->method.
sub _on_shift {
    my ( $self, $op ) = @_;
    return unless $self->_is_args_shift($op);
    $self->{rec}{reads_args} = 1;
    return if $self->{consumed}{$$op};
    $self->_add_param( name => undef, index => $self->{shifted}++, source => 'shift' );
    return;
}

sub _is_args_elem {
    my ( $self, $op ) = @_;
    my $gv = $self->_gv($op);
    return ( _fullname($gv) // '' ) eq 'main::_';
}

sub _elem_index {
    my ($op) = @_;
    return unpack( 'c', pack( 'C', $op->private ) );
}

# $_[N] used directly.
sub _on_aelemfast {
    my ( $self, $op ) = @_;
    return unless $self->_is_args_elem($op);
    $self->{rec}{reads_args} = 1;
    return if $self->{consumed}{$$op};
    my $index = _elem_index($op);
    return if $index < 0;
    $self->_add_param( name => undef, index => $index, source => 'element' );
    return;
}

sub _on_pad {
    my ( $self, $op, $ancestors ) = @_;
    my $var    = $self->_padname( $op->targ ) // return;
    my $parent = $ancestors->[-1]             // return;
    my $pname  = $parent->name;

    # A declaration of the variable is not a use of it.
    return if $op->private & B::OPpLVAL_INTRO;

    my $usage = $self->_usage_of($var);
    if    ( $pname eq 'rv2hv' )    { $usage->{hashref}  = 1 }
    elsif ( $pname eq 'rv2av' )    { $usage->{arrayref} = 1 }
    elsif ( $pname eq 'rv2cv' )    { $usage->{coderef}  = 1 }
    elsif ( $NUMERIC_OPS{$pname} ) { $usage->{numeric}  = 1 }
    elsif ( $STRING_OPS{$pname} )  { $usage->{string}   = 1 }
    return;
}

sub _add_key {
    my ( $self, $var, $key ) = @_;
    return if !defined $var || !defined $key;
    my $usage = $self->_usage_of($var);
    $usage->{keys} //= [];
    push @{ $usage->{keys} }, $key unless any { $_ eq $key } @{ $usage->{keys} };
    return;
}

# $h->{a}[0], $o{size}, exists $o{verbose} and the like, compiled into one op.
sub _on_multideref {
    my ( $self, $op ) = @_;
    my @items   = $op->aux_list( $self->{cv} );
    my $actions = shift @items;
    my $first   = 1;
    my $var;

    while (1) {
        my $action = $actions & B::MDEREF_ACTION_MASK;
        if ( $action == B::MDEREF_reload ) {
            $actions = shift @items;
            next;
        }
        my $is_hash = any { $action == $_ } @HASH_MDEREF_ACTIONS;

        if ( $action == B::MDEREF_AV_padav_aelem || $action == B::MDEREF_HV_padhv_helem ) {
            $var = $self->_padname( shift @items );
        }
        elsif ( $action == B::MDEREF_AV_padsv_vivify_rv2av_aelem || $action == B::MDEREF_HV_padsv_vivify_rv2hv_helem ) {
            $var = $self->_padname( shift @items );
            $self->_usage_of($var)->{ $is_hash ? 'hashref' : 'arrayref' } = 1 if defined $var;
        }
        elsif ($action == B::MDEREF_AV_gvav_aelem
            || $action == B::MDEREF_HV_gvhv_helem
            || $action == B::MDEREF_AV_gvsv_vivify_rv2av_aelem
            || $action == B::MDEREF_HV_gvsv_vivify_rv2hv_helem ) {
            shift @items;
            $var = undef;
        }
        elsif ( !$first ) {

            # A deeper level of a chain that started at $var: it says nothing more about $var itself.
            $var = undef;
        }

        my $index = $actions & B::MDEREF_INDEX_MASK;
        last if $index == B::MDEREF_INDEX_none;
        my $key = shift @items;
        if ( $index == B::MDEREF_INDEX_const ) {
            $self->_add_key( $var, ref $key ? _sv_value($key) : $key ) if $is_hash;
        }

        last if $actions & B::MDEREF_FLAG_last;
        $actions >>= B::MDEREF_SHIFT;
        $first = 0;
    }
    return;
}

# $o{name} or $h->{name} when perl did not fold it into a multideref.
sub _on_helem {
    my ( $self, $op )  = @_;
    my ( $hash, $key ) = _kids($op);
    return unless $hash && $key && $key->name eq 'const';
    my $var;
    if ( $hash->name eq 'padhv' ) {
        $var = $self->_padname( $hash->targ );
    }
    elsif ( $hash->name eq 'rv2hv' ) {
        my ($ref) = _kids($hash);
        $var = $self->_padname( $ref->targ ) if $ref && $ref->name eq 'padsv';
    }
    $self->_add_key( $var, _sv_value( $self->_const_sv($key) ) );
    return;
}

# exists $o{name} or delete $o{name} when perl did not fold it into a multideref:
# the hash element is then a null op that was a helem.
sub _on_exists {
    my ( $self, $op ) = @_;
    my ($elem) = _kids($op);
    return if !$elem;
    return if $elem->name ne q{null} || $elem->targ != $HELEM;
    $self->_on_helem($elem);
    return;
}

sub _call_target {
    my ( $self, $op ) = @_;
    my @args = _significant_kids($op);
    @args = _significant_kids( $args[0] ) if @args == 1 && $args[0]->name eq 'null';
    my $target = pop @args;
    return ( undef, \@args ) if !$target;

    if ( $target->name eq 'method_named' ) {
        my $sv = $target->meth_sv;
        $sv = $self->_padval( $target->targ ) unless $$sv;
        return ( { type => 'method', method => _sv_value($sv) }, \@args );
    }
    if ( $target->name eq 'method' ) {
        return ( { type => 'method', method => undef }, \@args );
    }
    my $cvop = _unwrap($target);
    $cvop = _unwrap( ( _kids($cvop) )[0] ) if $cvop->name eq 'rv2cv' && _kids($cvop);
    if ( $cvop->name eq 'gv' ) {
        return ( { type => 'call', function => _sub_fullname( $self->_gv($cvop) ) }, \@args );
    }
    if ( $cvop->name eq 'padsv' ) {
        return ( { type => 'call', coderef => $self->_padname( $cvop->targ ) }, \@args );
    }
    return ( { type => 'call' }, \@args );
}

sub _on_entersub {
    my ( $self, $op, $ancestors ) = @_;
    my ( $target, $args ) = $self->_call_target($op);
    return if !$target;

    $self->_note_checker( $args, $ancestors ) if ( $target->{function} // q{} ) eq 'Type::Params::compile';
    $self->_note_guard( $target, $args );

    if ( $target->{type} eq 'method' ) {
        $self->_add_method_use( $args->[0], $target->{method} );
        $self->_add_death( $target->{method}, $ancestors ) if $TERMINATING_METHODS{ $target->{method} // q{} };
        return;
    }
    if ( defined $target->{coderef} ) {
        $self->_usage_of( $target->{coderef} )->{coderef} = 1;
        return;
    }
    if ( defined $target->{function} && $TERMINATORS{ $target->{function} } ) {
        $self->_add_death( $target->{function}, $ancestors );
    }
    return;
}

# Records METHOD as called on the variable that INVOCANT reads, when it reads one.
sub _add_method_use {
    my ( $self, $invocant, $method ) = @_;
    return if !$invocant || !defined $method;
    $invocant = _unwrap($invocant);
    return if $invocant->name ne 'padsv';
    my $var = $self->_padname( $invocant->targ ) // return;

    my $usage = $self->_usage_of($var);
    $usage->{methods} //= [];
    push @{ $usage->{methods} }, $method unless any { $_ eq $method } @{ $usage->{methods} };
    return;
}

sub _add_death {
    my ( $self, $via, $ancestors ) = @_;
    push @{ $self->{rec}{dies} }, {
        via    => $via,
        line   => $self->{line},
        caught => _is_caught($ancestors) ? 1 : 0,
    };
    return;
}

# Inside eval {} or the try block of try/catch, but not inside its catch block.
sub _is_caught {
    my ($ancestors) = @_;
    foreach my $ancestor ( reverse @$ancestors ) {
        my $name = $ancestor->name;
        return 1 if $name eq 'leavetry';
        return 0 if $name eq 'catch';
        return 1 if $name eq 'leavetrycatch' || $name eq 'entertrycatch';
    }
    return 0;
}

sub _on_die {
    my ( $self, $op, $ancestors ) = @_;
    $self->_add_death( $op->name, $ancestors );
    return;
}

sub _on_return {
    my ( $self, $op ) = @_;
    my @values = _significant_kids($op);
    my $line   = $self->{line};
    my @evidence;
    if ( !@values ) {
        @evidence = ( { type => 'empty' } );
    }
    elsif ( @values == 1 ) {
        @evidence = $self->classify( $values[0] );
    }
    else {
        my @items;
        foreach my $value (@values) {
            push @items, [ $self->classify($value) ];
        }
        @evidence = ( { type => 'list', count => scalar(@values), items => \@items } );
    }
    push @{ $self->{rec}{returns} }, map { +{ %$_, line => $line, implicit => 0 } } @evidence;
    return;
}

sub _implicit_returns {
    my ( $self, $op ) = @_;
    $op = $op->first if $op->name eq 'leavesub';
    return $self->_last_values($op);
}

sub _classify_refgen {
    my ( $self, $op ) = @_;
    my ($kid) = _significant_kids($op);
    $kid = _unwrap($kid) if $kid;
    my $kname = $kid ? $kid->name : '';
    return { type => 'coderef' }  if $kname eq 'anoncode';
    return { type => 'arrayref' } if $kname eq 'padav' || $kname eq 'rv2av';
    return { type => 'hashref' }  if $kname eq 'padhv' || $kname eq 'rv2hv';
    return { type => 'ref' };
}

sub _classify_bless {
    my ( $self, $op )    = @_;
    my ( undef, $class ) = _significant_kids($op);
    return { type => 'object', class => $self->{rec}{package} } if !$class;
    $class = _unwrap($class);
    return { type => 'object', class => _sv_value( $self->_const_sv($class) ) } if $class->name eq 'const';

    # bless REF, $class  or  bless REF, ref($proto) || $proto: the class comes from a variable.
    my $from = $class->name eq 'or' ? _unwrap( ( _kids($class) )[-1] ) : $class;
    return { type => 'object', class => undef, class_from => $self->_padname( $from->targ ) } if $from->name eq 'padsv';
    return { type => 'object', class => undef };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Coverage::More::Analyzer - Infer arguments, return values and termination of subs from their compiled op trees

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Pod::Coverage::More::Analyzer;

    my $analyzer = Pod::Coverage::More::Analyzer->new();
    my $subs     = $analyzer->analyze_package('Pod::Coverage::More::Analyzer');
    my @params   = map { $_->{name} } @{ $subs->{analyze_sub}{params} };

=head1 DESCRIPTION

Reads the op tree that perl compiled for each sub of a package, by way of L<B>.
This sees the same program that perl runs, so it also covers subs that have no source of their own,
such as closures assigned to globs, constants and accessors that were built with a string eval.

The op tree changes between perl versions.
C<new> returns an object of the subclass for the running perl,
and each subclass adds handlers for the ops of its version set.
This class handles the ops that all supported versions share.
L<B::Deparse> is the reference for how each op of each perl version is meant to be read.

The analysis is best effort.
It reports what the op tree shows, and it marks what it cannot resolve with the type C<unknown>.

=head1 SUPPORTED PERLS

5.36 and later releases.
Development perls (odd minor versions, such as 5.43.x) are not supported:
their ops can change from one development release to the next.

=over 4

=item 5.36 - L<Pod::Coverage::More::Analyzer::Perl5_36>

=item 5.38 to 5.42 - L<Pod::Coverage::More::Analyzer::Perl5_38>

=item 5.44 and later - L<Pod::Coverage::More::Analyzer::Perl5_44>

=back

Each version set inherits from the one before it, and adds or replaces the handlers for the ops that changed.

=head1 METHODS

=head2 analyze_package(package)

The records of the subs that C<package> defines, as C<analyze_sub> returns them. The package must be loaded already.  Subs that it imported from another package are left out.

When a class builder or a signature module declares a sub, as L<Pod::Coverage::More::Declared> reads it, its record also has C<declared>: that declaration, with C<wrapped> in place of its C<body>, and each parameter that a declared one matches has C<declared>, the declared L<Type::Tiny> constraint. The record of a sub that only wraps the code that does the work describes that code.

=over 4

=item package - Str - the name of the package

=back

Returns HashRef, from the name of each sub to its record.

    my $records = $analyzer->analyze_package('Pod::Coverage::More');

=head2 analyze_sub(code, name, package)

The record of what the op tree of C<code> shows, as RECORDS describes it.

=over 4

=item code - CodeRef - the sub

=item name - Str - the name of the sub

=item package - Str - the package that the sub belongs to

=back

Returns HashRef, the record.

    my $record = $analyzer->analyze_sub( \&Pod::Coverage::More::coverage, 'coverage', 'Pod::Coverage::More' );

=head2 backend_for(version)

The subclass that handles the perl C<version>.

=over 4

=item version - Num - in the numeric form of C<$]>

=back

Returns Str, the name of the subclass.

Dies when no subclass handles the version.

    my $backend = Pod::Coverage::More::Analyzer::backend_for($]);

=head2 classify(op)

The evidence that C<op>, an op that produces a value, gives about that value. It is one HASHREF per alternative, because an expression such as C<COND ? A : B> has more than one.

The C<type> of each is one of C<undef>, C<empty>, C<number>, C<string>, C<boolean>, C<hashref>, C<arrayref>, C<coderef>, C<ref>, C<object>, C<variable>, C<call>, C<method>, C<list>, C<context> or C<unknown>.

=over 4

=item op - InstanceOf["B::OP"] - the op that produces the value

=back

Returns HashRef, the evidence, as a list of HASHREFs.

    my @evidence = $self->classify($op);

=head2 finish_sub(record)

Called once the op tree of a sub was walked, before the parameters are sorted. Subclasses override it to add what only the whole tree shows.  The default does nothing.

=over 4

=item record - HashRef - the record of the sub, as RECORDS describes it

=back

Returns nothing.

    $walker->finish_sub( \%record );

=head2 new

An analyzer of the subclass that handles the running perl.

Returns Object, the analyzer, an instance of that subclass.

Dies when the running perl is older than the oldest supported version set.

    my $analyzer = Pod::Coverage::More::Analyzer->new;

=head2 op_classifiers

The methods that C<classify> calls for some ops, ahead of its own rules. Subclasses add the value-producing ops of their version set here, as they add walk handlers in C<op_handlers>. The default has none.

Returns HashRef, from the name of each op to the name of its method.

    my $classifiers = $analyzer->op_classifiers;

=head2 op_handlers

The methods that the walk calls for each op, with the op and the ARRAYREF of its ancestors, nearest last. Subclasses add the ops of their version set to what this returns.

Returns HashRef, from the name of each op to the name of its method.

    my $handlers = $analyzer->op_handlers;

=head2 op_kids(op)

The kids of C<op>, in order, for the handlers of subclasses.

=over 4

=item op - InstanceOf["B::OP"] - the op

=back

Returns the kids, as a list of B::OP objects.

    my @kids = $self->op_kids($op);

=head1 RECORDS

The record of a sub, which C<analyze_sub> returns, is a HASHREF with what the op tree of the sub shows:

=over 4

=item B<name>, B<package> - STRING - the name and the package, as given

=item B<kind> - STRING - C<perl>, C<xs> or C<constant>

=item B<value> - SCALAR - the value of a constant

=item B<file>, B<line> - STRING, INTEGER - where the body starts

=item B<generated> - BOOLEAN - true when the sub has no source file of its own, was installed under a different name,
or was compiled in a file other than the one that PACKAGE was loaded from, as an accessor that a class builder installs

=item B<method> - BOOLEAN - true for a C<method> of the core class feature, whose parameter 0 is the implicit C<$self>

=item B<signature> - BOOLEAN - true when the sub has a signature, even an empty one

=item B<reads_args> - BOOLEAN - true when the body reads C<@_> in any way: a shift of it, an element, or the whole array

=item B<params> - ARRAYREF - one HASHREF per parameter, in order: C<name> (undef when it has none), C<index>, C<source> (C<shift>, C<list>, C<element>, C<signature>, C<invocant>, or C<checked> for a parameter that a call such as C<< $check->(@_) >> returns), C<slurpy>, C<optional>, C<default>, C<keys>,
C<inferred>, the L<Type::Tiny> constraint that the uses of the parameter in the body amount to, or undef,
and C<declared>, a constraint that the code declares for it, with C<declared_by>, what declared it:
a guard such as C<assert_Int($x)> of a L<Type::Library> or a type check that L<Method::Signatures> compiled,
a checker of L<Type::Params>, or the declaration of a class builder or a signature module

=item B<usage> - HASHREF - per lexical variable, how the body uses it: C<hashref>, C<arrayref>, C<coderef>, C<numeric>, C<string>, C<methods> and C<keys>

=item B<returns> - ARRAYREF - one HASHREF per value the sub can return, with C<type>, C<line> and C<implicit>,
C<constraint>, the L<Type::Tiny> constraint that the value satisfies when the evidence says,
C<weak>, true when the value is the result of an operator, which overloading can change, plus details per type

=item B<dies> - ARRAYREF - one HASHREF per explicit termination, with C<via>, C<line> and C<caught>

=back

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Pod::Coverage::More|Pod::Coverage::More>

=item *

L<B>

=item *

L<B::Deparse>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/Pod-Coverage-More/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <teodesian@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2026 George S. Baugh


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
