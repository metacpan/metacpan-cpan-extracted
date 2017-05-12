#!/usr/bin/env perl

# Copyright (C) 2012 by CPqD

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.014;
use utf8;
use autodie;
use JSON;
use POSIX qw(strftime);
use Getopt::Long;
use Term::Prompt;
use OCS::Client;

my $usage  = "$0 --svn=WCPATH --ocsurl=URL [--checksum=NUM] [--all] [--dont] [--verbose]\n";
my $SVN;
my $OCSURL;
no strict 'subs';
my $Checksum  =
    OCS::Client::BIOS |
    OCS::Client::HARDWARE |
    OCS::Client::LOGICAL_DRIVES |
    OCS::Client::MEMORY_SLOTS |
    OCS::Client::MODEMS |
    OCS::Client::NETWORK_ADAPTERS |
    OCS::Client::REGISTRY |
    OCS::Client::SOFTWARE |
    OCS::Client::SOUND_ADAPTERS |
    OCS::Client::STORAGE_PERIPHERALS |
    OCS::Client::VIDEO_ADAPTERS;
use strict 'subs';
my $All       = 0;
my $Dont;
my $Verbose   = 0;
GetOptions(
    'svn=s'      => \$SVN,
    'ocsurl=s'   => \$OCSURL,
    'chechsum=i' => \$Checksum,
    'all'        => \$All,
    'dont'       => \$Dont,
    'verbose+'   => \$Verbose,
) or die $usage;

defined $SVN or die "$usage\nMissing --svn option.\n";
-d $SVN or die "No such directory '$SVN'.\n";
chdir $SVN;

defined $OCSURL or die "$usage\nMissing --ocsurl option.\n";

warn "* TIME: ", scalar(localtime), "\n" if $Verbose;
warn "* OCS URL: $OCSURL\n" if $Verbose;

# Get the svn repository URL
my ($svn_url) = (`svn info` =~ /Repository Root:\s*(\S+)/);
die "Error in svn info: $?" if $?;
die "Couldn't get URL from svn info" unless $svn_url;

warn "* SVN repo URL: $svn_url\n" if $Verbose;

# Get the most recent tag so that we can avoid fetching information
# about hosts that weren't updated since the tag was created.
my $last_tag = (sort (`svn ls $svn_url/tags` =~ /(\d{14})/g))[-1];
die "Error in svn ls $svn_url/tags: $?" if $?;

# Use a fake time well in the past if we don't have any tags.
my $last_tag_time = $last_tag || '20000101000000';

# Convert tag time format into OCS time format for later comparisons.
$last_tag_time =~ s/(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/$1-$2-$3 $4:$5:$6/;

# A handy function to invoke shell commands.
sub shell {
    my ($cmd) = @_;
    warn "\$ $cmd\n" if $Verbose > 1;
    return if $Dont;
    system($cmd) == 0
	or warn "! Error in system($cmd): $@\n";
}

sub get_credentials {
    my ($userenv, $passenv, %opts) = @_;

    $opts{prompt}      ||= '';
    $opts{userhelp}    ||= '';
    $opts{passhelp}    ||= '';
    $opts{userdefault} ||= $ENV{USER};

    my $user = $ENV{$userenv} || prompt('x', "$opts{prompt} Username: ", $opts{userhelp}, $opts{userdefault});
    my $pass = $ENV{$passenv};
    unless ($pass) {
	$pass = prompt('p', "$opts{prompt} Password: ", $opts{passhelp}, '');
	print "\n";
    }

    return ($user, $pass);
}

my $ocs = OCS::Client->new($OCSURL, get_credentials('ocsuser', 'ocspass', prompt => 'OCS'));

my $json = JSON->new->pretty->canonical;

# The %ids hash is going to map the DATABASEID to the NAME of all the
# computers that have been inventoried since $last_tag_time.
my %ids = do {
    warn "* Get meta information of all inventoried computers in OCS...\n" if $Verbose;

    # Grok meta information for all computers in OCS
    my %metas;			# map computers by name
    my $next_computer = $ocs->computer_iterator(asking_for => 'META');
  COMPUTER:
    while (my $computer = $next_computer->()) {
	foreach my $info (qw/DATABASEID NAME/) {
	    exists $computer->{$info} && ! ref $computer->{$info} && length $computer->{$info}
		or warn "! No $info or invalid $info for meta (", $json->encode($computer), "). Skipping computer...\n"
		    and next COMPUTER;
	}
	! exists $metas{$computer->{NAME}}
	    or warn "! Duplicate NAME found ($computer->{NAME}) in meta. Keeping just the first one found...\n"
		and next COMPUTER;
	$metas{$computer->{NAME}} = $computer;
    }
    warn "* There is a total of ", scalar(keys %metas), " inventoried computers in OCS.\n" if $Verbose;

    # Remove from the working copy any computer not found in OCS.
    opendir HOSTS, '.';
    foreach my $file (grep {-f $_} readdir HOSTS) {
	if ($file =~ /^(?<name>.*)\.js$/ && ! exists $metas{$+{name}}) {
	    warn "* Remove file $file from working copy since there's no corresponding computer in OCS.\n" if $Verbose;
	    shell("svn rm -q '$file'");
	}
    }
    closedir HOSTS;

    # Collect the IDs of the ones recently inventoried or never gotten before
    map {$_->{DATABASEID} => $_->{NAME}}
	grep { $All || ! exists $_->{LASTDATE} || $_->{LASTDATE} gt $last_tag_time || ! -e "$_->{NAME}.js" }
	    values %metas;
};
warn "* ", scalar(keys %ids), " of which have been inventoried since $last_tag_time or neven gotten before.\n" if $Verbose;

# FIXME: The OCS documentation says that I can ask for a bunch of
# computers in a single get_computers_V1 invokation. It would be
# interesting to ask for computers in batches of 10, for instance, to
# make it faster.

{
    my $i = 0;
    my $total = keys %ids;
    while (my ($id, $name) = each %ids) {
	++$i;
	warn "* [$i/$total] get_computers_V1(ID => $id, checksum => $Checksum)\n" if $Verbose;
	my @computers = $ocs->get_computers_V1(id => $id, checksum => $Checksum);
	@computers > 0
	    or warn "! Can't get any computer for id $id.\n"
		and next;
	@computers == 1
	    or warn "! There are ", scalar(@computers), " computers for id $id. I'm considering just the first one.\n";

	my $file = "$name.js";
	my $existed = -e $file;

	warn '* ', ($existed ? 'Update' : 'Add   '), " $file\n" if $Verbose;
	unless ($Dont) {
	    my $computer = OCS::Client::prune($computers[0]);

	    # Some computers don't have this important field in their
	    # INVENTORY's ACCOUNTINFO. Hence, we insert it from the
	    # META we grokked earlier.
	    foreach my $accountinfo (values %{$computer->{ACCOUNTINFO}}) {
		$accountinfo->{DATABASEID} //= $id;
	    }

	    open my $fd, '>:raw', $file;
	    $fd->print($json->utf8->encode($computer));
	}

	shell("svn add -q '$file' && svn propset -q svn:mime-type 'text/javascript; charset=UTF-8' '$file'")
	    unless $existed;
    }
}

warn "* Commit changes...\n";
shell("svn ci -q -m 'ocssvn commit'");

my $new_tag = strftime("%F%T", localtime);
$new_tag =~ tr/0-9//cd;
warn "* Previous tag: $svn_url/tags/$last_tag\n";
warn "* New      tag: $svn_url/tags/$new_tag\n";
shell("svn cp -m \"ocssvn tag\" ^/trunk ^/tags/$new_tag");

shell('svn up -q');

warn "* TIME: ", scalar(localtime), "\n" if $Verbose;


__END__
=head1 NAME

ocssvn.pl - keep OCS computer data versioned in Subversion.

=head1 SYNOPSIS

ocssvn.pl --svn=WCPATH --ocsurl=URL [--checksum=NUM] [--all] [--dont] [--verbose]

=head1 DESCRIPTION

Use this script to keep the information from a OCS server
(L<http://www.ocsinventory-ng.org/>) versioned in a Subversion
repository.

The information about each computer in OCS is kept in a text file in
JSON format (http://json.org/), which is a structured and readable
format.

First you need to create a dedicated Subversion repository to keep OCS
information. Also, you need to create a C<trunk> and a C<tags>
directory at the root of the repository. You can do this with these
commands:

    $ svnadmin create /path/to/ocssvnrepo
    $ svn mkdir -m'Create standard root directories' file:///path/to/ocssvnrepo/{trunk,branches,tags}

Then, checkout the trunk directory creating a working copy. The
working copy can be in the same computer as the repository or in a
remote machine. You need to adjust the URL accordingly.

    $ svn checkout file:///path/to/ocssvnrepo/trunk /path/to/ocssvn

Now you can run the script. The two required options are the path to
the Subversion working copy that you just created (C<--svn>) and the
URL to the OCS server.

    $ ocssvn.pl --svn=/path/to/ocssvn --ocsurl=http://ocs.domain.com/

On its first run, the script will fetch information about all
computers registered in OCS and create a file called C<name.js> in the
working copy. The C<name> part is taken from the NAME of the computer
as fetched from its META information. When all computers are fetched
and their files created the script runs a C<svn add> for each file and
a C<svn commit> to commit the changed working copy to the
repository. Then it creates a tag by copying C<trunk> to a directory
which name conforms to C<tags/YYYYMMDDHHMMSS>. The tag name is the
time when it was created.

On subsequent runs, the script will first fetch the META information
from all computers in OCS and then fetch the complete information only
of the computers which have been inventoried since the last tag was
created. After doing that it does the commit and a new tag is
created. This was you have a new tag for each run, which allows you to
have complete versioning of OCS information.

The script fetches the information via OCS's SOAP API, using the
C<OCS::Client> module. It asks for the login credentials on
interactive calls. If you want to invoke it via cron, you should set
the credentials before calling it by setting the environment variables
C<ocsuser> and C<ocspass>.

The computer information is pruned before being saved in the JSON file
by the C<OCS::Client::prune> routine.

=head1 OPTIONS

=over

=item --svn=WCPATH

This required option specifies the path to the Subversion working copy
where the computer files are kept.

=item --ocsurl=URL

This required option specifies the OCS server URL.

=item --checksum=NUM

This option specifies the CHECKSUM parameter that will be passed to
OCS::Client::get_computers_V1, in order to tell what information is
requested from the computers. Its default has the following bits
enabled:

    OCS::Client::BIOS
    OCS::Client::HARDWARE
    OCS::Client::LOGICAL_DRIVES
    OCS::Client::MEMORY_SLOTS
    OCS::Client::MODEMS
    OCS::Client::NETWORK_ADAPTERS
    OCS::Client::REGISTRY
    OCS::Client::SOFTWARE
    OCS::Client::SOUND_ADAPTERS
    OCS::Client::STORAGE_PERIPHERALS
    OCS::Client::VIDEO_ADAPTERS

=item --all

By default, only computers that have been inventoried since the most
recent Subversion tag has been generated or computers which don't yet
have a corresponding JSON file are fetched from OCS. This option
forces the fetching of all computers.

It's handy when the script JSON output changes and you want to force
the refresh of all files.

=item --dont

This option makes the script refrain from making any changes in
Subversion.

=item --verbose

This option makes the script verbose. If you repeat it it will make
the script even more verbose.

=back

=head1 SEE ALSO

=head1 COPYRIGHT

Copyright 2012 CPqD.

=head1 AUTHOR

Gustavo Chaves <gustavo@cpqd.com.br>
