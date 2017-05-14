package MooseX::Types::LaxNum;

use strict;
use warnings;
use Moose::Util::TypeConstraints;
use Scalar::Util qw( looks_like_number );
# ABSTRACT: A LaxNum type which provides the loose behavior of Moose's Num pre-2.10

my $value_type = Moose::Util::TypeConstraints::find_type_constraint('Value');
subtype 'LaxNum'
    => as 'Str'
    => where { Scalar::Util::looks_like_number($_) }
=> inline_as {
    # the long Str tests are redundant here
    $value_type->_inline_check($_[1])
	. ' && Scalar::Util::looks_like_number(' . $_[1] . ')'
};

1;

__END__

=pod

=head1 NAME

MooseX::Types::LaxNum - A LaxNum type which provides the loose behavior of Moose's Num pre-2.10

=head1 VERSION

version 0.04

=head1 SYNOPSIS

   #!/usr/bin/env perl

   use strict;
   use warnings;

   package Foo {
       use Moose;
       use MooseX::Types::LaxNum;

       has 'laxnum', is => 'rw', isa => 'LaxNum';
   }

   my $foo = Foo->new( laxnum => '1234' );

=head1 DESCRIPTION

C<LaxNum> accepts everything for which L<Scalar::Util/looks_like_number> return true.
It can be used to get the old behaviour of C<Moose::Util::TypeConstraints::Num>,
since Num has been changed to be more strict.

=head1 NAME

MooseX::Types::LaxNum

=head1 COPYRIGHT & LICENSE

Copyright 2013 Upasana Shukla.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Upasana Shukla <me@upasana.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Upasana Shukla.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
