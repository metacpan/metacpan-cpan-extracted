# Use the output of list_lyrics to identify songs without lyrics 
# then try and use Lyric::Fetcher to grab them and put them in the 
# lyrics directory
use strict;
use warnings;

BEGIN
  {
    foreach my $dir ('../lib','lib','.')
      {
        unshift @INC,$dir if(-d $dir);
      }
  }

use IO::File;
use Carp;
use MusicRoom;
use MusicRoom::Lyrics;
use Lyrics::Fetcher;
use LWP;

my $browser = LWP::UserAgent->new();
$browser->agent('Mozilla/5.0 (Windows; U; Windows NT 5.1; en-GB; rv:1.7.10) Gecko/20050717 Firefox/1.0.6');

my $ifh = IO::File->new("missing-lyrics.csv");
if(!defined $ifh)
  {
    croak("Cannot open file \"missing-lyrics.csv\"");
  }

my $local_save_dir = "lyrics";

mkdir $local_save_dir,0755
          if(!-d $local_save_dir);
if(!-d $local_save_dir)
  {
    croak("Cannot create local save directory $local_save_dir");
  }
my $local_flag_dir = "missing_lyrics";

mkdir $local_flag_dir,0755
          if(!-d $local_flag_dir);
if(!-d $local_flag_dir)
  {
    croak("Cannot create local save directory $local_flag_dir");
  }

# Which entry in the musicroom_path do we want to save to?
my $save_slot = 2;

MusicRoom::Text::CSV::scan($ifh,action => \&fetch_lyric,discard_data=>1);
$ifh->close();

exit 0;

sub fetch_lyric
  {
    my(%attribs) = @_;

    if(!defined $attribs{lyrics_file})
      {
        croak("No lyrics_file column in CSV, giving up");
      }
    return
        if($attribs{lyrics_file} ne "");

    my @search_names = split(/\s*,\s*/,$attribs{search_list});
    my $full_target = $search_names[$save_slot];
    # File name removes the dir part of the path
    my $file_name = $full_target;
    if($file_name =~ m#\/([^\/]+)$#)
      {
        $file_name = $1;
      }

    # First do we have a file in the flag_dir indicating that we should ignore 
    # this one?
    return if(-f "$local_flag_dir/$file_name");

    # Or do we have a valid version in the local dir?
    return if(-f "$local_save_dir/$file_name");

    # OK try and grab the lyric
    my $lyrics;
    foreach my $try_artist (varients_of($attribs{artist}))
      {
        foreach my $try_song (varients_of($attribs{title}))
          {
#            next if($try_artist =~ /\'[^\']*\'/);
#            next if($try_song =~ /\'[^\']*\'/);
            $try_artist =~ s/^\s+//;
            $try_artist =~ s/\s+$//;
            $try_song =~ s/^\s+//;
            $try_song =~ s/\s+$//;
print "Calling |$try_artist| |$try_song|\n";
            foreach my $lyric_src (Lyrics::Fetcher->available_fetchers())
              {
                # sleep 2;
                $lyrics = Lyrics::Fetcher->fetch($try_artist,$try_song,$lyric_src);

                next if(!defined $lyrics || $lyrics eq "");
                # Ignore any lyrics that failed, or redirect if the 
                # returned value suggests it
                if($lyrics =~ /Sorry,\s+this\s+song\s+or\s+the\s+artist\s+is\s+deleted/i)
                  {
                    $lyrics = "";
                  }
                elsif($lyrics =~ /ad_text/i)
                  {
                    # Need to extract from added advertising crap that Lyrics007
                    # Inserts
                    my $post = $';
                    $post =~ s/^[^\n\r]*[\n\r]+//;
                    if($post =~ /ad_text/i)
                      {
                        $lyrics = $`;
                      }
                    else
                      {
                        carp("Cannot find back marker");
                      }
                  }
                elsif($lyrics =~ /due\s+to\s+licensing\s+restrictions/i)
                  {
                    # Ah, the site has the lyrics but cannot send them through the API
                    $lyrics = redirect_fetch($lyrics);
                    if(!defined $lyrics || $lyrics eq "")
                      {
                        carp("Redirect failed");
                      }
                  }
                last if(defined $lyrics && $lyrics ne "");
              }
            last if(defined $lyrics);
          }
        last if(defined $lyrics);
      }

    if(!defined $lyrics || $lyrics eq "")
      {
        # Nothing here, flag it and move on
failed:
        my $flag_fh = IO::File->new(">$local_flag_dir/$file_name");
        print $flag_fh "Failed";
        $flag_fh->close();
        return;
      }

    # Save it
    my $ofh = IO::File->new(">$local_save_dir/$file_name");
    print $ofh <<"EndFile";
#
# Artist: $attribs{artist}
# Song: $attribs{title}
#

$lyrics
EndFile
    $ofh->close();
  }

sub varients_of
  {
    my($try) = @_;

    my @versions = ($try);
    if($try =~ /\sand\s/i)
      {
        my $v = $try;
        $v =~ s/\s+and\s+/ \& /g;
        push @versions,$v,$`,$';
      }
    if($try =~ /\s\&\s/i)
      {
        my $v = $try;
        $v =~ s/\s+\&\s+/ and /g;
        push @versions,$v,$`,$';
      }
    if($try =~ /^The\s/i)
      {
        my $v = $try;
        $v =~ s/^The\s+//g;
        push @versions,$v;
      }
    if($try =~ /^A\s/i)
      {
        my $v = $try;
        $v =~ s/^A\s+//g;
        push @versions,$v;
      }
    if($try =~ /\(([^\(\)]*)\)/)
      {
        my($pre,$in,$post) = ($`,$1,$');
        if($pre ne "")
          {
            push @versions,$pre,$pre.$in;
            push @versions,$pre.$in.$post,$pre.$post if($post ne "");
          }
        if($post ne "")
          {
            push @versions,$post,$in.$post;
          }
        push @versions,$in;
      }
    if($try =~ /\./)
      {
        my $v = $try;
        $v =~ s/\.//g;
        push @versions,$v;
      }
    if($try =~ /in\'\s/ || $try =~ /in\'$/)
      {
        my $v = $try;
        $v =~ s/in\'\s/ing /g;
        $v =~ s/in\'$/ing/g;
        push @versions,$v;
      }
    if($try =~ /\'/)
      {
        my $v = $try;
        $v =~ s/\'//g;
        push @versions,$v;
      }
    my %mapping = 
      (
        "Pauline Black" => "The Selector",
        "Bad Manners" => "Madness",
        "Rankin\' Roger" => "The Specials",
        "Breakaway" => "Break Away",
        "Indigo Girls et al." => "Andrew Lloyd Webber",
        "Indigo Girls et al." => "Original Broadway Cast Recording",
        "Monty Python" => "Original Broadway Cast Recording",
        "Tom Robinson Band" => "Tom Robinson",
      );
    foreach my $val (@versions)
      {
        push @versions,$mapping{$val} if(defined $mapping{$val});
      }
    return @versions;
  }

sub redirect_fetch
  {
    my($source) = @_;
    my $result;

    if($source =~ m#(http:\/+.+)#im)
      {
        my $url = $1;
        my $request = HTTP::Request->new(GET => $url);
        my $response = $browser->request($request);
        if(!$response->is_success())
          {
            print STDERR "\nFailed to get $url\n";
            return;
          }
        my $page_contents = $response->content();
        if($page_contents =~ /<div\s+class=[\'\"]lyricbox[\'\"]\s*>/i)
          {
            my $lyrics_from = $';
            if($lyrics_from =~ m#(<p|</div)#)
              {
                my $lyric = $`;
                $lyric =~ s#<br\s*/>#\n#gi;
                return $lyric;
              }
            carp("Cannot find end of lyric");
            return "";
          }
        else
          {
            carp("Cannot identify lyricbox in content");
            return "";
          }
      }

    carp("Don't know how to redirect");
    return "";
  }

