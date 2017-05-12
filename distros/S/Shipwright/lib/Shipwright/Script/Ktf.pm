package Shipwright::Script::Ktf;

use strict;
use warnings;
use Shipwright::Util;

use base qw/App::CLI::Command Shipwright::Base Shipwright::Script/;
__PACKAGE__->mk_accessors(qw/set delete/);

use Shipwright;
use List::MoreUtils qw/uniq/;

sub options {
    (
        'd|delete' => 'delete',
        's|set=s'  => 'set',
    );
}

sub run {
    my $self  = shift;
    my @names = @_;

    my $shipwright = Shipwright->new( repository => $self->repository, );

    my $ktf = $shipwright->backend->ktf;

    if ( $self->delete || defined $self->set ) {
        confess_or_die "need name arg\n" unless @names;

        if ( $self->delete ) {
            delete $ktf->{$_} for @names;
        }
        if ( defined $self->set ) {
            $ktf->{$_} = $self->set for @names;
        }
        $shipwright->backend->ktf($ktf);
    }

    if ( @names ) {
        $self->_show_ktf( $ktf, $_ ) for @names;
    }
    else {
        $self->_show_ktf( $ktf, $_ ) for sort keys %$ktf;
    }
}

sub _show_ktf {
    my $self = shift;
    my $ktf  = shift;
    my $name = shift;

    if ( $self->delete ) {
        $self->log->fatal( "deleted known test failure for $name" );
    }
    else {
        if ( defined $self->set ) {
            $self->log->fatal(
                "successfully set known test failure condition for $name");
        }

        $self->log->fatal( "the condition of $name is: " . ( $ktf->{$name} || 'undef' ) );
    }
}

1;

__END__

=head1 NAME

Shipwright::Script::Ktf - Maintain known test failure conditions

=head1 SYNOPSIS

 shipwright ktf cpan-DBD-mysql --set '$^O eq "darwin"'

=head1 OPTIONS

 --delete conditions            : delete conditions
 --set conditions               : set conditions

=head1 GLOBAL OPTIONS

 -r [--repository] REPOSITORY   : specify the repository uri of our shipyard
 -l [--log-level] LOGLEVEL      : specify the log level
                                  (info, debug, warn, error, or fatal)
 --log-file FILENAME            : specify the log file


=head1 AUTHORS

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Shipwright is Copyright 2007-2015 Best Practical Solutions, LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

