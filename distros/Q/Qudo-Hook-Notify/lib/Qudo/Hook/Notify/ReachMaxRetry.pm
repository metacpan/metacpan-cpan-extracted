package Qudo::Hook::Notify::ReachMaxRetry;
use strict;
use warnings;
use base 'Qudo::Hook';

sub hook_point { 'post_work' }

sub load {
    my ($class, $klass) = @_;

    $klass->hooks->{post_work}->{'notify_reach_max_retry'} = sub {
        my $job = shift;

        if ($job->is_failed && ( $job->funcname->max_retries <= ($job->retry_cnt) )) {
            $klass->plugin->{logger}->emergency(
                sprintf('%s already retry max!!',$job->funcname)
            );
        }
    };
}

sub unload {
    my ($class, $klass) = @_;

    delete $klass->hooks->{post_work}->{'notify_reach_max_retry'};
}


1;
__END__

=head1 NAME

Qudo::Hook::Notify::ReachMaxRetry - notify reach job max retry count.

=head1 SYNOPSIS

    $manager->register_hooks(qw/Qudo::Hook::Notify::ReachMaxRetry/);
    $manager->register_plugins(
        +{
            name => 'Qudo::Plugin::Logger',
            option => +{
                dispatchers => ['mail'],
                mail => {
                    class     => 'Log::Dispatch::Email::MIMELite',
                    min_level => 'debug',
                    to        => [ qw/alert@example.com/ ],
                    from      => 'alert@example.com',
                    subject   => 'qudo error!',
                    format    => "[%p] %m\n",
                    buffered  => 0,
                },
            },
        }
    );

=head1 DESCRIPTION

Qudo::Hook::Notify::ReachMaxRetry is notify reach job max retry count. use Qudo::Plugin::Logger.

=head1 AUTHOR

Atsushi Kobayashi E<lt>nekokak _at_ gmail _dot_ comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

