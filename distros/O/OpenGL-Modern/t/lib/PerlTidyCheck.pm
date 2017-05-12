package PerlTidyCheck;

use strict;
use warnings;

use IO::All -binary;
use Capture::Tiny 'capture_merged';
use Perl::Tidy 'perltidy';
use Test::More;

sub format_untidied_entry {
    my ( $untidied ) = @_;

    my ( $file, $diff ) = @{$untidied};
    $diff ||= "";

    if ( $diff ) {
        my @diff = split /\n/, $diff;
        if ( @diff > 20 ) {
            @diff = ( @diff[ 0 .. 19 ], "[... snip ...]\n" );
            $diff = join "\n", "", @diff;
        }
        $file = ( "-" x 78 ) . "\n$file:\n";
        $diff = $diff . ( "-" x 78 ) . "\n\n";
    }

    return "$file\n$diff";
}

sub find_untidied_files {
    my ( $exclude_filter ) = @_;
    my @perl = find_perl_files();
    @perl = $exclude_filter->( @perl ) if $exclude_filter;
    my @untidied = map time_check( $_ ), @perl;
    return @untidied;
}

sub find_perl_files { grep !/\bblib\b/, grep /(^[^.]|\.(pl|PL|pm|t))$/, io( "." )->All_Files }

sub time_check {
    my ( $file ) = @_;
    my $start    = time;
    my @res      = check_tidy_status( $file );
    note sprintf "%s - $file", time - $start;
    return @res;
}

sub check_tidy_status {
    my ( $file ) = @_;

    my $source = $file->all;
    my $tidy   = transform_source( $source );
    return if $source eq $tidy;

    return [ "$file", "" ] if !require Text::Diff;

    my $diff = Text::Diff::diff( \$source, \$tidy, { Style => 'Unified' } );
    return [ "$file", $diff ];
}

# from Code::TidyAll::Plugin::PerlTidy
sub transform_source {
    my ( $source ) = @_;

    # perltidy reports errors in two different ways.
    # Argument/profile errors are output and an error_flag is returned.
    # Syntax errors are sent to errorfile or stderr, depending on the
    # the setting of -se/-nse (aka --standard-error-output).  These flags
    # might be hidden in other bundles, e.g. -pbp.  Be defensive and
    # check both.
    my ( $output, $error_flag, $errorfile, $stderr, $destination );
    $output = capture_merged {
        $error_flag = perltidy(
            source      => \$source,
            destination => \$destination,
            stderr      => \$stderr,
            errorfile   => \$errorfile
        );
    };
    die $stderr          if $stderr;
    die $errorfile       if $errorfile;
    die $output          if $error_flag;
    print STDERR $output if defined $output;
    return $destination;
}

1;
