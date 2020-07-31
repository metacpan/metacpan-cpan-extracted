use strict;
use warnings;
package RT::Extension::AuditLog;

our $VERSION = '0.02';

=head1 NAME

RT-Extension-AuditLog - Log all RT access requests

=head1 DESCRIPTION

In some environments, there are auditing requirements regarding access 
to the data in tickets. Modifications are already well preserved in the
transaction history of a ticket, but read access is not tracked by native
RT facilities.

There is the webserver log, but that does not include the user-name
in all cases.

=head1 RT VERSION

Tested with RT 4.4.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions.

I recommend you check if the two files were really installed into the right directory.

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::AuditLog');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

This module is configures by setting the following options in the 
RT configuration file (C<RT_SiteConfig.pm> or a new file under 
C<RT_SiteConfig.d>):

    Set($AuditLogToFileNamed, 'audit.log');
    Set($AuditLogToSyslog, 'Audit');        # "ident" parameter to Log::Dispatch::Syslog

=head1 AUTHOR

Otmar Lendl E<lt>lendl@cert.atE<gt>

(based on input received on the RT Dev forum:
https://forum.bestpractical.com/t/audit-log-for-user-read-activity/35137 )

=for html <p>All bugs should be reported via email to <a
href="mailto:lendl@cpan.org">lendl@cpan.org</a>.

=for text
    All bugs should be reported via email to
        bug-RT-Extension-AuditLog@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-AuditLog

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by nic.at GmbH

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


# most code taken from lib/RT.pm InitLogging()
sub Init {
    my $Config = $RT::Config;
    my $VarPath = $RT::VarPath;
    unless ( $RT::AuditLogger ) {
        $RT::AuditLogger = Log::Dispatch->new;

	my $file_cb = sub {
	    no warnings;
            my %p = @_;

	    # Encode to bytes, so we don't send wide characters
	    $p{message} = Encode::encode("UTF-8", $p{message});
	    
	    $p{'message'} =~ s/(?:\r*\n)+$//;
	    return gmtime(time) . " ". $p{'message'}. "\n";
	};

        if ( $Config->Get('AuditLogToFileNamed') ) {
            my ($filename, $logdir) = (
                $Config->Get('AuditLogToFileNamed') || 'rt-audit.log',
                $Config->Get('LogDir') || File::Spec->catdir( $VarPath, 'log' ),
            );
            if ( $filename =~ m![/\\]! ) { # looks like an absolute path.
                ($logdir) = $filename =~ m{^(.*[/\\])};
            }
            else {
                $filename = File::Spec->catfile( $logdir, $filename );
            }

            unless ( -d $logdir && ( ( -f $filename && -w $filename ) || -w $logdir ) ) {
                # localizing here would be hard when we don't have a current user yet
                die "Log file '$filename' couldn't be written or created.\n RT can't run.";
            }

            require Log::Dispatch::File;
            $RT::AuditLogger->add( Log::Dispatch::File->new( 
                    name=>'file',
                    min_level=> 'debug',
                    filename=> $filename,
                    mode=>'append',
                    callbacks => [ $file_cb ],
             ));
        }

        if ( $Config->Get('AuditLogToSyslog') ) {
            require Log::Dispatch::Syslog;
            $RT::AuditLogger->add(Log::Dispatch::Syslog->new( 
                name => 'syslog',
                ident => $Config->Get('AuditLogToSyslog'),
                min_level => 'debug'),
            );
        }
    }
}

Init();
1;
