=head1 NAME

Sub::Curried - automatically curried subroutines

=head1 SYNOPSIS

 curry add_n_to ($n, $val) {
    return $n+$val;
 }

 my $add_10_to = add_n_to( 10 );

 say $add_10_to->(4);  # 14

 # but you can also
 say add_n_to(10,4);  # also 14

 # or more traditionally
 say add_n_to(10)->(4);

=head1 DESCRIPTION

Currying and Partial Application come from the heady world of functional
programming, but are actually useful techniques.  Partial Application is used
to progressively specialise a subroutine, by pre-binding some of the arguments.

Partial application is the generic term, that also encompasses the concept of
plugging in "holes" in arguments at arbitrary positions.  Currying is more
specifically the application of arguments progressively from left to right
until you have enough of them.

=head1 DEPENDENCIES

Beyond those listed in META.yml/META.json, there is an optional dependency on
PPR: if you have it installed, then your curry definitions can include POD
syntax anywhere whitespace can occur between C<curry> and C<{>.  Without PPR,
that will trigger a syntax error.

If your Perl is older than 5.16, you'll also need Sub::Current.

=head1 USAGE

Define a curried subroutine using the C<curry> keyword.  You should list the
arguments to the subroutine in parentheses.  This isn't a sophisticated signature
parser, just a common separated list of scalars (or C<@array> or C<%hash> arguments,
which will be returned as a I<reference>).

    curry greet ($greeting, $greetee) {
        return "$greeting $greetee";
    }

    my $hello = greet("Hello");
    say $hello->("World"); # Hello World

=head2 Currying

Currying applies the arguments from left to right, returning a more specialised function
as it goes until all the arguments are ready, at which point the sub returns its value.

    curry three ($one,$two,$three) {
        return $one + $two * $three
    }

    three(1,2,3)  # normal call - returns 7

    three(1)      # a new subroutine, with $one bound to the number 1
        ->(2,3)   # call the new sub with these arguments

    three(1)->(2)->(3) # You could call the curried sub like this,
                       # instead of commas (1,2,3)

What about calling with I<no> arguments?  By extension that would return a function exactly
like the original one... but with I<no> arguments prebound (i.e. it's an alias!)

    my $fn = three;   # same as my $fn = \&three;

=head2 Anonymous curries

Just like you can have anonymous subs, you can have anonymous curried subs:

    my $greet = curry ($greeting, $greetee) { ... }

=head2 Composition

Curried subroutines are I<composable>.  This means that we can create a new
subroutine that takes the result of the second subroutine as the input of the
first.

Let's say we wanted to expand our greeting to add some punctuation at the end:

    curry append  ($r, $l) { $l . $r }
    curry prepend ($l, $r) { $l . $r }

    my $ciao = append('!') << prepend('Ciao ');
    say $ciao->('Bella'); # Ciao Bella!

How does this work?  Follow the pipeline in the direction of the E<lt>E<lt>...
First we prepend 'Ciao ' to get 'Ciao Bella', then we pass that to the curry that
appends '!'.  We can also write them in the opposite order, to match evaluation
order, by reversing the operator:

    my $ciao = prepend('Ciao ') >> append('!');
    say $ciao->('Bella'); # Ciao Bella!

Finally, we can create a shell-like pipeline:

    say 'Bella' | prepend('Ciao ') | append('!'); # Ciao Bella!

The overloaded syntax is provided by C<Sub::Composable> which is distributed with
this module as a base class.

=head2 Argument aliasing

When all the arguments are supplied and the function body is executed, the
arguments values are available in both the named parameters and the C<@_>
array.  Just as in a normal subroutine call, the elements of C<@_> (but
I<not> the named parameters) are aliased to the variables supplied by the
caller, so you can use pass-by-reference semantics.

    curry set ($a, $b) {
      foreach my $arg (@_) { $arg = 1; } # affects the caller
      $a = $b = 2;                       # doesn't affect the caller
    }
    my ($x, $y) = (0, 0);
    set($x)->($y); # $x == 1, $y == 1

=head2 Stack traces

The innermost stack frame has the function name you defined, with all the
accumulated arguments.  Any intermediate stack frames have the same or
similar function names; currently there is a C<__curried> suffix, but that
may change in the future.  Currently there is only one intermediate stack
frame, showing just the arguments that were passed in the final call that
reached the required number of arguments, but that may change in the future.
If you supply all the arguments in one call, there are no intermediate stack
frames.

    use Carp 'confess';
    curry func ($a, $b, $c, $d) {
      confess('ERROR MESSAGE');
    }
    sub call {
      func(1)->(2)->(3, 4);
    }
    call();

    ERROR MESSAGE at script.pl line 3
           main::func(1, 2, 3, 4) called at .../Sub/Curried.pm line 202
           main::func__curried(3, 4) called at script.pl line 6
           main::call() called at script.pl line 8

=cut

use strict; use warnings;
package Sub::Curried;
$Sub::Curried::VERSION = '0.14';
use parent 'Sub::Composable';

use Sub::Name;
use Keyword::Pluggable 1.05;
use Attribute::Handlers;

sub import {
    Keyword::Pluggable::define('keyword'    => 'curry',
                               'code'       => \&injector,
                               'expression' => 'dynamic');
}

sub unimport {
    Keyword::Pluggable::undefine('keyword' => 'curry');
}

sub UNIVERSAL::Sub__Curried :ATTR(CODE) {
    my ($package, $symbol, $ref, $attr, $arg) = @_;
    bless($ref, __PACKAGE__);
}

my $current_sub;
BEGIN {
    if ($^V lt v5.16.0) {
        require Sub::Current;
        $current_sub = 'Sub::Current::ROUTINE';
    } else {
        $current_sub = 'CORE::__SUB__';
    }
}

# PPR is the easiest way to parse POD.  But POD between "curry" and "{" was
# never supported before, and PPR may be slow depending on the Perl version,
# so make it optional.
eval { require PPR; };
my $space  = qr/(?:\s|#[^\n]*\n)/;
my $ppr    = exists($INC{"PPR/pm"})? $PPR::GRAMMAR: '';
my $nspace = exists($INC{"PPR/pm"})? '(?&PerlNWS)': qr/$space+/;
my $ospace = exists($INC{"PPR/pm"})? '(?&PerlOWS)': qr/$space*/;
my $sigil  = qr/[\$\%\@]/;
my $ident  = qr/(?:\p{XIDS}\p{XIDC}*)/;
my $param  = qr/$ospace $sigil $ident/x;

sub injector {
    my ($text) = @_;
    if ($$text !~ s/\A
                    (?<spacename> $nspace (?<name>$ident))?
                    (?<spaceparams> $ospace \(
                      (?<params> $param (?: $ospace , $param)* )?
                      $ospace \) )?
                    (?<space> $ospace ) \{ $ppr
                   /injection(%+)/xe) {
        die('invalid Sub::Curried syntax: '.substr($$text, 0, 80).'...');
    }
    return !defined($+{'name'});
}

sub injection {
    my (%match) = @_;
    my $esc_name = $match{'name'};
    if (defined($esc_name)) { $esc_name =~ s/([\\'])/\\$1/g; }
    my $curried_name = (defined($match{'name'})
                        ? $match{'name'} . '__curried'
                        : undef);
    my $esc_curried_name = $curried_name;
    if (defined($esc_curried_name)) { $esc_curried_name =~ s/([\\'])/\\$1/g; }
    my @name_wrapper = (defined($curried_name)
                        ? ("Sub::Name::subname('".$esc_curried_name."', ", ")")
                        : ('', ''));
    my @params = (defined($match{'params'})
                  ? @{[ ($match{'params'}.',') =~
                        m/$ospace ($sigil $ident) $ospace,$ppr/gx ]}
                  : ());
    return join('',
                'sub', grep(defined($_), $match{'spacename'}),
                ' :Sub__Curried', $match{'space'}, '{',
                ' if (@_ > ', scalar(@params), ') {',
                  " die('", (defined($esc_name)
                            ? $esc_name
                            : '<anonymous function>'),
                       ", expected ", scalar(@params),
                       " args but got '.\@_);",
                ' }',
                (@params == 0
                 ? () # We never need to return a closure
                 : (
                 ' if (@_ < ', scalar(@params), ') {',
                   ' my $func = ', $current_sub, ';',
                   ' my $args = \@_;',
                   ' return ',
                      $name_wrapper[0],
                      'bless(sub { $func->(@$args, @_) }, "Sub::Curried")',
                      $name_wrapper[1],
                    ';',
                 ' }')),
                map({ my @param = ('$_[', $_, ']');
                      (' my ', $params[$_], ' = ',
                       ($params[$_]=~/^([\%\@])/
                        ? ($1, '{', @param, '}')
                        : @param), ';') }
                    0..$#params));
}

=head1 BUGS

No major bugs currently open.  Please report any bugs via RT or email.

=head1 SEE ALSO

L<Keyword::Pluggable> provides the syntactic magic.

There are several modules on CPAN that already do currying or partial evaluation:

=over 4

=item *

L<Perl6::Currying> - Filter based module prototyping the Perl 6 system

=item *

L<Sub::Curry> - seems rather complex, with concepts like blackholes and antispices.  Odd.

=item *

L<AutoCurry> - creates a currying variant of all existing subs automatically.  Very odd.

=item *

L<Sub::DeferredPartial> - partial evaluation with named arguments (as hash keys).  Has some
great debugging hooks (the function is a blessed object which displays what the current
bound keys are).

=item *

L<Attribute::Curried> - exactly what we want minus the sugar.  (The attribute has
to declare how many arguments it's expecting)

=back

=head1 AUTHOR

 (c)2008-2013 osfameron@cpan.org
 (c)2024 Paul Jarc <purge@cpan.org>

=head1 CONTRIBUTORS

=over 4

=item *

Florian (rafl) Ragwitz

=back

=head1 LICENSE

This module is distributed under the same terms and conditions as Perl itself.

=head1 CONTRIBUTING

Please submit bugs to RT or email.

A git repo is available at L<https://github.com/pauljarc/Sub--Curried>

=cut

1;
