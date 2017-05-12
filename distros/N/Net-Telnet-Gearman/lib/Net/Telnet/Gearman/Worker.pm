package Net::Telnet::Gearman::Worker;

use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/file_descriptor ip_address client_id functions/);

sub parse_line {
    my ( $package, $line ) = @_;

    my ( $fd, $ip, $cid, $col, @functions ) = split /\s+/, $line;

    return $package->new(
        {
            file_descriptor => $fd,
            ip_address      => $ip,
            client_id       => $cid,
            functions       => [@functions],
        }
    );
}

=head1 NAME

Net::Telnet::Gearman::Worker

=head1 SYNOPSIS

    use Net::Telnet::Gearman;
    
    my $session = Net::Telnet::Gearman->new(
        Host => '127.0.0.1',
        Port => 4730,
    );
    
    my @workers = $session->workers();
    
    print Dumper @workers
    
    # $VAR1 = bless(
    #     {
    #         'client_id'       => '-',
    #         'file_descriptor' => '1',
    #         'functions'       => [ 'resize_image' ],
    #         'ip_address'      => '127.0.0.1'
    #     },
    #     'Net::Telnet::Gearman::Worker'
    # );

=head1 METHODS

=head2 file_descriptor

Returns the file descriptor of this worker.

=head2 ip_address

Returns the ip address this worker is connected from.

=head2 client_id

Returns the client id of this worker.

=head2 functions

Returns an arrayref of functions the worker is registered for.

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
