package Template::Iterator::AlzaboWrapperCursor;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = 0.01;

use base qw( Template::Iterator );
use Template::Constants;


# The majority of this code is copied and slightly altered from
# Template::Plugin::DBI::Iterator, in Template/Plugin/DBI.pm

sub new {
    my $class = shift;
    my $cursor = shift;

    return bless {
        cursor  => $cursor,
        # Template::Iterator expects these fields to exist, but we
        # should not need to use them
        SIZE    => undef,
        MAX     => undef,
    }, $class;
}

sub get_first {
    my $self = shift;
    $self->{_STARTED} = 1;

    @$self{ qw(  PREV   ITEM FIRST LAST COUNT INDEX ) }
            = ( undef, undef,    2,   0,    0,   -1 );

    # get the first row
    $self->_next();

    return $self->get_next();
}

sub get_next {
    my $self = shift;

    $self->{INDEX}++;
    $self->{COUNT}++;

    $self->{FIRST}-- if $self->{FIRST};

    my $row = $self->{NEXT};
    return ( undef, Template::Constants::STATUS_DONE )
	unless $row;

    $self->{PREV} = $self->{ITEM};

    $self->_next();

    $self->{ITEM} = $row;

    return ( $row, Template::Constants::STATUS_OK );
}

sub get_all {
    my $self = shift;

    $self->{ LAST } = 1;
    $self->{ NEXT } = undef;

    return ( [ $_[0]->{cursor}->all ], Template::Constants::STATUS_OK );
}

sub _next {
    my $self = shift;

    my %rows = $self->{cursor}->next_as_hash;

    unless ( keys %rows ) {
	$self->{LAST} = 1;
	$self->{NEXT} = undef;

	return;
    }

    if ( keys %rows == 1 ) {
        $self->{NEXT} = (values %rows)[0];
    }
    else {
        for my $k ( keys %rows ) {
            ( my $lc_key = $k ) =~ s/(^|.)([A-Z])/$1 ? "$1\L_$2" : "\L$2"/ge;
            $rows{$lc_key} = delete $rows{$k};
        }

        $self->{NEXT} = \%rows;
    }

    return;
}


1;

__END__

=head1 NAME

Template::Iterator::AlzaboWrapperCursor - Turns a Class::AlzaboWrapper::Cursor object into a TT2 iterator

=head1 SYNOPSIS

  my $users =
      Template::Iterator::AlzaboWrapperCursor->new($cursor);
  # pass $users to a template

  my $users_with_pages =
      Template::Iterator::AlzaboWrapperCursor->new($users_with_pages);

In a template:

  [% FOREACH user = users %]
    Name: [% user.name %]<br />
  [% END %]

  [% FOREACH user_with_page = users_with_pages %]
    [% user_with_page.user.name %]: [% user_with_page.page.title %]
  [% END %]

=head1 DESCRIPTION

This module allows a C<Class::AlzaboWrapper::Cursor> object to be used
as a TT2 iterator.

=head1 USAGE

For a cursor which returns one object at a time, the iterator simply
returns one object per iteration. When the cursor returns multiple
objects, the iterator returns a hash reference where the keys are the
table name of the object's class in lower-case, with camel-casing
turned into underscores. The values of the hash are the objects.

So if the cursor returns C<Foo::User> and C<Foo::Page> objects, the
keys are "user" and "page".

=head1 METHODS

This class provides the following methods:

=head2 new($cursor)

This method accepts a C<Class::AlzaboWrapper::Cursor> object and
returns an iterator suitable for use in TT2 templates.

=head1 WISHLIST

I wish that TT2 allowed multiple assignment in C<FOREACH> loops so we
could just do this:

  [% FOREACH user, page = users_with_pages %]

That's so much cleaner.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

Initially written for Socialtext, Inc.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-template-iterator-alzabowrappercursor@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
