package Sub::Sequence;
use strict;
use warnings;
use parent qw/Exporter/;

our $VERSION = '0.03';

our @EXPORT = qw/
    seq
/;

sub seq {
    my ($list, $every, $code) = @_;

    _croak("First arg must ARRAY REF: $list") if ref($list) ne 'ARRAY';
    _croak("Second arg is wrong: $every")     if $every < 1;
    _croak("Third arg must CODE REF: $code")  if ref($code) ne 'CODE';

    my $loop = 0;
    my @result;

    my $last = $#{$list};

    while (1) {
        my $start = $loop * $every;
        last if $start > $last;
        my $end = $start + $every - 1;
        if ($end > $last) { $end = $last; }
        $loop++;
        my $ret = $code->(
            +[ @{$list}[$start .. $end] ],
            $loop,
            ($loop - 1) * $every
        );
        if (wantarray && ref($ret) eq 'ARRAY') {
            push @result, @{$ret};
        }
        else {
            push @result, $ret;
        }
    }

    return wantarray ? @result : \@result;
}

sub _croak {
    require Carp;
    Carp::croak($_[0]);
}

1;

__END__

=head1 NAME

Sub::Sequence - simplest, looping over an array in chunks


=head1 SYNOPSIS

    use Sub::Sequence;

    my @user_id_list = (1..10_000_000);

    seq \@user_id_list, 50, sub {
        my $list = shift;

        my $in_id = join ',', map { int $_; } @{$list};
        # UPDATE table SET status=1 WHERE id IN ($id_cond)
        sleep 1;
    };


=head1 DESCRIPTION

Sub::Sequence provides the function named 'seq'.
You can treat an array with simple interface.


=head1 FUNCTIONS

=over 4

=item seq($array_ref, $n, \&code)

This function calls C<\&code> with split array.
And C<\&code> takes $n items at a time(also give $step_count and $offset).

    use Sub::Sequence;
    use Data::Dumper;

    my $result = seq [1, 2, 3, 4, 5], 2, sub {
        my ($list, $step, $offset) = @_;
        # ... Do something ...
        return $offset;
    };

    warn Dumper($result); # [ 0, 2, 4 ]

B<NOTE>: Return value of C<seq> is the array reference of return values of C<\&code> in scalar context. However, C<seq> was called in the list context, then return value is the B<flatten> list.

    use Sub::Sequence;
    use Data::Dumper;

    # scalar context
    my $foo = seq [1, 2, 3, 4, 5], 2, sub {
        my @list = @{ $_[0] };
        return \@list;
    };
    warn Dumper($foo); # [ [1, 2], [3, 4], [5] ]

    # list context
    my @bar = seq [1, 2, 3, 4, 5], 2, sub {
        my @list = @{ $_[0] };
        return \@list;
    };
    warn Dumper(\@bar); # [ 1, 2, 3, 4, 5 ]

=back


=head1 REPOSITORY

Sub::Sequence is hosted on github
<http://github.com/bayashi/Sub-Sequence>


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

An interface of this module was inspired by L<Sub::Retry>.

Also check similar modules, L<Iterator::GroupedRange> and C<natatime> method in L<List::MoreUtils>.

Lastly, see C<benchmark.pl> (Sub::Sequence vs splice vs natatime) in C<samples> directory.


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
