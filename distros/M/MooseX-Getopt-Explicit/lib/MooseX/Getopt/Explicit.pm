## no critic (RequireUseStrict)
package MooseX::Getopt::Explicit;
$MooseX::Getopt::Explicit::VERSION = '0.03';
## use critic (RequireUseStrict)
use Moose::Role;

with 'MooseX::Getopt';

around _compute_getopt_attrs => sub {
    my ( $orig, $self, @args ) = @_;

    my @attrs = $self->$orig(@args);

    return grep {
        $_->does('MooseX::Getopt::Meta::Attribute::Trait')
    } @attrs;
};

1;

=pod

=encoding UTF-8

=head1 NAME

MooseX::Getopt::Explicit - MooseX::Getopt, but without implicit option generation [DEPRECATED]

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Moose;
  with 'MooseX::Getopt::Explicit';

  has foo => (
    is => 'rw',
  ); # Does *not* cause a Getopt option to be generated!

  has bar => (
    is     => 'ro'
    isa    => 'Str',
    traits => ['Getopt'],
  ); # *Does* cause a Getopt option to be generated!

=head1 DESCRIPTION

B<NOTE> I didn't know about L<MooseX::Getopt::Strict> when I wrote this; use
that instead!

L<MooseX::Getopt> is nice, but I don't care for how it creates a command
line option for every attribute in my classes unless explicitly overridden.
So this role does the opposite: it requires C<traits =E<gt> ['Getopt']> in
order for a command line option to be generated.

=head1 SEE ALSO

L<MooseX::Getopt>

L<MooseX::Getopt::Strict> - when using this, give attributes
a C<Getopt> metaclass if you want it to get a command-line option.

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hoelzro/moosex-getopt-explicit/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__END__

# ABSTRACT: MooseX::Getopt, but without implicit option generation [DEPRECATED]

