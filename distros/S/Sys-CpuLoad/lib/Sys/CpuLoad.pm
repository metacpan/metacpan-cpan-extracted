package Sys::CpuLoad;

# ABSTRACT: retrieve system load averages

# Copyright (c) 1999-2002 Clinton Wong. All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

use v5.6;

use strict;
use warnings;

use parent qw(Exporter);

use IO::File;
use XSLoader;

our @EXPORT    = qw();
our @EXPORT_OK = qw(load);

our $VERSION = '0.21';

XSLoader::load 'Sys::CpuLoad', $VERSION;


sub BEGIN {

    my $this = __PACKAGE__;
    my $os   = lc $^O;

    if ( $os =~ /^(darwin|(free|net|open)bsd|linux|solaris|sunos)$/ ) {

        no strict 'refs'; ## no critic (ProhibitNoStrict)

        *{"${this}::load"} = \&_getbsdload;

    }
    elsif ( -r '/proc/loadavg' && $os ne 'cygwin' ) {

        no strict 'refs'; ## no critic (ProhibitNoStrict)

        *{"${this}::load"} = sub {
            my $fh = IO::File->new( '/proc/loadavg', 'r' );
            if ( defined $fh ) {
                my $line = <$fh>;
                $fh->close();
                if ( $line =~ /^(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)/ ) {
                    return ( $1, $2, $3 );
                }
            }
            return undef; ## no critic (ProhibitExplicitReturnUndef)
        };

    }
    else {

        no strict 'refs'; ## no critic (ProhibitNoStrict)

        *{"${this}::load"} = sub {

            local %ENV = %ENV;
            $ENV{'LC_NUMERIC'} =
              'POSIX';    # ensure that decimal separator is a dot

            my $fh = IO::File->new('/usr/bin/uptime|');
            if ( defined $fh ) {
                my $line = <$fh>;
                $fh->close();
                if ( $line =~
                    /(\d+\.\d+)\s*,\s+(\d+\.\d+)\s*,\s+(\d+\.\d+)\s*$/ )
                {
                    return ( $1, $2, $3 );
                }
            }
            return undef; ## no critic (ProhibitExplicitReturnUndef)
        };
    }

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::CpuLoad - retrieve system load averages

=head1 VERSION

version 0.21

=head1 SYNOPSIS

 use Sys::CpuLoad 'load';
 print '1 min, 5 min, 15 min load average: ',
       join(',', load()), "\n";

=head1 DESCRIPTION

This module retrieves the 1 minute, 5 minute, and 15 minute load average
of a machine.

=head1 EXPORTS

=head2 load

This method returns the load average for 1 minute, 5 minutes and 15
minutes as an array.

On Linux, FreeBSD and OpenBSD systems, it will make a call to C<getloadavg>.

If F</proc/loadavg> is available, it will attempt to parse the file.

Otherwise, it will attempt to parse the output of C<uptime>.

On error, it will return an array of C<undef> values.

=head1 SEE ALSO

L<Sys::CpuLoadX>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Sys-CpuLoad>
and may be cloned from L<git://github.com/robrwo/Sys-CpuLoad.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Sys-CpuLoad/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Robert Rothenberg <rrwo@cpan.org>

=item *

Clinton Wong <clintdw@cpan.org>

=back

=head1 CONTRIBUTOR

=for stopwords Vincent Lefèvre

Vincent Lefèvre <vincent@vinc17.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 1999-2002, 2020 by Clinton Wong <clintdw@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
