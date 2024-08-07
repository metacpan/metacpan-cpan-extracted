package RxPerl::Extras;

use strict;
use warnings;

use RxPerl::Operators::Creation 'rx_observable', 'rx_timer';
use RxPerl::Operators::Pipeable 'op_map', 'op_take';

use Exporter 'import';
our @EXPORT_OK = qw/
    op_exhaust_all_with_latest op_exhaust_map_with_latest
    op_throttle_time_with_both_leading_and_trailing
    op_throttle_with_both_leading_and_trailing
/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = "v0.0.3";

sub op_exhaust_all_with_latest {
    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my $active_subscription;
            my $big_completed;
            my $own_subscription = RxPerl::Subscription->new;

            my ($owed_val, $val_is_owed);
            my $helper_sub;

            $subscriber->subscription->add(
                \$active_subscription,
                $own_subscription,
                sub { undef $helper_sub }, # break ref cycle
            );

            $helper_sub = sub {
                my ($new_obs) = @_;

                !$active_subscription or do {
                    $owed_val = $new_obs;
                    $val_is_owed = 1;
                    return;
                };

                $active_subscription = RxPerl::Subscription->new;
                my $small_subscriber = {
                    new_subscription => $active_subscription,
                    next             => sub {
                        $subscriber->{next}->(@_) if defined $subscriber->{next};
                    },
                    error            => sub {
                        $subscriber->{error}->(@_) if defined $subscriber->{error};
                    },
                    complete         => sub {
                        undef $active_subscription;
                        if ($val_is_owed) {
                            $val_is_owed = 0;
                            $helper_sub->($owed_val);
                        } else {
                            $subscriber->{complete}->() if $big_completed and defined $subscriber->{complete};
                        }
                    },
                };
                $new_obs->subscribe($small_subscriber);
            };

            my $own_subscriber = {
                new_subscription => $own_subscription,
                next             => $helper_sub,
                error            => sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
                complete         => sub {
                    $big_completed = 1;
                    $subscriber->{complete}->() if !$active_subscription and defined $subscriber->{complete};
                },
            };

            $source->subscribe($own_subscriber);

            return;
        });
    }
}

sub op_exhaust_map_with_latest {
    my ($observable_factory) = @_;

    return sub {
        my ($source) = @_;

        return $source->pipe(
            op_map($observable_factory),
            op_exhaust_all_with_latest(),
        );
    };
}

sub op_throttle_time_with_both_leading_and_trailing {
    my ($duration) = @_;

    return op_throttle_with_both_leading_and_trailing(sub { rx_timer($duration) });
}

sub op_throttle_with_both_leading_and_trailing {
    my ($duration_selector) = @_;

    return sub {
        my ($source) = @_;

        return rx_observable->new(sub {
            my ($subscriber) = @_;

            my ($owed_val, $val_is_owed);
            my ($helper_sub, $mini_subscriber, $mini_subscription);

            my $own_subscription = RxPerl::Subscription->new;

            $subscriber->subscription->add(
                $own_subscription,
                \$mini_subscription,
                sub { undef $helper_sub }, # break ref cycle
            );

            $mini_subscriber = {
                error    => sub {
                    $subscriber->{error}->(@_) if defined $subscriber->{error};
                },
                complete => sub {
                    undef $mini_subscription;
                    if ($val_is_owed) {
                        $val_is_owed = 0;
                        $helper_sub->($owed_val);
                    }
                },
            };

            $helper_sub = sub {
                my ($v) = @_;

                if ($mini_subscription) {
                    $owed_val = $v;
                    $val_is_owed = 1;
                } else {
                    $mini_subscription = do { local $_ = $v; $duration_selector->($v) }->pipe(
                        op_take(1),
                    )->subscribe($mini_subscriber);
                    $subscriber->{next}->(@_) if defined $subscriber->{next};
                }
            };

            my $own_subscriber = {
                new_subscription => $own_subscription,
                %$subscriber,
                next => $helper_sub,
                complete => sub {
                    $subscriber->{next}->($owed_val), $val_is_owed = 0 if $val_is_owed and defined $subscriber->{next};
                    $subscriber->{complete}->() if defined $subscriber->{complete};
                },
            };

            $source->subscribe($own_subscriber);

            return;
        });
    };
}


1;
__END__

=encoding utf-8

=head1 NAME

RxPerl::Extras - original extra operators for RxPerl

=head1 SYNOPSIS

    use RxPerl::Mojo qw/ ... /; # RxPerl::IOAsync and RxPerl::AnyEvent also possible
    use RxPerl::Extras 'op_exhaust_map_with_latest'; # or ':all'

    # (pause 5 seconds) 0, (pause 5 seconds) 2, complete
    rx_timer(0, 2)->pipe(
        op_take(3),
        op_exhaust_map_with_latest(sub ($val, @) {
            return rx_of($val)->pipe( op_delay(5) );
        }),
    )->subscribe($observer);

=head1 DESCRIPTION

RxPerl::Extras is a collection of original L<RxPerl> operators not found in RxJS,
which the author thinks might be useful to many.

It currently contains four pipeable operators.

=head1 EXPORTABLE FUNCTIONS

The code samples in this section assume C<$observer> has been set to:

    $observer = {
        next     => sub {say "next: ", $_[0]},
        error    => sub {say "error: ", $_[0]},
        complete => sub {say "complete"},
    };

=head2 PIPEABLE OPERATORS

=over

=item op_exhaust_all_with_latest

See L</op_exhaust_map_with_latest>.

    # (pause 5 seconds) 0, (pause 5 seconds) 2, complete
    rx_timer(0, 2)->pipe(
        op_take(3),
        op_map(sub { rx_of($_)->pipe( op_delay(5) ) }),
        op_exhaust_all_with_latest(),
    )->subscribe($observer);

=item op_exhaust_map_with_latest

Works like RxPerl's L<op_exhaust_map|RxPerl/op_exhaust_map>, except if any new next events arrive before exhaustion,
the latest of those events will be processed after exhaustion as well.

    # (pause 5 seconds) 0, (pause 5 seconds) 2, complete
    rx_timer(0, 2)->pipe(
        op_take(3),
        op_exhaust_map_with_latest(sub ($val, @) {
            return rx_of($val)->pipe( op_delay(5) );
        }),
    )->subscribe($observer);

=item op_throttle_time_with_both_leading_and_trailing

Immediately emits events received if none have been emitted during the past C<$duration>,
but if during the next C<$duration> seconds after emitting, some next events are received,
the latest one of those will be emitted after C<$duration>.

    # 0, (pause 3 seconds) 4, complete
    rx_timer(0, 0.7)->pipe(
        op_throttle_time_with_both_leading_and_trailing(3),
        op_take(2),
    )->subscribe($observer);

=item op_throttle_with_both_leading_and_trailing

    # 0, (pause 3 seconds) 4, complete
    rx_timer(0, 0.7)->pipe(
        op_throttle_with_both_leading_and_trailing(sub ($val) { rx_timer(3) }),
        op_take(2),
    )->subscribe($observer);

=back

=head1 NOTIFICATIONS FOR NEW RELEASES

You can start receiving emails for new releases of this module, at L<https://perlmodules.net>.

=head1 COMMUNITY CODE OF CONDUCT

L<RxPerl's Community Code of Conduct|RxPerl::CodeOfConduct> applies to this module too.

=head1 LICENSE

Copyright (C) 2024 Alexander Karelas.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Alexander Karelas E<lt>karjala@cpan.orgE<gt>

=cut
