package Siebel::Lbconfig::Daemon::Action::ListServers;

our $VERSION = '0.002'; # VERSION
use Moose 2.0401;
use namespace::autoclean 0.13;
use Siebel::Srvrmgr::Daemon::ActionStash 0.27;
use Carp;
use Scalar::Util qw(blessed);

extends 'Siebel::Srvrmgr::Daemon::Action';

=pod

=head1 NAME

Siebel::Lbconfig::Daemon::Action::ListServers - subclass to information from C<list servers> command

=head1 DESCRIPTION

Siebel::Lbconfig::Daemon::Action::ListServers will simply recover and "return" the output of C<list servers>
command. See C<do_parsed> method for details.

=head1 EXPORTS

Nothing.

=head1 METHODS

This class implements a single method besides the "hidden" C<_build_exp_output>.

=cut

override '_build_exp_output' => sub {
    return 'Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers';
};

=pod

=head2 do_parsed

This method is overriden from parent class.

It expects the parsed output from C<list servers> command.

It returns nothing, but sets the singleton L<Siebel::Srvrmgr::Daemon::ActionStash> with a hash
reference containing the Siebel Server name as key and the respect Server Id as value.

=cut

override 'do_parsed' => sub {
    my ( $self, $obj ) = @_;
    my %servers;

    if ( $obj->isa( $self->get_exp_output ) ) {
        my $iter = $obj->get_servers_iter;

        while ( my $server = $iter->() ) {
            $servers{ $server->get_name } = $server->get_id;
        }

        my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();
        $stash->push_stash( \%servers );
        return 1;

    }
    else {
        confess('object received ISA not '
              . $self->get_exp_output() . ' but '
              . blessed($obj) );
    }

};

__PACKAGE__->meta->make_immutable;
