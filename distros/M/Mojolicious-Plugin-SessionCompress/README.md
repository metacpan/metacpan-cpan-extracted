# NAME

Mojolicious::Plugin::SessionCompress - Session serialization and compression plugin for Mojolicious

# SYNOPSIS

    # Default settings

    plugin 'SessionCompress';

    # Custom settings

    use Compress::Zlib qw(deflateInit inflateInit Z_STREAM_END);
    use Data::Dumper 'Dumper';
    $Data::Dumper::Terse = 1;

    plugin session_compress => {
      compress => sub {
        my $string = shift;

        my $d = deflateInit(-Level => 1, -memLevel => 4, -WindowBits => -15);
        return $d->deflate($string) . $d->flush;
      },
      decompress => sub {
        my $string = $_[0];

        my $d = inflateInit(-WindowBits => -15);
        my ($inflated, $status) = $d->inflate($string);
        # Check to see if it's actually compressed
        return $_[0] if $status != Z_STREAM_END || length($inflated) <= 1;
        return $inflated;
      },
      serialize => sub {
        my $hashref = shift;

        return Dumper($hashref);
      },
      deserialize => sub {
        my $string = shift;

        return eval $string;
      },
      min_size => 100
    };

# DESCRIPTION

Mojolicious::Plugin::SessionCompress allows compression of and custom serialization for Mojolicious::Session
sessions.

# CONFIGURATION

Though it works "out of the box" you can change how de/compression and de/serialzation is handled. You can also
change the minimum size required for compression with min_size. de/compression and de/serialzation subs need to be
paired respectively.

## `compress`

    # This and the following are the defaults used internally
    compress => sub {
      my $string = shift;

      my $d = Compress::Zlib::deflateInit(-Level => 1, -memLevel => 5, -WindowBits => -15);
      return $d->deflate($string) . $d->flush;
    }

## `decompress`

    decompress => sub {
      my $string = $_[0];

      my $d = Compress::Zlib::inflateInit(-WindowBits => -15);
      my ($inflated, $status) = $d->inflate($string);
      # Check to see if it's actually compressed
      return $_[0] if $status != Compress::Zlib::Z_STREAM_END || length($inflated) <= 1;
      return $inflated;
    }

## `serialize`

    serialize => \&Mojo::JSON::encode_json

## `deserialze`

    deserialize > \&Mojo::JSON::j

## `min_size`

    min_size minimum size that's allowed to be compressed

    min_size => 250

# OLD VERSION CONSIDERATIONS

Mojolicious::Plugin::SessionCompress versions prior to 0.03 rely on Mojo::Util::monkey_patch to override j and
encode_json within Mojolicious::Sessions. This may seem hack-y to some.

# SEE ALSO

[Mojolicious](http://search.cpan.org/perldoc?Mojolicious), [Compress::Zlib](http://search.cpan.org/perldoc?Compress::Zlib)

LICENSE AND COPYRIGHT

Copyright (C) 2014 Sean Ohashi

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

http://www.perlfoundation.org/artistic_license_2_0
