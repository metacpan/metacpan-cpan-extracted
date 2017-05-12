package Template::Plugin::Digest::SHA3;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 0.02;

use base qw(Template::Plugin);
use Template::Plugin;
use Template::Stash;
use Digest::SHA3;

my $sha3;

$Template::Stash::SCALAR_OPS->{'sha3'}          = \&_sha3;
$Template::Stash::SCALAR_OPS->{'sha3_hex'}      = \&_sha3_hex;
$Template::Stash::SCALAR_OPS->{'sha3_base64'}   = \&_sha3_base64;

sub new {
    my ($class, $context, $options) = @_;

    my $hashlen = $options || 256;
    $sha3 = new Digest::SHA3 $hashlen;

    # now define the filter and return the plugin
    $context->define_filter('sha3',         \&_sha3);
    $context->define_filter('sha3_hex',     \&_sha3_hex);
    $context->define_filter('sha3_base64',  \&_sha3_base64);
    return bless {}, $class;
}

sub _sha3 {
    $sha3->reset();
    $sha3->add(join('', @_));
    return $sha3->digest();
}

sub _sha3_hex {
    $sha3->reset();
    $sha3->add(join('', @_));
    return $sha3->hexdigest();
}

sub _sha3_base64 {
    $sha3->reset();
    $sha3->add(join('', @_));
    return $sha3->b64digest();
}

1;

__END__

=head1 NAME

Template::Plugin::Digest::SHA3 - TT2 interface to the SHA3 Algorithm

=head1 SYNOPSIS

  [% USE Digest.SHA3 -%]
  [% checksum = content FILTER sha3 -%]
  [% checksum = content FILTER sha3_hex -%]
  [% checksum = content FILTER sha3_base64 -%]
  [% checksum = content.sha3 -%]
  [% checksum = content.sha3_hex -%]
  [% checksum = content.sha3_base64 -%]

=head1 DESCRIPTION

The I<Digest.SHA3> Template Toolkit plugin provides access to the NIST SHA-1
algorithm via the C<Digest::SHA3> module.  It is used like a plugin but
installs filters and vmethods into the current context.

When you invoke

    [% USE Digest.SHA3 %]

the following filters (and vmethods of the same name) are installed
into the current context:

=over 4

=item C<sha3>

Calculate the SHA-2 digest of the input, and return it in binary form.

=item C<sha3_hex>

Same as C<sha3>, but will return the digest in hexadecimal form. The returned
string will only contain characters from this set: '0'..'9' and 'a'..'f'.

=item C<sha3_base64>

Same as C<sha3>, but will return the digest as a base64 encoded string. The
returned string will only contain characters from this set: 'A'..'Z', 'a'..'z',
'0'..'9', '+' and '/'.

=back

As the filters are also available as vmethods the following are all
equivalent:

    FILTER sha3_hex; content; END;
    content FILTER sha3_hex;
    content.sha3_base64;

=head2 Bit length

By default the checksum is produced with a 256 bit length string. The 
supported bit lengths are 224, 256, 384, and 512, which are set as follows:

    [% USE Digest.SHA3(224) %]
    [% USE Digest.SHA3(256) %]
    [% USE Digest.SHA3(384) %]
    [% USE Digest.SHA3(512) %]

=head1 SEE ALSO

L<Digest::SHA3>, L<Template>

=head1 AUTHOR

  Barbie <barbie@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2014-2015 Barbie for Miss Barbell Productions.

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut
