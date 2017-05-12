package Template::Plugin::HashMerge;

use strict;
use warnings;

require Template::Plugin::Procedural;
use Hash::Merge;

use vars qw($VERSION @ISA);
$VERSION = '0.01';
@ISA     = qw(Template::Plugin::Procedural);

=head1 NAME

Template::Plugin::HashMerge - TT2 plugin to use Hash::Merge

=head1 SYNOPSIS

  [% USE HashMerge %]
  [% a = {
             foo => 1,
             bar => [ 'a', 'b', 'e' ],
             baz => {
                        bob => 'alice',
                    },
         };
     b = {
             foo => 2,
             bar => [ 'c', 'd' ],
             baz => {
                        ted => 'margeret',
                    },
         };
     HashMerge.set_behaviour( 'RIGHT_PRECEDENT' );
     c = HashMerge.merge( a, b ); %]

=head1 DESCRIPTION

L<Template::Toolkit> plugin HashMerge provides the L<Hash::Merge> functions
C<merge> and C<set_behaviour> to be used within templates.

This can be useful in all cases a template works directly on data - e.g.
when processing results from a query using L<Template::DBI> and join the
result with results from derived queries.

=head1 USAGE

  [% USE HashMerge %]
  [% HashMerge.set_behaviour( <behaviour name> );
     result = HashMerge.merge( hash1, hash2 ); %]

Detailed function description and default behaviours are available in
L<Hash::Merge>.

If you prefer to use virtual hash methods, see L<Template::Plugin::HashMergeVMethods>.

=head1 FUNCTIONS PROVIDED

=head2 merge

=head2 get_behavior

=head2 set_behavior

=head2 specify_behavior

=cut

no strict 'refs';

*merge = *{'Hash::Merge::merge'}{CODE} if( defined( *{'Hash::Merge::merge'}{CODE} ) );
*get_behavior = *{'Hash::Merge::get_behavior'}{CODE} if( defined( *{'Hash::Merge::get_behavior'}{CODE} ) );
*set_behavior = *{'Hash::Merge::set_behavior'}{CODE} if( defined( *{'Hash::Merge::set_behavior'}{CODE} ) );
*specify_behavior = *{'Hash::Merge::specify_behavior'}{CODE} if( defined( *{'Hash::Merge::specify_behavior'}{CODE} ) );

=head1 INSTALL

To install this module, use

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 BUGS & LIMITATIONS

None known.

=head1 SUPPORT

Free support can be requested via regular CPAN bug-tracking system. There is
no guaranteed reaction time or solution time. It depends on business load.
That doesn't mean that ticket via rt aren't handles as soon as possible,
that means that soon depends on how much I have to do.

Business and commercial support should be aquired via preferred freelancer
agencies.

=head1 AUTHOR

    Jens Rehsack
    CPAN ID: REHSACK
    rehsack@cpan.org
    http://search.cpan.org/~rehsack/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1), L<Template::Toolkit>

=cut

1;

