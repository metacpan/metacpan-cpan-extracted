package Simple::Tuple;

use 5.006;
use strict;
use warnings;
use Carp;

=head1 NAME

Simple::Tuple - Because tuples should be simple and simple to use!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Tuples should simple to use and create so I created a simple tuple generator.

To create a tuple just use Simple::Tuple and include a list of the name of the tuple and elements of the tuple.
The Simple::Tuple will automatically create a class and getters and setters for the elements.
example:
use Simple::Tuple qw<Pair first second>;

will create a class called Pair with getters get_first, get_second and setters set_first, set_second.

code snippet demostrating Simple::Tuple.

 #! /usr/bin/env perl

 use warnings;
 use strict;
 use utf8;
 use feature qw<say>;
 use Data::Dumper;
 use Simple::Tuple qw<Pair first second>;
 use Simple::Tuple qw<Node left data right>;

 my $p = Pair->new(1, 2,);
 my $n = Node->new(4, 5, 6,);

 say Dumper($p);
 say Dumper($n);

 say $p->get_first;
 say $p->get_second;

 say $n->get_left;
 say $n->get_data;
 say $n->get_right;

 $p->set_first(11);
 $p->set_second(12);

 $n->set_left(14);
 $n->set_data(15);
 $n->set_right(16);

 say $p->get_first;
 say $p->get_second;

 say $n->get_left;
 say $n->get_data;
 say $n->get_right;

 exit 0;
    
=head1 EXPORT

No functions are exported.

=head1 SUBROUTINES/METHODS

=head2 import

=cut

sub import {
    my (undef, $name, @funcs) = @_;
    return if !defined $name;
    no strict qw<refs>;
    *{"${name}::new"} = sub {
        my (undef, @v) = @_;
        my $c = @funcs;
        croak "Data structure($name) has $c elements(@funcs) but you entered(@v)" if @v != @funcs;
        bless \@v, $name
    };
    while (my ($i, $f) = each @funcs) {
        *{"${name}::get_${f}"} = sub{my ($s) = @_; $s->[$i]};
        *{"${name}::set_${f}"} = sub{my ($s, $d) = @_; $s->[$i] = $d};
    }
}

=head1 AUTHOR

Gerard Gauthier, C<< <gerard4143 at hotmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-simple-tuple at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Simple-Tuple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Simple::Tuple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Simple-Tuple>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Simple-Tuple>

=item * Search CPAN

L<https://metacpan.org/release/Simple-Tuple>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Gerard Gauthier.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Simple::Tuple
