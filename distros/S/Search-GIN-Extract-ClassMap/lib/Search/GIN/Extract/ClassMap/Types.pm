use 5.006;    # our
use strict;
use warnings;

package Search::GIN::Extract::ClassMap::Types;

# ABSTRACT: Types for Search::GIN::Extract::ClassMap, mostly for coercing.

our $VERSION = '1.000003';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use MooseX::Types::Moose qw( :all );
use MooseX::Types -declare => [
  qw[
    IsaClassMap
    DoesClassMap
    LikeClassMap
    Extractor
    CoercedClassMap
    ],
];













## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)
class_type IsaClassMap, { class => 'Search::GIN::Extract::ClassMap::Isa' };

coerce IsaClassMap, from HashRef, via {
  require Search::GIN::Extract::ClassMap::Isa;
  'Search::GIN::Extract::ClassMap::Isa'->new( classmap => $_ );
};













class_type DoesClassMap, { class => 'Search::GIN::Extract::ClassMap::Does' };

coerce DoesClassMap, from HashRef, via {
  require Search::GIN::Extract::ClassMap::Does;
  'Search::GIN::Extract::ClassMap::Does'->new( classmap => $_ );
};













class_type LikeClassMap, { class => 'Search::GIN::Extract::ClassMap::Like' };

coerce LikeClassMap, from HashRef, via {
  require Search::GIN::Extract::ClassMap::Like;
  'Search::GIN::Extract::ClassMap::Like'->new( classmap => $_ );
};





















subtype Extractor, as Object, where {
  $_->does('Search::GIN::Extract')
    or $_->isa('Search::GIN::Extract');
};

coerce Extractor, from ArrayRef [Str], via {
  require Search::GIN::Extract::Attributes;
  Search::GIN::Extract::Attributes->new( attributes => $_ );

};
coerce Extractor, from CodeRef, via {
  require Search::GIN::Extract::Callback;
  Search::GIN::Extract::Callback->new( extract => $_ );
};


















subtype CoercedClassMap, as HashRef, where {
  for my $v ( values %{$_} ) {
    return unless is_Extractor($v);
  }
  return 1;
}, message {
  for my $k ( keys %{$_} ) {
    next if is_Extractor( $_->{$k} );
    return "Key $k in the hash expected Search::GIN::Extract implementation";
  }
};

coerce CoercedClassMap, from HashRef, via {
  my $newhashref = {};
  my $old        = $_;
  for my $key ( keys %{$old} ) {
    $newhashref->{$key} = to_Extractor( $old->{$key} );
  }
  return $newhashref;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::GIN::Extract::ClassMap::Types - Types for Search::GIN::Extract::ClassMap, mostly for coercing.

=head1 VERSION

version 1.000003

=head1 TYPES

=head2 C<IsaClassMap>

=over 4

=item C<class_type> : L<< C<::ClassMap::Isa>|Search::GIN::Extract::ClassMap::Isa >>

=item C<coerces_from>: C<HashRef>

=back

=head2 C<DoesClassMap>

=over 4

=item C<class_type>: L<< C<::ClassMap::Does>|Search::GIN::Extract::ClassMap::Does >>

=item coerces from: C<HashRef>

=back

=head2 C<LikeClassMap>

=over 4

=item C<class_type>: L<< C<::ClassMap::Like>|Search::GIN::Extract::ClassMap::Like >>

=item coerces from: C<HashRef>

=back

=head2 C<Extractor>

Mostly here to identify things that derive from L<< C<Search::GIN::Extract>|Search::GIN::Extract >>

=over 4

=item C<subtype>: C<Object>

=item coerces from: C<ArrayRef[ Str ]>

Coerces into a L<< C<::Extract::Attributes>|Search::GIN::Extract::Attributes >> instance.

=item coerces from: C<CodeRef>

Coerces into a L<< C<::Extract::Callback>|Search::GIN::Extract::Callback >> instance.

=back

=head2 C<CoercedClassMap>

This is here to implement a ( somewhat hackish ) semi-deep recursive coercion.

Ensures all keys are of type L</Extractor> in order to be a valid C<HashRef>,
and coerces to L</Extractor>'s where possible.

=over 4

=item C<subtype>: C<HashRef[ Extractor ]>

=item coerces from: C<HashRef[ coerce Extractor ]>

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
