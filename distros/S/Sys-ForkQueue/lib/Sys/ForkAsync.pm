package Sys::ForkAsync;
{
  $Sys::ForkAsync::VERSION = '0.14';
}
BEGIN {
  $Sys::ForkAsync::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Simple async one-time job

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

# for fork()
use Errno qw(EAGAIN);
use POSIX qw(WNOHANG);

has 'chdir' => (
    'is'      => 'rw',
    'isa'     => 'Str',
    'default' => 0,
);

has 'redirect_output' => (
    'is'      => 'rw',
    'isa'     => 'Bool',
    'default' => 1,
);

has 'close_fhs' => (
    'is'      => 'rw',
    'isa'     => 'Bool',
    'default' => 1,
);

has 'setsid' => (
    'is'      => 'rw',
    'isa'     => 'Bool',
    'default' => 0,
);

has 'name' => (
    'is'    => 'ro',
    'isa'   => 'Str',
);

sub dispatch {
    my $self = shift;

    my $code_ref = shift;
    my $arg_ref  = shift;

    # fork() - see Programming Perl p. 737
  FORK:
    {
        if ( my $pid = fork ) {

            # This is the parent process, child pid is in $pid
        }
        elsif ( defined $pid ) {
            POSIX::setsid() if $self->setsid();    # create own process group
            if ( $self->chdir() && -d $self->chdir() ) {
                chdir( $self->chdir() );
            }
            elsif ( $self->chdir() ) {
                chdir(q{/});
            }
            # DGR: what should i do? just ignore it ...
            ## no critic (RequireCheckedClose)
            close(STDIN);
            if ( $self->redirect_output() ) {
                close(STDOUT);
                close(STDERR);
            }
            ## use critic
            ## no critic (RequireCheckedOpen ProhibitUnixDevNull)
            open( STDIN, '<', '/dev/null' );
            if ( $self->redirect_output() ) {
                open( STDOUT, '>', '/dev/null' );
                open( STDERR, '>', '/dev/null' );
            }
            ## use critic
            # close any other filehandles (DBI, etc.)
            # STDIN - 0
            # STDOUT - 1
            # STDERR - 2
            # those were handled above ... now take care of the rest
            if ( $self->close_fhs() ) {
                ## no critic (ProhibitMagicNumbers)
                foreach my $i ( 3 .. 255 ) {
                    POSIX::close($i);
                }
                ## use critic
            }

            # $pid is null, if defined
            # This is the child process
            # get the pid of the parent via getppid
            ## no critic (ProhibitPunctuationVars)
            my $pid  = $$;
            ## use critic
            my $ppid = getppid();

            $0 = $self->name() if $self->name();

            my $t0     = time();                                  # starttime
            my $status = &{$code_ref}( 'ForkAsync', $arg_ref );
            my $d0     = time() - $t0;                            # duration
            if ($status) {
                exit 0;
            }
            else {
                exit 1;
            }

            # end of fork(). The child _must_ exit here!
        }
        ## no critic (ProhibitPunctuationVars ProhibitMagicNumbers)
        elsif ( $! == EAGAIN ) {
            # EAGAIN, probably temporary fork error
            sleep 5;
            redo FORK;
        }
        ## use critic
        else {

            # Strange fork error
            ## no critic (ProhibitPunctuationVars)
            warn 'Can not exec fork: '.$!."\n";
            ## use critic
        }
    }    # FORK
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sys::ForkAsync - Simple async one-time job

=head1 SYNOPSIS

    use Sys::ForkAsync;
    my $Mod = Sys::ForkAsync::->new();

=head1 DESCRIPTION

Run a system command asynchronous.

=head1 ATTRIBUTES

=head2 chdir

Change to this directory after the fork.

=head2 redirect_output

If set to true the output of the child will
be redirected to /dev/null.

=head2 close_fhs

Close all open filehandles after the fork
to prevent unsynchronized file I/O

=head2 setsid

Create its own process group.

=head2 name

Set the process name to this string, if set.

=head1 METHODS

=head2 dispatch

Run the command in its own fork.

=head2 EAGAIN

Imported from Errno.

1; # End of Linux::ForkAsync

=head1 NAME

Sys::ForkAsync - Run async commands

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
