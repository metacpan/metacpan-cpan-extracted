=head1 NAME

Synapse::CLI::Logger - yet another logging mechanism


=head1 About Synapse's Open Telephony Toolkit

L<Synapse::Logger> is a part of Synapse's Wholesale Open Telephony
Toolkit.

As we are refactoring our codebase, we at Synapse have decided to release a
substantial portion of our code under the GPL. We hope that as a developer, you
will find it as useful as we have found open source and CPAN to be of use to
us.


=head1 What is L<Synapse::Logger> all about

Does what it says on the tin.


=head1 SYNOPSIS

    use Synapse::Logger;
    logger ("some stuff");            # uses $0 as logname...
    logger (logname => "some stuff"); # specifies logname...

Or on the command-line

    synapse-logger logname "some stuff"


=head1 API

=cut
package Synapse::Logger;
use base qw /Exporter/;
use warnings;
use strict;

our @EXPORT    = qw(logger);


=head2 GLOBALS

=over 4

=item $Synapse::Logger::VERSION - library version number

=item $Synapse::Logger::BASE_DIR - points to the directory where logfiles live.

=back

=cut
our $VERSION  = 0.1;
our $BASE_DIR = $ENV{LOGGER_BASEDIR} || "/var/log/synapse/";



sub base_dir {
    -e $BASE_DIR or mkdir $BASE_DIR;
    return $BASE_DIR;
}


sub logname {
    local $_ = $0;
    s/[^a-z0-9]/-/gi;
    s/\-+/-/g;
    s/^\-//;
    s/\-$//;
    return $_;
}


=head2 logger($message)

Exported function that logs stuff.

=cut
sub logger {
    my ($logname, $message) = @_ == 1 ? (Synapse::Logger::logname(), shift()) : @_;
    my $file = Synapse::Logger::base_dir() . "/$logname.log";
    my $date = scalar gmtime;
    open LOGFILE, ">>$file" or return;
    print LOGFILE "$date\t$message\n"; 
    close LOGFILE;
}



1;


__END__

=head1 EXPORTS

function logger()


=head1 BUGS

Please report them to me. Patches always welcome...


=head1 AUTHOR

Jean-Michel Hiver, jhiver (at) synapse (dash) telecom (dot) com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
