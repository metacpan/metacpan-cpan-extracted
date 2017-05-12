package Sysync::File;
use strict;
use YAML;
use base 'Sysync';

=head1 NAME

Sysync::File - Use Sysync with flat-files on the backend.

=head1 SYNOPSIS

See: http://sysync.nongnu.org/tutorial.html

=head1 METHODS

=head3 get_user_password

Return a user's encrypted password.

=cut


sub get_user_password
{
    my ($self, $username) = @_;
    my $sysdir = $self->sysdir;
    return $self->read_file_contents("$sysdir/users/$username.passwd");
}

=head3 set_user_password

Set a user's password.

=cut

sub set_user_password
{
    my ($self, $username, $passwd) = @_;
    my $sysdir = $self->sysdir;
    open(F, ">$sysdir/users/$username.passwd");
    print F $passwd;
    close(F);

    return 1;
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

sub get_host_files
{
    my ($self, $host) = @_;
    return unless $self->is_valid_host($host);

    my %files;
    my $sysdir = $self->sysdir;
    my $default_host_config = {};
    if (-e "$sysdir/hosts/default.conf")
    {
        $default_host_config = Load($self->read_file_contents("$sysdir/hosts/default.conf"));
    }

    my $default_files = $self->_process_file_block(($default_host_config->{files} || []), $host);

    my $host_config = {};
    if ($self->is_valid_host($host))
    {
        $host_config = Load($self->read_file_contents("$sysdir/hosts/$host.conf"));
    }

    my $host_files = $self->_process_file_block(($host_config->{files} || []), $host);

    my $files = { %$default_files, %$host_files };

    return $files;
}

# returns hashref
#
# '/etc/filename.conf' => {
#    mode     => 600,
#    owner    => root,
#    group    => root,
#    data     => '',
# }
# 

sub _process_file_block
{
    my ($self, $block, $host, $stack) = @_;
    my $sysdir = $self->sysdir;
    $stack = [] unless defined $stack;

    my $users  = $self->get_host_users($host);
    my $groups = $self->get_host_groups($host);


    my %block;

    for my $item (@{$block || []})
    {
        if (my $file = $item->{file})
        {
            if ($item->{directory} or $item->{'import'})
            {
                die "[$host: error] malformed file ($file) item with conflicting types\n";
            }

            if ($item->{source})
            {
                if ($item->{source} =~ /^\//)
                {
                    $item->{data} = $self->read_file_contents($item->{source}, must_exist => 1);
                }
                else # file is localized
                {
                    $item->{data} = $self->read_file_contents("$sysdir/$item->{source}", must_exist => 1);
                }
            }

            my $owner = $users->{$item->{owner}};
            my $group = $groups->{$item->{group}};

            if (not $owner)
            {
                die "[$host: error] Invalid owner ($item->{owner}) for $file\n";
            }
            if (not $group)
            {
                die "[$host: error] Invalid group ($item->{group}) for $file\n";
            }
            if (not $item->{mode})
            {
                die "[$host: error] Mode missing for $file\n";
            }
            $item->{uid} = $owner->{uid};
            $item->{gid} = $group->{gid};

            $block{$file} = $item;
        }
        elsif (my $directory = $item->{directory})
        {
            my $owner = $users->{$item->{owner}};
            my $group = $groups->{$item->{group}};

            if (not $owner)
            {
                die "[$host: error] Invalid owner ($item->{owner}) for $file\n";
            }
            if (not $group)
            {
                die "[$host: error] Invalid group ($item->{group}) for $file\n";
            }
            $item->{uid} = $owner->{uid};
            $item->{gid} = $group->{gid};

            $block{$directory} = $item;
        }
        elsif (my $type = $item->{'import'})
        {
            if ($type eq 'host')
            {
                my $h = $item->{host};

                if ($self->is_valid_host($h))
                {
                    my $fetch_host = Load($self->read_file_contents("$sysdir/hosts/$h.conf"));
                    if (my $file_block = $fetch_host->{files})
                    {
                        if (grep { $_ eq "$sysdir/hosts/$h.conf" } @$stack)
                        {
                            die "[$host: error] recursion found importing host $h\n";
                        }
                        push @$stack, "$sysdir/hosts/$h.conf";
                        my $remote_conf = $self->_process_file_block($file_block, $host, $stack);
                        pop @$stack;

                        %block = (%block, %$remote_conf);
                    }
                }
                else
                {
                    die "[$host: error] invalid host ($h) used in import\n";
                }
            }
            elsif ($type eq 'config')
            {
                my $source = $item->{config};
                my $config;
                if ($source =~ /^\//)
                {
                    $config = Load($self->read_file_contents($source, must_exist => 1));
                }
                else # file is localized
                {
                    $config = Load($self->read_file_contents("$sysdir/$source", must_exist => 1));
                }
                next unless $config;

                if (my $file_block = $config->{files})
                {
                    if (grep { $_ eq $source } @$stack)
                    {
                        die "[$host: error] recursion found importing config $source\n";
                    }

                    push @$stack, $source;
                    my $remote_conf = $self->_process_file_block($file_block, $host, $stack);
                    pop @$stack;

                    %block = (%block, %$remote_conf);
                }
            }
        }

    }

    return \%block;
}

=head3 is_valid_host

Returns true if host is valid.

=cut

sub is_valid_host
{
    my ($self, $host) = @_;
    my $sysdir = $self->sysdir;
    return -e "$sysdir/hosts/$host.conf";
}

=head3 is_valid_user

Returns true if user is valid.

=cut

sub is_valid_user
{
    my ($self, $username) = @_;
    my $sysdir = $self->sysdir;
    return -e "$sysdir/users/$username.conf";
}

=head3 get_host_users_groups

Get both users and groups for a specific host.

=cut

sub get_host_users_groups
{
    my ($self, $host) = @_;

    my $sysdir = $self->sysdir;
    my $default_host_config = {};
    if (-e "$sysdir/hosts/default.conf")
    {
        $default_host_config = Load($self->read_file_contents("$sysdir/hosts/default.conf"));
    }

    my $host_config = {};
    if ($self->is_valid_host($host))
    {
        $host_config = Load($self->read_file_contents("$sysdir/hosts/$host.conf"));
    }

    my (%host_users, %host_groups);
    # merge default users and host users via config

    $host_users{$_->{username}} = $_ for (@{ $default_host_config->{users} || [ ] });
    $host_users{$_->{username}} = $_ for (@{ $host_config->{users} || [ ] });

    $host_groups{$_->{groupname}} = $_ for (@{ $default_host_config->{groups} || [ ] });
    $host_groups{$_->{groupname}} = $_ for (@{ $host_config->{groups} || [ ] });

    my $user_groups = $host_config->{user_groups} || $default_host_config->{user_groups};

    for my $group (@{$user_groups || []})
    {
        my @users;
        if ($group eq 'all')
        {
            @users = $self->get_all_users;
        }
        else
        {
            @users = $self->get_users_from_group($group);
        }

        for my $username (@users)
        {
            my $user = $self->get_user($username);
            next unless $user;

            $host_users{$username} = $user;
        }
    }

    my @users = sort { $a->{uid} <=> $b->{uid} }
        map { $host_users{$_} } keys %host_users;

    # add all groups with applicable users
    for my $group ($self->get_all_groups)
    {
        # trust what we have if something is degined already
        next if $host_groups{$group};

        my $group = Load($self->read_file_contents("$sysdir/groups/$group.conf"));
        $host_groups{$group->{groupname}} = $group;
    }

    # add magical per-user groups
    for my $user (@users)
    {
        if (not $host_groups{$user->{username}} and not $user->{gid})
        {
            $host_groups{$user->{username}} = {
                gid => $user->{uid},
                groupname => $user->{username},
                users => [ ],
            };
        }
    }

    my @groups = sort { $a->{gid} <=> $b->{gid} }
        map { $host_groups{$_} } keys %host_groups;

    return {
        users  => \@users,
        groups => \@groups,
    };
}

=head3 get_user

Returns hashref of user information.

Unless "hard-coded", the user's password will not be returned in this hashref.

=cut

sub get_user
{
    my ($self, $username) = @_;
    my $sysdir = $self->sysdir;
    return unless -e "$sysdir/users/$username.conf";

    my $user_conf = Load($self->read_file_contents("$sysdir/users/$username.conf"));

    return $user_conf;
}

=head3 get_all_users

Returns an array of all usernames.

=cut

sub get_all_users
{
    my $self = shift;
    my $sysdir = $self->sysdir;
    my @users;
    opendir(DIR, "$sysdir/users");
    while (my $file = readdir(DIR))
    {
        if ($file =~ /(.*?)\.conf$/)
        {            
            push @users, $1;
        }
    }
    closedir(DIR);
    return @users;
}

=head3 get_all_hosts

=cut

sub get_all_hosts
{
    my $self = shift;
    my $sysdir = $self->sysdir;
    return Load($self->read_file_contents("$sysdir/hosts.conf")) || {};
}

=head3 get_all_groups

Returns array of groups

=cut

sub get_all_groups
{
    my $self = shift;
    my $sysdir = $self->sysdir;
    my @groups;
    opendir(DIR, "$sysdir/groups");
    while (my $file = readdir(DIR))
    {
        if ($file =~ /(.*?)\.conf$/)
        {            
            push @groups, $1;
        }
    }
    closedir(DIR);
    return @groups;
}

=head3 get_users_from_group

Returns array of users in a given group

=cut

sub get_users_from_group
{
    my ($self, $group) = @_;
    my $sysdir = $self->sysdir;
    return () unless -e "$sysdir/groups/$group.conf";

    my $group_conf = Load($self->read_file_contents("$sysdir/groups/$group.conf"));

    return () unless $group_conf->{users} and ref($group_conf->{users}) eq 'ARRAY';

    return @{ $group_conf->{users} };
}

=head3 must_refresh

Returns true if sysync must refresh.

Passing 1 or 0 as an argument sets whether this returns true.

=cut

sub must_refresh
{
    my $self = shift;
    my $stagedir = $self->stagedir;

    if (scalar @_ >= 1)
    {
        if ($_[0])
        {
            open(F, ">$stagedir/.refreshnow");
            close(F);
            return 1;
        }
        else
        {
            unlink("$stagedir/.refreshnow");
            return 0;
        }
    }
    else
    {
        return -e "$stagedir/.refreshnow";
    }
}

=head3 must_refresh_files

Returns true if sysync must refresh managed files.

Passing 1 or 0 as an argument sets whether this returns true.

=cut

sub must_refresh_files
{
    my $self = shift;
    my $stagefilesdir = $self->stagefilesdir;

    if (scalar @_ >= 1)
    {
        if ($_[0])
        {
            open(F, ">$stagefilesdir/.refreshnow");
            close(F);
            return 1;
        }
        else
        {
            unlink("$stagefilesdir/.refreshnow");
            return 0;
        }
    }
    else
    {
        return -e "$stagefilesdir/.refreshnow";
    }
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

