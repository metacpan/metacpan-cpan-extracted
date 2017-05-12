package RPC::ExtDirect::Demo::TestAction;

use strict;
use warnings;

use Carp;

use RPC::ExtDirect Action => 'TestAction';

sub doEcho : ExtDirect(1) {
    my ($class, $data) = @_;

    return $data;
}

sub multiply : ExtDirect(1) {
    my ($class, $num) = @_;

    croak "Call to multiply with a value that is not a number"
        unless $num =~ / \A \d+ \z /xms;

    return $num * 8;
}

sub getTree : ExtDirect(1) {
    my ($class, $id) = @_;

    return if length $id == 3;

    # Construct root node elements
    return [ map { { id => "n$_", text => "Node $_", leaf => \0 } } 1..5 ]
        if $id eq 'root';

    my ($parent) = $id =~ /n(\d)/;

    # Construct leaf node elements
    return [
        map { { id => "$id$_", text => "Node $parent.$_", leaf => \1 } } 1..5
    ];
}

sub getGrid : ExtDirect( params => [ 'sort' ] ) {
    my ($class, %params) = @_;

    my $field     = $params{sort}->[0]->{property};
    my $direction = $params{sort}->[0]->{direction};

    my $sort_sub = sub {
        my ($foo, $bar)         = $direction eq 'ASC' ? ($a, $b)
                                :                       ($b, $a)
                                ;
        return $field eq 'name' ? $foo->{name}     cmp $bar->{name} 
                                : $foo->{turnover} <=> $bar->{turnover}
                                ;
    };

    my @data = sort $sort_sub (
        { name => 'ABC Accounting',         turnover => 50000   },
        { name => 'Ezy Video Rental',       turnover => 106300  },
        { name => 'Greens Fruit Grocery',   turnover => 120000  },
        { name => 'Icecream Express',       turnover => 73000   },
        { name => 'Ripped Gym',             turnover => 88400   },
        { name => 'Smith Auto Mechanic',    turnover => 222980  },
    );

    return [ @data ];
}

sub showDetails : ExtDirect(params => [qw(firstName lastName age)]) {
    my ($class, %params) = @_;

    my $first = $params{firstName};
    my $last  = $params{lastName};
    my $age   = $params{age};

    return "Hi $first $last, you are $age years old.";
}

1;

=pod

=head1 NAME

RPC::ExtDirect::Demo::TestAction - Part of Ext.Direct interface demo

=head1 DESCRIPTION

This module implements TestAction class used in ExtJS Ext.Direct demo
scripts; it is not intended to be used per se but rather as an example.

I decided to keep it in the installation tree so that it will always
be available to look up without going to CPAN.

=head1 SEE ALSO

You can use C<perldoc -m RPC::ExtDirect::Demo::TestAction> to see the actual
code.

=head1 AUTHOR

Alexander Tokarev E<lt>tokarev@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011-2016 by Alexander Tokarev.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

=cut

