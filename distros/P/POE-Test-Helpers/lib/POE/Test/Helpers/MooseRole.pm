use strictures 1;
package POE::Test::Helpers::MooseRole;
BEGIN {
  $POE::Test::Helpers::MooseRole::VERSION = '1.11';
}
# ABSTRACT: A Moose role for POE::Test::Helpers for MooseX::POE

use Carp;
use Test::Deep         qw( cmp_bag bag );
use Test::Deep::NoTest qw( eq_deeply );
use List::AllUtils     qw( none );
use Test::More;
use Moose::Role;
use POE::Session; # for POE variables
use POE::Test::Helpers;

has 'object' => (
    is         => 'ro',
    isa        => 'POE::Test::Helpers',
    lazy_build => 1,
    handles    => [ 'reached_event', 'check_all_counts' ],
);

has 'tests'       => ( is => 'ro', isa => 'HashRef', required => 1         );
has 'params_type' => ( is => 'ro', isa => 'Str',     default  => 'ordered' );

sub _build_object {
    my $self   = shift;
    my $object = POE::Test::Helpers->new(
        run         => sub {1},
        tests       => $self->tests,
        params_type => $self->params_type,
    );
}

before 'STARTALL' => sub {
    my $self  = shift;
    my $class = ref $self;

    $self->reached_event(
        name  => '_start',
        order => 0,
    );

    my $count = 1;
    my @subs_to_override = keys %{ $self->object->{'tests'} };

    foreach my $event (@subs_to_override) {
        $event eq '_start' || $event eq '_stop' and next;

        Moose::Meta::Class->initialize($class)->add_before_method_modifier(
            $event => sub {
                my $self = $_[OBJECT];
                $self->reached_event(
                    name   => $event,
                    order  => $count++,
                    params => [ @_[ ARG0 .. $#_ ] ],
                );
            }
        );
    }
};

after 'STOPALL' => sub {
    my $self = shift;
    my $order = $self->object->{'events_order'}             ?
                scalar @{ $self->object->{'events_order'} } :
                0;

    $self->reached_event(
        name  => '_stop',
        order => $order,
    );

    $self->check_all_counts;
};

no Moose::Role;
1;



=pod

=head1 NAME

POE::Test::Helpers::MooseRole - A Moose role for POE::Test::Helpers for MooseX::POE

=head1 VERSION

version 1.11

=head1 SYNOPSIS

This provides a L<Moose> role for any L<MooseX::POE> applications.

    package MySession;
    use MooseX::POE;
    with 'POE::Test::Helpers::MooseRole';

    has '+tests' => ( default => sub { {
        next => { count => 1 },
        last => { count => 1, deps => ['next'] },
    } } );

    event 'START' => sub {
        $_[KERNEL]->yield('next');
    };

    event 'next' => sub {
        $_[KERNEL]->yield('last');
    };

    event 'last' => sub {
        ...
    };

    package main;
    use Test::More tests => 3;
    use POE::Kernel;
    MySession->new();
    POE::Kernel->run();

    ...

In order to use it, you must consume the role (using I<with>) and then change
the following attributes.

=head1 Attributes

=head2 tests

This is a hash reference that includes all the tests you want to run. You should
read the documentation in L<POE::Test::Helpers> to understand what are the
accepted formats.

Here are some examples:

    has '+tests' => ( default => sub { {
        hello => { count  => 1         },
        there => { params => ['hello'] },
        world => {
            count  => 2,
            params => ['hello'],
        },
    } } );

=head2 params_type

This is a simple string which controls how the event_params will go. Meanwhile
it can only be set to "ordered" and "unordered". This might change in the
future, be warned.

Basically this means that you don't care about the order of how the parameters
get there, but only that whenever the event was run, it had one of the sets of
parameters.

=head1 AUTHOR

Sawyer, C<< <xsawyerx at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-poe-test-simple at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Test-Helpers>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Test::Helpers

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Test-Helpers>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Test-Helpers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Test-Helpers>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Test-Helpers/>

=back

=head1 ACKNOWLEDGEMENTS

I owe a lot of thanks to the following people:

=over 4

=item * Chris (perigrin) Prather

Thanks for all the comments and ideas. Thanks for L<MooseX::POE>!

=item * Rocco (dngor) Caputo

Thanks for the input and ideas. Thanks for L<POE>!

=item * #moose and #poe

Really great people and constantly helping me with stuff, including one of the
core principles in this module.

=back

=head1 AUTHOR

  Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

