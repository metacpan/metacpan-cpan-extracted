package Padre::Plugin::SVN;

use 5.008;
use warnings;
use strict;

use Padre::Config ();
use Padre::Wx     ();
use Padre::Plugin ();
use Padre::Util   ();



use SVN::Class qw(svn_file);

our $VERSION = '0.05';
our @ISA     = 'Padre::Plugin';

=head1 NAME

Padre::Plugin::SVN - Simple SVN interface for Padre

=head1 SYNOPSIS

Requires SVN client tools to be installed.

cpan install Padre::Plugin::SVN

Acces it via Plugin/SVN

=head1 REQUIREMENTS

The plugin requires that the SVN client tools be installed and setup, this includes any cached authentication.

For most of the unices this is a matter of using the package manager to install the svn client tools.

For windows try: http://subversion.tigris.org/getting.html#windows.


=head2 Configuring the SVN client for cached authentication.

Because this module uses the installed SVN client, actions that require authentication from the server will fail and leave Padre looking as though it has hung.

The way to address this is to run the svn client from the command line when asked for the login and password details, enter as required.

Once done you should now have your authentication details cached.

More details can be found here: http://svnbook.red-bean.com/nightly/en/svn.serverconfig.netmodel.html#svn.serverconfig.netmodel.credcache

=head1 AUTHOR

Gabor Szabo, C<< <szabgab at gmail.com> >>

Additional work:

Peter Lavender, C<< <peter.lavender at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<http://padre.perlide.org/>


=head1 COPYRIGHT & LICENSE

Copyright 2008, 2009, 2010 The Padre development team as listed in Padre.pm.
all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

#####################################################################
# Padre::Plugin Methods

sub plugin_enable {
	my $self = shift;
}

# clean up modules used.
sub plugin_disable {
	my $self = shift;

	#require Class::Unload;
	#Class::Unload->unload('Padre::Plugin::SVN::Wx::SVNDialog');
	#Class::Unload->unload('Padre::Plugin::SVN');
}

sub padre_interfaces {
	'Padre::Plugin' => 0.43;
}

sub plugin_name {
	'SVN';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [

		# maybe reorganize according to File/Directory/Project ?
		#'File'		=> [
		Wx::gettext('Add') => [
			Wx::gettext('File')    => sub { $self->svn_add_file },
			Wx::gettext('Dir')     => sub { $self->svn_diff_of_dir },
			Wx::gettext('Project') => sub { $self->svn_diff_of_project },
		],
		Wx::gettext('Blame') => sub { $self->svn_blame },
		Wx::gettext('Commit') => [
			Wx::gettext('File')    => sub { $self->svn_commit_file },
			Wx::gettext('Project') => sub { $self->svn_commit_project },
		],
		Wx::gettext('Diff') => [
			Wx::gettext('File') => [ 
				Wx::gettext('Show')          => sub { $self->svn_diff_of_file }, 
				Wx::gettext('Open in Padre') => sub {$self->svn_diff_in_padre },
			],
			Wx::gettext('Dir')     => sub { $self->svn_diff_of_dir },
			Wx::gettext('Project') => sub { $self->svn_diff_of_project },

		],
		Wx::gettext('Revert') => sub { $self->svn_revert },
		Wx::gettext('Log') => [
			Wx::gettext('File')    => sub { $self->svn_log_of_file },
			Wx::gettext('Project') => sub { $self->svn_log_of_project },
		],
		Wx::gettext('Status') => [
			Wx::gettext('File')    => sub { $self->svn_status_of_file },
			Wx::gettext('Project') => sub { $self->svn_status_of_project },
		],
		Wx::gettext('About') => sub { $self->show_about },
	];
}

#####################################################################
# Custom Methods

sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::SVN");
	$about->SetDescription( <<"END_MESSAGE" );
Initial SVN support for Padre
END_MESSAGE
	$about->SetVersion($VERSION);

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}

# TODO: I see this a lot. Should something like
# this be on Padre::Util?
sub _get_current_filename {
	my $main     = Padre->ide->wx->main;
	my $document = $main->current->document;
	my $filename = $document->filename;
	if ($filename) {

		if ( $document->is_modified ) {
			my $ret = Wx::MessageBox(
				sprintf(
					Wx::gettext(
						      '%s has not been saved but SVN would commit the file from disk.'
							. "\n\nDo you want to save the file first (No aborts commit)?"
					),
					$filename,
				),
				Wx::gettext("Commit warning"),
				Wx::wxYES_NO | Wx::wxCENTRE,
				$main,
			);

			return if $ret == Wx::wxNO;

			$main->on_save;

		}

		return $filename;
	} else {
		$main->error('File needs to be saved first.');
		return;
	}
}

# TODO Add in a timer so long running calls can be stopped at some point.

# TODO: update!

sub svn_revert {
	my ($self) = @_;

	# firstly warn the person their actions will
	# go back to the last version of the file

	my $main   = Padre::Current->main;
	my $layout = [
		[   [   'Wx::StaticText', undef,
				"Warning!\n\nSVN Revert will revert the current file saved to the file system.\n\nIt will not change your current document if you have unsaved changes.\n\nReverting your changes means you will lose any changes made since your last SVN Commit."
			],

		],
		[   [ 'Wx::Button', 'ok',     Wx::wxID_OK ],
			[ 'Wx::Button', 'cancel', Wx::wxID_CANCEL ]
		]
	];
	my $dialog = Wx::Perl::Dialog->new(
		parent => $main,
		title  => 'SVN Revert',
		layout => $layout,
		width  => [ 500, 1200 ],

	);
	return if not $dialog->show_modal;
	my $data = $dialog->get_data;
	if ( $data->{cancel} ) {

		#print "Canceling the revert\n";
		return;
	} else {

		#
		my $filename = _get_current_filename();
		if ($filename) {
			my $file = svn_file($filename);
			$file->revert();
		}
	}
}


sub svn_blame {
	my ($self) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		my $main = Padre::Current->main;
		$self->{_busyCursor} = Wx::BusyCursor->new();
		my $file = svn_file($filename);
		$file->blame();
		
		#my $blame = join( "\n", @{ $file->stdout } );
		my @blame = @{ $file->stdout };
		require Padre::Plugin::SVN::Wx::SVNDialog;
		my $dialog = Padre::Plugin::SVN::Wx::SVNDialog->new( $main, $filename, \@blame, 'Blame' );
		$self->{_busyCursor} = undef;
		$dialog->Show(1);
		return 1;
	}

	return;

}

sub svn_status {
	my ( $self, $path ) = @_;
	my $main = Padre->ide->wx->main;

	my $file = svn_file($path);

	my $info = "";

	if ( $file->info ) {

		#print $file->info->dump();
		$info .= "Author: " . $file->info->{author} . "\n";
		$info .= "File Name: " . $file->info->{name} . "\n";
		$info .= "Last Revision: " . $file->info->{last_rev} . "\n";
		$info .= "Current Revision: " . $file->info->{rev} . "\n\n";

		$info .= "File create Date: " . $file->info->{date} . "\n\n";

		$info .= "Last Updated: " . $file->info->{updated} . "\n\n";

		$info .= "File Path: " . $file->info->{path} . "\n";
		$info .= "File URL: " . $file->info->{_url} . "\n";
		$info .= "File Root: " . $file->info->{root} . "\n\n";

		$info .= "Check Sum: " . $file->info->{checksum} . "\n";
		$info .= "UUID: " . $file->info->{uuid} . "\n";
		$info .= "Schedule: " . $file->info->{schedule} . "\n";
		$info .= "Node: " . $file->info->{node} . "\n\n";
	} else {
		$info .= 'File is not managed by SVN';
	}

	#print $info;
	$main->message( $info, "$path" );
	return;
}

sub svn_status_of_file {
	my ($self) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		$self->svn_status($filename);
	}
	return;
}

sub svn_status_of_project {
	my ($self) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		my $main = Padre::Current->main;
		my $dir  = Padre::Util::get_project_dir($filename);
		return $main->error( Wx::gettext('Could not find project root') ) if not $dir;
		$self->svn_status($dir);
	}
	return;
}


sub svn_log {
	my ( $self, $path ) = @_;
	my $main = Padre->ide->wx->main;

	my $file = svn_file($path);
	$self->{_busyCursor} = Wx::BusyCursor->new();
	my $out = join( "\n", @{ $file->log() } );
	$self->{_busyCursor} = undef;

	#$main->message( $out, "$path" );
	require Padre::Plugin::SVN::Wx::SVNDialog;
	my $log = Padre::Plugin::SVN::Wx::SVNDialog->new( $main, $path, $out, 'Log' );
	$log->Show(1);


}

sub svn_log_of_file {
	my ($self) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		$self->svn_log($filename);
	}
	return;
}

sub svn_log_of_project {
	my ($self) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		my $main = Padre::Current->main;
		my $dir  = Padre::Util::get_project_dir($filename);
		return $main->error( Wx::gettext('Could not find project root') ) if not $dir;
		$self->svn_log($dir);
	}
	return;
}




sub svn_diff {
	my ( $self, $path ) = @_;
	my $main = Padre->ide->wx->main;

	my $file = svn_file($path);

	#print $file->stderr;
	#print $file->stdout;

	$file->diff();
	my $status = join( "\n", @{ $file->stdout } );

	#$main->message( $status, "$path" );
	require Padre::Plugin::SVN::Wx::SVNDialog;
	my $log = Padre::Plugin::SVN::Wx::SVNDialog->new( $main, $path, $status, 'Diff' );
	$log->Show(1);

	return;

}

sub svn_diff_in_padre {
	my ($self)   = @_;
	my $filename = _get_current_filename();
	my $main     = Padre->ide->wx->main;


	if ($filename) {
		my $file     = svn_file($filename);
		my $diff     = $file->diff;
		my $diff_str = join( "\n", @{ $file->stdout } );
		$main->new_document_from_string( $diff_str, 'text/x-patch' );
		return 1;
	}
	return;

}

sub svn_diff_of_file {
	my ($self) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		$self->svn_diff($filename);
	}
	return;
}

sub svn_diff_of_project {
	my ($self) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		my $dir = Padre::Util::get_project_dir($filename);
		$self->svn_diff($dir);
	}
	return;
}

sub svn_commit {
	my ( $self, $path ) = @_;

	my $main = Padre->ide->wx->main;
	my $file = svn_file($path);

# 	== 0 seems to produce false errors here
#	if (( ! defined($file)) or ($file == 0)){
	if ( ! defined($file)){
		$main->error(Wx::gettext('Unable to find SVN file!'),Wx::gettext('Error - SVN Commit'));
		return;
	}

	my $info = "$path\n\n";
	if ( defined( $file->info->{last_rev} ) ) {
		$info .= "Last Revision: " . $file->info->{last_rev};
	} else { # New files
		$info .= "Last Revision: (none)";
	}
	
	require Padre::Plugin::SVN::Wx::SVNDialog;
	my $dialog = Padre::Plugin::SVN::Wx::SVNDialog->new( $main, $info, undef, 'Commit File', 1 );
	$dialog->ShowModal;

	# check Cancel!!!!
	return if( $dialog->{cancelled});
	
	my $message = $dialog->get_data;

	
	

	# whoops!! This isn't going to work "Commit message" is always set in the text control.
	if ($message && $message ne 'Commit Message') { # "Commit Message" come from SVNDialog
		$self->{_busyCursor} = Wx::BusyCursor->new();

		my $revNo = $file->commit($message);

		$self->{_busyCursor} = undef;

		my @commit = @{ $file->stdout };
		my @err    = @{ $file->stderr };
		if (@err) {
			$main->error( join( "\n", @err ), Wx::gettext('Error - SVN Commit') );
		} else {
			$main->info( join( "\n", @commit ), "Committed Revision number $revNo." );
		}

	}
	else {
	    my $ret = Wx::MessageBox( Wx::gettext(
				  'You really should commit with a useful message'
				  .  "\n\nDo you really want to commit with out a message?"
			    ),
				    Wx::gettext("Commit warning"),
				    Wx::wxYES_NO | Wx::wxCENTRE,
				    $main,
			    );
	    if( $ret == Wx::wxYES ) {
		$self->{_busyCursor} = Wx::BusyCursor->new();

		my $revNo = $file->commit($message);

		$self->{_busyCursor} = undef;

		my @commit = @{ $file->stdout };
		my @err    = @{ $file->stderr };
		if (@err) {
			$main->error( join( "\n", @err ), 'Error - SVN Commit' );
		} else {
			$main->info( join( "\n", @commit ), "Committed Revision number $revNo." );
		}		    
	    }
	    else {
		$self->svn_commit($path);    
	    }
	
	}

	return;
}

sub svn_commit_file {
	my ($self) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		$self->svn_commit($filename);
	}
	return;
}

sub svn_commit_project {
	my ($self) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		my $dir = Padre::Util::get_project_dir($filename);
		$self->svn_commit($dir);
	}
	return;
}

sub svn_add {
	my ( $self, $path ) = @_;
	
	my $main = Padre->ide->wx->main;

	my $file = svn_file($path);
	$file->add;
	if ($file->errstr) {
		$main->error($file->errstr);
	} else {
		$main->info("$path scheduled to be added to " . $file->info->{_url});
	}

	return;
}

sub svn_add_file {
	my ($self) = @_;
	my $filename = _get_current_filename();
	if ($filename) {
		$self->svn_add($filename);
	}
	return;
}

1;

