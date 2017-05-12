package Siebel::Srvrmgr::OS::Unix;

use Moose 2.0401;
use Proc::ProcessTable 0.53;
use namespace::autoclean 0.13;
use Set::Tiny 0.02;
use Carp qw(cluck confess);
use Siebel::Srvrmgr::OS::Process;
our $VERSION = '0.29'; # VERSION

=pod

=head1 NAME

Siebel::Srvrmgr::OS::Unix - module to recover information from OS processes of Siebel components

=head1 SYNOPSIS

    use Siebel::Srvrmgr::OS::Unix;
    my $procs = Siebel::Srvrmgr::OS::Unix->new(
        {
            comps_source =>
              Siebel::Srvrmgr::Log::Enterprise::Parser::Comp_alias->new(
                {
                    process_regex => 'Created\s(multithreaded)?\sserver\sprocess', 
                    log_path => $enterprise_log,
                    archive  => Archive->new( { dbm_path => $MY_DBM } )
                }
              ),
            cmd_regex => $siebel_path,
        }
    );

    # hash reference of objects Siebel::Srvrmgr::OS::Process
    my $procs_ref = $procs->get_procs;
    foreach my $comp_pid( keys( %{$procs_ref} ) ) {

        print 'Component ', $procs_ref->{$comp_pid}->{comp_alias}, ' is using ', $procs_ref->{$comp_pid}->{pctcpu}, "% of CPU now\n";

    }

=head1 DESCRIPTION

This module is a L<Moose> class.

It is responsible to recover information from processes executing on a UNIX-like O.S. and merging that with information of Siebel components.

Details on running processes are recovered from C</proc> directory meanwhile the details about the components are read from a class that implements the L<Siebel::Srvrmgr::Comps_source> role.

=head1 ATTRIBUTES

=head2 comps_source

Required attribute.

An instance of a class that implements the Moose Role L<Siebel::Srvrmgr::Comps_source>. Those classes are supposed to recover information about the current modules available in a Siebel Server.

=cut

has comps_source => (
    is       => 'ro',
    does     => 'Siebel::Srvrmgr::Comps_source',
    required => 1,
    reader   => 'get_comps_source'
);

=head2 cmd_regex

Required attribute.

A string of the regular expression to match the command executed by the Siebel user from the C<cmdline> file in C</proc>.
This usually is the path included in the binary when you check with C<ps -aux> command.

This attribute is a string, not a compiled regular expression with C<qr>.

The amount of processes returned will depend on the regular expression used: one can match anything execute by the Siebel 
OS user or only the processes related to the Siebel components.

=cut

has cmd_regex => (
    is       => 'rw',
    isa      => 'Str',
    reader   => 'get_cmd',
    writer   => 'set_cmd',
    required => 1
);

=head2 mem_limit

Optional attribute.

A integer representing the maximum bytes of RSS a Siebel process might have.

If set together with C<limits_callback>, this class can execute some action when this threshold is exceeded.

=cut

has mem_limit => (
    is      => 'rw',
    isa     => 'Int',
    reader  => 'get_mem_limit',
    writer  => 'set_mem_limit',
    default => 0
);

=head2 cpu_limit

Optional attribute.

A integer representing the maximum CPU percentage a Siebel process might have.

If set together with C<limits_callback>, this class can execute some action when this threshold is exceeded.

=cut

has cpu_limit => (
    is      => 'rw',
    isa     => 'Int',
    reader  => 'get_cpu_limit',
    writer  => 'set_cpu_limit',
    default => 0
);

=head2 limits_callback

Optional attribute.

A code reference that will be executed when one of the attributes C<mem_limit> and C<cpu_limit> threshold is exceeded.

This is useful, for example, with you want to set a alarm or something like that.

The code reference will receive a hash reference as parameter which keys and values will depend on the type of limit triggered:

=over

=item *

memory:

    type  => 'memory'
    rss   => <processes RSS>
    vsz   => <process VSZ>
    pid   => <process id>
    fname => <process fname>,
    cmd   => <process cmndline>

=item *

CPU:

    type  => 'cpu'
    cpu   => <process % of cpu>
    pid   => <process id>
    fname => <process fname>
    cmd   => <process cmndline>

=back

=cut

has limits_callback => (
    is     => 'rw',
    isa    => 'CodeRef',
    reader => 'get_callback',
    writer => 'set_callback'
);

=head1 METHODS

=head2 new

To create new instances of Siebel::Srvrmgr::OS::Unix.

The constructor expects a hash reference with the attributes required plus those that are marked as optional.

=head2 get_procs

Searches through C</proc> and and returns an hash reference with the pids as keys and L<Siebel::Srvrmgr::OS::Process> instances as values.

Those instances will be created by merging information from C</proc> and the C<comps_source> attribute instance.

=cut

sub get_procs {

    my $self = shift;
    my $cmd_regex;

    {

        my $regex = $self->get_cmd;
        $cmd_regex = qr/$regex/;

    }

    my $t = Proc::ProcessTable->new( enable_ttys => 0 );

    my %procs;

    for my $process ( @{ $t->table } ) {

        next unless ( $process->cmndline =~ $cmd_regex );

        # :WORKAROUND:22-03-2015 20:54:51:: forcing conversion to number
        my $pctcpu = $process->pctcpu;
        $pctcpu =~ s/\s//;
        $pctcpu += 0;

        $procs{ $process->pid } = Siebel::Srvrmgr::OS::Process->new(
            {
                pid    => $process->pid,
                fname  => $process->fname,
                pctcpu => $pctcpu,
                pctmem => ( $process->pctmem + 0 ),
                rss    => ( $process->rss + 0 ),
                vsz    => ( $process->size + 0 )
            }
        );

        if ( $self->get_mem_limit > 0 ) {

            if (    ( $process->rss > $self->get_mem_limit )
                and ( defined( $self->get_callback ) ) )
            {

                $self->get_callback->(
                    {
                        type  => 'memory',
                        rss   => $process->rss,
                        vsz   => $process->size,
                        pid   => $process->pid,
                        fname => $process->fname,
                        cmd   => $process->cmndline
                    }
                );

            }

        }

        if ( $self->get_cpu_limit > 0 ) {

            if (    ( $process->pctcpu > $self->get_cpu_limit )
                and ( defined( $self->get_callback ) ) )
            {

                $self->get_callback->(
                    {
                        type  => 'cpu',
                        cpu   => $process->pctcpu,
                        pid   => $process->pid,
                        fname => $process->fname,
                        cmd   => $process->cmndline
                    }
                );

            }

        }

    }

    $self->find_comps( \%procs );

    return \%procs;

}

sub find_comps {

    my $self      = shift;
    my $procs_ref = shift;
    $self->get_comps_source()->find_comps($procs_ref);

}

=head1 SEE ALSO

=over

=item *

L<Moose>

=item *

L<Proc::ProcessTable>

=item *

L<Siebel::Srvrmgr::Log::Enterprise::Parser::Comp_alias>

=item *

L<Siebel::Srvrmgr::Comps_source>

=item *

L<Siebel::Srvrmgr::OS::Process>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;
