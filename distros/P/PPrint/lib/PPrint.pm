package PPrint;
require 5.005_62;
use strict;
use warnings;
use Carp;
use Data::Dumper; # need this for the A directive

BEGIN {
    use Exporter ();
    our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    our $VERSION = "0.1";
    @ISA         = qw( Exporter );
    @EXPORT      = qw( &pprint );
    %EXPORT_TAGS = qw( );
    @EXPORT_OK   = qw( );
}

sub tilde {
    my @params = @{ $_[0] };
    my $repeat = $params[0] || 1;
    return sub { '~' x $repeat };
}

sub R {
    my ($params, $flags) = @_;
    my $radix         = $params->[0] || 10;
    carp "Nonsense radix: $radix" if $radix < 1;
    my $mincol        = $params->[1] || 0;
    carp "Invalid minimum numbers of columns: $mincol" if $mincol < 0;
    my $padchar       = defined $params->[2] ? $params->[2] : " ";
    my $commachar     = $params->[3] || ',';
    my $commainterval = $params->[4] || 3;

    return sub {
        my @args = @{ $_[0] };
        my $num = shift @args;
        my $str = toStringRadix(abs $num, $radix);
        if ($flags->{":"}) {
            # add in commas
            $str = reverse join $commachar, grep { defined $_ && $_ ne '' } split /(.{$commainterval})/, reverse $str;
        }
        $str = "-" . $str if $num < 0;
        $str = "+" . $str if ($num > 0) && (defined($flags->{";"}));
        if (length($str) < $mincol) {
            my $padding = $padchar x ($mincol - length($str));
            if ($flags->{"!"}) {
                $str = $str . $padding;
            } else {
                $str = $padding . $str;
            }
        }
        return $str;
    }
}

sub D {
    my ($params, $flags) = @_;
    unshift @{ $params }, 10;
    return R(@_);
}

sub O {
    my ($params, $flags) = @_;
    unshift @{ $params }, 8;
    return R(@_);
}

sub X {
    my ($params, $flags) = @_;
    unshift @{ $params }, 16;
    return R(@_);
}

sub B {
    my ($params, $flags) = @_;
    unshift @{ $params }, 2;
    return R(@_);
}

sub S {
    my ($params, $flags) = @_;
    return sub { sprintf("\%s", shift @{ $_[0] } ); };
}

sub A {
    my ($params, $flags) = @_;
    my ($indent_style, $purity, $useqq, $terse, $deepcopy,
        $quotekeys, $max_depth) = @{ $params };
    $indent_style = 2 unless defined $indent_style;
    $purity ||= 0;
    $useqq ||= 0;
    $terse ||= 0;
    $deepcopy ||= 0;
    $quotekeys ||= 0;
    $max_depth ||= 0;

    my $dumper = Data::Dumper->new([])
      ->Indent($indent_style)
      ->Purity($purity)
      ->Useqq($useqq)
      ->Terse($terse)
      ->Deepcopy($deepcopy)
      ->Quotekeys($quotekeys)
      ->Maxdepth($max_depth);

    return sub {
        $dumper->Values([ shift @{ $_[0] } ]);
        $dumper->Dump;
    }
}

sub n {
    my ($params, $flags) = @_;
    my $repeats = $params->[0] || 1;
    my $type = $params->[1];
    my $new_line = "\n";
    if ($type) {
        if ($type eq 'm') {
            $new_line = chr(0x0D);
        } elsif ($type eq 'u') {
            $new_line = chr(0x0A);
        } elsif ($type eq 'd') {
            $new_line = chr(0x0D) . chr(0x0A);
        }
    }
    return sub { "$new_line" x $repeats; };
}

sub J {
    my ($params, $flags) = @_;
    my ($join_char, $pre_char, $post_char) = @{ $params };
    $join_char = ' ' unless defined $join_char;
    $pre_char = '' unless defined $pre_char;
    $post_char = '' unless defined $post_char;
    return sub {
        my @to_join = @{ shift @{ $_[0] } };
        return $pre_char . join($join_char, @to_join) . $post_char;
    }
}

######################################################################
# utilities

# take a positive integer, return it's string representation in radix n
sub toStringRadix {
    my ($num, $radix) = @_;
    if ($radix == 0) {
        carp "0 is a sensless value for a radix, what are you thinking?";
        return;
    }
    if ($radix < 0) {
        carp "what am i supposed to do with a negative radix?";
        return;
    }
    my @alphabet = ( "0" .. "9", "a" .. "z" );
    my $string = "";
    while ($num != 0) {
        my $rem = $num % $radix;
        $num = int($num/$radix);
        $string = $alphabet[$rem] . $string;
    }
    return $string;
}

######################################################################
# directive table

my %standard_directives = ( 'n' => \&n,
                            '~' => \&tilde,
                            'r' => \&R,
                            'd' => \&D,
                            'o' => \&O,
                            'x' => \&X,
                            'b' => \&B,
                            'a' => \&A,
                            'j' => \&J,
                          );

our %directives = %standard_directives;

#####################################################################
# do it!

my $flags_class = "[:!@|?;]";

# build_directive takes a dirctive string as an arg and returns a sub
# which takes the argument list as an arg
sub build_directive {
    my $directive_string = shift;
    # the type of directive is the last char in the string
    my $directive_type = substr ($directive_string, -1);
    # remove leading '~' and last char (directive type)
    $directive_string = substr ($directive_string, 1);
    $directive_string = substr ($directive_string, 0, -1);
    my %flags;
    if ($directive_string =~ s/((?<!')($flags_class+))$//) {
        %flags = map { $_ => 1 } split //, $2;
    }
    my @params = map { s/^'//; $_ }
      split /(?<!'),/, $directive_string;
    if (grep { $_ eq "v" } @params) {
        # v arg, we have to build the directive function at ever
        # invocation:
        return sub {
            my @args = @{ shift() };
            @params = map {
                if ($_ eq "v") {
                    shift(@args);
                } else {
                    $_;
                }
            } @params;
            $directives{$directive_type}->(\@params, \%flags)->(@args);
        }
    } else {
        return $directives{$directive_type}->(\@params, \%flags);
    }
}

# we go through $string and build up a list of subs to call
sub compile_control_string {
    my $directive_class = join('', keys %directives);
    my $directive_regexp =
      qr/(~ # start with a '~'
         (?:(?:[,0-9]|'.)*?) # followed by a sequence of nu\mbers or quoted chars or co\m\mas
         $flags_class* # then the flags
         (?<!')(?:[$directive_class])) # finally ter\minated by a non quoted directive char
    /x;
    my $control = shift;
    my @pieces =
      map {
          # build up the sub
          if (/$directive_regexp/) {
              build_directive($_);
          } else {
              sub { $_ };
          }
      } grep { $_ } split $directive_regexp, $control;
    return sub {
        my @args = @_;
        join '', map { $_->(\@args) } @pieces;
    }
}

sub pprint {
    my ($control, @args) = @_;
    if (ref $control eq 'CODE') {
        return $control->(@args);
    } else {
        return compile_control_string($control)->(@args);
    }
}

1;
__END__;
