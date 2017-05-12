package Template::Plugin::Lingua::EN::NameCase;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = 0.02;

use base qw(Template::Plugin);
use Template::Plugin;
use Template::Stash;
use Lingua::EN::NameCase qw( nc );

$Template::Stash::SCALAR_OPS->{'nc'} = \&_nc;

sub new {
    my ($class, $context, $options) = @_;

    # now define the filter and return the plugin
    $context->define_filter('nc', \&_nc);
    return bless {}, $class;
}

sub _nc {
    my $options = ref $_[-1] eq 'HASH' ? pop : {};
    return nc(join('', @_));
}

1;

__END__

=head1 NAME

Template::Plugin::Lingua::EN::NameCase - TT2 interface to Lingua::EN::NameCase module

=head1 SYNOPSIS

  [% USE Lingua.EN.NameCase -%]
  [% checksum = content FILTER nc -%]
  [% checksum = content.nc -%]

=head1 DESCRIPTION

The I<Lingua::EN::NameCase> Template Toolkit plugin provides access to the
Lingua::EN::NameCase module functions, to translate number values to their
names.

When you invoke

  [% USE Lingua.EN.NameCase %]

the following filters (and vmethods of the same name) are installed
into the current context:

=over 4

=item C<nc>

Converts a fraction (such as 3/4) into English text (such as "three quarters").

=back

=head1 SEE ALSO

L<Lingua::EN::NameCase>, L<Template>, C<Template::Plugin>

=head1 AUTHOR

  Barbie <barbie@cpan.org>  2014

=head1 COPYRIGHT & LICENSE

Copyright (C) 2014-2015 Barbie for Miss Barbell Productions.

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut
