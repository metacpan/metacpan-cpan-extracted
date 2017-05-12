package MusicRoom::Charts;

=head1 NAME

MusicRoom::Charts - Process some music charts

=head1 DESCRIPTION


=cut

use strict;
use warnings;
use Carp;

my($room_dir,%data);
my $build;

sub init
  {
    my($cat) = @_;

    return if(defined $data{$cat});

    $build = $data{$cat} = {};

    if(!defined $room_dir)
      {
        $room_dir = MusicRoom::get_conf("dir");
      }
    my $file_name = MusicRoom::File::latest(
                               "chart-${cat}s", look_for => "csv", 
                               dir => $room_dir,quiet => 1);
    return undef if(!defined $file_name);
    my $ifh = IO::File->new($file_name);
    if(!defined $ifh)
      {
        carp("Failed to open $file_name");
        return undef;
      }
    MusicRoom::Text::CSV::scan($ifh,action => \&add_entry);
    $ifh->close();
  }

sub add_entry
  {
    my(%attribs) = @_;
    my $artist = $attribs{artist};
    my $name = $attribs{name};
    my $year = $attribs{year};
    my $score = $attribs{score};
    $score = 1 if(!defined $score);
    $build->{$artist} = {} if(!defined $build->{$artist});
    if(defined $build->{$artist}->{$name})
      {
        carp("Multiple definitions for \"$artist\" - \"$name\"");
      }
    $build->{$artist}->{$name} = 
      {
        year => $year, score => $score,
      };
  }

sub artists
  {
    my($cat) = @_;

    init($cat);
    return undef if(!defined $data{$cat});

    return sort keys %{$data{$cat}};
  }

sub entries
  {
    my($cat,$artist) = @_;

    init($cat);
    return undef if(!defined $data{$cat});
    return undef if(!defined $data{$cat}->{$artist});
    return sort keys %{$data{$cat}->{$artist}};
  }

sub year
  {
    my($cat,$artist,$entry) = @_;

    init($cat);
    return undef if(!defined $data{$cat});
    return undef if(!defined $data{$cat}->{$artist});
    return undef if(!defined $data{$cat}->{$artist}->{$entry});
    return $data{$cat}->{$artist}->{$entry}->{year};
  }

sub score
  {
    my($cat,$artist,$entry) = @_;

    init($cat);
    return undef if(!defined $data{$cat});
    return undef if(!defined $data{$cat}->{$artist});
    return undef if(!defined $data{$cat}->{$artist}->{$entry});
    return $data{$cat}->{$artist}->{$entry}->{score};
  }
1;

