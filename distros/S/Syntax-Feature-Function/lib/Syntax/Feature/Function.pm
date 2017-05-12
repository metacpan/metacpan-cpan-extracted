use strict;
use warnings;

# ABSTRACT: Provides a function keyword

package Syntax::Feature::Function;
{
  $Syntax::Feature::Function::VERSION = '0.002';
}

use Carp                    qw( croak );
use Function::Parameters    ();
use B::Hooks::EndOfScope;
use Import::Into;

use namespace::clean;

$Carp::Internal{ +__PACKAGE__ }++;

sub install {
    my ($class, %args) = @_;

    my $target  = $args{into};
    my $options = $args{options};
    my @names   = qw( fun );

    # we received options
    if (defined $options) {
        my $options_ref = ref $options;

        # function => { ... }
        if ($options_ref eq 'HASH') {

            # function => { -as => ... }
            if (defined( my $as = $options->{ -as } )) {
                my $as_ref = ref $as;

                # -as => 'fun'
                if (not $as_ref) {

                    @names = ($as);
                }

                # -as => [qw( fun f )]
                elsif (ref $as eq 'ARRAY') {

                    @names = @$as;
                }

                # bad -as type
                else {

                    croak q(The '-as' option to the 'function' syntax feature only accepts)
                        . q( scalar and array reference values);
                }
            }
        }

        # bad options type
        else {

            croak q(Options for feature must be a hash or array reference);
        }
    }

    # make sure all names are valid
    m/\A[_a-z][_a-z0-9]*\Z/i 
        or croak qq(Invalid function declaration identifier '$_')
        for @names;

    # install handlers
    Function::Parameters->import::into($target, $_)
        for @names;

    on_scope_end {
        namespace::clean->clean_subroutines($target, @names);
    };

    return 1;
}

1;

__END__

=pod

=head1 NAME

Syntax::Feature::Function - Provides a function keyword

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    package Foo;
    use syntax 'function';

    fun curry ($orig, @orig_args) {
        fun (@args) { $orig->(@orig_args, @args) }
    }

    curry(fun ($n, $m) { $n + $m }, 2)->(3); # 5

    1;

=head1 DESCRIPTION

This library uses the L<syntax> dispatching mechanism to activate the
functionality provided by L<Function::Parameters>.

=head2 Keyword Naming

By default, a C<fun> keyword will be provided. There are various ways to change
the name and number of function keywords that will be provided.

=head3 Using a different name

    use syntax function => { -as => 'f' };

The above example would provide a function declaration keyword named C<f>
instead of C<fun>. So you could say

    f foo ($n) { 2 * $n }

and

    f ($n) { 2 * $n }

for anonymous functions.

=head3 Multiple function declarators

    use syntax function => { -as => [qw( f fun )] };

This usage will provide you with B<both> keywords: C<f> and C<fun>. They will
both work the same way.

=head1 METHODS

=head2 install

Called by L<syntax> to install the function declarator keyword into the 
requesting package.

=head1 SEE ALSO

L<syntax>, 
L<Function::Parameters>, 
L<Devel::Declare>

=head1 AUTHOR

Robert 'phaylon' Sedlacek <rs@474.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Robert 'phaylon' Sedlacek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
