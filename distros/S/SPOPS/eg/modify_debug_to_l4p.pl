#!/usr/bin/perl

# modify_log.pl
#   Translate existing '_w()' and '_wm()' logging statements to the
#   new log4perl stuff

use strict;
use File::Find;

my $VALID_EXTENSION_RE = 'pm';

my %LEVELS = (
    0 => 'warn',
    1 => 'info',
    2 => 'debug',
    3 => 'debug',
    4 => 'debug',
    5 => 'debug',
);

my $dir = shift @ARGV || '.';
find( \&wanted, $dir );

sub wanted {
    my $base_file = $_;
    return unless ( /\.$VALID_EXTENSION_RE$/ );
    my $full_file   = $base_file;
    my $backup_file = $base_file . ".old";
    my $new_file    = $base_file . ".new";
    open( OLD, '<', $full_file )
                    || die "Cannot read '$full_file': $!";
    my @lines   = ();

    my $has_changes = 0;
    my $use_idx     = 0;
    my $log_idx     = 0;
    my $line_count  = 0;
    my $in_code     = 1;

LINE:
    while( <OLD> ) {

        if ( /^(=pod|=head|__END__)/ ) {
            $in_code = 0;
        }

        unless ( $in_code ) {
            push @lines, $_;
            $line_count++;
            next LINE;
        }

        # put the 'use Log::Log4perl' after 'use strict' ...
        if ( /^use strict/ ) {
            $use_idx = $line_count + 1;
        }
        # ...or 'use base' if it's around
        elsif ( /^use base/ ) {
            $use_idx = $line_count + 1;
        }

        # ...or if neither defined, somewhere around some other 'use'
        # statements; and the '$log' package lexical should be
        # somewhere after the last 'use'
        if ( /^use/ ) {
            $use_idx ||= $line_count + 1;
            $log_idx   = $line_count + 2;
        }

        # Get rid of imports (not used anymore)
        if ( /^use SPOPS(\s|\;)/ ) {
            $_ = "use SPOPS;\n";
            $has_changes++;
        }

        # Do all these separately since we need to capture the initial
        # space (and my regex-fu ain't all that... )

        # debug: using _w + DEBUG
        elsif ( /^(\s*)DEBUG(\(\s*\))?\s*&&\s*_w\(\s*(\w+)\s*,\s*(.*)$/ ) {
            my ( $pad, $old_level, $msg ) = ( $1, $3, $4 );
            $_ = transform_old( $pad, $old_level, $msg );
            $has_changes++;
        }

        # debug: using _w w/o DEBUG
        elsif ( /^(\s*)_w\(\s*(\w+)\s*,\s*(.*)$/ ) {
            my ( $pad, $old_level, $msg ) = ( $1, $2, $3 );
            $_ = transform_old( $pad, $old_level, $msg );
            $has_changes++;
        }

        # debug: using _wm + DEBUG
        elsif ( /^(\s*)[\w\$\_]*DEBUG[\w_]*(\(\s*\))?\s*&&\s*_wm\(\s*(\w+)\s*,\s*([^,]+),\s*(.*)$/ ) {
            my ( $pad, $old_level, $msg ) = ( $1, $3, $5 );
            $_ = transform_old( $pad, $old_level, $msg );
            $has_changes++;
        }

        # debug: using _wm w/o DEBUG
        elsif ( /^(\s*)_wm\(\s*(\w+)\s*,\s*([^,]+),\s*(.*)$/ ) {
            my ( $pad, $old_level, $msg ) = ( $1, $2, $4 );
            $_ = transform_old( $pad, $old_level, $msg );
            $has_changes++;
        }

        push @lines, $_;
        $line_count++;
    }
    close( OLD );
    $_ = $base_file;
    return unless ( $has_changes );
    warn "File '$File::Find::name' has changes\n";

    # Add the 'use' and '$log' declaration (this could have
    # problems with premature initialization...)

    splice( @lines, $use_idx, 0,
            "use Log::Log4perl qw( get_logger );\n" );
    splice( @lines, $log_idx, 0,
            "\nmy \$log = get_logger();\n" );

    open( NEW, '>', $new_file )
                    || die "Cannot write to '$new_file': $!";
    print NEW join( '', @lines );
    close( NEW );

    rename( $full_file, $backup_file );
    rename( $new_file, $full_file );
}


sub transform_old {
    my ( $pad, $old_level, $msg ) = @_;
    my $level = $LEVELS{ $old_level };
    if ( $level =~ /^(warn|error|fatal)$/ ) {
        return "$pad\$log->$level( $msg\n";
    }
    else {
        return "$pad\$log->is_$level &&\n" .
               "$pad    \$log->$level( $msg\n";
    }
}

__END__

=head1 NAME

modify_debug_to_l4p.pl - Modify SPOPS 0.80 and earlier logging statements to use log4perl

=head1 SYNOPSIS

 $ cd /path/to/my/SPOPS/source
 $ perl modify_debug_to_l4p.pl

=head1 DESCRIPTION

This script modifies your .pm files to use Log4perl instead of the
woefully inadequate SPOPS debugging. It probably won't get 100% of
your debugging statements, but it will take care of the common cases
and leave you to deal manually with the (hopefully) small handful of
exceptions.

=head2 Configuration

You shouldn't need to do any configuration to make this work. That
said...

B<Changing Directory Processed>

By default it recursively processes all files ending in '.pm' in the
current directory. To use a different directory pass it in on the
command-line:

 # Use the current directory
 $ perl modify_debug_to_l4p.pl
 
 # Use another directory
 $ perl modify_debug_to_l4p.pl /path/to/other/source

B<Changing Files Processed>

You can modify the files processed by changing the variable
'$VALID_EXTENSION_RE' from:

 my $VALID_EXTENSION_RE = 'pm';

to something like:

 my $VALID_EXTENSION_RE = '(pm|pl|cgi)';

B<Changing Level Mapping>

The old SPOPS debugging used numbers for logging levels, but log4perl
uses names. (Much better!) We map the numbers to levels like this:

 0 => warn
 1 => info
 2 => debug
 3 => debug
 4 => debug
 5 => debug

So this:

 _w( 0, "Message goes here" );

will become:

 $log->warn( "Message goes here" );

and:

 _w( 1, "Other message goes here" );

will become:

 $log->is_info &&
     $log->info( "Other message goes here" );

You can change this by modifying the C<%LEVELS> variable.

Note also that 'debug' and 'info' levels get the initial 'is_debug' or
'is_info' check, while 'warn', 'error' and 'fatal' do not.

=head2 What It Changes

B<Import statements>

The import of the debugging constants is no longer needed, so:

 use SPOPS qw( _w DEBUG );

becomes:

 use SPOPS;

Most people won't even need the 'use', but we left it in just in
case. (It won't hurt anything...)

=head2 What It Changes: Debugging Statements

This is where most of the work is done. The main cases are:

B<With _w and DEBUG>

Change:

 DEBUG() && _w( 0, "This is my message (0)" );
 DEBUG() && _w( 1, "This is my message (1)" );
 DEBUG() && _w( 2, "This is my message (2)" );

to:

 $log->warn( "This is my message (0)" );
 $log->is_info &&
     $log->info( "This is my message (1)" );
 $log->is_debug &&
     $log->debug( "This is my message (2)" );

B<With _w>

Change:

 _w( 0, "This is my message (0)" );
 _w( 1, "This is my message (1)" );
 _w( 2, "This is my message (2)" );

to:

 $log->warn( "This is my message (0)" );
 $log->is_info &&
     $log->info( "This is my message (1)" );
 $log->is_debug &&
     $log->debug( "This is my message (2)" );

B<With _wm and DEBUG>

Note that we discard the comparison with the old variable:

Change:

 DEBUG() && _wm( 0, $LEVEL_VAR, "This is my message (0)" );
 DEBUG() && _wm( 1, $LEVEL_VAR, "This is my message (1)" );
 DEBUG() && _wm( 2, $LEVEL_VAR, "This is my message (2)" );

to:

 $log->warn( "This is my message (0)" );
 $log->is_info &&
     $log->info( "This is my message (1)" );
 $log->is_debug &&
     $log->debug( "This is my message (2)" );

B<With _wm>

Note that we discard the comparison with the old variable:

Change:

 _wm( 0, $LEVEL_VAR, "This is my message (0)" );
 _wm( 1, $LEVEL_VAR, "This is my message (1)" );
 _wm( 2, $LEVEL_VAR, "This is my message (2)" );

to:

 $log->warn( "This is my message (0)" );
 $log->is_info &&
     $log->info( "This is my message (1)" );
 $log->is_debug &&
     $log->debug( "This is my message (2)" );

=head2 What It Adds

B<Log4perl include>

We add a:

 use Log::Log4perl qw( get_logger );

somewhere after 'use strict' and 'use base'. If you care about
alphabetizing your includes this might drive you crazy. Patches
welcome.

B<Package-level logger>

Taking the side of simplicity we didn't add a logger declaration in
every scope we found the previous debugging statements in. Instead we
just added:

 my $log = get_logger();

somewhere after the 'use' statements are done. This may cause problems
with premature initialization of the logger, but hopefully in whatever
scripts you're using SPOPS for you initialize the logger B<before>
initializing SPOPS. In fact you may want to change something like:

 use strict;
 use SPOPS::Initialize;
 ...
 sub runs_at_startup {
     my ( $class ) = @_;
     my %config = get_spops_config();
     SPOPS::Initialize->process({ config => \%config });
 }

to:

 use strict;
 use Log::Log4perl;
 ...
 sub runs_at_startup {
     my ( $class ) = @_;
     Log::Log4perl::init( '/path/to/my/log4perl.conf' );
     my %config = get_spops_config();
     require SPOPS::Initialize;
     SPOPS::Initialize->process({ config => \%config });
 }

=head1 SEE ALSO

L<Log::Log4perl>

=head1 AUTHOR

Chris Winters E<lt>chris@cwinters.comE<gt>
