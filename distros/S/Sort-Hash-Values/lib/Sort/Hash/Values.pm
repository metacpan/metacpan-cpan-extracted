package Sort::Hash::Values;
{
  $Sort::Hash::Values::VERSION = '0.1.1';
}
use strict;
use warnings;
use Exporter 5.59 qw/import/;
our @EXPORT = our @EXPORT_OK = qw/sort_values/;

# Returns keys of sorted hash values
sub sort_values(&@) {
    my ($code, %hash) = @_;

    # Perl has special behavior when code prototype is $$ of uploading
    # sorted values to @_. || "" is needed to avoid undef warning.
    if ((prototype $code || "") eq '$$') {
        my $old_code = $code;
        $code = sub {
            $old_code->($a, $b);
        }
    }

    # I need caller, so the package to modify would be known.
    my $pkg = caller;

    # I need this sub {} because for some reason I'm not allowed to use
    # lexical pragmas in sort block.
    my $by_values = sub {
        # As I'm doing direct symbol table modifications, disable
        # strict 'refs' for this subroutine.
        no strict 'refs';
        # Localize $a and $b in caller package
        local *{"${pkg}::a"} = \$a->[1];
        local *{"${pkg}::b"} = \$b->[1];
        $code->();
    };
    map $_->[0], sort $by_values map [$_ => $hash{$_}], keys %hash;
}

# Positive value at end
1;

=head1 NAME

Sort::Hash::Values - sort hashes by values

=head1 SYNOPSIS

    use Sort::Hash::Values;

    my %birth_dates = (
        Larry  => 1954,
        Randal => 1961,
        Damian => 1964,
        Simon  => 1978,
        Mark   => 1965,
        Jesse  => 1976,
    );

    for my $name (sort_values { $a <=> $b } %birth_dates) {
        printf "%7s was born in %s.\n", $name, $birth_dates{$name};
    }

=head1 DESCRIPTION

C<sort_values()> is a function that returns keys of values after
sorting its values.

=head1 EXPORTS

All functions are exported using L<Exporter>. If you don't want this
(but why you would use this module then) try importing it using empty
list of functions.

    use Sort::Hash::Values ();

=over 4

=item sort_values { code } %hash

The only function in this module. It sorts every value in hash using
specified code and returns list of their keys sorted according to their
values.

Just like with C<sort> in Perl, when code prototype is C<$$>, the
variables to sort will be in C<@_> too.

=back

=head1 CAVEATS

When giving the function to C<sort_values> it has to be function in
scope where you call C<sort_values>. This is internal limitation caused
by the fact that Perl module cannot know what package the function you
used belongs. It can only know where C<sort_values> was called. This
bug also affects C<reduce> in L<List::Util>, C<pairwise> in
L<List::MoreUtils> and other functions that use C<$a> or C<$b>
variables - those variables have to be modified in function's package.

The code block isn't optional. I really would like to make it optional,
but I cannot with Perl limitations. Instead, use C<{ $a cmp $b }> just
after C<sort_values>.

If you will make C<$a> or C<$b> lexical, except this module to break,
as they aren't referencing global variables anymore. This affects every
function that uses those variables, even C<sort> builtin.
L<Just don't|http://perl-begin.org/tutorials/bad-elements/#vars-a-and-b>.

When using C<$a> or C<$b> only once in the code (with the exception for
C<sort> builtin), Perl will warn you. This also affects other modules
that use those variables. To remove warnings about this, use following
code.

    no warnings 'once';

=head1 AUTHOR

Konrad Borowski <glitchmr@myopera.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Konrad Borowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
