#!/usr/bin/perl

# $Id: template_translate.pl,v 1.2 2001/08/26 04:38:52 lachoy Exp $

# template_translate.pl
#
#   Translates templates in one or more directories from the old style
#   Template Toolkit integration to the new style.
#
#   Modified templates are saved under the same name as the old
#   template; the old template is renamed to 'name.old' -- nothing is
#   deleted.

# Usage:
#   perl template_translate.pl dir [ dir, dir ... ]

# Author:
#   Chris Winters <chris@cwinters.com>

use strict;

# from OI::Template

my @TT_PROP = qw(
     security_level security_scope login logged_in login_group return_url
     error_hold session
);
my $REGEX_TT_PROP = join( '|', @TT_PROP );

# from OI::Template::Toolkit

my @TT_FUNC = qw(
     comp limit_string javascript_quote regex_chunk box_add limit_sentences
     percent_format money_format html_encode html_decode
);
my $REGEX_TT_FUNC = join( '|', @TT_FUNC );


# Map old OI::Template::Toolkit methods to the new ones

my %TT_RENAME = (
   object_info    => 'object_description',
   ucfirst        => 'uc_first',
   date_into_hash => 'date_into_object',
);
my $REGEX_TT_RENAME = join( '|', keys %TT_RENAME );


# Custom functions (deal with these individually)

my @CUSTOM = ( 'dump_it', 'simulate_sprintf', 'now\(' );
my $REGEX_TT_CUSTOM = join( '|', @CUSTOM );

# Theme key to check for

my $THEME_KEY = 'th\.';


{
    my @dir_process = @ARGV;
    local $/ = undef;

DIR:
    foreach my $dir ( @dir_process ) {
        unless ( -d $dir ) {
            warn "Not processing directory ($dir): it does not seem to exist.\n";
            next DIR;
        }
        warn "Dir: $dir\n";
        opendir( TMPLDIR, $dir ) || die "Cannot open directory ($dir): $!";
        my @files = grep /\.tmpl$/, readdir( TMPLDIR );
        closedir( TMPLDIR );
FILE:
        foreach my $filename ( @files ) {
            my $full_filename = join( '/', $dir, $filename );
            open( TMPL, $full_filename ) || die "Cannot open file ($full_filename): $!";
            my $text = <TMPL>;
            my $translated = translate( $text );
            close( TMPL );
            unless ( $translated ne $text ) {
                warn "   NOT changed: $full_filename\n";
                next FILE;
            }
            rename( $full_filename, "$full_filename.old" );
            open( NEW, "> $full_filename" ) || die "Cannot open file ($full_filename) for writing: $!";
            print NEW $translated;
            close( NEW );
            warn "   CHANGED: $full_filename\n";
        }
    }
}



sub translate {
    my ( $text ) = @_;

    # First the 'easy' stuff -- everything in @TT_prop needs to have
    # an 'OI.' slapped in front

    $text =~ s/\b($REGEX_TT_PROP)\b/OI.$1/gsm;

    # Now the functions

    $text =~ s/\b($REGEX_TT_FUNC)\(/OI.$1\(/gsm;

    # Now renaming thingies

    $text =~ s/\b($REGEX_TT_RENAME)\(/"OI.$TT_RENAME{ $1 }("/gsme;

    # Themes -- rather than rename the 'th.xxx' calls, we'll just
    # create a hash called 'th' in every template that uses themes

    if ( $text =~ /$THEME_KEY/ ) {
        $text = join( "\n", '[%- th = OI.theme_properties -%]', $text );
    }

    # Custom stuff -- these are rarely used, but issue warnings anyway

    if ( my @custom_keys = $text =~ /($REGEX_TT_CUSTOM)/gsm ) {
        foreach my $custom_key ( @custom_keys ) {
            if ( $custom_key eq 'dump_it' ) {
                $text = join( "\n", '[%- USE Dumper -%]', $text );
                $text =~ s/dump_it\(/Dumper.dump\(/g;
            }
            elsif ( $custom_key eq 'simulate_sprintf' ) {
               warn "********************\n",
                    "Please see docs about replacing 'simulate_sprintf' -- not translated.\n",
                    "********************\n";
            }
            elsif ( $custom_key eq 'now\(' ) {
               warn "********************\n",
                    "Please see docs about replacing 'now' -- not translated.\n",
                    "********************\n";
           }
        }
    }
    return $text;
}
