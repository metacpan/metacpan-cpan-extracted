package PerlX::ScopeFunction;
use v5.36;

our $VERSION = "0.03";

use Const::Fast ();
use Keyword::Simple;
use PPR;

our %STASH = ();

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
    my %handler = (
        'let' => \&__rewrite_let,
        'with' => \&__rewrite_with,
    );

    my %import_as = do {
        if (@args > 0) {
            %{ __parse_imports(@args) };
        } else {
            map { $_ => $_ } keys %handler;
        }
    };

    for (keys %import_as) {
        my $keyword = $import_as{$_};
        Keyword::Simple::define $keyword, $handler{$_};
        push @{ $STASH{$class} }, $keyword;
    }
}

sub unimport ($class) {
    for my $keyword (@{ $STASH{$class} //[]}) {
        Keyword::Simple::undefine $keyword;
    }
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

This module provide 2 extra keywords -- C<with> and C<let> -- for
creating creating scopes that look a little bit better than just a
bare code BLOCK.

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

If in the current scope, thee are variables with identical names as
the ones in the DECLARATED, they are masked in the let-block.

For example, these would creating 3 new variables in the let-block
that mask the ones with identical names in the current scope.

    my ($foo, $bar, $baz) = (10, 20, 30);
    let ($foo = 1; $bar = 2; $baz = $foo + $bar) {
        say "$foo $bar $baz"; #=> 1 2 3
    }
    say "$foo $bar $baz"; #=> 10 20 30

Array and Hash can also be created:

    let (@foo = (1,2,3); %bar = (bar => 1); $baz = 42) {
        ...
    }

=head1 Importing as different names

Since the keywords provided in this module are commonly defined in
other CPAN modules, this module also provides a way to let users to
import those keywords as different names, with a conventional spec also
seen in L<Sub::Exporter>.

For example, to import C<with> as C<given_these>, you say:

    use PerlX::ScopeFunction "with" => { -as => "given_these" };

Basically HashRef in import list becomes modifiers of the previous
entry. However, This module supports only the modifier C<-as> but not
other ones as seen in L<Sub::Exporter>.

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
