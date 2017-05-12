package Sledge::Plugin::Stash;
use strict;
use warnings;
our $VERSION = '0.04';
use Carp;
use 5.008001;

sub import {
    my $pkg = caller(0);

    {
        no strict 'refs'; ## no critic

        *{"$pkg\::stash"} = sub :lvalue {
            my ($self, ) = @_;
            $self->{stash};
        };
    }

    $pkg->add_trigger(
        AFTER_INIT => sub {
            my $self = shift;
            $self->stash = {};
        },
    );

    $pkg->add_trigger(
        BEFORE_OUTPUT => sub {
            my $self = shift;
            $self->tmpl->param( %{ $self->stash } );
        }
    );
}

1;
__END__

=head1 NAME

Sledge::Plugin::Stash - sledge with lvalue.

=head1 SYNOPSIS

    package Your::Pages;
    use Sledge::Plugin::Stash;

    sub dispatch_foo {
        my ($self, ) = @_;
        $self->stash->{foo} = 'bar';
    }

    # in your template.
    [% foo %]

=head1 DESCRIPTION

    $self->tmpl->param('foo' => 'bar');

is not visceral.

Let's use the lvalue.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Tokuhiro Matsuno  C<< <tokuhirom @at gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Tokuhiro Matsuno C<< <tokuhiro __at__ mobilefactory.jp> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

