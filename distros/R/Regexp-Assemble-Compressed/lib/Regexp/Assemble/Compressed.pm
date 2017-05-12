package Regexp::Assemble::Compressed;

use strict;
use warnings;
our $VERSION = '0.02';
use base qw(Regexp::Assemble);

# Note: maybe handle \U,\L more smartly
our $char = qr/
    (?:\\u|\\l|)                                 # \u, \l acts on one char or char group
    (?:
          \\Q.+?\\E                              # capture \Q..\E completely
        | \[:[^:]+:\]                            # posix char class
        | \\[UL].+?(?:\\E|\Z)                    # capture \U..\E and \L..\E completely
        | \\x(?:\{[\dA-Fa-f]+\}|[\dA-Fa-f]{1,2}) # \x.. or \x{...}
        | \\\d{1,3}                              # \000 - octal
        | \\N\{[^{]+\}                           # unicode char
        | \\[pP]\{[^{]+\}                        # unicode character class
        | \\c.                                   # control char \cX
        | \\.                                    # \t \n \s ...
        | .                                      # any char
     )
/xo;

sub as_string {
    my $self = shift;
    my $string = $self->SUPER::as_string;
    $string =~ s{(?<!\\)\[(\^|)((?:\[:[^:]+:\]|.)+?)(?<!\\)\]}{ "[" . $1 . _compress($2) . "]" }eg;
    return $string;
}

sub _compress {
    my $string = shift;
    my @characters = sort $string =~ m{ ( $char\-$char | $char ) }sgx;
    #warn "[ ".join('|', @characters)." ]";
    my @stack = ();
    my @skipped = ();
    my $last;
    for my $char (@characters) {
        if ( length($char) == 1 ) {
            my $num = ord $char;
            if (defined $last and $num - $last == 0) { next }
            if (defined $last and @skipped and $num >= ord $skipped[0] and $num <= ord $skipped[-1]) { next }
            if (defined $last and $num - $last == 1) {
                push @skipped, $char;
                $last = $num;
                next;
            }
            elsif (@skipped) {
                push @stack, @skipped < 2 ? @skipped : ('-', $skipped[-1]);
                @skipped = ();
            }
            push @stack, $char;
            $last = $num;
        }
        elsif (length $char == 3 and $char =~ /^([^\\])-([^\\])$/) {
            my ($beg,$end) = ($1,$2);
            my $num = ord $beg;
            my $enn = ord $end;
            if (defined $last and @skipped and $num + 1 >= ord $skipped[0] and $num <= ord $skipped[-1]) {
                if ($enn <= ord $skipped[-1]) { next }
                else {
                    my $next = $skipped[-1];
                    ++$next;
                    push @skipped, $next..$end;
                    $last = $enn;
                    next;
                }
            }
            if (defined $last and $num - $last == 1) {
                push @skipped, $beg..$end;
                $last = $enn;
                next;
            }
            elsif (@skipped) {
                push @stack, @skipped < 2 ? @skipped : ('-', $skipped[-1]);
                @skipped = ();
            }
            push @stack, $beg;
            push @skipped, ++$beg..$end;
            $last = $enn;
        }
        else {
            if (@skipped) {
                push @stack, @skipped < 2 ? @skipped : ('-', $skipped[-1]);
                @skipped = ();
            }
            push @stack, $char;
        }
    }
    if (@skipped) {
        push @stack, @skipped < 2 ? @skipped : ('-', $skipped[-1]);
    }
    return join '', @stack;
}

1;
__END__

=head1 NAME

Regexp::Assemble::Compressed - Assemble more compressed Regular Expression

=head1 SYNOPSIS

 use Regexp::Assemble::Compressed;
  
 my $ra = Regexp::Assemble::Compressed->new;
 my @cctlds = qw(ma mc md me mf mg mh mk ml mm mn mo mp
                 mq mr ms mt mu mv mw mx my mz);
 for my $tld ( @cctlds ) {
     $ra->add( $tld );
 }
 print $ra->re; # prints m[ac-hk-z].
                # Regexp::Assemble prints m[acdefghklmnopqrstuvwxyz]

=head1 DESCRIPTION

Regexp::Assemble::Compressed is a subclass of Regexp::Assemble.
It assembles more compressed regular expressions.

=head1 AUTHOR

Koichi Taniguchi E<lt>taniguchi@livedoor.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Regexp::Assemble>

=cut
