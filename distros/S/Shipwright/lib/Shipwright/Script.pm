package Shipwright::Script;
use strict;
use warnings;
use App::CLI;
use Shipwright::Util;
use base qw/App::CLI Shipwright::Base/;

__PACKAGE__->mk_accessors(qw/repository log_file log_level/);

=head2 alias
=cut

sub alias {
    return (
        ls         => 'list',
        del        => 'delete',
        up         => 'update',
        init       => 'create',
        initialize => 'create',
    );
}

=head2 global_options

=cut

sub global_options {
    (
        'r|repository=s' => 'repository',
        'l|log-level=s'  => 'log_level',
        'log-file=s'     => 'log_file',
    );
}

=head2 prepare
=cut

sub prepare {
    my $self = shift;
    $ARGV[0] = 'help' unless @ARGV;

    if ( $ARGV[0] =~ /--?h(elp)?/i ) {
        $ARGV[0] = 'help';
    }
    elsif ( $ARGV[0] =~ /^(-v|--version|version)$/ ) {
        print( "This is Shipwright, version $Shipwright::VERSION" . "\n" );
        exit 0;
    }

    my $action = $ARGV[0];

    my $cmd = $self->SUPER::prepare(@_);

    unless ( ref $cmd eq 'Shipwright::Script::Help' ) {
        $cmd->repository( $ENV{SHIPWRIGHT_SHIPYARD} )
          if !$cmd->repository && $ENV{SHIPWRIGHT_SHIPYARD};
        $cmd->repository( $ENV{SHIPWRIGHT_REPOSITORY} )
          if !$cmd->repository && $ENV{SHIPWRIGHT_REPOSITORY};
        if ( $cmd->repository ) {
            require Shipwright::Backend;
            my $backend = Shipwright::Backend->new(
                repository        => $cmd->repository,
                no_sync_local_dir => 1,
            );

            # this $shipwright object will do nothing, except for init logging
            my $shipwright = Shipwright->new(
                repository => $cmd->repository,
                log_level  => $cmd->log_level,
                log_file   => $cmd->log_file,
            );
            confess_or_die 'invalid repository: '
              . $cmd->repository
              unless $backend->check_repository(
                action => $action,
                $action eq 'create' ? ( force => $cmd->force ) : ()
              );
        }
        else {
            confess_or_die "need repository arg\n";
        }
    }
    return $cmd;
}

=head2 log
=cut

sub log {
    my $self = shift;

    # init logging is done in prepare, no need to init here, just returns logger
    return Log::Log4perl->get_logger( ref $self );
}

1;

__END__

=head1 NAME

Shipwright::Script - Base class and dispatcher for commands

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2007-2015 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

