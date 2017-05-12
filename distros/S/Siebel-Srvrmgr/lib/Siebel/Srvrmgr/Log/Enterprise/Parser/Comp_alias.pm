package Siebel::Srvrmgr::Log::Enterprise::Parser::Comp_alias;

use Moose;
use namespace::autoclean;
use Set::Tiny 0.02;
use Carp qw(cluck confess);
use Siebel::Srvrmgr::Log::Enterprise;

with 'Siebel::Srvrmgr::Comps_source';
our $VERSION = '0.29'; # VERSION

=pod

=head1 NAME

Siebel::Srvrmgr::Log::Enterprise::Parser::Comp_alias - parses of component alias from the Siebel Enterprise log file

=head1 SYNOPSIS

    # see the proc_mon.pl script in the examples directory

=head1 DESCRIPTION

This class implements the L<Siebel::Srvrmgr::Comps_source> Moose Role to recover information from components by reading the Siebel Enterprise log file.

This enables one to create a "cheap" (in the sense of not needing to connect to the Siebel Server) component monitor to recover information about CPU, memory, etc, usage by the Siebel 
components.

=head1 ATTRIBUTES

=head2 process_regex

Required attribute.

A string of the regular expression to match the components PID logged in the Siebel Enterprise log file. The regex should match the text in the sixth "column" (considering
that they are delimited by a character) of a Siebel Enterprise log. Since the Siebel Enterprise may contain different language settings, this parameter is required and 
will depend on the language set.

An example of configuration will help understand. Take your time to review the piece of Enterprise log file below:

    ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	AdminNotify	STARTING	Component is starting up.
    ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	AdminNotify	INITIALIZED	Component has initialized (no spawned procs).
    ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SvrTaskPersist	STARTING	Component is starting up.
    ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9644	) for SRProc
    ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9645	) for FSMSrvr
    ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9651	) for AdminNotify

In this case, the string should be a regular expression something like C<Created\s(multithreaded)?\sserver\sprocess>.

This attribute is a string, not a compiled regular expression with C<qr>.

=cut

has process_regex => (
    is       => 'ro',
    isa      => 'Str',
    reader   => 'get_process_regex',
    required => 1
);

=head2 archive

An optional object instance of a class that uses the L<Moose::Role> L<Siebel::Srvrmgr::Log::Enterprise::Archive>.

An important concept (and the reason for this paragraph) is that the reading of the Siebel Enterprise log file might be restricted or not.

In restricted mode, the Siebel Enterprise log file is read once and the already read component aliases is persisted somehow, including the last line of the file read: that will avoid
reading all over the file again, and more important, minimizing association of reused PIDs with component aliases, thus generating incorrect data.

To use "simple" mode, nothing else is necessary. Simple is much simpler to be used, but there is the risk of PIDs reutilization causing invalid data to be generated. For long running monitoring, 
I suggest using restricted mode.

=cut

has 'archive' => (
    is     => 'ro',
    does   => 'Siebel::Srvrmgr::Log::Enterprise::Archive',
    reader => 'get_archive'
);

=head2 log_path

A string of the complete pathname to the Siebel Enterprise log file.

=cut

has log_path =>
  ( is => 'ro', isa => 'Str', required => 1, reader => 'get_log_path' );

=head1 METHODS

=head2 get_process_regex

Getter for the attribute C<process_regex>.

=cut

=head2 find_comps

Parses the Siebel Enterprise log file by using a instance of a class that implements L<Siebel::Srvrmgr::Log::Enterprise::Archive> Moose Role.

Expects as parameter a hash reference containing as keys the PIDs and as values the respective instances of L<Siebel::Srvrmgr::OS::Process>.

It will return the same reference with the component alias information include when possible.

=cut

sub find_comps {

    my $self  = shift;
    my $procs = shift;

    confess "the processes parameter is required" unless ( defined($procs) );
    confess "must receive an hash reference as parameter"
      unless ( ref($procs) eq 'HASH' );

    foreach my $pid ( keys( %{$procs} ) ) {

        confess
"values of process parameter must be instances of Siebel::Srvrmgr::OS::Process"
          unless ( $procs->{$pid}->isa('Siebel::Srvrmgr::OS::Process') );

    }

    my $enterprise_log = Siebel::Srvrmgr::Log::Enterprise->new(
        { path => $self->get_log_path() } );

    my $create_regex;

    {

        my $regex = $self->get_process_regex;
        $create_regex = qr/$regex/;

    }

    if ( defined( $self->get_archive() ) ) {

        $self->_archived_recover( $procs, $enterprise_log, $create_regex );

    }
    else {

        $self->_recover( $procs, $enterprise_log, $create_regex );

    }

    return $procs;

}

sub _get_last_line {

    my $self = shift;

    return $self->get_archive()->get_last_line();

}

sub _set_last_line {

    my $self  = shift;
    my $value = shift;

    $self->get_archive()->set_last_line($value);

}

sub _delete_old {

    my $self      = shift;
    my $procs_ref = shift;
    my $archived  = $self->get_archive->get_set();
    my $new       = Set::Tiny->new( keys( %{$procs_ref} ) );
    my $to_delete = $archived->difference($new);

    foreach my $pid ( $to_delete->members ) {

        $self->get_archive()->remove($pid);

    }

}

sub _to_add {

    my $self      = shift;
    my $procs_ref = shift;
    my $archived  = $self->get_archive->get_set();
    my $new       = Set::Tiny->new( keys( %{$procs_ref} ) );
    return $new->difference($archived);

}

sub _add_new {

    my $self      = shift;
    my $to_add    = shift;
    my $procs_ref = shift;

    foreach my $pid ( $to_add->members ) {

        $self->get_archive->add( $pid, $procs_ref->{$pid}->get_comp_alias() );

    }

}

sub _recover {

    my $self         = shift;
    my $procs_ref    = shift;
    my $ent_log      = shift;
    my $create_regex = shift;
    my %comps;

    my $next        = $ent_log->read();
    my $field_delim = $ent_log->get_fs();
    local $/ = $ent_log->get_eol();

    # for performance reasons this loop is duplicated in res_find_pid
    while ( my $line = $next->() ) {

        chomp($line);
        my @parts = split( /$field_delim/, $line );
        next unless ( scalar(@parts) >= 7 );

#ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9645	) for FSMSrvr
        if ( $parts[1] eq 'ProcessCreate' ) {

            if ( $parts[5] =~ $create_regex ) {

                $parts[7] =~ s/\s(\w)+\s//;
                $parts[7] =~ tr/)//d;

                # pid => component alias
                $comps{ $parts[6] } = $parts[7];
                next;

            }
            else {

                cluck
"Found a process creation statement but I cannot match process_regex against '$parts[5]'. Check the regex";

            }

        }

    }

    foreach my $proc_pid ( keys( %{$procs_ref} ) ) {

        if ( exists( $comps{$proc_pid} ) ) {

            $procs_ref->{$proc_pid}->set_comp_alias( $comps{$proc_pid} );

        }

    }

}

# restrict find the pid by ignoring previous read line from the Siebel Enterprise log file
sub _archived_recover {

    my $self         = shift;
    my $procs_ref    = shift;
    my $ent_log      = shift;
    my $create_regex = shift;
    my %comps;

    my $next        = $ent_log->read();
    my $field_delim = $ent_log->get_fs();
    $self->get_archive()->validate_archive( $ent_log->get_header() );
    local $/ = $ent_log->get_eol();

    my $last_line = $self->_get_last_line();

    # for performance reasons this loop is duplicated in find_pid
    while ( my $line = $next->() ) {

        next unless ( ( $last_line == 0 ) or ( $. > $last_line ) );
        chomp($line);
        my @parts = split( /$field_delim/, $line );

        next unless ( scalar(@parts) >= 7 );

#ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9645	) for FSMSrvr
        if ( $parts[1] eq 'ProcessCreate' ) {

            if ( $parts[5] =~ $create_regex ) {

                $parts[7] =~ s/\s(\w)+\s//;
                $parts[7] =~ tr/)//d;

                # pid => component alias
                $comps{ $parts[6] } = $parts[7];
                next;

            }
            else {

                cluck
"Found a process creation statement but I cannot match process_regex against '$parts[5]'. Check the regex";

            }

        }

    }

    $self->_set_last_line($.);

# consider that PIDS not available anymore in the /proc are gone and should be removed from the cache
    $self->_delete_old($procs_ref);

    # must keep the pids to add before modifying the procs_ref
    my $to_add = $self->_to_add($procs_ref);
    my $cached = $self->get_archive()->get_set();

    foreach my $proc_pid ( keys( %{$procs_ref} ) ) {

        if ( ( exists( $comps{$proc_pid} ) ) and ( $cached->has($proc_pid) ) ) {

# new reads from log has precendence over the cache, so cache must be also updated
            $procs_ref->{$proc_pid}->set_comp_alias( $comps{$proc_pid} );
            $self->get_archive()->remove($proc_pid);
            next;

        }

        if ( exists( $comps{$proc_pid} ) ) {

            $procs_ref->{$proc_pid}->{comp_alias} = $comps{$proc_pid};

        }
        elsif ( $cached->has($proc_pid) ) {

            $procs_ref->{$proc_pid}->{comp_alias} =
              $self->get_archive()->get_alias($proc_pid);

        }

    }

    $self->_add_new( $to_add, $procs_ref );

}

=head1 SEE ALSO

=over

=item *

L<Moose>

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
