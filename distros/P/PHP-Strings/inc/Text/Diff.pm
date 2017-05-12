#line 1 "inc/Text/Diff.pm - /opt/perl/5.8.2/lib/site_perl/5.8.2/Text/Diff.pm"
package Text::Diff;

$VERSION = 0.35;

#line 49

use Exporter;
@ISA = qw( Exporter );
@EXPORT = qw( diff );

use strict;
use Carp;
use Algorithm::Diff qw( traverse_sequences );

## Hunks are made of ops.  An op is the starting index for each
## sequence and the opcode:
use constant A       => 0;   # Array index before match/discard
use constant B       => 1;
use constant OPCODE  => 2;   # "-", " ", "+"
use constant FLAG    => 3;   # What to display if not OPCODE "!"


#line 146

my %internal_styles = (
    Unified  => undef,
    Context  => undef,
    OldStyle => undef,
    Table    => undef,   ## "internal", but in another module
);

sub diff {
    my @seqs = ( shift, shift );
    my $options = shift || {};

    for my $i ( 0..1 ) {
        my $seq = $seqs[$i];
	my $type = ref $seq;

        while ( $type eq "CODE" ) {
	    $seqs[$i] = $seq = $seq->( $options );
	    $type = ref $seq;
	}

	my $AorB = !$i ? "A" : "B";

        if ( $type eq "ARRAY" ) {
            ## This is most efficient :)
            $options->{"OFFSET_$AorB"} = 0
                unless defined $options->{"OFFSET_$AorB"};
        }
        elsif ( $type eq "SCALAR" ) {
            $seqs[$i] = [split( /^/m, $$seq )];
            $options->{"OFFSET_$AorB"} = 1
                unless defined $options->{"OFFSET_$AorB"};
        }
        elsif ( ! $type ) {
            $options->{"OFFSET_$AorB"} = 1
                unless defined $options->{"OFFSET_$AorB"};
	    $options->{"FILENAME_$AorB"} = $seq
	        unless defined $options->{"FILENAME_$AorB"};
	    $options->{"MTIME_$AorB"} = (stat($seq))[9]
	        unless defined $options->{"MTIME_$AorB"};

            local $/ = "\n";
            open F, "<$seq" or carp "$!: $seq";
            $seqs[$i] = [<F>];
            close F;

        }
        elsif ( $type eq "GLOB" || UNIVERSAL::isa( $seq, "IO::Handle" ) ) {
            $options->{"OFFSET_$AorB"} = 1
                unless defined $options->{"OFFSET_$AorB"};
            local $/ = "\n";
            $seqs[$i] = [<$seq>];
        }
        else {
            confess "Can't handle input of type ", ref;
        }
    }

    ## Config vars
    my $output;
    my $output_handler = $options->{OUTPUT};
    my $type = ref $output_handler ;
    if ( ! defined $output_handler ) {
        $output = "";
        $output_handler = sub { $output .= shift };
    }
    elsif ( $type eq "CODE" ) {
        ## No problems, mate.
    }
    elsif ( $type eq "SCALAR" ) {
        my $out_ref = $output_handler;
        $output_handler = sub { $$out_ref .= shift };
    }
    elsif ( $type eq "ARRAY" ) {
        my $out_ref = $output_handler;
        $output_handler = sub { push @$out_ref, shift };
    }
    elsif ( $type eq "GLOB" || UNIVERSAL::isa $output_handler, "IO::Handle" ) {
        my $output_handle = $output_handler;
        $output_handler = sub { print $output_handle shift };
    }
    else {
        croak "Unrecognized output type: $type";
    }

    my $style  = $options->{STYLE};
    $style = "Unified" unless defined $options->{STYLE};
    $style = "Text::Diff::$style" if exists $internal_styles{$style};

    if ( ! $style->can( "hunk" ) ) {
	eval "require $style; 1" or die $@;
    }

    $style = $style->new
	if ! ref $style && $style->can( "new" );

    my $ctx_lines = $options->{CONTEXT};
    $ctx_lines = 3 unless defined $ctx_lines;
    $ctx_lines = 0 if $style->isa( "Text::Diff::OldStyle" );

    my @keygen_args = $options->{KEYGEN_ARGS}
        ? @{$options->{KEYGEN_ARGS}}
        : ();

    ## State vars
    my $diffs = 0; ## Number of discards this hunk
    my $ctx   = 0; ## Number of " " (ctx_lines) ops pushed after last diff.
    my @ops;       ## ops (" ", +, -) in this hunk
    my $hunks = 0; ## Number of hunks

    my $emit_ops = sub {
        $output_handler->( $style->file_header( @seqs,     $options ) )
	    unless $hunks++;
        $output_handler->( $style->hunk_header( @seqs, @_, $options ) );
        $output_handler->( $style->hunk       ( @seqs, @_, $options ) );
        $output_handler->( $style->hunk_footer( @seqs, @_, $options ) );
    };

    ## We keep 2*ctx_lines so that if a diff occurs
    ## at 2*ctx_lines we continue to grow the hunk instead
    ## of emitting diffs and context as we go. We
    ## need to know the total length of both of the two
    ## subsequences so the line count can be printed in the
    ## header.
    my $dis_a = sub {push @ops, [@_[0,1],"-"]; ++$diffs ; $ctx = 0 };
    my $dis_b = sub {push @ops, [@_[0,1],"+"]; ++$diffs ; $ctx = 0 };

    traverse_sequences(
        @seqs,
        {
            MATCH => sub {
                push @ops, [@_[0,1]," "];

                if ( $diffs && ++$ctx > $ctx_lines * 2 ) {
        	   $emit_ops->( [ splice @ops, 0, $#ops - $ctx_lines ] );
        	   $ctx = $diffs = 0;
                }

                ## throw away context lines that aren't needed any more
                shift @ops if ! $diffs && @ops > $ctx_lines;
            },
            DISCARD_A => $dis_a,
            DISCARD_B => $dis_b,
        },
        $options->{KEYGEN},  # pass in user arguments for key gen function
        @keygen_args,
    );

    if ( $diffs ) {
        $#ops -= $ctx - $ctx_lines if $ctx > $ctx_lines;
        $emit_ops->( \@ops );
    }

    $output_handler->( $style->file_footer( @seqs, $options ) ) if $hunks;

    return defined $output ? $output : $hunks;
}


sub _header {
    my ( $h ) = @_;
    my ( $p1, $fn1, $t1, $p2, $fn2, $t2 ) = @{$h}{
        "FILENAME_PREFIX_A",
        "FILENAME_A",
        "MTIME_A",
        "FILENAME_PREFIX_B",
        "FILENAME_B",
        "MTIME_B"
    };

    ## remember to change Text::Diff::Table if this logic is tweaked.
    return "" unless defined $fn1 && defined $fn2;

    return join( "",
        $p1, " ", $fn1, defined $t1 ? "\t" . localtime $t1 : (), "\n",
        $p2, " ", $fn2, defined $t2 ? "\t" . localtime $t2 : (), "\n",
    );
}

## _range encapsulates the building of, well, ranges.  Turns out there are
## a few nuances.
sub _range {
    my ( $ops, $a_or_b, $format ) = @_;

    my $start = $ops->[ 0]->[$a_or_b];
    my $after = $ops->[-1]->[$a_or_b];

    ## The sequence indexes in the lines are from *before* the OPCODE is
    ## executed, so we bump the last index up unless the OP indicates
    ## it didn't change.
    ++$after
        unless $ops->[-1]->[OPCODE] eq ( $a_or_b == A ? "+" : "-" );

    ## convert from 0..n index to 1..(n+1) line number.  The unless modifier
    ## handles diffs with no context, where only one file is affected.  In this
    ## case $start == $after indicates an empty range, and the $start must
    ## not be incremented.
    my $empty_range = $start == $after;
    ++$start unless $empty_range;

    return
        $start == $after
            ? $format eq "unified" && $empty_range
                ? "$start,0"
                : $start
            : $format eq "unified"
                ? "$start,".($after-$start+1)
                : "$start,$after";
}


sub _op_to_line {
    my ( $seqs, $op, $a_or_b, $op_prefixes ) = @_;

    my $opcode = $op->[OPCODE];
    return () unless defined $op_prefixes->{$opcode};

    my $op_sym = defined $op->[FLAG] ? $op->[FLAG] : $opcode;
    $op_sym = $op_prefixes->{$op_sym};
    return () unless defined $op_sym;

    $a_or_b = $op->[OPCODE] ne "+" ? 0 : 1 unless defined $a_or_b;
    return ( $op_sym, $seqs->[$a_or_b][$op->[$a_or_b]] );
}


#line 397

{
    package Text::Diff::Base;
    sub new         {
        my $proto = shift;
	return bless { @_ }, ref $proto || $proto;
    }

    sub file_header { return "" }
    sub hunk_header { return "" }
    sub hunk        { return "" }
    sub hunk_footer { return "" }
    sub file_footer { return "" }
}


#line 456

@Text::Diff::Unified::ISA = qw( Text::Diff::Base );

sub Text::Diff::Unified::file_header {
    shift; ## No instance data
    my $options = pop ;

    _header(
        { FILENAME_PREFIX_A => "---", FILENAME_PREFIX_B => "+++", %$options }
    );
}

#line 475

sub Text::Diff::Unified::hunk_header {
    shift; ## No instance data
    pop; ## Ignore options
    my $ops = pop;

    return join( "",
        "@@ -",
        _range( $ops, A, "unified" ),
        " +",
        _range( $ops, B, "unified" ),
        " @@\n",
    );
}


#line 498

sub Text::Diff::Unified::hunk {
    shift; ## No instance data
    pop; ## Ignore options
    my $ops = pop;

    my $prefixes = { "+" => "+", " " => " ", "-" => "-" };

    return join "", map _op_to_line( \@_, $_, undef, $prefixes ), @$ops
}


#line 587


@Text::Diff::Context::ISA = qw( Text::Diff::Base );

sub Text::Diff::Context::file_header {
    _header { FILENAME_PREFIX_A=>"***", FILENAME_PREFIX_B=>"---", %{$_[-1]} };
}


sub Text::Diff::Context::hunk_header {
    return "***************\n";
}

sub Text::Diff::Context::hunk {
    shift; ## No instance data
    pop; ## Ignore options
    my $ops = pop;
    ## Leave the sequences in @_[0,1]

    my $a_range = _range( $ops, A, "" );
    my $b_range = _range( $ops, B, "" );

    ## Sigh.  Gotta make sure that differences that aren't adds/deletions
    ## get prefixed with "!", and that the old opcodes are removed.
    my $after;
    for ( my $start = 0; $start <= $#$ops ; $start = $after ) {
        ## Scan until next difference
        $after = $start + 1;
        my $opcode = $ops->[$start]->[OPCODE];
        next if $opcode eq " ";

        my $bang_it;
        while ( $after <= $#$ops && $ops->[$after]->[OPCODE] ne " " ) {
            $bang_it ||= $ops->[$after]->[OPCODE] ne $opcode;
            ++$after;
        }

        if ( $bang_it ) {
            for my $i ( $start..($after-1) ) {
                $ops->[$i]->[FLAG] = "!";
            }
        }
    }

    my $b_prefixes = { "+" => "+ ",  " " => "  ", "-" => undef, "!" => "! " };
    my $a_prefixes = { "+" => undef, " " => "  ", "-" => "- ",  "!" => "! " };

    return join( "",
        "*** ", $a_range, " ****\n",
        map( _op_to_line( \@_, $_, A, $a_prefixes ), @$ops ),
        "--- ", $b_range, " ----\n",
        map( _op_to_line( \@_, $_, B, $b_prefixes ), @$ops ),
    );
}
#line 655

@Text::Diff::OldStyle::ISA = qw( Text::Diff::Base );

sub _op {
    my $ops = shift;
    my $op = $ops->[0]->[OPCODE];
    $op = "c" if grep $_->[OPCODE] ne $op, @$ops;
    $op = "a" if $op eq "+";
    $op = "d" if $op eq "-";
    return $op;
}

sub Text::Diff::OldStyle::hunk_header {
    shift; ## No instance data
    pop; ## ignore options
    my $ops = pop;

    my $op = _op $ops;

    return join "", _range( $ops, A, "" ), $op, _range( $ops, B, "" ), "\n";
}

sub Text::Diff::OldStyle::hunk {
    shift; ## No instance data
    pop; ## ignore options
    my $ops = pop;
    ## Leave the sequences in @_[0,1]

    my $a_prefixes = { "+" => undef,  " " => undef, "-" => "< "  };
    my $b_prefixes = { "+" => "> ",   " " => undef, "-" => undef };

    my $op = _op $ops;

    return join( "",
        map( _op_to_line( \@_, $_, A, $a_prefixes ), @$ops ),
        $op eq "c" ? "---\n" : (),
        map( _op_to_line( \@_, $_, B, $b_prefixes ), @$ops ),
    );
}

#line 724

1;
