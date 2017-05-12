package Term::SimpleColor;

use strict;
use warnings;
use utf8;
use Carp;
use base 'Exporter';

our $VERSION = '0.0.3';

our @EXPORT = qw/ black red green yellow blue magenta cyan gray white default /;
our @EXPORT_OK =
  qw/ bg_default bg_black bg_red bg_green bg_yellow bg_blue bg_magenta bg_cyan bg_gray underscore bold invert dc_default /;

our %EXPORT_TAGS = (
    all        => \@EXPORT_OK,
    background => [
        qw(bg_default bg_black bg_red bg_green bg_yellow bg_blue bg_magenta bg_cyan bg_gray)
    ],
    decoration => [qw(underscore bold invert dc_default)],
);


# TRIVIA: \x1b is escape code
my %COLOR = (
    black   => "\x1b[30m",
    red     => "\x1b[31m",
    green   => "\x1b[32m",
    yellow  => "\x1b[33m",
    blue    => "\x1b[34m",
    magenta => "\x1b[35m",
    cyan    => "\x1b[36m",
    white   => "\x1b[37m",
    default => "\x1b[39m",
);

my %BG_COLOR = (
    bg_black   => "\x1b[40m",
    bg_red     => "\x1b[41m",
    bg_green   => "\x1b[42m",
    bg_yellow  => "\x1b[43m",
    bg_blue    => "\x1b[44m",
    bg_magenta => "\x1b[45m",
    bg_cyan    => "\x1b[46m",
    bg_gray    => "\x1b[47m",
    bg_default => "\x1b[49m",
);

my %DECORATE = (
    underscore => "\x1b[4m",
    bold       => "\x1b[1m",
    invert     => "\x1b[7m",
    dc_default => "\x1b[0m",
);


sub _code {
    my ( $color_key, $string ) = @_;

    if ( !defined($color_key) || !defined( $COLOR{$color_key} ) ) {
        croak 'The color is NOT defined';
    }

    return $COLOR{$color_key}  unless defined($string);
    return $COLOR{$color_key} . $string . default();
}


sub default {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _code($me, $string);
}


sub black {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _code($me, $string);
}



sub red {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _code($me, $string);
}

sub green {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _code($me, $string);
}

sub yellow {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _code($me, $string);
}

sub blue {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _code($me, $string);
}

sub magenta {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _code($me, $string);
}

sub cyan {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _code($me, $string);
}


sub white {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _code($me, $string);
}


sub _bg_code {
    my ( $color_key, $string ) = @_;

    if ( !defined($color_key) || !defined( $BG_COLOR{$color_key} ) ) {
        croak 'The color is NOT defined';
    }

    return $BG_COLOR{$color_key}  unless defined($string);
    return $BG_COLOR{$color_key} . $string . bg_default();

    return '';
}


sub bg_default {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _bg_code($me, $string);
}

sub bg_black {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _bg_code($me, $string);
}


sub bg_red {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _bg_code($me, $string);
}

sub bg_green {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _bg_code($me, $string);
}

sub bg_yellow {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _bg_code($me, $string);
}

sub bg_blue {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _bg_code($me, $string);
}

sub bg_magenta {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _bg_code($me, $string);
}

sub bg_cyan {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _bg_code($me, $string);
}

sub bg_gray {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _bg_code($me, $string);
}



sub _dc_code {
    my ( $color_key, $string ) = @_;

    if ( !defined($color_key) || !defined( $DECORATE{$color_key} ) ) {
        croak 'The color is NOT defined.', " $color_key" ;
    }

    return $DECORATE{$color_key}  unless defined($string);
    return $DECORATE{$color_key} . $string . dc_default();

    return '';
}

sub dc_default {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _dc_code($me, $string);
}

sub underscore {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _dc_code($me, $string);
}

sub bold {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _dc_code($me, $string);
}

sub invert {
    my ($string) = @_;
    my $me = (split('::', (caller(0))[3]))[-1];
    return _dc_code($me, $string);
}

1;
__END__

=head1 NAME

Term::SimpleColor - A very simple color screen output

=head2 SYNOPSIS

    use Term::SimpleColor;
    print red "a red line\n";

    print green;
    print "green\n";
    print "green line 2\n";
    print default; # finish green


    # backgroud color
    use Term::SimpleColor qw(:background);
    print bg_red "a line on red background\n";

    print bg_green;
    print "line 1 on green background\n";
    print "line 2 on green background\n";
    print bg_default; # finish green


    # text decoration
    use Term::SimpleColor qw(:decorate);
    print underscore "a line with underscore\n";

    print invert;
    print "line 1 with invert\n";
    print "line 2 with invert\n";
    print dc_default; # finish invert


=head2 DESCRIPTION

   Easy to make your terminal program output colorful.
   Term::ANSIColor is very useful but complicate.
   Term::SimpleColor provides easy understanding methods with an implementation optimised for the common case.


=head2 METHODS

=over

=item black( $string )

    This shows black string.
    If parameter is set, only set the string black.
    The paramater is not set, you can show multiple string black.
    black method is defaultly exported.

    Exsample for one string

    print black( $string );
        OR:
    print black $string;


    Exsample for multiple string.
   
    print black();
    print $string1;
    print $string2;
    print default(); # back to default setting

=item red( $string )

    Same as black()

=item green( $string )

    Same as black()

=item yellow( $string )

    Same as black()

=item blue( $string )

    Same as black()

=item magenta( $string )

    Same as black()

=item cyan( $string )

    Same as black()

=item white( $string )

    Same as black()

=item default()

    Same as black()

=item bg_black( $string )

    This shows the string on black background.
    If parameter is set, only show the string on black backgrond.
    The paramater is not set, you can show multiple strings on black background.
    To export like these
    'use Term::SimplrColor qw( bg_black );',
    'use Term::SimplrColor qw( :background );'
    or
    'use Term::SimplrColor qw( :all );'

    Exsample for using one string

    print bg_black( $string );
        OR:
    print bg_black $string;


    Exsample for multiple string.
   
    print bg_black();
    print $string1;
    print $string2;
    print bg_default(); # back to default setting


=item bg_red( $string )

    Same as bg_black()

=item bg_green( $string )

    Same as bg_black()

=item bg_yellow( $string )

    Same as bg_black()

=item bg_blue( $string )

    Same as bg_black()

=item bg_magenta( $string )

    Same as bg_black()

=item bg_cyan( $string )

    Same as bg_black()

=item bg_gray( $string )

    Same as bg_black()

=item bg_default()

    Same as bg_black()

=item bold( $string )

    This shows the bold string.
    If parameter is set, only show the bold string. 
    The paramater is not set, you can show multiple bold strings.
    To export like these
    'use Term::SimplrColor qw( bold );',
    'use Term::SimplrColor qw( :decoration );'
    or 
    'use Term::SimplrColor qw( :all );'


    Exsample for using one string

    print bold( $string );
        OR:
    print bold $string;


    Exsample for multiple string.
   
    print bold();
    print $string1;
    print $string2;
    print dc_default(); # back to default setting

=item underscore( $string )

    Same as bold().

=item invert( $string )

    Same as bold().

=item dc_default()

    Same as bold().

=back

=head2 AUTHOR

Takashi Uesugi <tksuesg@gmail.com>

=head2 COPYRIGHT AND LICENCE

Copyright (C) 2013 by Takashi Uesugi
This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

