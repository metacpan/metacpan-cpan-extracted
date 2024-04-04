package Qhull::PP;

# ABSTRACT: Pure Perl interface to Qhull
use v5.26;

use strict;
use warnings;
use experimental 'signatures', 'lexical_subs', 'declared_refs';

our $VERSION = '0.06';


use Exporter::Shiny 'qhull';
use Scalar::Util 'blessed';
use Ref::Util 'is_arrayref';

use List::Util 'any';
use Log::Any '$log';

use Eval::Closure 'eval_closure';
use Ref::Util 'is_hashref', 'is_plain_arrayref';
use File::Spec;
use Qhull::Util 'parse_output';
use Qhull::Util::Options 'CAT_OUTPUT_FORMAT';
use Qhull::Options;
use System::Command;


use Alien::Qhull;

my sub croak {
    require Carp;
    our @CARP_NOT = qw( Qhull );
    goto \&Carp::croak;
}

use constant qhull_exe => do {
    my $exe;
    if ( my @bin_dirs = Alien::Qhull->bin_dir ) {
        for my $dir ( @bin_dirs ) {
            $exe = File::Spec->catfile( $dir, 'qhull' );
            last if -x $exe;
            undef $exe;
        }
    }

    _croak( q{Qhull executable 'qhull' was not found} )
      if !defined $exe;

    $exe;
};

my sub build_feed_qhull {
    my @args = @_;

    # individual coordinate elements
    if ( @args == 1 && blessed $args[0] && $args[0]->isa( 'PDL' ) ) {
        croak( 'a single NDArray argument must have dimensions == 2: got ' . $args[0]->ndims )
          if $args[0]->ndims != 2;
        @args = $args[0]->dog;
    }

    # these are captured in the constructed feed_qhull() sub; $nelem
    # is determined after scanning the input
    my $nelem;
    my $ndims = @args;
    croak( 'number of dimensions must be > 1' )
      if @args < 2;

    my @qsub;
    my @extents;
    my $icoord = 0;
    for my $coord ( @args ) {
        if ( is_plain_arrayref( $coord ) ) {
            push @extents, 0+ @$coord;
            push @qsub,    sprintf( q|$coord[%d][$_]|, $icoord );
        }
        elsif ( blessed $coord && $coord->isa( 'PDL' ) ) {
            croak( "coord[$icoord]: NDArray coordinate argument must be 1D" )
              if $coord->ndims != 1;
            push @extents, $coord->nelem;
            push @qsub,    sprintf( q|$coord[%d]->at($_)|, $icoord );
        }
        else {
            croak( "coord[$icoord] is neither a Perl arrayref or an NDArray" );
        }
    }
    continue { $icoord++ }

    # initialize value for capture.
    $nelem = $extents[0];

    croak( 'coordinate arrays must have the same extent: ' . join( ', ', @extents ) )
      if any { $_ != $nelem } @extents;

    # actually the following is not quite true.  depending upon what
    # the caller is asking to be computed, the minimum number of
    # points may be larger.
    croak( 'number of points must be > 1' )
      if $nelem < 2;

    my $source = join( "\n",
        q| use experimental 'signatures'; |,
        q| sub ($fh) { |,
        q| $fh->say( $ndims ); |,
        q| $fh->say( $nelem ); |,
        q| $fh->say( join( "\t", |,
        join( ', ', @qsub ),
        qq|) ) for (0..$nelem-1)|, q|}|, );

    return (
        eval_closure(
            source      => $source,
            environment => {
                '@coord' => \@args,
                '$ndims' => \$ndims,
                '$nelem' => \$nelem,
            },
        ),
        $source,
    );
}







































## no critic( Subroutines::ProhibitExcessComplexity )
sub qhull ( @coords ) {

    my %option = (
        raw         => !!0,
        passthrough => [],
        trace       => !!0,
        qh_opts     => undef,
        save_input  => undef,
        is_hashref( $coords[-1] ) ? %{ pop @coords } : (),
    );

    my $raw        = delete $option{raw};
    my $trace      = delete $option{trace};
    my $qh_opts    = delete( $option{qh_opts} ) // [];
    my $save_input = delete $option{save_input};

    if ( is_arrayref( $qh_opts ) ) {
        $qh_opts = Qhull::Options->new_from_options( $qh_opts );
        my $passthrough = delete $option{passthrough};
        $qh_opts = $qh_opts->filter_args( passthrough => $passthrough )
          if !$raw;
    }
    elsif ( !blessed( $qh_opts ) || !$qh_opts->isa( 'Qhull::Options' ) ) {
        croak( 'qh_opts must be a Qhull::Options object or an arrayref' );
    }

    # default mode is convex hull, return orderd list of indices (extrema), (format => 'Fx')
    $qh_opts = $qh_opts->clone_with_options( ['Fx'] )
      if !$qh_opts->has_compute && !$qh_opts->has_output_format;

    croak( 'unknown options passed to qhull: ' . join( ', ', keys %option ) )
      if %option;

    croak( 'specify coordinates either via "TI" or as an argument to qhull(), but not both' )
      if @coords && defined $qh_opts->input;

    croak( 'no coordinates specified' )
      if !defined $qh_opts->input && !@coords;

    # if there are errors in creating the feed routine, die before starting up
    # qhull
    my ( $feed, $feed_source ) = @coords ? build_feed_qhull( @coords ) : ();

    $log->is_debug
      && $log->debug( 'executing qhull: ', $qh_opts->qhull_opts );

    my @cmd = ( qhull_exe, $qh_opts->qhull_opts->@* );
    my $cmd = System::Command->new( @cmd );
    if ( $feed ) {

        # Log::Any says don't use newlines; ignore that advice here.
        $log->trace( $feed_source );

        if ( defined $save_input ) {
            open my $fh, '>', $save_input
              or croak( "unable to create $save_input" );
            $feed->( $fh );
            $fh->close or croak( "error closing $save_input" );
        }

        $feed->( $cmd->stdin );
        $cmd->stdin->close;
    }

    my $stderr = do {
        local $/ = undef;
        readline( $cmd->stderr );
    };

    croak( 'error running ' . join( q{ }, @cmd ) . ': ' . $stderr )
      if length $stderr;

    my $output = defined( $qh_opts->output )
      ? do {
        $cmd->close;
        require File::Slurper;
        File::Slurper::read_binary( $qh_opts->output );
      }
      : do {
        local $/ = undef;
        readline( $cmd->stdout );
      };

    return $output if $raw;

    my @output = parse_output(
        { trace => $trace },
        $output, map { $_->[1]{name} } $qh_opts->by_category->{ +CAT_OUTPUT_FORMAT }{by_position}->@*,
    );

    return @output;
}

1;

#
# This file is part of Qhull
#
# This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory passthrough qhull

=head1 NAME

Qhull::PP - Pure Perl interface to Qhull

=head1 VERSION

version 0.06

=head1 SYNOPSIS

   use Qhull 'qhull';

   # generate a convex hull and return the ordered
   # indices of the points in the convex hull
   my \@indices = qhull( $x, $y );

=head1 DESCRIPTION

This is a pure-Perl interface to B<qhull>.  It passes input to the
B<qhull> executable and parses and returns the results.

=head1 SUBROUTINES

=head2 qhull

   @results = qhull( @coords, ?\%options );

Make B<qhull> do something.  If no options are specified, the default
is to generate a convex hull and return a list of the ordered indices
of the points on the convex hull.

The following options are available:

=over

=item *

raw => I<Boolean>

Don't parse the output; return it as a single string;

=item *

passthrough => I<array of Qhull options>

=item *

trace   => I<Boolean>

Add line number info to parsed output.

=item *

qh_opts   => I<array of Qhull options> or a L<Qhull::Options> object.

It's expensive to parse the options, so for repeat calls, pass in a L<Qhull::Options> object.

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-qhull@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Qhull>

=head2 Source

Source is available at

  https://gitlab.com/djerius/p5-qhull

and may be cloned from

  https://gitlab.com/djerius/p5-qhull.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Qhull|Qhull>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
