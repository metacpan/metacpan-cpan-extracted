#===============================================================================
#
#         FILE:  Run.pm
#
#  DESCRIPTION:  Function to run individual tests
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Geoffrey Leach, <geoff@hughes.net>
#      VERSION:  1.1.11
#      CREATED:  12/20/07 13:29:02 PST
#    COPYRIGHT:  (c) 2008-2010 Geoffrey Leach
#===============================================================================

package Run;
use 5.006002;

use strict;
use warnings;

use Carp;
use English qw{ -no_match_vars };
use File::Slurp;
use Readonly;
use IPC::Run qw( start pump finish );
use Test::More qw(no_plan);

BEGIN {
    use_ok(q{Pod::HtmlEasy});
    use_ok( q{Pod::HtmlEasy::Data},
        qw( EMPTY NL body css gen head headend title toc top podon podoff ) );
}

use Exporter::Easy ( OK => [qw( run html_file )], );

my $pod_file  = q{test.pod};
my $html_file = q{test.html};
my $htmleasy  = Pod::HtmlEasy->new;
ok( defined $htmleasy, q{New HtmlEasy} );

Readonly::Scalar my $LAST_OK => 3;
my ($test_id) = $PROGRAM_NAME =~ m{(\w+)\.t\Z}smx;
my $test_no = $LAST_OK;

my %default_opts = (
    no_css       => 1,
    title        => $html_file,
    no_generator => 1,
);

sub run {    ## no critic (ProhibitExcessComplexity)
    my ( $desc, $pod, $expect, $inx, $opts ) = @_;

    $test_no++;
    my $test = sprintf q{%s-%02d.html}, $test_id, $test_no;

    # If $pod is undef we test against empty input
    my @pod;
    if ( defined $pod ) {

        # EMPTY becomes an empty line when NL is mapped in below
        @pod = ( q{=pod}, EMPTY );

        push @pod, map { ( $_, EMPTY ) } @{$pod};
        push @pod, q{=cut};
        @pod = map { $_ . NL } @pod;
    }
    write_file( $pod_file, \@pod );
    if ( not defined $opts ) { $opts = \%default_opts; }
    if ( not exists $opts->{title} ) {
        $opts->{title} = $default_opts{title};
    }
    if ( exists $opts->{htmleasy} ) {

        # Alert: $htmleasy is now not what it was originally defined
        $htmleasy = $opts->{htmleasy};
        delete $opts->{htmleasy};
    }
    my @html;
    if ( exists $opts->{stdio} ) {

        # Generate code to pipe @pod to pod2html and retrieve outptut

        # Simple expression for expected StDERR output RT 92035
        my $error_tag = $opts->{stdio};

        # Avoid complaint option stdio not suported
        delete $opts->{stdio};

        my ( $in, $out, $err );

        # Execute this
        my @cmd = ( $EXECUTABLE_NAME, qw{-Ilib -MPod::HtmlEasy -e} );

        # Note: no "'"!
        # To test the "-" file convention, add '"-",' after the left paren
        my $cmd = q{Pod::HtmlEasy->new->pod2html(};

        # Stringify options, add to -e command
        foreach my $k ( keys %{$opts} ) {
            $cmd .= $k . q{,} . $opts->{$k} . q{,};
        }
        $cmd =~ s{title,([\w.]+)}{title,'$1'};
        $cmd =~ s{,$}{};
        $cmd .= q{)};

        # Complete the command
        push @cmd, $cmd;
        my $harness = start \@cmd, \$in, \$out, \$err;
        foreach my $p (@pod) {
            $in .= $p;
            $harness->pump;
        }
        $harness->finish;
        ## no critic (RequireExtendedFormatting RequireLineBoundaryMatching)
        @html = map {qq{$_\n}} split m{\n}, $out;

        if ( $err ) {
            if ( $err !~ m{$error_tag} ) {
                carp $err;
            }
        }
    }
    elsif ( exists $opts->{outfile} ) {

        # Outfile is for this;
        my $outfile = $opts->{outfile};
        delete $opts->{outfile};
        @html
            = $htmleasy->pod2html( $pod_file, q{output}, $outfile, %{$opts} );
    }
    else {
        @html = $htmleasy->pod2html( $pod_file, %{$opts} );
    }
    if ( defined $expect ) {
        my @expect;
        if ( not $opts->{only_content} ) {
            @expect = head();
            if ( not exists $opts->{no_generator} ) {
                push @expect,
                    gen( $Pod::HtmlEasy::VERSION, $Pod::Parser::VERSION );
            }
            push @expect, title( $opts->{title} );
            if ( exists $opts->{css} ) {
                push @expect, css( $opts->{css} );
            }
            else {
                if ( not exists $opts->{no_css} ) { push @expect, css(); }
            }
            push @expect, headend();
            push @expect, body( $opts->{body} );
        }
        if ( exists $opts->{top} )          { push @expect, top(); }
        if ( not exists $opts->{no_index} ) { push @expect, toc( @{$inx} ); }
        push @expect, podon();
        push @expect, @{$expect};
        push @expect, podoff( exists $opts->{only_content} ? 1 : undef );
        @expect = map { $_ . NL } @expect;
        if ( not is_deeply( \@html, \@expect, $desc ) ) {
            print qq{POD input $test}, NL, @pod, NL,
                qq{Expected output $test}, NL, @expect, NL,
                qq{Actual output $test}, NL, @html
                or carp q{Unable to print output html};
        }
    }
    else {
        print qq{Actual output $test}, NL, @html
            or carp q{Unable to print output html};
    }

    if ( exists $ENV{DUMPHTML} ) { write_file( $test, \@html ); }
    unlink $pod_file, $html_file;
    return;
}

sub html_file { return $html_file; }

1;
