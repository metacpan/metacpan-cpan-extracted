#!/usr/bin/perl
# Sysync
# 
# Copyright (C) 2012 Ohio-Pennsylvania Software, LLC.
#
# This file is part of sysync.
# 
# sysync is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# 
# sysync is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;

use File::Copy;
use Digest::MD5 qw(md5_hex);
use YAML;

my $sysdir = '/var/sysync';

unless ($< == 0)
{
    warn "may only be ran as root\n";
    exit(0);
}

sub main
{
    unless (-d $sysdir)
    {
        mkdir("$sysdir");
        chmod 0700, "$sysdir";
    }

    mkdir("$sysdir/users")  unless -d "$sysdir/users";
    mkdir("$sysdir/groups") unless -d "$sysdir/groups";
    mkdir("$sysdir/hosts")  unless -d "$sysdir/hosts";
    mkdir("$sysdir/stage/") unless -d "$sysdir/stage";
    mkdir("$sysdir/stage-files/") unless -d "$sysdir/stage-files";
    mkdir("$sysdir/files/") unless -d "$sysdir/files";
    mkdir("$sysdir/keys")   unless -d "$sysdir/keys";
    chmod 0700, "$sysdir/keys";

    unless (-e '/var/sysync/keys/sysync_rsa')
    {
        print "Generating ssh keys for sysync...\n";
        system(q[ssh-keygen -N "" -f /var/sysync/keys/sysync_rsa]);
    }

    print "Installing /usr/sbin/sysync\n";
    copy('./bin/sysync', '/usr/sbin/sysync');
    chmod 0755, '/usr/sbin/sysync';

    print "Installing /usr/sbin/sysyncd\n";
    copy('./bin/sysyncd', '/usr/sbin/sysyncd');
    chmod 0755, '/usr/sbin/sysyncd';

    print "Copying /etc/init.d/sysync\n";
    copy('./defaults/sysync', '/etc/init.d/sysync');
    chmod 0755, '/etc/init.d/sysync';

    print "Adding to init.d...\n";

    # add to rc.d
    # symlink('../init.d/sysync', '/etc/rc0.d/K20sysync');
    # symlink('../init.d/sysync', '/etc/rc1.d/K20sysync');
    # symlink('../init.d/sysync', '/etc/rc2.d/S20sysync');
    # symlink('../init.d/sysync', '/etc/rc3.d/S20sysync');
    # symlink('../init.d/sysync', '/etc/rc4.d/S20sysync');
    # symlink('../init.d/sysync', '/etc/rc5.d/S20sysync');
    # symlink('../init.d/sysync', '/etc/rc6.d/K20sysync');

    copy('./defaults/hosts.conf', "$sysdir/hosts.conf")
        unless -e "$sysdir/hosts.conf";

    copy('./defaults/ssh.conf', "$sysdir/ssh.conf")
        unless -e "$sysdir/ssh.conf";

    copy('./defaults/sysync.conf', "$sysdir/sysync.conf")
        unless -e "$sysdir/sysync.conf";
    
    copy('./defaults/default.conf', "$sysdir/hosts/default.conf")
        unless -e "$sysdir/hosts/default.conf";

    print "Sysync successfully installed.\n";

    return 0;
}

exit __PACKAGE__->main;

