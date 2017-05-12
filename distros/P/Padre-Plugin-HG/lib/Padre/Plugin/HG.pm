package Padre::Plugin::HG;

use 5.008;
use warnings;
use strict;

use Padre::Config ();
use Padre::Wx     ();
use Padre::Plugin ();
use Padre::Util   ();

use Capture::Tiny  qw(capture_merged);
use File::Basename ();
use File::Spec;

use Padre::Plugin::HG::ProjectCommit;
use Padre::Plugin::HG::ProjectClone;
use Padre::Plugin::HG::UserPassPrompt;
use Padre::Plugin::HG::DiffView;
use Padre::Plugin::HG::LogView;
my %projects;
our $VERSION = '0.17';
our @ISA     = 'Padre::Plugin';

my $VCS = "Mercurial"
# enter the vcs commands here, variables will be evaled in in the sub routines. 
# was meant as a way to make it more generic.  Not sure it is going to 
# succeed. 
my %VCSCommand = ( commit => 'hg commit -A -m"$message" $path ',
		add => 'hg add $path',
		status =>'hg status --all $path',
		root => 'hg root', 
		diff => 'hg diff $path',
		diff_revision => 'hg diff -r $revision $path',
		clone=> 'hg clone $path',
		pull =>'hg pull --update --noninteractive  ',
		push =>'hg push $path',
		log =>'hg log $path');
		


=pod

=head1 NAME

Padre::Plugin::HG - Mecurial interface for Padre

=head1 Instructions

Ensure Mecurial is installed and the hg command is in the path. 

cpan install Padre::Plugin::HG

Either open a file in an existing Mecurial project or choose Plugins > HG > Clone and enter an 
exisiting repository to clone. 
 
you can clone this project it self with
"hg clone https://code4pay@bitbucket.org/code4pay/padre-plugin-hg/"

Once you have a file from the project open  got to Plugins > HG > View Project.
this will display the project tree in the left hand side bar and allow you to 
perform operations on the files /project via the right mouse button.

Project wide operations like pull are only available by right clicking the project root. 
 

=head1 AUTHOR

Michael Mueller << <michael at muellers.net.au> >>

=head1 BUGS

Please report any bugs or feature requests to L<http://padre.perlide.org/>


=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 Michael Mueller
all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.



=cut


#####################################################################
# Padre::Plugin Methods

sub padre_interfaces {
	'Padre::Plugin' => 0.90
}

sub plugin_name {
	'HG';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About'             => sub { $self->show_about },
		'View Project'	    => sub {$self->show_statusTree},
		'Clone'		    => sub {$self->show_project_clone},

	];
}

sub plugin_disable
{
  require Class::Unload;
  Class::Unload->unload('Padre::Plugin::HG::StatusTree;');
}

sub padre_hooks
{
    my %hooks;
     $hooks{after_save} =  \&after_save;
     return \%hooks;
}

#####################################################################
# Custom Methods

sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::HG");
	$about->SetDescription( <<"END_MESSAGE" );
Mecurial support for Padre
END_MESSAGE
	$about->SetVersion( $VERSION );

	# Show the About dialog
	Wx::AboutBox( $about );

	return;
}

#
#vcs_commit
#
# performs the commit 
# $self->vcs_commit($filename, $dir);
# will prompt for the commit message.
# 


sub vcs_commit {
	my ($self, $path, $dir ) = @_;
	my $main = Padre->ide->wx->main;
	
	if (!$self->_project_root($path))
	{
		$main->error("File not in a $VCS Project", "Padre $VCS" );
		return;
	}

	my $message = $main->prompt("$VCS Commit of $path", "Please type in your message", "MY_".$VCS."_COMMIT");
	if ($message) {
		
		my $command = eval "qq\0$VCSCommand{commit}\0";
		my $result = $self->vcs_execute($command, $dir);
		$main->message( $result, "$VCS Commiting $path" );
	}

	return;	
}


#
#vcs_add
#
# Adds the file to the repository
# $self->vcs_add($filename, $dir);
# will prompt for the commit message.
# 


sub vcs_add {
	my ($self, $path, $dir) = @_;
	my $main = Padre->ide->wx->main;
	my $command = eval "qq\0$VCSCommand{add}\0";
	my $result = $self->vcs_execute($command,$dir);
	$main->message( $result, "$VCS Adding to Repository" );
	return;	
}

#
# vcs_diff
#
# compare the file to the repository tip
# $self->vcs_diff($filename, $dir);
# provides some basic diffing the current file agains the tip

sub vcs_diff {
	my ($self, $path, $dir) = @_;
	
	my $main = Padre->ide->wx->main;
	my $command = eval "qq\0$VCSCommand{diff}\0";
	return $main->error('File not in a $VCS Project', "Padre $VCS" ) if not $self->_project_root($path);
	my $result = $self->vcs_execute($command, $dir);
	return $result;
}

# vcs_diff_revision
#
# compare the file to a repository revision 
# $self->vcs_diff($filename, $dir, $revision);
# Revision for HG is the changeset id. 


sub vcs_diff_revision {
	my ($self, $path, $dir, $revision) = @_;
	
	my $main = Padre->ide->wx->main;
	my $command = eval "qq\0$VCSCommand{diff_revision}\0";
	return $main->error('File not in a $VCS Project', "Padre $VCS" ) if not $self->_project_root($path);
	my $result = $self->vcs_execute($command, $dir);
	return $result;
}



# vcs_log
#
# show the commit history of the passed file. 
# $self->vcs_commit($filename, $dir);
# returns a string containing the log history


sub vcs_log {
	my ($self, $path, $dir) = @_;
	
	my $main = Padre->ide->wx->main;
	my $command = eval "qq\0$VCSCommand{log}\0";
	return $main->error('File not in a $VCS Project', "Padre $VCS" ) if not $self->_project_root($path);
	my $result = $self->vcs_execute($command, $dir);
	return $result;
}


#
#clone_project
#
# Adds the file to the repository
# $self->vcs_diff($repository, $destination_dir);
# Will clone a repository and place it in the destination dir
# 

sub clone_project
{
	my ($self, $path, $dir) = @_;
	my $main = Padre->ide->wx->main;
	my $command = eval "qq\0$VCSCommand{clone}\0";
	my $result = $self->vcs_execute($command, $dir);
	$main->message( $result, "$VCS Cloning $path" );
	return;
}

#
# pull_update_project
#
# Pulls updates to a project. 
# It will perform an update automatically on the repository
# $self->pull_update_project($file, $projectdir);
# Only pulls changes from the default repository, which is normally
# the one you cloned from.

sub pull_update_project
{
	my ($self, $path, $dir) = @_;
	my $main = Padre->ide->wx->main;
	return $main->error('File not in a $VCS Project', "Padre $VCS" ) if not $self->_project_root($path);
	my $command = eval "qq\0$VCSCommand{pull}\0";
	my $result = $self->vcs_execute($command, $dir);
	$main->message( $result, "$VCS Cloning $path" );
	return;
}


# Pushes updates to a remote repository. 
# Prompts for the username and password. 
# $self->push_project($file, $projectdir);
# Only pushes changes to the default remote repository, which is normally
# the one you cloned from.


sub push_project
{
	my ($self, $path, $dir) = @_;
	my $main = Padre->ide->wx->main;
	return $main->error('File not in a $VCS Project', "Padre $VCS" ) if not $self->_project_root($path);
	my $config_command = 'hg showconfig';
	my $result1 = $self->vcs_execute($config_command, $dir);	#overwriting path on purpose.
	#overwriting path on purpose.
	#gets the configured push path if it exists
	($path) = $result1 =~ /paths.default=(.*)/;
	return $main->error('No default push path', "Padre $VCS" ) if not $path;
	my ($default_username) = $path =~ /\/\/(.*)@/;
	my $prompt = Padre::Plugin::HG::UserPassPrompt->new(
			title=>'Mecurial Push',
			default_username=>$default_username, 
			default_password =>'');
	my $username = $prompt->{username};
	my $password = $prompt->{password};
	$path =~ s/\/(.*)@/\/\/$username:$password@/g;
	my $command = eval "qq\0$VCSCommand{push}\0";
	my $result = $self->vcs_execute($command, $dir);
	$main->message( $result, "$VCS Pushing $path" );
	return;
}



# vcs_execute
#
# Executes a command after changing to the appropriate dir.
# $self->vcs_execute($command, $dir);
# All output is captured and returned as a string.

sub vcs_execute
{
	my ($self, $command, $dir) = @_;
	print "Command $command\n";
	my $busyCursor = Wx::BusyCursor->new();
	my $result = capture_merged(sub{chdir($dir);system($command)});
	if (!$result){$result = "Action Completed"}
	$busyCursor = undef;
	return $result;
}





# show_statusTree
#
# Displays a Project Browser in the side pane. The Browser shows the status of the
# files in HG and gives menu options to perform actions. 


sub show_statusTree
{	
	my ($self) = @_;
	require Padre::Plugin::HG::StatusTree;
	my $main = Padre->ide->wx->main;
	my $project_root = $self->_project_root(current_filename());
	$self->{project_path} = $project_root;
	return $main->error("Not a $VCS Project") if !$project_root;
	# we only want to add a tree for projects that don't already have one. 
	if (!exists($projects{$project_root}) )
	{
		$projects{$project_root} = Padre::Plugin::HG::StatusTree->new($self,$project_root);	
	}
}



# close_statusTree
#
# Closes the Project Browser and deletes the Status tree object

sub close_statusTree
{	
	my ($self) = @_;
	my $project_root = $self->_project_root(current_filename());
	if (exists($projects{$project_root}) )
	{
		delete $projects{$project_root} ;
		print "deleted $project_root\n";
	}
}


#
#
#show_commit_list
#
# Displays a list of all the files that are awaiting commiting. It will include
# not added and deleted files adding and removing them as required. 


sub show_commit_list
{	
	my ($self) = @_;
	my $main = Padre->ide->wx->main;
	 $self->{project_path} = $self->_project_root(current_filename());

	return $main->error("Not a $VCS Project") if ! $self->{project_path} ;
 
	my $obj = Padre::Plugin::HG::ProjectCommit->showList($self);	
	$obj = undef;

}


#
# show_diff
#
# Displays a list of all the files that are awaiting commiting. It will include
# not added and deleted files adding and removing them as required. 


sub show_diff
{	
	my ($self, $file, $path) = @_;
	my $main = Padre->ide->wx->main;
	 $self->{project_path} = $self->_project_root($file);
        my $full_path = File::Spec->catdir(($path,$file));
        return $main->error("Not a $VCS Project") if ! $self->{project_path} ;
 	my $differences = $self->vcs_diff($file, $path);	
	Padre::Plugin::HG::DiffView->showDiff($self,$differences);

	

}

#show_diff_revision
#
# Displays a list of all the revisions for the selected file. 
# Allowing you to choose one to diff the current selection to.  

sub show_diff_revision
{	
	my ($self, $file, $path) = @_;
	my $main = Padre->ide->wx->main;
	 $self->{project_path} = $self->_project_root($file);
        my $full_path = File::Spec->catdir(($path,$file));
	return $main->error("Not a $VCS Project") if ! $self->{project_path} ;
 	my $changeset = Padre::Plugin::HG::LogView->showList($self,$full_path);
	my $differences = $self->vcs_diff_revision($file, $path, $changeset);	
	Padre::Plugin::HG::DiffView->showDiff($self,$differences);


}

#show_commit_list
#
# Displays a list of all the files that are awaiting commiting. It will include
# not added and deleted files adding and removing them as required. 

sub show_log
{	
	my ($self) = @_;
	my $main = Padre->ide->wx->main;
	 $self->{project_path} = $self->_project_root(current_filename());

	return $main->error("Not a $VCS Project") if ! $self->{project_path} ;
	
	my $obj = Padre::Plugin::HG::LogView->showList($self,current_filename());	
	$obj = undef;

}




#show_project_clone
#
# Dialog for project cloning
#

sub show_project_clone
{	
	my ($self) = @_;
	my $main = Padre->ide->wx->main;
	my $clone = Padre::Plugin::HG::ProjectClone->new($self);
	if ($clone->enter_repository())
	{
		$clone->choose_destination();
	}

	if ($clone->project_url()  and $clone->destination_dir())
	{
		$self->clone_project(
			$clone->project_url(),
			$clone->destination_dir()
			); 
	}
        
    
}	


# Event Listner for Save 
# refresh the dir when done
#

sub after_save
{
	my ( $self ) = @_;
	my $project_root = $self->_project_root(current_filename());
	if ($projects{$project_root}){
		$projects{$project_root}->refresh($projects{$project_root}->{treeCtrl});
	}
	print ("saved");
}	




#
# _project_root
#
# $self->_project_root($filename);
# Calculates the project root.  if the file is not in a project it 
# will return 0 
# otherwise it returns the fully qualified path to the project. 


sub _project_root
{
	my ($self, $filename) = @_;
	if (!$filename){
		return 0;
	}
	my $dir = File::Basename::dirname($filename);
	my $project_root = $self->vcs_execute($VCSCommand{root}, $dir);
	#file in not in a HG project.
	if ($project_root =~ m/^abort:/)
	{
			$project_root = 0;
	}
	chomp ($project_root);
	return $project_root;
}


# _get_hg_files
#
# $self->_get_hg_files(@hgStatus);
#  Pass the output of hg status and it will give back an array
#  each element of the array is [$status, $filename]



sub _get_hg_files
{
	my ($self, @hg_status) = @_;
	my @files;
	foreach my $line (@hg_status)
	{
		my ($filestatus, $path) = split(/\s/,$line);
		push (@files, ([$filestatus,$path]));
	}
	return @files;
}


#current_filename 
#
# $self->current_filename();
#  returns the path of the file with the current attention 
#  in the ide


sub current_filename {

	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	my $filename = '';
	if ($doc){
	 $filename = $doc->filename;
	}
	return $main->error("No document found") if not $filename;
        return ($filename); 
}

#parse_log
#
# $self->parse_log($log);;
# Pass it the output of the hg log command and it will 
# return an array of hashes with each array element 
# being  a  hash of the commit values. 
# eg changeset, user, date ...
#



sub parse_log {
	my ($self,$log) = @_;
	
	# log output looks like
	# 
	#changeset:   3:80d72b2a4751
	#user:        bill@microsoft.com
	#date:        Fri Oct 16 07:05:27 2009 +1100
	#summary:     Added files for CPAN distribution
	#
	#changeset:   3:80d72b2a4751
	#user:        bill@microsoft.com
	#date:        Fri Oct 16 07:05:27 2009 +1100
	#summary:     Tricky Comment summary: CPAN distribution
	
	#split the output at blank lines
	my @commits = split(/\n{2,}/, $log);
	my $i = 0;
	my @result;
	foreach my $commit (@commits)
	{
		
		
		$result[$i] = {
			changeset=>$commit =~ /^changeset:\s+(.*)/m,
			user=>$commit=~ /^user:\s+(.*)/m,
			date=>$commit=~ /^date:\s+(.*)/m, 
			summary=>$commit=~ /^summary:\s+(.*)/m,
		} ;
		$i++;
	} 
	
	return @result;
}



# object_for_testing
#
# creates a blessed object so we can run our tests. 
#


sub object_for_testing
{
	my ($class) = @_;
	my $self = {};
	bless $self,$class;
	
	
}

1;

# Copyright 2008-2009 Michael Mueller.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

