package Neovim::RPC::API;
our $AUTHORITY = 'cpan:YANICK';
$Neovim::RPC::API::VERSION = '0.2.0';
use 5.10.0;

use strict;
use warnings;

use Moose::Role;

use Neovim::RPC::API::Command;

use List::AllUtils qw/ any /;

with 'MooseX::Role::Loggable';

has "rpc" => (
    isa => 'Neovim::RPC',
    is => 'ro',
    required => 1,
);

has channel_id => (
    is => 'rw',
    isa => 'Int',
);

has commands => (
    traits => [ 'Array' ],
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
    handles => {
        _push_command => 'push',
        all_commands => 'elements',
    },
);

has types => (
    is => 'ro',
    default => sub{ {} },
);

sub print_commands {
    my( $self ) = @_;

    for my $c ( sort { $a->name cmp $b->name } $self->all_commands ) {
        say $c->name, ' ( ', join( ', ', map { join ' ', @$_ } $c->all_parameters ) , ' ) -> ',
            $c->return_type; 
    }

}

sub has_command {
    my( $self, $command ) = @_;
    return any { $_->{name} eq $command } $self->all_commands;
}

sub add_command {
    my( $self, $command ) = @_;

    $command->{api} = $self;

    my $c = Neovim::RPC::API::Command->new($command);
    $self->_push_command($c);

    $self->meta->add_method( $c->name => sub {
        shift;
        my @args = @_;

        my $struct = $c->args_to_struct(@args);

        $self->rpc->request( $c->name => $struct);
    })

}


sub export_dsl {
    my $self = shift;
    my $interactive = shift;

    my $class = caller;

    for my $command ( $self->all_commands ) {
        my $name = $command->name;

        eval qq! 
            sub ${class}::$name { 
                my \$p =\$self->$name(\@_);
                return unless \$interactive;
                \$self->rpc->loop(\$p);
                \$p->is_done ? \$p->get : warn \$p->failure; 
            }
        !;
    }
    
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neovim::RPC::API

=head1 VERSION

version 0.2.0

=head1 METHODS

=head2 export_dsl( $interactive )

Exports all the api commands as functions in the current namespace. 

    $rpc->api->export_dsl;

    vim_set_current_line( "hello there!" );

If C<$interactive> is set to C<true>, the function will also
C<$rpc->loop()> until the response is received from the editor.
The result of the response promise will then be returned (or, if there was a problem, the error message will be I<warn>ed).

    $rpc->api->export_dsl(1);

    vim_get_current_line->on_done(
        vim_set_current_line( scalar reverse shift );
    );

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
