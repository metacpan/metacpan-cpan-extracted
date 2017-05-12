package Template::Plugin::HashMergeVMethods;

use strict;
use warnings;

use vars qw($VERSION @ISA $VMETHOD_PACKAGE @HASH_OPS);

use Template::Plugin::VMethods;
use Template::Plugin::HashMerge;

$VERSION = '0.01';
@ISA = qw(Template::Plugin::VMethods);
$VMETHOD_PACKAGE = 'Template::Plugin::HashMerge';

@HASH_OPS = qw(merge);

=head1 NAME

Template::Plugin::HashMergeVMethods - virtual methods for TT2 hashes to merge them

=head1 SYNOPSIS

  [% USE HashMerge %]
  [% USE HashMergeVMethods %]
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
     c = a.merge( b ); %]

=head1 DESCRIPTION

L<Template::Toolkit> plugin HashMergeVMethods provides the L<Hash::Merge>
functions C<merge> and C<set_behaviour> to be used within templates as
virtual methods of hashes.

This can be useful in all cases a template works directly on data - e.g.
when processing results from a query using L<Template::DBI> and join the
result with results from derived queries.

=head1 USAGE

  [% USE HashMerge %]
  [% USE HashMergeVMethods %]
  [% HashMerge.set_behaviour( <behaviour name> );
     result = hash1.merge( hash2 ); %]

Detailed function description and default behaviours are available in
L<Hash::Merge>.

If you prefer to use object methods, see L<Template::Plugin::HashMerge>.

=head1 FUNCTIONS PROVIDED

=head2 merge

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

perl(1), L<Template::Toolkit>, L<Template::Plugin::VMethods>

=cut

1;
