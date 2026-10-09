package Perl::Critic::Policy::ProhibitUnusedDefinitions;
$Perl::Critic::Policy::ProhibitUnusedDefinitions::VERSION = '0.005';
# ABSTRACT: A sub nobody calls, or a global nobody reads, is code nobody needs.

use 5.014;

use strict;
use warnings FATAL => 'all';

use re '/aa';

use Readonly;

use Digest::SHA  ();
use PPI          ();
use Scalar::Util ();

use Perl::Critic::Distribution ();
use Perl::Critic::Utils        qw{ :severities :classification };
use parent                     qw{Perl::Critic::Policy};


Readonly::Scalar my $EXPL => q{Delete it, or it goes on being read, tested and maintained for nothing};

Readonly::Hash my %DESC_FOR => (
    sub      => q{Sub %s is never called from bin/ or lib/},
    constant => q{Constant %s is never used in bin/, lib/, t/ or xt/},
    global   => q{Global %s is never used in bin/, lib/, t/ or xt/},
);

Readonly::Scalar my $DEFAULT_ALLOW_SUBS => join ' ', qw{
  BEGIN END INIT CHECK UNITCHECK AUTOLOAD DESTROY import unimport CLONE CLONE_SKIP
  BUILD BUILDARGS DEMOLISH FOREIGNBUILDARGS
  TIESCALAR TIEARRAY TIEHASH TIEHANDLE FETCH STORE FETCHSIZE STORESIZE EXTEND
  EXISTS DELETE CLEAR PUSH POP SHIFT UNSHIFT SPLICE FIRSTKEY NEXTKEY SCALAR UNTIE
  PRINT PRINTF WRITE READ READLINE GETC CLOSE OPEN BINMODE EOF FILENO SEEK TELL
};

Readonly::Scalar my $DEFAULT_ALLOW_GLOBALS => join ' ', qw{
  $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD
};

# Where a use counts from.  A call from a test does not make a sub needed; a
# test reading a global does make the global needed.
Readonly::Hash my %AREA_OF => ( bin => 'code', lib => 'code', t => 'test', xt => 'test' );
Readonly::Hash my %AREAS_FOR => ( sub => [qw{code}], constant => [qw{code test}], global => [qw{code test}] );

Readonly::Array my @DIST_MARKERS => qw{ dist.ini Makefile.PL Build.PL META.json META.yml cpanfile .git };

Readonly::Array my @INTERPOLATING => qw{
  PPI::Token::Quote::Double
  PPI::Token::Quote::Interpolate
  PPI::Token::QuoteLike::Backtick
  PPI::Token::QuoteLike::Command
  PPI::Token::QuoteLike::Readline
  PPI::Token::QuoteLike::Regexp
  PPI::Token::Regexp
  PPI::Token::HereDoc
};

# A variable inside a string, and what follows it: "$x[0]" is a use of @x.
Readonly::Scalar my $INTERPOLATED_RX => qr/ (?<! \\ ) ([\$\@]) \{? (\w+ (?: ::\w+ )*) \}? ([\[\{])? /x;

# Code inside a string: "@{[ $obj->name ]}" and "${\ $obj->name }", braces and
# all.  Only those two forms, because "${name}" and "@{name}" are variables.
Readonly::Scalar my $INTERPOLATED_CODE_RX => qr/
    (?<! \\ ) (?: \@ \{ (?= \s* \[ ) | \$ \{ (?= \s* \\ ) )
    ( (?: [^{}]++ | (?<braces> \{ (?: [^{}]++ | (?&braces) )* \} ) )* )
    \}
/x;

# One index per distribution root, for the life of the process.  Per process
# rather than per policy object, so a harness that builds a new Perl::Critic
# for every file still resolves the distribution once.  our, so that a test
# can empty it and read the cache on disk as a new process does.
our %INDEX_FOR;

# Change it when what _parse returns, or what the stash holds, changes shape.
Readonly::Scalar my $DATA_FORMAT => 4;


sub supported_parameters {
    return (
        {
            name           => 'allow_subs',
            description    => 'Subs and constants that are never reported, in addition to the built-in list.',
            default_string => $DEFAULT_ALLOW_SUBS,
            behavior       => 'string list',
        },
        {
            name           => 'allow_globals',
            description    => 'Globals, with their sigil, that are never reported, in addition to the built-in list.',
            default_string => $DEFAULT_ALLOW_GLOBALS,
            behavior       => 'string list',
        },
        {
            name           => 'cache',
            description    => 'Keep the index of each distribution on disk between runs.',
            default_string => '1',
            behavior       => 'boolean',
        },
        {
            name           => 'cache_dir',
            description    => 'Where the index is kept.  Empty means the default of Perl::Critic::Distribution.',
            default_string => q{},
            behavior       => 'string',
        },
    );
}

sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    # 'string list' hands us the configured value in place of the default, and
    # somebody naming one plugin hook of their own did not mean to start
    # reporting DESTROY.
    $self->{_allow_subs}{$_}    = 1 for split m/\s+/, $DEFAULT_ALLOW_SUBS;
    $self->{_allow_globals}{$_} = 1 for split m/\s+/, $DEFAULT_ALLOW_GLOBALS;

    # Through a closure, so that a test that replaces _parse is seen.
    Perl::Critic::Distribution->register(
        name    => __PACKAGE__,
        version => join( q{/}, $DATA_FORMAT, Perl::Critic::Distribution->stamp(__FILE__) // q{} ),
        collect => sub { return _parse(@_) },
    );

    return $self->SUPER::initialize_if_enabled($config);
}

sub default_severity { return $SEVERITY_LOW }
sub default_themes   { return qw(maintenance) }
sub applies_to       { return qw(PPI::Statement::Sub PPI::Statement::Variable PPI::Statement::Include) }


sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $definitions = $self->_definitions_in($doc)                            or return;
    my $defined     = $definitions->{by_elem}{ Scalar::Util::refaddr($elem) } or return;

    my $index = $INDEX_FOR{ $definitions->{root} } //= _build_index( $definitions->{dist} );

    return map { $self->violation( sprintf( $DESC_FOR{ $_->[0] }, $_->[1] ), $EXPL, $elem ) }
      grep { !$self->_is_needed( $index, @$_ ) } @$defined;
}

# What each statement in this document defines, keyed by the statement.  Kept
# for the document most recently asked about, since violates() is called once
# per statement and the walk is over the whole file.
sub _definitions_in {
    my ( $self, $doc ) = @_;

    my $last = $self->{_last};
    return $last->{definitions} if $last && Scalar::Util::refaddr( $last->{doc} ) == Scalar::Util::refaddr($doc);

    # Only a file in bin/ or lib/ is checked.
    my $definitions;
    my ( undef, $area ) = Perl::Critic::Distribution->root_of( $doc->filename() );
    if ( $area && $AREA_OF{$area} eq 'code' && ( my $dist = $self->_distribution( $doc->filename() ) ) ) {
        my %by_elem;
        foreach my $def ( @{ _walk_document( $doc->ppi_document() )->{defs} } ) {
            my ( $elem, @kind_and_key ) = @$def;
            push @{ $by_elem{ Scalar::Util::refaddr($elem) } }, \@kind_and_key;
        }
        $definitions = { root => $dist->root(), dist => $dist, by_elem => \%by_elem };
    }

    # The document is held, not just its address, so the address cannot be
    # handed to the next document while we still think we know what is in it.
    $self->{_last} = { doc => $doc, definitions => $definitions };
    return $definitions;
}

sub _is_needed {
    my ( $self, $index, $kind, $key ) = @_;

    my ( $sigil, $bare ) = $key =~ m/\A([\$\@\%]?)(?:.*::)?(\w+)\z/;
    my $allow = $kind eq 'global' ? $self->{_allow_globals} : $self->{_allow_subs};
    return 1 if $allow->{$key} || $allow->{ $sigil . $bare } || $index->{exported}{$key};

    # A constant is a sub, so a method call can reach it.  A global cannot.
    my @keys = $kind eq 'global' ? ($key) : ( $key, "->$bare" );
    foreach my $area ( @{ $AREAS_FOR{$kind} } ) {
        foreach my $use (@keys) {
            return 1 if $index->{used}{$area}{$use};
        }
    }
    return 0;
}

# The distribution of a file, with the cache that this policy is configured
# with: none when cache is off, the default when cache_dir is empty.
sub _distribution {
    my ( $self, $file ) = @_;

    return Perl::Critic::Distribution->for_file( $file, cache_dir => undef )               if !$self->{_cache};
    return Perl::Critic::Distribution->for_file( $file, cache_dir => $self->{_cache_dir} ) if $self->{_cache_dir};
    return Perl::Critic::Distribution->for_file($file);
}

# Every definition, export and use in the distribution.  A file's uses are
# not resolved again while the file and the set of definitions are the ones
# they were resolved against.
sub _build_index {
    my ($dist) = @_;

    my $walks = $dist->collected(__PACKAGE__);
    my ( %defined, %exported );
    foreach my $walk ( values %$walks ) {
        $defined{$_}  = 1 for @{ $walk->{defs} };
        $exported{$_} = 1 for @{ $walk->{exports} };
    }

    # Whether an unqualified bar() in package Baz means Baz::bar depends on
    # whether some other file defines one.  So a file resolved against the
    # same definitions keeps its answer, and every file is resolved again when
    # the definitions change.
    my $definitions = Digest::SHA::sha1_hex( join "\n", sort keys %defined );
    my $kept        = $dist->stash(__PACKAGE__) // {};
    my $held        = ( $kept->{definitions} // q{} ) eq $definitions && ref $kept->{resolved} eq 'HASH' ? $kept->{resolved} : {};

    my ( %used, %resolved );
    my $changed = 0;
    foreach my $file ( sort keys %$walks ) {
        my $stamp = $dist->stamp_of($file);
        my $was   = $held->{$file};

        if ( ref $was ne 'HASH' || ( $was->{stamp} // q{} ) ne $stamp || ref $was->{keys} ne 'ARRAY' ) {
            my %keys = map { $_ => 1 } map { _resolve( \%defined, @$_ ) } @{ $walks->{$file}{uses} };
            $was     = { stamp => $stamp, keys => [ sort keys %keys ] };
            $changed = 1;
        }
        $resolved{$file} = $was;
        $used{ $AREA_OF{ $dist->area_of($file) } }{$_} = 1 for @{ $was->{keys} };
    }

    # A file that is gone is a change too.
    $changed ||= grep { !$resolved{$_} } keys %$held;
    $dist->keep( __PACKAGE__, { definitions => $definitions, resolved => \%resolved } ) if $changed;

    return { exported => \%exported, used => \%used };
}

# What one file defines, exports and uses, as plain data that JSON can hold.
# Perl::Critic::Distribution calls it, with the parsed file.
sub _parse {
    my ($ppi) = @_;

    my $found = _walk_document($ppi);
    return {
        defs    => [ map { $_->[2] } @{ $found->{defs} } ],
        exports => $found->{exports},
        uses    => $found->{uses},
    };
}

# A use as the walk saw it -- sigil, name, package, enclosing sub, whether it
# was a method call -- as the keys of whatever it could be a use of.
sub _resolve {
    my ( $defined, $sigil, $name, $pkg, $in_sub, $method ) = @_;

    if ( $sigil eq '*' ) {
        return map { _resolve( $defined, $_, $name, $pkg, $in_sub, 0 ) } ( q{}, qw{$ @ %} );
    }

    if ($method) {
        $name =~ s/\ASUPER:://;
        return _qualify( $pkg, $name ) if index( $name, '::' ) >= 0;
        return                         if defined $in_sub && $in_sub =~ m/::\Q$name\E\z/;    # $self->same_sub
        return "->$name";
    }

    my $key = _qualify( $pkg, $sigil . $name );

    # Unqualified and not defined in this package: a builtin, a lexical, or
    # somebody else's, and nothing of ours.
    return if index( $name, '::' ) < 0 && !$defined->{$key};
    return if defined $in_sub          && $key eq $in_sub;     # recursion is not a caller
    return $key;
}

sub _qualify {
    my ( $pkg, $name ) = @_;

    my ( $sigil, $bare ) = $name =~ m/\A([\$\@\%]?)(.*)\z/s;
    $bare =~ s/\A::/main::/;
    return $sigil . ( index( $bare, '::' ) >= 0 ? $bare : "${pkg}::$bare" );
}

sub _walk_document {
    my ($ppi) = @_;

    my %found = ( defs => [], exports => [], uses => [] );
    _walk( $ppi, 'main', undef, \%found );
    return \%found;
}

# In source order, so each token is seen with the package and sub it is in.
# $pkg changes among siblings and is passed down, never back up, which is how
# a package statement ends with its enclosing block.
sub _walk {
    my ( $node, $pkg, $in_sub, $found ) = @_;

    foreach my $child ( $node->children() ) {
        if ( $child->isa('PPI::Statement::Package') ) {
            my ($block) = grep { $_->isa('PPI::Structure::Block') } $child->schildren();
            if ($block) {
                _walk( $block, $child->namespace(), $in_sub, $found );
            }
            else {
                $pkg = $child->namespace();
            }
            next;
        }

        if ( $child->isa('PPI::Statement::Sub') && !$child->forward() ) {
            my $key = _qualify( $pkg, $child->name() );
            push @{ $found->{defs} }, [ $child, 'sub', $key ];
            _walk( $child, $pkg, $key, $found );
            next;
        }

        _definitions( $child, $pkg, $found ) if $child->isa('PPI::Statement');

        if ( $child->isa('PPI::Node') ) {
            _walk( $child, $pkg, $in_sub, $found );
        }
        else {
            _token( $child, $pkg, $in_sub, $found );
        }
    }
    return;
}

sub _definitions {
    my ( $stmt, $pkg, $found ) = @_;

    if ( $stmt->isa('PPI::Statement::Variable') && $stmt->type() eq 'our' ) {
        push @{ $found->{defs} }, map { [ $stmt, 'global', _qualify( $pkg, $_ ) ] } $stmt->variables();
    }
    elsif ( $stmt->isa('PPI::Statement::Include') && $stmt->type() eq 'use' && ( $stmt->module() // q{} ) eq 'constant' ) {
        push @{ $found->{defs} }, map { [ $stmt, 'constant', _qualify( $pkg, $_ ) ] } _constant_names($stmt);
    }
    return;
}

# use constant NAME => ..., or use constant { A => ..., B => ... }
sub _constant_names {
    my ($stmt) = @_;

    my $first = $stmt->schild(2) or return;
    if ( $first->isa('PPI::Structure::Constructor') ) {
        my ($expr) = $first->schildren() or return;
        return map { _literal($_) } grep { is_hash_key($_) } $expr->schildren();
    }
    return _literal($first);
}

sub _literal {
    my ($token) = @_;

    return $token->string()  if $token->isa('PPI::Token::Quote');
    return $token->content() if $token->isa('PPI::Token::Word');
    return;
}

sub _token {
    my ( $token, $pkg, $in_sub, $found ) = @_;

    if ( $token->isa('PPI::Token::Word') ) {
        _word( $token, $pkg, $in_sub, $found );
    }
    elsif ( $token->isa('PPI::Token::Symbol') ) {
        _symbol( $token, $pkg, $in_sub, $found );
    }
    elsif ( $token->isa('PPI::Token::ArrayIndex') ) {
        push @{ $found->{uses} }, [ '@', substr( $token->content(), 2 ), $pkg, $in_sub, 0 ];
    }
    elsif ( grep { $token->isa($_) } @INTERPOLATING ) {
        _interpolated( $token, $pkg, $in_sub, $found );
    }
    return;
}

sub _word {
    my ( $word, $pkg, $in_sub, $found ) = @_;

    # The sub keyword and the name being defined, not a call of it.
    return if $word->parent()->isa('PPI::Statement::Sub');

    # is_hash_key calls the last word in any subscript a key, and that includes
    # the method name in $h{ $obj->name }.
    my $method = is_method_call($word) ? 1 : 0;
    return if is_class_name($word)          || ( !$method && is_hash_key($word) );
    return if is_package_declaration($word) || is_included_module_name($word);

    my $name = $word->content();
    $name =~ s/::\z//;
    return if !length $name;

    push @{ $found->{uses} }, [ q{}, $name, $pkg, $in_sub, $method ];
    return;
}

sub _symbol {
    my ( $symbol, $pkg, $in_sub, $found ) = @_;

    my ( $sigil, $name ) = $symbol->symbol() =~ m/\A([\$\@\%\&\*])(.+)\z/s or return;

    _exports( $symbol, $name, $pkg, $found ) if $name =~ m/(?:\A|::)EXPORT(?:_OK|_TAGS)?\z/;
    return                                   if _is_declaration($symbol);

    $sigil = q{} if $sigil eq '&';
    push @{ $found->{uses} }, [ $sigil, $name, $pkg, $in_sub, 0 ];
    return;
}

# The names an @EXPORT, @EXPORT_OK or %EXPORT_TAGS statement lists.
sub _exports {
    my ( $symbol, $name, $pkg, $found ) = @_;

    my $owner = $name =~ m/\A(.+)::/ ? $1 : $pkg;
    my $stmt  = $symbol->statement() or return;

    my @literals = (
        map( { $_->literal() } @{ $stmt->find('PPI::Token::QuoteLike::Words') || [] } ),
        map( { $_->string() } @{ $stmt->find('PPI::Token::Quote')             || [] } ),
    );
    foreach my $literal (@literals) {
        next if $literal =~ m/\A[:-]/;    # a tag, or an Exporter option
        $literal =~ s/\A&//;
        push @{ $found->{exports} }, _qualify( $owner, $literal );
    }
    return;
}

# Is this symbol one a my/our/state statement is declaring, rather than one its
# initializer is reading?
sub _is_declaration {
    my ($symbol) = @_;

    my $node = $symbol;
    while ( my $parent = $node->parent() ) {
        return 0 if $parent->isa('PPI::Structure::Block');
        if ( $parent->isa('PPI::Statement::Variable') ) {

            # PPI calls `local $Foo::x` a declaration too, but it is the
            # global's use -- often a test's only one.
            return 0 if $parent->type() eq 'local';
            foreach my $child ( $parent->schildren() ) {
                return 1 if $child == $node;
                return 0 if $child->isa('PPI::Token::Operator') && $child->content() eq '=';
            }
            return 0;
        }
        $node = $parent;
    }
    return 0;
}

# PPI hands back a string as one token, so "$Foo::x" contains no Symbol to find.
sub _interpolated {
    my ( $token, $pkg, $in_sub, $found ) = @_;

    my $content = $token->isa('PPI::Token::HereDoc') ? join( q{}, $token->heredoc() ) : $token->content();
    while ( $content =~ m/$INTERPOLATED_RX/g ) {
        my ( $sigil, $name, $subscript ) = ( $1, $2, $3 );
        $sigil = $subscript eq '[' ? '@' : '%' if defined $subscript;
        push @{ $found->{uses} }, [ $sigil, $name, $pkg, $in_sub, 0 ];
    }

    # Parsed as the code it is, so a call in it is a call and a string in it is
    # still only a string.
    while ( $content =~ m/$INTERPOLATED_CODE_RX/g ) {
        my $source = $1;
        my $code   = PPI::Document->new( \$source ) or next;
        _walk( $code, $pkg, $in_sub, $found );
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::ProhibitUnusedDefinitions - A sub nobody calls, or a global nobody reads, is code nobody needs.

=head1 VERSION

version 0.005

=head1 Perl::Critic::Policy::ProhibitUnusedDefinitions

A sub that nothing calls is still read, still reviewed, still kept working
through every refactor -- and still tells the next reader that something,
somewhere, needs it.  The same goes for an C<our> variable nothing reads and a
constant nothing names.

Whether anything uses a definition is not a question one file can answer, so
this policy reads the whole distribution around the file being critiqued,
through L<Perl::Critic::Distribution>.  The first time it is asked about a
file, everything under F<bin/>, F<lib/>, F<t/> and F<xt/> is parsed once, and
every call and every reference is noted.  Every later file in the same
distribution is checked against that note rather than parsed again.  Another
policy that reads the distribution through the same library shares the parse.

=over 4

=item Subs

must be called at least once from F<bin/> or F<lib/>.  A sub only the tests
call is a sub only the tests need.

=item C<our> variables and C<use constant> constants

must be used at least once anywhere in F<bin/>, F<lib/>, F<t/> or F<xt/>.
A global the test suite sets to change the code's behaviour is doing its job.

=back

Only definitions in files under F<bin/> or F<lib/> are reported.  A helper
defined in a test is the test's business.

=head2 PROHIBITED

    package My::Thing;
    sub helper { ... }          # nothing in bin/ or lib/ calls it
    our $DEBUG = 0;             # nothing anywhere reads it
    use constant LIMIT => 10;   # nothing anywhere names it

=head2 ALLOWED

    package My::Thing;
    sub helper { ... }
    sub run    { helper() }     # ...and bin/thing calls My::Thing->run

    our @EXPORT_OK = qw{ tool };
    sub tool { ... }            # exported, so its callers are elsewhere

    sub DESTROY { ... }         # perl calls it

=head2 WHAT COUNTS AS A USE

=over 4

=item * A call, bare or qualified: C<helper()>, C<My::Thing::helper()>.

=item * A method call, C<< $obj->helper >>, wherever it is written -- a
subscript such as C<< $h{ $obj->helper } >> included.  The class behind
C<$obj> cannot be known statically, so this counts as a use of every sub named
C<helper>.

=item * A reference: C<\&helper>, C<&helper>, C<*helper>.

=item * Any of these inside an interpolating string or heredoc, as
C<< "@{[ $obj->helper ]}" >> or C<< "${\ helper() }" >>.  What is inside is
read as the code it is.

=item * For variables, any mention other than the declaration itself --
C<$x>, C<$x[0]> and C<$#x> for C<@x>, C<$x{k}> for C<%x>, qualified or not,
and inside an interpolating string or regex.

=back

An unqualified name is resolved to the package it appears in.  A C<bar()> in
package C<Baz> is a use of C<Baz::bar>, not of an unrelated C<Foo::bar>.

A string that happens to spell a sub's name is B<not> a use, so
C<< __PACKAGE__->can('helper') >> and C<< { list => 'do_list' } >> do not
count, and nor do C<< "@{[ 'helper' ]}" >> or C<"${helper}">.  Those are what
C<allow_subs> and C<## no critic> are for.

=head2 EXEMPT

Anything listed in a package's C<@EXPORT>, C<@EXPORT_OK> or C<%EXPORT_TAGS>.
Exporting it is the point, and its callers are in some other distribution.

The names perl or a framework calls for you, and the globals perl reads itself:

    BEGIN END INIT CHECK UNITCHECK AUTOLOAD DESTROY import unimport
    CLONE CLONE_SKIP BUILD BUILDARGS DEMOLISH FOREIGNBUILDARGS
    and the tie interface: TIEHASH FETCH STORE and the rest

    $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD

=head2 CONFIGURATION

=over 4

=item C<allow_subs>

Space separated subs and constants that are never reported, as a bare name or
qualified with its package.  Adds to the built-in list rather than replacing
it:

    [ProhibitUnusedDefinitions]
    allow_subs = new My::Plugin::register

=item C<allow_globals>

The same for C<our> variables, with their sigil:

    [ProhibitUnusedDefinitions]
    allow_globals = $DEBUG %My::Thing::REGISTRY

=item C<cache>

Whether to keep the index on disk between runs.  On by default.  See
L</THE INDEX ON DISK>.

    [ProhibitUnusedDefinitions]
    cache = 0

=item C<cache_dir>

Where the index is kept.  The default is that of
L<Perl::Critic::Distribution>, F<$XDG_CACHE_HOME/perl-critic-distribution>, or
F<~/.cache/perl-critic-distribution> when C<XDG_CACHE_HOME> is not set.  Give
every policy that reads the distribution the same one, or none, so that they
share a parse.

=back

=head2 THE INDEX ON DISK

An editor integration such as PerlNavigator starts a new process for every file
that it checks.  Without a cache, every check of a file in F<bin/> or F<lib/>
parses the whole distribution again, which takes seconds on a large one.

So what each file defines, exports and uses is kept on disk, by
L<Perl::Critic::Distribution>, whose documentation says how.  A new process
parses only the files that changed.  A new version of this policy, or an edit
to it, parses every file again.

Each file's uses are kept resolved, too, with a digest of every definition in
the distribution when they were resolved.  An unqualified call means a sub in
its own package only if some file defines one, so what a use means can change
when another file changes.  While the definitions stay the same, an unchanged
file keeps its resolved uses, and only the changed files are resolved.  When a
definition is added, removed or renamed, every file is resolved again.

=head2 CAVEATS

The distribution's root is found as L<Perl::Critic::Distribution/root_of>
says: the nearest directory above the file with a F<dist.ini>, F<Makefile.PL>,
F<Build.PL>, F<META.json>, F<META.yml>, F<cpanfile> or F<.git> in it.  Only a
file in its F<lib/> or F<bin/> is checked.  Source with no file name -- a
string handed to C<critique> -- belongs to no distribution and is never
reported.

The index is built once per distribution per process.  A file edited after it
was built is not seen again in that process.  L</THE INDEX ON DISK> is how the
next process sees it.

Anything reached only at runtime -- a symbolic call, a string C<eval>, an
C<AUTOLOAD>, a dispatch table of names, C<use overload> with method names --
reads as unused, because the source does not say otherwise.

Every heredoc is read as though it interpolates, C<<< <<'END' >>> included, so a
variable or an C<@{[ ... ]}> spelled out in a literal one still counts as a
use.

Lexical scope is not tracked.  In a package that declares C<our $x>, every
C<$x> is read as the global, including the reads of a C<my $x> that shadows
it.  Neither is C<our>'s habit of reaching across a later C<package> statement
in the same block, nor C<${name}> written with braces outside a string.

=head2 TEMPLATES

Templates are not read, so a sub called only from a template reads as unused.

For most templates that costs nothing.  L<Text::Xslate>,
L<Template Toolkit|Template>, L<Mojo::Template>, L<HTML::Template> and the rest
hand a template a hash of variables, and a key in a hash is not a sub:
C<[% domain %]> or C<[% vhost.name %]> on plain data reaches no perl code.

The exception is an object in that hash. Don't forget to search your templates
any time you are tempted to remove code flagged in classes by this policy.

=head2 METHODS

=head3 supported_parameters

C<allow_subs> and C<allow_globals>, the names that are never reported, added
to the built-in lists.  C<cache> and C<cache_dir>, which control
L</THE INDEX ON DISK>.

=head3 initialize_if_enabled

Folds the built-in exemptions back into whatever was configured, so a user's
list adds to the defaults instead of replacing them.  Registers what this
policy collects from each file with L<Perl::Critic::Distribution>, so that it
is collected in the same parse as what any other enabled policy needs.

=head3 default_severity

SEVERITY_LOW

=head3 default_themes

maintenance

=head3 applies_to

PPI::Statement::Sub, PPI::Statement::Variable and PPI::Statement::Include --
the three ways to define a sub, a global or a constant.

=head3 violates

Standard L<Perl::Critic::Policy> interface.  Returns one violation for each
sub, global or constant the statement defines that nothing in the distribution
uses, builds the distribution's index the first time it is needed.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/perl-critic-policy-prohibitunuseddefinitions/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


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
