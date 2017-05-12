package PerlFM;

use warnings;
use strict;
use Gtk2;
use Gtk2::PathButtonBar;
use Gtk2::SimpleList;
use Cwd qw(chdir abs_path cwd);
use ZConf::Runner;
use File::Stat::Bits;
use String::ShellQuote;
use ZConf::Bookmarks;
use Gtk2::Chmod;
use File::MimeInfo::Magic;
use Dir::Watch;

=head1 NAME

PerlFM - A Perl based file manager.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';


=head1 SYNOPSIS

    use PerlFM;
    use Gtk2;
    
    my $pfm = PerlFM->new();
    
    Gtk2->init;
    
    my $window = Gtk2::Window->new();
    
    my %gui=$pfm->filemanager;
    
    $window->add($gui->{VB});
    
    $window->show;
    
    Gtk2-main;

=head1 METHODES

=head2 new

Initiates the new function.

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	
	my $self={error=>undef, errorString=>'', defaultAction=>'view'};
	bless $self;
	
	Gtk2->init;

	$self->{zcr}=ZConf::Runner->new;
	$self->{zcbm}=ZConf::Bookmarks->new;

	return $self;
}

=head2 addBM

This is the call back that is called when the addBM button is clicked.

=cut

sub addBM{
	my %h;
	if (defined($_[1])) {
		%h=%{$_[1]};
	}

	my @selected=$_[1]{gui}{list}->get_selected_indices;
	
	my $entry=$_[1]{self}{data}{ $_[1]{gui}{id} }{data}{reverse}[$selected[0]];

	my $path=cwd().'/'.$entry;

	my $text='';
	my $window = Gtk2::Dialog->new($text,
								   undef,
								   [qw/modal destroy-with-parent/],
								   'gtk-cancel'     => 'cancel',
								   'gtk-ok'     => 'accept',
								   );
	
	$window->set_position('center-always');
	
	$window->set_response_sensitive ('accept', 0);
	$window->set_response_sensitive ('reject', 0);
	
	my $vbox = $window->vbox;
	$vbox->set_border_width(5);
	
	my $label = Gtk2::Label->new_with_mnemonic('Add a new bookmark?');
	$vbox->pack_start($label, 0, 0, 1);
	$label->show;

	#path stuff
	my $phbox=Gtk2::HBox->new;
	$phbox->show;
	my $plabel=Gtk2::Label->new('path: ');
	$plabel->show;
	$phbox->pack_start($plabel, 0, 1, 0);
	my $pentry = Gtk2::Entry->new();
	$pentry->set_editable(0);
	$pentry->set_text($path);
	$pentry->show;
	$phbox->pack_start($pentry, 1, 1, 0);
	$vbox->pack_start($phbox, 0, 0, 1);
	
	#name stuff
	my $nhbox=Gtk2::HBox->new;
	$nhbox->show;
	my $nlabel=Gtk2::Label->new('name: ');
	$nlabel->show;
	$nhbox->pack_start($nlabel, 0, 1, 0);
	my $nentry = Gtk2::Entry->new();
	$nentry->set_text($path);
	$nhbox->pack_start($nentry, 1, 1, 0);
	$nentry->show;	
	$vbox->pack_start($nhbox, 0, 0, 1);

	#description stuff
	my $dhbox=Gtk2::HBox->new;
	$dhbox->show;
	my $dlabel=Gtk2::Label->new('description: ');
	$dlabel->show;
	$dhbox->pack_start($dlabel, 0, 1, 0);
	my $dentry = Gtk2::Entry->new();
	$dentry->set_text($path);
	$dhbox->pack_start($dentry, 1, 1, 0);
	$dentry->show;	
	$vbox->pack_start($dhbox, 0, 0, 1);

	$dentry->signal_connect (changed => sub {
								my $text = $dentry->get_text;
								$window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								$window->set_response_sensitive ('reject', 1);
							}
							);

	$nentry->signal_connect (changed => sub {
								my $text = $nentry->get_text;
								$window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								$window->set_response_sensitive ('reject', 1);
							}
							);
	
	my $name;
	my $description;
	my $pressed;
	
	$window->signal_connect(response => sub {
								$name=$nentry->get_text;
								$description=$dentry->get_text;
								$pressed=$_[1];
							}
							);
	#runs the dailog and gets the response
	#'cancel' means the user decided not to create a new set
	#'accept' means the user wants to create a new set with the entered name
	my $response=$window->run;
	
	$window->destroy;

	if ($pressed ne 'accept') {
		#update the stuff
		$_[1]{self}->update( $_[1]{gui}{id}, $_[1]{self} );
		return undef;
	}

	#add the bookmark
	$_[1]{self}{zcbm}->addBookmark({
									scheme=>'file',
									name=>$name,
									link=>$path,
									description=>$description,
									});
	
	#update the stuff
	$_[1]{self}->update( $_[1]{gui}{id}, $_[1]{self} );
	$_[1]{self}->updateBM( \%{$_[1]{gui}}, $_[1]{self} );
}

=head2 app

This invokes it as application.

Upon the window being destroyed, it will exit.

This method does not return. Upon being called it creates
a window and when that window is destroyed, it exits.

=head3 args hash

=head4 path

This is the path to start in.

=head4 hidden

If this is set to true, hidden files will be shown.

    $args{path}='/tmp';
    $args{hidden}=0;
    $pfm->app(\%args);

=cut

sub app{
	my $self=$_[0];
	my %args;
	if (defined($_[1])) {
		%args=%{$_[1]};
	}

	my %window=$self->window();
	$window{window}->show;

	$window{window}->signal_connect('delete-event'=>sub{
										exit 0;
									}
									);

	Gtk2->main;
}

=head2 askYN

This is used in a few places to present a yes/no dialog.



=cut

sub askYN{
        my $text=$_[0];

        my $window = Gtk2::Dialog->new($text,
									   undef,
									   [qw/modal destroy-with-parent/],
									   'gtk-cancel'     => 'cancel',
									   'gtk-ok'     => 'ok',
									   );
		
        $window->set_position('center-always');

        $window->set_response_sensitive ('accept', 0);
        $window->set_response_sensitive ('reject', 0);

        my $vbox = $window->vbox;
        $vbox->set_border_width(5);

        my $label = Gtk2::Label->new_with_mnemonic($text);
        $vbox->pack_start($label, 0, 0, 1);
        $label->show;

        my $pressed;

        $window->signal_connect(response => sub {
									$pressed=$_[1];
								}
								);
        #runs the dailog and gets the response
        #'cancel' means the user decided not to create a new set
        #'ok' means the user wants to create a new set with the entered name
        my $response=$window->run;

        $window->destroy;

        return $pressed;
}

=head2 checkForUpdate

This checks for any updates to a directory.

One arguement is accepted and it is a 

    $pfm->checkForUpdate($guiID);

=cut

sub checkForUpdate{
	my $self=$_[0];
	my $guiID=$_[1];

	if (!defined($self->{gui}{$guiID})) {
		return undef;
	}

	if ( $self->{gui}{$guiID}{watcher}->check() ) {
		$self->update($guiID, $self);
	}

	return 1;
}

=head2 chmod

This is the call back that is called when a chmod key/button is pressed.

=cut

sub chmod{
	my @selected=$_[1]->{gui}{list}->get_selected_indices;
	
	#get the entry
	my $entry=$_[1]{self}{data}{ $_[1]{gui}{id} }{data}{reverse}[$selected[0]];

	#
	my %returned=Gtk2::Chmod->ask($entry);

	#return if ok was pressed
	if ($returned{pressed} ne 'ok') {
		#update the stuff
		$_[1]{self}->update( $_[1]{gui}{id}, $_[1]{self} );
		return undef;
	}

	#process each entry
	my $int=0;
	while (defined($selected[$int])) {
		$entry=$_[1]{self}{data}{ $_[1]{gui}{id} }{data}{reverse}[$selected[$int]];
		
		#choose the proper method for file/directory
		if (-d $entry) {
			#use chmod binary if needed
			if ($returned{recursive}) {
				system('chmod -R '.shell_quote($returned{dirmode}).' '.shell_quote($entry) );
			}else {
				chmod(oct($returned{dirmode}), $entry);
			}
		}else {
			chmod(oct($returned{filemode}), $entry);
		}

		$int++;
	}

	#update the stuff
	$_[1]{self}->update( $_[1]{gui}{id}, $_[1]{self} );
}

=head2 chown

This is the call back that is called when a mkdir key/button is pressed.

=cut

sub chown{
	my $text='';
	my $window = Gtk2::Dialog->new($text,
								   undef,
								   [qw/modal destroy-with-parent/],
								   'gtk-cancel'     => 'cancel',
								   'gtk-save'     => 'accept',
								   );
	
	$window->set_position('center-always');
	
	$window->set_response_sensitive ('accept', 0);
	$window->set_response_sensitive ('reject', 0);
	
	my $vbox = $window->vbox;
	$vbox->set_border_width(5);
	
	my $label = Gtk2::Label->new_with_mnemonic('Change user/group ownership?');
	$vbox->pack_start($label, 0, 0, 1);
	$label->show;

	#group stuff
	my $ghbox=Gtk2::HBox->new;
	$ghbox->show;
	my $glabel=Gtk2::Label->new('group: ');
	$glabel->show;
	$ghbox->pack_start($glabel, 0, 1, 0);
	my $gentry = Gtk2::Entry->new();
	$gentry->show;
	$ghbox->pack_start($gentry, 0, 1, 0);
	$vbox->pack_start($ghbox, 0, 0, 1);
	
	#user stuff
	my $uhbox=Gtk2::HBox->new;
	$uhbox->show;
	my $ulabel=Gtk2::Label->new('user');
	$ulabel->show;
	$uhbox->pack_start($ulabel, 0, 1, 0);
	my $uentry = Gtk2::Entry->new();
	$uhbox->pack_start($uentry, 0, 1, 0);
	$uentry->show;	
	$vbox->pack_start($uhbox, 0, 0, 1);

	#check button
	my $recursivecheck=Gtk2::CheckButton->new('recursive');
	$recursivecheck->show;
	$vbox->pack_start($recursivecheck, 0, 0, 1);
	
	$uentry->signal_connect (changed => sub {
								my $text = $uentry->get_text;
								$window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								$window->set_response_sensitive ('reject', 1);
							}
							);

	$gentry->signal_connect (changed => sub {
								my $text = $gentry->get_text;
								$window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								$window->set_response_sensitive ('reject', 1);
							}
							);
	
	my $user;
	my $group;
	my $pressed;
	
	$window->signal_connect(response => sub {
								$user=$uentry->get_text;
								$group=$gentry->get_text;
								$pressed=$_[1];
							}
							);
	#runs the dailog and gets the response
	#'cancel' means the user decided not to create a new set
	#'accept' means the user wants to create a new set with the entered name
	my $response=$window->run;
	
	$window->destroy;

	if ($pressed eq 'reject') {
		return undef;
	}

	#set the pressed to reject if 
	if (($user eq '' )&&($group eq '')) {
		$pressed='reject'
	}

	#convert the user to a uid if the ownership is not a digit
	if ($user !~ /[[:digit:]]/) {
		my ($login, $pass, $uid)=getpwnam($user);
		if (defined($uid)) {
			$user=$uid;
		}
	}

	#convert the user to a uid if the ownership is not a digit
	if ($group !~ /[[:digit:]]/) {
		my ($name,$passwd,$gid,$members)=getgrnam($user);
		if (defined($gid)) {
			$group=$gid;
		}
	}

	#gets the data
	my %data=$_[1]{self}->datahash($_[1]{gui}{check}->get_active);

	#get the entries in question
	my @entries;
	my @selected=$_[1]{gui}{list}->get_selected_indices;
	my $int=0;
	while (defined($selected[$int])) {
		my $entry=$data{reverse}[$selected[$int]];

		push(@entries, $entry);
		
		$int++;
	}


	#chown it
	chown($user, $group, @entries);

	#update the stuff
	$_[1]{self}->update( $_[1]{gui}{id}, $_[1]{self} );
}


=head2 datahash

This builds the data hash for the current directory. This is primarily for
internal use.

=cut

sub datahash{
	my $self=$_[0];
	my $hidden=$_[1];
	
	my $path=cwd;
	
	my %data;
	$data{names}={};

	#populates data hash
	opendir(FILEMANAGER, $path);
	my $entry=readdir(FILEMANAGER);
	while (defined($entry)) {
		my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($entry);

		my $add=1;

		#if it is a hidden file, check if it should be added or not
		if ($entry =~ /^\./) {
			$add=0;
			if ($hidden || (($entry eq '.')||($entry eq '..')) ) {
				$add=1;
			}
		}

		if ($add) {
			if (-d $entry) {
				$entry=$entry.'/';
			}
			
			$data{names}{$entry}={
								  dev=>$dev, inode=>$ino, mode=>$mode, nlink=>$nlink,
								  uid=>$uid, gid=>$gid, rdev=>$rdev, size=>$size,
								  atime=>$atime, mtime=>$mtime, ctime=>$ctime,
								  blksize=>$blksize, blocks=>$blocks,
								  };
			
		}
		$entry=readdir(FILEMANAGER);
	}
	closedir(FILEMANAGER);
	
	#sort the entries
	my @entries=keys(%{$data{names}});
	@entries=sort(@entries);

	#puts them all together
	my @r1;
	my @r2;
	my $int=0;
	while (defined($entries[$int])) {
		if (-d $entries[$int]) {
			push(@r1, $entries[$int]);
		}else {
			push(@r2, $entries[$int]);			
		}

		$int++;
	}
	my @sortedentries=@r1;
	push(@sortedentries, @r2);

	$data{reverse}=\@sortedentries;

	#
	my @dirs;
	$int=0;
	while (defined($entries[$int])) {
		if (-d $entries[$int]) {
			push(@dirs, $entries[$int]);
		}

		$int++;
	}

	my @sorteddirs=sort(@dirs);

	$data{dirreverse}=\@sorteddirs;

	#this puts together the mode strings
	my $mode='';
	$int=0;
	while (defined( $data{reverse}[$int] )) {
		my $entry=$data{reverse}[$int];
		my $bmode=$data{names}{$entry}{mode};

		#user read
		if (S_IRUSR & $bmode) {
			$mode=$mode.'r';
		}else {
			$mode=$mode.'-';
		}
		#user write
		if (S_IWUSR & $bmode) {
			$mode=$mode.'w';
		}else {
			$mode=$mode.'-';
		}
		#user exec
		if (S_ISUID & $bmode) {
			$mode=$mode.'s';
		}else {
			if (S_IXUSR & $bmode) {
				$mode=$mode.'x';
			}else {
				$mode=$mode.'-';
			}
		}

		#group read
		if (S_IRGRP & $bmode) {
			$mode=$mode.'r';
		}else {
			$mode=$mode.'-';
		}
		#group write
		if (S_IWGRP & $bmode) {
			$mode=$mode.'w';
		}else {
			$mode=$mode.'-';
		}
		#group exec
		if (S_ISGID & $bmode) {
			$mode=$mode.'s';
		}else {
			if (S_IXGRP & $bmode) {
				$mode=$mode.'x';
			}else {
				$mode=$mode.'-';
			}
		}

		#other read
		if (S_IROTH & $bmode) {
			$mode=$mode.'r';
		}else {
			$mode=$mode.'-';
		}
		#other write
		if (S_IWOTH & $bmode) {
			$mode=$mode.'w';
		}else {
			$mode=$mode.'-';
		}
		#other exec
		if (S_IXOTH & $bmode) {
			$mode=$mode.'x';
		}else {
			$mode=$mode.'-';
		}

		$data{names}{$entry}{mode}=$mode;

		$mode='';
		$int++;
	}

	return %data;
}

=head2 delete

This is a call back the handles deleting files.

=cut

sub delete{

	#ask if it should delete them
	my $returned=askYN('Delete the selected files?');
	#if not, return
	if ($returned ne 'ok') {
		#update the stuff
		$_[1]{self}->update( $_[1]{gui}{id}, $_[1]{self} );
		return undef;
	}
	

	my @selected=$_[1]->{gui}{list}->get_selected_indices;

	#gets the data
	#my %data=$_[1]{self}->datahash($_[1]{gui}{check}->get_active);
	

	my $int=0;
	while (defined($selected[$int])) {
		my $entry=$_[1]{self}{data}{ $_[1]{gui}{id} }{data}{reverse}[$selected[$int]];
		if (-d $entry) {
			rmdir($entry);
		}
		if (-f $entry) {
			unlink($entry);
		}

		$int++;
	}

	#update the stuff
	$_[1]{self}->update( $_[1]{gui}{id}, $_[1]{self} );
}

=head2 deleteBM

This is the call back used when the currently seleced book mark
is being deleted.

=cut

sub deleteBM{
	#ask if it should delete them
	my $returned=askYN('Delete the selected bookmarks?');
	#if not, return
	if ($returned ne 'ok') {
		#update the stuff
		$_[1]{self}->update( $_[1]{gui}{id}, $_[1]{self} );
		return undef;
	}

	my @selected=$_[1]->{gui}{bmlist}->get_selected_indices;
	
	my $int=0;
	while (defined($selected[$int])) {
		my $bmID=$_[1]{self}->{bookmarkReverse}[$selected[$int]];

		$_[1]{self}->{zcbm}->delBookmark('file', $bmID);

		$int++;
	}
	
	#update the stuff
	$_[1]{self}->update( $_[1]{gui}{id}, $_[1]{self} );
	$_[1]{self}->updateBM( \%{$_[1]{gui}}, $_[1]{self} );
}

=head2 editBM

This is the call back used for editing the current bookmark.

=cut

sub editBM{
	my @selected=$_[1]->{gui}{bmlist}->get_selected_indices;

	#make sure something is selected
	if (!defined($selected[0])) {
		return undef;
	}

	#gets the bookmark ID
	my $bmid=$_[1]{self}->{bookmarkReverse}[$selected[0]];

	if (!defined($bmid)) {
		return undef;
	}

	#gets the bookmark
	my %bookmark=$_[1]{self}->{zcbm}->getBookmark('file', $bmid);
	if (!defined( $bookmark{name} )) {
		return undef;
	}

	my $window = Gtk2::Dialog->new('',
								   undef,
								   [qw/modal destroy-with-parent/],
								   'gtk-cancel'     => 'cancel',
								   'gtk-ok'     => 'accept',
								   );
	
	$window->set_position('center-always');
	
	$window->set_response_sensitive ('accept', 0);
	$window->set_response_sensitive ('reject', 0);
	
	my $vbox = $window->vbox;
	$vbox->set_border_width(5);
	
	my $label = Gtk2::Label->new_with_mnemonic('Edit a bookmark?');
	$vbox->pack_start($label, 0, 0, 1);
	$label->show;

	#path stuff
	my $phbox=Gtk2::HBox->new;
	$phbox->show;
	my $plabel=Gtk2::Label->new('path: ');
	$plabel->show;
	$phbox->pack_start($plabel, 0, 1, 0);
	my $pentry = Gtk2::Entry->new();
	$pentry->set_editable(1);
	$pentry->set_text($bookmark{link});
	$pentry->show;
	$phbox->pack_start($pentry, 1, 1, 0);
	$vbox->pack_start($phbox, 0, 0, 1);
	
	#name stuff
	my $nhbox=Gtk2::HBox->new;
	$nhbox->show;
	my $nlabel=Gtk2::Label->new('name: ');
	$nlabel->show;
	$nhbox->pack_start($nlabel, 0, 1, 0);
	my $nentry = Gtk2::Entry->new();
	$nentry->set_text($bookmark{name});
	$nhbox->pack_start($nentry, 1, 1, 0);
	$nentry->show;	
	$vbox->pack_start($nhbox, 0, 0, 1);

	#description stuff
	my $dhbox=Gtk2::HBox->new;
	$dhbox->show;
	my $dlabel=Gtk2::Label->new('description: ');
	$dlabel->show;
	$dhbox->pack_start($dlabel, 0, 1, 0);
	my $dentry = Gtk2::Entry->new();
	$dentry->set_text($bookmark{description});
	$dhbox->pack_start($dentry, 1, 1, 0);
	$dentry->show;	
	$vbox->pack_start($dhbox, 0, 0, 1);

	$dentry->signal_connect (changed => sub {
								my $text = $dentry->get_text;
								$window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								$window->set_response_sensitive ('reject', 1);
							}
							);

	$pentry->signal_connect (changed => sub {
								 my $text = $dentry->get_text;
								 $window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								 $window->set_response_sensitive ('reject', 1);
							 }
							 );

	$nentry->signal_connect (changed => sub {
								my $text = $nentry->get_text;
								$window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								$window->set_response_sensitive ('reject', 1);
							}
							);
	
	my $name;
	my $description;
	my $pressed;
	my $path;
	
	$window->signal_connect(response => sub {
								$name=$nentry->get_text;
								$description=$dentry->get_text;
								$path=$pentry->get_text;
								$pressed=$_[1];
							}
							);
	#runs the dailog and gets the response
	#'cancel' means the user decided not to create a new set
	#'accept' means the user wants to create a new set with the entered name
	my $response=$window->run;
	
	$window->destroy;

	if ($pressed ne 'accept') {
		#update the stuff
		$_[1]{self}->update( $_[1]{gui}{id}, $_[1]{self} );
		return undef;
	}

	#add the bookmark
	$_[1]{self}{zcbm}->modBookmark({
									scheme=>'file',
									bmid=>$bmid,
									name=>$name,
									link=>$path,
									description=>$description,
									});
	
	#update the stuff
	$_[1]{self}->update( $_[1]{gui}{id}, $_[1]{self} );
	$_[1]{self}->updateBM( { gui=>$_[1]{gui}, self=>$_[1]{self} });

}

=head2 filemanager

This returns a hash that contains the various elements.

=head3 args hash

=head4 path

This is the path to start in.

=head4 hidden

If this is set to true, hidden files will be shown.

    $args{path}='/tmp';
    $args{hidden}=0;
    
    my %gui=$pfm->filemanager(\%args);
    
    #get it again after it has been created
    my $guiID=$gui{id};
    %gui=%{$pfm->{gui}{$guID}};

=cut

sub filemanager{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	
	$self->errorblank;
	
	if (!defined($args{path})) {
		$args{path}=cwd;
	}

	#go to the specified path
	chdir($args{path});

	#init the gui hash
	my %gui;
	$gui{id}=rand().rand();

	#turn on view hidden by default
	$gui{hidden}=$args{hidden};

	#this is what will be returned
	$gui{VB}=Gtk2::VBox->new;
	$gui{VB}->show;

	#puts together the button box
	$gui{buttonHB}=Gtk2::HBox->new;
	$gui{buttonHB}->show;
	#menu init
	$gui{menubar}=Gtk2::MenuBar->new;
	$gui{menubarmenu}=Gtk2::MenuItem->new('_m');
	$gui{menubar}->show;
	$gui{menubarmenu}->show;
	$gui{menu}=Gtk2::Menu->new;
	$gui{menu}->show;
	$gui{menuTearoff}=Gtk2::TearoffMenuItem->new;
	$gui{menuTearoff}->show;
	$gui{menu}->append($gui{menuTearoff});
	$gui{menubarmenu}->set_submenu($gui{menu});
	$gui{menubar}->append($gui{menubarmenu});
	#check
	$gui{check}=Gtk2::CheckMenuItem->new('show _hidden');
	$gui{check}->show;
	$gui{check}->set_active($gui{hidden});
	$gui{check}->signal_connect(toggled=>sub{
									$_[1]{self}{gui}{ $_[1]{id} }{hidden}=$_[1]{self}{gui}{ $_[1]{id} }{check}->get_active;
									$_[1]{self}->update( $_[1]{id}, $_[1]{self} );
								},
								{
								 self=>$self,
								 id=>$gui{id},
								 }
								);
	$gui{menu}->append($gui{check});
	$gui{menuS0}=Gtk2::SeparatorMenuItem->new();
	$gui{menuS0}->show;
	$gui{menu}->append($gui{menuS0});
	#delete menu item
	$gui{delete}=Gtk2::MenuItem->new('_delete');
	$gui{delete}->show;
	$gui{delete}->signal_connect(activate=>\&delete,
								 {
								  gui=>\%gui,
								  self=>$self,
								  }
								 );
	$gui{menu}->append($gui{delete});
	#mkdir menu item
	$gui{mkdir}=Gtk2::MenuItem->new('_mkdir');
	$gui{mkdir}->show;
	$gui{mkdir}->signal_connect(activate=>\&mkdir,
								 {
								  gui=>\%gui,
								  self=>$self,
								  }
								 );
	$gui{menu}->append($gui{mkdir});
	$gui{menuS1}=Gtk2::SeparatorMenuItem->new();
	$gui{menuS1}->show;
	$gui{menu}->append($gui{menuS1});
	#chmod
	$gui{chmod}=Gtk2::MenuItem->new('_chmod');
	$gui{chmod}->show;
	$gui{chmod}->signal_connect(activate=>\&chmod,
								 {
								  gui=>\%gui,
								  self=>$self,
								  }
								 );
	$gui{menu}->append($gui{chmod});
	#chown
	$gui{chown}=Gtk2::MenuItem->new('ch_own');
	$gui{chown}->show;
	$gui{chown}->signal_connect(activate=>\&chown,
								 {
								  gui=>\%gui,
								  self=>$self,
								  }
								 );
	$gui{menu}->append($gui{chown});
	$gui{menuS2}=Gtk2::SeparatorMenuItem->new();
	$gui{menuS2}->show;
	$gui{menu}->append($gui{menuS2});
	#show directories
	$gui{showdirectories}=Gtk2::MenuItem->new('show directories (_l)');
	$gui{showdirectories}->show;
	$gui{showdirectories}->signal_connect(activate=>sub{
											  #gets the current page
											  my $cp=$_[1]{self}{gui}{ $_[1]{id} }{DBnotebook}->get_current_page;
											  
											  if ($cp ne '0') {
												  $_[1]{self}{gui}{ $_[1]{id} }{DBnotebook}->set_current_page(0);
												  $_[1]{self}{gui}{ $_[1]{id} }{hpaned}->set_position(230);
												  $_[1]{self}{gui}{ $_[1]{id} }{dirlist}->grab_focus;
											  }else {
												  my $pos=$_[1]{self}{gui}{ $_[1]{id} }{hpaned}->get_position();
												  if ($pos ne '0') {
													  $_[1]{self}{gui}{ $_[1]{id} }{hpaned}->set_position(0);
													  $_[1]{self}{gui}{ $_[1]{id} }{list}->grab_focus;
												  }else {
													  $_[1]{self}{gui}{ $_[1]{id} }{hpaned}->set_position(230);
													  $_[1]{self}{gui}{ $_[1]{id} }{dirlist}->grab_focus;
												  }
											  }
										  },
										  {
										   id=>$gui{id},
										   self=>$self,
										  }
										  );
	$gui{menu}->append($gui{showdirectories});
	#show bookmarks
	$gui{showbookmarks}=Gtk2::MenuItem->new('show _bookmarks');
	$gui{showbookmarks}->show;
	$gui{showbookmarks}->signal_connect(activate=>sub{
											#gets the current page
											my $cp=$_[1]{self}{gui}{ $_[1]{id} }{DBnotebook}->get_current_page;
											
											if ($cp ne '1') {
												$_[1]{self}{gui}{ $_[1]{id} }{DBnotebook}->set_current_page(1);
												$_[1]{self}{gui}{ $_[1]{id} }{hpaned}->set_position(230);
												$_[1]{self}{gui}{ $_[1]{id} }{bmlist}->grab_focus;
											}else {
												my $pos=$_[1]{self}{gui}{ $_[1]{id} }{hpaned}->get_position();
												if ($pos ne '0') {
													$_[1]{self}{gui}{ $_[1]{id} }{hpaned}->set_position(0);
													$_[1]{self}{gui}{ $_[1]{id} }{list}->grab_focus;
												}else {
													$_[1]{self}{gui}{ $_[1]{id} }{hpaned}->set_position(230);
													$_[1]{self}{gui}{ $_[1]{id} }{bmlist}->grab_focus;
												}
											}
										  },
										  {
										   id=>$gui{id},
										   self=>$self,
										  }
										  );
	$gui{menu}->append($gui{showbookmarks});
	$gui{menuS3}=Gtk2::SeparatorMenuItem->new();
	$gui{menuS3}->show;
	$gui{menu}->append($gui{menuS3});
	#quit
	$gui{quit}=Gtk2::MenuItem->new('_quit');
	$gui{quit}->show;
	$gui{quit}->signal_connect(activate=>sub{
								   Gtk2->main_quit;
								   exit 0;
							   },
							   {
								id=>$gui{id},
								self=>$self,
								}
							   );
	$gui{menu}->append($gui{quit});
	#put it together
	$gui{buttonHB}->pack_start($gui{menubar}, 0, 0, 0);
	$gui{VB}->pack_start($gui{buttonHB}, 0, 1, 0);

	#rmenu init
	$gui{rmenubarmenu}=Gtk2::MenuItem->new('_r');
	$gui{rmenubarmenu}->show;
	$gui{menubar}->append($gui{rmenubarmenu});

	#This is the pathbuttonbar
	$gui{PB}=Gtk2::PathButtonBar->new({
									   exec=>'chdir("/".${$myself}->{path}); '.
									         '${$myself}->{vars}{pfm}->update( ${$myself}->{vars}{id}, ${$myself}->{vars}{pfm} ); ',
									   vars=>{
											  pfm=>$self,
											  id=>$gui{id},
											  },
									});
	$gui{buttonHB}->pack_start($gui{PB}->{vbox}, 1, 1, 0);
	
	#init the hpaned
	$gui{hpaned}=Gtk2::HPaned->new;
	$gui{hpaned}->set_position(0);
	$gui{hpaned}->show;
	$gui{VB}->pack_start($gui{hpaned}, 1, 1, 0);

	#initialize the notebook
	$gui{DBnotebook}=Gtk2::Notebook->new;
	$gui{DBnotebook}->show;
	$gui{DBnotebookDL}=Gtk2::Label->new('Directories');
	$gui{DBnotebookDL}->show;
	$gui{DBnotebookDB}=Gtk2::Label->new('Bookmarks');
	$gui{DBnotebookDB}->show;
	$gui{hpaned}->add1($gui{DBnotebook});

	#the directory list
	$gui{dirlistSW}=Gtk2::ScrolledWindow->new;
	$gui{dirlistSW}->show;
 	$gui{dirlist}=Gtk2::SimpleList->new(
										'Directories'=>'text',
										);
	$gui{dirlist}->get_selection->set_mode ('multiple');
	$gui{dirlist}->show;
	$gui{dirlist}->signal_connect(row_activated=>sub{
									  my @selected=$_[3]->{self}{gui}{ $_[3]{id} }{dirlist}->get_selected_indices;

									  chdir($_[3]{self}{data}{ $_[3]{id} }{data}{dirreverse}[$selected[0]]);

									  $_[3]{self}->update( $_[3]{id}, $_[3]{self} );
								  },
								  {
								   self=>$self,
								   id=>$gui{id},
								   }
								  );
	$gui{dirlistSW}->add($gui{dirlist});
	$gui{DBnotebook}->append_page($gui{dirlistSW}, $gui{DBnotebookDL});

	#bookmark stuff
	$gui{bmlistVB}=Gtk2::VBox->new;
	$gui{bmlistVB}->show;
	$gui{bmlistSW}=Gtk2::ScrolledWindow->new;
	$gui{bmlistSW}->show;
	#put the buttons together for book marks
	$gui{bmlist}=Gtk2::SimpleList->new(
										'Bookmarks'=>'text',
										);
	$gui{bmlist}->get_selection->set_mode ('multiple');
	$gui{bmlist}->show;
	$gui{bmlist}->signal_connect(row_activated=>sub{
									 my @selected=$_[3]->{self}{gui}{ $_[3]{id} }{bmlist}->get_selected_indices;

									 my $bmID=$_[3]{self}->{bookmarkReverse}[$selected[0]];

									 #get the bookmark and make sure we have a link
									 my %bookmark=$_[3]{self}->{zcbm}->getBookmark('file', $bmID);
									 if (!defined($bookmark{link})) {
										 return undef;
									 }

									 #cd to the specified directory
									 chdir($bookmark{link});

									 #update it
									 $_[3]{self}->update( $_[3]{id} , $_[3]{self} );
								 },
								 {
								  self=>$self,
								  id=>$gui{id},
								  }
								 );
	$gui{bmlistSW}->add($gui{bmlist});
	$gui{bmlistVB}->pack_start($gui{bmlistSW}, 1, 1, 0);
	#put the buttons together
	$gui{bmlistBB}=Gtk2::HBox->new;
	$gui{bmlistBB}->show;
	$gui{bmlistVB}->pack_start($gui{bmlistBB}, 0, 1, 0);
	#add
	$gui{bmlistAdd}=Gtk2::Button->new;
	$gui{bmlistAdd}->set_label('Add');
	$gui{bmlistAdd}->show;
	$gui{bmlistBB}->pack_start($gui{bmlistAdd}, 0, 1, 0);
	$gui{bmlistAdd}->signal_connect(clicked=>\&addBM,{self=>$self, gui=>\%gui});
	#del
	$gui{bmlistDel}=Gtk2::Button->new;
	$gui{bmlistDel}->set_label('Del');
	$gui{bmlistDel}->show;
	$gui{bmlistBB}->pack_start($gui{bmlistDel}, 0, 1, 0);
	$gui{bmlistDel}->signal_connect(clicked=>\&deleteBM,{self=>$self, gui=>\%gui});
	#edit
	$gui{bmlistEdit}=Gtk2::Button->new;
	$gui{bmlistEdit}->set_label('Edit');
	$gui{bmlistEdit}->show;
	$gui{bmlistBB}->pack_start($gui{bmlistEdit}, 0, 1, 0);
	$gui{bmlistEdit}->signal_connect(clicked=>\&editBM,{self=>$self, gui=>\%gui});
	#finish this tab
	$gui{DBnotebook}->append_page($gui{bmlistVB}, $gui{DBnotebookDB});

	#display the bookmark stuff by default
	$gui{DBnotebook}->set_current_page('0');
	
	#the list of names/files
	$gui{listSW}=Gtk2::ScrolledWindow->new;
	$gui{listSW}->show;
	$gui{list}=Gtk2::SimpleList->new(
									 'Name'=>'text',
									 'User'=>'text',
									 'Group'=>'text',
									 'Perms'=>'text',
									 'Size'=>'text',
									 'MTime'=>'text',
									 'CTime'=>'text',
									 'ATime'=>'text',
									 );
	$gui{list}->get_selection->set_mode ('multiple');
	$gui{list}->show;
	$gui{list}->signal_connect(row_activated=>sub{
									  my @selected=$_[3]->{self}{gui}{ $_[3]{id} }{list}->get_selected_indices;

									  my $entry=$_[3]{self}{data}{ $_[3]{id} }{data}{reverse}[$selected[0]];

									  if(-d $entry){
										  chdir( $_[3]{self}{data}{ $_[3]{id} }{data}{reverse}[$selected[0]] );
										  $_[3]{self}->update( $_[3]{id}, $_[3]{self} );
									  }else {
										  if (-x $entry) {
											  #If it has a . in it, it may not be a executable file
											  #but on a fat32 partition or the like.
											  if ($entry =~ /\./) {
												  system('zcrunner -o '.shell_quote($entry).' &');
											  }else {
												  system(shell_quote($entry).' &');
											  }
										  }else {
											  system('zcrunner -o '.shell_quote($entry).' &');
										  }
										  
									  }
								  },
								  {
								   self=>$self,
								   id=>$gui{id},
								   }
							   );
	$gui{list}->signal_connect('cursor-changed'=>sub{
								   my $self=$_[1]{self};
								   my $id=$_[1]{id};
								   
								   $self->updateRmenu($id);
								  },
								  {
								   self=>$self,
								   id=>$gui{id},
								   }
							   );
	$gui{listSW}->add($gui{list});
	$gui{hpaned}->add2($gui{listSW});

	#adds the watcher
	$gui{watcher}=Dir::Watch->new();

	$gui{timer}=Glib::Timeout->add('2000',
								   sub{
									   #this should never happen, but check any ways
									   if (!defined( $_[0]{id} )) {
										   return 0;
									   }
									   #remove it if needed
									   if (!defined( $_[0]{self}->{gui}{$_[0]{id}} )) {
										   return 0;
									   }

									   $_[0]{self}->checkForUpdate($_[0]{id});
									   return 1;
								   },
								   {
									self=>$self,
									id=>$gui{id},
									}
								   );

	#save the gui
	$self->{gui}{$gui{id}}=\%gui;

	$self->update($gui{id}, $self);

	#update the bookmarks
	$self->updateBM({ gui=>\%gui, self=>$self });

	return %gui;
}

=head2 getAction

This fetches the default action.

    my $action=$self->getAction;

=cut

sub getAction{
	my $self=$_[0];

	if (!defined($self->{defaultAction})) {
		return 'view';
	}

	return $self->{defaultAction};
}

=head2 mkdir

This is the call back that is called when a mkdir key/button is pressed.

=cut

sub mkdir{
	my $text='';
	my $window = Gtk2::Dialog->new($text,
								   undef,
								   [qw/modal destroy-with-parent/],
								   'gtk-cancel'     => 'cancel',
								   'gtk-ok'     => 'accept',
								   );
	
	$window->set_position('center-always');
	
	$window->set_response_sensitive ('accept', 0);
	$window->set_response_sensitive ('reject', 0);
	
	my $vbox = $window->vbox;
	$vbox->set_border_width(5);
	
	my $label = Gtk2::Label->new_with_mnemonic('Name for new directory?');
	$vbox->pack_start($label, 0, 0, 1);
	$label->show;
	
	my $entry = Gtk2::Entry->new();
	$vbox->pack_end($entry, 0, 0, 1);
	$entry->show;
	
	$entry->signal_connect (changed => sub {
								my $text = $entry->get_text;
								$window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								$window->set_response_sensitive ('reject', 1);
							}
							);
	
	my $value;
	my $pressed;
	
	$window->signal_connect(response => sub {
								$value=$entry->get_text;
								$pressed=$_[1];
							}
							);
	#runs the dailog and gets the response
	#'cancel' means the user decided not to create a new set
	#'accept' means the user wants to create a new set with the entered name
	my $response=$window->run;
	
	$window->destroy;
	
	#set the pressed to reject if 
	if (($value eq '' )&&($pressed eq 'accept')) {
		$pressed='reject'
	}
	
	if ($pressed eq 'accept') {
		mkdir($value);
	}

	#update the stuff
	$_[1]{self}->update( $_[1]{gui}{id}, $_[1]{self} );
}

=head2 runViaNew

This is the call back that is called when
a entry is asked to be run via new a new
action.

=cut

sub runViaNew{
	my $self=$_[1];
	my $guiID=$_[2];
	my $item=$_[3];
	
	my $text='';
	my $window = Gtk2::Dialog->new('Run Via New Action',
								   undef,
								   [qw/modal destroy-with-parent/],
								   'gtk-cancel'     => 'cancel',
								   'gtk-ok'     => 'accept',
								   );
	
	$window->set_position('center-always');
	
	$window->set_response_sensitive ('accept', 0);
	$window->set_response_sensitive ('reject', 0);
	
	my $vbox = $window->vbox;
	$vbox->set_border_width(5);
	
	my $label = Gtk2::Label->new_with_mnemonic('Name for new action?');
	$vbox->pack_start($label, 0, 0, 1);
	$label->show;
	
	my $entry = Gtk2::Entry->new();
	$vbox->pack_end($entry, 0, 0, 1);
	$entry->show;
	
	$entry->signal_connect (changed => sub {
								my $text = $entry->get_text;
								$window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								$window->set_response_sensitive ('reject', 1);
							}
							);
	
	my $action;
	my $pressed;
	
	$window->signal_connect(response => sub {
								$action=$entry->get_text;
								$pressed=$_[1];
							}
							);
	#runs the dailog and gets the response
	#'cancel' means the user decided not to create a new set
	#'accept' means the user wants to create a new set with the entered name
	my $response=$window->run;
	
	$window->destroy;
	
	#set the pressed to reject if 
	if (($action eq '' )&&($pressed eq 'accept')) {
		$pressed='reject';
		return;
	}
	
	if ($pressed eq 'accept') {
		system('zcrunner -a '.shell_quote($action).' -o '.shell_quote($item).' &');
	}

	#update the stuff
	$self->{zcr}->readSet();
	$self->{zcrUpdate}=1;
	$self->update( $guiID, $self );
	$self->updateRmenu($guiID);
}

=head2 setAction

This sets the default action to use with the ZConf::Runner.

One arguement is taken and that is the name of the action.

    $pfm-setAction($action);

=cut

sub setAction{
	my $self=$_[0];
	my $action=$_[1];

	if (!defined($action)) {
		return undef;
	}

	$self->{defaultAction}=$action;

	return undef;
}

=head2 setActionCB

This is the call back used by the set default action
button.

=cut

sub setActionCB{
	my $self=$_[1];
	my $guiID=$_[2];
	
	my $text='';
	my $window = Gtk2::Dialog->new('Set Default Action',
								   undef,
								   [qw/modal destroy-with-parent/],
								   'gtk-cancel'     => 'cancel',
								   'gtk-ok'     => 'accept',
								   );
	
	$window->set_position('center-always');
	
	$window->set_response_sensitive ('accept', 0);
	$window->set_response_sensitive ('reject', 0);
	
	my $vbox = $window->vbox;
	$vbox->set_border_width(5);
	
	my $label = Gtk2::Label->new_with_mnemonic('New default action?');
	$vbox->pack_start($label, 0, 0, 1);
	$label->show;
	
	my $entry = Gtk2::Entry->new();
	$vbox->pack_end($entry, 0, 0, 1);
	$entry->show;
	
	$entry->signal_connect (changed => sub {
								my $text = $entry->get_text;
								$window->set_response_sensitive ('accept', $text !~ m/^\s*$/);
								$window->set_response_sensitive ('reject', 1);
							}
							);
	
	my $action;
	my $pressed;
	
	$window->signal_connect(response => sub {
								$action=$entry->get_text;
								$pressed=$_[1];
							}
							);
	#runs the dailog and gets the response
	#'cancel' means the user decided not to create a new set
	#'accept' means the user wants to create a new set with the entered name
	my $response=$window->run;
	
	$window->destroy;
	
	#set the pressed to reject if 
	if (($action eq '' )&&($pressed eq 'accept')) {
		$pressed='reject';
		return;
	}
	
	$self->setAction($action);

	$self->update( $guiID, $self );
	$self->updateRmenu($guiID);
}

=head2 update

This is the is used by callbacks for updating.

    $pfm->update($gui{id}, $self);

=cut

sub update{
#	my $self=$_[0];
#	my %gui;
#	if (defined($_[1])) {
#		%gui=%{$_[1]};
#	}
	my $guiID=$_[1];
	my $self=$_[2];

#	if (!defined($gui{VB})) {
#		warn('PerlFM update: The passed GUI hash does not appear to be something returned by the filemanager method');
#		return undef;
#	}

	#set the window title
	if (defined($self->{window})) {
		$self->{window}{window}->set_title('pfm: '.cwd);
	}

	#gets the data
	my %datahash=$self->datahash($self->{gui}{$guiID}{hidden});
	$self->{data}{$guiID}{data}=\%datahash;

	$self->{test}="3\n\n";

	my @listdata;
	my @dirlistdata;
	my @dirlistdata2;
	my $int=0;
	while (defined( $datahash{reverse}[$int] )) {
		my $entry=$datahash{reverse}[$int];
		my $atime=localtime($datahash{names}{$entry}{atime});
		my $ctime=localtime($datahash{names}{$entry}{ctime});
		my $mtime=localtime($datahash{names}{$entry}{mtime});
		my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire) = getpwuid($datahash{names}{$entry}{uid});
		if (!defined($name)) {
			$name=$datahash{names}{$entry}{uid};
		}
		my ($gname,$gpasswd,$ggid,$members) = getgrgid($datahash{names}{$entry}{gid});
		if (!defined($gname)) {
			$gname=$datahash{names}{$entry}{gid};
		}

		if (-d $entry) {
			my @row=(
					 $entry,
					 );
			my @row2=(
					  $entry,
					  $name,
					  $gname,
					  $datahash{names}{$entry}{mode},
					  $datahash{names}{$entry}{size},
					  $mtime,
					  $ctime,
					  $atime
					  );
			push(@dirlistdata2, \@row2);
			push(@dirlistdata, \@row);
		}else {
			my @row=(
					 $entry,
					 $name,
					 $gname,
					 $datahash{names}{$entry}{mode},
					 $datahash{names}{$entry}{size},
					 $mtime,
					 $ctime,
					 $atime
					 );
			push(@listdata, \@row);
		}

		$int++;
	}

	my @fulllist;
	push(@fulllist, @dirlistdata2);
	push(@fulllist, @listdata);

	@{$self->{gui}{$guiID}{list}->{data}}=@fulllist;

	@{$self->{gui}{$guiID}{dirlist}->{data}}=@dirlistdata;

	$self->{gui}{$guiID}{PB}->setPath(cwd);

	$self->{gui}{$guiID}{watcher}=Dir::Watch->new;
}

=head2 updateBM

This is the method that is used for updating the bookmark selection.

It is called automatically as needed.

=cut

sub updateBM{
	my %h;
	if (defined($_[1])) {
		%h=%{$_[1]};
	}

	$h{self}->errorblank;

	#get the list of bookmarks
	my @bookmarks=$h{self}->{zcbm}->listBookmarks('file');
	if ($h{self}->{zcbm}->{error}) {
		warn('PerlFM updatebm: listBookmarks fialed for ZConf::Bookmarks');
		return undef;
	}

	my %bmhash;
	my @names;

	#process the bookmarks
	my $int=0;
	while (defined($bookmarks[$int])) {
		my $bmID=$bookmarks[$int];

		my %bookmark=$h{self}->{zcbm}->getBookmark('file', $bmID);

		#puts it together if there was not a error with it
		if (!defined( $h{self}->{zcbm}->{error} )) {
			$bmhash{$bookmarks[$int]}=\%bookmark;

			push(@names, $bookmark{name});
		}

		$int++;
	}
	
	#sort the names
	@names=sort(@names);

	#save them for later recall as $h{gui} is not blessed
	$h{self}->{bookmarkNames}=\@names;
	$h{self}->{bookmarks}=\%bmhash;
	$h{self}->{bookmarkIDs}=\@bookmarks;

	#this will contain the reverse mappings
	my @reverse;

	#put it together
	$int=0;
	my %matched;#the bookmark ID will be defined if it is used...
	while (defined($names[$int])) {
		my $bmInt=0;
		while ($bookmarks[$bmInt]) {
			#make sure it has not been matched yet
			if (!$matched{$bookmarks[$bmInt]}) {
				if ( $bmhash{ $bookmarks[$bmInt] }{name} eq $names[$int] ) {
					push(@reverse, $bookmarks[$bmInt]);
					#mark it as matched
					$matched{$bookmarks[$bmInt]}=1;
				}
			}

			$bmInt++;
		}

		$int++;
	}

	#this is a the reverse hash
	$h{self}->{bookmarkReverse}=\@reverse;

	@{$h{self}{gui}{ $h{gui}{id} }{bmlist}->{data}}=@names;

}

=head2 updateRmenu

This updates the r menu and used by various callbacks.

=cut

sub updateRmenu{
	my $self=$_[0];
	my $guiID=$_[1];

	#update if needed
	if (defined($self->{zcrUpdate})) {
		if ($self->{zcrUpdate} eq '1'){
			$self->{zcr}->readSet();
			$self->{zcrUpdate}=0;
		}
	}

	#get the selected entry
	my @selected=$self->{gui}{ $guiID }{list}->get_selected_indices;
	#return if we don't have any thing
	if (!defined($selected[0])) {
		return undef;
	}
	my $entry=$self->{data}{ $guiID }{data}{reverse}[$selected[0]];

	#get the mimetype
	my $mimetype=mimetype($entry);

	#if that mime type is setup, get the available entries
	my $avail=$self->{zcr}->mimetypeIsSetup($mimetype);
	my @available;
	if ($avail) {
		@available=$self->{zcr}->listActions($mimetype);
	}

	#the enw rmenu
	my $rmenu=Gtk2::Menu->new;
	$rmenu->new;

	my $to=Gtk2::TearoffMenuItem->new;
	$to->show;
	$rmenu->append($to);

	#add the new itme
	my $new=Gtk2::MenuItem->new('run via a _new action');
	$new->show;
	$new->signal_connect(activate=>sub{
							 $_[1]{self}->runViaNew($_[1]{self}, $_[1]{id}, $_[1]{entry});
						 },
						 {
						  id=>$guiID,
						  self=>$self,
						  entry=>$entry,
						  }
						 );
	$rmenu->append($new);

	#add the new itme
	my $set=Gtk2::MenuItem->new('_set default action ('.$self->getAction.')');
	$set->show;
	$set->signal_connect(activate=>sub{
							 $_[1]{self}->setActionCB($_[1]{self}, $_[1]{id});
						 },
						 {
						  id=>$guiID,
						  self=>$self,
						  entry=>$entry,
						  }
						 );
	$rmenu->append($set);

	#add the refresh item
	my $refresh=Gtk2::MenuItem->new('_refresh');
	$refresh->show;
	$refresh->signal_connect(activate=>sub{
							 $_[1]{self}->{zcr}->readSet;
							 $_[1]{self}->updateRmenu($_[1]{id});
						 },
						 {
						  id=>$guiID,
						  self=>$self,
						  entry=>$entry,
						  }
						 );
	$rmenu->append($refresh);

	my $so=Gtk2::SeparatorMenuItem->new();
	$so->show;
	$rmenu->append($so);
	
	#process all actions
	my @actions;
	my $int=0;
	while (defined($available[$int])) {
		$actions[$int]=Gtk2::MenuItem->new('_'.$int.' '.$available[$int]);
		$actions[$int]->show;
		$actions[$int]->signal_connect(activate=>sub{
										   system('zcrunner -a '.shell_quote($_[1]{action}).' -o '.shell_quote($_[1]{entry}).' &');
									   },
									   {
										action=>$available[$int],
										entry=>$entry,
										}
									   );
		$rmenu->append($actions[$int]);
		$int++;
	}

	#add the menu
	$self->{gui}{ $guiID }{rmenubarmenu}->set_submenu($rmenu);

}

=head2 window

This returns a hash containing the various widgets.

=head3 args hash

=head4 path

This is the path to start in.

=head4 hidden

If this is set to true, hidden files will be shown.

    $args{path}='/tmp';
    $args{hidden}=0;
    my %winhash=$pfm->window(\%args);
    $winhash{window}->show;
    Gtk2->init;

=cut

sub window{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	my %window;

	$window{window}=Gtk2::Window->new;
	$window{window}->set_default_size(750, 400);

	$window{window}->set_title('pfm: '.cwd);

	#gets the GUI and add it
	my %gui=$self->filemanager(\%args);
	$window{fm}=\%gui;
	$window{window}->add($window{fm}{VB});

	$self->{window}=\%window;

	return %window;
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

=cut

#blanks the error flags
sub errorblank{
	my $self=$_[0];
	
	$self->{error}=undef;
	$self->{errorString}="";
	
	return 1;
}

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-perlfm at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PerlFM>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PerlFM


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PerlFM>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PerlFM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PerlFM>

=item * Search CPAN

L<http://search.cpan.org/dist/PerlFM/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of PerlFM
