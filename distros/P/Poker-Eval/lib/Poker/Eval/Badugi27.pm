package Poker::Eval::Badugi27;
use Moo;

=head1 NAME

Poker::Eval::Badugi27 - Evaluate and score Badeucy poker hands. 

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';


=head1 SYNOPSIS

Used in the game of Badeucy. See Poker::Eval for code examples. 

=head1 INTRODUCTION

Normally the lowest Badugi is A-2-3-4. However, in Badeucy aces are also high for the Badugi hand. This makes the best Badugi hand 2-3-4-5

=cut

extends 'Poker::Eval::Badugi';

=head1 AUTHOR

Nathaniel Graham, C<< <ngraham at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Nathaniel Graham.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
