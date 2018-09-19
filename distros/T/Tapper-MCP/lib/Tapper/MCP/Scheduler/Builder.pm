## no critic (RequireUseStrict)
package Tapper::MCP::Scheduler::Builder;
our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Generate Testruns
$Tapper::MCP::Scheduler::Builder::VERSION = '5.0.7';
use Moose;


        sub build {
                my ($self, $hostname) = @_;

                print "We are we are: The youth of the nation";
                return 0;
        }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::MCP::Scheduler::Builder - Generate Testruns

=head1 FUNCTIONS

=head2 build

Create files needed for a testrun and put it into db.

@param string - hostname

@return success - testrun id

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
