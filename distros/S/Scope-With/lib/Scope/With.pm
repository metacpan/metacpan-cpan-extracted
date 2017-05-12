package Scope::With;

use 5.008001;

use strict;
use warnings;

use Devel::Declare::Context::Simple ();

our $VERSION = '0.01';

=begin comment

Under the hood, C<Scope::With> turns a statement like the following:

    with (MyClass $foo) {
        bar();
        baz ...;
        quux (42);
    }

into (formatted for clarity):

    with {
        use Scope::With::Inject qw(MyClass);
        set_invocant($foo);
        no Scope::With::Inject;
        bar();
        baz ...;
        quux = 42;
    }

    sub with(&) {
        my $block = shift;
        $block->();
    }

C<Scope::With::Inject> installs a lexical sub for each of C<MyClass>'s methods (determined at compile-time)
which calls the corresponding method on the specified invocant (set at runtime). C<no Scope::With::Inject> unimports
the C<set_invocant> method, which provides it conflicting with any prior or subsequent subroutines
of that name, but it leaves the lexical delegating subs intact.

If no class is specified in the C<with> statement, then only C<AUTOLOAD> and C<set_invocant>
are installed in the scope, and C<use Scope::With::Inject> is called with no argument.

=end comment

=cut

sub with(&) { $_[0]->() }

sub import {
    my $class   = shift;
    my $keyword = shift || 'with';
    my $caller  = Devel::Declare::get_curstash_name;

    Devel::Declare->setup_for(
        $caller,
        {
            $keyword => {
                const => sub { $class->parser(Devel::Declare::Context::Simple->new->init(@_)) }
            }
        }
    );

    no strict 'refs';
    *{"$caller\::$keyword"} = \&with;
}

sub parser {
    my ($class, $context) = @_;

    $context->skip_declarator;
    $context->skipspace;

    my $proto = $context->strip_proto;
    $context->skipspace;

    my $inject;

    if ($proto =~ /^\s*(\S+)\s+(.+?)\s*$/) {
        $inject = "use Scope::With::Inject qw($1); set_invocant($2); no Scope::With::Inject;";
    } else {
        $inject = "use Scope::With::Inject; set_invocant($proto); no Scope::With::Inject;";
    }

    # prefix our injected code with code that appends a semicolon to the end of the block
    $inject = $context->scope_injector_call(';') . $inject;
    $context->inject_if_block($inject);
}

1;

__END__

=head1 NAME

Scope::With - A JavaScript-style with statement for lexically-scoped method delegation

=head1 SYNOPSIS

    use Builder;
    use Scope::With;

    my $builder = Builder->new();
    my $xml = $builder->block('Builder::XML');

    with ($xml) {
        body(
            div(
                span({ id => 1 }, 'one'),
                span({ id => 2 }, 'two'),
            )
        );
    }

    say $builder->render();

=head1 DESCRIPTION

C<Scope::With> provides an implementation of the JavaScript C<with> statement. Subroutines
inside the C<with> block that correspond to methods on the value passed into
the C<with> statement (the invocant) invoke the corresponding method on that value
with the supplied arguments. The subroutines are lexically-scoped, and are not
defined outside of the block.

The C<with> keyword can be replaced by another keyword by supplying it as an argument to
the C<use Scope::With> statement e.g.

    use Scope::With qw(using);

    using ($xml) {
        div(
            span( ... ),
            span( ... ),
        );
    }

The C<with> statement takes two forms.

=head2 STATIC

C<with> can be passed a class name/invocant pair separated by one or more spaces e.g.:

    with (Dog $spot) {
        bark ...;
        wag_tail;
    }

The class name must be a bareword i.e. an expression evaluating to a class name is not allowed.
The invocant can be an arbitrary expression.

In this form, the class's methods are determined at compile-time and used to install the appropriate
subroutines. The benefit of this usage is that the delegating subroutines are installed,
with suitable prototypes, before the rest of the block is compiled, and therefore do not need
to be invoked with parentheses.

By default, these subs have a prototype of C<@>, which works for zero or more
arguments, though it doesn't cater for subs that take blocks.

Note that when using the static form, the installed subroutines correspond to the methods available
on the specified class at the time the C<with> statement is compiled. This will install
an C<AUTOLOAD> subroutine, if the class defines or inherits an C<AUTOLOAD> method, but won't pick
up methods added after the C<with> statement has been compiled, and, likewise, won't
detect methods that are subsequently removed from the class.

=head2 DYNAMIC

The second form takes only an invocant (which can be an arbitrary expression),
and defers the method lookup to runtime. This is done by means of a (lexically-scoped) C<AUTOLOAD> sub.
This requires each delegating sub to be called with parentheses.

This is useful in situations where parentheses are either a) not burdensome or b) required:

    with ($xml) {
        div( 
            span( ... ),
            span( ... ),
        );
    }

=head1 CAVEATS

=over

=item * lvalue subs/methods are not currently supported

=item * method prototypes are not currently honoured i.e. the default prototype, C<@>, is used in all cases

=back

=head1 VERSION

0.01

=head1 SEE ALSO

=over

=item * L<Builder|Builder>

=item * L<with|with>

=back

=head1 AUTHOR

chocolateboy <chocolate@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by chocolateboy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
