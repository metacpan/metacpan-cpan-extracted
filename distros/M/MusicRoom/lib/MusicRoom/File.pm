# Provide functions that deal with File names
package MusicRoom::File;

use strict;
use warnings;

use Carp;
use File::Copy;

use MusicRoom;
use MusicRoom::Text::Nearest;

my $working_format = "wav";

my(%paths,%formats,%exts,%mp3_ID3v2_to_tags,%mp3_tags_to_ID3v2);
my(@attribs);

my $init_done = "";

my $operating_system;

sub _init
  {
    return if($init_done);

    $init_done = 1;

    $operating_system = eval(sprintf('$%c',0xf));

    %mp3_ID3v2_to_tags =
      (
        TALB => 'album', TIT2 => 'title', TPE1 => 'artist',
        TRCK => 'track_num', TYER => 'year', COMM => 'id',
      );

    %mp3_tags_to_ID3v2 =
      (
        album => 'TALB', title => 'TIT2', artist => 'TPE1',
        track_num => 'TRCK', year => 'TYER', id => 'COMM', 
      );

    %formats = 
      (
        wav =>
          {
            uses_package => ["Audio::Wav"],
            store_format => "flac",
            ext => "wav",
            is_valid => sub
              {
                my($format,$src_file) = @_;
                if(!-r $src_file)
                  {
                    carp("Cannot read $format file \"$src_file\"");
                    return "";
                  }
                return 1;
              },
            get_tags => sub
              {
                # How to grab tags from an flac file
                my($format,$src_file) = @_;

                my %attribs;
                my $wav = new Audio::Wav;
                my $read = $wav->read($src_file);
                my $details = $read->details();

                foreach my $tag (@attribs)
                  {
                    # I don't see an easy way to do this, so...
                    if($tag eq "album" || $tag eq "title" || 
                           $tag eq "artist" || $tag eq "track_num" ||
                           $tag eq "year" || $tag eq "id" ||
                           $tag eq "dir_artist" || $tag eq "dir_album")
                      {
                        # No chance of getting these from the tags, 
                        # wav files don't have them
                      }
                    elsif($tag eq "length_secs")
                      {
                        $attribs{$tag} = int($details->{length});
                      }
                    elsif($tag eq "file")
                      {
                        $attribs{$tag} = $src_file;
                      }
                    elsif($tag eq "original_format")
                      {
                        # FLAC is lossless so there is no bitrate
                        $attribs{$tag} = $format;
                      }
                    elsif($tag eq "quality")
                      {
                        $attribs{$tag} = 7;
                      }
                    else
                      {
                        carp("unknown $format tag \"$tag\"");
                      }
                  }
                return %attribs;
              },
          },
        flac_older =>
          {
            # The Audio::FLAC module used to be available for older Perl
            # versions, if you want to use it rename this one to "flac"
            # remove the "disabled" flag, call the next one "flac_newer"
            # and insert a "disabled" flag
            disabled => 1,
            uses_encoder => "flac",
            uses_package => ["Audio::FLAC"],
            ext => "flac",
            is_valid => sub
              {
                my($format,$src_file) = @_;
                if(!-r $src_file)
                  {
                    carp("Cannot read $format file \"$src_file\"");
                    return "";
                  }
                my $flac = Audio::FLAC->new($src_file);
                if(!defined $flac)
                  {
                    carp("File \"$src_file\" appears to not be $format format");
                    return "";
                  }
                return 1;
              },
            get_tags => sub
              {
                # How to grab tags from an flac file
                my($format,$src_file) = @_;

                my %attribs;
                my $flac = Audio::FLAC->new($src_file);
                my $info = $flac->info();
                my $tags = $flac->tags();

                foreach my $tag (@attribs)
                  {
                    # I don't see an easy way to do this, so...
                    if($tag eq "album")
                      {
                        $attribs{$tag} = $tags->{ALBUM};
                      }
                    elsif($tag eq "title")
                      {
                        $attribs{$tag} = $tags->{TITLE};
                      }
                    elsif($tag eq "artist")
                      {
                        $attribs{$tag} = $tags->{ARTIST};
                      }
                    elsif($tag eq "length_secs")
                      {
                        $attribs{$tag} = int($info->{TOTALSAMPLES}/
                                              $info->{SAMPLERATE});
                      }
                    elsif($tag eq "track_num")
                      {
                        $attribs{$tag} = $tags->{TRACKNUMBER};
                      }
                    elsif($tag eq "year")
                      {
                        $attribs{$tag} = $tags->{DATE};
                      }
                    elsif($tag eq "id")
                      {
                      }
                    elsif($tag eq "file")
                      {
                        $attribs{$tag} = $src_file;
                      }
                    elsif($tag eq "original_format")
                      {
                        # FLAC is lossless so there is no bitrate
                        $attribs{$tag} = $format;
                      }
                    elsif($tag eq "quality")
                      {
                        $attribs{$tag} = 8;
                      }
                    elsif($tag eq "dir_artist" || $tag eq "dir_album")
                      {
                      }
                    else
                      {
                        carp("unknown $format tag \"$tag\"");
                      }
                  }
                return %attribs;
              },
            to_working => sub
              {
                my($format,$src_file,$dest_file) = @_;
    
                # decode a flac to wav
                # $src_file & $dest_file have been dosified already

                system("$paths{flac} -d \"$src_file\" -o \"$dest_file\"");
              },
          },
        flac =>
          {
            # Newer releases use the Audio::FLAC::Header module to extract 
            # data from flac files
            uses_encoder => "flac",
            uses_package => ["Audio::FLAC::Header"],
            ext => "flac",
            is_valid => sub
              {
                my($format,$src_file) = @_;
                if(!-r $src_file)
                  {
                    carp("Cannot read $format file \"$src_file\"");
                    return "";
                  }
                my $flac = Audio::FLAC::Header->new($src_file);
                if(!defined $flac)
                  {
                    carp("File \"$src_file\" appears to not be $format format");
                    return "";
                  }
                return 1;
              },
            get_tags => sub
              {
                # How to grab tags from an flac file
                my($format,$src_file) = @_;

                my %attribs;
                my $flac = Audio::FLAC::Header->new($src_file);
                my $info = $flac->info();
                my $tags = $flac->tags();

                foreach my $tag (@attribs)
                  {
                    # I don't see an easy way to do this, so...
                    if($tag eq "album")
                      {
                        $attribs{$tag} = $tags->{ALBUM};
                      }
                    elsif($tag eq "title")
                      {
                        $attribs{$tag} = $tags->{TITLE};
                      }
                    elsif($tag eq "artist")
                      {
                        $attribs{$tag} = $tags->{ARTIST};
                      }
                    elsif($tag eq "length_secs")
                      {
                        $attribs{$tag} = int($info->{TOTALSAMPLES}/
                                              $info->{SAMPLERATE});
                      }
                    elsif($tag eq "track_num")
                      {
                        $attribs{$tag} = $tags->{TRACKNUMBER};
                      }
                    elsif($tag eq "year")
                      {
                        $attribs{$tag} = $tags->{DATE};
                      }
                    elsif($tag eq "id")
                      {
                      }
                    elsif($tag eq "file")
                      {
                        $attribs{$tag} = $src_file;
                      }
                    elsif($tag eq "original_format")
                      {
                        # FLAC is lossless so there is no bitrate
                        $attribs{$tag} = $format;
                      }
                    elsif($tag eq "quality")
                      {
                        $attribs{$tag} = 8;
                      }
                    elsif($tag eq "dir_artist" || $tag eq "dir_album")
                      {
                      }
                    else
                      {
                        carp("unknown $format tag \"$tag\"");
                      }
                  }
                return %attribs;
              },
            to_working => sub
              {
                my($format,$src_file,$dest_file) = @_;
    
                # decode a flac to wav
                # $src_file & $dest_file have been dosified already

                system("$paths{flac} -d \"$src_file\" -o \"$dest_file\"");
              },
          },
        ogg =>
          {
#            disabled => 1,
            ext => ["ogg","ogv","oga","ogx"],

            uses_encoder => ["oggenc2","oggdec"],
            # The latest package name is Ogg-Vorbis-Header-PurePerl 
            uses_package => ["Ogg::Vorbis::Header::PurePerl"],
            is_valid => sub
              {
                my($format,$src_file) = @_;

                my $ogg = Ogg::Vorbis::Header::PurePerl->new($src_file);
                if(!defined $ogg)
                  {
                    carp("File \"$src_file\" appears to not be $format format");
                    return "";
                  }
                return 1;
              },
            to_working => sub
              {
                my($format,$src_file,$dest_file) = @_;
    
                # decode an mp3 to wav
                # $src_file & $dest_file have been dosified already

                system("$paths{oggdec} \"$src_file\" -o > \"$dest_file\"");
              },
            from_working => sub
              {
                my($format,$src_file,$dest_file) = @_;
    
                my $bitrate = bitrate_of($format);
                my $br_flag = "-b $bitrate";
                $br_flag = "" if($bitrate eq "");

                # decode an mp3 to wav
                # $src_file & $dest_file have been dosified already

                system("$paths{oggenc2} $br_flag \"$src_file\" -o \"$dest_file\"");
              },
            get_tags => sub
              {
                # How to grab tags from an mp3 file
                my($format,$src_file) = @_;

                my %attribs;
                my $ogg = Ogg::Vorbis::Header::PurePerl->new($src_file);
                if(!defined $ogg)
                  {
                    carp("File \"$src_file\" appears to not be $format format");
                    return "";
                  }
                my $info = $ogg->info();
                my %tags;
                foreach my $tag ($ogg->comment_tags())
                  {
                    my @vals = $ogg->comment($tag);
                    if($#vals < 0)
                      {
                        # Just ignore missing values
                      }
                    elsif($#vals == 0)
                      {
                        $tags{lc($tag)} = $vals[0];
                      }
                    else
                      {
                        carp("Muliple values for $tag, just taking first");
                        $tags{lc($tag)} = $vals[0];
                      }
                  }

                foreach my $tag (@attribs)
                  {
                    # I don't see an easy way to do this, so...
                    if($tag eq "album")
                      {
                        $attribs{$tag} = $tags{album};
                      }
                    elsif($tag eq "title")
                      {
                        $attribs{$tag} = $tags{title};
                      }
                    elsif($tag eq "artist")
                      {
                        $attribs{$tag} = $tags{artist};
                      }
                    elsif($tag eq "length_secs")
                      {
                        $attribs{$tag} = $info->{length};
                      }
                    elsif($tag eq "track_num")
                      {
                        $attribs{$tag} = $tags{tracknumber};
                      }
                    elsif($tag eq "year")
                      {
                        if($tags{date} =~ /(\d{4})/)
                          {
                            $attribs{$tag} = $1;
                          }
                        else
                          {
                            $attribs{$tag} = $tags{date};
                          }
                      }
                    elsif($tag eq "id")
                      {
                      }
                    elsif($tag eq "file")
                      {
                        $attribs{$tag} = $src_file;
                      }
                    elsif($tag eq "original_format")
                      {
                        # ogg bitrate is always autodetected, so we don't include it here
                        $attribs{$tag} = $format;
                      }
                    elsif($tag eq "quality")
                      {
                        $attribs{$tag} = 8;
                      }
                    elsif($tag eq "dir_artist" || $tag eq "dir_album")
                      {
                      }
                    else
                      {
                        carp("unknown $format tag \"$tag\"");
                      }
                  }
                return %attribs;
              },
          },
        aac =>
          {
            uses_encoder => "ffmpeg",
            ext => ["aac","m4a","m4p","m4b",
                    "m4r","m4v","3gp","mp4",],
            uses_package => ["MP4::Info"],
            to_working => sub
              {
                my($format,$src_file,$dest_file) = @_;

                # decode a aac to wav
                system("$paths{ffmpeg} -i \"$src_file\" \"$dest_file\"");
              },
            is_valid => sub
              {
                my($format,$src_file) = @_;
                my $aac = MP4::Info->new($src_file);
                if(!defined $aac)
                  {
                    carp("File \"$src_file\" appears to not be $format format");
                    return "";
                  }
                return 1;
              },
            get_tags => sub
              {
                # How to grab tags from an mp3 file
                my($format,$src_file) = @_;

                my %attribs;
                my $aac = MP4::Info->new($src_file);

                foreach my $tag (@attribs)
                  {
                    # I don't see an easy way to do this, so...
                    if($tag eq "album")
                      {
                        $attribs{$tag} = $aac->{ALB};
                      }
                    elsif($tag eq "title")
                      {
                        $attribs{$tag} = $aac->{NAM};
                      }
                    elsif($tag eq "artist")
                      {
                        $attribs{$tag} = $aac->{ART};
                        $attribs{$tag} = $aac->{WRT}
                                          if(!defined $attribs{$tag});
                      }
                    elsif($tag eq "length_secs")
                      {
                        $attribs{$tag} = int($aac->{SECS});
                      }
                    elsif($tag eq "track_num")
                      {
                        $attribs{$tag} = $aac->{TRACKNUM};
                      }
                    elsif($tag eq "year")
                      {
                        $attribs{$tag} = $aac->{YEAR};
                      }
                    elsif($tag eq "id")
                      {
                        $attribs{$tag} = extract_id($aac->{CMT});
                      }
                    elsif($tag eq "file")
                      {
                        $attribs{$tag} = $src_file;
                      }
                    elsif($tag eq "original_format")
                      {
                        # The fact that the bitrate is arbitrary, means it 
                        # cannot be part of the format name
                        $attribs{$tag} = $format;
                      }
                    elsif($tag eq "quality")
                      {
                        my $bitrate = $aac->{BITRATE};
                        if(!defined $bitrate)
                          {
                            $attribs{$tag} = 7;
                          }
                        elsif($bitrate > 200)
                          {
                            $attribs{$tag} = 8;
                          }
                        elsif($bitrate > 100)
                          {
                            $attribs{$tag} = 7;
                          }
                        elsif($bitrate > 64)
                          {
                            $attribs{$tag} = 6;
                          }
                        else
                          {
                            $attribs{$tag} = 5;
                          }
                      }
                    elsif($tag eq "dir_artist" || $tag eq "dir_album")
                      {
                      }
                    else
                      {
                        carp("unknown $format tag \"$tag\"");
                      }
                  }
                return %attribs;
              },
          },
        wma =>
          {
            uses_encoder => "ffmpeg",
            uses_package => ["Audio::WMA"],

            # These are the standard bitrates from mp3, I am guessing that
            # wma will have a similar set
            bitrates => [32, 40, 48, 56, 64, 80, 96, 
                         112, 128, 144, 160, 192, 224, 256, 320],
            ext => "wma",
            to_working => sub
              {
                my($format,$src_file,$dest_file) = @_;

                # decode a wma to wav
                system("$paths{ffmpeg} -i \"$src_file\" \"$dest_file\"");
              },
            is_valid => sub
              {
                my($format,$src_file) = @_;
                if(!-r $src_file)
                  {
                    carp("Cannot read $format file \"$src_file\"");
                    return "";
                  }
                my $wma = Audio::WMA->new($src_file);
                if(!defined $wma)
                  {
                    carp("File \"$src_file\" appears to not be $format format");
                    return "";
                  }
                return 1;
              },
            get_tags => sub
              {
                # How to grab tags from an mp3 file
                my($format,$src_file) = @_;

                my %attribs;
                my $wma = Audio::WMA->new($src_file);
                my $tags = $wma->tags();
                my $info = $wma->info();

                foreach my $tag (@attribs)
                  {
                    # I don't see an easy way to do this, so...
                    if($tag eq "album")
                      {
                        $attribs{$tag} = $tags->{ALBUMTITLE};
                      }
                    elsif($tag eq "title")
                      {
                        $attribs{$tag} = $tags->{TITLE};
                      }
                    elsif($tag eq "artist")
                      {
                        $attribs{$tag} = $tags->{AUTHOR};
                        $attribs{$tag} = $tags->{COMPOSER}
                                          if(!defined $attribs{$tag});
                        $attribs{$tag} = $tags->{ALBUMARTIST}
                                          if(!defined $attribs{$tag});
                      }
                    elsif($tag eq "length_secs")
                      {
                        $attribs{$tag} = int($info->{playtime_seconds});
                      }
                    elsif($tag eq "track_num")
                      {
                        $attribs{$tag} = $tags->{TRACKNUMBER};
                      }
                    elsif($tag eq "year")
                      {
                        $attribs{$tag} = $tags->{YEAR};
                      }
                    elsif($tag eq "id")
                      {
                        $attribs{$tag} = extract_id($tags->{DESCRIPTION});
                      }
                    elsif($tag eq "file")
                      {
                        $attribs{$tag} = $src_file;
                      }
                    elsif($tag eq "original_format")
                      {
                        $attribs{$tag} = $format;
                        my $bitrate = closest_bitrate($format,$info->{bitrate},
                                                      @{$formats{$format}->{bitrates}});
                        if(defined $bitrate && $bitrate ne "")
                          {
                            $attribs{$tag} = "${format}:${bitrate}";
                          }
                        else
                          {
                            $attribs{$tag} = $format;
                          }
                      }
                    elsif($tag eq "dir_artist" || $tag eq "dir_album" ||
                          $tag eq "quality")
                      {
                      }
                    else
                      {
                        carp("unknown $format tag \"$tag\"");
                      }
                  }
                return %attribs;
              },
          },
        mp3 =>
          {
            uses_encoder => "lame",

            # The MP3::Info package is implicitly called by
            # total_secs_int
            uses_package => ["MP3::Tag","MP3::Info",],
            # Bitrates defined in the mp3 standard
            bitrates => [32, 40, 48, 56, 64, 80, 96, 
                         112, 128, 144, 160, 192, 224, 256, 320],
            ext => "mp3",
            to_working => sub
              {
                my($format,$src_file,$dest_file) = @_;
    
                # decode an mp3 to wav
                # $src_file & $dest_file have been dosified already

                system("$paths{lame} -h --decode \"$src_file\" -o \"$dest_file\"");
              },
            is_valid => sub
              {
                my($format,$src_file) = @_;
                if(!-r $src_file)
                  {
                    carp("Cannot read $format file \"$src_file\"");
                    return "";
                  }
                my $mp3 = MP3::Tag->new($src_file);
                if(!defined $mp3)
                  {
                    carp("File \"$src_file\" appears to not be $format format");
                    return "";
                  }
                return 1;
              },
            from_working => sub
              {
                # encode a wav to mp3
                my($format,$src_file,$dest_file) = @_;
    
                # decode an mp3 to wav

                # $src_file & $dest_file are dosified by the caller

                my $bitrate = bitrate_of($format);
                my $br_flag = "-b $bitrate";
                $br_flag = "" if($bitrate eq "");

                system("$paths{lame} -h $br_flag \"$src_file\" -o \"$dest_file\"");
              },
            get_tags => sub
              {
                # How to grab tags from an mp3 file
                my($format,$src_file) = @_;
                my $mp3 = MP3::Tag->new($src_file);
                if(!defined $mp3)
                  {
                    carp("File \"$src_file\" appears to not be $format format");
                    return "";
                  }
                my %attribs;
                $mp3->get_tags();
                foreach my $tag (@attribs)
                  {
                    if($tag eq "file")
                      {
                        $attribs{$tag} = $src_file;
                        next;
                      }
                    elsif($tag eq "length_secs")
                      {
                        $attribs{$tag} = $mp3->total_secs_int();
                      }
                    elsif($tag eq "original_format")
                      {
                        $attribs{$tag} = $format;
                        $attribs{$tag} = $format;
                        my $bitrate = closest_bitrate($format,1000*$mp3->bitrate_kbps(),
                                                      @{$formats{$format}->{bitrates}});
                        if(defined $bitrate && $bitrate ne "")
                          {
                            $attribs{$tag} = "${format}:${bitrate}";
                          }
                        else
                          {
                            $attribs{$tag} = $format;
                          }
                      }
                    elsif($tag eq "quality")
                      {
                        my $bitrate = $mp3->bitrate_kbps();
                        if(!defined $bitrate)
                          {
                            $attribs{$tag} = 7;
                          }
                        elsif($bitrate > 200)
                          {
                            $attribs{$tag} = 8;
                          }
                        elsif($bitrate > 100)
                          {
                            $attribs{$tag} = 7;
                          }
                        elsif($bitrate > 64)
                          {
                            $attribs{$tag} = 6;
                          }
                        else
                          {
                            $attribs{$tag} = 5;
                          }
                      }
                    elsif($tag eq "dir_artist" || $tag eq "dir_album" ||
                          $tag eq "quality")
                      {
                        $attribs{$tag} = "";
                      }
                  }
                if(defined $mp3->{ID3v2})
                  {
                    foreach my $tag (@attribs)
                      {
                        next if(defined $attribs{$tag});
                        my $id3v2 = $mp3_tags_to_ID3v2{$tag};
                        next if(!defined $id3v2);
                        my($val,$typ) = $mp3->{ID3v2}->get_frame($id3v2);
                        next if(!defined $val);
                        if($tag eq "id")
                          {
                            $attribs{$tag} = extract_id($val->{Text});
                            next;
                          }
                        $attribs{$tag} = $val;
                      }
                  }
                if(defined $mp3->{ID3v1})
                  {
                    foreach my $tag (@attribs)
                      {
                        next if(defined $attribs{$tag});
                        # I don't see an easy way to do this, so...
                        if($tag eq "album")
                          {
                            $attribs{$tag} = $mp3->{ID3v1}->album;
                          }
                        elsif($tag eq "title")
                          {
                            $attribs{$tag} = $mp3->{ID3v1}->song;
                          }
                        elsif($tag eq "artist")
                          {
                            $attribs{$tag} = $mp3->{ID3v1}->artist;
                          }
                        elsif($tag eq "track_num")
                          {
                            $attribs{$tag} = $mp3->{ID3v1}->track;
                          }
                        elsif($tag eq "year")
                          {
                            $attribs{$tag} = $mp3->{ID3v1}->year;
                          }
                        elsif($tag eq "id")
                          {
                            $attribs{$tag} = extract_id($mp3->{ID3v1}->comment);
                          }
                        else
                          {
                            carp("unknown $format tag \"$tag\"");
                          }
                      }
                  }
                return %attribs;
              },
            set_tags => sub
              {
                # How to assign tags in an mp3 file
                my($vals_hash,$file_name) = @_;

                my $mp3 = MP3::Tag->new($file_name);
                if(!defined $mp3)
                  {
                    carp("Cannot get tags from $file_name");
                    return "";
                  }
                if(!defined $mp3->{ID3v2})
                  {
                    $mp3->new_tag("ID3v2");
                  }

                foreach my $tag (keys %mp3_tags_to_ID3v2)
                  {
                    my $val = $vals_hash->{$tag};
                    if(!defined $val)
                      {
                        carp("Cannot find value for $val in $vals_hash->{id}");
                        $val = "";
                      }
                    my $frame = $mp3_tags_to_ID3v2{$tag};
                    my @extra = ();

                    if($tag eq "id")
                      {
                        $val = insert_id($vals_hash->{id});
                        @extra = ("ENG","Short Text");
                      }
                    if(defined $mp3->{ID3v2}->get_frame($frame))
                      {
                        $mp3->{ID3v2}->change_frame($frame,@extra,$val);
                      }
                    else
                      {
                        $mp3->{ID3v2}->add_frame($frame,@extra,$val);
                      }
                  }
                $mp3->{ID3v2}->write_tag();
                
                return 1;
              },
          },
      );
    
    foreach my $format (keys %formats)
      {
        # Is this format to be ignored?
        if(defined $formats{$format}->{disabled} && 
                     $formats{$format}->{disabled})
          {
            next;
          }

        next if(!MusicRoom::is_running());
        my $is_disabled = MusicRoom::get_conf("${format}_disabled",1);
        if(defined $is_disabled && $is_disabled)
          {
            $formats{$format}->{disabled} = 1;
            next;
          }

        my @encoders;
        if(!defined $formats{$format}->{uses_encoder})
          {
            @encoders = ();
          }
        elsif(ref($formats{$format}->{uses_encoder}) eq "ARRAY")
          {
            @encoders = @{$formats{$format}->{uses_encoder}};
          }
        else
          {
            @encoders = ($formats{$format}->{uses_encoder});
          }
        if(!_check_encoders($format,@encoders))
          {
            $formats{$format}->{disabled} = 1;
            next;
          }

        my @packages;
        if(!defined $formats{$format}->{uses_package})
          {
            @packages = ();
          }
        elsif(ref($formats{$format}->{uses_package}) eq "ARRAY")
          {
            @packages = @{$formats{$format}->{uses_package}};
          }
        else
          {
            @packages = ($formats{$format}->{uses_package});
          }

        if(!_check_packages($format,@packages))
          {
            $formats{$format}->{disabled} = 1;
            next;
          }

        my @exts = ($format);
        if(defined $formats{$format}->{ext})
          {
            if(ref($formats{$format}->{ext}) eq "ARRAY")
              {
                @exts = @{$formats{$format}->{ext}};
              }
            else
              {
                @exts = ($formats{$format}->{ext});
              }
          }
        elsif(defined $formats{$format}->{no_ext} &&
                          $formats{$format}->{no_ext})
          {
            # The format is explicitly not the extension
            @exts = ();
          }
    
        foreach my $ext (@exts)
          {
            if(defined $exts{$ext})
              {
                carp("Multiple formats could have extension $ext ($format, ".
                          $exts{$ext}.")");
              }
            $exts{$ext} = $format;
            my @bitrates = ();
            @bitrates = @{$formats{$format}->{bitrates}}
                           if(defined $formats{$format}->{bitrates});
            foreach my $bitrate ("",@bitrates)
              {
                my $fmt = "$ext:$bitrate";
                $fmt = $ext if($bitrate eq "");
                next if(defined $formats{$fmt});
                my %desc = %{$formats{$format}};
                $desc{bitrate} = $bitrate if($bitrate ne "");
                $formats{$fmt} = \%desc;
              }
          }
      }
  }

sub closest_bitrate
  {
    my($format,$real_bitrate,@bitrates) = @_;

    # Anything within 10% will match
    foreach my $try (@bitrates)
      {
        my $ratio = $real_bitrate / $try;
        return $try if($ratio > 900 && $ratio < 1100);
      }
    return undef;
  }

sub extract_id
  {
    my($from_val) = @_;

    return undef if(!defined $from_val || $from_val eq "");
    if($from_val =~ /TrackID\{(.+)\}/i)
      {
        return $1;
      }
    return undef;
  }

sub insert_id
  {
    my($id) = @_;

    return "TrackID{${id}}";
  }

sub _check_packages
  {
    my($format,@packages) = @_;

    my $num_failed = 0;
    foreach my $package (@packages)
      {
        my $success = 0;
        eval("require $package;\$success = 1;");

        next if($success);
        $num_failed++;
        carp("Failed to load perl module \"$package\", $format format will be disabled");
      }
    return "" if($num_failed > 0);
    return 1;
  }

sub _check_encoders
  {
    my($format,@programs) = @_;

    my $num_failed = 0;

    foreach my $program_name (@programs)
      {
        foreach my $dir (MusicRoom::get_conf("tools_dir"),$ENV{PATH})
          {
            foreach my $extension ("",".exe",".pl",".bat")
              {
                if(-x "$dir/$program_name$extension")
                  {
                    $paths{$program_name} = dosify("$dir/$program_name$extension");
                    last;
                  }
              }
            last if(defined $paths{$program_name});
          }
        next if(defined $paths{$program_name});

        $num_failed++;
        carp("Cannot find program \"$program_name\" required for $format conversion");
        $paths{$program_name} = "";
      }
    return "" if($num_failed > 0);
    return 1;
  }

sub _is_valid_src
  {
    my($format,$src_file) = @_;

    return "" if(defined $formats{$format}->{disabled} &&
                         $formats{$format}->{disabled});

    if(!-r $src_file)
      {
        carp("Cannot read file \"$src_file\"");
        return "";
      }
    if(defined $formats{$format}->{is_valid})
      {
        return &{$formats{$format}->{is_valid}}($format,$src_file);
      }

    # Any format without an is_valid method is assumed to be 
    # valid without looking at it
    return 1;
  }

sub _is_valid_dest
  {
    my($format,$dest_file) = @_;
    return "" if(defined $formats{$format}->{disabled} &&
                         $formats{$format}->{disabled});

    if(-r $dest_file)
      {
        carp("File \"$dest_file\" already exists");
        return "";
      }
    return 1;
  }

sub _get_tags
  {
    my($format,$src_file) = @_;

    @attribs = MusicRoom::Track::attribs() if(!@attribs);
    
    return undef if(defined $formats{$format}->{disabled} &&
                         $formats{$format}->{disabled});
    if(!-r $src_file)
      {
        carp("Cannot read file \"$src_file\"");
        return ();
      }
    if(defined $formats{$format}->{get_tags})
      {
        my %attribs = &{$formats{$format}->{get_tags}}($format,$src_file);
        $attribs{file} = $src_file;
        if(defined $attribs{track_num})
          {
            if($attribs{track_num} =~ /^\D*(\d+)/)
              {
                $attribs{track_num} = $1;
              }
          }
        $attribs{quality} = 7 
                          if(!defined $attribs{quality} ||
                                       $attribs{quality} eq "");

        foreach my $attrib (@attribs)
          {
            $attribs{$attrib} = "" if(!defined $attribs{$attrib});
          }
        return %attribs;
      }
    return ();
  }

sub format_of
  {
    my($src_file) = @_;
    _init();

    my $format;

    if($src_file =~ /\.([^\.]+)$/)
      {
        # We have an extension
        $format = lc($1);
      }
    else
      {
        carp("Cannot deduce extension from \"$src_file\"");
        return undef;
      }

    if(!defined $formats{$format})
      {
        carp("$format format is not supported");
        return undef;
      }
    if(defined $formats{$format}->{disabled} &&
                         $formats{$format}->{disabled})
      {
        carp("$format format is not enabled");
      }
    return $format;
  }

sub get_tags
  {
    my($src_file) = @_;
    _init();
    my $format = format_of($src_file);
    if(!defined $format || $format eq "")
      {
        return undef;
      }
    return _get_tags($format,$src_file);
  }

sub is_valid_src
  {
    my($src_file) = @_;
    _init();
    my $format = format_of($src_file);
    if(!defined $format || $format eq "")
      {
        return undef;
      }
    return _is_valid_src($format,$src_file);
  }

sub is_valid_dest
  {
    my($src_file) = @_;
    _init();
    my $format = format_of($src_file);
    if(!defined $format || $format eq "")
      {
        return undef;
      }
    return _is_valid_dest($format,$src_file);
  }

sub tidy
  {
    # Given a name return one suitable for using in most 
    # file systems as a file name.  This means that we must remove 
    # any characters that are at all dubious
    my($name) = @_;

    _init();
    # Some file names are actualy two or more of these concatenated
    # so this limit needs to be well within the OS limit (often 
    # 128 chars)
    my $max_len = 50;

    # Do a real job on removing troublesome chars (the only 
    # ones left should be [a-zA-Z0-9_\(\) \'])
    $name =~ s/[\`\"]/\'/g;
    $name =~ s/[\/\\\:\;\^\|]/ /g;
    $name =~ s/[\-\,\x7f-\xff\*\.\=\~]/_/g;
    $name =~ s/[\!\#\$\%\?]//g;
    $name =~ s/_+/_/g;
    $name =~ s/^\s+//;
    $name =~ s/\s+$//;
    $name =~ s/\s+/ /g;
    $name =~ s/\s+_/_/g;
    $name =~ s/_\s+/ /g;
    $name =~ s/[\&]/\+/g;
    $name =~ s/[\<\[\{]/\(/g;
    $name =~ s/[\>\]\}]/\(/g;

    if(length($name) > $max_len)
      {
        if($name =~ /(\([^\(\)]+\))$/)
          {
            my $qualifier = $1;
            my $pre = substr($`,0,$max_len - length($qualifier));
            $name = $pre.$qualifier;
          }
        else
          {
            $name = substr($name,0,$max_len);
          }
      }
    return $name;
  }

sub latest
  {
    my($base_name,%options) = @_;

    my @extensions;

    $options{dir} = "." if(!defined $options{dir});
    if($base_name =~ m#/+([^/]+)$#)
      {
        $options{dir} .= "/".$`;
        $base_name = $1;
      }

    if(!defined $options{look_for})
      {
        $options{look_for} = "";
      }
    if(ref($options{look_for}) eq "ARRAY")
      {
        @extensions = @{$options{look_for}};
      }
    else
      {
        @extensions = split(/,/,$options{look_for});
      }
    my $quiet = "";
    $quiet = $options{quiet} if(defined $options{quiet});

    my %wanted_ext;
    foreach my $ext (@extensions)
      {
        $wanted_ext{$ext} = "want";
      }

    local(*DIR);
    opendir(DIR,$options{dir});
    my @files = readdir(DIR);
    closedir(DIR);
    my $best_name = "";
    my $best_time = 0;
    
    foreach my $file (@files)
      {
        next if(!-r "$options{dir}/$file");
        next if($file =~ /\~$/);

        if(@extensions && $file =~ m#\.([^\.]+)$#)
          {
            # We have an extension, is this wanted?
            my $ext = lc($1);
            next if(!defined $wanted_ext{$ext} || 
                                    $wanted_ext{$ext} ne "want");
          }
        
        if($file =~ m#^$base_name#i)
          {
            my $this_time = (stat("$options{dir}/$file"))[9];
            if($this_time > $best_time)
              {
                $best_name = "$options{dir}/$file";
                $best_time = (stat("$options{dir}/$file"))[9];
              }
          }
      }
    if($best_name eq "" || $best_time <= 0)
      {
        return undef if($options{quiet});
        croak("Cannot find file $options{dir}/$base_name");
      }
    return $best_name;
  }

sub new_name
  {
    # Generate a new file name
    my($base,$typ) = @_;

    _init();
    my($s,$mi,$h,$d,$mo,$y,$wd) = gmtime(time);
    
    my $nam1 = sprintf("$base-%02d%s%02d.$typ",$y % 100,
               ('Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec')[$mo],$d);
    my $try_count = 1;
    while(1)
      {
        last if(!-r $nam1);
        $nam1 = sprintf("$base-%02d%s%02d_%02d.$typ",$y % 100,
               ('Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec')[$mo],$d,$try_count++);
      }
    return $nam1;
  }

sub formats
  {
    # Provide a list of the formats that this software understands
    _init();
    return keys %formats;
  }

sub working_format
  {
    _init();
    return $working_format;
  }

sub extensions
  {
    _init();
    return keys %exts;
  }

sub is_music_extension
  {
    my($ext) = @_;

    _init();
    if(!defined $exts{$ext})
      {
        if(defined $exts{lc($ext)})
          {
            # Ah an extension with upper case in it, complain and 
            # fix it
            $exts{$ext} = $exts{lc($ext)};
            carp("Extension \"$ext\" should probably be ".lc($ext));
            return 1;
          }
        return "";
      }
    return 1;
  }

sub formats_extension
  {
    my($format) = @_;
    _init();
    if(!defined $formats{$format})
      {
        if(defined $formats{lc($format)})
          {
            carp("\"$format\" should be in lower case");
            return extension_of(lc($format));
          }
        carp("\"$format\" is not a defined format");
        return "";
      }
    return $format
             if(!defined $formats{$format}->{ext});
    return $formats{$format}->{ext}->[0]
             if(ref($formats{$format}->{ext}) eq "ARRAY");
    return $formats{$format}->{ext};
  }

sub convert_audio
  {
    # Convert an audio file
    my($in_file,$in_format,$out_file,$out_format) = @_;

    _init();
    # Convert a sound file 

    # There are only three options that work, if the two formats 
    # are the same we have a copy, if the input format is the 
    # working one we use the from_working methods and if the 
    # output format is the working one we use the to_working methods
    # Anything else and we refuse
    return ""
                  if(!_is_valid_src($in_format,$in_file));
    return ""
                  if(!_is_valid_dest($out_format,$out_file));

    if($in_format eq $out_format)
      {
        # Just copy from one place to another
        my $os_in_file = dosify($in_file);
        my $os_out_file = dosify($out_file);
        copy($os_in_file,$os_out_file);
      }
    elsif($in_format eq $working_format)
      {
        # This converts from_working format
        if(!defined $formats{$out_format}->{from_working})
          {
            carp("Cannot find converter to $out_format");
            return "";
          }
        my $os_in_file = dosify($in_file);
        my $os_out_file = dosify($out_file);

        &{$formats{$out_format}->{from_working}}($out_format,$os_in_file,$os_out_file);
      }
    elsif($out_format eq $working_format)
      {
        # Convert to working format
        if(!defined $formats{$in_format}->{to_working})
          {
            carp("Cannot find converter from $in_format");
            return "";
          }
        my $os_in_file = dosify($in_file);
        my $os_out_file = dosify($out_file);

        &{$formats{$in_format}->{to_working}}($in_format,$os_in_file,$os_out_file);
      }
    else
      {
        carp("Cannot do general audio conversions, go via $working_format format");
        return "";
      }
    if(!-r $out_file)
      {
        # The conversion failed
        carp("Failed to create file \"$out_file\"");
        return "";
      }
    if(-s $out_file < 1024)
      {
        # A file this small is probably a problem
        carp("Output file \"$out_file\" is too small");
        return "";
      }
    return 1;
  }

sub normalise
  {
    my($dir,$mode,@files) = @_;

    _init();

    _check_encoders("","normalize");
    if(!defined $paths{normalize} || $paths{normalize} eq "")
      {
        croak("Cannot find the normalize command");
      }
    my $dos_cmd = $paths{normalize};
    if($mode eq "by_dir")
      {
        my $cmd = "$dos_cmd -b";
        foreach my $file (@files)
          {
            $cmd .= " \"".dosify("$dir/$file")."\"";
          }
        system($cmd);
      }
    else
      {
        foreach my $file (@files)
          {
            my $cmd = "$dos_cmd \"".dosify("$dir/$file")."\"";
            system($cmd);
          }
      }
  }

sub set_tags
  {
    my($tag_ref,$file_name,$format) = @_;
    _init();

    # Extract the attributes to a standard form
    my %attribs;
    if(ref($tag_ref) eq "HASH")
      {
        %attribs = %{$tag_ref};
      }
    elsif(ref($tag_ref) eq MusicRoom::Track::perl_class())
      {
        foreach my $attr ("album","title","artist","track_num","year","id")
          {
            $attribs{$attr} = $tag_ref->get($attr);
          }
      }
    else
      {
        croak("Function must have a hash or a Track object");
      }

    if(!-w $file_name)
      {
        # This shouldn't happen but...
        chmod 0755,$file_name;
      }
    if(!-w $file_name)
      {
        carp("Cannot write to $file_name");
        return "";
      }
    if(!defined $formats{$format}->{set_tags})
      {
        carp("Do not yet have a procedure for setting tags in $format");
        return "";
      }
    return &{$formats{$format}->{set_tags}}(\%attribs,$file_name);
  }

sub dosify
  {
    # Commands on some OSs make a fuss if the directory seperator 
    # is /
    my($name) = @_;

    _init();
    if(!defined $operating_system)
      {
        croak("The OS is not defined");
      }
    if($operating_system =~ /^MSWin/i)
      {
        # Take a perfectly good name and mess it up
        $name =~ s#/#\\#g;
      }
    # I think everything else can just use what we have been given
    return $name;
  }

sub bitrate_of
  {
    # Need a better way to do this
    my($format) = @_;

    _init();
    return $1
        if($format =~ /\:(\d+)$/);
    return "";
  }

1;
