package Sub::AliasedUnderscore;
use strict;
use warnings;

our $VERSION = 0.02;

use base 'Exporter';

our @EXPORT = ();
our @EXPORT_OK = qw/transform transformed/;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

=head1 NAME

Sub::AliasedUnderscore - transform a subroutine that operates on C<$_> into
one that operates on C<$_[0]>

=head1 SYNOPSIS

   use Sub::AliasedUnderscore qw/transform transformed/;

   my $increment = sub { $_++ };
   $increment = transform $increment;

   $_ = 1; 

   my $a = 41;
   $increment->($a); # returns 41
   # $a is now 42; $_ is still 1

   my $decrement = transformed { $_-- };
   $decrement->($a);
   # $a is now 41; $_ is still 1

=head1 DESCRIPTION

Often you'll want to accept a subroutine that operates on C<$_>, like
C<map> and C<grep> do.  The details of getting C<$_> to work that way
are inconvenient to worry about every time, so this module abstracts
that away.  Transform the subroutine that touches C<$_> with C<transform>,
and then treat it as though it is operating on C<$_[0]>.

=head1 EXPORT

Nothing by default.  If you want C<transform> or C<transformed>,
request them in the import list.

=head1 FUNCTIONS

=head2 transform($sub)

Transforms $sub to modify C<$_[0]> instead of C<$_>.  

This means you can write your subroutine as though it were the first
argument of C<map> or C<grep>, but execute it like C<$sub->($arg)>.

Everything works exactly the same as C<map> or C<grep> -- C<$_> is
localized, but aliased to whatever you call the subroutine with.  That
means that modifying C<$_> in C<$sub> will modify the argument passed
to the transformed sub, but won't touch the $_ that already exists.

It makes C<$_> DWIM.

=cut

sub transform($) {
    my $sub = shift;
    return sub {
        local *_ = \$_[0];
        $sub->();
    }
}

=head2 transformed BLOCK

Like C<transform>, but accepts a code block instead of a coderef:

  my $sub = transformed { do something to $_ }
  $sub->($a); # $a is $_ in the above block

=cut
  
sub transformed(&) {
    my $sub = shift;
    return transform($sub);
}

=head1 BUGS

None known; report to RT.

=head1 CODE

The repository is managed by git.  You can clone the repository with:

   git clone git://git.jrock.us/Sub-AliasedUnderscore

Patches welcome!

=head1 AUTHOR

Jonathan Rockway C<< jrockway@cpan.org >>

=head1 LICENSE

Copyright (c) 2007 Jonathan Rockway.  You may use, modify, and
distribute this code under the same conditions as Perl itself.

=cut

1;
