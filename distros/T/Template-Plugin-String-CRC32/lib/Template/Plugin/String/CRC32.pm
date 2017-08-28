package Template::Plugin::String::CRC32;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.03";

use base qw(Template::Plugin);
use Template::Plugin;
use Template::Stash;
use String::CRC32;

$Template::Stash::SCALAR_OPS->{'crc32'} = \&_crc32;

sub new {
    my ($class, $context, $options) = @_;

    # now define the filter and return the plugin
    $context->define_filter('crc32', \&_crc32);
    return bless {}, $class;
}

sub _crc32 {
    my $options = ref $_[-1] eq 'HASH' ? pop : {};
    return crc32(join('', @_));
}

1;
__END__

=encoding utf-8

=head1 NAME

Template::Plugin::String::CRC32 - L<Template::Toolkit> plugin-wrapper of L<String::CRC32>

=head1 SYNOPSIS

  [% USE String::CRC32 -%]
  [% 'test_string' | crc32 %]
  [% text = 'test_string'; text.crc32 %]

=head1 DESCRIPTION

I<Template::Plugin::String::CRC32> is wrapper of L<String::CRC32> module for L<Template::Toolkit>.
It provides access to CRC32 algorithm via the C<String::CRC32> module.
It is used like a plugin but installs filter and vmethod into the current context.

When you invoke
 
  [% USE String::CRC32 %]

the following filter (and vmethod of the same name) is installed
into the current context:

=over 4

=item C<crc32>

Calculate the CRC 32bit checksum of the input, and return it as 4-bytes integer.

=back

As the filter is also available as vmethod the following are all
equivalent:

    FILTER crc32; content; END;
    content FILTER crc32;
    content.crc32;


=head1 SEE ALSO

L<String::CRC32>, L<Template>

=head1 ACKNOWLEDGEMENTS

Code and documentation was inspired by L<Template::Plugin::Digest::MD5> module.

=head1 LICENSE

Copyright (C) Alexander A. Gnatyna.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Alexander A. Gnatyna E<lt>gnatyna@cpan.orgE<gt>

=cut

