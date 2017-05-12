package ModelSim::List;

use strict;
use warnings;

our $VERSION = '0.06';
our $error;

sub new ($) {
    my $class = ref $_[0] ? ref shift : shift;
    return bless {}, $class;
}

sub parse ($$) {
    my ($self, $file) = @_;
    my ($ast, $fh);
    unless(open $fh, $file) {
        $error = "file error - Can't open $file for reading: $!\n";
        return undef;
    }
    $_ = <$fh>;
    if (/^\@/o) {
        $ast = _parse_event_list($fh, $file);
    } else {
        $ast = _parse_normal_list($fh, $file);
    }
    close $fh;
    return undef unless $ast;
    %$self = %$ast;
    return 1;
}

sub _parse_normal_list ($$) {
    my ($fh, $file) = @_;
    my $ast = {};
    my (%cols, @cols);
    my $state = 0;
    do {{
        next if /^\s*$/o;
        if ($state == 0) {
            if (/\b\/\w+|\bdelta\b|\bns\b/o) {
                # process signal name list:
                while (/[\w\/]+/go) {
                    $cols{$+[0]} = $&;
                    #warn "$& - ", $+[0], "\n";
                }
            } else {
                # process the first data line:
                @cols = _sort_cols(%cols);
                undef %cols;
                _parse_data_line($ast, @cols);
                $state = 1;
            }
        } elsif ($state == 1) {
            # process data line:
            _parse_data_line($ast, @cols);
        } else {
            chomp;
            $error =  "file error - Syntax error: line $.: $_\n";
            return undef;
        }
    }} while (<$fh>);
    #die Data::Dumper->Dump([$ast], [qw(self)]);
    return $ast;
}

# used in sub _parse_normal_list:
sub _parse_data_line {
    my ($ast, @cols) = @_;
    s/^\s+//;
    my @data = split(/\s+/, $_);
    my $time = $data[0];
    for(my $i = 1; $i < @data; $i++) {
        my $sig = $cols[$i];
        my $val = $data[$i];
        #warn "@cols", " -> ", $sig, "\n";
        #warn "@data", " -> ", $val, "\n";
        next if $sig eq 'delta';
        $ast->{$sig} = [] unless ref $ast->{$sig};
        if (@{$ast->{$sig}} and ${$ast->{$sig}}[-2] eq $val) {
            next;
        }
        if (@{$ast->{$sig}} and ${$ast->{$sig}}[-1] eq $time) {
            ${$ast->{$sig}}[-2] = $val;
            next;
        }
        push @{$ast->{$sig}}, $val, $time;
    }
}

# used in sub _parse_normal_list:
sub _sort_cols {
    my %cols = @_;
    my @cols;
    foreach my $colnum (sort keys %cols) {
        push @cols, $cols{$colnum};
    }
    return @cols;
}

sub _parse_event_list {
    my ($fh, $file) = @_;
    my $ast = {};
    my $time;
    do {{
        next if /^\s*$/;
        if (/^\@(\d+)/) {
            $time = $1;
            next;
        }
        unless (defined $time) {
            $error = "file error - $file: Invalid file format\n";
            return undef;
        }
        if (/^([\w\/]+)\s+(\w+)\s*$/) {
            my ($sig, $val) = ($1, $2);
            $ast->{$sig} = [] unless ref $ast->{$sig};
            if (@{$ast->{$sig}} and ${$ast->{$sig}}[-1] eq $time) {
                ${$ast->{$sig}}[-2] = $val;
                next;
            }
            push @{$ast->{$sig}}, $val, $time;
            next;
        }
        $error = "file error - $file: Invalid file format\n";
        return undef;
    }} while (<$fh>);
    #die Data::Dumper->Dump([$ast], [qw(self)]);
    return $ast;
}

sub strobe {
    my ($self, $signal, $time) = @_;
    unless ($self->{$signal}) {
        $error = "strobe error - $signal: No such signal name.\n";
        return undef;
    }
    my @events = @{$self->{$signal}};
    if ($time < $events[1]) {
        $error = "strobe error - $signal: time $time underflow.\n";
        return undef;
    }
    my $value;
    while (@events) {
        my $val = shift @events;
        my $tm  = shift @events;

        if ($time < $tm) {
            return $value;
        } else {
            $value = $val;
        }
    }
    return $value;
}

sub _val_eq {
    my ($val, $pat) = @_;
    return $val =~ $pat if (ref($pat) eq 'Regexp');
    return $val eq $pat;
}

sub time_of {
    my ($self, $signal, $value, $start, $end) = @_;
    $start = 0 unless defined $start;
    if (defined $start and defined $end) {
        if ($start > $end) {
            $error = "time_of error - Starting time $start greater than the ".
                "ending time $end\n";
            return undef;
        }
    }
    unless ($self->{$signal}) {
        $error = "time_of error - $signal: No such signal name.\n";
        return undef;
    }
    my @events = @{$self->{$signal}};
    my $time;
    return $start if _val_eq($self->strobe($signal, $start), $value);
    while (@events) {
        my $val = shift @events;
        my $tm  = shift @events;

        if ($tm < $start) {
            next;
        }
        if (_val_eq $val, $value) {
            if (defined $end and $tm > $end) {
                $error = "time_of warning - $signal: Never achieved value $value ".
                    "during the time interval specified.\n";
                return undef;
            }
            return $tm;
        }
    }
    $error = "time_of warning - $signal: Never achieved value $value ".
        "during the time interval specified.\n";
    return undef;
}

# Return the error info:
sub error {
    return $error;
}

1;
__END__

=head1 NAME

ModelSim::List - Analyse the 'list' output of the ModelSim simulator

=head1 VERSION

This document describes ModelSim::List 0.06 released on
2 June, 2007.

=head1 SYNOPSIS

    use ModelSim::List;
    $list = ModelSim::List->new;

    # ram.lst is generated by ModelSim
    # simulator (via the "write list" command)
    $list->parse('ram.lst') or
        die $list->error();

    # get the value of signal /ram/address at time 100:
    $value = $list->strobe('/ram/address', 100);

    # get the time when signal /alu/rdy get the value 1:
    $time = $list->time_of('/alu/rdy', 1);

    # specify regex rather than actual value:
    $time = $list->time_of('/processor/bus_data', qr/^z+$/i);

    $time = $list->time_of($signal, $value, $start_time);
    $time = $list->time_of($signal, $value, $start_time, $end_time);
    die $list->error() unless defined $time;

=head1 DESCRIPTION

This module provides a class named C<ModelSim::List> with which the EDA tester
can easily check in the signals contained in the files generated by ModelSim's
C<"write list"> command in a programming manner.

=head1 METHODS

=over

=item C<< $list = ModelSim::List->new() >>

This is the constructor of the C<ModelSim::List> class.

=item C<< $list->parse($file_name) >>

This method gets the object parse the list file specified as C<$file_name>. You can
invoke the parse method on the same object several times. Once you specify a
list file, the new file will override the old one completely. No matter whether you use an
C<-event> option in your C<"write list"> command to generate the file or not, the object
will recognize the list format automatically.

I'd like to give one example for each of the two file format here:

         ns       /ram/mfc
          delta       /ram/bus_data
          0  +2          1 xxxxxxxx
          0  +3          0 zzzzzzzz
         10  +0          1 0000aaaa
         10  +1          0 0000abcd
         29  +0          1 0000abcd
         38  +0          0 0000abcd
         38  +2          0 zzzzzzzz
         86  +0          1 zzzzzzzz
         86  +1          1 0000abcd

and if you use the C<-event> option in the "write list" command,
the list file will like follows:

    @0 +0
    /ram/mfc x
    /ram/mfc 0
    /ram/bus_data zzzzzzzz
    /ram/bus_data zzzzzzzz
    @10 +0
    /ram/bus_data 0000abcd
    @29 +0
    /ram/mfc 1
    @38 +0
    /ram/mfc 0
    @38 +2

The method returns 1 to indicate success. When it returns undef, it is recommended to
check the error info via the C<error()> method.

=item C<< $list->error() >>

Returns the error message for the last failed operation.

=item C<< $list->strobe($signal, $time) >>

The I<strobe> method are used to get the value of a signal named C<$signal> at any given
time instant, $time. The object will preserve the original signal value format used
in the list file. No format conversion will happen.

When C<strobe()> returns undef, it is recommended to check the detailed info via the
C<error()> method if you feel surprised.

CAUTION: The delta number will be totally ignored. Therefore, if signal /module/a becomes 0 at
"0 ns +0", and changes to 1 at "0 ns +1", thus C<< $obj->strobe('/module/a', 0) >> will return 1 rather than
0.

=item C<< $list->time_of($signal, $value, ?$start, ?$end) >>

You can utilize the I<time_of> method to get the time instant when C<$signal> first gained
the value C<$value> within the time interval specified by C<$tart> and C<$end>.
Both the last two arguments are optional. In the case that $start is missing,
the initial time 0 will be
assumed. If the signal fails to achieve $value, I<time_of> will return undef.

If the $value argument is a regex ref, I<time_of> will perform pattern matching instead
of string comparing.

When C<time_of()> returns undef, it is recommended to check the detailed info via the
C<error()> method if you feel surprised.

=back

=head1 VERSION CONTROL

You can always get the latest source from the following
Subversion repository:

L<http://svn.openfoundry.org/modlesimlist>

which has anonymous access to all.

If you do want a commit bit, please let me know.

=head1 BUGS

There must be some serious bugs lurking somewhere. If
you find one, please consider firing off a report to
L<http://rt.cpan.org>.

=head1 CODE COVERAGE

I use L<Devel::Cover> to test the code coverage of this
module and here is the report:

 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 File                           stmt   bran   cond    sub    pod   time  total
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 blib/lib/ModelSim/List.pm      89.4   82.8   77.8   91.7   40.0   99.7   85.0
 ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 AUTHOR

Agent Zhang (E<lt>agentzh@gmail.comE<gt>)

=head1 COPYRIGHT

Copyright (C) 2005-2007 by Agent Zhang. All rights reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

ModelSim Command Reference

