package Template::Declare::TagSet;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors(
    qw{ namespace package }
);

sub get_alternate_spelling {
    undef;
}

sub get_tag_list {
    [];
}

# specify whether "<tag></tag>" can be combined to "<tag />"
sub can_combine_empty_tags {
    1;
}

1;
__END__

=head1 NAME

Template::Declare::TagSet - Base class for tag sets used by Template::Declare::Tags

=head1 SYNOPSIS

    package My::TagSet;
    use base 'Template::Declare::TagSet';

    # returns an array ref for the tag names
    sub get_tag_list {
        [ qw(
            html body tr td table
            base meta link hr
        )]
    }

    # prevents potential naming conflicts:
    sub get_alternate_spelling {
        my ($self, $tag) = @_;
        return 'row'  if $tag eq 'tr';
        return 'cell' if $tag eq 'td';
    }

    # Specifies whether "<tag></tag>" can be
    # combined to "<tag />":
    sub can_combine_empty_tags {
        my ($self, $tag) = @_;
        $tag =~ /^ (?: base | meta | link | hr ) $/x;
    }

=head1 DESCRIPTION

Template::Declare::TagSet is the base class for declaring packages of
Template::Delcare tags. If you need to create new tags for use in your
templates, this is the base class for you! Review the source code of
L<Template::Declare::TagSet::HTML|Template::Declare::TagSet::HTML> for a
useful example.

=head1 METHODS

=head2 new( PARAMS )

    my $tag_set = Template::Declare::TagSet->new({
        package   => 'Foo::Bar',
        namespace => undef,
    });

Constructor created by C<Class::Accessor::Fast>, accepting an optional hash
reference of parameters.

=head2 get_tag_list

    my $list = $tag_set->get_tag_list();

Returns an array ref for the tag names offered by a tag set.

=head2 get_alternate_spelling( TAG )

    $bool = $obj->get_alternate_spelling($tag);

Returns true if a tag has an alternative spelling. Basically it provides a way
to work around naming conflicts. For example, the C<tr> tag in HTML conflicts
with Perl's C<tr> operator, and the C<template> tag in XUL conflicts with the
C<template> sub exported by C<Template::Declare::Tags>.

=head2 can_combine_empty_tags( TAG )

    $bool = $obj->can_combine_empty_tags($tag);

Specifies whether C<< <tag></tag> >> can be combined into a single token,
C<< <tag /> >>. By default, all tags can be combined into a single token;
override in a subclass to change this value where appropriate. For example,
C<< Template::Declare::TagSet::HTML->can_combine_empty_tags('img') >> returns
true since C<< <img src="..." /> >> is always required for HTML pages.
C<< Template::Declare::TagSet::HTML->can_combine_empty_tags('script') >>, on
the other hand, returns false, since some browsers can't handle a single
script token.

=head1 ACCESSORS

This class has two read-only accessors:

=head2 package

    my $package = $obj->package();

Retrieves the value of the C<package> option set via the constructor.

=head2 namespace

    my $namespace = $obj->namespace();

Retrieves the value of the C<namespace> option set via the constructor.

=head1 AUTHOR

Agent Zhang <agentzh@yahoo.cn>.

=head1 SEE ALSO

L<Template::Declare::TagSet::HTML>, L<Template::Declare::TagSet::XUL>, L<Template::Declare::Tags>,
L<Template::Declare>.

