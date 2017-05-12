package Tapper::MCP::Plugin::Test::All;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::MCP::Plugin::Test::All::VERSION = '5.0.6';
use strict;
use warnings;
use Moose::Role;


sub console_start {
        my ($self) = @_;
        return 'test';
}


sub console_stop {
        my ($self) = @_;
        return 'test';
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::MCP::Plugin::Test::All

=head2 console_start

Empty function for console_start

=head2 console_stop

Empty function for console_stop

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
