#################################################################################
#########This Perl module represents the CPAN name space Net::Hulu.##############
####################Written by Gerald L. Hevener, M.S.###########################
##############AKA: jackl0phty in the whitehat hacker community.##################
#########This module is licensed under the same terms as Perl itself.############
#########Maintainer's Email:  hevenerg {[AT]} marshall {[DOT]} edu.##############
#After years of using free (as in beer) software, thought I'd try to give back. #
#################################################################################

# declare package name
package Net::Hulu;

use 5.006000;
use strict;
use warnings;
use Carp;
use XML::Twig;
use LWP::Simple;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::Hulu ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
		get_recent_videos get_recent_shows get_recent_movies get_highest_rated_videos
                get_popular_videos_today get_popular_videos_this_week
		get_popular_videos_this_month get_popular_videos_all_time
                get_soon_to_expire_videos get_recent_blog_postings download_recent_videos_xml
                download_recent_shows_xml download_recent_movies_xml download_highest_rated_videos_xml
                download_popular_videos_today_xml download_popular_videos_this_week_xml
		download_popular_videos_this_month_xml download_popular_videos_all_time_xml
		download_soon_to_expire_videos_xml download_recent_blog_postings_xml
);

our $VERSION = '0.03';

# declare variables for recent videos
my $recent_videos_url = "http://rss.hulu.com/HuluRecentlyAddedVideos?format=xml";
my $recent_videos_root;
my $recent_videos_xml;
my $recent_videos_twig = new XML::Twig(TwigRoots => {'item' => 1, pretty_print => 'indented'});

# declare variables for recent shows
my $recent_shows_url = "http://rss.hulu.com/HuluRecentlyAddedShows?format=xml";
my $recent_shows_root;
my $recent_shows_xml;
my $recent_shows_twig = new XML::Twig(TwigRoots => {'item' => 1, pretty_print => 'indented'});

# declare variables for recent movies
my $recent_movies_url = "http://rss.hulu.com/HuluRecentlyAddedMovies?format=xml";
my $recent_movies_root;
my $recent_movies_xml;
my $recent_movies_twig = new XML::Twig(TwigRoots => {'item' => 1, pretty_print => 'indented'});

# declare variables for highest rated videos
my $highest_rated_videos_url = "http://www.hulu.com/feed/highest_rated/videos";
my $highest_rated_videos_root;
my $highest_rated_videos_xml;
my $highest_rated_videos_twig = new XML::Twig(TwigRoots => {'item' => 1, pretty_print => 'indented'});

# declare variables for popular videos today
my $popular_videos_today_url = "http://rss.hulu.com/HuluPopularVideosToday?format=xml";
my $popular_videos_today_root;
my $popular_videos_today_xml;
my $popular_videos_today_twig = new XML::Twig(TwigRoots => {'item' => 1, pretty_print => 'indented'});

# declare variables for popular videos this week
my $popular_videos_this_week_url = "http://rss.hulu.com/HuluPopularVideosThisWeek?format=xml";
my $popular_videos_this_week_root;
my $popular_videos_this_week_xml;
my $popular_videos_this_week_twig = new XML::Twig(TwigRoots => {'item' => 1, pretty_print => 'indented'});

# declare variables for popular videos this month
my $popular_videos_this_month_url = "http://rss.hulu.com/HuluPopularVideosThisMonth?format=xml";
my $popular_videos_this_month_root;
my $popular_videos_this_month_xml;
my $popular_videos_this_month_twig = new XML::Twig(TwigRoots => {'item' => 1, pretty_print => 'indented'});

# declare variables for popular videos of all time
my $popular_videos_all_time_url = "http://rss.hulu.com/HuluPopularVideosAllTime?format=xml";
my $popular_videos_all_time_root;
my $popular_videos_all_time_xml;
my $popular_videos_all_time_twig = new XML::Twig(TwigRoots => {'item' => 1, pretty_print => 'indented'});

# declare variables for soon to expire videos 
my $soon_to_expire_videos_url = "http://www.hulu.com/feed/expiring/videos";
my $soon_to_expire_videos_root;
my $soon_to_expire_videos_xml;
my $soon_to_expire_videos_twig = new XML::Twig(TwigRoots => {'item' => 1, pretty_print => 'indented'});

# declare variables for recent blog postings
my $recent_blog_postings_url = "http://rss.hulu.com/HuluBlog?format=xml";
my $recent_blog_postings_root;
my $recent_blog_postings_xml;
my $recent_blog_postings_twig = new XML::Twig(TwigRoots => {'item' => 1, pretty_print => 'indented'});

# preloaded methods go here.
######################Begin Primary Subroutines##########################

sub get_recent_videos {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        $recent_videos_twig->parsefile("HuluRecentlyAddedVideos?format=xml");

        #set root of the twig (channel).
        $recent_videos_root = $recent_videos_twig->root;

        #get recent videos titles.
        foreach my $recent_videos_titles ($recent_videos_root->children('item')) {

                print $recent_videos_titles->first_child_text('title');
                print "\n";
        }

# sub get_recent_videos()
}

sub get_recent_shows {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #parse xml file for recent shows.
        $recent_shows_twig->parsefile("HuluRecentlyAddedShows?format=xml");

        #set root of the twig (channel).
        $recent_shows_root = $recent_shows_twig->root;

        #get recent videos titles.
        foreach my $recent_shows_titles ($recent_shows_root->children('item')) {

                print $recent_shows_titles->first_child_text('title');
                print "\n";
        }

# sub get_recent_shows()
}

sub get_recent_movies {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #parse xml file for recent movies.
        $recent_movies_twig->parsefile("HuluRecentlyAddedMovies?format=xml");

        #set root of the twig (channel).
        $recent_movies_root = $recent_movies_twig->root;

        #get recent movies titles.
        foreach my $recent_movies_titles ($recent_movies_root->children('item')) {

                print $recent_movies_titles->first_child_text('title');
                print "\n";
        }

# sub get_recent_movies() 
}

sub get_highest_rated_videos {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #parse xml file for highest rated videos.
        $highest_rated_videos_twig->parsefile("videos");

        #set root of the twig (channel).
        $highest_rated_videos_root = $highest_rated_videos_twig->root;

        #get highest rated videos.
        foreach my $highest_rated_videos_titles ($highest_rated_videos_root->children('item')) {

                print $highest_rated_videos_titles->first_child_text('title');
                print "\n";
        }

# sub get_highest_rated_videos()
}

sub get_popular_videos_today {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #parse xml file for popular videos today.
        $popular_videos_today_twig->parsefile("HuluPopularVideosToday?format=xml");

        #set root of the twig (channel).
        $popular_videos_today_root = $popular_videos_today_twig->root;

        #get popular videos today.
        foreach my $popular_videos_today_titles ($popular_videos_today_root->children('item')) {

                print $popular_videos_today_titles->first_child_text('title');
                print "\n";
        }

# sub get_popular_videos_today()
}

sub get_popular_videos_this_week {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #parse xml file for popular videos this week.
        $popular_videos_this_week_twig->parsefile("HuluPopularVideosThisWeek?format=xml");

        #set root of the twig (channel).
        $popular_videos_this_week_root = $popular_videos_this_week_twig->root;

        #get popular videos this week.
        foreach my $popular_videos_this_week_titles ($popular_videos_this_week_root->children('item')) {

                print $popular_videos_this_week_titles->first_child_text('title');
                print "\n";
        }

# sub get_popular_videos_this_week()
}

sub get_popular_videos_this_month {

	#Turn on strict and warnings.
        use strict;
        use warnings;

        #parse xml file for popular videos this month.
        $popular_videos_this_month_twig->parsefile("HuluPopularVideosThisMonth?format=xml");

        #set root of the twig (channel).
        $popular_videos_this_month_root = $popular_videos_this_month_twig->root;

        #get popular videos this month.
        foreach my $popular_videos_this_month_titles ($popular_videos_this_month_root->children('item')) {

                print $popular_videos_this_month_titles->first_child_text('title');
                print "\n";
        }

# sub get_popular_videos_this_month()
}

sub get_popular_videos_all_time {
	
	#Turn on strict and warnings.
	use strict;
	use warnings;

        #parse xml file for popular videos of all time.
        $popular_videos_all_time_twig->parsefile("HuluPopularVideosAllTime?format=xml");

        #set root of the twig (channel)
        $popular_videos_all_time_root = $popular_videos_all_time_twig->root;

        #get popular videos all time
        foreach my $popular_videos_all_time_titles ($popular_videos_all_time_root->children('item')) {

                print $popular_videos_all_time_titles->first_child_text('title');
                print "\n";
        }

# sub get_popular_videos_all_time()         
}

sub get_soon_to_expire_videos {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #parse xml file for soon to expire videos.
        $soon_to_expire_videos_twig->parsefile("videos.1");

        #set root of the twig (channel).
        $soon_to_expire_videos_root = $soon_to_expire_videos_twig->root;

        #get soon to expire videos.
        foreach my $soon_to_expire_videos_titles ($soon_to_expire_videos_root->children('item')) {

                print $soon_to_expire_videos_titles->first_child_text('title');
                print "\n";
        }

# sub get_soon_to_expire_videos()
}

sub get_recent_blog_postings {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #parse xml file for hulu's recent blog postings. (Hulu's primary RSS feed).
        $recent_blog_postings_twig->parsefile("HuluBlog?format=xml");

        #set root of the twig (channel).
        $recent_blog_postings_root = $recent_blog_postings_twig->root;

        #get hulu's recent blog postings
        foreach my $recent_blog_postings_titles ($recent_blog_postings_root->children('item')) {

                print $recent_blog_postings_titles->first_child_text('title');
                print "\n";
        }

# sub get_recent_blog_postings()         
}

######################End of primary subroutines##########################

########Begin subroutines that download XML RSS feeds from Hulu###########

sub download_recent_videos_xml {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #get xml using LWP::Simple.
        $recent_videos_xml = get $recent_videos_url;

        #get rid of non-ascii chars.
        $recent_videos_xml =~ s/[^[:ascii:]]+//g;

        #save XML to file.
        open( my $RECENT_VIDEOS_FH, ">", "HuluRecentlyAddedVideos?format=xml" ) or confess "Can't open file: $!";

                #print recent videos to file in PWD.
                print $RECENT_VIDEOS_FH "$recent_videos_xml";

        close($RECENT_VIDEOS_FH);

# sub download_recent_videos_xml()
}

sub download_recent_shows_xml {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #get xml using LWP::Simple.
        $recent_shows_xml = get $recent_shows_url;

        #get rid of non-ascii chars.
        $recent_shows_xml =~ s/[^[:ascii:]]+//g;

        #save XML to file.
        open( my $RECENT_SHOWS_FH, ">", "HuluRecentlyAddedShows?format=xml" ) or confess "Can't open file: $!";

                #print recent shows to file in PWD.
                print $RECENT_SHOWS_FH "$recent_shows_xml";

        close($RECENT_SHOWS_FH);

# sub download_recent_shows_xml()
}

sub download_recent_movies_xml {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #get xml using LWP::Simple.
        $recent_movies_xml = get $recent_movies_url;

        #get rid of non-ascii chars.
        $recent_movies_xml =~ s/[^[:ascii:]]+//g;

        #save XML to file.
        open( my $RECENT_MOVIES_FH, ">", "HuluRecentlyAddedMovies?format=xml" ) or confess "Can't open file: $!";

                #print recent movies to file in PWD.
                print $RECENT_MOVIES_FH "$recent_movies_xml";

        close($RECENT_MOVIES_FH);

# sub download_recent_movies().
}

sub download_highest_rated_videos_xml {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #get xml using LWP::Simple.
        $highest_rated_videos_xml = get $highest_rated_videos_url;

        #get rid of non-ascii chars.
        $highest_rated_videos_xml =~ s/[^[:ascii:]]+//g;

        #save XML to file.
        open( my $HIGHEST_RATED_VIDEOS_FH, ">", "videos" ) or confess "Can't open file: $!";

                #print highest rated videos to file in PWD.
                print $HIGHEST_RATED_VIDEOS_FH "$highest_rated_videos_xml";

        close($HIGHEST_RATED_VIDEOS_FH);

# sub download_highest_rated_videos_xml().
}

sub download_popular_videos_today_xml {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #get xml using LWP::Simple.
        $popular_videos_today_xml = get $popular_videos_today_url;

        #get rid of non-ascii chars.
        $popular_videos_today_xml =~ s/[^[:ascii:]]+//g;

        #save XML to file.
        open( my $POPULAR_VIDEOS_TODAY_FH, ">", "HuluPopularVideosToday?format=xml" ) or confess "Can't open file: $!";

                #print popular videos for today to file in PWD.
                print $POPULAR_VIDEOS_TODAY_FH "$popular_videos_today_xml";

        close($POPULAR_VIDEOS_TODAY_FH);

# sub download_popular_videos_today_xml.
}

sub download_popular_videos_this_week_xml {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #get xml using LWP::Simple.
        $popular_videos_this_week_xml = get $popular_videos_this_week_url;

        #get rid of non-ascii chars.
        $popular_videos_this_week_xml =~ s/[^[:ascii:]]+//g;

        #save XML to file.
        open( my $POPULAR_VIDEOS_THIS_WEEK_FH, ">", "HuluPopularVideosThisWeek?format=xml" ) or confess "Can't open file: $!";

                #print popular videos for this week to file in PWD.
                print $POPULAR_VIDEOS_THIS_WEEK_FH "$popular_videos_this_week_xml";

        close($POPULAR_VIDEOS_THIS_WEEK_FH);

# sub download_popular_videos_this_week().
}

sub download_popular_videos_this_month_xml {

        #Turn on strict and warnings.
        use strict;
        use warnings;

        #get xml using LWP::Simple.
        $popular_videos_this_month_xml = get $popular_videos_this_month_url;

        #get rid of non-ascii chars.
        $popular_videos_this_month_xml =~ s/[^[:ascii:]]+//g;

        #save XML to file.
        open( my $POPULAR_VIDEOS_THIS_MONTH_FH, ">", "HuluPopularVideosThisMonth?format=xml" ) or confess "Can't open file: $!";

                #print popular videos for this month to file in PWD.
                print $POPULAR_VIDEOS_THIS_MONTH_FH "$popular_videos_this_month_xml";

        close($POPULAR_VIDEOS_THIS_MONTH_FH);

# sub download_popular_videos_this_month().
}

sub download_popular_videos_all_time_xml {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #get xml using LWP::Simple.
        $popular_videos_all_time_xml = get $popular_videos_all_time_url;

        #get rid of non-ascii chars.
        $popular_videos_all_time_xml =~ s/[^[:ascii:]]+//g;

        #save XML to file.
        open( my $POPULAR_VIDEOS_ALL_TIME_FH, ">", "HuluPopularVideosAllTime?format=xml" ) or confess "Can't open file: $!";

                #print popular videos of all time to file in PWD.
                print $POPULAR_VIDEOS_ALL_TIME_FH "$popular_videos_all_time_xml";

        close($POPULAR_VIDEOS_ALL_TIME_FH);

# sub download_popular_videos_all_time_xml()
}

sub download_soon_to_expire_videos_xml {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #get xml using LWP::Simple.
        $soon_to_expire_videos_xml = get $soon_to_expire_videos_url;

        #get rid of non-ascii chars.
        $soon_to_expire_videos_xml =~ s/[^[:ascii:]]+//g;

        #save XML to file.
        open( my $SOON_TO_EXPIRE_VIDEOS_FH, ">", "videos" ) or confess "Can't open file: $!";

                #print soon to expire videos to file in PWD.
                print $SOON_TO_EXPIRE_VIDEOS_FH "$soon_to_expire_videos_xml";

        close($SOON_TO_EXPIRE_VIDEOS_FH);

# sub download_soon_to_expire_videos_xml().
}

sub download_recent_blog_postings_xml {

	#Turn on strict and warnings.
	use strict;
	use warnings;

        #get xml using LWP::Simple.
        $recent_blog_postings_xml = get $recent_blog_postings_url;

        #get rid of non-ascii chars.
        $recent_blog_postings_xml =~ s/[^[:ascii:]]+//g;

        #save XML to file.
        open( my $RECENT_BLOG_POSTINGS_FH, ">", "HuluBlog?format=xml" ) or confess "Can't open file: $!";

                #print recent blog postings to file in PWD.
                print $RECENT_BLOG_POSTINGS_FH "$recent_blog_postings_xml";

        close($RECENT_BLOG_POSTINGS_FH);

# sub download_recent_blog_postings_xml().
}

# Modules must return a true value
1;
