package Module::DevAid;
use strict;
use warnings;

=head1 NAME

Module::DevAid - tools to aid perl module developers

=head1 VERSION

This describes version B<0.24> of Module::DevAid.

=cut

our $VERSION = '0.24';

=head1 SYNOPSIS

  use Module::DevAid;

  my $da = Module::DevAid->new(
	dist_name => 'My::Module',
	modules => qw(lib/My/Module.pm lib/My/Module/Other.pm),
	scripts => qw(scripts/myscript),
	gen_readme => 1,
	gen_todo => 1,
	);

    $da->generate_readme_file();

=head1 DESCRIPTION

Module (and script) to aid with development, by helping (and testing)
auto-building of certain files, and with the steps needed in building and
committing a release.

At this point this only uses the darcs or svk revision systems.

Takes a project description, either through the command line options, or
via a project config file, which defaults to 'mod_devaid.conf' in
the current directory.

Features:

=over

=item *

generates a README file from POD

=item *

generates a TODO file from a devtodo .todo file

=item *

auto-updates a Changes file from the revision-control system's change log.

=item *

auto-changes version-id in module and script files

=item *

does all of the above and tags commits for a release

=back

=head1 METHODS

=head2 new
    
    my $da = new(%args)

Create a new object.  This first reads from the default config file
(see L<config_read>) and the defaults from there can be overridden
with the following arguments:

=over

=item changes_file => I<filename>

Name of the Changes file to be generated. (default: Changes)

=item commit_todo => 1

Should we commit the TODO file we generated?  If true, then will
attempt to do a darcs commit on the generated TODO file.  This needs
to be an option because some setups need the TODO file (as well as the
.todo file) to be under revision control, and others don't.
(see L<gen_todo>) (default: false)

=item dist_name => I<string>

The distribution name of the project, such as the name of the module
My::Module.

=item gen_readme => 1

Should we generate a README file? (see L<pod_file>)

=item gen_todo => 1

Should we generate a TODO file?  If true, the TODO file will be
generated from a .todo file of the kind created by the devtodo program.
(see L<todo_file>)

=item modules => qw(lib/My/Module.pm)

The module files in the project.  Must have their path relative
to the top directory of the project.

=item old_version_file => I<filename>

The file which will hold the previous version (gets updated on version_bump).
(see L<version_file>) (default: old_version.txt)

=item pod_file => I<filename>

The file which contains the POD from which the README file should
be generated.  If not defined, defaults to the first module
in the B<modules> list.

If B<gen_readme> is true, the README file will be generated from
I<select> sections of the B<pod_file> file.  The important ones are
NAME, DESCRIPTION, INSTALLATION, REQUIRES and AUTHOR.

=item readme_file => I<filename>

Name of the README file to be generated. (default: README)

=item version_bump_code => I<code reference>

    my $vsub = sub {
	my $version = shift;

	# code to update files
	...
    };

    version_bump_code => $vsub

Reference to a function which will perform custom actions to
automatically change the version-id.  The default actions go through the
B<modules> and B<scripts> and update anything matching a standard
VERSION-setting string, and which matches a 'This describes version'
string.  This subroutine is for doing anything additional or different.

This is given one argument, the version string.

=item version_bump_files

The list of files altered by the version_bump_code, so that all the
version changes can be committed at the same time.  This is needed because
some tests require the test files to have the version-id in them,
and therefore all version commits should be done at the same time,
otherwise the tests will fail, and the commits won't work.

=item scripts => qw(scripts/myscript)

The script files in the project.  Must have their path relative
to the top directory of the project.

=item todo_file => I<filename>

Name of the TODO file to be generated. (default: TODO)

=item version_file => I<filename>

The file from which to take the version.  The version should be in the form
of a standard VERSION id: I<number>.I<number> on a line by itself.
Optionally, it can be I<number>.I<number> followed by a general id,
for example 2.03_rc1
(default: version.txt)

=item version_control => I<string>

Which version-control system is being used.  The options are 'darcs'
and 'svk'.  (default: darcs)
The version control system is used for listing and committing changes.

=back

=cut
use Pod::Select;
use Pod::Text;
use IO::String;

sub new {
    my $class = shift;
    my %parameters = (@_);
    my $self = bless({}, ref ($class) || $class);
    $self->config_read();

    # set the parameters, which override the config
    if (%parameters) {
	while (my ($key, $value) = each (%parameters))
	{
	    $self->{$key} = $value;
	}
    }

    # set the defaults if not already set
    $self->{version_control} ||= 'darcs';
    $self->{pod_file} ||= $self->{modules}->[0];
    $self->{commit_todo} ||= 0;
    $self->{gen_readme} ||= 0;
    $self->{gen_todo} ||= 0;
    $self->{todo_file} ||= 'TODO';
    $self->{changes_file} ||= 'Changes';
    $self->{readme_file} ||= 'README';
    $self->{version_file} ||= 'version.txt';
    $self->{old_version_file} ||= 'old_version.txt';
    $self->{version_bump_files} ||= [];
    $self->{scripts} ||= [];
    $self->{pod_sel} = new Pod::Select();
    $self->{pod_text} = Pod::Text->new(alt=>1,indent=>0);
    return $self;
} # new

=head2 config_read

Set the configuration from a config file.  This is called
for the default config when "new" is invoked, so there's no
need to call this unless you want to use an additional config file.

The information about a project can be given in a config file, which
defaults to 'mod_devaid.conf' in the current directory.  If you want
to use a different file, set the MOD_DEVAID_CONF environment variable,
and the module will use that.

The options which can be set in the config file are exactly the same
as those which can be set in B<new>.

The options are set with a 'option = value' setup.  Blank lines are
ignored.

For example:

    dist_name = My::Module
    modules = lib/My/Module.pm lib/My/Module/Other.pm
    gen_readme = 1

=head3 version_bump_code

Use with CAUTION.

This defines additional code which can be used for the automatic
update of version numbers in files.  It has to be defined all on one
line, and basically be a subroutine definition, like so:

version_bump_code = sub { my $version = shift; # code to update files ...  };

=head3 version_bump_files

The list of files altered by the version_bump_code, so that all the
version changes can be committed at the same time.  This is needed because
some tests require the test files to have the version-id in them,
and therefore all version commits should be done at the same time,
otherwise the tests will fail, and the commits won't work.

=cut

sub config_read {
    my $self = shift;
    my $filename = (@_ ? shift :
	($ENV{MOD_DEVAID_CONF} || 'mod_devaid.conf'));

    return unless -e $filename;

    open my $config_file, '<', $filename
	or die "couldn't open config file $filename: $!";

    while (<$config_file>) { 
	chomp;
	next if /\A\s*\Z/sm;
	if (/\A(\w+)\s*=\s*(.+)\Z/sm)
	{
	    my $key = $1;
	    my $value = $2;
	    if ($key =~ /^(modules|scripts|version_bump_files)$/) # plural thing
	    {
		$self->{$key} = [split(/\s+/, $value)];
	    }
	    elsif ($key eq 'version_bump_code')
	    {
		if ($value =~ /^sub/)
		{
		    $self->{$key} = eval "$value";
		}
		else
		{
		    warn "$key: $value is not code\n";
		}
	    }
	    else
	    {
		$self->{$key} = $value;
	    }
	}
    }
    return 1;
}

=head2 do_release

Do a release, using darcs as the revision control system.

=cut

sub do_release {
    my $self = shift;

    my $old_version = $self->get_old_version();
    my $version = $self->get_new_version();

    # release notes
    # note that we update the changes file first,
    # so as not to have the automatic changes included in the list
    $self->update_changes_file($old_version, $version);

    $self->generate_todo_file();

    # version
    $self->version_bump($version, 1);

    # readme has to be generated after the version_bump
    # because it may contain version info
    $self->generate_readme_file(1);

    # release tag
    $self->tag_release($version);

    if (-f 'Build.PL') # we are using Module::Build
    {
	# Rebuild the Build file and make the dist file.
	# Note that this has to be done as a shell command
	# because it needs the new Build script to get
	# the correct version
	my $command = "perl Build.PL && Build dist";
	system($command);
    }
    elsif (-f 'Makefile.PL') # we are using ExtUtils::MakeMaker
    {
	# Rebuild the Makefile and make the dist file.
	# Note that this has to be done as a shell command
	# because it needs the new Makefile to get
	# the correct version
	my $command = "perl Makefile.PL && make dist";
	system($command);
    }
    else # make a darcs dist
    {
	my $dist_rel_name = $self->{dist_name};
	$dist_rel_name =~ s/::/-/g;
	my $command = "darcs dist -d $dist_rel_name-$version";
	system($command);
    }
} # do_release

=head2 version_bump

Automate the update of the version, taken from B<version_file>
and B<old_version_file>

=cut

sub version_bump {
    my $self = shift;
    my $version = shift;
    my $do_commit = (@_ ? shift : 0);

    my $old_version_file = $self->{old_version_file};
    my $version_file = $self->{version_file};

    print STDERR "\$VERSION = '$version'\n";

    #================================================================
    # change the version in various files
    #
    my @files = @{$self->{modules}};
    push @files, @{$self->{scripts}} if @{$self->{scripts}};

    my $command;
    if (@files)
    {
	$command = 'perl -pi -e "/VERSION\s+=\s+\'\d/ && s/VERSION\s+=\s+\'\d+\.\d+\w*\''
	    . "/VERSION = '${version}'/\" " . 
	    join(' ', @files);
	system($command);

	$command = 'perl -pi -e \'/^This describes version/ && s/B<\d+[.]\d+\w*>'
	    . "/B<$version>/' " .
	    join(' ', @files);
	system($command);
    }

    # call the user custom code
    if (exists $self->{version_bump_code}
	&& defined $self->{version_bump_code}
	&& ref($self->{version_bump_code}) eq 'CODE')
    {
	$self->{version_bump_code}->($version);
    }

    #================================================================

    # copy the current version to old_version_file
    if (-f $old_version_file
	&& open(OVFILE, ">$old_version_file"))
    {
	print OVFILE "$version\n";
	close(OVFILE);
    }

    if ($do_commit && $self->{version_control} eq 'darcs')
    {
	$command = "darcs record -am 'bump version to $version' $old_version_file $version_file "
	    . join(' ', @files, @{$self->{version_bump_files}});
	system($command);
    }
    elsif ($do_commit && $self->{version_control} eq 'svk')
    {
	$command = "svk commit -m 'bump version to $version' $old_version_file $version_file "
	    . join(' ', @files, @{$self->{version_bump_files}});
	system($command);
    }

} # version_bump

=head2 get_todo_content

Get the content which would be put in a TODO file
generated using devtodo .todo file in project directory.

Returns a string.

=cut

sub get_todo_content {
    my $self = shift;

    my $product = $self->{dist_name};
    my $todo_file = $self->{todo_file};

    my $title_str = "TODO list for $product";
    my $format = 'todo=%i%[info]%f%2n. %[priority]%+1T\n%+1i%[info]Added:%[normal]%c  %[info]Priority: %[normal]%p\n\n';
    my $todo_cmd = "todo --format '$format' --use-format display=todo";
    my $todo_str = `$todo_cmd`;
    if (!$todo_str)
    {
	$todo_str = "\t** nothing to do! **\n";
    }
    my $ret_str = join("\n", $title_str, '=' x length($title_str), $todo_str);
}

=head2 generate_todo_file

Generate TODO file using devtodo .todo file in project directory.
Uses get_todo_content().

=cut

sub generate_todo_file {
    my $self = shift;

    if ($self->{gen_todo})
    {
	my $product = $self->{dist_name};
	my $todo_file = $self->{todo_file};
	my $do_commit = $self->{commit_todo};

	my $todo_str = $self->get_todo_content();
	if (open(OTFILE, ">${todo_file}"))
	{
	    print OTFILE $todo_str, "\n";
	    close(OTFILE);
	    print "generated $todo_file\n";
	}
	if ($do_commit && $self->{version_control} eq 'darcs')
	{
	    my $command = "darcs record -am 'generate TODO file' $todo_file";
	    system($command);
	}
	elsif ($do_commit && $self->{version_control} eq 'svk')
	{
	    my $command = "svk commit -m 'generate TODO file' $todo_file";
	    system($command);
	}
    }
}

=head2 get_readme_content

Generate README content from PoD in module.
Only uses selected sections, rather than the whole thing.
Returns a string.

=cut

sub get_readme_content {
    my $self = shift;

    my $pod_file = $self->{pod_file};
    $self->{pod_sel}->select('NAME','VERSION','DESCRIPTION',
			     'INSTALLATION','CONTENTS','REQUIRES|PREREQUISITES',
			     'AUTHOR','SUPPORT','COPYRIGHT.*|LICENCE|LICENSE');
    my $readme_pod;
    my $io_pod = IO::String->new($readme_pod);
    my $pod_file_fh;
    open($pod_file_fh, $pod_file) or die "Could not open $pod_file";
    $self->{pod_sel}->parse_from_filehandle($pod_file_fh, $io_pod);

    # reset the handle to zero so it can be read from
    $io_pod->setpos(0);

    my $readme_txt;
    my $io_txt = IO::String->new($readme_txt);

    $self->{pod_text}->parse_from_filehandle($io_pod, $io_txt);

    return $readme_txt;
}

=head2 generate_readme_file

Generate README file from PoD in module.
(uses get_readme_content)

=cut

sub generate_readme_file {
    my $self = shift;
    my $do_commit = (@_ ? shift : 0);

    if ($self->{gen_readme})
    {
	my $pod_file = $self->{pod_file};
	my $readme_file = $self->{readme_file};
	my $readme_str = $self->get_readme_content();
	open RMFILE, ">$readme_file"
	    or die "Cannot write to $readme_file";
	print RMFILE $readme_str;
	close (RMFILE);
	print "generated $readme_file\n";
	if ($do_commit && $self->{version_control} eq 'darcs')
	{
	    my $command = "darcs record -am 'generate README file' $readme_file";
	    system($command);
	}
	elsif ($do_commit && $self->{version_control} eq 'svk')
	{
	    my $command = "svk commit -m 'generate README file' $readme_file";
	    system($command);
	}
    }
}

=head2 get_new_changes

Get the changes committed since the last release.
Generate a more compact format than the default.

=cut

sub get_new_changes {
    my $self = shift;
    my $old_version = shift;

    my $new_changes;
    if ($self->{version_control} eq 'darcs')
    {
	$new_changes = $self->get_new_darcs_changes($old_version);
    }
    elsif ($self->{version_control} eq 'svk')
    {
	$new_changes = $self->get_new_svk_changes($old_version);
    }
    return $new_changes;
}

=head2 get_changes_content

Get the contents of what the new changes file should be.
Takes version and old_version id strings as arguments.
(uses get_new_changes)
Returns a string.

=cut

sub get_changes_content {
    my $self = shift;
    my $old_version = shift;
    my $version = shift;

    my $product = $self->{dist_name};
    my $new_changes = $self->get_new_changes($old_version);
    chomp $new_changes;
    my $date_str = `date "+%a %d %B %Y"`;
    chomp $date_str;
    my $changes_file = $self->{changes_file};
    my $existing_changes = '';
    if (-f $changes_file
	&& open(CFILE, $changes_file))
    {
	my $count = 0;
	while (my $line = <CFILE>)
	{
	    # skip the header part -- first three lines
	    if (!($line =~ /^Revision history/
		|| ($line =~ /^======/ && $count < 3)
		|| ($line =~ /^\s*$/ && $count < 3)))
	    {
		$existing_changes .= $line;
	    }
	    $count++;
	}
	close (CFILE);
    }
    my $title_str = "Revision history for $product";
    my $version_title_str = "$version $date_str";
    my $ret_str = join("\n",
	$title_str,
	'=' x length($title_str),
	'',
	$version_title_str,
	'-' x length($version_title_str),
	'',
	$new_changes,
	$existing_changes
    );
    return $ret_str;
}

=head2 get_old_version

Get the version-id of the previous release from B<old_version_file>

=cut

sub get_old_version {
    my $self = shift;

    my $old_version_file = $self->{old_version_file};
    my $old_version = '';

    # read the old version
    if (-f $old_version_file
	&& open(OVFILE, $old_version_file))
    {
	while (my $line = <OVFILE>)
	{
	    if ($line =~ /^([0-9]+\.[0-9]+)$/)
	    {
		eval "\$old_version = '$1';";
		last;
	    }
	}
	close(OVFILE);
    }
    return $old_version;
} # get_old_version

=head2 get_new_version

Get the version-id of the up-and-coming release from B<version_file>

=cut

sub get_new_version {
    my $self = shift;

    my $new_version_file = $self->{version_file};
    my $version = '';

    # read the old version
    if (-f $new_version_file
	&& open(NVFILE, $new_version_file))
    {
	while (my $line = <NVFILE>)
	{
	    if ($line =~ /^(\d+\.\d+\w*)$/)
	    {
		eval "\$version = '$1';";
		last;
	    }
	}
	close(NVFILE);
    }
    return $version;
} # get_new_version

=head1 INTERNAL METHODS

These are documented for the developer only, and are not meant
to be used by the outside.

=head2 get_new_darcs_changes

Get the changes committed to darcs since the last release.
Generate a more compact format than the darcs changes default.

=cut

sub get_new_darcs_changes {
    my $self = shift;
    my $old_version = shift;

    my $command = "darcs changes --from-patch release-$old_version";
    my $new_changes = '';
    if (!`$command`) # check the command works
    {
	$command = 'darcs changes';
    }
    if (open(CFILE, "$command |"))
    {
	my $cdate = '';
	while (my $line = <CFILE>)
	{
	    # filter out the tagged release bit
	    if ($line =~ /^\s*tagged\s+release/)
	    {
	    }
	    # grab the date parts
	    elsif ($line =~ /^(Mon|Tue|Wed|Thu|Fri|Sat|Sun)\s+([a-zA-Z]+)\s+(\d+)\s+\d\d:\d\d:\d\d\s+\w+\s+(\d+)/)
	    {
		my $month = $2;
		my $day = $3;
		my $year = $4;
		$cdate = "$day $month $year";
	    }
	    elsif ($line =~ /\s+\*\s+/) # item start
	    {
		# stick the date in
		$line =~ s/(\s+\*\s+)/$1\($cdate\) /;
		$new_changes .= $line;
	    }
	    else
	    {
		$new_changes .= $line;
	    }
	}
	close CFILE;
    }
    if (!$new_changes) # get ALL the changes if that failed
    {
	$new_changes = `darcs changes`;
    }
    return $new_changes;
} # get_new_darcs_changes

=head2 get_new_svk_changes

Get the changes committed to svk since the last release.
Generate a more compact format than the svk changes default.

=cut

sub get_new_svk_changes {
    my $self = shift;
    my $old_version = shift;

    # find out the version of the most recent tag
    my $info_cmd = "svk info";
    my $fh;
    my $depot_path = '';
    my $local_last_rev = '';
    if (open($fh, "$info_cmd |"))
    {
	while (my $line = <$fh>)
	{
	    if ($line =~ /Depot Path:\s+(.*)/)
	    {
		$depot_path = $1;
	    }
	    elsif ($line =~ /Last Changed Rev.:\s*(\d+)/)
	    {
		$local_last_rev = $1;
	    }
	}
	close $fh;
    }
    my $tags_path = $depot_path;
    $tags_path =~ s/trunk/tags/;

    $info_cmd = "svk info $tags_path";
    my $tags_last_rev = '';
    if (open($fh, "$info_cmd |"))
    {
	while (my $line = <$fh>)
	{
	    if ($line =~ /Last Changed Rev.:\s*(\d+)/)
	    {
		$tags_last_rev = $1;
	    }
	}
	close $fh;
    }
    my $new_changes = '';

    my $command = "svk log -r HEAD:$tags_last_rev";
    # if the local change is older than the tag change,
    # there are no changes; fall back to all changes.
    if ($local_last_rev < $tags_last_rev)
    {
	$command = 'svk log';
    }
    if (!`$command`) # check the command works
    {
	$command = 'svk log';
    }
    if (open(CFILE, "$command |"))
    {
	my $cdate = '';
	my $item = '';
	while (my $line = <CFILE>)
	{
	    # filter out the tagged release bit
	    if ($line =~ /^\s*tagged\s+release/)
	    {
	    }
	    # grab the date parts
	    elsif ($line =~ /^r\d+:\s+\w+\s+\|\s+(\d\d\d\d-\d+-\d+)/)
	    {
		$cdate = $1;
		$item = '';
	    }
	    elsif ($line =~ /----------/) # item start or end
	    {
		if ($item) # end
		{
		    $new_changes .= "  * ($cdate) $item";
		}
	    }
	    elsif ($line =~ /^$/) # blank
	    {
		$item .= $line if $item;
	    }
	    else
	    {
		if ($item)
		{
		    $item .= "    $line"; # alignment
		}
		else
		{
		    $item .= $line;
		}
	    }
	}
	close CFILE;
	$new_changes .= "\n" if $new_changes;
    }
    if (!$new_changes) # get ALL the changes if that failed
    {
	$new_changes = `svk log`;
    }
    return $new_changes;
} # get_new_svk_changes

=head2 update_changes_file

Called by do_release.  Overwrites the changes file and commits
the change. (uses get_changes_content)

=cut

sub update_changes_file {
    my $self = shift;
    my $old_version = shift;
    my $version = shift;

    my $changes_str = $self->get_changes_content($old_version, $version);
    my $changes_file = $self->{changes_file};
    if (open(OCFILE, ">${changes_file}"))
    {
	print OCFILE $changes_str;
	close(OCFILE);
    }
    if ($self->{version_control} eq 'darcs')
    {
	my $command = "darcs record -am 'update release notes' $changes_file";
	system($command);
    }
    elsif ($self->{version_control} eq 'svk')
    {
	my $command = "svk commit -m 'update release notes' $changes_file";
	system($command);
    }
}

=head2 tag_release

Called by do_release.  Tags the release.

=cut

sub tag_release {
    my $self = shift;
    my $version = shift;

    if ($self->{version_control} eq 'darcs')
    {
	my $command = "darcs tag -m release-$version --checkpoint";
	system($command);
    }
    elsif ($self->{version_control} eq 'svk')
    {
	# find the tag path
	my $info_cmd = "svk info";
	my $fh;
	my $depot_path = '';
	if (open($fh, "$info_cmd |"))
	{
	    while (my $line = <$fh>)
	    {
		if ($line =~ /Depot Path:\s+(.*)/)
		{
		    $depot_path = $1;
		}
	    }
	    close $fh;
	}
	my $tags_path = $depot_path;
	$tags_path =~ s/trunk/tags/;
	my $command = "svk copy -p -m release-$version $depot_path $tags_path/v$version";
	system($command);
    }
} # tag_release

=head1 REQUIRES

    Getopt::Long
    Pod::Usage
    Data::Dumper
    Test::More

=head1 SEE ALSO

perl(1).

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.com

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2004-2007 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Module::DevAid
__END__
