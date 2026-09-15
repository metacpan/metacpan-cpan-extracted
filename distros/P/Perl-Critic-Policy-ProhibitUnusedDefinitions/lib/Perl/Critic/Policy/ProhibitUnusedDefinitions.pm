package Perl::Critic::Policy::ProhibitUnusedDefinitions;
$Perl::Critic::Policy::ProhibitUnusedDefinitions::VERSION = '0.002';
# ABSTRACT: A sub nobody calls, or a global nobody reads, is code nobody needs.

use 5.014;

use strict;
use warnings FATAL => 'all';

use re '/aa';

use Readonly;

use Cwd          ();
use File::Spec   ();
use PPI          ();
use Scalar::Util ();

use Perl::Critic::Utils qw{ :severities :classification all_perl_files };
use parent              qw{Perl::Critic::Policy};


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
# for every file still parses the distribution once.
my %INDEX_FOR;


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
    );
}

sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    # 'string list' hands us the configured value in place of the default, and
    # somebody naming one plugin hook of their own did not mean to start
    # reporting DESTROY.
    $self->{_allow_subs}{$_}    = 1 for split m/\s+/, $DEFAULT_ALLOW_SUBS;
    $self->{_allow_globals}{$_} = 1 for split m/\s+/, $DEFAULT_ALLOW_GLOBALS;

    return $self->SUPER::initialize_if_enabled($config);
}

sub default_severity { return $SEVERITY_LOW }
sub default_themes   { return qw(maintenance) }
sub applies_to       { return qw(PPI::Statement::Sub PPI::Statement::Variable PPI::Statement::Include) }


sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $definitions = $self->_definitions_in($doc)                            or return;
    my $defined     = $definitions->{by_elem}{ Scalar::Util::refaddr($elem) } or return;

    my $index = $INDEX_FOR{ $definitions->{root} } //= _build_index( $definitions->{root} );

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

    my $definitions;
    if ( my $root = _dist_root( $doc->filename() ) ) {
        my %by_elem;
        foreach my $def ( @{ _walk_document( $doc->ppi_document() )->{defs} } ) {
            my ( $elem, @kind_and_key ) = @$def;
            push @{ $by_elem{ Scalar::Util::refaddr($elem) } }, \@kind_and_key;
        }
        $definitions = { root => $root, by_elem => \%by_elem };
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

# The distribution a file belongs to, if the file is in its bin/ or lib/.
sub _dist_root {
    my ($file) = @_;

    return if !defined $file;
    my $path = Cwd::abs_path($file) // return;

    my ( $volume, $directories ) = File::Spec->splitpath($path);
    my @dirs = File::Spec->splitdir($directories);
    pop @dirs while @dirs && !length $dirs[-1];

    # The nearest directory that looks like a distribution decides, and a file
    # in its t/lib is not in its lib.  Only with no such directory anywhere do
    # we guess from the path alone.
    my $fallback;
    foreach my $depth ( reverse 0 .. $#dirs ) {
        my $ancestor = File::Spec->catpath( $volume, File::Spec->catdir( @dirs[ 0 .. $depth ] ), q{} );
        my $in_code  = $depth < $#dirs && ( $AREA_OF{ $dirs[ $depth + 1 ] } // q{} ) eq 'code';

        if ( grep { -e File::Spec->catfile( $ancestor, $_ ) } @DIST_MARKERS ) {
            return if !$in_code;
            return $ancestor;
        }
        $fallback //= $ancestor if $in_code;
    }
    return $fallback;
}

# Every definition, export and use in the distribution, read once.
sub _build_index {
    my ($root) = @_;

    my ( %defined, %exported, @uses );
    foreach my $dir ( sort keys %AREA_OF ) {
        my $path = File::Spec->catdir( $root, $dir );
        next if !-d $path;

        foreach my $file ( all_perl_files($path) ) {
            my $ppi   = PPI::Document->new($file) or next;
            my $found = _walk_document($ppi);
            $defined{ $_->[2] } = 1 for @{ $found->{defs} };
            $exported{$_} = 1 for @{ $found->{exports} };
            push @uses, map { [ $AREA_OF{$dir}, @$_ ] } @{ $found->{uses} };
        }
    }

    # Resolved only now, because whether an unqualified bar() in package Baz
    # means Baz::bar depends on whether some other file defines one.
    my %used;
    foreach my $use (@uses) {
        my ( $area, @use ) = @$use;
        $used{$area}{$_} = 1 for _resolve( \%defined, @use );
    }

    return { exported => \%exported, used => \%used };
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

version 0.002

=head1 Perl::Critic::Policy::ProhibitUnusedDefinitions

A sub that nothing calls is still read, still reviewed, still kept working
through every refactor -- and still tells the next reader that something,
somewhere, needs it.  The same goes for an C<our> variable nothing reads and a
constant nothing names.

Whether anything uses a definition is not a question one file can answer, so
this policy reads the whole distribution around the file being critiqued.  The
first time it is asked about a file, it finds the distribution's root, parses
everything under F<bin/>, F<lib/>, F<t/> and F<xt/> once, and notes every call
and every reference.  Every later file in the same distribution is checked
against that note rather than parsed again.

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

=back

=head2 CAVEATS

The distribution's root is the nearest directory above the file with a
F<dist.ini>, F<Makefile.PL>, F<Build.PL>, F<META.json>, F<META.yml>,
F<cpanfile> or F<.git> in it.  Failing that, it is the directory holding the
F<lib/> or F<bin/> the file is in.  Source with no file name -- a string handed
to C<critique> -- belongs to no distribution and is never reported.

The index is built once per distribution per process.  A file edited after it
was built is not seen again until the next run.

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
to the built-in lists.

=head3 initialize_if_enabled

Folds the built-in exemptions back into whatever was configured, so a user's
list adds to the defaults instead of replacing them.

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
