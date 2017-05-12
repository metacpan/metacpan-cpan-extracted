#!/usr/bin/env perl

use SVN::Access;
use warnings;
use strict;

my ($acl_file, $perm, $resource, @targets) = @ARGV;

unless ($acl_file && defined($perm) && $resource) {
    print usage();
    exit();
}

my $acl = SVN::Access->new(acl_file => $acl_file);

# /path/to/my.conf +w / ak1520 @admins "peter rabbit" "jane fonda" webster
# /path/to/my.conf +_user_ @admins ak1520 ab2320 aa0028 god

if ($perm =~ /^(\+|\-)_user_/) {
    my $op = $1;
    # this is a group add / del / modify.
    $resource =~ s/\@//g;
    if ($op eq "+") {
        if (my $group = $acl->group($resource)) {
            foreach my $user (@targets) {
                $group->add_member($user);
            }
        } else {
            #new group!
            $acl->add_group($resource, @targets);
        }
    } else {
        if (my $group = $acl->group($resource)) {
            foreach my $user (@targets) {
                $group->remove_member($user);
            }
        }
    }
    # commit changes.
    $acl->write_pretty;
} elsif ($perm =~ /^(\+|\-)(\w*)$/) {
    my $op = $1;
    my $flags = $2;
    # this is a resource add / del / modify.
    if ($op eq "+") {
        if (my $r = $acl->resource($resource)) {
            my %authorized = %{$r->authorized};
            foreach my $user (@targets) {
                if (exists($authorized{$user})) {
                    my $final_flags = merge_flags($authorized{$user}, $flags);
                    $r->authorize($user, $final_flags);
                } else {
                    # user doesn't have any access yet.
                    $r->authorize($user, $flags);
                }
            }
         } else {
             # new resource
             my %authorized = map { $_ => $flags } @targets;
             $acl->add_resource($resource, %authorized);
         }
    } else {
        if (my $resource = $acl->resource($resource)) {
            my %authorized = %{$resource->authorized};
            foreach my $user (@targets) {
                if (exists($authorized{$user})) {
                    my $final_flags = remove_flags($authorized{$user}, $flags);
                    if ($final_flags) {
                        $resource->authorize($user, $final_flags);
                    } else {
                        $resource->deauthorize($user);
                    }
                } 
            }
        }
    }
    # commit changes.
    $acl->write_pretty;
} else {
    die "Error: '$perm' improperly formatted.\n";
}

sub merge_flags {
    my ($has_flags, $new_flags) = @_;
    my @hf = split(//, $has_flags);
    my @nf = split(//, $new_flags);
    for (@nf) {
        push(@hf, $_) unless has_element($_, @hf);
    }
    return join('', @hf);
}

sub remove_flags {
    my ($has_flags, $rem_flags) = @_;
    my @hf = split(//, $has_flags);
    my @rf = split(//, $rem_flags);
    my @final;
    for (@hf) {
        push(@final, $_) unless has_element($_, @rf);
    }
    return join('', @final);
}

sub has_element {
    my ($e, @array) = @_;
    for (@array) {
        return 1 if $e eq $_;
    }
    return undef;
}

sub usage {
    return<<EOF;
SVN::Access - svnaclmgr.pl
    
svnaclmgr.pl usage:
svnaclmgr.pl <acl_file> <perm> <resource> <users / groups>

example:
svnaclmgr.pl /tmp/svnacl.conf +rw /trunk \@admin frank bob

you can also manage users and groups using this tool by using 
_user_ as the <perm> with a - or + prefixed, and a group as 
the <resource>.

example:
svnaclmgr.pl /tmp/svnacl.conf +_user_ \@admin jeff rich wendel

EOF
}

__END__

1
