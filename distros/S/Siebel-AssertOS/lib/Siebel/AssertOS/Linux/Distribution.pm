package Siebel::AssertOS::Linux::Distribution;

use 5.006000;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw( distribution_name distribution_version );

our $VERSION = "0.07";

our $release_files_directory = '/etc';
our $standard_release_file   = 'lsb-release';

our %release_files = (
    'gentoo-release'        => 'gentoo',
    'fedora-release'        => 'fedora',
    'centos-release'        => 'centos',
    'enterprise-release'    => 'oracle enterprise linux',
    'turbolinux-release'    => 'turbolinux',
    'mandrake-release'      => 'mandrake',
    'mandrakelinux-release' => 'mandrakelinux',
    'debian_version'        => 'debian',
    'debian_release'        => 'debian',
    'SuSE-release'          => 'suse',
    'knoppix-version'       => 'knoppix',
    'yellowdog-release'     => 'yellowdog',
    'slackware-version'     => 'slackware',
    'slackware-release'     => 'slackware',
    'redflag-release'       => 'redflag',
    'redhat-release'        => 'redhat',
    'redhat_version'        => 'redhat',
    'conectiva-release'     => 'conectiva',
    'immunix-release'       => 'immunix',
    'tinysofa-release'      => 'tinysofa',
    'trustix-release'       => 'trustix',
    'adamantix_version'     => 'adamantix',
    'yoper-release'         => 'yoper',
    'arch-release'          => 'arch',
    'libranet_version'      => 'libranet',
    'va-release'            => 'va-linux',
    'pardus-release'        => 'pardus',
    'system-release'        => 'amazon',
);

our %version_match = (
    'gentoo'  => 'Gentoo Base System release (.*)',
    'debian'  => '(.+)',
    'suse'    => 'VERSION = (.*)',
    'fedora'  => 'Fedora(?: Core)? release (\d+) \(',
    'redflag' => 'Red Flag (?:Desktop|Linux) (?:release |\()(.*?)(?: \(.+)?\)',
    'redhat'  => 'Red Hat(?: Enterprise)? Linux(?: Server)? release (.*) \(',
    'oracle enterprise linux' => 'Enterprise Linux Server release (.+) \(',
    'slackware'               => '^Slackware (.+)$',
    'pardus'                  => '^Pardus (.+)$',
    'centos'                  => '^CentOS(?: Linux)? release (.+) \(',
    'scientific'              => '^Scientific Linux release (.+) \(',
    'amazon'                  => 'Amazon Linux AMI release (.+)$',
);

sub new {
    my %self = (
        'DISTRIB_ID'          => '',
        'DISTRIB_RELEASE'     => '',
        'DISTRIB_CODENAME'    => '',
        'DISTRIB_DESCRIPTION' => '',
        'release_file'        => '',
        'pattern'             => ''
    );

    return bless \%self;
}

sub distribution_name {
    my $self = shift || new();
    my $distro;
    if ( $distro = $self->_get_lsb_info() ) {
        return $distro if ($distro);
    }

    foreach (qw(enterprise-release fedora-release)) {
        if ( -f "$release_files_directory/$_"
            && !-l "$release_files_directory/$_" )
        {
            if ( -f "$release_files_directory/$_"
                && !-l "$release_files_directory/$_" )
            {
                $self->{'DISTRIB_ID'}   = $release_files{$_};
                $self->{'release_file'} = $_;
                return $self->{'DISTRIB_ID'};
            }
        }
    }

    foreach ( keys %release_files ) {
        if ( -f "$release_files_directory/$_"
            && !-l "$release_files_directory/$_" )
        {
            if ( -f "$release_files_directory/$_"
                && !-l "$release_files_directory/$_" )
            {
                if ( $release_files{$_} eq 'redhat' ) {
                    foreach my $rhel_deriv ( 'centos', 'scientific', ) {
                        $self->{'pattern'}      = $version_match{$rhel_deriv};
                        $self->{'release_file'} = 'redhat-release';
                        if ( $self->_get_file_info() ) {
                            $self->{'DISTRIB_ID'}   = $rhel_deriv;
                            $self->{'release_file'} = $_;
                            return $self->{'DISTRIB_ID'};
                        }
                    }
                    $self->{'pattern'} = '';
                }
                $self->{'release_file'} = $_;
                $self->{'DISTRIB_ID'}   = $release_files{$_};
                return $self->{'DISTRIB_ID'};
            }
        }
    }
    undef;
}

sub distribution_version {
    my $self = shift || new();
    my $release;
    return $release if ( $release = $self->_get_lsb_info('DISTRIB_RELEASE') );
    if ( !$self->{'DISTRIB_ID'} ) {
        $self->distribution_name() or die 'No version because no distro.';
    }
    $self->{'pattern'}         = $version_match{ $self->{'DISTRIB_ID'} };
    $release                   = $self->_get_file_info();
    $self->{'DISTRIB_RELEASE'} = $release;
    return $release;
}

sub _get_lsb_info {
    my $self  = shift;
    my $field = shift || 'DISTRIB_ID';
    my $tmp   = $self->{'release_file'};
    if ( -r "$release_files_directory/" . $standard_release_file ) {
        $self->{'release_file'} = $standard_release_file;
        $self->{'pattern'}      = $field . '=(.+)';
        my $info = $self->_get_file_info();
        if ($info) {
            $self->{$field} = $info;
            return $info;
        }
    }
    $self->{'release_file'} = $tmp;
    $self->{'pattern'}      = '';
    undef;
}

sub _get_file_info {
    my $self = shift;
    open my $fh, '<', "$release_files_directory/" . $self->{'release_file'}
      or die 'Cannot open file: '
      . $release_files_directory . '/'
      . $self->{'release_file'};
    my $info = '';
    local $_;
    while (<$fh>) {
        chomp $_;
        ($info) = $_ =~ m/$self->{'pattern'}/;
        return "\L$info" if $info;
    }
    undef;
}

1;

__END__

=head1 NAME

Siebel::AssertOS::Linux::Distribution - detect if the Linux distribution supports Siebel CRM.

=head1 DESCRIPTION

This module is a copy from L<Linux::Distribution> version 0.22. This had to be done because the original distribution checks in the Makefile.PL
if the operation system trying to install is Linux, which in the case is the correct procedure as described in L<http://wiki.cpantesters.org/wiki/CPANAuthorNotes>.

Unfortunately, L<Siebel::AssertOS> must consider first if the OS is Linux or not, then check other supported OS (if not).

Maybe in the future L<Siebel::AssertOS> can go back only using L<Linux::Distribution> directly.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Linux::Distribution>

=head1 AUTHORS

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel GNU Tools project.

Siebel GNU Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel GNU Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel GNU Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

