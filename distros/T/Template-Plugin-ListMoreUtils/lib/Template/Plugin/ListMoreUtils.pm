package Template::Plugin::ListMoreUtils;

use strict;
use warnings;

no strict 'refs';

use vars qw($VERSION @ISA);

use List::MoreUtils;
use Template::Plugin::Procedural;
use vars qw(@ISA $VERSION);

$VERSION = '0.03';
@ISA     = qw(Template::Plugin::Procedural);

=head1 NAME

Template::Plugin::ListMoreUtils - TT2 plugin to use List::MoreUtils

=head1 SYNOPSIS

  [% my1to9even = [ 2, 4, 6, 8 ];
     my1to9prim = [ 2, 3, 5, 7 ];
     my1to9odd  = [ 1, 3, 5, 7, 9 ]; %]

  [% USE ListMoreUtils %]
  [% my1to9all = ListMoreUtils.uniq( my1to9even.merge( my1to9prim, my1to9odd ) ); %]
  1 .. 9 are [% my1to9all.size() %]

=head1 DESCRIPTION

This module provides an Template::Toolkit interface to Tassilo von Parseval's
L<List::MoreUtils>. It extends the built-in functions dealing with lists as
well as L<Template::Plugin::ListUtil>.

=head1 USAGE

To use this module from templates, you can choose between class interface

  [% my1to9even = [ 2, 4, 6, 8 ];
     my1to9prim = [ 2, 3, 5, 7 ];
     my1to9odd  = [ 1, 3, 5, 7, 9 ]; %]

  [% USE ListMoreUtils %]
  [% my1to9all = ListMoreUtils.uniq( my1to9even.merge( my1to9prim, my1to9odd ) ); %]
  1 .. 9 are [% my1to9all.size() %]

or the virtual method interface, which is described in
L<Template::Plugin::ListMoreUtilsVMethods>.

=head1 FUNCTIONS PROVIDED

All functions behave as documented in L<List::MoreUtils>. I don't plan to
copy the entire POD from there.
L<Template::Toolkit> provides lists as list reference, so they were expanded
before the appropriate function in C<List::MoreUtils> is called.

=head2 any BLOCK LIST

=cut

sub any(&\@) { List::MoreUtils::any( \&{ $_[0] }, @{ $_[1] } ); }

=head2 all BLOCK LIST

=cut

sub all(&\@) { List::MoreUtils::all( \&{ $_[0] }, @{ $_[1] } ); }

=head2 none BLOCK LIST

=cut

sub none(&\@) { List::MoreUtils::none( \&{ $_[0] }, @{ $_[1] } ); }

=head2 notall BLOCK LIST

=cut

sub notall(&\@) { List::MoreUtils::notall( \&{ $_[0] }, @{ $_[1] } ); }

=head2 any_u BLOCK LIST

=cut

sub any_u(&\@) { List::MoreUtils::any_u( \&{ $_[0] }, @{ $_[1] } ); }

=head2 all_u BLOCK LIST

=cut

sub all_u(&\@) { List::MoreUtils::all_u( \&{ $_[0] }, @{ $_[1] } ); }

=head2 none_u BLOCK LIST

=cut

sub none_u(&\@) { List::MoreUtils::none_u( \&{ $_[0] }, @{ $_[1] } ); }

=head2 notall_u BLOCK LIST

=cut

sub notall_u(&\@) { List::MoreUtils::notall_u( \&{ $_[0] }, @{ $_[1] } ); }

=head2 true BLOCK LIST

=cut

sub true(&\@) { List::MoreUtils::true( \&{ $_[0] }, @{ $_[1] } ); }

=head2 false BLOCK LIST

=cut

sub false(&\@) { List::MoreUtils::false( \&{ $_[0] }, @{ $_[1] } ); }

=head2 firstidx BLOCK LIST

=head2 first_index BLOCK LIST

=cut

sub firstidx(&\@) { List::MoreUtils::firstidx( \&{ $_[0] }, @{ $_[1] } ); }
*first_index = *{'firstidx'}{CODE};

=head2 lastidx BLOCK LIST

=head2 last_index BLOCK LIST

=cut

sub lastidx(&\@) { List::MoreUtils::lastidx( \&{ $_[0] }, @{ $_[1] } ); }
*last_index = *{'lastidx'}{CODE};

=head2 onlyidx BLOCK LIST

=head2 only_index BLOCK LIST

=cut

sub onlyidx(&\@) { List::MoreUtils::onlyidx( \&{ $_[0] }, @{ $_[1] } ); }
*only_index = *{'onlyidx'}{CODE};

=head2 firstres BLOCK LIST

=head2 first_result BLOCK LIST

=cut

sub firstres(&\@) { List::MoreUtils::firstres( \&{ $_[0] }, @{ $_[1] } ); }
*first_result = *{'firstres'}{CODE};

=head2 lastres BLOCK LIST

=head2 last_result BLOCK LIST

=cut

sub lastres(&\@) { List::MoreUtils::lastres( \&{ $_[0] }, @{ $_[1] } ); }
*last_result = *{'lastres'}{CODE};

=head2 onlyres BLOCK LIST

=head2 only_result BLOCK LIST

=cut

sub onlyres(&\@) { List::MoreUtils::onlyres( \&{ $_[0] }, @{ $_[1] } ); }
*only_result = *{'onlyres'}{CODE};

=head2 firstval BLOCK LIST

=head2 first_value BLOCK LIST

=cut

sub firstval(&\@) { List::MoreUtils::firstval( \&{ $_[0] }, @{ $_[1] } ); }
*first_value = *{'firstval'}{CODE};

=head2 lastval BLOCK LIST

=head2 last_value BLOCK LIST

=cut

sub lastval(&\@) { List::MoreUtils::lastval( \&{ $_[0] }, @{ $_[1] } ); }
*last_value = *{'lastval'}{CODE};

=head2 onlyval BLOCK LIST

=head2 only_value BLOCK LIST

=cut

sub onlyval(&\@) { List::MoreUtils::onlyval( \&{ $_[0] }, @{ $_[1] } ); }
*only_value = *{'onlyval'}{CODE};

=head2 insert_after BLOCK VALUE LIST

=cut

*insert_after = *{'List::MoreUtils::insert_after'}{CODE} if ( defined( *{'List::MoreUtils::insert_after'}{CODE} ) );

=head2 insert_after_string STRING VALUE LIST

=cut

*insert_after_string = *{'List::MoreUtils::insert_after_string'}{CODE}
  if ( defined( *{'List::MoreUtils::insert_after_string'}{CODE} ) );

=head2 apply BLOCK LIST

=cut

sub apply(&\@) { List::MoreUtils::apply( \&{ $_[0] }, @{ $_[1] } ); }

=head2 after BLOCK LIST

=cut

sub after(&\@) { List::MoreUtils::after( \&{ $_[0] }, @{ $_[1] } ); }

=head2 after_incl BLOCK LIST

=cut

sub after_incl(&\@) { List::MoreUtils::after_incl( \&{ $_[0] }, @{ $_[1] } ); }

=head2 before BLOCK LIST

=cut

sub before(&\@) { List::MoreUtils::before( \&{ $_[0] }, @{ $_[1] } ); }

=head2 before_incl BLOCK LIST

=cut

sub before_incl(&\@) { List::MoreUtils::before_incl( \&{ $_[0] }, @{ $_[1] } ); }

=head2 indexes BLOCK LIST

=cut

sub indexes(&\@) { List::MoreUtils::indexes( \&{ $_[0] }, @{ $_[1] } ); }

=head2 pairwise BLOCK LIST LIST

Unlike the original C<pairwise>, both variables are given through C<@_>.
Template::Toolkit uses eval to evaluate the perl code declared there and
passes neither C<$a> nor C<$b> (which sounds reasonable to me).

=cut

sub pairwise(&\@\@)
{
    my $userfn = $_[0];
    List::MoreUtils::pairwise( sub { &{$userfn}( $a, $b ); }, @{ $_[1] }, @{ $_[2] } );
}

=head2 minmax LIST

=cut

sub minmax(\@) { List::MoreUtils::minmax( @{ $_[0] } ); }

=head2 uniq LIST

=head2 distinct LIST

=cut

sub uniq(\@) { List::MoreUtils::uniq( @{ $_[0] } ); }
*distinct = *{'uniq'}{CODE};

=head2 singleton LIST

=cut

sub singleton(\@) { List::MoreUtils::singleton( @{ $_[0] } ); }

=head2 mesh

=head2 zip

=cut

*mesh = *{'List::MoreUtils::mesh'}{CODE} if ( defined( *{'List::MoreUtils::mesh'}{CODE} ) );
*zip  = *{'List::MoreUtils::zip'}{CODE}  if ( defined( *{'List::MoreUtils::zip'}{CODE} ) );

=head2 part BLOCK LIST

=cut

sub part(&\@) { List::MoreUtils::part( \&{ $_[0] }, @{ $_[1] } ) }

=head2 bsearch BLOCK LIST

=cut

sub bsearch(&\@)
{
    my $user_fn = $_[0];
    List::MoreUtils::bsearch( sub { $user_fn->($_) }, @{ $_[1] } );
}

=head2 bsearchidx BLOCK LIST

=head2 bsearch_index BLOCK LIST

=cut

sub bsearchidx(&\@)
{
    my $user_fn = $_[0];
    List::MoreUtils::bsearchidx( sub { $user_fn->($_) }, @{ $_[1] } );
}
*bsearch_index = *{'bsearchidx'}{CODE};

=head1 LIMITATION

Except the typical limitations known from perl functions embedded in
L<Template::Toolkit>, the only limitation I currently miss is being
able to use TT2 defined macros as callback.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-Template-Plugin-ListMoreUtils at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-ListMoreUtils>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Plugin::ListMoreUtils

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Plugin-ListMoreUtils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Plugin-ListMoreUtils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Plugin-ListMoreUtils>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Plugin-ListMoreUtils/>

=back

Business and commercial support should be acquired via preferred freelancer
agencies.

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2015 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

perl(1), L<List::MoreUtils>, <Template::Plugin::ListUtil>

=cut

1;
