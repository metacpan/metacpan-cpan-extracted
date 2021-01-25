package Net::OpenVAS;

use warnings;
use strict;
use utf8;
use feature ':5.10';

use base 'Net::OpenVAS::OMP';

our $VERSION = '0.200';

1;
__END__
=head1 NAME

Net::OpenVAS - Perl extension for OpenVAS Scanner

=head1 SYNOPSIS

    use Net::OpenVAS qw( -commands );

    my $openvas = Net::OpenVAS->new(
        host     => 'localhost:9390',
        username => 'admin',
        password => 's3cr3t'
    ) or die "ERROR: $@";

    my $task = $openvas->create_task(
        name   => [ 'Scan created via Net::OpenVAS' ],
        target => { id => 'a800d5c7-3493-4f73-8401-c42e5f2bfc9c' },
        config => { id => 'daba56c8-73ec-11df-a475-002264764cea' }
    );

    if ( $task->is_created ) {

        my $task_id = $task->result->{id};

        say "Created task $task_id";

        my $task_start = $openvas->start_task( task_id => $task_id );

        say "Task $task_id started (" . $task_start->status_text . ')' if ( $task_start->is_accepted );

    }

    if ( $openvas->error ) {
        say "ERROR: " . $openvas->error;
    }

=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the OMP (OpenVAS Management Protocol) of OpenVAS.

For more information about the OPM follow the online documentation:

L<https://docs.greenbone.net/API/OMP/omp.html>


=head2 CLASSES

=over 4

=item * L<Net::OpenVAS> : Wrapper class for L<Net::OpenVAS::OMP>

=item * L<Net::OpenVAS::Error> : Helper error class

=item * L<Net::OpenVAS::OMP> : Provides high-level interface for OpenVAS OMP protocol

=over 4

=item * L<Net::OpenVAS::OMP::Request> : Helper class for OMP request

=item * L<Net::OpenVAS::OMP::Response> : Helper class for OMP response

=back

=back



=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-OpenVAS/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-OpenVAS>

    git clone https://github.com/giterlizzi/perl-Net-OpenVAS.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
