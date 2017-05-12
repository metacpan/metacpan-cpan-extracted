package Padre::Plugin::HG::ProjectCommit;
use strict;
use Padre::Wx;
use Padre::Wx::Icon;
use Wx::Event qw( EVT_BUTTON );
our @ISA     = 'Wx::Dialog';


my $images = Wx::ImageList->new( 16, 16 );
        my $file_types = {
                M => $images->Add(
	                        Wx::ArtProvider::GetBitmap( 'wxART_TIP', 'wxART_OTHER_C', [ 16, 16 ] ),
                ),
                dir => $images->Add(
                        Wx::ArtProvider::GetBitmap( 'wxART_FOLDER', 'wxART_OTHER_C', [ 16, 16 ] ),
                ),
                C => $images->Add(
                        Wx::ArtProvider::GetBitmap( 'wxART_TICK_MARK', 'wxART_OTHER_C', [ 16, 16 ] ),
                ),
                '?' => $images->Add(
                        Wx::ArtProvider::GetBitmap( 'wxART_MISSING_IMAGE', 'wxART_OTHER_C', [ 16, 16 ] ),
                ),
          };


sub showList
{
	my ($class, $hg) = @_;
	
		my $self = $class->SUPER::new(
		undef,
		-1,
		'Padre Mecurial Commit',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_FRAME_STYLE | Wx::wxTAB_TRAVERSAL,
		
	);
	$self->{hg} = $hg;
	$self->SetIcon(Padre::Wx::Icon::PADRE);
	my $sizer = Wx::BoxSizer->new(Wx::wxVERTICAL);
	my $sizer2 = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	my   $listbox1 = Wx::ListCtrl->new($self, -1, Wx::wxDefaultPosition,
	Wx::wxDefaultSize,Wx::wxLC_LIST, Wx::wxDefaultValidator, 'listbox_1');
        $listbox1->AssignImageList($images,1);
        #insert the HG data
        chdir ($self->{hg}->{project_path});
        my @hgdata = `hg status`;
        my @filestatus =  $self->{hg}->_get_hg_files(@hgdata);
        $self->{file_listbox} = $listbox1;
	$self->_populate_list( \@filestatus );
   

	


	my $ok_button = Wx::Button->new($self, 
						1,                  # id
						"OK", # label
						[50,50]             # position
                                       );
	my $cancel_button = Wx::Button->new($self,             # parent
                                        2,                  # id
                                        "Cancel", # label
                                        [50,50]             # position
                                       );

	#Handle the Button Clicks
	
	EVT_BUTTON( $ok_button, 
             1,         
             sub{$self->_get_selected_items} 
             );
             
	EVT_BUTTON( $cancel_button, 
             2,
              sub{$self->Close(); return} 
             );

    $sizer->Add($listbox1, 1, Wx::wxEXPAND, 10);
    $sizer2->Add($ok_button, 0, Wx::wxALL, 10);
    $sizer2->Add($cancel_button, 0, Wx::wxALL, 10);
    $sizer->Add($sizer2, 0, Wx::wxEXPAND, 10);
    $self->SetSizer($sizer);
    $self->SetAutoLayout(1);
    $self->ShowModal(); 
}


sub _get_selected_items
{
	my( $self, $event ) = @_; 

	# Change the contents of $self->{txt}
	
	my $file_list;
	#$self->{txt}->SetLabel("The button was clicked!"); 
	my $item = -1;
	 while ( 1 ==1 )
	{
        $item = $self->{file_listbox}->GetNextItem($item,
                                     Wx::wxLIST_NEXT_ALL,
                                     Wx::wxLIST_STATE_SELECTED);
        if ( $item == -1 )
        {
            last;
	}
        # this item is selected - do whatever is needed with it
        my $itemObj = $self->{file_listbox}->GetItem($item);
        $file_list .= ' "'.$itemObj->GetText().'" ';
       
    }
    
    $self->{hg}->vcs_commit($file_list, $self->{hg}->{project_path});
    $self->Close();
}

sub _populate_list
{
 my ($self, $filestatus) = @_;
 
 if (!$filestatus) {return}
 foreach my $file (@$filestatus)
 {
	my ($status, $path) = @$file;
	$self->{file_listbox}->InsertImageStringItem(1, $path, $file_types->{$status});
 }	
	
}


