package SM::Simulator;

use strict;
use warnings;

use base 'Exporter';
use base 'Sim';

our @EXPORT_OK = qw(log);

sub log {
    my $now = __PACKAGE__->now;
    print "\@$now @_\n";
}

1;
__END__

=head1 NAME

SM::Simulator - Simulator for the SM library

=head1 SYNOPSIS

    use SM;
    my $server = new SM::Server(sub { rand(1) });
    my $handle;
    $handle = sub {
        $server->join_queue(new SM::Client);
        SM::Simulator->schedule(
            SM::Simulator->now + rand(2) => $handle
        );
    };
    SM::Simulator->schedule( 0.0 => $handle );
    SM::Simulator->run(duration => 25.0);

=head1 DESCRIPTION

SM::Simulator subclasses the Sim::Dispatcher class and only provides one
more subroutine, namely, the C<log> sub.

=head1 METHODS

=over

=item C<< CLASS->log($message) >>

Logs the message. currently the logger is just stdout.

=back

=head1 AUTHOR

Agent Zhang E<lt>agentzh@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2006 by Agent Zhang. All rights reserved.

This library is free software; you can modify and/or modify it under the same terms as
Perl itself.

=head1 SEE ALSO

L<Sim::Dispatcher>, L<SM>, L<SM::Server>, L<SM::Simulator>.
