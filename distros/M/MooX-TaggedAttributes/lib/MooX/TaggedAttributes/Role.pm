package MooX::TaggedAttributes::Role;

# ABSTRACT: "Parent" Tag Role

## no critic
our $VERSION = '0.15';
## use critic

use MRO::Compat;

use Scalar::Util           ();
use MooX::TaggedAttributes ();
use Sub::Name              ();

# Moo::Role won't compose anything before it was used into a consuming
# package.
use Moo::Role;

# sub import;
# *import = \&MooX::TaggedAttributes::import;

my $maybe_next_method = sub { ( shift )->maybe::next::method };

# this modifier is run once for each composition of a tag role into
# the class.  role composition is orthogonal to class inheritance, so we
# need to carefully handle both

# see http://www.nntp.perl.org/group/perl.moose/2015/01/msg287{6,7,8}.html,
# but note that djerius' published solution was incomplete.
around _tag_list => sub {

# 1. call &$orig to handle tag role compositions into the current class
# 2. call up the inheritance stack to handle parent class tag role compositions.

    my $orig    = shift;
    my $package = caller;

    # create the proper environment context for next::can
    my $code
      = Sub::Name::subname( "${package}::_tag_list" => $maybe_next_method );
    my $next = $_[0]->$code;

    return [ @{&$orig}, $next ? @{$next} : () ];
};


# _tags can't be lazy; we must resolve the tags and attributes at
# object creation time in case a role is modified after this object
# is created, as we scan both clsses and roles to gather the tags.
# classes should be immutable after the first instantiation
# of an object (but see RT#101631), but roles aren't.

# We also need to identify when a role has been added to an *object*
# which adds tagged attributes.  TODO: make this work.

# this is where all of the tags get stored while a class is being
# built up.  eventually they are condensed into a simple hash via
# _build_cache

sub _tag_list { [] }














sub _tags {
    my $class = Scalar::Util::blessed $_[0];

    # called as an object method?
    if ( defined $class ) {
        return $MooX::TaggedAttributes::TAGCACHE{$class}
          //= MooX::TaggedAttributes::Cache->new( $class );
    }

    else {
        $class = $_[0];
        return $MooX::TaggedAttributes::TAGCACHE{$class}
          // MooX::TaggedAttributes::Cache->new( $class );
    }

}

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

MooX::TaggedAttributes::Role - "Parent" Tag Role

=head1 VERSION

version 0.15

=head1 SUBROUTINES

=head2 _tags

  $tag_object = $class->_tags;
  $tag_object = object->_tags;

Return the tags.

If this is the first time this has been called as an object method,
the tag object will be cached for future use, otherwise it is newly
constructed from L</tag_list()>.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-moox-taggedattributes@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-TaggedAttributes

=head2 Source

Source is available at

  https://gitlab.com/djerius/moox-taggedattributes

and may be cloned from

  https://gitlab.com/djerius/moox-taggedattributes.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooX::TaggedAttributes|MooX::TaggedAttributes>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
