# -*-perl-*-

################################################################################
#
# $Id: ErrLogger.pm 211 2009-05-25 06:05:50Z aijaz $
#
################################################################################

=head1 NAME

TaskForest::ErrLogger - Functions related to logging to stderr

=head1 DOCUMENTATION

This is a class that is used to tie prints to STDERR to $log->error();
See Logger::Log4perl for more details. 

=cut

package TaskForest::ErrLogger;


use strict;
use warnings;
use TaskForest::Logs;
use Log::Log4perl;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '1.30';
}

sub TIEHANDLE {
    my $class = shift;
    bless { log => $TaskForest::Logs::log } , $class;
}

sub PRINT {
    my $self = shift;
    $Log::Log4perl::caller_depth++;
    $self->{log}->error(@_);
    $Log::Log4perl::caller_depth--;
}

1;

