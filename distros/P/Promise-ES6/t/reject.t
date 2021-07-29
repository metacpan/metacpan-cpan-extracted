package t::reject;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;

use parent qw(Test::Class);
use Test::Deep;
use Test::More;
use Test::FailWarnings;

use Promise::ES6;

sub reject : Tests(1) {
    Promise::ES6->reject('oh my god')->then(sub {
        die;
    }, sub {
        my ($reason) = @_;
        is $reason, 'oh my god';
    });

    return;
}

sub reject_undef : Tests(2) {
    my @warnings;

    local $SIG{'__WARN__'} = sub { push @warnings, @_ };

    Promise::ES6->reject(undef)->catch( sub {
        my @args= @_;

        is_deeply( \@args, [undef], 'undef given to reject callback' );
    } );

    my $this_file = __FILE__;

    cmp_deeply( \@warnings, [
        all(
            re( qr<initialized> ),
            re( qr<\Q$this_file\E> ),
        ),
    ], 'warning happens' );
}

sub reject_nothing : Tests(2) {
    my @warnings;

    local $SIG{'__WARN__'} = sub { push @warnings, @_ };

    Promise::ES6->reject()->catch( sub {
        my @args= @_;

        is_deeply( \@args, [undef], 'undef given to reject callback' );
    } );

    cmp_deeply( \@warnings, [ re( qr<.> ) ], 'warning happens' );
}

sub reject_undef_via_callback : Tests(2) {
   my @warnings;

    local $SIG{'__WARN__'} = sub { push @warnings, @_ };

    Promise::ES6->new( sub { $_[1]->(undef) } )->catch( sub {
        my @args= @_;

        is_deeply( \@args, [undef], 'undef given to reject callback' );
    } );

    cmp_deeply( \@warnings, [ re( qr<.> ) ], 'warning happens' );
}

sub reject_nothing_via_callback : Tests(2) {
    my @warnings;

    local $SIG{'__WARN__'} = sub { push @warnings, @_ };

    Promise::ES6->new( sub { $_[1]->(undef) } )->catch( sub {
        my @args= @_;

        is_deeply( \@args, [undef], 'undef given to reject callback' );
    } );

    cmp_deeply( \@warnings, [ re( qr<.> ) ], 'warning happens' );
}

sub reject_promise : Tests(2) {
    my ($self) = @_;

    my $p2 = Promise::ES6->resolve(123);

  SKIP: {
        skip 'Devel::Cover causes memory leaks here.', $self->num_tests() if $INC{'Devel/Cover.pm'};

        my $reason;

        Promise::ES6->reject($p2)->catch( sub {
            $reason = shift;
        } );

        is( $reason, $p2, 'reject() - promise as rejection is literal rejection value' );

        Promise::ES6->new( sub { $_[1]->($p2) } )->catch( sub {
            $reason = shift;
        } );

        is( $reason, $p2, 'callback - promise as rejection is literal rejection value' );
    }

    return;
}

__PACKAGE__->runtests;
