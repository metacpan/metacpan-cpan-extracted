package Regexp::Subst::Parallel;

use Exporter;
use Carp;

our @ISA = qw/Exporter/;
our @EXPORT = qw/subst/;

our $VERSION = 0.11;

sub subst
{
    my $str = shift;
    my $pos = 0;
    my @subs;
    while (@_) {
        push @subs, [ shift, shift ];
    }
    my $res;
    
    while ($pos < length $str) {
        my (@bplus, @bminus, $best);
        for my $rref (@subs) {
            pos $str = $pos;
            if ($str =~ /\G$rref->[0]/) {
                if ($+[0] > $bplus[0]) {
                    @bplus = @+;
                    @bminus = @-;
                    $best = $rref;
                }
            }
        }
        if (@bminus) {
            my $temp = $best->[1];
            if (ref $temp eq 'CODE') {
                $res .= $temp->(map { substr $str, $bminus[$_], $bplus[$_]-$bminus[$_] } 0..$#bminus);
            }
            elsif (not ref $temp) {
                # I can't help using it even before I'm done writing it!
                $temp = subst($temp, 
                              qr/\\\\/        => sub { '\\' },
                              qr/\\\$/        => sub { '$' },
                              qr/\$(\d+)/     => sub { substr $str, $bminus[$_[1]], $bplus[$_[1]]-$bminus[$_[1]] },
                              qr/\$\{(\d+)\}/ => sub { substr $str, $bminus[$_[1]], $bplus[$_[1]]-$bminus[$_[1]] },
                        );
                $res .= $temp;
            }
            else {
                croak 'Replacements must be strings or coderefs, not ' . 
                    ref($temp) . ' refs';
            }
            $pos = $bplus[0];
        }
        else {
            $res .= substr $str, $pos, 1;
            $pos++;
        }
    }
    return $res;
}

=head1 NAME

Regexp::Subst::Parallel - Safely perform multiple substitutions on a string
in parallel.
    
=head1 VERSION

Regexp::Subst::Parallel version 0.11, Feb 9, 2003.

=head1 SYNOPSIS

    # Rephrase $str into the form of a question.
    my $qstr = subst($str,
                   qr/I|me/  => 'you',
                   qr/my/    => 'your',
                   qr/mine/  => 'yours',
                   qr/you/   => 'me',
                   qr/your/  => 'my',
                   qr/yours/ => 'mine',
                   ...);
    
    # Apply implicit html highlighting
    my $html = subst($text,
                   qr/\{(.*?)\}/ => '$1',  # Protect things in braces
                   qr/_(\w+)_/   => '<u>$1</u>',
                   qr/<(\w+)>/   => '<i>$1</i>',
               );

    # Toggle the case of every character
    my $vAR = subst($Var,
                  qr/([a-z]+)/ => sub { uc $_[1] },
                  qr/([A-Z]+)/ => sub { lc $_[1] },
              );

=head1 DESCRIPTION

C<Regexp::Subst::Parallel> is a module that allows you to make
multiple simultaneous substitutions safely.  Using the sole exported
C<subst> function has a rather different effect from doing each
substitution sequentially.  For example:

    $text = '{process_the_data} was _called_ without <data>!';
    $text =~ s/\{(.*?)\}/$1/g;
    # $text eq 'process_the_data was _called_ without <data>!'
    $text =~ s/_(\w+)_/<u>$1</u>/g;
    # $text eq 'process<u>the</u>data was <u>called</u> without <data>!'
    $text =~ s/<(\w+)>/<i>$1</i>/g;
    # $text eq 'process<i>u</i>the</u>data was <i>u</i>called</u> without <i>data</i>!'

Which is clearly the wrong result.  On the other hand,
C<Regexp::Subst::Parallel> does them all in parallel, so:

    $text = '{process_the_data} was _called_ without <data>!';
    $text = subst($text,
                qr/\{(.*?)\}/ => '$1',  # Protect things in braces
                qr/_(\w+)_/   => '<u>$1</u>',
                qr/<(\w+)>/   => '<i>$1</i>',
            );
    # $text eq 'process_the_data was <u>called</u> without <i>data</i>'

Which seems to be right.

The algorithm moves from left to right, and the longest match is
substituted in case of conflict.  The substitution side of the pairs
can either be a string, in which non-backslashed $n's are substituted,
or a coderef, in which the sub is called and passed the list of
captures in @_.  $_[0] is analogous to $& : it refers to the entire
match.

=head2 Gotchas

Make sure when you're using the string method to have the $'s included
in the string.  That means if you're using an interpolating quote ("",
qq{}, etc.)  that you backslash $1, $2, etc.  Otherwise you will get
the $n's from the current lexical scope, which is not what you want.

=head2 Caveats

To include a single backslash followed by an interpolated capture,
C<subst> needs to see '\\$1', which means that you have to type
'\\\\$1' when you just want I<a single backslash>.  That's sick.

=head1 AUTHORS

Luke Palmer <fibonaci@babylonia.flatirons.org>

=head1 COPYRIGHT

Copyright (C) 2003 Luke Palmer.  This module is distributed under the
same terms as Perl itself.

    http://www.perl.com/perl/misc/Artistic.html
