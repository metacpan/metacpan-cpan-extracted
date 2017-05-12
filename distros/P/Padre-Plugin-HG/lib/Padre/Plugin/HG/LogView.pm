=pod

=head1  NAME

Padre::Plugin::HG::LogView
Displays a list of commits for the passed file. 

=head1 SYNOPSIS

 my $changeset = Padre::Plugin::HG::LogView->showList($self, $file);
 
=head1 DESCRIPTION

This module displays the list of commits that have occured for the passed file. 
it returns the changeset number. 
=head1 METHODS

=cut


package Padre::Plugin::HG::LogView;
use strict;
use Padre::Wx;
use Padre::Wx::Icon;
use Wx::Event qw( EVT_BUTTON );
our @ISA     = 'Wx::Dialog';



sub showList
{
	my ($class, $hg, $file) = @_;
	
		my $self = $class->SUPER::new(
		undef,
		-1,
		'Padre Diff to Revision',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_FRAME_STYLE | Wx::wxTAB_TRAVERSAL,
		
	);
	$self->{hg} = $hg;
	$self->SetIcon(Padre::Wx::Icon::PADRE);
	my $sizer = Wx::BoxSizer->new(Wx::wxVERTICAL);
	my $sizer2 = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$self->{list_box} = Wx::ListCtrl->new($self, -1, Wx::wxDefaultPosition,
	Wx::wxDefaultSize,Wx::wxLC_REPORT|Wx::wxLC_SINGLE_SEL, Wx::wxDefaultValidator, 'listbox_1');
        #insert the HG data
        chdir ($self->{hg}->{project_path});
        my $hgdata = $self->{hg}->vcs_log($file, $self->{hg}->{project_path});
        
        $self->_populate_list( $hgdata);

	


	my $ok_button = Wx::Button->new($self, 
						1,                  # id
						"OK", # label
						[50,50]             # position
                                       );


	#Handle the Button Clicks
	
        my $changeset;
         
	EVT_BUTTON( $ok_button, 
             1,
               sub{$changeset = $self->_get_selected_item();
                $self->Close();
                return $changeset;
                  
               }
              );
      
    $sizer->Add($self->{list_box}, 1, Wx::wxEXPAND, 10);
    $sizer2->Add($ok_button, 0, Wx::wxALL, 10);
    $sizer->Add($sizer2, 0, Wx::wxEXPAND, 10);
    $self->SetSizer($sizer);
    $self->SetAutoLayout(1);
    $self->ShowModal();
    return $changeset;

}


sub _get_selected_item
{
	my( $self, $event ) = @_; 

	# Change the contents of $self->{txt}
	
	my $changeset;
	
	my $item = -1;
	 while ( 1 ==1 )
	{
        $item = $self->{list_box}->GetNextItem($item,
                                     Wx::wxLIST_NEXT_ALL,
                                     Wx::wxLIST_STATE_SELECTED);
        if ( $item == -1 )
        {
            last;
	}
        # this item is selected - do whatever is needed with it
        my $itemObj = $self->{list_box}->GetItem($item);
        $changeset .= $itemObj->GetText();
       
    }
    $changeset =~ s/^.*://;
     return $changeset;    
 }

sub _populate_list
{
 my ($self, $log) = @_;
 my @commits = $self->{hg}->parse_log($log);
 
 if (!$log) {return}
 #build the list headers
 $self->{list_box}->InsertColumn(0,'changeset');
 $self->{list_box}->InsertColumn(1,'user');
 $self->{list_box}->InsertColumn(2,'date');
 $self->{list_box}->InsertColumn(3,'summary');
 
 for (my $i = (scalar(@commits)-1); $i >= 0; $i--)
  {
	
	my $item = $self->{list_box}->InsertStringItem(0,$commits[$i]->{changeset});
	$self->{list_box}->SetItem($item,1, $commits[$i]->{user});
	$self->{list_box}->SetItem($item,2, $commits[$i]->{date});
	$self->{list_box}->SetItem($item,3, $commits[$i]->{summary});
	
 }	
	
}


