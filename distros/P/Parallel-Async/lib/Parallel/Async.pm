package Parallel::Async;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.03";

use parent qw/Exporter/;
our @EXPORT    = qw/async/;
our @EXPORT_OK = qw/async_task/;

use Parallel::Async::Task;
our $TASK_CLASS = 'Parallel::Async::Task';

sub async_task (&) {## no critic
    my $code = shift;
    return $TASK_CLASS->new(code => $code);
}

# alias
no warnings 'once';
*async = \&async_task;

1;
__END__

=encoding utf-8

=head1 NAME

Parallel::Async - run parallel task with fork to simple.

=head1 SYNOPSIS

    use Parallel::Async;

    my $task = async {
        print "[$$] start!!\n";
        my $msg = "this is run result of pid:$$."; # MSG
        return $msg;
    };

    my $msg = $task->recv;
    say $msg; # same as MSG

=head1 DESCRIPTION

Parallel::Async is yet another fork tool.
Run parallel task with fork to simple.

See also L<Parallel::Async::Task> for more usage.

=head1 SEE ALSO

L<Parallel::ForkManager> L<Parallel::Prefork>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
