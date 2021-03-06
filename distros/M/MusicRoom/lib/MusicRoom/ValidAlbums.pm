package MusicRoom::ValidAlbums;

=head1 NAME

MusicRoom::ValidAlbums - Find the nearest artist

=head1 DESCRIPTION

Identify albums from the list

=cut

use strict;
use warnings;

use MusicRoom;
use MusicRoom::Text::Nearest;
use IO::File;
use Carp;

my($musicroom_dir,$loaded);

my %added;

sub nearest
  {
    my($name,$from,$quiet) = @_;

    _init();
    $from = "ValidAlbums Module" if(!defined $from || $from eq "");

    # Check if any items have been added during this session, 
    # this is a shortcut but sure better than doing the complete 
    # process again
    return $name if(defined $added{$name});

    return MusicRoom::Text::Nearest::get(
                               "album", $name, $from,$quiet);
  }

sub add
  {
    # Add a new entry into the file
    my(@entries) = @_;

    _init();
    my $file_name = MusicRoom::File::latest(
                               "valid-albums",
                               look_for => "txt", dir => $musicroom_dir);
    return undef if(!defined $file_name);
    if(!-w $file_name)
      {
        carp("Do not have permission to write to $file_name");
        return undef;
      }
    my $ofh = IO::File->new(">>$file_name");
    if(!defined $ofh)
      {
        carp("Failed to open $file_name");
        return undef;
      }
    foreach my $item (@entries)
      {
        # Certain characters are just not allowed
        if($item =~ m#\"\{\}#)
          {
            carp("Cannot have a valid value of \"$item\"");
            $item =~ tr/\"\{\}/\'\(\)/;
          }
        $added{$item} = 1;
        print $ofh "$item\n";
      }
    $ofh->close();
  }

sub _init
  {
    return if(defined $loaded && $loaded);

    $musicroom_dir = MusicRoom::get_conf("dir");
    MusicRoom::Text::Nearest::add_categories(
        album => 
          {
            qualifiers => [# '\s*\(1\)', '\s*\(2\)', '\s*\(3\)',
                           # '\s*\(disc 1\)', '\s*\(disc 2\)', '\s*\(disc 3\)',
                           # '\s*\(Remastered\)' 
                           ],
            from_file => MusicRoom::File::latest(
                               "valid-albums",
                               look_for => "txt", dir => ${musicroom_dir}),
            save_cache => 1,
          },);
    $loaded = 1;
  }

1;
