package Test::SharedFork;
use strict;
use warnings;
use base 'Test::Builder::Module';
our $VERSION = '0.35';
use Test::Builder 0.32; # 0.32 or later is needed
use Test::SharedFork::Scalar;
use Test::SharedFork::Array;
use Test::SharedFork::Store;
use Config;
use 5.008000;

{
    package #
        Test::SharedFork::Contextual;

    sub call {
        my $code = shift;
        my $wantarray = [caller(1)]->[5];
        if ($wantarray) {
            my @result = $code->();
            bless {result => \@result, wantarray => $wantarray}, __PACKAGE__;
        } elsif (defined $wantarray) {
            my $result = $code->();
            bless {result => $result, wantarray => $wantarray}, __PACKAGE__;
        } else {
            { ; $code->(); } # void context
            bless {wantarray => $wantarray}, __PACKAGE__;
        }
    }

    sub result {
        my $self = shift;
        if ($self->{wantarray}) {
            return @{ $self->{result} };
        } elsif (defined $self->{wantarray}) {
            return $self->{result};
        } else {
            return;
        }
    }
}

my $STORE;

sub _mangle_builder {
    my $builder = shift;

    if( $] >= 5.008001 && $Config{useithreads} && $INC{'threads.pm'} ) {
        die "# Current version of Test::SharedFork does not supports ithreads.";
    }

    if ($builder->can("coordinate_forks")) {
        # Use Test::Builder's implementation.
        $builder->new->coordinate_forks(1);
    } elsif($INC{'Test2/Global.pm'} || $INC{'Test2/API.pm'} || $INC{'Test2/Context.pm'}) {
        require Test2::Global;

        Test2::Global::test2_ipc_enable_polling();

        # Check if we already have IPC
        my $stack = $builder->{Stack};
        return if $stack->top->ipc;

        # Find a driver
        my ($driver) = Test2::Global::test2_ipc_drivers();
        unless ($driver) {
            require Test2::IPC::Driver::Files;
            $driver = 'Test2::IPC::Driver::Files';
        }

        # Add the IPC to all hubs
        my $ipc = $driver->new();
        for my $hub (@$stack) {
            $hub->set_ipc($ipc);
            $ipc->add_hub($hub->hid);
        }
    } elsif($INC{'Test/Stream/Sync.pm'}) {
        require Test::Stream::IPC;
        Test::Stream::IPC->import('poll');
        Test::Stream::IPC->enable_polling if Test::Stream::IPC->can('enable_polling');
        my $stack = $builder->{Stack};
        return if $stack->top->ipc;
        my ($driver) = Test::Stream::IPC->drivers;
        my $ipc = $driver->new();
        for my $hub (@$stack) {
            $hub->set_ipc($ipc);
            $ipc->add_hub($hub->hid);
        }
    } else {
        # older Test::Builder
        $STORE = Test::SharedFork::Store->new(
            cb => sub {
                my $store = shift;
                tie $builder->{Curr_Test}, 'Test::SharedFork::Scalar',
                    $store, 'Curr_Test';
                tie $builder->{Is_Passing}, 'Test::SharedFork::Scalar',
                    $store, 'Is_Passing';
                tie @{ $builder->{Test_Results} },
                    'Test::SharedFork::Array', $store, 'Test_Results';
            },
            init => +{
                Test_Results => $builder->{Test_Results},
                Curr_Test    => $builder->{Curr_Test},
                Is_Passing   => 1,
            },
        );

        # make methods atomic.
        no strict 'refs';
        no warnings 'redefine';
        no warnings 'uninitialized';
        for my $name (qw/ok skip todo_skip current_test is_passing/) {
            my $orig = *{"Test::Builder::${name}"}{CODE};
            *{"Test::Builder::${name}"} = sub {
                local $Test::Builder::Level = $Test::Builder::Level + 1;
                local $Test::Builder::BLevel = $Test::Builder::BLevel + 1;
                my $lock = $STORE->get_lock(); # RAII
                $orig->(@_);
            };
        };
    }
}

BEGIN {
    my $builder = __PACKAGE__->builder;
    _mangle_builder($builder);
}

{
    # backward compatibility method
    sub parent { }
    sub child  { }
    sub fork   { fork() }
}

1;
__END__

=for stopwords slkjfd yappo konbuizm

=head1 NAME

Test::SharedFork - fork test

=head1 SYNOPSIS

    use Test::More tests => 200;
    use Test::SharedFork;

    my $pid = fork();
    if ($pid == 0) {
        # child
        ok 1, "child $_" for 1..100;
    } elsif ($pid) {
        # parent
        ok 1, "parent $_" for 1..100;
        waitpid($pid, 0);
    } else {
        die $!;
    }

=head1 DESCRIPTION

Test::SharedFork is utility module for Test::Builder.

This module makes L<fork(2)> safety in your test case.

This module merges test count with parent process & child process.

=head1 LIMITATIONS

This version of the Test::SharedFork does not support ithreads, because L<threads::shared> conflicts with L<Storable>.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom  slkjfd gmail.comE<gt>

yappo

=head1 THANKS TO

kazuhooku

konbuizm

=head1 SEE ALSO

L<Test::TCP>, L<Test::Fork>, L<Test::MultiFork>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
