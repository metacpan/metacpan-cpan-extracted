package MooseX::Lexical::Types::TypedScalar;
our $VERSION = '0.01';


use strict;
use warnings;
use Carp qw/confess/;
use Variable::Magic qw/wizard cast/;
use namespace::autoclean;

my $wiz = wizard
    data => sub { $_[1]->get_type_constraint },
    set  => sub {
        if (defined (my $msg = $_[1]->validate(${ $_[0] }))) {
            confess $msg;
        }
        ();
    };

sub TYPEDSCALAR {
    cast $_[1], $wiz, $_[0];
    ();
}

1;

__END__
=head1 NAME

MooseX::Lexical::Types::TypedScalar

=head1 VERSION

version 0.01

=head1 AUTHOR

  Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

