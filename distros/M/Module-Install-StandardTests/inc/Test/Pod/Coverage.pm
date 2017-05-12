#line 1
package Test::Pod::Coverage;

#line 11

our $VERSION = "1.08";

#line 74

use strict;
use warnings;

use Pod::Coverage;
use Test::Builder;

my $Test = Test::Builder->new;

sub import {
    my $self = shift;
    my $caller = caller;
    no strict 'refs';
    *{$caller.'::pod_coverage_ok'}       = \&pod_coverage_ok;
    *{$caller.'::all_pod_coverage_ok'}   = \&all_pod_coverage_ok;
    *{$caller.'::all_modules'}           = \&all_modules;

    $Test->exported_to($caller);
    $Test->plan(@_);
}

#line 112

sub all_pod_coverage_ok {
    my $parms = (@_ && (ref $_[0] eq "HASH")) ? shift : {};
    my $msg = shift;

    my $ok = 1;
    my @modules = all_modules();
    if ( @modules ) {
        $Test->plan( tests => scalar @modules );

        for my $module ( @modules ) {
            my $thismsg = defined $msg ? $msg : "Pod coverage on $module";

            my $thisok = pod_coverage_ok( $module, $parms, $thismsg );
            $ok = 0 unless $thisok;
        }
    }
    else {
        $Test->plan( tests => 1 );
        $Test->ok( 1, "No modules found." );
    }

    return $ok;
}


#line 150

sub pod_coverage_ok {
    my $module = shift;
    my %parms = (@_ && (ref $_[0] eq "HASH")) ? %{(shift)} : ();
    my $msg = @_ ? shift : "Pod coverage on $module";

    my $pc_class = (delete $parms{coverage_class}) || 'Pod::Coverage';
    eval "require $pc_class" or die $@;

    my $pc = $pc_class->new( package => $module, %parms );

    my $rating = $pc->coverage;
    my $ok;
    if ( defined $rating ) {
        $ok = ($rating == 1);
        $Test->ok( $ok, $msg );
        if ( !$ok ) {
            my @nakies = sort $pc->naked;
            my $s = @nakies == 1 ? "" : "s";
            $Test->diag(
                sprintf( "Coverage for %s is %3.1f%%, with %d naked subroutine$s:",
                    $module, $rating*100, scalar @nakies ) );
            $Test->diag( "\t$_" ) for @nakies;
        }
    }
    else { # No symbols
        my $why = $pc->why_unrated;
        my $nopublics = ( $why =~ "no public symbols defined" );
        my $verbose = $ENV{HARNESS_VERBOSE} || 0;
        $ok = $nopublics;
        $Test->ok( $ok, $msg );
        $Test->diag( "$module: $why" ) unless ( $nopublics && !$verbose );
    }

    return $ok;
}

#line 199

sub all_modules {
    my @starters = @_ ? @_ : _starting_points();
    my %starters = map {$_,1} @starters;

    my @queue = @starters;

    my @modules;
    while ( @queue ) {
        my $file = shift @queue;
        if ( -d $file ) {
            local *DH;
            opendir DH, $file or next;
            my @newfiles = readdir DH;
            closedir DH;

            @newfiles = File::Spec->no_upwards( @newfiles );
            @newfiles = grep { $_ ne "CVS" && $_ ne ".svn" } @newfiles;

            push @queue, map "$file/$_", @newfiles;
        }
        if ( -f $file ) {
            next unless $file =~ /\.pm$/;

            my @parts = File::Spec->splitdir( $file );
            shift @parts if @parts && exists $starters{$parts[0]};
            shift @parts if @parts && $parts[0] eq "lib";
            $parts[-1] =~ s/\.pm$// if @parts;

            # Untaint the parts
            for ( @parts ) {
                if ( /^([a-zA-Z0-9_\.\-]+)$/ && ($_ eq $1) ) {
                    $_ = $1;  # Untaint the original
                }
                else {
                    die qq{Invalid and untaintable filename "$file"!};
                }
            }
            my $module = join( "::", @parts );
            push( @modules, $module );
        }
    } # while

    return @modules;
}

sub _starting_points {
    return 'blib' if -e 'blib';
    return 'lib';
}

#line 303

1;
