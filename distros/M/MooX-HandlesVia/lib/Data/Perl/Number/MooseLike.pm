package Data::Perl::Number::MooseLike;
$Data::Perl::Number::MooseLike::VERSION = '0.001008';
# ABSTRACT: data::Perl::Number subclass that simulates Moose's native traits.

use strictures 1;

use Role::Tiny::With;
use Class::Method::Modifiers;

with 'Data::Perl::Role::Number';

my @methods = grep { $_ ne 'new' } Role::Tiny->methods_provided_by('Data::Perl::Role::Number');

around @methods => sub {
    my $orig = shift;

    $orig->(\$_[0], @_[1..$#_]);
};

1;

=pod

=encoding UTF-8

=head1 NAME

Data::Perl::Number::MooseLike - data::Perl::Number subclass that simulates Moose's native traits.

=head1 VERSION

version 0.001008

=head1 SYNOPSIS

    # you should not be consuming this class directly.

=head1 DESCRIPTION

This class provides a wrapper and methods for interacting with a boolean. All
methods are written to emulate/match existing behavior that exists with Moose's
native traits.

=head1 SEE ALSO

=over 4

=item * L<Data::Perl>

=item * L<Data::Perl::Role::Collection::Number>

=back

=head1 AUTHOR

Matthew Phillips <mattp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Matthew Phillips <mattp@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
==pod

