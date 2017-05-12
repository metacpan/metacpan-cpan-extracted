package Plack::Middleware::LightProfile;
$Plack::Middleware::LightProfile::VERSION = '0.002';
use parent qw/Plack::Middleware/;
use Process::SizeLimit::Core;
use Time::HiRes qw/gettimeofday tv_interval/;
use Log::Any qw/$log/;

sub call {
    my ($self, $env) = @_;
    my ($base_memory) = Process::SizeLimit::Core->_check_size();
    my $t0 = [gettimeofday()];
    my $res = $self->app->($env);
    my $duration = tv_interval($t0);
    my ($end_memory) = Process::SizeLimit::Core->_check_size();
    my $memory_consumed = $end_memory - $base_memory;
    $log->infof("response time: %5.3f end memory: %d added memory: %d", $duration, $end_memory, $memory_consumed);
    return $res;
}

1;

__END__

=head1 NAME

Plack::Middleware::LightProfile - A small, lightweight profiler for time and memory as Plack middleware

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Plack::Builder;
    use Log::Any;
    my $app = sub { ... };
    builder {
        enable "LightProfile";
    };

=head1 DESCRIPTION

A little profiler for Plack applications.  All data is sent out over Log::Any at C<info> level.
A lot of this information is available in L<Plack::Middleware::Debug>, but this allows you to
aggregate it over all child processes at once.

These items are logged as a single log line:

=over

=item response time

How long did it take for the app to return a response.  This may include the time for other middleware wrapped by this.

=item end memory

After generating the current response, the amount of memory used by the current process.

=item added memory

How much memory was leaked (added) to the base process making the current response.

=back

=head1 SUPPORT

=over

=item Repository

L<http://github.com/perldreamer/Plack-Middleware-LightProfile>

=item Bug Reports

L<http://github.com/perldreamer/Plack-Middleware-LightProfile>

=back

=head1 DEPENDENCIES

  Log::Any
  Time::HiRes
  Process::SizeLimit::Core

=head1 AUTHOR

Colin Kuskie <colink_at_plainblack_dot_com>

=head1 LEGAL

This module is Copyright 2014 Plain Black Corporation. It is distributed under the same terms as Perl itself. 

=cut
