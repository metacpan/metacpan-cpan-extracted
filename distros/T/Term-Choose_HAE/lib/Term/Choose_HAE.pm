package Term::Choose_HAE;

use warnings;
use strict;
use 5.010001;

our $VERSION = '0.057';
use Exporter 'import';
our @EXPORT_OK = qw( choose );

use Parse::ANSIColor::Tiny qw();
use Term::ANSIColor        qw( colored );
use Text::ANSI::WideUtil   qw( ta_mbtrunc );

use if $^O eq 'MSWin32', 'Win32::Console::ANSI';

use Term::Choose::Constants qw( :choose :screen :linux );
use Term::Choose::LineFold qw( print_columns );

use parent 'Term::Choose';



sub __valid_options {
    my $valid = Term::Choose::__valid_options();
    $valid->{fill_up} = '[ 0 1 2 ]';
    return $valid;
};


sub __defaults {
    my ( $self ) = @_;
    my $defaults = Term::Choose::__defaults();
    $defaults->{fill_up} = 1;
    return $defaults;
}


sub choose {
    if ( ref $_[0] ne 'Term::Choose_HAE' ) {
        return Term::Choose_HAE->new()->Term::Choose::__choose( @_ );
    }
    my $self = shift;
    return $self->Term::Choose::__choose( @_ );
}


sub __copy_orig_list {
    my ( $self, $orig_list ) = @_;
    $self->{list} = [ @$orig_list ];
    if ( $self->{ll} ) {
        for ( @{$self->{list}} ) {
            $_ = $self->{undef} if ! defined $_;
        }
    }
    else {
        for ( @{$self->{list}} ) {
            if ( ! $_ ) {
                $_ = $self->{undef} if ! defined $_;
                $_ = $self->{empty} if $_ eq '';
            }
            if ( ref ) {
                $_ = sprintf "%s(0x%x)", ref $_, $_;
            }
            s/\t/ /g;
            s/[\x{000a}-\x{000d}\x{0085}\x{2028}\x{2029}]+/\ \ /g; # \v 5.10
            s/[\p{Cc}\p{Noncharacter_Code_Point}\p{Cs}]/$&=~m|\e| && $&/eg; # remove \p{Cc} but keep \e\[
        }
    }
}


sub __length_longest {
    my ( $self ) = @_;
    my $list = $self->{list};
    if ( $self->{ll} ) {
        $self->{length_longest} = $self->{ll};
        $self->{length} = [ ( $self->{length_longest} ) x @$list ];
    }
    else {
        my $len = [];
        my $longest = 0;
        for my $i ( 0 .. $#$list ) {
            $len->[$i] = print_columns( _strip_ansi_color( $list->[$i] ) );
            $longest = $len->[$i] if $len->[$i] > $longest;
        }
        $self->{length_longest} = $longest;
        $self->{length} = $len;
    }
}


sub _strip_ansi_color {
    ( my $str = $_[0] ) =~ s/\e\[[\d;]*m//msg;
    return $str;
}


sub __unicode_sprintf {
    my ( $self, $idx, $is_current_pos, $is_marked ) = @_;
    my $unicode = '';
    my $str_length = $self->{length}[$idx];
    if ( $str_length > $self->{avail_col_width} ) {
        if ( $self->{avail_col_width} > 3 ) {
            $unicode = ta_mbtrunc( $self->{list}[$idx], $self->{avail_col_width} - 3 ) . '...';
        }
        else {
            $unicode = ta_mbtrunc( $self->{list}[$idx], $self->{avail_col_width} );
        }
    }
    elsif ( $str_length < $self->{avail_col_width} ) {
        if ( $self->{justify} == 0 ) {
            $unicode = $self->{list}[$idx] . " " x ( $self->{avail_col_width} - $str_length );
        }
        elsif ( $self->{justify} == 1 ) {
            $unicode = " " x ( $self->{avail_col_width} - $str_length ) . $self->{list}[$idx];
        }
        elsif ( $self->{justify} == 2 ) {
            my $all = $self->{avail_col_width} - $str_length;
            my $half = int( $all / 2 );
            $unicode = " " x $half . $self->{list}[$idx] . " " x ( $all - $half );
        }
    }
    else {
        $unicode = $self->{list}[$idx];
    }

    my $wrap = '';
    open my $trapstdout, '>', \$wrap or die "can't open TRAPSTDOUT: $!";
    select $trapstdout;
    print BOLD_UNDERLINE if $is_marked;
    print REVERSE        if $is_current_pos;
    select STDOUT;
    close $trapstdout;
    my $ansi   = Parse::ANSIColor::Tiny->new();
    my @codes  = ( $wrap =~ /\e\[([\d;]*)m/g );
    my @attr   = $ansi->identify( @codes ? @codes : '' );
    my $marked = $ansi->parse( $unicode );
    if ( $self->{length}[$idx] > $self->{avail_width} && $self->{fill_up} != 2 ) {
        if ( @$marked > 1 && ! @{$marked->[-1][0]} && $marked->[-1][1] =~ /^\.\.\.\z/ ) {
            $marked->[-1][0] = $marked->[-2][0];
        }
    }
    if ( $attr[0] ne 'clear' ) {
        if ( $self->{fill_up} == 1 && @$marked > 1 ) {
            if ( ! @{$marked->[0][0]} && $marked->[0][1] =~ /^\s+\z/ ) {
                $marked->[0][0] = $marked->[1][0];
            }
            if ( ! @{$marked->[-1][0]}&& $marked->[-1][1] =~ /^\s+\z/ ) {
                $marked->[-1][0] = $marked->[-2][0];
            }
        }
        if ( ! $self->{fill_up} ) {
            if ( ! @{$marked->[0][0]} && $marked->[0][1] =~ /^(\s+)\S/ ) {
                my $tmp = $1;
                $marked->[0][1] =~ s/^\s+//;
                unshift @$marked, [ [], $tmp ];
            }
            elsif ( ! @{$marked->[-1][0]} && $marked->[-1][1] =~ /\S(\s+)\z/ ) {
                my $tmp = $1;
                $marked->[-1][1] =~ s/\s+\z//;
                push @$marked, [ [], $tmp ];
            }
        }
        for my $i ( 0 .. $#$marked ) {
            if ( ! $self->{fill_up} ) {
                if ( $i == 0 || $i == $#$marked ) {
                    if ( ! @{$marked->[$i][0]} && $marked->[$i][1] =~ /^\s+\z/ ) {
                        next;
                    }
                }
            }
            $marked->[$i][0] = [ $ansi->normalize( @{ $marked->[$i][0] }, @attr ) ];
        }
    }
    print join '', map { @{$_->[0]} ? colored( @$_ ) : $_->[1] } @$marked;
    if ( $is_marked || $is_current_pos ) {
        print RESET;
    }
}




1;


__END__

=pod

=encoding UTF-8

=head1 NAME

Term::Choose_HAE - Choose items from a list interactively.

=head1 VERSION

Version 0.057

=cut

=head1 SYNOPSIS

Functional interface:

    use Term::Choose_HAE qw( choose );
    use Term::ANSIColor;

    my $array_ref = [
        colored( 'red_string', 'red'),
        colored( 'green_string', 'green'),
        colored( 'blue_string', 'cyan'),
    ];

    my $choice = choose( $array_ref );                            # single choice
    print "$choice\n";

    my @choices = choose( [ 1 .. 100 ], { justify => 1 } );       # multiple choice
    print "@choices\n";

    choose( [ 'Press ENTER to continue' ], { prompt => '' } );    # no choice

Object-oriented interface:

    use Term::Choose_HAE;
    use Term::ANSIColor;

    my $array_ref = [
        colored( 'red_string', 'red'),
        colored( 'green_string', 'green'),
        colored( 'blue_string', 'cyan'),
    ];

    my $new = Term::Choose_HAE->new();

    my $choice = $new->choose( $array_ref );                       # single choice
    print "$choice\n";

    my @choices = $new->choose( [ 1 .. 100 ] );                    # multiple choice
    print "@choices\n";

    my $stopp = Term::Choose_HAE->new( { prompt => '' } );
    $stopp->choose( [ 'Press ENTER to continue' ] );               # no choice

=head1 DESCRIPTION

Choose interactively from a list of items.

C<Term::Choose_HAE> works like C<Term::Choose> except that C<choose> from C<Term::Choose_HAE> does not disable ANSI
escape sequences; so with C<Term::Choose_HAE> it is possible to output colored text. On a MSWin32 OS
L<Win32::Console::ANSI> is used to translate the ANSI escape sequences. C<Term::Choose_HAE> provides one additional
option: I<fill_up>.

Else see L<Term::Choose> for usage and options.

=head2 Occupied escape sequences

C<choose> uses the "inverse" escape sequence to mark the cursor position and the "underline" and "bold" escape sequences
to mark the selected items in list context.

=head1 OPTIONS

C<Term::Choose_HAE> inherits the options from L<Term::Choose|Term::Choose/OPTIONS> (except the option I<ll>) and adds
the option I<fill_up>:

=head2 fill_up

0 - off

1 - fill up selected items with the adjacent color. (default)

2 - fill up selected items with the default color.

If I<fill_up> is enabled, the highlighting of the cursor position and in list context the highlighting of the selected
items has always the width of the column.

=over

=item

I<fill_up> set to C<1>: the color of the highlighting of leading and trailings spaces is set to the color of
the highlighting of the adjacent non-space character of the item if these spaces are not embedded in escape sequences.

=item

I<fill_up> set to C<2>: leading and trailings spaces are highlighted with the default color for highlighting if
these spaces are not embedded in escape sequences.

=back

If I<fill_up> is disabled, leading and trailing spaces are not highlighted if they are not embedded in escape sequences.

=head1 REQUIREMENTS

The requirements are the same as with C<Term::Choose> except that the minimum Perl version for C<Term::Choose_HAE> is
5.10.1 instead of 5.8.3.

=head2 Perl version

Requires Perl version 5.10.1 or greater.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Term::Choose_HAE

=head1 AUTHOR

Matthäus Kiem <cuer2s@gmail.com>

=head1 CREDITS

Based on a patch for C<Term::Choose> from Stephan Sachse.

Thanks to the L<Perl-Community.de|http://www.perl-community.de> and the people form
L<stackoverflow|http://stackoverflow.com> for the help.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015-2018 Matthäus Kiem.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For
details, see the full text of the licenses in the file LICENSE.

=cut
