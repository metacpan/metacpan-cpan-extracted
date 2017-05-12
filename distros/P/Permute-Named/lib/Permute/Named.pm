use 5.008;
use strict;
use warnings;

package Permute::Named;
BEGIN {
  $Permute::Named::VERSION = '1.100980';
}

# ABSTRACT: permute multiple-valued key-value pairs
use Storable 'dclone';
use Exporter qw(import);
our @EXPORT = qw(permute_named);

sub permute_named {
    my $args;
    if (@_ == 1) {
        $args = shift;
    } else {
        $args = \@_;
    }
    if (ref $args eq 'HASH') {
        $args = [%$args];
    }
    if (ref $args ne 'ARRAY') {
        die "permute_named expects an array ref or a hash ref\n";
    }
    if (@$args % 2 == 1) {
        die "permute_named got an uneven-sized list of arguments\n";
    }
    my @permutations;
    my $permute;
    $permute = sub {
        my ($args, $done) = @_;
        my $done_clone = dclone $done;
        if (@$args == 0) {
            push @permutations => $done_clone;
            return;
        }
        my $args_clone = dclone $args;
        my ($key, $value) = splice @$args_clone, 0, 2;
        $value = [$value] unless ref $value eq 'ARRAY';
        for my $element (@$value) {
            $done_clone->{$key} = $element;
            $permute->($args_clone, $done_clone);
        }
    };
    $permute->($args, {});
    wantarray ? @permutations : \@permutations;
}
1;


__END__
=pod

=head1 NAME

Permute::Named - permute multiple-valued key-value pairs

=head1 VERSION

version 1.100980

=head1 SYNOPSIS

    use Permute::Named;

    my @p = permute_named(bool => [ 0, 1 ], x => [qw(foo bar baz)]);
    for (@p) {
        some_setup() if $_->{bool};
        other_setup($_->{x});
        # ... now maybe do some tests ...
    }

=head1 FUNCTIONS

=head2 permute_named

Takes a list of key-specification pairs where the specifications can be
references to arrays of possible actual values. It then permutes all
key-specification combinations and returns the resulting list of permutations.

The function expects the pairs as an array, an array reference or a hash
reference. The benefit of passing it as an array or array reference is that
you can specify the order in which the permutations will take place - the
final specification will be processed first, then the next-to-last
specification and so on. Any other type of reference causes it to die. An
uneven-sized list of elements - indicating that one key won't have a
specification - also causes it to die.  The resulting permutation list is
return as an array in list context or as a reference to an array in scalar
context.

Each specification can be a scalar or a reference to an array of possible
values.

Example 1:

    permute_named(bool => [ 0, 1 ], x => [qw(foo bar baz)])

returns:

    [ { bool => 0, x => 'foo' },
      { bool => 0, x => 'bar' },
      { bool => 0, x => 'baz' },
      { bool => 1, x => 'foo' },
      { bool => 1, x => 'bar' },
      { bool => 1, x => 'baz' },
    ]

The following call is equivalent to the call above:

    permute_named([ bool => [ 0, 1 ], x => [qw(foo bar baz)] ])

Passing the key-specification pairs as a hash reference also works, but does
not guarantee the permutation order:

    permute_named({ bool => [ 0, 1 ], x => [qw(foo bar baz)] })

Example 2:

    permute_named(foo => 1, bar => 2)

just returns the one permutation:

    [ { foo => 1, bar => 2 } ]

The C<permute_named()> function has been useful in making sure that tests
work for all combinations of settings, as shown in the synopsis.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Permute-Named>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Permute-Named/>.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

