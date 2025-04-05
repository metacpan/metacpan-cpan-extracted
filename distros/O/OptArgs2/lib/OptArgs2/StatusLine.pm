use strict;
use warnings;

package OptArgs2::StatusLine;

our $VERSION = 'v2.0.13';

sub RS { chr(30) }
my $RS = RS;

sub TIESCALAR {
    my $class = shift;
    bless [], $class;
}

sub FETCH { $_[0]->[0] }

sub STORE {
    my $self = shift;
    my $arg  = shift // return;
    my $str;

    if ( 'SCALAR' eq ref $arg ) {
        if ( not defined $self->[0] ) {
            $str = $$arg . $RS;
        }
        else {
            $str = $self->[0] =~ s/[^$RS]+/$$arg/r;
        }
    }
    elsif ( $arg =~ m/$RS/ ) {
        $str = $arg;
    }
    elsif ( not defined $self->[0] ) {
        require File::Basename;
        $str = File::Basename::basename($0) . ': ' . RS . $arg;
    }
    elsif ( $self->[0] =~ m/(.*)$RS/ ) {
        $str = $1 . RS . $arg;
    }
    else {
        warn "Internal Error - should never happen!";
        return;
    }

    my $NL = $str =~ s/\n\z// ? "\n" : "\r";
    my $fh = select;

    if ( -t $fh ) {
        $fh->printflush( $str . "\e[K" . $NL );
    }
    else {
        $fh->print( $str . "\n" );
    }

    $str =~ s/(.*$RS).*/$1/ if $NL eq "\n";
    $self->[0] = $str;
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
        else {
            die 'expected "RS" or "$scalar"';
        }

    }
}

1;

__END__

=head1 NAME

OptArgs2::StatusLine - terminal status line

=head1 VERSION

v2.0.13 (2025-04-04)

=head1 SYNOPSIS

    use OptArgs2::StatusLine '$status';
    use Time::HiRes 'sleep';    # just for simulating work

    $status = 'working ... ';
    sleep .7;

    foreach my $i ( 1 .. 10 ) {
        $status .= " $i";
        sleep .3;
    }

    # You can localize $status for temporary changes
    {
        local $status = "temporary info";
        sleep .8;
    }

    # Right back where you started
    sleep .7;
    $status = "Done.\n";

=head1 DESCRIPTION

B<OptArgs2::StatusLine> provides a simple terminal status line
implementation, using the L<perltie> mechanism. Simply assigning to a
C<$scalar> prints the string to the terminal. The terminal line will be
overwritten by the next assignment unless it ends with a newline.

You can create a status C<$scalar> at import time as shown in the
SYNOPSIS, or you can C<tie> your own variable manually, even in a HASH:

    my $self = bless {}, 'My::Class';
    tie $self->{status}, 'OptArgs2::StatusLine';
    $self->{status} = 'my status line';

Status variables have a default prefix of "program-name: ". You can
change that two ways:

=over

=item * Assign a scalar reference:

    $status = \'New Prefix: ';
    $status = 'fine';             # "New Prefix: fine"

=item * Use an ASCII record separator (i.e. chr(30)) which you can
import as RS() if you prefer:

    use OptArgs2::StatusLine 'RS';

    $status = 'Other: ' . RS . 'my status'; # "Other: my status"
    $status = 'something else';             # "Other: something else"

=back

You can import multiple status variables in one statement:

    use OptArgs2::StatusLine '$status', '$d_status';

    untie $d_status unless $DEBUG;
    $status   = 'frobnicating';
    $d_status = 'frobnicating in detail, maybe';

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

Mark Lawrence <nomad@null.net>

=head1 LICENSE

Copyright 2022 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

