package Sysync;
use strict;
use Digest::MD5 qw(md5_hex);
use File::Find;
use File::Path;

our $VERSION = '0.35';

=head1 NAME

Sysync - Simplistic system management

=head1 SYNOPSIS

See: http://sysync.nongnu.org/tutorial.html

=head1 METHODS

=head3 new

Creates a new Sysync object.

 my $sysync = Sysync->new({
    sysdir      => '/var/sysync',
    stagedir    => '/var/sysync/stage', # if omitted, appends ./stage to sysdir
    salt_prefix => '', # if omitted, defaults to '$6$'
    log         => $file_handle_for_logging,
 });

=cut

sub new
{
    my ($class, $params) = @_;
    my $self = {
        sysdir        => $params->{sysdir},
        stagedir      => ($params->{stagedir}     || "$params->{sysdir}/stage"),
        stagefilesdir => ($params->{stagefiledir} || "$params->{sysdir}/stage-files"),
        salt_prefix   => (exists($params->{salt_prefix}) ? $params->{salt_prefix} : '$6$'),
        log           => $params->{log},
    };

    bless($self, $class);

    return $self;
}

=head3 log

Log a message.

 $self->log('the moon is broken');

=cut

sub log
{
    my $self = shift;
    my $lt   = localtime;
    my $log  = $self->{log};

    print $log "$lt: $_[0]\n";
}

=head3 sysdir

Returns the base system directory for sysync.

=cut

sub sysdir { shift->{sysdir} }

=head3 stagedir

Returns stage directory.

=cut

sub stagedir { $_[0]->{stagedir} || join('/', $_[0]->sysdir, 'stage' ) }

=head3 stagefilesdir

Returns stage-files directory.

=cut

sub stagefilesdir { $_[0]->{stagefilesdir} || join('/', $_[0]->sysdir, 'stage-files' ) }

=head3 get_user

Returns hashref of user information. It's worth noting that passwords should not be returned here for normal users.

 Example:

 {
   username => 'wafflewizard',
   uid => 1001,
   fullname => 'Waffle E. Wizzard',
   homedir => '/home/wafflewizard',
   shell => '/bin/bash',
   disabled => 0,
   ssh_keys => [
      'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA10YAFEAByOlrMmd5Beh73SOg7okHpK5Bz9dOgmYb4idR3A6iz+ycyXtnCmwSGdmh6AQoeKfJx+9rxLtvdHUzhRa/YejqBGsTwYl5Q+1bKbCkJfgZhtB99Xt5j7grXzrJ0zp2vTfG2mPndnD7xuQQQnLsZrFSoTY8FPvQo3a9R1wPIuxBGs5jWm9+pvluJtAT3I7IaVfylNBCGU8+Fw/qvJtWEesyqyRmFJZ47XzFKJ5EzB6hLaW+MAaCH6fZDycdjiTfJOMThtpFF557rqz5EN76VRqHpnkiqKpatMX4h0hiL/Snl+fbUxOYm5qcHughuis4Sf6xXoABsyz2lsrqiQ== wafflewizard',
   ],
 }

=cut

sub get_user { die 'needs implemented' }

=head3 get_all_users

Return array of all usernames.

=cut

sub get_all_users { die 'needs implemented' }

=head3 get_user_password

Return a user's encrypted password.

=cut

sub get_user_password { die 'needs implemented' }

=head3 set_user_password

Set a user's encrypted password.

=cut

sub set_user_password { die 'needs implemented' }

=head3 get_users_from_group

Returns array of users in a given group.

=cut

sub get_users_from_group { die 'needs implemented' }

=head3 get_all_groups

Returns array of all groups.

=cut

sub get_all_groups { die 'needs implemented' }

=head3 get_all_hosts

Returns all hosts.

=cut

sub get_all_hosts { die 'needs implemented' }

=head3 must_refresh

Returns true if sysync must refresh.

Passing 1 or 0 as an argument sets whether this returns true.

=cut

sub must_refresh { die 'needs implemented' }

=head3 must_refresh_files

Returns true if sysync must refresh managed files.

Passing 1 or 0 as an argument sets whether this returns true.

=cut

sub must_refresh_files { die 'needs implemented' }

=head3 generate_user_line

Generate a line for both the user and shadow file.

=cut

sub generate_user_line
{
    my ($self, $user, $what) = @_;

    my $gid      = $user->{gid} || $user->{uid};
    my $fullname = $user->{fullname} || $user->{username};

    my $password = '*';

    if ($user->{password})
    {
        $password = $user->{password};
    }
    else
    {
        my $p = $self->get_user_password($user->{username});

        $password = $p if $p;
    }

    my $line = q[];
    if ($what eq 'passwd')
    {
        $line = join(':', $user->{username}, 'x', $user->{uid}, $gid,
                     $fullname, $user->{homedir}, $user->{shell});
    }
    elsif ($what eq 'shadow')
    {
        my $password = $user->{disabled} ? '!' : $password;
        $line = join(':', $user->{username}, $password, 15198, 0, 99999, 7, '','','');
    }

    return $line;
}

=head3 generate_group_line

Generate a line for the group file.

=cut

sub generate_group_line
{
    my ($self, $group, $what) = @_;

    my $users = join(',', @{$group->{users} || []}) || '';

    my $line = '';
    if ($what eq 'group')
    {
        $line = join(':', $group->{groupname}, 'x', $group->{gid}, $users);
    }
    elsif ($what eq 'gshadow')
    {
        $line = sprintf('%s:*::%s', $group->{groupname}, $users);
    }
}

=head3 is_valid_host

Returns true if host is valid.

=cut

sub is_valid_host { die 'needs implemented' }

=head3 get_host_user

Given a host, then a username, return a hashref with user details.

=cut

sub get_host_user
{
    my ($self, $host, $username) = @_;

    my $data   = $self->get_host_users_groups($host);
    my @users  = @{$data->{users} || []};

    return (grep { $username eq $_->{username} } @users)[0];
}

=head3 get_host_group

Given a host, then a group name, return a hashref with group details.

=cut

sub get_host_group
{
    my ($self, $host, $groupname) = @_;

    my $data   = $self->get_host_users_groups($host);
    my @groups = @{$data->{groups} || []};

    return (grep { $groupname eq $_->{groupname} } @groups)[0];
}

=head3 get_host_users

Given a host return a hashref with user details.

=cut

sub get_host_users
{
    my ($self, $host, $username) = @_;

    my $data   = $self->get_host_users_groups($host);
    my @users  = @{$data->{users} || []};

    my %u = map { $_->{username} => $_ } @users;

    return \%u;
}

=head3 get_host_groups

Given a host return a hashref with group details.

=cut

sub get_host_groups
{
    my ($self, $host, $groupname) = @_;

    my $data   = $self->get_host_users_groups($host);
    my @groups = @{$data->{groups} || []};

    my %g = map { $_->{groupname} => $_ } @groups;

    return \%g;
}

=head3 get_host_ent

For a generate all of the password data, including ssh keys, for a specific host.

=cut

sub get_host_ent
{
    my ($self, $host) = @_;

    return unless $self->is_valid_host($host);
    
    my $data   = $self->get_host_users_groups($host);
    my @users  = @{$data->{users} || []};
    my @groups = @{$data->{groups} || []};

    my $passwd = join("\n", map { $self->generate_user_line($_, 'passwd') } @users) . "\n";
    my $shadow = join("\n", map { $self->generate_user_line($_, 'shadow') } @users) . "\n";
    my $group  = join("\n", map { $self->generate_group_line($_, 'group',) } @groups) . "\n";
    my $gshadow  = join("\n", map { $self->generate_group_line($_, 'gshadow',) } @groups) . "\n";

    my @ssh_keys;
    for my $user (@users)
    {
        next unless $user->{ssh_keys};

        if ($user->{disabled} and $user->{ssh_keys})
        {
            $_ = "# $_" for @{$user->{ssh_keys}};
            unshift @{$user->{ssh_keys}}, '### ACCOUNT DISABLED VIA SYSYNC';
        }

        my $keys = join("\n", @{$user->{ssh_keys} || []});
        $keys .= "\n" if $keys;

        next unless $keys;

        push @ssh_keys, {
            username => $user->{username},
            keys     => $keys,
            uid      => $user->{uid},
        };
    }

    return {
        passwd   => $passwd,
        shadow   => $shadow,
        group    => $group,
        gshadow  => $gshadow,
        ssh_keys => \@ssh_keys,
        data     => $data,
    };
}

=head3 get_host_files

Generate a list of files with their content.

 Returns hashref:
 '/etc/filename.conf' => {
    mode     => 600,
    gid      => 0,
    uid      => 0,
    data     => 'data is here'
 }

=cut

sub get_host_files { die 'needs implemented' }

=head3 update_host_files

Build host files from specifications.

=cut

sub update_host_files
{
    my ($self, $host) = @_;

    my $stagefilesdir = $self->stagefilesdir;
    my $stagedir      = $self->stagedir;

    my $r = 0;

    next unless $self->is_valid_host($host);
    my $files = $self->get_host_files($host);

    unless (-d "$stagefilesdir/$host")
    {
        mkdir "$stagefilesdir/$host";
        chmod 0755, "$stagefilesdir/$host";
        chown 0, 0, "$stagefilesdir/$host";

        $self->log("creating: $stagefilesdir/$host");
        $r++;
    }

    unless (-d "$stagefilesdir/$host/etc")
    {
        mkdir "$stagefilesdir/$host/etc";
        chmod 0755, "$stagefilesdir/$host/etc";
        chown 0, 0, "$stagefilesdir/$host/etc";

        $self->log("creating: $stagefilesdir/$host/etc");
            $r++;
    }

    unless (-d "$stagefilesdir/$host/etc/ssh")
    {
        mkdir "$stagefilesdir/$host/etc/ssh";
        chmod 0755, "$stagefilesdir/$host/etc/ssh";
        chown 0, 0, "$stagefilesdir/$host/etc/ssh";

        $self->log("creating: $stagefilesdir/$host/etc/ssh");
        $r++;
    }

    unless (-d "$stagefilesdir/$host/etc/ssh/authorized_keys")
    {
        mkdir "$stagefilesdir/$host/etc/ssh/authorized_keys";
        chmod 0755, "$stagefilesdir/$host/etc/ssh/authorized_keys";
        chown 0, 0, "$stagefilesdir/$host/etc/ssh/authorized_keys";

        $self->log("creating: $stagefilesdir/$host/etc/ssh/authorized_keys");
        $r++;
    }

    for my $path (sort keys %{ $files || {} })
    {
        my $item = $files->{$path};
        next unless $item->{directory};

        $item->{directory} =~ s/\/$//;

        next if $item->{directory} eq '/etc';
        next if $item->{directory} eq '/etc/ssh';
        next if $item->{directory} eq '/etc/ssh/authorized_keys';

        $item->{directory} =~ s/^\///;

        my @path_parts = split('/', $item->{directory});
        my $filename   = pop @path_parts;
        my $parent_dir = join('/', @path_parts);

        $item->{file} =~ s/^\///;

        unless (-d "$stagefilesdir/$host/$parent_dir")
        {
            die "[$host: error] parent directory $parent_dir not defined for $item->{directory}\n";
        }

        unless (-d "$stagefilesdir/$host/$item->{directory}")
        {
            mkdir "$stagefilesdir/$host/$item->{directory}";
            $self->log("creating: $stagefilesdir/$host/$item->{directory}");
        }

        my $mode = sprintf("%04i", $item->{mode});
        chmod $mode, "$stagefilesdir/$host/$item->{directory}";
        chown $item->{uid}, $item->{gid}, "$stagefilesdir/$host/$item->{directory}";

        $r++;
    }

    for my $path (keys %{ $files || {} })
    {
        my $item = $files->{$path};
        next unless $item->{file};

        my @path_parts = split('/', $item->{file});

        my $filename   = pop @path_parts;
        my $parent_dir = join('/', @path_parts);

        $item->{file} =~ s/^\///;

        unless (-d "$stagefilesdir/$host/$parent_dir")
        {
            die "[$host: error] directory $parent_dir not defined for $item->{file}\n";
        }

        if ($self->write_file_contents("$stagefilesdir/$host/$item->{file}", $item->{data}))
        {
            $r++;
        }

        my $mode = sprintf("%04i", $item->{mode});

        chmod oct($mode), "$stagefilesdir/$host/$item->{file}";
        chown $item->{uid}, $item->{gid}, "$stagefilesdir/$host/$item->{file}";
    }

    # get list of staging directory contents
    my @staged_file_list;
    File::Find::find({
        wanted   => sub { push @staged_file_list, $_ }, 
        no_chdir => 1,
    }, "$stagefilesdir/$host");

    for my $staged_file (@staged_file_list)
    {
        next unless -e $staged_file;

        (my $local_staged_file = $staged_file) =~ s/^$stagefilesdir\/$host//;
        next unless $local_staged_file;

        next if $local_staged_file eq '/';
        next if $local_staged_file eq '/etc';
        next if $local_staged_file eq '/etc/ssh';
        next if $local_staged_file eq '/etc/ssh/authorized_keys';

        unless ($files->{$local_staged_file})
        {
            if (-d $staged_file)
            {
                $self->log("deleting directory: $staged_file");
                rmtree($staged_file);
            }
            elsif (-e $staged_file)
            {
                $self->log("deleting file: $staged_file");
                unlink($staged_file);
            }
            $r++;
        }
    }

    return $r;
}

=head3 update_all_hosts

Iterate through every host and build password files.

=cut

sub update_all_hosts
{
    my ($self, %params) = @_;

    # get list of hosts along with image name
    my $hosts = $params{hosts} || $self->get_all_hosts;

    # first, build staging directories
    my @hosts = keys %{ $hosts->{hosts} || {} };

    my $stagedir = $self->stagedir;

    my $r = 0;

    for my $host (@hosts)
    {
        next unless $self->is_valid_host($host);

        unless (-d "$stagedir/$host")
        {
            mkdir "$stagedir/$host";
            chmod 0755, "$stagedir/$host";
            chown 0, 0, "$stagedir/$host";
            $self->log("creating: $stagedir/$host");
            $r++;
        }

        unless (-d "$stagedir/$host/etc")
        {
            mkdir "$stagedir/$host/etc";
            chmod 0755, "$stagedir/$host/etc";
            chown 0, 0, "$stagedir/$host/etc";
            $self->log("creating: $stagedir/$host/etc");
            $r++;
        }

        unless (-d "$stagedir/$host/etc/ssh")
        {
            mkdir "$stagedir/$host/etc/ssh";
            chmod 0755, "$stagedir/$host/etc/ssh";
            chown 0, 0, "$stagedir/$host/etc/ssh";
            $self->log("creating: $stagedir/$host/etc/ssh");
            $r++;
        }

        unless (-d "$stagedir/$host/etc/ssh/authorized_keys")
        {
            mkdir "$stagedir/$host/etc/ssh/authorized_keys";
            chmod 0755, "$stagedir/$host/etc/ssh/authorized_keys";
            chown 0, 0, "$stagedir/$host/etc/ssh/authorized_keys";
            $self->log("creating: $stagedir/$host/etc/ssh/authorized_keys");
            $r++;
        }

        # write host files
        my $ent_data = $self->get_host_ent($host);

        next unless $ent_data;

        for my $key (@{ $ent_data->{ssh_keys} || [] })
        {
            my $username = $key->{username};
            my $uid      = $key->{uid};
            my $text     = $key->{keys};

            if ($self->write_file_contents("$stagedir/$host/etc/ssh/authorized_keys/$username", $text))
            {
                chmod 0600, "$stagedir/$host/etc/ssh/authorized_keys/$username";
                chown $uid, 0, "$stagedir/$host/etc/ssh/authorized_keys/$username";
                $r++;
            }
        }

        my ($shadow_group) =
            grep { $_->{groupname} eq 'shadow' }
                @{ $ent_data->{data}{groups} || [ ] };

        $shadow_group = {} unless defined $shadow_group;
        $shadow_group = $shadow_group->{gid} || 0;

        if ($self->write_file_contents("$stagedir/$host/etc/passwd", $ent_data->{passwd}))
        {
            chmod 0644, "$stagedir/$host/etc/passwd";
            chown 0, 0, "$stagedir/$host/etc/passwd";
            $r++;
        }

        if ($self->write_file_contents("$stagedir/$host/etc/group", $ent_data->{group}))
        {
            chmod 0644, "$stagedir/$host/etc/group";
            chown 0, 0, "$stagedir/$host/etc/group";
            $r++;
        }

        if ($self->write_file_contents("$stagedir/$host/etc/shadow", $ent_data->{shadow}))
        {
            chmod 0640, "$stagedir/$host/etc/shadow";
            chown 0, $shadow_group, "$stagedir/$host/etc/shadow";
            $r++;
        }
 
       if ($self->write_file_contents("$stagedir/$host/etc/gshadow", $ent_data->{gshadow}))
        {
            chmod 0640, "$stagedir/$host/etc/gshadow";
            chown 0, $shadow_group, "$stagedir/$host/etc/gshadow";
            $r++;
        }
   }

    return $r;
}

=head3 write_file_contents

=cut

sub write_file_contents
{
    my ($self, $file, $data) = @_;

    # check to see if this differs

    if (-e $file)
    {
        if (md5_hex($data) eq md5_hex($self->read_file_contents($file)))
        {
            return;
        }
    }

    $self->log("writing: $file");

    if (-e $file)
    {
        unlink($file) or die $!;
    }

    open(F, "> $file") or die $!;
    print F $data;
    close(F);

    return 1;
}

=head3 read_file_contents

=cut

sub read_file_contents
{
    my ($self, $file, %params) = @_;

    die "error: $file does not exist\n"
        if $params{must_exist} and not -f $file;

    return unless -e $file;

    open(my $fh, $file);
    my @content = <$fh>;
    close($fh);

    return join('', @content);
}

1;


=head1 COPYRIGHT

L<Bizowie|http://bizowie.com/> L<cloud erp|http://bizowie.com/solutions/>

=head1 LICENSE

 Copyright (C) 2012, 2013 Bizowie

 This file is part of Sysync.
 
 Sysync is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.
 
 Sysync is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.
 
 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Michael J. Flickinger, C<< <mjflick@gnu.org> >>

=cut

