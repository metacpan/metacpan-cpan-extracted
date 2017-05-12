#!/usr/bin/perl

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto AWS Installer Dashboard
#    Copyright (C) 2000-2017  Brian M. Kelly
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but **WITHOUT ANY WARRANTY**; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public
#    License along with this program.  If not, see:
#    <http://www.gnu.org/licenses/agpl.html>.
#
#######################################################################

use Wx::Perl::Packager;
use Wx qw(wxOK wxICON_INFORMATION);
use Cwd;
our $begin_cwd=cwd();
chdir "$ENV{PAR_TEMP}/inc" if -e "$ENV{PAR_TEMP}/inc";

our $VERSION = '0.02';

use 5.010;
use strict;
use warnings;
use Wx qw(:everything :id :misc :panel);
use Wx::Event qw(EVT_BUTTON EVT_TREE_SEL_CHANGED EVT_MENU EVT_CLOSE
                 EVT_MEDIA_LOADED EVT_MEDIA_PLAY EVT_ACTIVATE
                 EVT_NOTEBOOK_PAGE_CHANGED EVT_MEDIA_STATECHANGED
                 EVT_DROP_FILES EVT_FILEPICKER_CHANGED EVT_TEXT
                 EVT_PAINT EVT_CHECKBOX);

use Wx::Media;
use Wx::WebView;
use Wx::DND;
use Wx::Perl::ProcessStream qw( :everything );
use wxPerl::Constructors;
use File::Copy qw(copy);
use File::Find;
use Win32::TieRegistry;

# create the WxApplication
my $app = Wx::SimpleApp->new;
my $frame = Wx::Frame->new(undef, -1,
	        '© FullAuto Automates EVERYTHING - AWS Installer Dashboard',
                 wxDefaultPosition,[ 800, 600 ]);
SplitterWindow($frame);
$frame->Show;
$app->MainLoop;

# Example specific code
sub SplitterWindow {

   my ( $self ) = @_;

   my $splitterWindow = Wx::SplitterWindow->new($self, -1);
   #get our logo
   Wx::InitAllImageHandlers();

   # create menu bar
   my $bar  = Wx::MenuBar->new;
   my $file = Wx::Menu->new;
   my $help = Wx::Menu->new;
   my $edit = Wx::Menu->new;

   $file->Append( wxID_EXIT, '' );

   $help->Append( wxID_ABOUT, '' );

   $edit->Append( wxID_COPY,  '' );
   $edit->Append( wxID_PASTE,  '' );
   #my $find_again = $edit->Append( -1, "Find Again\tF3" );

   $bar->Append( $file, "&File" );
   #$bar->Append( $edit, "&Edit" );
   $bar->Append( $help, "&Help" );

   $self->SetMenuBar( $bar );
   $self->{menu_count} = $self->GetMenuBar->GetMenuCount;
   $self->{par_temp} = $ENV{PAR_TEMP} if exists $ENV{PAR_TEMP};
   $self->{begin_cwd}= $begin_cwd;

   my $logo = Wx::Bitmap->new("fullautogreenbannerpower.png",
                              wxBITMAP_TYPE_PNG );

   my $banner = Wx::BannerWindow->new($splitterWindow);
   $banner->SetBitmap( $logo );
   $banner->Show(1);
   my $don = Wx::Bitmap->new("donate.png",
                         wxBITMAP_TYPE_PNG );
   my $dn=Wx::BitmapButton->new($banner,-1,$don,[12.7,12.7]);
   $dn->SetToolTip( Wx::ToolTip->new( Wx::gettext('Please Donate!') ) );
   $dn->Enable(1);
	
   my $rightWindows = Wx::SplitterWindow->new($splitterWindow, -1);
   $rightWindows->Show(1);

   my $pem_file='';
   my $full_pem='';
   my $ppk_file='';
   my $tagged;
   my $ip_txt='';
   my $saved_txt='';
   my $cre_file='';
   opendir(PH,".");
   while (my $f=readdir(PH)) {
      next if $f eq '.';
      next if $f eq '..';
      if ($f=~/\.pem$/) {
         $pem_file=$f;
      } elsif ($f=~/\.ppk$/) {
         $ppk_file=$f;
      } elsif ($f=~/^ip.txt$/) {
         open (FH,"<ip.txt");
         my @ip_txt=<FH>;
         $ip_txt=join "\n", @ip_txt;
         close FH;
         $ip_txt=~s/^\s*.*?(\d+[.]\d+[.]\d+[.]\d+).*$/$1/s;
      } elsif ($f=~/^saved.txt$/) {
         open(FH,"<saved.txt") || warn $!;
         my @lines=<FH>;
         close FH;
         foreach my $line (@lines) {
            chomp $line;
            $saved_txt=$line if
                $line=~s/^\s*.*?(\d+[.]\d+[.]\d+[.]\d+).*$/$1/s;
            $ppk_file=$line if $line=~/ppk$/;
            $full_pem=$line if $line=~/pem$/;
            $cre_file=$line if $line=~/csv$/;
            $tagged=$line if $line=~/TagFA/;
         }
         $tagged=~s/TagFA=// if $tagged;
         $pem_file=$full_pem;
         $pem_file=~s/^.*\\(.*)$/$1/;
         last;
      }
   }
   close PH;

   my $righttop = Wx::Notebook->new($rightWindows,-1,[-1,-1],[-1,-1],
         wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN);
   $righttop->Show(1);

   my $media = Wx::MediaCtrl->new($righttop, -1, '', [-1,-1], [-1,-1], 0 );
   my $media2 = Wx::MediaCtrl->new($righttop, -1, '', [-1,-1], [-1,-1], 0 );
   my $media3 = Wx::MediaCtrl->new($righttop, -1, '', [-1,-1], [-1,-1], 0 );
   my $vid="https://youtu.be/QnDAaGQMRS0";
   #my $vid="https://www.youtube.com/watch?v=dW7fXqYbXS0";
   my $vid2="Introduction_to_Amazon_Elastic_Compute_Cloud_EC2.mp4";
   $media->LoadURI("fullauto_demonstration.mp4");
   $media->Show( 1 );
   $media->ShowPlayerControls;
   $righttop->{media}=$media;
   $media2->LoadURI($vid);
   $media2->ShowPlayerControls;
   $righttop->{media2}=$media2;
   $media3->LoadURI($vid2);
   $media3->ShowPlayerControls;
   $righttop->{media3}=$media3;

   EVT_MEDIA_STATECHANGED($righttop, $media,\&main::on_media_loaded);
   EVT_MEDIA_STATECHANGED($righttop, $media2,\&main::on_media2_loaded);
   EVT_MEDIA_STATECHANGED($righttop, $media3,\&main::on_media3_loaded);

   my $webpanel='';my $webpanel2='';my $webpanel3='';
   $webpanel = Wx::Panel->new($righttop, wxID_ANY);
   #my $aws_url='https://www.youtube.com/embed/gRwa1QoOS7M';
   my $aws_url='https://www.youtube.com/embed/QnDAaGQMRS0';
   $webpanel->{defaulturl}=$aws_url;
   my $html = Wx::WebView::New($webpanel, wxID_ANY, $webpanel->{defaulturl});
   $html->{defaulturl}=$aws_url;
   $webpanel->{webview}=$html;

   my $msizer = Wx::BoxSizer->new( wxVERTICAL );
   $msizer->Add($html, 1, wxEXPAND|wxALL, 0);
   #$msizer->Add($buttonsizer, 0, wxEXPAND|wxALL, 0);

   $webpanel->SetSizer( $msizer );
   $webpanel->Layout;
   $webpanel->Refresh;

   $webpanel2 = Wx::Panel->new($righttop, wxID_ANY);
   $aws_url='https://www.youtube.com/embed/dW7fXqYbXS0';
   $webpanel2->{defaulturl}=$aws_url;
   my $html2 = Wx::WebView::New($webpanel2, wxID_ANY, $webpanel2->{defaulturl});
   $html2->{defaulturl}=$aws_url;
   $webpanel2->{webview}=$html2;
   $msizer = Wx::BoxSizer->new( wxVERTICAL );
   $msizer->Add($html2, 1, wxEXPAND|wxALL, 0);
   $webpanel2->SetSizer( $msizer );
   $webpanel2->Layout;
   $webpanel2->Refresh;
   $webpanel3 = Wx::Panel->new($righttop, wxID_ANY);
   $aws_url='https://www.youtube.com/embed/Px7ZPLq4AOU';
   $webpanel3->{defaulturl}=$aws_url;
   my $html3 = Wx::WebView::New($webpanel3, wxID_ANY, $webpanel3->{defaulturl});
   $html3->{defaulturl}=$aws_url;
   $webpanel3->{webview}=$html3;
   $msizer = Wx::BoxSizer->new( wxVERTICAL );
   $msizer->Add($html3, 1, wxEXPAND|wxALL, 0);
   $webpanel3->SetSizer( $msizer );
   $webpanel3->Layout;
   $webpanel3->Refresh;

   $self->{media}=$media;

   $righttop->AddPage( $webpanel, "FullAuto AWS Dashboard", 0 );
   $righttop->AddPage( $webpanel2, "Amazon Web Services", 0 );
   $righttop->AddPage( $webpanel3, " Amazon Web Services EC2 ", 0 );

   $righttop->Show(1);

   my $rightbottom = Wx::Panel->new($rightWindows,-1,[-1,-1]);

   # http://avtanski.net/projects/lcd/applet.html
   my $notready  = Wx::Bitmap->new("notready.jpg",
                                 wxBITMAP_TYPE_JPEG );
   my $presshere = Wx::Bitmap->new("presshere.jpg",
                                 wxBITMAP_TYPE_JPEG );
   my $underway  = Wx::Bitmap->new("underway.jpg",
                                 wxBITMAP_TYPE_JPEG );
   my $taskdone  = Wx::Bitmap->new("taskdone.jpg",
                                 wxBITMAP_TYPE_JPEG );
   my $steel = Wx::Bitmap->new(
         "Scratched_Steel_Texture_by_AaronDesign_Enlarged.jpg",
         wxBITMAP_TYPE_JPEG);
   $rightbottom->{steel}=$steel;
   EVT_PAINT($rightbottom,\&on_paint);

   my $statbm = '';
   if($pem_file && $ip_txt) {
     $statbm = Wx::StaticBitmap->new($rightbottom,-1,$presshere,[440,30]);
     $statbm->SetToolTip( Wx::ToolTip->new( Wx::gettext('Press FA =>') ) );
   } elsif ($saved_txt) {
     $statbm = Wx::StaticBitmap->new($rightbottom,-1,$presshere,[440,105]);
     $statbm->SetToolTip( Wx::ToolTip->new( Wx::gettext('Press FA =>') ) );
   } else {
     $statbm = Wx::StaticBitmap->new($rightbottom,-1,$notready,[440,105]);
   }
   $rightbottom->{statbm}=$statbm;
   $rightbottom->{notready}=$notready;
   $rightbottom->{presshere}=$presshere;
   $rightbottom->{underway}=$underway;
   $rightbottom->{taskdone}=$taskdone;
   $rightbottom->{righttop}=$righttop;
   $rightbottom->DragAcceptFiles(1);
   $rightbottom->SetBackgroundColour(Wx::Colour->new(128,128,128));
   my $fp1='';my $fp2='';my $fp3='';
   unless ($pem_file && $ip_txt) {
     my $pem_f=($full_pem)?$full_pem:'';
     $fp1 = Wx::FilePickerCtrl->new( $rightbottom, -1, $pem_f,
                "Find and Select AWS Key File -> yourkeyfile.pem",
                "PEM files (*.pem)|*.pem|All files|*.*",
                [30, 15], [400,-1],wxFLP_USE_TEXTCTRL);
     $fp1->SetPath($pem_file) if $pem_file && $ip_txt;
     $fp1->Enable(0) if $pem_f;
     $fp1->Show(1);
     $rightbottom->{fp1}=$fp1;
     EVT_FILEPICKER_CHANGED( $rightbottom, $fp1, \&on_change );
     my $csv_f=($full_pem)?$cre_file:'';
     $fp2 = Wx::FilePickerCtrl->new( $rightbottom, -1, $csv_f,
                "Find and Select AWS Credentials file ".
                "-> credentials.csv",
                "CSV files (*.csv)|*.csv|All files|*.*",
                [30, 45], [400,-1],wxFLP_USE_TEXTCTRL);
     $fp2->Show(1);
     $fp2->Enable(0) if $csv_f;
     $rightbottom->{fp2}=$fp2;
     EVT_FILEPICKER_CHANGED( $rightbottom, $fp2, \&on_change );
     $fp3 = Wx::FilePickerCtrl->new( $rightbottom, -1, $csv_f,
                "Find and Select Private FullAuto Instruction ".
                "Set",
                "PM files (*.pm)|*.pm|All files|*.*",
                [117, 158], [303,-1],wxFLP_USE_TEXTCTRL); #[30,45] 312 size
     $fp3->SetPath("Optional Private Instruction Set");
     $fp3->Show(1);
     $fp3->Enable(1); #if $csv_f;
     $rightbottom->{fp3}=$fp3;
     EVT_FILEPICKER_CHANGED( $rightbottom, $fp3, \&on_change );

     my $button1=wxPerl::Button->new(
         $rightbottom,
         '<- filename.pem   [AWS EC2]',
         id        => -1,
         position  => [440,15],
         size      => [176,-1],
         style     => 0,
         validator => Wx::wxDefaultValidator(),
         name      => 'key',
     );
     $rightbottom->{key}=$button1;
     $button1->Enable(0) if $full_pem;
     EVT_BUTTON( $rightbottom, $button1, \&main::OnClick_button1 );

     my $button2=wxPerl::Button->new(
        $rightbottom,
        '<- credentials.csv [AWS IAM]',
        id        => -1,
        position  => [440,45],
        size      => [176,-1],
        style     => 0,
        validator => Wx::wxDefaultValidator(),
        name      => 'credentials',
     );
     $rightbottom->{credentials}=$button2;
     $button2->Enable(0) if $full_pem; 
     EVT_BUTTON( $rightbottom, $button2, \&main::OnClick_button2 );

     my $ins=($saved_txt)?'Amazon EC2 Dashboard':
                          '<- Instance IP Address  [EC2]';
     my $button3=wxPerl::Button->new(
        $rightbottom,
        $ins,
        id        => -1,
        position  => [440,75],
        size      => [176,-1],
        style     => 0,
        validator => Wx::wxDefaultValidator(),
        name      => 'ip',
     );
     $rightbottom->{dashboard}=$button3;
     if ($saved_txt) {
        $button3->SetBackgroundColour(Wx::Colour->new(32,161,35));
     } else {
        $button3->SetBackgroundColour(Wx::Colour->new("RED"));
     }
     EVT_BUTTON( $rightbottom, $button3, \&main::OnClick_button3 );
     my $ip_=($saved_txt)?$saved_txt:'';
     my $ipbox=wxPerl::TextCtrl->new(
        $rightbottom,
        $ip_,
        id        => -1,
        position  => [330,76],
        size      => [100,-1],
        style     => 0,
        validator => Wx::wxDefaultValidator(),
        name      => 'ipbox',
     );
     $rightbottom->{ipbox}=$ipbox;
     $self->{ipbox}=$ipbox;
     $ipbox->Show(1);
     $ipbox->Enable(0) if $ip_;
     EVT_TEXT( $rightbottom, $ipbox, \&on_change );

     my $chk=157;
     my $firstpaint=0;
     if (!exists $self->{firstpaint} && (exists $self->{ip_txt})) {
        $chk=87;
        $firstpaint=1;
     }
     $self->{firstpaint}=$firstpaint;
     $chk=76;
     my $button4=wxPerl::Button->new(
        $rightbottom,
        "Cleanup",
        id        => -1,
        position  => [118,$chk],
        size      => [90,-1],
        style     => 0,
        validator => Wx::wxDefaultValidator(),
        name      => 'cleanup',
     );
     $rightbottom->{cleanup}=$button4;
     EVT_BUTTON( $rightbottom, $button4, \&main::OnClick_button4 );

   }

   my $bmp = Wx::Bitmap->new("fakey.png",
                         wxBITMAP_TYPE_PNG );

   my $bht=105;
   if ($pem_file && $ip_txt) {
      $bht=30;
   }
   my $bb=Wx::BitmapButton->new($rightbottom,-1,$bmp,[555,$bht]);
   if (($pem_file && $ip_txt) || $saved_txt) {
      $bb->Enable(1);
      $rightbottom->{cleanup}->Enable(1); 
   } else {
      $bb->Enable(0);
   }

   my $new_server_chkbox='';
   my $export_logs_chkbox='';
   my $export_putty_chkbox='';
   my $chk=169;
   $chk=99 if !exists $rightbottom->{firstpaint}
                          && $pem_file && $ip_txt;
   $export_putty_chkbox=Wx::CheckBox->new($rightbottom,-1,'',
                          [226,$chk-87],[-1,-1],wxTRANSPARENT_WINDOW); # 118 $chk-83
   $export_putty_chkbox->SetBackgroundColour(Wx::Colour->new(77,77,77));
   $rightbottom->{epcb}=$export_putty_chkbox;
   EVT_CHECKBOX( $rightbottom, $export_putty_chkbox,
                           \&main::OnClick_chkbox2 );
   #$new_server_chkbox=Wx::CheckBox->new($rightbottom,-1,'',[440,$chk],
   #                       [-1,-1],wxTRANSPARENT_WINDOW);
   #$new_server_chkbox->SetBackgroundColour(Wx::Colour->new(77,77,77));
   #$rightbottom->{nscb}=$new_server_chkbox;
   #$new_server_chkbox->SetValue(1) unless ($ip_txt || $saved_txt);
   $export_logs_chkbox=Wx::CheckBox->new($rightbottom,-1,'',[440,$chk],
                          [-1,-1],wxTRANSPARENT_WINDOW);
   $export_logs_chkbox->SetBackgroundColour(Wx::Colour->new(77,77,77));
   if (($pem_file && $ip_txt) || $saved_txt) {
      $export_logs_chkbox->Enable(1);
   } else {
      $export_logs_chkbox->Enable(0);
   }
   $rightbottom->{elcb}=$export_logs_chkbox;
   
   #EVT_CHECKBOX( $rightbottom, $new_server_chkbox,
   #                        \&main::OnClick_chkbox3 );
   EVT_CHECKBOX( $rightbottom, $export_logs_chkbox,
                           \&main::OnClick_chkbox3 );
   #my $eng = Wx::Bitmap->new("engineroom.jpg",
   #                      wxBITMAP_TYPE_JPEG );
   my $clb = Wx::Bitmap->new("cb.png",
                         wxBITMAP_TYPE_PNG );
   my $cbt=80;
   if ($pem_file && $ip_txt) {
      $cbt=16;
   }
   my $cb=Wx::BitmapButton->new($rightbottom,-1,$clb,[30,$cbt]);
   $cb->SetToolTip( Wx::ToolTip->new( Wx::gettext('CLIPBUCKET Setup Instructions') ) );
   $cb->Enable(1);
   my $gnu = Wx::Bitmap->new("gnusoc.png",
                         wxBITMAP_TYPE_PNG );
   my $gnt=135;
   if ($pem_file && $ip_txt) {
      $gnt=16;
   }
   my $gs=Wx::BitmapButton->new($rightbottom,-1,$gnu,[30,$gnt]);
   $gs->SetToolTip( Wx::ToolTip->new( Wx::gettext('GNU Social Setup Instructions') ) );
   $gs->Enable(1);
   $rightbottom->{bb}=$bb;
   $rightbottom->{bmp}=$bmp;


   my $gif='';
   if (-e "standup.gif") {
      $gif=Wx::Animation->new();
      # Scrolling Gif Generator
      # http://www.ottoschellekens.nl/downloads/downloads.html
      $gif->LoadFile("standup.gif",wxANIMATION_TYPE_GIF);
      my $ht=115;
      if ($pem_file && $ip_txt) {
         $ht=40;
      }
      my $newAni=Wx::AnimationCtrl->new(
            $rightbottom,-1, $gif, [118,$ht-9], [-1,-1], 0 );
      $newAni->Play();
   }
   $rightbottom->{ppk_file} = $ppk_file if $ppk_file;
   $rightbottom->{ip_txt} = $ip_txt if $ip_txt;
   $rightbottom->{tagged} = $tagged if defined $tagged;
   EVT_BUTTON( $rightbottom, $bb, \&fullauto_button);
   EVT_BUTTON( $rightbottom, $cb, \&cb_button);
   EVT_BUTTON( $banner, $dn, \&dn_button);
   EVT_BUTTON( $rightbottom, $gs, \&gs_button);
   EVT_DROP_FILES( $rightbottom, \&main::on_drop );

   $rightbottom->Show(1);

   $splitterWindow->SetMinimumPaneSize(5);
   $rightWindows->SetMinimumPaneSize(5);

   if ($pem_file && $ip_txt) {
      $rightWindows->SplitHorizontally($righttop,$rightbottom,414);
   } else {
      $rightWindows->SplitHorizontally($righttop,$rightbottom,340);
   }
   $rightWindows->SetSashGravity(1.0);
   $splitterWindow->SplitVertically($banner,$rightWindows,142);

   #EVT_CLOSE( $self, \&cleanup );
   EVT_MENU( $self, wxID_ABOUT, \&on_about );
   EVT_MENU( $self, wxID_EXIT, sub { $self->Close } );
   EVT_MENU( $self, wxID_COPY, \&on_copy );
   EVT_MENU( $self, wxID_PASTE, \&on_paste );
   #EVT_MENU( $self, wxID_FIND, \&on_find );
   #EVT_MENU( $self, $find_again, \&on_find_again );

   $self->SetIcon(Wx::Icon->new("FA.ico",wxBITMAP_TYPE_ICO));
   $self->Show;

}

sub on_paint {

    my $self = shift;
    my $dc = Wx::PaintDC->new( $self );

    $dc->DrawBitmap( $self->{steel},0,0,0);
    my $chk=169;
    my $firstpaint=0;
    if (!exists $self->{firstpaint} && (exists $self->{ip_txt})) {
       $chk=99;
       $firstpaint=1;
    }
    $self->{firstpaint}=$firstpaint;
    $dc->SetTextForeground(Wx::Colour->newRGB(192,192,192));
    $dc->DrawText('Export FullAuto Log Files',460,$chk);
    $dc->DrawText('Export PuTTY',244,$chk-87); # 139 $chk-83

}

sub evt_process_exit {

    my ($self, $event) = @_;
    $event->Skip(1);
    my $process=eval {
       return $event->GetProcess;
    };
    $process||='';
    $process->Destroy if $process;
    my $log_out='';
    my @lines=();
    print "Process Exit Event at ".scalar localtime(time())."\n";
    if (-e "putty.log") {
       open (FH,"<putty.log");
       @lines=<FH>;
       close FH;
       $log_out=join '',@lines;
       my $fa_log=$log_out;
       $fa_log=~s/^.*?LOGFILE ==[>] ["](.*?)["].*$/$1/s;
       my $falog=$fa_log;
       $falog=~s/^.*\/(.*)$/$1/s;
       my $c="pscp.exe -batch -v -i \"$self->{ppk_file}\" ".
             "ec2-user\@$self->{ip_txt}:$fa_log $falog";
       Wx::Shell($c);
       system("copy putty.log output.txt");
       sleep 1;
       system("zip.exe logs.zip $falog");
       system("zip.exe logs.zip output.txt");
    }
    my $webapp_url='';
    my $set_shifted_flag=0;
    my $webapp_flag=0;
    if (!exists $self->{shifted_cmds} &&
          (-1<index $log_out,'Nothing to do') &&
          (-1==index $log_out,'ACCESS ')) {
      copy "cmds_saved.template", "cmds.txt";
      my $iptext=$self->{ip_txt};
      $set_shifted_flag=1;
      my $proc=Wx::Perl::ProcessStream::Process->new(
            "runputty \'$self->{ppk_file}\' $iptext",'putty',$self);
      $self->{shifted_cmds}=$proc;
      $proc->Run;
    } elsif (!exists $self->{webapp}) {
      my $count=0;
      foreach my $line (reverse @lines) {
         $count++;
         if ($line=~/GNU.io/ or $line=~/clipbucket[.]com/i) {
            next;
         } elsif (
               $line=~/ACCESS (?:HADOOP|KALI|OPENLDAP|CATALYST|GNU|CLIP)/) {
            last;
         } elsif ($line=~/ACCESS.*AT:\s+http:/ && $count<70) {
            $webapp_url=$line;
            $webapp_url=~s/^.*ACCESS.*AT:\s+(http.*)\s*$/$1/;
            last;
         } elsif ($line=~s/^\s+(http.*)\s*$/$1/ && $count<70) {
            $webapp_url=$line;
         }
      }
    }
    if (!(exists $self->{webapp}) && $webapp_url) {
      $self->{dashboard}->SetBackgroundColour(Wx::Colour->new(32,161,35));
      $self->{statbm}->SetBitmap($self->{taskdone});
      $webapp_flag=1;
      $self->{webapp}=1;
      Wx::LaunchDefaultBrowser($webapp_url,wxBROWSER_NEW_WINDOW);
      $self->{bb}->Enable(1);
      $self->{elcb}->Enable(1);
      $self->{cleanup}->Enable(1);
      $self->{fp3}->Enable(1);
    } 
    if ((!(exists $self->{shifted_cmds}) && !(exists $self->{webapp})) ||
          (!($set_shifted_flag) && !($webapp_flag))) {
       $self->{dashboard}->SetBackgroundColour(Wx::Colour->new(32,161,35));
       $self->{statbm}->SetBitmap($self->{presshere});
       $self->{statbm}->SetToolTip(
          Wx::ToolTip->new( Wx::gettext('Press FA =>') ) );
       $self->{bb}->Enable(1);
       $self->{elcb}->Enable(1);
       $self->{fp3}->Enable(1);
       $self->{cleanup}->Enable(1);
       $self->{key}->Enable(1);
       $self->{credentials}->Enable(1);
       $self->{ipbox}->Enable(1) unless -e "putty.log";
    }

}

sub fullauto_button {

   my ($self, $event) =@_;
   # http://proton-ce.sourceforge.net/rc/wxwidgets \
   # /docs/html/wx/wx_processfunctions.html
   # tag_for_removal($self,$event) unless exists $self->{tagged};
   $self->{key}->Enable(0);
   $self->{credentials}->Enable(0);
   $self->{ipbox}->Enable(0);
   $self->{fp1}->Enable(0);
   $self->{fp2}->Enable(0);
   $self->{fp3}->Enable(0);
   $self->{dashboard}->SetBackgroundColour(Wx::Colour->new(248,115,17));
   $self->{statbm}->SetBitmap($self->{underway});
   #$self->{nscb}->SetValue(0);
   $self->{elcb}->Enable(0);
   $self->{bb}->Enable(0);
   $self->{cleanup}->Enable(0);
   my $title='IMPORTANT!';
   my $message='The FullAuto AWS Installer Dashboard is nothing more '.
               'than a tool for automating the setup and use of PuTTY '.
               'to connect to the Amazon AWS EC2 server you '.
               'populated the IP Address box with. PuTTY is the most '.
               'popular SSH Client for Windows. However, it is not '.
               'the easiest tool to use, especially for non-technical '.
               'people. (It is possible to use PuTTY alone or another '.
               'Windows SSH Client like the one supplied with Cygwin.  '.
               'There are detailed instructions available that you '.
               "can use instead of this Dashboard.)\n\nWhat ".
               'follows when you press "OK" is a number of Windows '.
               'will open and close in quick succession. It is '.
               'advised that you avoid touching the mouse and '.
               'keyboard for the next TWO MINUTES or so, or until '.
               "you see a Window with the title".
               '"FullAuto Build UNDER WAY!"';
   my $dialog=Wx::MessageDialog->new(
      $self,$message,$title,wxOK|wxICON_EXCLAMATION);
   my $choice=$dialog->ShowModal();
   delete $self->{webapp} if exists $self->{webapp};
   delete $self->{shifted_cmds} if exists $self->{shifted_cmds};
   my $key=$self->{fp1}->GetPath();
   $key=~s/^.*\/(.*)$/$1/;
   my $keybasename=$key;
   $keybasename=~s/^.*\\(.*)\.pem/$1/;
   my $i=$self->{ipbox}->GetLineText(0);
   my $path=$ENV{HOMEDRIVE}.$ENV{HOMEPATH};
   my $iptext='';
   if (exists $self->{ip_txt}) {
      $iptext=$self->{ip_txt};
   } else {
      $iptext=$self->{ipbox}->GetLineText(0);
      $self->{ip_txt}=$iptext;
   }
   unless (-e "putty.log") {
      # http://www.techbout.com/remove-onedrive-windows-10-4548/
      # https://onedrive.uservoice.com/forums/262982-onedrive/suggestions/9123334-start-onedrive-manually-on-windows-10
      Wx::ExecuteCommand("puttycfg $iptext",wxEXEC_SYNC)
   }
   EVT_WXP_PROCESS_STREAM_EXIT($self, \&evt_process_exit);
   my $pis=$self->{fp3}->GetPath();
   if ($pis=~/\.pm$/) {
      if (exists $ENV{PAR_TEMP} && (-e "$ENV{PAR_TEMP}/inc")) {
         copy "$pis", "$ENV{PAR_TEMP}/inc";
      } else {
         copy "$pis", cwd();
      }
   } else {
      $pis='';
   }
   unless ((-e "saved.txt") || (-e "ip.txt")) {
      my $ver=`ver`;
      $ver=~s/^.*(Version.*)$/$1/s;
      $ver=~s/^Version (10).*$/$1/;
      $ver=~s/\s//sg;
      $ver=0 unless $ver=~/10/;
      unless (-e "$keybasename.ppk") {
         $self->{cleanup}->Enable(0);
         Wx::ExecuteCommand("puttykey \"$keybasename\" $path $ver",wxEXEC_SYNC);
         sleep 1;
      }
      if (exists $ENV{PAR_TEMP} && (-e "$ENV{PAR_TEMP}/inc")) {
         copy "$path/$keybasename.ppk", "$ENV{PAR_TEMP}/inc";
      } else {
         copy "$path\\$keybasename.ppk", cwd();
      }
      unlink "$path/$keybasename.ppk";
      my ($rcode,$stdout,$stderr)=('','','');
      $self->{cleanup}->Enable(0);
      ($rcode,$stdout,$stderr)=Wx::ExecuteStdoutStderr(
         "puttyyes \"$keybasename.ppk\" ec2-user $i",
         wxEXEC_SYNC);
      if ($rcode) {
         my $title="FullAuto AWS Installer Dashboard Fatal Error";
         my $message="Fatal Error: $stderr";
         my $dialog=Wx::MessageDialog->new(
            $self,$message,$title,wxOK|wxICON_EXCLAMATION);
         my $choice=$dialog->ShowModal(); 
         return;
      }
      $self->{ppk_file}="$keybasename.ppk";
      my $c="pscp.exe -batch -v -i \"$keybasename.ppk\" ".
            "MyConfig.pm ec2-user\@$i:/home/ec2-user";
      Wx::Shell($c);
      $c="pscp.exe -batch -v -i \"$keybasename.ppk\" ".
            "\"$keybasename.pem\" ec2-user\@$i:/home/ec2-user";
      Wx::Shell($c);
      $c="pscp.exe -batch -v -i \"$keybasename.ppk\" ".
            "credentials.csv ec2-user\@$i:/home/ec2-user";
      Wx::Shell($c);
      copy "cmds.template", "cmds.txt";
   } elsif (-e "ip.txt") {
      copy "cmds_ip.template", "cmds.txt";
   } else {
      copy "cmds_saved.template", "cmds.txt";
   }
   if ($pis) {
      $pis=~s/^.*\\(.*)$/$1/;
      my $c="pscp.exe -batch -v -i \"$keybasename.ppk\" ".
            "$pis ec2-user\@$i:/home/ec2-user";
      Wx::Shell($c);
   }
   open(FH,"+<cmds.txt");
   my $out='';my $k=$keybasename.'.pem';
   while(my $line=<FH>) {
      $line=~s/_p_/$k/eg;
      $line=~s/_c_/$self->{tagged}/eg;
      $line=~s/_i_/$pis/eg;
      $out.=$line;
   }
   seek(FH,0,0);
   print FH $out;
   truncate(FH,tell(FH));
   close(FH);
   open(FH,">saved.txt");
   print FH $iptext."\n";
   print FH $self->{ppk_file}."\n";
   print FH $self->{fp1}->GetPath()."\n";
   print FH $self->{fp2}->GetPath()."\n";
   print FH "TagFA=".$self->{tagged}."\n";
   close FH;
print "GOING TO RUNPUTTY: runputty \"$self->{ppk_file}\" $iptext\n";
   $self->{cleanup}->Enable(0);
   my $proc1=Wx::Perl::ProcessStream::Process->new(
         "runputty \"$self->{ppk_file}\" $iptext",'putty',$self);
   $proc1->Run;

}

sub dn_button {

   my ($self, $event) =@_;
   my $webapp_url='http://www.fullauto.com/donate.html';
   Wx::LaunchDefaultBrowser($webapp_url,wxBROWSER_NEW_WINDOW);

}

sub cb_button {

   my ($self, $event) =@_;
   my $webapp_url='file:///FullAuto%20Windows%20Dashboard%20CLIPBUCKET%20Linux%20Installation%20Instructions.pdf';
   Wx::LaunchDefaultBrowser($webapp_url,wxBROWSER_NEW_WINDOW);

}

sub gs_button {

   my ($self, $event) =@_;
   my $webapp_url='file:///FullAuto%20Windows%20Dashboard%20GNU%20Social%20Installation%20Instructions.pdf';
   Wx::LaunchDefaultBrowser($webapp_url,wxBROWSER_NEW_WINDOW);

}

sub enginerm_button {

   my ($self, $event) =@_;
   my $cwd=cwd();
   Wx::Shell("$cwd/engine.exe"); 

}

sub on_change {

   my ($self, $event) =@_;
   my $text=$self->{ipbox}->GetLineText(0);
   my $key='';my $cred='';
   if ($text=~/\d+\.\d+\.\d+\.\d+/ &&
         ($cred=$self->{fp2}->GetPath()) &&
         ($key=$self->{fp1}->GetPath())) {
      if (exists $ENV{PAR_TEMP} && (-e "$ENV{PAR_TEMP}/inc")) {
         copy $cred, "$ENV{PAR_TEMP}/inc";
         copy $key,  "$ENV{PAR_TEMP}/inc";
      } else {
         copy $cred, cwd();
         copy $key, cwd();
      }
      $self->{statbm}->SetBitmap($self->{presshere});
      $self->{statbm}->SetToolTip(
         Wx::ToolTip->new( Wx::gettext('Press FA =>') ) );
      $self->{dashboard}->SetLabel('Amazon EC2 Dashboard');
      $self->{dashboard}->SetBackgroundColour(Wx::Colour->new(32,161,35));
      $self->{bb}->SetBitmap($self->{bmp});
      $self->{bb}->Enable(1);
      $self->{elcb}->Enable(1);
      $self->{fp3}->Enable(1);
      $self->{cleanup}->Enable(1);
   } elsif ($text=$self->{fp1}->GetPath()) {
      $self->{statbm}->SetBitmap($self->{notready});
      $self->{bb}->Enable(0);
      #$self->{cleanup}->Enable(0);
   }
}

sub tag_for_removal {

   my ($self, $event) =@_;
   my $title='Tag FullAuto Server for Later Removal?';
   my $message='You have just provided an IP Address for a server '.
               'you have manually launched in the Amazon EC2 Cloud. '.
               'On this server, FullAuto will install itself, and then '.
               'proceed with processing where FullAuto will stand '.
               'up other servers, and exhibit the completely automated '.
               'installation and startup of complex software/application '.
               'architecture spanning multiple hosts. If you click the '.
               'button \'Tag for Removal\', FullAuto will terminate this '.
               'server along with all servers launched for the session '.
               'when you click the checkbox \'Cleanup on Terminate\' at the '.
               "bottom of the FullAuto AWS Dashboard interface.\n\nWould you ".
               "like to tag this server for later termination?\n\n(If you ".
               'are new to the Cloud, and only wish to test drive FullAuto, '.
               'it is recommended you choose \'Tag for '.
               'Removal\', and later check the box \'Cleanup on Terminate\' '.
               'when you are done with the session, so that you don\'t '.
               'incur any unnecessary Amazon fees.)';
   my $dialog=Wx::MessageDialog->new(
      $self,$message,$title,wxOK|wxCANCEL|wxICON_EXCLAMATION);
   $dialog->SetOKCancelLabels('Tag for Removal','Do NOT Tag');
   my $choice=$dialog->ShowModal();
   $choice||=0;
   if ($choice==5101) {
      $self->{tagged}=0;
   } else {
      $self->{tagged}=1;
   }

}

sub OnClick_chkbox1 {

   my ($self, $event) =@_;
   my $title='Cleanup on Terminate?';
   my $message='When this box is checked, upon termination of the '.
               'FullAuto© AWS Installer Dashboard window, '.
               'a cleanup process is launched which will destroy all the '.
               'servers this session creates on Amazon EC2, as well as all files '.
               'cached locally. NOTHING will be saved except for this '.
               'FullAuto-AWS-Installer-Dashboard-MSWin.exe file itself, which you '.
               'may manually delete. You will have to launch a '.
               'new FullAuto server from Amazon and download a new '.
               'key file and credentials file to run a session again, '.
               'if you terminate this instance of the Dashboard with this '.
               'box checked. So it is recommended that you DO NOT have '.
               'this box checked until you are pretty certain you have no '.
               'more need to run the FullAuto AWS Installer Dashboard, '.
               'for yourself or others.';
   my $dialog=Wx::MessageDialog->new(
      $self,$message,$title,wxOK|wxCANCEL|wxICON_EXCLAMATION);
   $dialog->SetOKCancelLabels('OK','CANCEL Cleanup');
   my $choice=$dialog->ShowModal() if $self->{cucb}->IsChecked();
   $choice||=0;
   if ($choice==5101) {
      $self->{cucb}->SetValue(0);
   }

}

sub OnClick_chkbox2 {

   my ($self, $event) =@_;
   my $desktop=$ENV{HOMEDRIVE}.$ENV{HOMEPATH}.'\\desktop';
   my $filedlg = Wx::FileDialog->new($self,         # parent
                                     'Open File',   # Caption
                                     $desktop,      # Default directory
                                     'putty',       # Default file
                                     "putty utilities (*.exe)|*.exe", # wildcard
                                     wxFD_SAVE|wxFD_OVERWRITE_PROMPT); #style
   # If the user really selected one
   if ($filedlg->ShowModal==wxID_OK)
   {
       my $filename = $filedlg->GetPath;
       my $dir=$filename;
       $dir=~s/^(.*)\\.*$/$1/;
       copy "putty.exe", $filename;
       copy "puttygen.exe", "$dir\\puttygen.exe";
       copy "pscp.exe", "$dir\\pscp.exe";
   }
   $self->{epcb}->SetValue(0);

}

sub OnClick_chkbox3 {

   my ($self, $event) =@_;
   my $desktop=$ENV{HOMEDRIVE}.$ENV{HOMEPATH}.'\\desktop';
   my $filedlg = Wx::FileDialog->new($self,         # parent
                                     'Open File',   # Caption
                                     $desktop,      # Default directory
                                     'logs',        # Default file
                                     "FullAuto Log Files (*.zip)|*.zip",
                                                    # wildcard
                                     wxFD_SAVE|wxFD_OVERWRITE_PROMPT); #style
   # If the user really selected one
   unless (-e "logs.zip") {
      my $title="No Log Files Available";
      my $message="No Log Files Available - Logs are available ".
                  "after an Instruction Set is run => $desktop";
      my $dialog=Wx::MessageDialog->new(
         $self,$message,$title,wxOK|wxICON_EXCLAMATION);
      my $choice=$dialog->ShowModal();
   } elsif ($filedlg->ShowModal==wxID_OK) {
       my $filename = $filedlg->GetPath;
       my $dir=$filename;
       $dir=~s/^(.*)\\.*$/$1/;
       copy "logs.zip", "$dir\\logs.zip";
   }
   $self->{elcb}->SetValue(0);

}

sub OnClick_chkbox_export {

   my ($self, $event) =@_;
   my $title='Launch New FullAuto Server?';
   my $message='';
   if (-e "ip.txt") {
      $message='It is important to note that this copy of '.
               'FullAuto_DEMO_MSWin.exe is supplied with active '.
               'credentials enabling you to bypass the somewhat lengthy '.
               'FullAuto Server setup, and saving you the task of having '.
               'to work with Amazon\'s AWS EC2 web dashboard. If you proceed '.
               'with this choice, you will have to first launch a server '.
               'from the Amazon AWS EC2 dashboard, create and download a new '.
               'private key, and obtain access credentials for the Amazon '.
               'API. Then you will have to wait at least 20 minutes for '.
               'a new FullAuto setup to be downloaded and installed on the '.
               'new FullAuto server before you can obtain the same setup, '.
               'access, and ability to run and view the session that you have '.
               "now.\n\nYOU CANNOT REVERSE THIS DECISION!\n\nOnce you proceed ".
               'with the choise to Launch a new FullAuto Server, the '.
               'currently active credentials will be permanently discarded '.
               "and unrecoverable.\n\nDo you still wish to proceed?";
   } elsif (-e "saved.txt") {
      $message='You have checked the box to Launch a New FullAuto Server. '.
               'Understand that if you proceed with this choice, that your '.
               'current settings will be permanently discarded. You will '.
               'again have to launch a server from the Amazon AWS EC2 '.
               'dashboard, or specify a pre-existing server (use the Amazon '.
               'AWS EC2 dashboard to learn the IP Address of any pre-existing '.
               'servers.) You will again have to create, download and '.
               'specify a credentials.csv file, or use a pre-existing one '.
               '(if the credentials are still active in AWS.) You will again '.
               'have to indicate a key file (<filename>.pem, a new one you '.
               'can choose to create when launching a new server, or '.
               'pre-existing if you have one that is still active. You will '.
               'again have to wait at least 20 minutes for a new FullAuto '.
               'install to take place before you can obtain the same setup '.
               'access, and ability to run and view the session that have now. '.
               "\n\nYOU CANNOT REVERSE THIS DECISION!\n\nOnce you proceed ".
               'with the choice to Launch a new FullAuto Server, the current '.
               'settings will be permanently discarded and unrecoverable '.
               "(except by manual re-entry.)\n\nDo you still wish to proceed?";
   } else {
      #$self->{nscb}->SetValue(1);
      $message='There are no saved settings, and a session is not currently '.
               'running. To run any FullAuto Instruction Set, a fully functioning '.
               'FullAuto Server is necessary, which it is the job of this '.
               'FullAuto-AWS-Installer-Dashboard-MSWin.exe application/utility to assist you '.
               'with. Therefore, this box will remain checked until such '.
               'time as the first FullAuto Server install has been launched';
      my $dialog=Wx::MessageDialog->new(
         $self,$message,$title,wxOK);
      my $choice=$dialog->ShowModal();
      return;
   }
   my $dialog=Wx::MessageDialog->new(
      $self,$message,$title,wxYES|wxNO|wxICON_EXCLAMATION);
   #my $choice=$dialog->ShowModal() if $self->{nscb}->IsChecked();
   my $choice=$dialog->ShowModal();
   $choice||=0;
   if ($choice==5104) {
      #$self->{nscb}->SetValue(0);
   } elsif (-e "saved.txt") {
      unlink "saved.txt";
      unlink "putty.log";
      $self->{key}->Enable(1);
      $self->{credentials}->Enable(1);
      $self->{ipbox}->Clear();
      $self->{ipbox}->Enable(1);
      $self->{fp1}->SetPath('');
      $self->{fp1}->Enable(1);
      $self->{fp2}->SetPath('');
      $self->{fp2}->Enable(1);
      $self->{dashboard}->SetBackgroundColour(Wx::Colour->new("RED"));
      $self->{statbm}->SetBitmap($self->{notready});
      #$self->{nscb}->SetValue(1);
      $self->{elcb}->Enable(0);
      $self->{bb}->Enable(0);
   }
}

sub OnClick_button1 {

   my ($self, $event) =@_;
   my $url='https://console.aws.amazon.com/ec2#KeyPairs:sort=keyName';
   Wx::LaunchDefaultBrowser($url,wxBROWSER_NEW_WINDOW);

}

sub OnClick_button2 {

   my ($self, $event) =@_;
   my $url='https://console.aws.amazon.com/iam/#users';
   Wx::LaunchDefaultBrowser($url,wxBROWSER_NEW_WINDOW);

}

sub OnClick_button3 {

   my ($self, $event) =@_;
   my $url='https://console.aws.amazon.com/ec2';
   Wx::LaunchDefaultBrowser($url,wxBROWSER_NEW_WINDOW);

}

sub OnClick_button4 {

   my ($self, $event) =@_;
   &cleanup($self,$event);

}

sub on_drop {

    my( $self, $wxDropFilesEvent ) = @_;
    my @files = $wxDropFilesEvent->GetFiles;
    if ($files[0]=~/csv$/) {
       $self->{fp2}->SetPath($files[0]);
    } elsif ($files[0]=~/pem$/) {
       $self->{fp1}->SetPath($files[0]);
    }
}

sub on_media3_loaded {

    my( $self, $event ) = @_;
    #Wx::LogMessage( 'Media loaded, start playback' );
    unless (exists $self->{done3}) {
       $self->{media3}->Play;
       $self->{media3}->Pause;
       $self->{media3}->Seek(0,0);
       $self->{done3}=1;
    }
}

sub on_media2_loaded {

    my( $self, $event ) = @_;
    #Wx::LogMessage( 'Media loaded, start playback' );
    unless (exists $self->{done2}) {
       $self->{media2}->Play;
       $self->{media2}->Pause;
       $self->{media2}->Seek(0,0);
       $self->{done2}=1;
    }
}

sub on_media_loaded {

    my( $self, $event ) = @_;
    #Wx::LogMessage( 'Media loaded, start playback' );
    unless (exists $self->{done}) {
       $self->{media}->Play;
       $self->{media}->Pause;
       $self->{media}->Seek(0,0);
       $self->{done}=1;
    }
}

sub GoToDefBrowser {

   my ( $self ) = @_;
   my $url=$self->{webview}->GetCurrentURL();
   Wx::LaunchDefaultBrowser($url,wxBROWSER_NEW_WINDOW);

   return;

}

sub OnBtnURL {
    my ($self, $event) = @_;

    my $url=$self->{webview}->GetCurrentURL();
    my $dialog = Wx::TextEntryDialog->new
        ( $self, "Enter a URL to load", "Enter a URL to load",
        $url );
    my $res = $dialog->ShowModal;
    my $rvalue =  $dialog->GetValue;
    $dialog->Destroy;
    return if $res == wxID_CANCEL;
    $self->{defaulturl} = $rvalue;
    $self->{webview}->LoadURL( $rvalue );
}

sub OnBtnBack {
    my ($self, $event) = @_;
    $self->{webview}->GoBack if $self->{webview}->CanGoBack;
}

sub OnBtnForward {
    my ($self, $event) = @_;
    $self->{webview}->GoForward if $self->{webview}->CanGoForward;
}

sub OnBtnHistory {
    my ($self, $event) = @_;
    my @past = $self->{webview}->GetBackwardHistory;
    my @future = $self->{webview}->GetForwardHistory;

    my $ptext = '<h3>Backward History</h3><br>';
    $ptext .= $_->GetTitle . ' : ' .  $_->GetUrl . '<br>' for ( @past );
    $ptext .= '<h3>Forward History</h3><br>';
    $ptext .= $_->GetTitle . ' : ' .  $_->GetUrl . '<br>' for ( @future );
    $ptext .= '</font>';

    $self->{webview}->SelectAll;
    $self->{webview}->DeleteSelection;

    $self->{webview}->SetPage($ptext, 'http://localhost:54321/');
}

sub on_find {

   my( $self ) = @_;
   $self->get_search_term;
   $self->search;

   return;
}

sub on_find_again {

   my( $self ) = @_;
   if (not $self->search_term) {
       $self->get_search_term;
   }
   $self->search;

   return;
}

sub get_search_term {

   my ($self) = @_;

   my $search_term = $self->search_term || '';
   my $dialog = Wx::TextEntryDialog->new( $self, "",
                "Search term", $search_term );
   if ($dialog->ShowModal == wxID_CANCEL) {
       $dialog->Destroy;
       return;
   }
   $search_term = $dialog->GetValue;
   $self->search_term($search_term);
   $dialog->Destroy;
   return;
}

sub search {

   my ($self) = @_;

   my $search_term = $self->search_term;
   return if not $search_term;

   my $code = $self->{source};
   my ($from, $to) = $code->GetSelection;
   my $last = $code->isa( 'Wx::TextCtrl' ) ? $code->GetLastPosition()
            : $code->GetLength();
   my $str  = $code->isa( 'Wx::TextCtrl' ) ? $code->GetRange(0, $last) 
            : $code->GetTextRange(0, $last);
   my $pos = index($str, $search_term, $from+1);
   if (-1 == $pos) {
       $pos = index($str, $search_term);
   }
   if (-1 == $pos) {
       return; # not found
   }

   $code->SetSelection($pos, $pos+length($search_term));

   return;
}

sub cleanup {

   my( $self, $event ) = @_;
   $event->Skip if $event;
   chdir "../../..";
   my $cwd=cwd();
   my $title='Continue with Cleanup of FullAuto?';
   my $message="You have pushed the Cleanup button. If you choose to continue, a process will\n".
               "launch that will remove all FullAuto files cached locally when you first ran\n".
               "the FullAuto AWS Installer Dashboard. NOTHING will be saved except for the\n".
               "FullAuto-AWS-Installer-Dashboard-MSWin.exe file, which you may manually\n".
               "delete. If you later wish to use the Dashboard again, you will have to again\n".
               "populate the key file, credentials file and IP Address boxes. If you think you\n".
               "want to run additional FullAuto Instruction Sets in the near future, FullAuto\n".
               "saves these entries for re-use by default. However, these settings are\n".
               "permanently lost if you continue Cleanup.\n\n".
               "By default, Cleanup will connect to Amazon AWS EC2 and terminate the FullAuto\n".
               "server indicated in the IP Address box. If you don't anticipate needing the\n".
               "FullAuto server further, terminating it will save you Amazon AWS EC2 charges.\n".
               "You can always build a new one from scratch in just a few minutes. If you want\n".
               "to cleanup the local files, but keep the FullAuto server in Amazon, check the\n".
               "checkbox below.\n\n".
               "NOTE: Cleanup will not touch anything built with FullAuto Instruction Sets.\n".
               "      To clean up those servers, use the AWS Console ->\n".
               "      https://console.aws.amazon.com";
   my @choices = ("DO NOT terminate FullAuto Server");
   my $multiChoiceDialog = Wx::MultiChoiceDialog->new($self, $message, $title, \@choices);
   my $do_not_terminate_fullauto_server=0;
   if ($multiChoiceDialog->ShowModal() == wxID_OK) {
      my @selections = $multiChoiceDialog->GetSelections();
      $do_not_terminate_fullauto_server = $#selections +1;
   } else {
      return
   }
   if (exists $ENV{PAR_TEMP}) {
      chdir "$ENV{PAR_TEMP}\\inc";
      copy "cmds_cleanup.template", "cmds.txt";
      my $ppk_file='';my $saved_txt;my $full_pem='';
      my $cre_file='';my $tagged='';
      opendir(PH,'.');
      while (my $f=readdir(PH)) {
         next if $f eq '.';
         next if $f eq '..';
         if ($f=~/\.ppk$/) {
            $ppk_file=$f;
         } elsif ($f=~/^saved.txt$/) {
            open(FH,"<saved.txt") || warn $!;
            my @lines=<FH>;
            close FH;
            foreach my $line (@lines) {
               chomp $line;
               $saved_txt=$line if
                  $line=~s/^\s*.*?(\d+[.]\d+[.]\d+[.]\d+).*$/$1/s;
               $ppk_file=$line if $line=~/ppk$/;
               $full_pem=$line if $line=~/pem$/;
               $cre_file=$line if $line=~/csv$/;
               $tagged=$line if $line=~/TagFA/;
            }
            $tagged=~s/TagFA=// if $tagged;
         }
      }
      my $i=$self->{ipbox}->GetLineText(0);
      my $pem=$full_pem;
      $pem=~s/^.*\\(.*)/$1/;
      if (-e "cmds.txt") {
         open(FH,"+<cmds.txt") || warn $!;
         my $out='';
         while(my $line=<FH>) {
            $line=~s/_p_/$pem/eg;
            $line=~s/_c_/$tagged/eg;
            $out.=$line;
         }
         seek(FH,0,0);
         print FH $out;
         truncate(FH,tell(FH));
         close(FH);
         my $ping=Wx::ExecuteStdout("tcping $i 22",wxEXEC_SYNC);
         $ping=join '',@{$ping};
         if ((-1<index $ping,'Port is open') && $ppk_file
               && !$do_not_terminate_fullauto_server) {
            my $cmd="runcleanup \"$ppk_file\" $i";
            Wx::ExecuteCommand($cmd,wxEXEC_SYNC)
         }
      }
      my $pardir=$ENV{PAR_TEMP}||'';
      $pardir=~s/^(.*)\\.*$/$1/;
      copy "saved.txt", "saved.txt.bak";
      unlink "saved.txt";
      copy "putty.log", "putty.log.bak";
      chdir $cwd;
      open(FH,">clean_fullauto.bat");
      print FH "ping 127.0.0.1 -n 1 -w 6000 > nul\n";
      print FH "del /S /Q $pardir\\inc\\putty.log\n";
      print FH "rmdir /S /Q $pardir\n";
      print FH "ping 127.0.0.1 -n 1 -w 6000 > nul\n";
      print FH "del /S /Q $pardir\\inc\\putty.log\n";
      print FH "rmdir /S /Q $pardir\n";
      print FH 'start /b "" cmd /c del "%~f0"&exit /b';
      close FH;
      my $sessions=
            'HKEY_CURRENT_USER\\Software\\SimonTatham\\PuTTY\\Sessions';
      my $sshhkeys=
            'HKEY_CURRENT_USER\\Software\\SimonTatham\\PuTTY\\SshHostKeys';
      my $jumplist=
            'HKEY_CURRENT_USER\\Software\\SimonTatham\\PuTTY\\Jumplist';
      my @sessions=();my $ses='';
      open(FH,"reg query $sessions|");
      while (my $line=<FH>) {
         next if $line=~/^\s*$/;
         if (-1<index $line, 'FullAuto') {
            chomp($line);
            my $key=$line;
            $key=~s/^.*\\(.*)\s*$/$1/s;
            push @sessions, $key;
            open (DH,"reg delete $line /f 2>&1|");
            while (my $line=<DH>) {
               print $line;
            }
            close DH;
         }
      }
      close FH;
      foreach my $session (@sessions) {
         my $ip=$session;
         $ip=~s/^.*_(.*)$/$1/;
         chomp($ip);
         open(FH,"reg query $sshhkeys|");
         while (my $line=<FH>) {
            next if $line=~/^\s*$/;
            if (-1<index $line, $ip) {
               my $key=$line;
               $line=~s/^\s+(.*?)\s+.*$/$1/;
               open (DH,"reg delete $sshhkeys /f /v \"$line\" 2>&1|");
               while (my $line=<DH>) {
                  print $line;
               }
               close DH;
               last;
            }
         }
         open(FH,"reg query $jumplist|");
         while (my $line=<FH>) {
            next if $line=~/^\s*$/;
            if ($line=~/FullAuto/) {
               my @rsess=split " |.0", $line;
               foreach my $rs (@rsess) {
                  next if $rs=~/^\s*$/;
                  next if -1<index $rs,'Recent';
                  next if -1<index $rs,'sessions';
                  next if -1<index $rs,'REG_MULTI_SZ';
                  next if -1<index $rs,'FullAuto';
                  $ses.="$rs ";
               }
               $ses=~s/\s*$//;
               open (DH,
                  "reg delete $jumplist /f /v \"Recent sessions\" 2>&1|");
               while (my $line=<DH>) {
                  print $line;
               }
               close DH;
               if ($ses) {
                  my $c="reg add $jumplist /f /v \"Recent sessions\" /t ".
                        "REG_MULTI_SZ /d \"$ses\"";
                  open (DH,"$c 2>&1|");
                  while (my $line=<DH>) {
                     print $line;
                  }
                  close DH;
               }
               last;
            }
         }
      }
      my @arg=("clean_fullauto.bat");
      exec @arg;
   }
   copy "saved.txt", "saved.txt.bak";
   unlink "saved.txt";
   copy "putty.log", "putty.log.bak";
   unlink "putty.log";
   $frame->Destroy() unless $ENV{PAR_TEMP};

}

sub on_about {

   my( $self ) = @_;
   use Wx qw(wxOK wxCENTRE wxVERSION_STRING);

   my $info = Wx::AboutDialogInfo->new;

   $info->SetName( "FullAuto AWS Installer Dashboard" );
   $info->SetVersion( '0.01' );
   $info->SetDescription( 'FullAuto Automates EVERYTHING AWS Installer Dashboard' );
   $info->SetCopyright(
      "(c) 2000-2017 Brian Kelly <Brian.Kelly\@FullAutoSoftware.net>" );
   $info->SetWebSite(
      'http://www.FullAutoSoftware.net', 'The FullAuto web site' );
   $info->AddDeveloper( 'Brian Kelly <Brian.Kelly@FullAutoSoftware.net>' );
   $info->SetIcon(Wx::Icon->new("FA.ico",wxBITMAP_TYPE_ICO));

   Wx::AboutBox( $info );

}

sub on_paste {

   my( $self ) = @_;

   my $code = $self->{source};
   my ($from, $to) = $code->GetSelection;
   my $str = $code->isa( 'Wx::TextCtrl' ) ? $code->GetRange($from, $to)
                                           : $code->GetTextRange($from, $to);
   if (wxTheClipboard->Open()) {
       wxTheClipboard->SetData( Wx::TextDataObject->new($str) );
       wxTheClipboard->Close();
   }

   return;

if (wxTheClipboard->Open())
{
    if (wxTheClipboard->IsSupported( wxDF_TEXT ))
    {
        #wxTextDataObject data;
        #wxTheClipboard->GetData( data );
        #wxMessageBox( data.GetText() );
    }
    wxTheClipboard->Close();
}

}

# TODO: disallow copy when not the code is in focus
# or copy the text from the log window too.
sub on_copy {
print "ONCOPY\n";
   my( $self ) = @_;

   my $code = $self->{source};
   my ($from, $to) = $code->GetSelection;
   my $str = $code->isa( 'Wx::TextCtrl' ) ? $code->GetRange($from, $to)
                                           : $code->GetTextRange($from, $to);
   if (wxTheClipboard->Open()) {
       wxTheClipboard->SetData( Wx::TextDataObject->new($str) );
       wxTheClipboard->Close();
   }

   return;
}

1;
