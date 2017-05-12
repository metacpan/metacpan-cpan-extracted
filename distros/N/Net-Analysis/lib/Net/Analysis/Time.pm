package Net::Analysis::Time;
# $Id: Time.pm 131 2005-10-02 17:24:31Z abworrall $

use 5.008000;
our $VERSION = '0.01';
use strict;
use warnings;
use Carp qw(carp croak confess);
use POSIX qw(strftime);
use overload
    q("")  => \&as_string,
    q(0+)  => \&as_number,
    q(+=)  => \&inceq,
    q(-=)  => \&deceq, #)
    q(+)   => \&addition,
    q(-)   => \&subtraction,    #)
    q(<=>) => \&numerical_cmp;

our $Default_format = ''; # No format, raw epoch

# {{{ POD

=head1 NAME

Net::Analysis::Time - value object for [tv_sec, tv_usec] times

=head1 SYNOPSIS

  use Net::Analysis::Time;

  my $t1 = Net::Analysis::Time->new(10812345, 123456);
  my $t2 = Net::Analysis::Time->new(10812356, 123456);

  my $diff = $t2-$t1; # == new Time Object

  print "$diff\n"; # == "11.000000"

  $t1->round_usec(10000); # "$t1" == "10812345.120000";

=head1 DESCRIPTION

Can't believe I've found myself implementing a date/time module. The shame of
it.

This is a heavily overloaded object, so '+', '-' do what you expect.

There is some format stuff to change how it stringfies, and some stuff for
rounding off values, used elsewhere for time-boxing.

This stuff should probably all be junked as soon as someone wants some
efficiency.

=cut

# }}}

#### Public methods
#
# {{{ new

# {{{ POD

=head2 new ($sec [, $usec] )

If passed a single floating point arg, does what it can, but don't blame me if
rounding errors knacker things up.

Best to pass two ints, one seconds and one microseconds.

=cut

# }}}

sub new {
    my ($class, $s, $us) = @_;

    # If it looks like we've been passed floating point seconds, sort it out
    if (!defined $us && ($s - int($s))) {
        ($s, $us) = _breakup_float ($s);
    }

    $us = 0 if (!defined $us);

    return bless ({'s'=>$s, us=>$us}, $class);
}

# }}}
# {{{ clone

# {{{ POD

=head2 clone ()

Returns a new object, holding the same time value as the invocant.

=cut

# }}}

sub clone {
    my ($self) = shift;

    my $new = { %$self };

    return bless $new => ref($self); # Copy class over
}

# }}}
# {{{ numbers

sub numbers {
    my $self = shift;
    return (wantarray)
            ? ( $self->{'s'}, $self->{us} )
            : [ $self->{'s'}, $self->{us} ];
}

# }}}
# {{{ round_usec

=head2 round_usec ($usec_step [, $round_up_not_down])

Rounds the time down to the nearest usec_step value. Valid values between 10
and 1000000. A value of 1000000 will round to the nearest second.

Optional argument, if true, causes rounding to go up, not down.

=cut

sub round_usec {
    my ($self, $val, $up) = @_;

    if ($val < 10 || $val > 1000000) {
        croak ("round_usec([10-1000000]), not '$val'\n");
    }

    $self->{rem} = $self->{us} % $val;

    $self->{us} -= $self->{rem};

    if ($up && $self->{rem}) {
        if ($val == 1000000) {
            $self->{'s'}++;
        } else {
            $self->{us} += $val ; # round up, not down
        }

        $self->{rem} = $val - $self->{rem}; # Allow for one level of restore
    }
}

# }}}
# {{{ usec

sub usec {
    my $self = shift;

    return $self->{'s'} * 1000000 + $self->{us};
}

# }}}

#### Overload methods
#
# {{{ as_string

sub as_string {
    my ($self, $fmt) = @_;
    my $ret = '';

    # If we've been passed an explicit format, override the default for
    #  the scope of this execution.
    local $Default_format = $Default_format;
    Net::Analysis::Time->set_format($fmt) if ($fmt);

    if ($Default_format) {
        $ret = strftime($Default_format, gmtime($self->{'s'}));
    } else {
        $ret = $self->{'s'};
    }

    return $ret . sprintf (".%06d", $self->{us});
}

# }}}
# {{{ as_number

sub as_number {
    my ($self) = shift;

    return $self->{'s'} + ($self->{us} / 1000000);
}

# }}}
# {{{ numerical_cmp

sub numerical_cmp {
    # If the seconds agree, it's down to the microseconds ...
    if (ref($_[0]) ne 'Net::Analysis::Time' ||
        ref($_[1]) ne 'Net::Analysis::Time')
    {
        confess "Time<=> args bad: ".ref($_[0]).", ".ref($_[1])."\n";
    }

    if ($_[0]->{'s'} == $_[1]->{'s'}) {
        return ($_[0]->{'us'} <=> $_[1]->{'us'});
    }
    return ($_[0]->{'s'} <=> $_[1]->{'s'});
}

# }}}
# {{{ inceq

sub inceq {
    my ($arg1, $arg2, $arg3) = @_;

    # Should really work out what to do here ..
    die "we have arg3 1 !\n".Data::Dumper::Dumper(\@_) if ($arg3);

    $arg1->_add (_arg_to_nums ($arg2));

    return $arg1;
}

# }}}
# {{{ deceq

sub deceq {
    my ($arg1, $arg2, $arg3) = @_;

    # Should really work out what to do here ..
    die "we have arg3 2 !\n".Data::Dumper::Dumper(\@_) if ($arg3);

    $arg1->_subtract (_arg_to_nums ($arg2));

    return $arg1;
}

# }}}
# {{{ addition

sub addition {
    my ($arg1, $arg2, $arg3) = @_;

    # Should really work out what to do here ..
    die "we have arg3 3!\n".Data::Dumper::Dumper(\@_) if ($arg3);

    my $new = $arg1->clone();

    $new->_add (_arg_to_nums ($arg2));

    return $new;
}

# }}}
# {{{ subtraction

sub subtraction {
    my ($arg1, $arg2, $arg3) = @_;

    # Should really work out what to do here ..
    confess "we have arg3 4!\n".Data::Dumper::Dumper(\@_) if ($arg3);

    my $new = $arg1->clone();

    $new->_subtract (_arg_to_nums ($arg2));

    return $new;
}

# }}}

#### Class methods
#
# {{{ set_format

=head1 CLASS METHODS

=head2 set_format ($format)

Set the default output format for stringification of the date/time.
The parameter is either a C<strftime(3)> compliant string, or a named
format:

  raw  - 1100257189.123456
  time - 10:59:49.123456
  full - 2004/11/12 10:59:49.123456

Returns the old format.

=cut

sub set_format {
    my ($class, $fmt) = @_;
    my (%format_shortcuts) = (raw  => '',
                              full => '%Y/%m/%d %T',
                              time => '%T',
                             );
    my $old_format = $Default_format;

    if (exists $format_shortcuts{$fmt}) {
        $Default_format = $format_shortcuts{$fmt};
    } else {
        $Default_format = $fmt;
    }

    return $old_format;
}

# }}}

#### Helpers
#
# {{{ _breakup_float

sub _breakup_float {
    my ($f) = shift;

    # Break up float with: int (rounds down), and sprintf (rounds closest)
    my $s  = int($f);
    my $us = sprintf ("%6d", ($f - $s) * 1000000);

    return (wantarray) ? ($s,$us) : [$s,$us];
}

# }}}
# {{{ _arg_to_nums

sub _arg_to_nums {
    my ($arg) = @_;

    if (! ref($arg)) {
        return _breakup_float($arg);

    } elsif (ref ($arg) eq 'ARRAY') {
        return (@$arg);

    } elsif (ref ($arg) eq 'Net::Analysis::Time') {
        return ($arg->{'s'}, $arg->{us});

    } else {
        die "could not make arg '$arg' into time: ".Data::Dumper::Dumper($arg);
    }
}

# }}}

# {{{ _add

sub _add {
    my ($self, $s, $us) = @_;

    $self->{'s'}  += $s;

    # Catch overflows
    if (($self->{'us'} += $us) > 1000000) {
        $self->{'s'}++;
        $self->{'us'} -= 1000000;
    }
}

# }}}
# {{{ _subtract

sub _subtract {
    my ($self, $s, $us) = @_;

    $self->{'s'}  -= $s;

    # Catch underflows
    if (($self->{'us'} -= $us) < 0) {
        $self->{'s'}--;
        $self->{'us'} += 1000000;
    }
}

# }}}

1;
__END__
# {{{ POD

=head2 EXPORT

None by default.

=head1 AUTHOR

Adam B. Worrall, E<lt>worrall@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Adam B. Worrall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

# }}}

# {{{ -------------------------={ E N D }=----------------------------------

# Local variables:
# folded-file: t
# end:

# }}}
