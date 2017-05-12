package MooseX::StrictConstructor::Trait::Method::Constructor;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.21';

use Moose::Role;

use B ();

around _generate_BUILDALL => sub {
    my $orig = shift;
    my $self = shift;

    my $source = $self->$orig();
    $source .= ";\n" if $source;

    my @attrs = ( '__INSTANCE__ => 1,', '__no_BUILD__ => 1,' );
    push @attrs, map { B::perlstring($_) . ' => 1,' }
        grep {defined}
        map  { $_->init_arg() } @{ $self->_attributes() };

    $source .= <<"EOF";
my \%attrs = (@attrs);

my \@bad = sort grep { ! \$attrs{\$_} }  keys \%{ \$params };

if (\@bad) {
    Moose->throw_error("Found unknown attribute(s) passed to the constructor: \@bad");
}
EOF

    return $source;
    }
    if $Moose::VERSION < 1.9900;

1;

# ABSTRACT: A role to make immutable constructors strict

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::StrictConstructor::Trait::Method::Constructor - A role to make immutable constructors strict

=head1 VERSION

version 0.21

=head1 DESCRIPTION

This role simply wraps C<_generate_BUILDALL()> (from
C<Moose::Meta::Method::Constructor>) so that immutable classes have a
strict constructor.

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/moose/MooseX-StrictConstructor/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for MooseX-StrictConstructor can be found at L<https://github.com/moose/MooseX-StrictConstructor>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2007 - 2017 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
