package PerlX::ScopeFunction;
use v5.36;

our $VERSION = "0.05";

use Package::Stash;
use Const::Fast qw( const );
use Keyword::Simple;
use PPR;

our %STASH = ();

const our $do => \&__do;
const our $also => \&__also;
const our $tap => \&__also;

sub __parse_imports (@args) {
    my %import_as;

    my $keyword;
    while (@args) {
        my $it = shift @args;
        if (defined($keyword)) {
            if (!ref($it)) {
                $import_as{$keyword} = $keyword;
                $keyword = $it;
            } elsif (ref($it) eq 'HASH') {
                $import_as{$keyword} = $it->{'-as'} // $keyword;
                $keyword = undef;
            }
        } else {
            if (!ref($it)) {
                $keyword = $it
            }
        }
    }

    $import_as{$keyword} = $keyword if defined($keyword);

    return \%import_as;
}

sub import ($class, @args) {
    my $caller = (caller)[0];
    my %handler = (
        'let' =>[
            sub { __define_keyword( \&__rewrite_let, $_[0] ) },
            sub { __undefine_keyword( $_[0] ) },
        ],
        'with' =>[
            sub { __define_keyword( \&__rewrite_with, $_[0] ) },
            sub { __undefine_keyword( $_[0] ) },
        ],
        '$also' => [
            sub { __import_scalar_symbol(\\&__also, $_[0], $_[1]) },
            sub { __unimport_scalar_symbol($_[0], $_[1]) },
        ],
        '$tap' => [
            sub { __import_scalar_symbol(\\&__also, $_[0], $_[1]) },
            sub { __unimport_scalar_symbol($_[0], $_[1]) },
        ],
        '$do' => [
            sub { __import_scalar_symbol(\\&__do, $_[0], $_[1]) },
            sub { __unimport_scalar_symbol($_[0], $_[1]) },
        ],
    );

    my %import_as = do {
        if (@args > 0) {
            %{ __parse_imports(@args) };
        } else {
            map { $_ => $_ } keys %handler
        }
    };

    for (keys %import_as) {
        my ($importer, $unimporter) = @{$handler{$_}};
        my $as = $import_as{$_};
        $importer->($as, $caller);
        push @{ $STASH{$caller} }, sub { $unimporter->($as, $caller) };
    }
}

sub unimport ($class) {
    my $caller = (caller)[0];
    for my $unimporter (@{ $STASH{$caller} // []}) {
        $unimporter->();
    }
}

sub __do {
    my ($self, $code) = @_;
    local $_ = $self;
    return $self->$code();
}

sub __also {
    my ($self, $code) = @_;
    local $_ = $self;
    $self->$code();
    return $self;
}

sub __import_scalar_symbol ($code, $symbol, $pkg) {
    Package::Stash->new($pkg)->add_symbol($symbol, $code);
}

sub __unimport_scalar_symbol ($symbol, $pkg) {
    Package::Stash->new($pkg)->remove_symbol($symbol);
}

sub __define_keyword ($code, $keyword) {
    Keyword::Simple::define $keyword, $code;
}

sub __undefine_keyword ($keyword) {
    Keyword::Simple::undefine $keyword;
}

my $GRAMMAR = qr{
    (?(DEFINE)
        (?<LetAssignmentSequence>
            ((?&LetAssignment))
            (?: ; (?&PerlOWS) ((?&LetAssignment)))*
            (?: ; )?
        )

        (?<LetAssignmentLHS>
            (?>(?&PerlLvalue))
        )

        (?<LetAssignment>
            (?&LetAssignmentLHS) (?&PerlOWS) = (?&PerlOWS) (?&PerlExpression)
        )
    )

    $PPR::GRAMMAR
}x;

sub __comb_PerlVariable ($code) {
    map {
        s/(?&PerlOWS) $GRAMMAR//xg;
        $_
    } map {
        grep { defined } m/((?&PerlVariable)) $GRAMMAR/xsg;
    } $code
}

sub __parse_LetAssignmentSequence ($code) {
    map {
        my $expr = $_;
        my ($lhs) = $expr =~ m/\A ((?&LetAssignmentLHS)) $GRAMMAR /xs;

        +{
            "expr" => $expr,
            "lhs" => $lhs,
            "variables" => [ __comb_PerlVariable($lhs) ],
        }
    } grep { defined } $code =~ m{
        ( (?>(?&LetAssignment)) ) (?: ; (?&PerlOWS))?
        $GRAMMAR
    }xg;
}

sub __rewrite_let ($ref) {
    return unless $$ref =~ m{
        \A (?&PerlOWS)
        \( (?&PerlOWS) (?<assignments> (?&LetAssignmentSequence) ) (?&PerlOWS) \)
        (?&PerlOWS)
        (?<block> (?&PerlBlock))
        (?<remainder> .*)

        $GRAMMAR
    }xs;

    my ($assignments, $remainder) = @+{"assignments", "remainder"};

    # This is meant to remove the surrounding bracket characters ('{' and '}')
    my ($statements) = substr($+{"block"}, 1, -1);

    my @assignments = __parse_LetAssignmentSequence( $assignments );
    my @vars = map { @{ $_->{"variables"} } } @assignments;

    my $code = "(sub {\n";
    $code .= "my (" . join(",", @vars) . ");\n";
    for my $assignment (@assignments) {
        $code .= $assignment->{"expr"} . ";\n";
    }
    for my $var (@vars) {
        $code .= "Const::Fast::_make_readonly(\\$var,1);\n";
    }
    $code .= $statements
        . "\n})->();\n"
        . $remainder;

    $$ref = $code;
}

sub __rewrite_with ($ref) {
    return unless $$ref =~ m{
        \A
        (?&PerlOWS)
        (?<expr> (?&PerlParenthesesList))
        (?&PerlOWS)
        (?<block> (?&PerlBlock))
        (?<remainder> .*)
        $PPR::GRAMMAR
    }xs;

    my $expr = $+{"expr"};
    my $remainder = $+{"remainder"};

    # This is meant to remove the surrounding bracket characters ('{' and '}')
    my ($statements) = substr($+{"block"}, 1, -1);

    $$ref = '(sub { local $_ = $_[-1];'
        . $statements
        . '})->' . $expr . ';'
        . $remainder;
}

1;

__END__

=head1 NAME

PerlX::ScopeFunction - new keywords for creating scopes.

=head1 SYNOPSIS

    use PerlX::ScopeFunction qw( let with );
    use List::Util qw( sum0 );
    use List::MoreUtils qw( part minmax );

    with ( part { $_ % 2 } @input ) {
        my ($evens, $odds) = @_;
        say "There are " . scalar(@$evens) . " even numbers: " . join(" ", @$evens);
        say "There are " . scalar(@$odds) .  " odd numbers: " . join(" ", @$odds);
    }

    let ( ($min,$max) = minmax(@input); $mean = sum0(@input)/@input ) {
        ...
    }

=head1 DESCRIPTION

Scope functions can be used to create small lexical scope, inside
which the results of an given expression are used, but not outside.

This module provide extra keywords / methods / symbols for creating
scopes that help grouping related statements together, or generally
help on making the code look more fluent.

By C<use>-ing this module without a import list, all keywords are imported.
To import only wanted keywords, specify them in the import list:

    # Import all keywords
    use PerlX::ScopeFunction;

    # Import just `let`
    use PerlX::ScopeFunction qw(let);

    # Import just `with`, and name it differently
    use PerlX::ScopeFunction 'with' => { -as 'withThese' }

Imported keywords can be removed by a C<no> statement.

    no PerlX::ScopeFunction;

=head1 Importable keywords / methods / symbols.

=head2 C<with>

The C<with> keyword can be used to bring the result of an given EXPR
to a smaller scope (code block):

    with ( EXPR ) BLOCK

The EXPR are evaluated in list context, and the result (a list) is
available inside BLOCK as C<@_>. The conventional topic variable C<$_>
is also assigned the last value of the list (C<$_[-1]>).

=head2 C<let>

The C<let> keyword can be used to create readonly C<my>- variables in
a smaller scope (code block).

The keyword C<let> should be followed by a list of variable
declarations, then a block.

    let ( DECLARATIONS ) BLOCK

The word C<DECLARATIONS> here means a list of variable declaration
statements seperated by semicolons, except there must be a RHS. They
must be given without any of C<my>, C<our>, C<state> keywords.

For example, if in the BLOCK you would do these to prepare 3
convenient variables:

    my $mean = mean(@input);
    my ($min, $max) = minmax(@input);

With C<let> statements, you do this instead:

    let (
        $mean = mean(@input);
        ($min,$max) = minmax(@input);
    ) {
        ...
    }

Declaration are evaluated in the same order as they are given and all
variables declarated by this are made readonly inside the BLOCK. The
underlying library to make variables readonly is
L<Const::Fast>. Variables created in the beginning of this list of can
be used in the latter positions.

If in the current scope, there are variables with identical names as
the ones in the DECLARATIONS, they are masked in the let-block.

For example, in the following example code, 3 new variables are
created in the let-block and they the ones with identical names
outside of the let-block.

    my ($foo, $bar, $baz) = (10, 20, 30);
    let ($foo = 1; $bar = 2; $baz = $foo + $bar) {
        say "$foo $bar $baz"; #=> 1 2 3
    }
    say "$foo $bar $baz"; #=> 10 20 30

Array and Hash can also be created:

    let (@foo = (1,2,3); %bar = (bar => 1); $baz = 42) {
        ...
    }

=head2 C<$do>

C<$do> is a method that can be used as a call on any objects. It takes
a CodeRef, evaluates the CodeRef on the context of the object being
called on, and returns the result.

Syntax-wise, C<$do> is used like this:

    EXPR -> $do(sub BLOCK)

For example, the following code would take an object
and compute a sha1 digest:

    my $digest = $o->$do(sub {
        sha1($_->header->title . $_->body->content)
    });

Inside the CodeRef BLOCK, both C<$_> and C<$_[0]> are an alias to the
object being called on.

=head2 C<$tap>, and C<$also>

C<$tap> is a method that takes a CodeRef can be inserted of into a
chain of method calls, do some side actions, then resume.

C<$also> is an alternative name of C<$tap>. They are completely
identical. Import and use which ever that is more comprehensible to
you.

Syntax-wise C<$tap> is supposed to used like these:

    EXPR -> $tap(sub BLOCK)
    EXPR -> $tap(sub BLOCK) -> EXPR

For example, the following code would produce a warning message before
calling C<send()> method on object C<$o>:

    my $o = Example::Mail->new( body => $args{body}, to => $args{to} )
        ->$tap(sub { warn "Mail sening to: " . $_->to ) })
        ->send();

In side the tap code block, C<$_> (and C<$_[0]>) refers to the object
from the EXPR beforehand. The return value of tap code block is thrown
away, and the C<$tap> itself always evaulates to the same object C<$_>
it is called on. This makes it easier to do some side-effects in the
middle of a call chain, but without having to rewrite the call chain
as 2 separate statements. It can also be useful to work around methods
with "inconvenient" return values, or to group a sequence of
object-setup statements together, in a tighter scope:

For example, here we construct an C<Example::Mail>, fill it a
recipient and body, but we want to check some external factors before
actully send it:

    my $o = Example::Mail->new()
        ->$tap(sub {
            $_->set_body( $args{body} );
            $_->set_to( $args{to} );

            $_->ping_mail_server() or die "No internet";
            $_->check_recipient_mood() or die "Bad timing";
        })
        ->send();

The C<$tap> can be think as a method that can be invoked on any
objects. But it would not work on plain scalar values, or anything you
couldn't call methods on.

Since it is just a scalar variable, it can also be copied to a lexical
variable, under whatever more sensible names:

    sub run ($self) {
        my $byTheWay = $PerlX::ScopeFunction::tap;

        $self->$byTheWay(sub { warn "Star running" })
            ->do_run();
    }

See also the C<tap> method from L<Mojo::Base>. Or the scope function
C<also> in Kotlin programming language: L<Kotlin Scope
Function|https://kotlinlang.org/docs/scope-functions.html>

=head1 Importing as different names

Since the keywords provided in this module are commonly defined in
other CPAN modules, this module also provides a way to let users to
import those keywords as different names, with a conventional spec also
seen in L<Sub::Exporter>.

For example, to import C<with> as C<given_these>, you say:

    use PerlX::ScopeFunction "with" => { -as => "given_these" };

Basically HashRef in import list becomes modifiers of their previous
entries. However, This module supports only the modifier C<-as> but
not other ones as seen in L<Sub::Exporter>.

=head1 CAVEATS

Due to the fact this module hooks into perl parser, the keywords
cannot be used without being imported into current namespace.
Statements like the following do not compile:

     PerlX::ScopeFunction::let( ... ) {
         ...
     }

     PerlX::ScopeFunction::with( ... ) {
         ...
     }

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>

=head1 LICENCE

The MIT License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
