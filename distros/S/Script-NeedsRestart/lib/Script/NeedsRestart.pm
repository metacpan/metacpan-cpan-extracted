package Script::NeedsRestart;

use warnings;
use strict;

our $VERSION = '0.02';
our $logger;
our $SLEEP_BEFORE_RESTART = 2;

our @exec_self_cmd = ($^X, (map {'-I' . $_} @INC), $0, @ARGV);

sub _log {return $logger;}
sub set_logger {$logger = $_[1];}

sub restart_if_needed {
    my ($self) = @_;

    if ($self->check_mtimes) {
        sleep($SLEEP_BEFORE_RESTART);
        $self->restart();
    }

    return;
}

sub check_mtimes {
    my ($self) = @_;

    my @files_to_check = ($0, values(%INC));
    foreach my $file (@files_to_check) {
        if ((-f $file) && (-M $file < 0)) {
            $self->_log
                && $self->_log->info('file ' . $file . ' modified');
            return $file;
        }
    }

    return 0;
}

sub restart {
    my ($self) = @_;

    $self->_log
        && $self->_log->debug('exec `' . join(' ', @exec_self_cmd) . '`');

    exec(@exec_self_cmd)
        or die('exec of `' . join(' ', @exec_self_cmd) . '` failed');
}

1;

__END__

=head1 NAME

Script::NeedsRestart - checks mtime of script and it's included files

=head1 SYNOPSIS

    use Script::NeedsRestart;
    Script::NeedsRestart->set_logger($log);       # optional

    while (1) {
        last if Script::NeedsRestart->check_mtimes;
        
        # or
        
        Script::NeedsRestart->restart_if_needed();
        
        # .... do something
        sleep(10);
    }

=head1 DESCRIPTION

File modification time based checking of script and included files.

=head1 FUNCTIONS

=head2 check_mtimes

Scans script file and all included Perl modules in C< %INC > for
modification timestamp and returns true if any of the files have
modification timestamp greater then the script start-up time.

In case scripts running via any of the daemon tools, check can be an
indication when to terminate the loop to initiate auto restarted.

=head2 restart

re-exec current script

=head2 restart_if_needed

will re-exec current script if it or any dependent files changed.

=head2 set_logger

setting optional logger, if set, C< check_mtimes() > and C< restart() >
will will log their events.

    Script::NeedsRestart->set_logger($log);

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
