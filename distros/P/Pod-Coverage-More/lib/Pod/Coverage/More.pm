# ABSTRACT: Make sure your POD covers more ground than just subroutines
# PODNAME: Pod::Coverage::More

package Pod::Coverage::More 0.005;

use 5.036;
use warnings FATAL => q{all};
use re q{/xsaa};

use List::Util      qw{all any none};
use Module::Runtime qw{module_notional_filename require_module};
use mro;
use Package::Stash;
use Pod::Find       qw(pod_where);
use Types::Standard qw{Any ArrayRef CodeRef GlobRef HashRef ScalarRef Str};

use parent 'Pod::Coverage::TrustPod';

use Pod::Coverage::More::Analyzer;
use Pod::Coverage::More::Documentation;

# Set to print what the parse and the coverage found, for debugging.
our $TRACE_ALL = 0;


our @CHECKS = qw{arguments argument_types returns termination examples};

# The fraction of the public subs that the POD documents, as L<Pod::Coverage> rates it,
# from the headings that L<Pod::Coverage::More::Documentation> reads.
# Nothing when the package has no POD or no public subs, and C<why_unrated> says why.
# @returns Num  from 0 to 1
# @example my $rating = $pc->coverage;
sub coverage {
    my $self = shift;

    my $package = $self->{package};
    my $doc     = $self->_documentation;
    _trace_dump($doc);
    return unless $doc;

    my %symbols = map { $_ => 0 } $self->_get_syms($package);

    if ( !%symbols && $self->{why_unrated} ) {

        # _get_syms failed violently
        return;
    }

    print "tying shoelaces\n" if $TRACE_ALL;
    foreach my $documentation ( $self->_documentations ) {
        foreach my $pod ( $documentation->identifiers ) {
            $symbols{$pod} = 1 if exists $symbols{$pod};
        }
    }
    foreach my $sym ( keys %symbols ) {
        $symbols{$sym} = 1 if $self->_trustme_check($sym);
    }

    # stash the results for later
    $self->{symbols} = \%symbols;
    _trace_dump($self);

    my $symbols    = scalar keys %symbols;
    my $documented = scalar grep { $_ } values %symbols;
    unless ($symbols) {
        $self->{why_unrated} = "no public symbols defined";
        return;
    }
    return $documented / $symbols;
}


# The failures of each check, for each public sub that has a section in the POD:
# a HASHREF from the name of the sub to a HASHREF with C<section>, the section that C<section_for> returns,
# C<inherited>, true when that section is in the POD of a parent class, and C<failures>,
# a HASHREF from the name of each check in THE CHECKS to an ARRAYREF of the messages of its failures, empty when it passes.
# The report is made once.  Nothing when there is no POD to rate, and C<why_unrated> says why.
# @returns HashRef  the report
# @example my $failures = $pc->coverage_report->{resize}{failures}{examples};
sub coverage_report {
    my $self = shift;
    return $self->{report} if $self->{report};
    return                 if !$self->_documentation;
    my $analysis = $self->analysis;

    my %report;
    foreach my $name ( sort $self->_get_syms( $self->{package} ) ) {
        my $section   = $self->section_for($name) or next;
        my $rec       = $analysis->{$name}        or next;
        my $inherited = $self->_documentation->section_for($name) ? 0 : 1;
        my %failures;
        foreach my $check (@CHECKS) {
            my $method = "_check_$check";
            $failures{$check} = [ $self->$method( $name, $section, $rec, $inherited ) ];
        }
        $report{$name} = { section => $section, inherited => $inherited, failures => \%failures };
    }
    return $self->{report} = \%report;
}

# The result of the B<arguments> check over every sub: a HASHREF with C<status>, true when it passes,
# and C<message>, the messages of its failures, one per line, or undef.
# @returns HashRef  with status and message
# @example my $result = $pc->coverage_arguments;
# @example print $result->{message} if !$result->{status};
sub coverage_arguments { my ($self) = @_; return $self->_check_result('arguments') }

# The result of the B<argument_types> check, as C<coverage_arguments> returns it for its check.
# @returns HashRef  with status and message
# @example my $result = $pc->coverage_argument_types;
sub coverage_argument_types { my ($self) = @_; return $self->_check_result('argument_types') }

# The result of the B<returns> check, as C<coverage_arguments> returns it for its check.
# @returns HashRef  with status and message
# @example my $result = $pc->coverage_return_types;
sub coverage_return_types { my ($self) = @_; return $self->_check_result('returns') }

# The result of the B<termination> check, as C<coverage_arguments> returns it for its check.
# @returns HashRef  with status and message
# @example my $result = $pc->coverage_termination;
sub coverage_termination { my ($self) = @_; return $self->_check_result('termination') }

# The result of the B<examples> check, as C<coverage_arguments> returns it for its check.
# @returns HashRef  with status and message
# @example my $result = $pc->coverage_examples;
sub coverage_examples { my ($self) = @_; return $self->_check_result('examples') }

sub _check_result {
    my ( $self, $check ) = @_;
    my $report = $self->coverage_report or return { status => 0, message => ( $self->{why_unrated} // 'no POD' ) . "\n" };
    my @failures;
    foreach my $name ( sort keys %$report ) {
        push @failures, @{ $report->{$name}{failures}{$check} };
    }
    return { status => @failures ? 0 : 1, message => @failures ? join( q{}, map { "$_\n" } @failures ) : undef };
}

# The names that a POD argument can match: the parameters, the keys of named arguments, and the declared parameters.
sub _accepted_names {
    my ($rec) = @_;
    my @names;
    foreach my $param ( @{ $rec->{params} } ) {
        push @names, $param->{name} if defined $param->{name};
    }
    push @names, _named_keys($rec);
    foreach my $param ( @{ $rec->{declared}{params} || [] } ) {
        push @names, $param->{name}  if defined $param->{name};
        push @names, $param->{named} if defined $param->{named};
    }
    return _bare_names(@names);
}

# The keys of the hashes of named arguments of a sub.
sub _named_keys {
    my ($rec) = @_;
    my @keys;
    foreach my $param ( @{ $rec->{params} } ) {
        push @keys, @{ $param->{keys} || [] } if !_is_invocant( $rec, $param );
    }
    return @keys;
}

# The arguments in ARGS, the list of the POD, that stand at the position of a parameter with no name,
# such as a placeholder in a signature, which the POD may call anything, or at or after a slurpy one with no name.
sub _at_unnamed_params {
    my ( $rec, @args ) = @_;
    my ( @params, %invocants );
    foreach my $param ( sort { $a->{index} <=> $b->{index} } @{ $rec->{params} } ) {
        if ( _is_invocant( $rec, $param ) ) {
            $invocants{ Pod::Coverage::More::Documentation->bare_name( $param->{name} ) } = 1 if defined $param->{name};
            next;
        }
        push @params, $param;
    }
    my @listed;
    foreach my $arg (@args) {
        push @listed, $arg if !$invocants{ Pod::Coverage::More::Documentation->bare_name($arg) };
    }

    # A slurpy parameter takes every argument from its position on, so an argument beyond it stands at it.
    my @unnamed;
    foreach my $at ( 0 .. $#listed ) {
        my $param = $at <= $#params ? $params[$at] : $params[-1];
        next if !$param || ( $at > $#params && !$param->{slurpy} );
        push @unnamed, $listed[$at] if !defined $param->{name};
    }
    return @unnamed;
}

# The arguments in ARGS, the list of the POD, that the sub takes, by name or at the position of a parameter with no name.
sub _taken {
    my ( $rec, @args ) = @_;
    my %taken   = map { $_ => 1 } _accepted_names($rec);
    my %unnamed = map { $_ => 1 } _at_unnamed_params( $rec, @args );
    my @taken;
    foreach my $arg (@args) {
        push @taken, $arg if $unnamed{$arg} || $taken{ Pod::Coverage::More::Documentation->bare_name($arg) };
    }
    return @taken;
}

# Whether PARAM is the object or class that a method is called on, whose keys are its fields and not named arguments.
sub _is_invocant {
    my ( $rec, $param ) = @_;
    return 1 if $param->{source} eq 'invocant';
    my $name = $param->{name} // return 0;
    return 1 if $name =~ m/\A\$(?:self|class|proto)\z/;
    return @{ $rec->{usage}{$name}{methods} || [] } ? 1 : 0;
}

# Whether the code of a sub shows nothing of its arguments: an XS sub or a constant, or a stub with no signature
# that reads nothing of @_, as a default that subclasses override.  Its POD names its arguments on the author's word.
sub _is_stub {
    my ($rec) = @_;
    return 1 if $rec->{kind} ne 'perl';
    return 0 if $rec->{signature} || $rec->{reads_args} || @{ $rec->{params} } || @{ $rec->{declared}{params} || [] };
    return 1;
}

# Whether a sub is an abstract method: it takes at most its invocant and never returns, as a default that dies
# for a subclass that does not override it.  Its POD documents the interface of the overrides.
sub _is_abstract {
    my ($rec) = @_;
    return 0 if !$rec->{never_returns} || @{ $rec->{declared}{params} || [] };
    my @params = @{ $rec->{params} };
    return 0 if @params > 1;
    return 1 if !@params;
    return $params[0]{index} == 0 && ( !defined $params[0]{name} || _is_invocant( $rec, $params[0] ) ) ? 1 : 0;
}

sub _check_arguments {
    my ( $self, $name, $section, $rec, $inherited ) = @_;
    return if _is_stub($rec) || _is_abstract($rec) || $inherited;
    my $args     = $section->{args}{$name} or return;
    my @accepted = _accepted_names($rec);
    my %unnamed  = map { $_ => 1 } _at_unnamed_params( $rec, @$args );
    my @failures;
    foreach my $arg ( _bare_names( grep { !$unnamed{$_} } @$args ) ) {
        push @failures, "Var Mismatch for function $name: $arg not in @accepted" if none { $_ eq $arg } @accepted;
    }
    return @failures;
}

our %SIGIL_TYPES = ( '$' => 'scalar', '@' => 'array', '%' => 'hash' );

sub _check_argument_types {
    my ( $self, $name, $section, $rec, $inherited ) = @_;
    return if _is_stub($rec) || _is_abstract($rec);
    my $args = $section->{args}{$name} or return;
    $args = [ _taken( $rec, @$args ) ] if $inherited;
    my @params = grep { defined } map { $_->{name} } @{ $rec->{params} };

    # Strategy 1: the POD wrote each argument with its sigil, so it must match the sigil of the parameter, in any case.
    # A key of the named arguments, as the heading writes it in key => value, has no sigil to match.
    if ( any { m/\A[\$*\\@%&|]/ } @$args ) {
        my %unnamed = map { $_ => 1 } _at_unnamed_params( $rec, @$args );
        my %keys    = map { $_ => 1 } _named_keys($rec);
        my @failures;
        foreach my $arg ( map { s/\A\\[\$*@%&|]/\$/r } grep { !$unnamed{$_} && !$keys{$_} } @$args ) {
            push @failures, "Var Type Mismatch for function $name: $arg not in @params" if none { lc($_) eq lc($arg) } @params;
        }
        return @failures;
    }

    # Strategy 2: the type of each argument is in an =item of its section.
    my $types = $section->{types}{$name} || {};
    my @failures;
    foreach my $arg (@$args) {
        push @failures, "Var $arg not documented whatsoever for $name!" if !$types->{ Pod::Coverage::More::Documentation->bare_name($arg) };
    }
    foreach my $param ( @{ $rec->{params} } ) {
        next if !defined $param->{name};
        my ( $sigil, $arg_name ) = $param->{name} =~ m/\A(.)(.+)\z/ or next;
        my $documented = $types->{ lc $arg_name } or next;
        push @failures, _type_failures( $name, $arg_name, $SIGIL_TYPES{$sigil}, $documented, $param );
    }
    return @failures;
}

# The failures of the documented type of one parameter: against its sigil, its declared type, and its uses.
sub _type_failures {
    my ( $name, $arg_name, $sigil_type, $documented, $param ) = @_;
    my $word = $documented->{word};
    return "No type declared for arg $arg_name of $name" if $word eq q{};
    return                                               if $word eq 'mixed';

    # An item with the sigil of a list documents the type of each element, which the code shows nothing of.
    if ( my $elements = $documented->{sigil} ) {
        return if defined $sigil_type && $SIGIL_TYPES{$elements} eq $sigil_type;
        return "Type mismatch for arg $arg_name of $name: documented the elements of $elements$arg_name, expected " . ( $sigil_type // 'a parameter with a sigil' );
    }

    # A word for a container names the kind of the parameter itself, and only a container parameter is one.
    if ( defined $sigil_type && $word ne $sigil_type && ( $word eq 'array' || $word eq 'hash' || $sigil_type ne 'scalar' ) ) {
        return "Type mismatch for arg $arg_name of $name: got $word, expected $sigil_type";
    }

    my $type = $documented->{type} or return;
    if ( my $declared = $param->{declared} ) {
        return if $type->equals($declared) || $type->is_subtype_of($declared);
        return "Type mismatch for arg $arg_name of $name: documented " . $type->display_name . ", but $param->{declared_by} declares " . $declared->display_name;
    }
    if ( my $inferred = $param->{inferred} ) {
        return "Type mismatch for arg $arg_name of $name: documented " . $type->display_name . ', but the code uses it as ' . $inferred->display_name
          if _contradicts( $type, $inferred );
    }
    return;
}

# The kinds of value that no type of another kind can be.
our @KINDS = ( HashRef, ArrayRef, CodeRef, ScalarRef, GlobRef, Str );

sub _kinds_of {
    my ($type) = @_;
    my @members = $type->can('type_constraints') ? @{ $type->type_constraints } : ($type);
    my %kinds;
    foreach my $member (@members) {
        foreach my $kind (@KINDS) {
            $kinds{ $kind->name } = 1 if $member->is_a_type_of($kind);
        }
    }
    return \%kinds;
}

# Whether a documented type and a type that the code implies are of different kinds, as a hash reference and an array reference.
sub _contradicts {
    my ( $documented, $inferred ) = @_;
    my $documented_kinds = _kinds_of($documented);
    my $inferred_kinds   = _kinds_of($inferred);
    return 0 if !%$documented_kinds || !%$inferred_kinds;
    return ( none { $inferred_kinds->{$_} } keys %$documented_kinds ) ? 1 : 0;
}

sub _check_returns {
    my ( $self, $name, $section, $rec ) = @_;
    my @returned = grep { $_->{type} ne 'empty' } @{ $rec->{returns} };
    my @declared = @{ $rec->{declared}{returns} || [] };
    return if !@returned && !@declared;

    my @statements = @{ $section->{returns} };
    return "No return value documented for $name" if !@statements;
    my @documented = map { @{ $_->{types} } } @statements;
    if ( !@documented ) {
        return if !_all_nothing(@statements);

        # What a call returns is not in this code, and may be nothing, so only another value contradicts the POD.
        return if !@declared && all { $_->{type} eq 'call' || $_->{type} eq 'method' } @returned;
        return "$name is documented to return nothing, but it returns a value";
    }

    my @failures;
    my %seen;
    my @checked = ( ( map { [ $_->{constraint}, "line $_->{line}", $_->{weak}, $_ ] } grep { $_->{constraint} } @returned ), ( map { [ $_, 'declared', 0 ] } @declared ) );
    foreach my $returned (@checked) {
        my ( $type, $where, $weak, $evidence ) = @$returned;
        next if _covered( $type, \@documented );

        # A literal is one value, which can satisfy a type that its own type is no subtype of, as 1 satisfies Bool.
        next if $evidence && exists $evidence->{value} && _value_covered( $evidence->{value}, \@documented );

        # The code shows the kind of what it returns, as [ ... ] is an ArrayRef, but not what is inside it.
        next if $evidence && !exists $evidence->{value} && _parameterizes( $type, \@documented );

        # The type of the result of an operator is weak: overloading can change it, so it fails only when it contradicts.
        next if $weak && any { !_contradicts( $_, $type ) } @documented;
        next if $seen{ $type->display_name }++;
        push @failures, "Return type mismatch for $name: returns " . $type->display_name . " ($where), documented as " . join( ' or ', _names_of( \@documented ) );
    }
    return @failures;
}

# Whether the statements of the return value only say that it returns nothing.
sub _all_nothing {
    my (@statements) = @_;
    return ( any { $_->{nothing} } @statements ) && ( none { @{ $_->{types} } } @statements );
}

sub _value_covered {
    my ( $value, $documented ) = @_;
    foreach my $candidate (@$documented) {
        return 1 if $candidate->check($value);
    }
    return 0;
}

sub _covered {
    my ( $type, $documented ) = @_;
    foreach my $candidate (@$documented) {
        return 1 if $candidate->equals(Any) || $type->equals($candidate) || $type->is_subtype_of($candidate);
    }
    return 0;
}

# Whether a documented type is a parameterization of TYPE, as ArrayRef[HashRef] is of ArrayRef.
sub _parameterizes {
    my ( $type, $documented ) = @_;
    foreach my $candidate (@$documented) {
        return 1 if $candidate->is_parameterized && $candidate->parameterized_from->equals($type);
    }
    return 0;
}

# The names of NAMES without sigils, in lower case, as the POD and the code are compared.
sub _bare_names {
    my (@names) = @_;
    my @bare;
    foreach my $name (@names) {
        push @bare, Pod::Coverage::More::Documentation->bare_name($name);
    }
    return @bare;
}

# The display names of the constraints in the ARRAYREF TYPES.
sub _names_of {
    my ($types) = @_;
    my @names;
    foreach my $type (@$types) {
        push @names, $type->display_name;
    }
    return @names;
}

sub _check_termination {
    my ( $self, $name, $section, $rec ) = @_;
    my @uncaught = grep { !$_->{caught} } @{ $rec->{dies} };
    return if !@uncaught || @{ $section->{terminations} };
    return "$name can terminate ($uncaught[0]{via} at line $uncaught[0]{line}), but its POD does not say so";
}

sub _check_examples {
    my ( $self, $name, $section ) = @_;
    my @failures;
    if ( $section->{assigns} ) {
        my $args = $section->{args}{$name};
        my $head = $name . ( $args ? '(' . join( ', ', @$args ) . ')' : q{} );
        push @failures, "The heading of $name is an example: move `$section->{heading}` into a verbatim block, and head the section $head";
    }
    push @failures, "No example of $name in its POD" if none { m/\b\Q$name\E\s*\(|->\s*\Q$name\E\b/ } @{ $section->{verbatim} };
    return @failures;
}

sub _trace_dump {
    my ($data) = @_;
    return if !$TRACE_ALL;
    require Data::Dumper;
    print Data::Dumper::Dumper($data);
    return;
}

sub _documentation {
    my $self = shift;
    return $self->{documentation} if $self->{documentation};

    my $package = $self->{package};
    print "getting pod location for '$package'\n" if $TRACE_ALL;
    $self->{pod_from} ||= pod_where( { -inc => 1 }, $package ) // $INC{ module_notional_filename($package) };
    my $pod_from = $self->{pod_from};
    unless ($pod_from) {
        $self->{why_unrated} = "couldn't find pod";
        return;
    }

    # The headings name subs only once the package is loaded, so load it before reading its symbols.
    if ( !eval { require_module($package); 1 } ) {
        $self->{why_unrated} = "requiring '$package' failed";
        return;
    }

    print "parsing '$pod_from'\n" if $TRACE_ALL;
    my @subs = Package::Stash->new($package)->list_all_symbols('CODE');
    return $self->{documentation} = Pod::Coverage::More::Documentation->new( subs => \@subs )->parse_file($pod_from);
}

# The documentation of the package, then of each of its parent classes, as Pod::Coverage::CountParents reads them.
sub _documentations {
    my $self = shift;
    return @{ $self->{documentations} } if $self->{documentations};
    my $own            = $self->_documentation or return;
    my @documentations = ($own);
    foreach my $parent ( @{ mro::get_linear_isa( $self->{package} ) } ) {
        next if $parent eq $self->{package};
        my $file = pod_where( { -inc => 1 }, $parent ) or next;
        my @subs = Package::Stash->new($parent)->list_all_symbols('CODE');
        push @documentations, Pod::Coverage::More::Documentation->new( subs => \@subs )->parse_file($file);
    }
    $self->{documentations} = \@documentations;
    return @documentations;
}

# The section that documents the sub C<name>, as C<section_for> of L<Pod::Coverage::More::Documentation> returns it:
# the section in the POD of the package, or else in that of the nearest parent class that documents it.
# Nothing when no POD documents it.
# @param   name  Str  the name of the sub
# @returns HashRef  the section
# @example my $section = $pc->section_for('coverage');
sub section_for {
    my ( $self, $name ) = @_;
    foreach my $documentation ( $self->_documentations ) {
        my $section = $documentation->section_for($name);
        return $section if $section;
    }
    return;
}

# The section that documents the sub C<name> in the POD of the package itself, not of a parent class.
# Nothing when the POD of the package does not document it.
# @param   name  Str  the name of the sub
# @returns HashRef  the section
# @example my $section = $pc->own_section_for('coverage');
sub own_section_for {
    my ( $self, $name ) = @_;
    my $documentation = $self->_documentation or return;
    return $documentation->section_for($name);
}

# The analysis of every sub of the package, as C<analyze_package> of L<Pod::Coverage::More::Analyzer> returns it.
# The package is analyzed once.
# @returns HashRef  from the name of each sub to the record of its analysis
# @example my $records = $pc->analysis;
sub analysis {
    my ($self) = @_;
    return $self->{analysis} //= Pod::Coverage::More::Analyzer->new->analyze_package( $self->{package} );
}

# The public subs of the package, as L<Pod::Coverage> counts them: not private, not imported, and not trusted.
# @returns the names of the subs, as a list
# @example my @names = $pc->public_subs;
sub public_subs {
    my ($self) = @_;
    my @public;
    foreach my $name ( $self->_get_syms( $self->{package} ) ) {
        push @public, $name if !$self->_trustme_check($name);
    }
    return @public;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Coverage::More - Make sure your POD covers more ground than just subroutines

=head1 VERSION

version 0.005

=head1 SYNOPSIS

   use Pod::Coverage::More;

   my $pc     = Pod::Coverage::More->new( package => 'Pod::Coverage::More' );
   my $report = $pc->coverage_report;
   my $acov   = $pc->coverage_arguments;
   print $acov->{message} if !$acov->{status};

=head1 DESCRIPTION

Extends L<Pod::Coverage>, which makes sure that the POD names each public sub of a module,
to make sure that the POD also says what each sub takes, returns, and how it fails.
It compares what L<Pod::Coverage::More::Documentation> reads from the POD
with what L<Pod::Coverage::More::Analyzer> reads from the compiled subs,
and the types that they name as L<Type::Tiny> constraints.

It counts a sub as documented when a C<=for Pod::Coverage> line or a C<=begin Pod::Coverage> block names it,
as L<Pod::Coverage::TrustPod>, its parent class, counts it, and then does not check it.

L<Test::Pod::Coverage::More> runs these checks as tests.

=head1 WRITING THE POD

A heading names the subs that its section documents, each with an optional argument list,
and an C<=item> per argument gives its type.  L<Pod::Coverage::More::Documentation> describes the forms in full.

    =head2 resize($width, $height)

    =over 4

    =item width - Int - in pixels

    =item height - Int - in pixels

    =back

    Returns a Image object.  Dies when either size is not positive.

        my $smaller = $image->resize( 100, 50 );

For several functions on one line, separate them with commas or spaces; for arguments, use commas.
A heading of prose, such as C<=head2 The token cache>, names no sub, even when one of its words is the name of one.
A heading can call the sub on an object or a class, as C<< =head2 $image->resize($width, $height) >>,
but a heading that assigns the call, as C<< =head2 $smaller = $image->resize($width, $height) >>, is an example,
which belongs in a verbatim block of the section, and fails B<examples>.
An argument list can give the sigils of the arguments, as C<($foo, @bar, \%baz)>.
Then the sigils are compared with those of the parameters, and no C<=item> is needed.

=head1 THE CHECKS

Each check applies to the public subs that have a section in the POD.
A sub without one is the business of C<coverage>.
The code of a stub, a sub with no signature that reads nothing of C<@_>, such as a default that subclasses override,
shows nothing of its arguments, and neither does an XS sub; so the argument checks take their POD on the author's word.
So do they for an abstract method, a sub that takes at most its invocant and never returns, as one that dies
for a subclass that does not override it, directly or through a helper: its POD documents the interface that the overrides implement.
A sub with a signature, even an empty one, declares its arguments, and they are checked.
A sub that a parent class documents counts as documented, as L<Pod::Coverage::CountParents> counts it,
and the checks compare its own code with the section of the parent.
That section documents the interface that callers use, and an override may ignore arguments that they pass,
so an argument of the section that the override does not take is no failure of B<arguments> or B<argument_types>.

=over 4

=item B<arguments> - each argument that the POD names is a parameter of the sub: a variable assigned from C<@_>,
a parameter of a signature, a key of a hash of named arguments, or a parameter that a class builder or a signature module declares.
A parameter with no name, such as the placeholder C<$> in C<sub check ($self, $)>
or the C<undef> in C<my ($self, undef) = @_>, takes whatever name the POD gives the argument at its position.
A slurpy parameter with no name, as the C<@> in C<sub capture ($self, @)>, takes every argument from its position on, whatever their names.
An argument beyond the parameters of the sub still fails.

=item B<argument_types> - each argument has a documented type that agrees with the code.  A documented type must be the type that
the code declares or a narrower one, so that the POD never promises that the sub takes what it refuses.
A type that the code only implies by its use of the argument fails only when it contradicts the documented one,
as a hash reference where the code uses an array reference.
The type of a list parameter, such as C<@paths>, is C<ARRAY> or C<HASH>, or else an item that keeps the sigil,
as C<=item @paths - Str>, gives the type of each element.

=item B<returns> - a sub that returns a value says so with a C<Returns> paragraph or an C<=item Returns>,
and the documented types cover every type that the code returns or declares.
A sub whose POD says that it returns nothing may return the value of a call, such as C<< $self->SUPER::update(@_) >>,
because what the call returns is not in its code; any other value that it returns fails.
A documented parameterization of a type that the code returns, such as C<ArrayRef[HashRef]> for C<[ map { {...} } @list ]>,
covers it, because the code shows the kind of the value and not what is inside it.
The type of the result of an operator, such as C<$x * 2>, is only probable, because an operand of a class that overloads the operator
makes the result an object of that class, as L<Math::GMP> does; so such a type fails only when it is of another kind than every documented one

=item B<termination> - a sub that can die, croak, confess, throw or exit, outside an C<eval> or C<try>, says so

=item B<examples> - the section has a verbatim paragraph that calls the sub, by C<name(> or C<< ->name >>,
and its heading does not assign the call to a variable, which makes the heading an example

=back

=head1 METHODS

The other methods of L<Pod::Coverage>, such as C<naked>, C<covered> and C<why_unrated>, work as they do there.

=head2 analysis

The analysis of every sub of the package, as C<analyze_package> of L<Pod::Coverage::More::Analyzer> returns it. The package is analyzed once.

Returns HashRef, from the name of each sub to the record of its analysis.

    my $records = $pc->analysis;

=head2 coverage

The fraction of the public subs that the POD documents, as L<Pod::Coverage> rates it, from the headings that L<Pod::Coverage::More::Documentation> reads. Nothing when the package has no POD or no public subs, and C<why_unrated> says why.

Returns Num, from 0 to 1.

    my $rating = $pc->coverage;

=head2 coverage_argument_types

The result of the B<argument_types> check, as C<coverage_arguments> returns it for its check.

Returns HashRef, with status and message.

    my $result = $pc->coverage_argument_types;

=head2 coverage_arguments

The result of the B<arguments> check over every sub: a HASHREF with C<status>, true when it passes, and C<message>, the messages of its failures, one per line, or undef.

Returns HashRef, with status and message.

    my $result = $pc->coverage_arguments;
    print $result->{message} if !$result->{status};

=head2 coverage_examples

The result of the B<examples> check, as C<coverage_arguments> returns it for its check.

Returns HashRef, with status and message.

    my $result = $pc->coverage_examples;

=head2 coverage_report

The failures of each check, for each public sub that has a section in the POD: a HASHREF from the name of the sub to a HASHREF with C<section>, the section that C<section_for> returns, C<inherited>, true when that section is in the POD of a parent class, and C<failures>, a HASHREF from the name of each check in THE CHECKS to an ARRAYREF of the messages of its failures, empty when it passes. The report is made once.  Nothing when there is no POD to rate, and C<why_unrated> says why.

Returns HashRef, the report.

    my $failures = $pc->coverage_report->{resize}{failures}{examples};

=head2 coverage_return_types

The result of the B<returns> check, as C<coverage_arguments> returns it for its check.

Returns HashRef, with status and message.

    my $result = $pc->coverage_return_types;

=head2 coverage_termination

The result of the B<termination> check, as C<coverage_arguments> returns it for its check.

Returns HashRef, with status and message.

    my $result = $pc->coverage_termination;

=head2 own_section_for(name)

The section that documents the sub C<name> in the POD of the package itself, not of a parent class. Nothing when the POD of the package does not document it.

=over 4

=item name - Str - the name of the sub

=back

Returns HashRef, the section.

    my $section = $pc->own_section_for('coverage');

=head2 public_subs

The public subs of the package, as L<Pod::Coverage> counts them: not private, not imported, and not trusted.

Returns the names of the subs, as a list.

    my @names = $pc->public_subs;

=head2 section_for(name)

The section that documents the sub C<name>, as C<section_for> of L<Pod::Coverage::More::Documentation> returns it: the section in the POD of the package, or else in that of the nearest parent class that documents it. Nothing when no POD documents it.

=over 4

=item name - Str - the name of the sub

=back

Returns HashRef, the section.

    my $section = $pc->section_for('coverage');

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Pod::Coverage>

=item *

L<Pod::Coverage::More::Documentation>

=item *

L<Pod::Coverage::More::Analyzer>

=item *

L<Test::Pod::Coverage::More>

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

=head1 CONTRIBUTOR

=for stopwords troglodyne-robot

troglodyne-robot <trogbot@troglodyne.net>

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
