use strict;
use warnings;

package OptArgs2::StatusLine;

our $VERSION = 'v2.0.15';

sub RS { chr(30) }
my $RS = RS;

our $WARN_FMT = "\e[38;5;220m%s\e[0m\n";
sub WARN { chr(5) }
my $WARN = WARN;

sub TIESCALAR {
    my $class = shift;
    bless( ( \my $str ), $class );
}

sub FETCH { ${ $_[0] } }

sub STORE {
    my $self = shift;
    my $arg  = shift // return $$self = undef;
    my %arg  = ();

    if ( 'SCALAR' eq ref $arg ) {
        $arg{prefix} = $$arg;
    }
    elsif ( '' eq $arg ) {
        $arg{msg} = '';
    }
    else {
        $arg =~ m/
            (?:(?<prefix>.+?)?(?:$RS))?
            (?<WARN>$WARN)?
            (?<msg>.+?)?
            (?<NL>\n)?
            \z
            /x;

        %arg = %+;
    }

    ( $$self // '' ) =~ m/
        (?:(?<prefix>.*)(?:$RS))?
        (?<msg>.*?)?
        \z
        /x;

    my %next = ( %+, NL => "\r", %arg );

    if ( not defined $next{prefix} ) {
        require File::Basename;
        $next{prefix} = File::Basename::basename($0) . ': ';
    }

    my $fh = select;
    if ( $next{WARN} ) {
        if ( -t STDERR ) {
            warn sprintf $WARN_FMT, $next{prefix} . $next{msg} . "\e[K";
        }
        else {
            warn $next{prefix}, $next{msg}, "\n";
        }
        $fh->print( $next{prefix}, $next{msg}, "\n" ) if not -t $fh;
    }
    elsif ( -t $fh ) {
        $fh->printflush( "\e[?25l", $next{prefix}, $next{msg}, "\e[K",
            $next{NL} );
    }
    else {
        $fh->print( $next{prefix}, $next{msg}, "\n" );
    }

    $next{msg} = '' if $next{NL} eq "\n";
    $$self = $next{prefix} . RS . $next{msg};
}

END {
    my $fh = select;
    $fh->printflush("\e[?25h") if -t $fh;
}

sub import {
    my $class  = shift;
    my $caller = scalar caller;

    no strict 'refs';
    foreach my $arg (@_) {
        if ( $arg =~ m/^\$(.*)/ ) {
            my $name = $1;
            tie my $x, 'OptArgs2::StatusLine';
            *{ $caller . '::' . $name } = \$x;
        }
        elsif ( $arg eq 'RS' ) {
            *{ $caller . '::RS' } = \&RS;
        }
        elsif ( $arg eq 'WARN' ) {
            *{ $caller . '::WARN' } = \&WARN;
        }
        else {
            require Carp;
            Carp::croak('expected "RS", "WARN" or "$scalar"');
        }

    }
}

sub _explode {
    require Carp;
    my $s = shift;
    $s =~ s/\n/\\n/g;
    $s = join( ' . RS . ', map { qq{"$_"} } split( /$RS/, $s ) );
    Carp::carp($s);
}

1;

__END__

=head1 NAME

OptArgs2::StatusLine - terminal status line

=head1 VERSION

v2.0.15 (2025-04-25)

=head1 SYNOPSIS

    use OptArgs2::StatusLine '$status', 'RS', 'WARN';
    use Time::HiRes 'sleep';    # just for simulating work

    $status = 'starting ... '; sleep .7;
    $status = WARN. 'Warning!';

    $status = 'working: ';
    foreach my $i ( 1 .. 10 ) {
        $status .= " $i"; sleep .15;
    }

    # You can localize $status for temporary changes
    {
        local $status = 'temporary: '. RS;
        foreach my $i ( 1 .. 10 ) {
            $status = $i; sleep .15;
        }
        sleep 1;
    }
    $status .= ' (previous)';
    sleep 1;

    # Right back where you started
    $status = "Done.\n";

=head1 DESCRIPTION

B<OptArgs2::StatusLine> provides a simple terminal status line
implementation, using the L<perltie> mechanism. Simply assigning to a
C<$scalar> prints the string to the terminal. The terminal line will be
overwritten by the next assignment unless it ends with a newline.

You can create a C<$status> scalar at import time as shown in the
SYNOPSIS, or you can C<tie> your own variable manually, even in a HASH:

    my $self = bless {}, 'My::Class';
    tie $self->{status}, 'OptArgs2::StatusLine';
    $self->{status} = 'my status line';

Status variables have a default prefix of "program-name: ". You can
change that two ways:

=over

=item * Use an ASCII record separator (i.e. chr(30)) which you can
import as C<RS>, as a prefix / message divider:

    use OptArgs2::StatusLine '$status', 'RS';

    $status = 'msg1';                  # "program: my status"
    $status = 'Other: ' . RS . 'msg2'; # "Other: msg2"
    $status = 'msg3';                  # "Other: msg3"

=item * Assign a scalar reference:

    $status = \'New Prefix: ';
    $status = 'fine';             # "New Prefix: fine"

=back

You can import multiple status variables in one statement:

    use OptArgs2::StatusLine '$status', '$d_status';

    if ($DEBUG) {
        $d_status = 'debug: '. RS;
    } else {
        untie $d_status;
    }

    $status   = 'frobnicating';     # program: frobnicating
    $d_status = 'details matter!';  # debug: details matter!

A status line can be sent to C<STDERR> via C<warn> by prefixing a
message with the ASCII enquiry character (i.e. chr(5)) which you can
import as C<WARN>:

    use OptArgs2::StatusLine '$status', 'WARN';

    $status = 'Normal';           # program: normal
    $status = WARN . 'Warning!';  # program: Warning! > /dev/stderr

A newline is automatically added to the end of a WARN status. The
formatting of the warning is determined by 
C<$OptArgs2::StatusLine::WARN_FMT>. This is set to
C<"\e[38;5;220m%s\e[0m\n"> by default, colouring the text yellow. Set
it to a plain C<"%s"> to remove formatting.

=head1 SEE ALSO

L<OptArgs2>

=head1 SUPPORT & DEVELOPMENT

This distribution is managed via github:

    https://github.com/mlawren/p5-OptArgs2

This distribution follows the semantic versioning model:

    http://semver.org/

Code is tidied up on Git commit using githook-perltidy:

    http://github.com/mlawren/githook-perltidy

=head1 AUTHOR

Mark Lawrence <mark@rekudos.net>

=head1 LICENSE

Copyright 2022-2025 Mark Lawrence <mark@rekudos.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

