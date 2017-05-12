package Net::Telnet::Gearman::Function;

use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
use Scalar::Util qw(looks_like_number);

__PACKAGE__->mk_accessors(qw/name queue busy free running/);

sub parse_line {
    my ( $package, $line ) = @_;

    my ( $name, $queue, $busy, $running ) = split /[\s]+/, $line;

    return
      if !looks_like_number($queue)
          || !looks_like_number($busy)
          || !looks_like_number($running);

    my $free = $running - $busy;

    return $package->new(
        {
            name    => $name,
            queue   => $queue,
            busy    => $busy,
            free    => $free,
            running => $running,
        }
    );
}

=head1 NAME

Net::Telnet::Gearman::Function

=head1 SYNOPSIS

    use Net::Telnet::Gearman;
    
    my $session = Net::Telnet::Gearman->new(
        Host => '127.0.0.1',
        Port => 4730,
    );
    
    my @functions = $session->status();
    
    print Dumper @functions
    
    # $VAR1 = bless(
    #     {
    #         'busy'    => 10,
    #         'free'    => 0,
    #         'name'    => 'resize_image',
    #         'queue'   => 74,
    #         'running' => 10
    #     },
    #     'Net::Telnet::Gearman::Function'
    # );

=head1 METHODS

=head2 name

Returns the name of the function.

=head2 queue

Returns the amount of queued jobs for this function.

=head2 busy

Returns the amount of workers currently working on this function.

=head2 free

Returns the amount of free workers that can do this function.

=head2 running

Returns the amount of running workers registered for this function.

=head1 AUTHOR

Johannes Plunien E<lt>plu@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Johannes Plunien

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4 

=item * L<Net::Telnet::Gearman>

=back

=cut

1;
