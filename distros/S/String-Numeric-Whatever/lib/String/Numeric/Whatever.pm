package String::Numeric::Whatever;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.03";

require Tie::Scalar;
our @ISA = qw(Tie::StdScalar);

use overload (
    '<=>' => \&compareAny,
    'cmp' => \&compareAny,
    '""'  => sub { $_[0]->FETCH() . '' },
    '0+'  => sub { $_[0]->FETCH() + 0 },
);

sub compareAny {
    no warnings;
    my $self = shift;
    return ( $_[0] ^ $_[0] ) eq '0'
        ? $self->FETCH() <=> $_[0]
        : $self->FETCH() cmp $_[0];
}

1;
__END__

=encoding utf-8

=head1 NAME

String::Numeric::Whatever - It's a test implement to
B<ignore> the difference between C<E<lt>=E<gt>> and C<cmp> 

=head1 SYNOPSIS

 use String::Numeric::Whatever;
 my $str = String::Numeric::Whatever->new('strings');

 say q|Succeeded in comparing with strings by 'eq'| if $str eq 'strings';            
 say q|Succeeded in comparing with Int by 'ne'|     if $str ne 100;            
 say q|Succeeded in comparing with Int by '!='|     if $str != 100;
 say q|Succeeded in comparing with strings by '=='| if $str == 'strings';
           
=head1 DESCRIPTION

=head2 INTRODUCE

If you have knowledge of other language, You may think like that.

I<Why strings can't be compared with using C<==>?>

I can't answer the reason why, but can give you this module.

It provides us comparable object with using C<==>, C<eq> or whatever!

=head2 CONSTRUCTORS

I'm sorry that you have to call constructors
before getting the benefits of this module.

=head3 new()

There is no validation. accepts all types of SCALAR

 my $str = String::Numeric::Whatever->new('strings');
 my $num = String::Numeric::Whatever->new(1234);

=head3 tie()

or you can set like this:

 tie my $str => 'String::Numeric::Whatever', 'strings';
 tie my $num => 'String::Numeric::Whatever', 1234;

=head2 THEN

Now you can compare the values with using any operators in below:

 < <= > >= == != <=>
 lt le gt ge eq ne cmp

After you assigned the constructors,
you don't have to care about whatever this is a string or number.

So you can write like below without warnings:

 say $str if $str == 'string';   # strings 
 say $num if $num ne 0;          # 1234 

=head1 LICENSE

Copyright (C) worthmine.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

L<Yuki Yoshida(worthmine)|https://github.com/worthmine>

=cut
