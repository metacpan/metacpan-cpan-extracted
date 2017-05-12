package Number::Continuation;

use strict;
use warnings;
use base qw(Exporter);
use boolean qw(true);

use Carp qw(croak);
use Params::Validate ':all';

our ($VERSION, @EXPORT_OK);

$VERSION = '0.05';
@EXPORT_OK = qw(continuation);

validation_options(
    on_fail => sub
{
    my ($error) = @_;
    chomp $error;
    croak $error;
},
    stack_skip => 2,
);

sub continuation
{
    my (@list, %opts, $set);

    _init(\$set, \%opts, \@_);

    if (wantarray) {
        _construct($set, \@list);
        return @list;
    }
    else {
        return _format($set, \%opts);
    }
}

sub _init
{
    my ($set, $opts, $args) = @_;

    if (ref $args->[-1] eq 'HASH') {
        %$opts = %{$args->[-1]};
        pop @$args;
    }

    my $re_digits = qr!^\-?\d+$!;

    my $spec = sub
    {
        my ($args, $spec) = @_;
        my @spec;
        push @spec, $spec while $args--;
        return @spec;
    };

    if (@$args == 1) {
        validate_pos(@$args, {
            type => SCALAR | ARRAYREF,
            callbacks => {
                'valid set' => sub
                {
                    foreach my $num (ref $_[0] ? @{$_[0]} : (split /\s+/, $_[0])) {
                        die "invalid number\n" unless $num =~ $re_digits;
                    }
                    $$set = ref $_[0] ? $_[0] : [ split /\s+/, $_[0] ];
                    return true;
                }
            },
        });
    }
    elsif (@$args > 1) {
        my %spec = (
            type  => SCALAR,
            regex => $re_digits,
        );
        validate_pos(@$args, $spec->(scalar @$args, \%spec));
        $$set = $args;
    }
    else {
        $$set = [];
    }

    my @args = %$opts;
    validate(@args, {
        delimiter => {
            type => SCALAR,
            optional => true,
            regex => qr!^\S{2}$!,
        },
        range => {
            type => SCALAR,
            optional => true,
            regex => qr!^\S{1,2}$!,
        },
        separator => {
            type => SCALAR,
            optional => true,
            regex => qr!^\S$!,
        },
    });

    $opts->{delimiter} ||= '';
    $opts->{range}     ||= '-';
    $opts->{separator} ||= ',';

    @{$opts->{delimiters}} = split //, $opts->{delimiter};
    $opts->{delimiters}[0] ||= '';
    $opts->{delimiters}[1] ||= '';
}

sub _construct
{
    my ($set, $list) = @_;

    my $prev_number = undef;

    my $entry = [];
    foreach my $num (@$set) {
        if (defined $prev_number
        && !(($num - $prev_number == 1) # positive continuation
          || ($prev_number - $num == 1) # negative continuation
        )) {
            push @$list, $entry;
            $entry = [];
        }
        push @$entry, $num;
        $prev_number = $num;
    }
    push @$list, $entry if @$entry;
}

sub _format
{
    my ($set, $opts) = @_;

    my $string = '';

    my $begin = sub
    {
        my ($string, $num) = @_;
        $$string .= $opts->{delimiters}[0];
        $$string .= $num;
    };
    my $range = sub
    {
        my ($string, $num) = @_;
        $$string .= $opts->{range};
        $$string .= $num;
    };
    my $end = sub
    {
        my ($string) = @_;
        $$string .= $opts->{delimiters}[1];
        $$string .= "$opts->{separator} ";
    };

    my $consecutive = 0;
    my $prev_number = undef;

    foreach my $num (@$set) {
        if (!defined $prev_number) {
            $begin->(\$string, $num);
        }
        else {
            if (($num - $prev_number == 1) # positive continuation
             || ($prev_number - $num == 1) # negative continuation
            ) {
                $consecutive++;
            }
            elsif ($consecutive) {
                $range->(\$string, $prev_number);
                $end->(\$string);
                $begin->(\$string, $num);
                $consecutive = 0;
            }
            else {
                $end->(\$string);
                $begin->(\$string, $num);
            }
        }
        $prev_number = $num;
    }
    if ($consecutive) {
        $range->(\$string, $prev_number);
    }
    if (@$set) {
        $end->(\$string);
    }

    $string =~ s/\Q$opts->{separator}\E $//;

    return $string;
}

1;
__END__

=head1 NAME

Number::Continuation - Create number continuations

=head1 SYNOPSIS

 use Number::Continuation qw(continuation);

 $set = '1 2 3 6 7 10 11 12 14';
 @set = (1,2,3,6,7,10,11,12,14);

 $contin = continuation($set);
 @contin = continuation($set);

 $contin = continuation(@set);
 @contin = continuation(@set);

 $contin = continuation(\@set);
 @contin = continuation(\@set);

 $contin = continuation($set, { delimiter => '[]', range => '~', separator => ';' });
 ...

 __OUTPUT__

 scalar context ($contin): '1-3, 6-7, 10-12, 14';
 list   context (@contin): [1,2,3], [6,7], [10,11,12], [14];

=head1 DESCRIPTION

=head2 continuation

 continuation($set | @set | \@set [, { options } ])

Returns in scalar context a stringified representation of a number continuation.
In list context a two-dimensional array is returned where each entry represents
a list of numbers that belong to a single continuation or which does not belong
to a continuation at all.

Continuation ranges may be negative.

It takes optionally a hash reference as last argument containing the parameters
C<delimiter>, C<range> and C<separator>. C<delimiter> may contain two characters,
where first one is prepended to the beginning of a continuation and the second one
appended to the end; C<range> may consist of one or two characters which are being
inserted between the beginning and end of a continuation; C<separator> may be set
to a single character which ends a continuation.

C<delimiter>, C<range> and C<separator> aren't mandatory parameters. If options
aren't defined, a reasonable default will be assumed.

=head1 EXPORT

C<continuation()> is exportable.

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
