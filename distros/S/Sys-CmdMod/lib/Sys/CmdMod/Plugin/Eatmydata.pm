package Sys::CmdMod::Plugin::Eatmydata;
{
  $Sys::CmdMod::Plugin::Eatmydata::VERSION = '0.18';
}
BEGIN {
  $Sys::CmdMod::Plugin::Eatmydata::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: CmdMod plugin for eatmydata

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use Sys::ForkAsync;

extends 'Sys::CmdMod::Plugin';

has '_init_ok' => (
    'is'      => 'rw',
    'isa'     => 'Bool',
    'default' => 0,
);

sub _init_priority { return 0; }

sub BUILD {
    my $self = shift;

    if ( -x $self->binary() ) {
        return 1;
    }
    else {
        die( 'Could not find eatmydata executable at ' . $self->binary() );
    }
}

sub _init_binary {
    my $self = shift;

    return $self->_find_binary('eatmydata');
}

sub cmd {
    my $self = shift;
    my $cmd  = shift;

    # we only want sync to be called later if eatmydata was actually used ...
    $self->_init_ok(1);

    return $self->binary() . q{ } . $cmd;
}

sub DEMOLISH {
    my $self = shift;

    # dirty hack, as long as Proc::ProcessTable is broken ...
    my $syncs_running = qx(ps x | grep sys-cmdmod-eatmydata-sync | grep -v grep | wc -l);
    chomp($syncs_running);

    # run 'sync' in background
    if ( $self->_init_ok() && !$syncs_running ) {
        #say 'Scheduling a background sync ...';
        my $FA  = Sys::ForkAsync::->new({
            'setsid'    => 1,
            'name'      => 'sys-cmdmod-eatmydata-sync',
            'redirect_output' => 1,
        });
        my $sub = sub {
            sleep 1;
            system('sync');
        };
        $FA->dispatch($sub);
    } else {
        #say 'NOT scheduling a background sync. Already one running ...';
    }

    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sys::CmdMod::Plugin::Eatmydata - CmdMod plugin for eatmydata

=head1 METHODS

=head2 BUILD

Detect binary and initialize this module.

=head2 DEMOLISH

If this module was successfully initialized in BUILD this will run an async 'sync'.

=head2 cmd

Return this modules command prefix.

=head1 NAME

Sys::CmdMod::Plugin::Eatmydata - Abstract base class for command modifier

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
