package Module::Changes;

use warnings;
use strict;


our $VERSION = '0.05';


# inherit from Module::Changes::Base first so we get our constructor

use base qw(Module::Changes::Base Class::Factory::Enhanced);


__PACKAGE__->add_factory_type(
    entire         => 'Module::Changes::Entire',
    release        => 'Module::Changes::Release',
    formatter_yaml => 'Module::Changes::Formatter::YAML',
    formatter_free => 'Module::Changes::Formatter::Free',
    parser_yaml    => 'Module::Changes::Parser::YAML',
    parser_free    => 'Module::Changes::Parser::Free',
    validator_yaml => 'Module::Changes::Validator::YAML',
);


1;

__END__

=head1 NAME

Module::Changes - Machine-readable Changes file

=head1 SYNOPSIS

  use Module::Changes;
  my $release = Module::Changes->make_object_for_type('release');

=head1 DESCRIPTION

If you are looking for an overview of what C<Module-Changes> is about, see the
documentation of the C<changes> program.

This class is the heart of the Module-Changes distribution. It is a factory
that can make relevant objects.

You can subclass this module to change its mappings. For example, if you write
a new YAML parser, you can set it as the object constructed for the
C<formatter_yaml> factory type. See L<Class::Factory::Enhanced> for more
information.

This is the place to document a few assumptions that L<Module-Changes> makes.

The terms I<revision>, I<version>, I<subversion> and I<alpha> are used in the
other modules' documentation. The meanings are taken directly from
L<Perl::Version>. For example, in the version number C<v1.02.03_04>, the
revision is C<1>, the version is C<02>, the subversion is C<03> and the alpha
is C<04>.

The layout of the YAML file is best demonstrated by an example:

    global:
      name: Foo-Bar
    releases:
      - v0.03:
          author: Marcel Gruenauer <marcel@cpan.org>
          date: 2008-02-15T14:23:12-05:00
          changes:
            - Complete rewrite
          tags:
            - APICHANGE
      - v0.02:
          author: Marcel Gruenauer <marcel@cpan.org>
          date: 2008-02-15T13:50:05-05:00
          changes:
            - Added this
            - Changed that
          tags:
            - MINOR
            - SECURITY
      - v0.01:
          author: Marcel Gruenauer <marcel@cpan.org>
          date: 2008-01-29T09:46:20-05:00
          changes:
            - Initial release

The file starts with a declaration of global attributes. At the moment there
is only one such attribute - the distribution name.

This is followed by any number of releases. Each release is a hash that has
the version number (in L<Perl::Version> notation) as the key and the release
details as the value.

The releases are within an array so that the order is preserved - within a
hash, the order is not guaranteed.

The release details are another hash, having keys for author and date, an
array of change strings and an array of tag strings. The date is in
L<DateTime::Format::W3CDTF> format.

This layout has been chosen so as to appear natural, with a sufficient amount
of machine-readable information, without being overburdened by details that no
one would maintain anyway.

=head1 BACKGROUND

There has been some discussion about a machine-readable Changes file.

See http://use.perl.org/article.pl?sid=07/09/06/0324215 and
http://use.perl.org/~miyagawa/journal/34850.

I'm maintaining a few distributions myself and have phases of making some
changes to several distributions. Opening the Changes file, copying a few
lines, inserting the current date and time and so on gets tedious.

I wanted to have a command-line tool with which to interact with Changes
files. Also the Changes file should be machine-readable. So I wrote
Module-Changes. I've chosen YAML for the format, although this is by no means
mandatory - it's easy to write a new parser or formatter for your format of
choice. Integration of new parsers, formatters etc. is something I still have
to work on, though.

Some see YAML as a I<failed format>, but enough people (me included) find it
useful and easy to read for both humans and machines, so that's what I've
chosen as the default format. Even so, we need to agree on a YAML schema -
that is, the layout of the Changes file.

This is not set in stone, it's more of a proposal. I'm hoping for a discussion
of what people like or don't like in the current version, and what they would
like to see in future versions.

=head1 TODO

Integrity check with regard to version numbers and timestamps.

=head1 TAGS

If you talk about this module in blogs, on del.icio.us or anywhere else,
please use the C<modulechanges> tag.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-module-changes@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see <http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

=head1 AUTHOR

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

