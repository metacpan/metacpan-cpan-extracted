
package App::HI;

use strict;
use Text::Table;
use Term::Size;

our $VERSION = '2.7191';

sub top_matter {
    my $no_extra = shift;
    my @to_import = qw(color colored colorvalid);

    if( $no_extra ) {
        eval qq/ use Term::ANSIColor qw(@to_import); 1 /
        or die $@;

    } else {
        eval qq/ use Term::ANSIColorx::ColorNicknames qw(@to_import); 1 /
        or die $@;
    }

    eval q { use Term::ANSIColorx::AutoFilterFH qw(filtered_handle); 1 }
    or die $@;
}

sub fire_filter {
    my $class = shift;
    my %o = @_;

    top_matter( $o{nixnics} );

    my $newstdout = filtered_handle(\*STDOUT, @ARGV);
    $| = 1; my $oldstdout = select $newstdout; $|=1;
    $newstdout->set_truncate($o{trunc}) if $o{trunc};

    binmode $newstdout, ':utf8';
    binmode STDIN,      ':utf8';

    while(<STDIN>) {
        print
    }
}

sub sort_colors {
    my %yet_seen;

    map {$_->{cn}}

    sort {
        $a->{bg} <=> $b->{bg} ||
        $a->{at} <=> $b->{at} ||
        $a->{fg} <=> $b->{fg}
    }

    map {
        my $res = { cn => $_ };
        my @v = map { $_ >= 90 && $_ <= 107 ? $_-60 : $_ } ( color($_) =~ m/(\d+)/g );

        $res->{at} = grep {$_ <= 8}              @v;
        $res->{fg} = grep {$_ >= 30 && $_ <= 37} @v;
        $res->{bg} = grep {$_ >= 40 && $_ <= 47} @v;

        $res->{at} =  0 unless $res->{at};
        $res->{fg} = 30 unless $res->{fg};
        $res->{bg} = 40 unless $res->{bg};

        $res;
    }

    grep {
        my $valid = colorvalid($_);
        warn "$_ isn't valid" unless $valid;

        $valid
    }

    grep {
        !$yet_seen{$_}++
    }

    @_
}

sub list_colors {
    my $class = shift;
    my %o = @_;

    top_matter( $o{nixnics} => qw(color colorvalid) );

    my $table;

    my @colors = sort_colors(
        map("bold $_",   qw( black red green yellow blue magenta cyan white )),
                         qw( black red green yellow blue magenta cyan white ),

        "white on_black", "white on_red", "blue on_green", "black on_yellow",
        "white on_blue", "white on_magenta", "black on_cyan", "black on_white",

        "pitch on white",

        keys %Term::ANSIColorx::ColorNicknames::NICKNAMES,
    );

    my ($columns, $rows) = Term::Size::chars *STDOUT;

    $columns --;

    my $m = 20;
    UGH_SO_BAD: {
        # XXX: this is so in-efficient it makes my soul hurt
        $table = Text::Table->new;

        my @row;
        for(@colors) {
            push @row, $_;

            unless( @row % $m ) {
                $table->add(map {$_ ? colored($_, $_) : $_} @row);
                @row = ();
            }
        }

        $table->add(map {$_ ? colored($_, $_) : $_} @row);

        $m -= 2;
        redo UGH_SO_BAD if $table->width > $columns;
    }

    print $table;
}

__END__

=head1 NAME

App::HI - highlight things in a stream of output

=head1 SYNOPSIS

This is just a placeholder for the command line app hi(1).

=head1 SEE ALSO

perl(1), hi(1), L<Term::ANSIColor>, L<Term::ANSIColorx::AutoFilterFH>, L<Term::ANSIColorx::ColorNicknames>
