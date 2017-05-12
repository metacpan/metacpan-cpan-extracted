package Template::Plugin::Digest::SHA1;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 0.05;

use base qw(Template::Plugin);
use Template::Plugin;
use Template::Stash;
use Digest::SHA1 qw(sha1 sha1_hex sha1_base64);

$Template::Stash::SCALAR_OPS->{'sha1'}          = \&_sha1;
$Template::Stash::SCALAR_OPS->{'sha1_hex'}      = \&_sha1_hex;
$Template::Stash::SCALAR_OPS->{'sha1_base64'}   = \&_sha1_base64;

sub new {
    my ($class, $context, $options) = @_;

    # now define the filter and return the plugin
    $context->define_filter('sha1',         \&_sha1);
    $context->define_filter('sha1_hex',     \&_sha1_hex);
    $context->define_filter('sha1_base64',  \&_sha1_base64);
    return bless {}, $class;
}

sub _sha1 {
    my $options = ref $_[-1] eq 'HASH' ? pop : {};
    return sha1(join('', @_));
}

sub _sha1_hex {
    my $options = ref $_[-1] eq 'HASH' ? pop : {};
    return sha1_hex(join('', @_));
}

sub _sha1_base64 {
    my $options = ref $_[-1] eq 'HASH' ? pop : {};
    return sha1_base64(join('', @_));
}

1;

__END__

=head1 NAME

Template::Plugin::Digest::SHA1 - TT2 interface to the SHA1 Algorithm

=head1 SYNOPSIS

  [% USE Digest.SHA1 -%]
  [% checksum = content FILTER sha1 -%]
  [% checksum = content FILTER sha1_hex -%]
  [% checksum = content FILTER sha1_base64 -%]
  [% checksum = content.sha1 -%]
  [% checksum = content.sha1_hex -%]
  [% checksum = content.sha1_base64 -%]

=head1 DESCRIPTION

The I<Digest.SHA1> Template Toolkit plugin provides access to the NIST SHA-1
algorithm via the C<Digest::SHA1> module.  It is used like a plugin but
installs filters and vmethods into the current context.

When you invoke

    [% USE Digest.SHA1 %]

the following filters (and vmethods of the same name) are installed
into the current context:

=over 4

=item C<sha1>

Calculate the SHA-1 digest of the input, and return it in binary form.
The returned string will be 20 bytes long.

=item C<sha1_hex>

Same as C<sha1>, but will return the digest in hexadecimal form. The
length of the returned string will be 40 and it will only contain
characters from this set: '0'..'9' and 'a'..'f'.

=item C<sha1_base64>

Same as C<sha1>, but will return the digest as a base64 encoded
string.  The length of the returned string will be 27 and it will
only contain characters from this set: 'A'..'Z', 'a'..'z',
'0'..'9', '+' and '/'.

Note that the base64 encoded string returned is not padded to be a
multiple of 4 bytes long.  If you want interoperability with other
base64 encoded sha1 digests you might want to append the redundant
string "=" to the result.

=back

As the filters are also available as vmethods the following are all
equivalent:

    FILTER sha1_hex; content; END;
    content FILTER sha1_hex;
    content.sha1_base64;

=head1 SEE ALSO

L<Digest::SHA1>, L<Template>

=head1 DEDICATION

This distribution was originally created by Andrew Ford. Sadly in early 2014,
Andrew was diagnosed with Pancreatic Cancer and passed away peacfully at home
on 25th April 2014.

One of his wishes was for his OpenSource work to continue. At his funeral, many
of his colleagues and friends, spoke of how he felt like a person of the world, 
and how he embrace the idea of OpenSource being for the benefit of the world.

Anyone wishing to donate in memory of Andrew, please consider the following
charities:

=over

=item Dignity in Dying - L<http://www.dignityindying.org.uk/>

=item Marie Curie Cancer Care - L<http://www.mariecurie.org.uk/>

=back

=head1 AUTHOR

  Original Author:    Andrew Ford               2006-2014
  Current Maintainer: Barbie <barbie@cpan.org>  2014

=head1 ACKNOWLEDGEMENTS

Thanks to Darren Chamberlain for a patch for vmethod support.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2006-2014 Andrew Ford
Copyright (C) 2014      Barbie for Miss Barbell Productions.

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut
