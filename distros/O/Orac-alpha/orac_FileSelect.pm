package orac_FileSelect;
use strict;

@orac_FileSelect::ISA = qw{orac_Base};

=head1 NAME

orac_FileSelect.pm - Orac code and Image Viewer

=head1 DESCRIPTION

This code is provides a way of traversing directories to
examine files.

=head1 PUBLIC METHODS

&new()
&req_filebox()

=cut

use vars qw( $pod $upBtn $updirImage $folderImage $fileImage $imageImage
             $pImage $start_directory %pod_txt_img $pod_txt_but
           );

require Tk::IconList;
require Tk::Photo;
require Pod::Text; import Pod::Text;
use FindBin;
use lib $FindBin::RealBin;
use File::Basename;

=head2 new

Sets up the blessed object, and makes sure we can change background
colours, give it the correct title etc.

=cut

sub new
{
   my $proto = shift;
   my $class = ref($proto) || $proto;

   my ($l_window, $l_text, $l_screen_title) = @_;

   my $self  = orac_Base->new("FileSelect",
                               $l_window,
                               $l_text,
                               $l_screen_title
                             );

   bless($self, $class);

   return $self;
}

=head2 req_filebox

The function called, when in use from the main Orac menu.  Pumps up
the screen, and sets up the main IconList.

=cut

sub req_filebox {

   my $self = shift;

   ($start_directory) = @_;

   # We've got to make sure, that whatever directory we've been
   # supplied with, we make sure it's in the correct format for the OS.
   # This makes sure later, we cannot move out of the Orac
   # distribution, or wherever it is we are.

   my $dirname = File::Basename::dirname($start_directory);
   my $basename = File::Basename::basename($start_directory);

   $start_directory = File::Spec->catfile($dirname, $basename);

   # Set up window, menus etc

   $self->{window} = $self->{Main_window}->Toplevel();
   $self->{window}->title( $self->{Version} );

   my(@filsel_lay) = qw/-side top -expand no -fill both/;
   my $filsel_menu = $self->{window}->Frame->pack(@filsel_lay);

   $self->{selectPath} = $start_directory;

   $self->top_left_message( \$filsel_menu, $main::lg{doub_click } );
   $self->top_right_ball_message( \$filsel_menu,
                                  \$self->{selectPath},
                                  \$self->{window}
                                );

   # Now start the work

   my $balloon;
   $self->balloon_bar(\$balloon, \$self->{window}, 72, );

   my $f0 = $self->{window}->Frame(-relief=>'ridge',
                                   -bd=>2,
                                  )->pack( -side=>'top',
                                           -expand => 'n',
                                           -fill => 'both'
                                         );

   # The back.gif is a typical Browser style "back" directional
   # arrow

   $self->get_img( \$self->{window}, \$updirImage, 'back');
   $self->get_img( \$self->{window}, \$pod_txt_img{0}, 'landscape' );
   $self->get_img( \$self->{window}, \$pod_txt_img{1}, 'pod' );

   $upBtn = $f0->Button(-image => $updirImage,
                        -command => sub { $self->UpDirCmd(@_); },
                       )->pack(-side => 'left', -padx => 4, -fill => 'both');

   $balloon->attach($upBtn, -msg => $main::lg{back_dir});

   $pod = 1;
   $pod_txt_but = $f0->Button(-image => $pod_txt_img{ $pod },
                              -command => sub {

      if ( $pod == 1 )
      {
         $pod = 0;
         $balloon->attach($pod_txt_but, -msg => $main::lg{txt_normal} );
      }
      else
      {
         $pod = 1;
         $balloon->attach($pod_txt_but, -msg => $main::lg{pod} );
      }
      $pod_txt_but->configure(-image => $pod_txt_img{ $pod } );

                                           }

                             )->pack( -side => 'left' );

   $balloon->attach($pod_txt_but, -msg => $main::lg{pod} );

   $self->orac_image_label(\$f0, \$self->{window}, );
   $self->window_exit_button(\$f0, \$self->{window}, 1, \$balloon, );

   # Now the original work

   my $f1 = $self->{window}->Frame;
   $f1->pack(-side=>'top', -expand => 'y', -fill => 'both');

   $self->{window}->{text} = $f1->IconList(

                      -background => $main::bc,
                      -command => sub { $self->ListInvoke(@_); },

                                             );

   $self->{window}->{text}->{font} = $main::font{name};
   $self->{window}->{text}->pack(-expand => 'y', -fill => 'both');

   main::iconize( $self->{window} );
   $self->SetPath($start_directory);
}

=head2 UpDirCmd

When the user presses the "Up Directory" button, this takes the user
to the desired location.  Should stop them moving outside of the
Orac distribution.

=cut

sub UpDirCmd {

   my $self = shift;

   $self->SetPath(File::Basename::dirname($self->{'selectPath'}))
      unless ($self->{'selectPath'} eq $start_directory );
}

=head2 ListInvoke

Gets called when user invokes the IconList widget (double-click,
Return key, etc).

=cut

sub ListInvoke {

   my $self = shift;

   my($text) = @_;

   return if ($text eq '');
   my $file = File::Spec->catfile($self->{selectPath}, $text);

   if (-d $file) {

      $self->SetPath($file);

   } else {

      $self->display_file($file)

   }
}

=head2 display_file

Takes the file picked, and then displays it.  Varies how it does
this on file type, whether POD required, etc.

=cut

sub display_file {

   my $self = shift;

   my($ffile) = @_;

   my ($file, $path, $suffix) = fileparse( $ffile, q{.\w+$} );

   if ($suffix =~ /\.gif$/i)
   {
      $self->see_gif( $ffile,
                    );
   }
   elsif ($suffix =~ m/p[lm]$|pod$/i)
   {
      # This is a Perl file.  Do they want to
      # POD it?

      #
      # Pod2text doesn't appear to handle tied objects.
      #

      if ($pod)
      {
        # Gotta set some stuff so the Pod::Text::pod2text function
        # can cope

	local $^W=0;
        $ENV{COLUMNS} = 80;

        # Now fill a local file with Pod

	my $tmp_file = "$FindBin::RealBin/txt/temp$$.pod";

	open( OUTPUT, ">$tmp_file");
	Pod::Text::pod2text(qq{$ffile}, *OUTPUT);
	close(OUTPUT);

        # Now re-open local file, fill the screen,
        # then remove the temporary Pod file.

        $self->see_sql( $self->{window},
                        $self->gf_str( $tmp_file ),
                        $ffile,
                      );

        # Remove the temporary file

	unlink( "$tmp_file" );

      }
      else
      {
         $self->see_sql( $self->{window},
                         $self->gf_str( $ffile ),
                         $ffile,
                       );
      }

   }
   else
   {
      # Just slap it out onto the old main screen.

      $self->see_sql( $self->{window},
                      $self->gf_str( $ffile ),
                      $ffile,
                    );

   }
   return;
}

=head2 SetPath

Changes the directory path, or at least gets the process going.

=cut

sub SetPath {

   my $self = shift;

   my($stub) = @_;

   $self->{selectPath} = $stub;

   $self->Update();
}

=head2 Update

Continues process of changing directory.  Once there, fills the IconList
widget with the appropriate icons.

=cut

sub Update {

   my $self = shift;

   # This proc may be called within an idle handler. Make sure that the
   # window has not been destroyed before this proc is called

   $self->get_img( \$self->{window}->{text}, \$folderImage, 'folder');
   $self->get_img( \$self->{window}->{text}, \$fileImage, 'text');
   $self->get_img( \$self->{window}->{text}, \$imageImage, 'image');
   $self->get_img( \$self->{window}->{text}, \$pImage, 'p');

   my $appPWD = Cwd::cwd();

   if ($self->{selectPath} eq $start_directory)
   {
      $upBtn->configure(-state=>'disabled');
   }
   else
   {
      $upBtn->configure(-state=>'normal');
   }

   if (!chdir $self->{selectPath}) {

      # We cannot change directory to $data(selectPath). $data(selectPath)
      # should have been checked before tkFDialog_Update is called, so
      # we normally won't come to here. Anyways, give an error and abort
      # action.

      main::mes($self->{window},
                qq{Cannot change to the directory }  .
                $self->{selectPath} . qq{\. \nPermission denied?}
	);

      return;
   }

   # Turn on the busy cursor.

   $self->{window}->Busy(-recurse=>1);
   $self->{window}->idletasks;

   $self->{window}->{text}->DeleteAll;

   # Make the dir list

   my %hasDoneDir;

   foreach my $f (sort { lc($a) cmp lc($b) } glob('.* *')) {
      next if $f eq '.' or $f eq '..';
      if (-d "./$f" and not exists $hasDoneDir{$f}) {
         $self->{window}->{text}->Add($folderImage, $f);
         $hasDoneDir{$f}++;
      }
   }

   # Make the file list

   my @files = sort { lc($a) cmp lc($b) } glob('.* *');

   my $top = 0;
   my %hasDoneFile;

   foreach my $ffile (@files) {
      if (-f "./$ffile" and not exists $hasDoneFile{$ffile}) {

         my $image;
         my ($file, $path, $suffix) = fileparse( $ffile, q{.\w+$} );

         if ($suffix =~ /\.gif$/i)
         {
            $image = $imageImage;
         }
         elsif ($suffix =~ m/p[lm]$|pod$/i)
         {
            $image = $pImage;
         }
         else
         {
            $image = $fileImage;
         }
         $self->{window}->{text}->Add($image, $ffile);
         $hasDoneFile{$ffile}++;
      }
   }
   $self->{window}->{text}->Arrange;
   $self->{window}->Unbusy;
}

1;
