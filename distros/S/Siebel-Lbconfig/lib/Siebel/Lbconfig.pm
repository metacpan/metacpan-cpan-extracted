package Siebel::Lbconfig;
use strict;
use warnings;
use Siebel::Srvrmgr::Daemon::Light 0.27;
use Siebel::Srvrmgr::Daemon::Command 0.27;
use Set::Tiny 0.03;
use Siebel::Srvrmgr::Util::IniDaemon 0.27 qw(create_daemon);
use Config::IniFiles 2.88;
use Carp;
use Exporter 'import';
use File::Spec;
use Cwd;
use Siebel::Lbconfig::Daemon::Action::ListServers;
use Siebel::Lbconfig::Daemon::Action::AOM;

our $VERSION = '0.003'; # VERSION

=pod

=head1 NAME

Siebel::Lbconfig - helper to generate an optimized F<lbconfig.txt> file

=head1 DESCRIPTION

The distribution Siebel-Lbconfig was created based on classes from L<Siebel::Srvrmgr>.

The command line utility C<lbconfig> will connect to a Siebel Enterprise with C<srvrmgr> and generate a optimized
F<lbconfig.txt> file by search all active AOMs that take can take advantage of the native load balancer.

=cut

our @EXPORT_OK = qw(recover_info get_daemon create_files);

=head1 FUNCTIONS

=head2 create_daemon

Creates a L<Siebel::Srvrmgr::Daemon> to connects to the Siebel Enterprise and retrieve the required information to create the F<lbconfig.txt>.

It expects as parameters:

=over

=item *

A string of the complete path to a configuration file that is understandle by L<Config::Tiny> (a INI file).

=back

Check the section "Configuration file" of this Pod for details about how to create and maintain the INI file.

Return two values:

=over

=item *

The daemon instance

=item * 

A L<Siebel::Srvrmgr::Daemon::ActionStash> instance.

=back

=head2 get_daemon

Expects the path to a INI file as parameter.

Returns an instance of L<Siebel::Srvrmgr::Daemon> subclass configured in the INI file.

=cut

sub get_daemon {
    my $cfg_file = shift;
    my $daemon   = create_daemon($cfg_file);

# LoadPreferences does not add anything into ActionStash, so it's ok use a second action here
    $daemon->push_command(
        Siebel::Srvrmgr::Daemon::Command->new(
            {
                command => 'list comp',
                action  => 'Siebel::Lbconfig::Daemon::Action::AOM'
            }
        )
    );
    $daemon->push_command(
        Siebel::Srvrmgr::Daemon::Command->new(
            {
                command => 'list servers',
                action  => 'Siebel::Lbconfig::Daemon::Action::ListServers'
            }
        )
    );
    my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();
    return $daemon, $stash;
}

=head2 recover_info

Expects as parameter the L<Siebel::Srvrmgr::Daemon::ActionStash> instance returned by C<create_daemon> and
the Siebel Connection Broker TCP port.

Returns a hash array reference with all the rows data of the F<lbconfig.txt>.

=cut

sub recover_info {
    my ( $stash, $scb_port ) = @_;
    my @data;
    my $comps_ref   = $stash->shift_stash();
    my $servers_ref = $stash->shift_stash();
    my $underscore  = qr/_/;
    my @sorted      = sort( keys( %{$comps_ref} ) );

    foreach my $comp_alias (@sorted) {
        my $virtual;

        if ( $comp_alias =~ $underscore ) {
            my @parts = split( '_', $comp_alias );
            $parts[0] =~ s/ObjMgr//;
            $virtual = $parts[0] . uc( $parts[1] ) . '_VS';
        }
        else {
            $virtual = $comp_alias . '_VS';
        }

        my @row;

        foreach my $server ( @{ $comps_ref->{$comp_alias} } ) {

            if ( exists( $servers_ref->{$server} ) ) {
                push(
                    @row,
                    (
                            $servers_ref->{$server} . ':'
                          . $server . ':'
                          . $scb_port
                    )
                );
            }
            else {
                confess
                  "'$server' is not part of the retrieved Sievel Server names!";
            }
        }

        push(
            @data,
            {
                comp_alias => $comp_alias,
                vs         => $virtual,
                servers    => ( join( ';', @row ) . ';' )
            }
        );
    }

    return \@data;
}

=head2 create_files

Creates the F<lbconfig.txt> and F<eapps*.cfg> files.

Expects as parameters the directory where the F<eapps*.cfg> file will be located. Those files will be used as templates, they will be copied to a new version of them,
with the C<ConnectionString> modified and all other content as is. The copied will have the C<.new> file "extension" attached to them.

Also, espects a data reference passed as the second parameter. The expected format is the same returned by the C<recover_info> sub.

Returns nothing. The F<lbconfig.txt> file will be located at the current directory.

=cut

sub create_files {
    my ( $dir, $data_ref ) = @_;
    my $lbconfig = File::Spec->catfile( getcwd(), 'lbconfig.txt' );
    open( my $out, '>', $lbconfig ) or confess "Cannot create $lbconfig: $!";
    my %aliases;

    foreach my $row ( @{$data_ref} ) {
        print $out $row->{vs}, '=', $row->{servers}, "\n";
        $aliases{ $row->{comp_alias} } = $row->{vs};
    }

    close($out);

    my $pattern    = File::Spec->catfile( $dir, 'eapps*.cfg' );
    my @eapps      = glob($pattern);
    my $conn_regex = qr#^ConnectString#;
    my $replace_regex =
      qr#^(ConnectString\s?\=\s?siebel\.TCPIP\.\w+\.\w+\://)\w+(/\w+/)(\w+)#;
    foreach my $file (@eapps) {
        my $new = "$file.new";
        open( my $old, '<', $file ) or confess "Cannot read $file: $!";
        open( my $out, '>', $new )  or confess "Cannot create $new: $!";

        while (<$old>) {

    #ConnectString = siebel.TCPIP.None.None://VirtualServer/foobar/ERMObjMgr_chs
            if ( $_ =~ $conn_regex ) {
                chomp();

                if ( $_ =~ $replace_regex ) {

                    if ( exists( $aliases{$3} ) ) {
                        print $out $1, $aliases{$3}, $2, $3, "\n";
                    }
                    else {
                        print $out $_, "\n";
                    }

                }
                else {
                    print $out $_, "\n";
                }

            }
            else {
                print $out $_;
            }

        }

        close($old);
        close($out);

    }
}

=head1 CONFIGURATION FILE

The configuration file must have a INI format, which is supported by the L<Config::Tiny> module.

Here is an example of the required parameters:

    [GENERAL]
    gateway=foobar:1055
    enterprise=MyEnterprise
    user=sadmin
    password=123456
    srvrmgr= /foobar/bin/srvrmgr
    load_prefs = 1
    type = light
    time_zone = America/Sao_Paulo

Beware that the commands executed by C<lbconfig> requires that the output has a specific configuration set: setting
C<load_prefs> is not optional here, but a requirement!

Also make sure to use C<type = light> because this distribution really doesn't need L<Siebel::Srvrmgr::Daemon::Heavy> and is
intended to work on MS Windows too.

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr>

=item *

L<Config::Tiny>

=item *

L<Siebel::Srvrmgr::Util::IniDaemon>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
