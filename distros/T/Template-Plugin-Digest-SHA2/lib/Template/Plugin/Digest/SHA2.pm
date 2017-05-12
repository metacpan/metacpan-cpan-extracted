package Template::Plugin::Digest::SHA2;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 0.01;

use base qw(Template::Plugin);
use Template::Plugin;
use Template::Stash;
use Digest::SHA2;

my $sha2;

$Template::Stash::SCALAR_OPS->{'sha2'}          = \&_sha2;
$Template::Stash::SCALAR_OPS->{'sha2_hex'}      = \&_sha2_hex;
$Template::Stash::SCALAR_OPS->{'sha2_base64'}   = \&_sha2_base64;

sub new {
    my ($class, $context, $options) = @_;

    my $hashlen = $options || 256;
    $sha2 = new Digest::SHA2 $hashlen;

    # now define the filter and return the plugin
    $context->define_filter('sha2',         \&_sha2);
    $context->define_filter('sha2_hex',     \&_sha2_hex);
    $context->define_filter('sha2_base64',  \&_sha2_base64);
    return bless {}, $class;
}

sub _sha2 {
    $sha2->reset();
    $sha2->add(join('', @_));
    return $sha2->digest();
}

sub _sha2_hex {
    $sha2->reset();
    $sha2->add(join('', @_));
    return $sha2->hexdigest();
}

sub _sha2_base64 {
    $sha2->reset();
    $sha2->add(join('', @_));
    return $sha2->b64digest();
}

1;

__END__

=head1 NAME

Template::Plugin::Digest::SHA2 - TT2 interface to the SHA2 Algorithm

=head1 SYNOPSIS

  [% USE Digest.SHA2 -%]
  [% checksum = content FILTER sha2 -%]
  [% checksum = content FILTER sha2_hex -%]
  [% checksum = content FILTER sha2_base64 -%]
  [% checksum = content.sha2 -%]
  [% checksum = content.sha2_hex -%]
  [% checksum = content.sha2_base64 -%]

=head1 DESCRIPTION

The I<Digest.SHA2> Template Toolkit plugin provides access to the NIST SHA-1
algorithm via the C<Digest::SHA2> module.  It is used like a plugin but
installs filters and vmethods into the current context.

When you invoke

    [% USE Digest.SHA2 %]

the following filters (and vmethods of the same name) are installed
into the current context:

=over 4

=item C<sha2>

Calculate the SHA-2 digest of the input, and return it in binary form.

=item C<sha2_hex>

Same as C<sha2>, but will return the digest in hexadecimal form. The returned
string will only contain characters from this set: '0'..'9' and 'a'..'f'.

=item C<sha2_base64>

Same as C<sha2>, but will return the digest as a base64 encoded string. The
returned string will only contain characters from this set: 'A'..'Z', 'a'..'z',
'0'..'9', '+' and '/'.

=back

As the filters are also available as vmethods the following are all
equivalent:

    FILTER sha2_hex; content; END;
    content FILTER sha2_hex;
    content.sha2_base64;

=head2 Bit length

By default the checksum is produced with a 256 bit length string. The 
supported bit lengths are 256, 384 and 512, which are set as follows:

    [% USE Digest.SHA2(256) %]
    [% USE Digest.SHA2(384) %]
    [% USE Digest.SHA2(512) %]

=head1 SEE ALSO

L<Digest::SHA2>, L<Template>

=head1 AUTHOR

  Barbie <barbie@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2014      Barbie for Miss Barbell Productions.

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut
