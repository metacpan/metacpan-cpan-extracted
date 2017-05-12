use strict;
package Template::Plugin::Class;
use base 'Template::Plugin';
use vars qw( $VERSION );
$VERSION = '0.14';

sub new {
    my $class = shift;
    my $context = shift;
    my $arg = shift;

    # stolen from base.pm
    eval "require $arg";
    # Only ignore "Can't locate" errors from our eval require.
    # Other fatal errors (syntax etc) must be reported.
    (my $filename = $arg) =~ s!::!/!g;
    die if $@ && $@ !~ /Can't locate \Q$filename\E\.pm/;
    no strict 'refs';
    unless (%{"$arg\::"}) {
        require Carp;
        Carp::croak("Package \"$arg\" is empty.\n",
                    "\t(Perhaps you need to 'use' the module ",
                    "which defines that package first.)");
    }

    return bless \$arg, 'Template::Plugin::Class::Proxy';
}

package Template::Plugin::Class::Proxy;
use vars qw( $AUTOLOAD );

sub AUTOLOAD {
    my $self = shift;
    my $class = ref $self;
    my ($method) = ($AUTOLOAD =~ /^$class\::(.*)/);
    $$self->$method(@_);
}

sub DESTROY {}

1;
__END__

=head1 NAME

Template::Plugin::Class - allow calling of class methods on arbitrary classes

=head1 SYNOPSIS

  [% USE foo = Class('Foo') %]
  [% foo.bar %]

=head1 DESCRIPTION

Template::Plugin::Class allows you to call class methods on
arbitrary classes.  One use for this is in Class::DBI style
applications, where you may do somthing like this:

  [% USE cd = Class('Music::CD') %]
  [% FOREACH disc = cd.retrieve_all %]
  [% disc.artist %] - [% disc.title %]
  [% END %]

=head1 CAVEATS

You won't be able to directly call C<AUTOLOAD> or C<DESTROY> methods
on the remote class.  This shouldn't be a huge hardship.

=head1 BUGS

Apart from the mentioned caveat, none currently known.  If you find
any please contact the author.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright (C) 2003, 2004, 2006, 2009 Richard Clamp.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>

=cut

