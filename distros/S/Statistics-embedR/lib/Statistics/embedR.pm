package Statistics::embedR;

use 5.010;
use warnings;
use strict;
use Statistics::useR;

our $VERSION = "0.10.1";

state $r = {};

sub new {
    return $r if ref $r ne "HASH";

    my $that = shift;
    my $class = ref $that || $that;
    init_R;
    bless $r, $class;
}

sub DESTROY {
    my $self = shift;
    $self->quit("save='no'");
    end_R;
}

sub AUTOLOAD {
    my ($name) = our $AUTOLOAD =~ /::(\w+)$/;

    my $method = sub {
        my $self = shift;
        $name =~ s/_/./g;
        $self->R("$name(@_)");
    };

    no strict 'refs';
    *{ $AUTOLOAD } = $method;
    goto &$method;
}

sub eval {
    my $self = shift;
    eval_R(join "\n", @_);
}

sub load {
    my $self = shift;
    $self->library($_) for @_;
}

sub R {
    my $self = shift;
    my $result = $self->eval(@_)->getvalue;
    my @keys = keys %$result;
    return $result unless @keys == 1;
    return $result unless $keys[0] ~~ ['int', 'str', 'real'];

    my $values = $result->{$keys[0]};
    return @$values == 1 ? $values->[0] : $values;
}

sub arry2R {
    my $self = shift;
    my ($src, $dest) = @_;
    Statistics::RData->new(
        data      => {val => $src},
        varname   => $dest
    );
    $self->eval("$dest <- $dest\$val");
}

1; # End of Statistics::embedR

__END__

=head1 NAME

Statistics::embedR - Object-oriented interface for Statistics::useR.

=head1 VERSION

Version 0.1.2

=head1 SYNOPSIS

    use Statistics::embedR;

    my $r = Statistics::embedR->new(); # new() must be called at least once, before call the other method
    $r->eval($stat);                   # execute one statement
    $r->eval($stat1, $stat2);          # execute a list of statements sequentially
    $r->load("GenABEL", "genetics");   # load a list of R library

    $r->R("1");                        # 1
    $r->R("'1'");                      # '1'
    $r->R("a <- 1:3", "a");            # [1, 2, 3]

    my $ary = [3,5,7];
    $r->arry2R($ary, "array");         # array == c(3,5,7)

    $r->sum("c(2,3)");                 # 5, almost all R functions are available automatically
    $r->as_numeric('c("1", "2")');     # [1, 2], calls as.numeric(c("1", "2")) in the R end

=head1 DESCRIPTION

This module provides an object-oriented interface for Statistics::useR.
And provides some additional useful methods for invoking R.

Almost all R functions are automatically available for you. If the R functions have dots in the name,
you can call it with underscore from Perl instead, since Perl don't let you define a method with the
name containing dots.

=head1 METHODS

=over 4

=item new

This method creates a Statistics::embedR instance. But you can call it as many times as you
want, since it'll only keep one copy of the instance during the life time of the whole program. And you have
to call it at least once before you can call the other methods provided by this module.

=item eval LIST

This method executes a list of R statements sequentially given by LIST.

=item load LIST

This method loads a list of R libraries given by LIST.

=item R LIST

This method executes a list of R statements given by LIST, and return the value of the last statement in a
somewhat usefull way by some transformation, so that vector with the length 1 returns as a scalar, a vecotr
with the length other than 1 returns as a ARRAY reference, and other things returns as a HASH reference.

=item arry2R SRC, DEST

This method convert a ARRAY ref given by SRC to a R vector, whose name is given by DEST.

=back

=head1 AUTHOR

Hongwen Qiu, C<< <qiuhongwen at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-statistics-embedr at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-embedR>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Hongwen Qiu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

# vim: sw=4 ts=4 expandtab ft=perl
