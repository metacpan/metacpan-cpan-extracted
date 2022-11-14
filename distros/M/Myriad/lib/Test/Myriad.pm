package Test::Myriad;

use strict;
use warnings;

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use IO::Async::Loop;
use Future::Utils qw(fmap0);
use Future::AsyncAwait;
use Check::UnitCheck;
use Object::Pad qw(:experimental);

use Myriad;
use Myriad::Service::Implementation;
use Test::Myriad::Service;

use Log::Any::Adapter;

our @REGISTERED_SERVICES;

my $loop = IO::Async::Loop->new();
my $myriad = Myriad->new();

=head1 NAME

Myriad::Test - a collection of helpers to test microservices.

=head1 SYNOPSIS

 use Test::Myriad;

 my $mock_service = add_service(name => 'mocked_service');

=head1 DESCRIPTION

A mini utility to help developers testing myriad services.

it can create completely fake services or mock already
existing ones.

It uses the L<Myriad::Transport::Memory> by default to change that
you can set the environment variable MYRIAD_TEST_TRANSPORT

=head1 Methods

=head2 add_service

Adds a service to the test environment the service can be
an already existing service or totally a new mocked one.

it takes one of the following params:

=over 4

=item * C<service> - A package name for an existing service.

=item * C<name> - A Perl package name that will hold the new mocked service.

=back

=cut

sub add_service {
    my ($self, %args) = @_;
    my ($pkg, $meta);
    if (my $service = delete $args{service}) {
        $pkg = $service;
        $meta = Object::Pad::MOP::Class->for_class($service);
    } elsif ($service = delete $args{name}) {
        die 'The name should look like a Perl package name' unless $service =~ /::/;
        $pkg  = $service;
        $meta = Object::Pad::MOP::Class->begin_class($pkg, extends => 'Myriad::Service::Implementation');

        {
            no strict 'refs';
            push @{$pkg . '::ISA' }, 'Myriad::Service';
            $Myriad::Service::SLOT{$pkg} = {
                map { $_ => $meta->add_field('$' . $_) } qw(api)
            };
        }
    }

    push @REGISTERED_SERVICES, $pkg;

    return Test::Myriad::Service->new(meta => $meta, pkg => $pkg, myriad => $myriad);
}

=head2 ready

Returns a L<Future> indicate that test env
is ready to be used.

at the moment it is just a shortcut for L<Myriad> run_future.

=cut

sub ready {
    return $myriad->run_future;
}

=head2 instance

Returns the L<Myriad> instance we are using

=cut

sub instance {
    return $myriad;
}

sub import {
    my $self = shift;;
    Check::UnitCheck::unitcheckify(sub {
        $myriad->configure_from_argv(('--transport', $ENV{MYRIAD_TEST_TRANSPORT} // 'memory', 'service'))->get();

        # Override logger
        Log::Any::Adapter->set('TAP', filter => 'info');

        $loop->later(sub {
            (fmap0 {
                $myriad->add_service($_);
            } foreach => [@REGISTERED_SERVICES])->then(sub {
                return $myriad->run;
            })->on_fail(sub {
                my $error = shift;
                die "Failed to start the test environment due: $error";
            })->retain;
        });
    });
}

1;

__END__

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020. Licensed under the same terms as Perl itself.

