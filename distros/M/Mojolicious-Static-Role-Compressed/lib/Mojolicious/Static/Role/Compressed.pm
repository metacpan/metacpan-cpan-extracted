package Mojolicious::Static::Role::Compressed;
use Mojo::Base -role;
use Mojo::Util   ();
use Carp         ();
use Scalar::Util ();

our $VERSION = '0.01';

my $served_compressed_asset;
my @compression_types = ({ext => 'br', encoding => 'br'}, {ext => 'gz', encoding => 'gzip'});

sub compression_types {
    return \@compression_types if @_ == 1;
    my ($self, $types) = @_;

    Carp::croak 'compression_types cannot be changed once serve_asset has served a compressed asset'
        if $served_compressed_asset;
    Carp::croak 'compression_types requires an ARRAY ref'
        unless defined Scalar::Util::reftype($types)
        and Scalar::Util::reftype($types) eq 'ARRAY';
    Carp::croak 'compression_types requires a non-empty ARRAY ref' unless @$types;

    my @new_types;
    my %exts;
    my %encodings;
    for (@$types) {
        my $reftype = Scalar::Util::reftype($_);

        if (not defined $reftype) {
            Carp::croak 'passed empty value in compression_types' unless defined $_ and $_ ne '';
            Carp::croak "duplicate ext '$_'"      if exists $exts{$_};
            Carp::croak "duplicate encoding '$_'" if exists $encodings{$_};

            $exts{$_} = $encodings{$_} = 1;

            push @new_types, {ext => $_, encoding => $_};
        } elsif ($reftype eq 'HASH') {
            my ($ext, $encoding) = (delete $_->{ext}, delete $_->{encoding});
            Carp::croak 'passed empty ext'      unless defined $ext      and $ext ne '';
            Carp::croak 'passed empty encoding' unless defined $encoding and $encoding ne '';
            Carp::croak q{extra keys and values passed in hash besides 'ext' and 'encoding': }
                . Mojo::Util::dumper $_
                if keys %$_;
            Carp::croak "duplicate ext '$ext'"           if exists $exts{$ext};
            Carp::croak "duplicate encoding '$encoding'" if exists $encodings{$encoding};

            $exts{$ext} = $encodings{$encoding} = 1;

            push @new_types, {ext => $ext, encoding => $encoding};
        } else {
            Carp::croak 'passed illegal value to compression_types. Each value of '
                . 'the ARRAY ref must be a scalar or a HASH ref with only the '
                . "keys 'ext' and 'encoding' and their values, but reftype was '$reftype'";
        }
    }

    @compression_types = @new_types;

    return $self;
}

my $should_serve_asset         = sub { $_->path !~ /\.(pdf|jpe?g|gif|png|webp)$/i };
my $should_serve_asset_is_code = 1;

sub should_serve_asset {
    return $should_serve_asset if @_ == 1;
    my ($self, $sub_or_scalar) = @_;

    my $reftype = Scalar::Util::reftype($sub_or_scalar);
    Carp::croak
        "reftype of should_serve_asset must be either undef (scalar) or 'CODE', but was '$reftype'"
        unless not defined $reftype or $reftype eq 'CODE';

    $should_serve_asset         = $sub_or_scalar;
    $should_serve_asset_is_code = defined $reftype;

    warn 'should_serve_asset is a scalar that is always false, so compressed '
        . 'assets will never be served. If this is because you are in development '
        . 'mode, you should instead just not load this role.'
        unless $should_serve_asset_is_code or $should_serve_asset;

    return $self;
}

my $_stash_asset_key            = 'mojolicious_static_role_compressed.asset';
my $_stash_compression_type_key = 'mojolicious_static_role_compressed.compression_type';

before serve_asset => sub {
    my ($self, $c, $asset) = @_;
    return unless $asset->is_file;

    if ($should_serve_asset_is_code) {
        local $_ = $asset;
        return unless $should_serve_asset->();
    } else {
        return unless $should_serve_asset;
    }

    my $req_headers = $c->req->headers;
    my ($compressed_asset, $compression_type);
    if (my $if_none_match_header = $req_headers->if_none_match) {
        my @if_none_matches = map { Mojo::Util::trim $_ } split ',', $if_none_match_header;

        for my $if_none_match (@if_none_matches) {
            if (my ($expected_encoding) = $if_none_match =~ /-(.+)"$/) {
                if (my ($type) = grep { $_->{encoding} eq $expected_encoding } @compression_types) {

                    my $compressed_asset_path = $asset->path . '.' . $type->{ext};
                    if (-f -r $compressed_asset_path) {
                        my $comp_asset = Mojo::Asset::File->new(path => $compressed_asset_path);
                        my $etag
                            = '"'
                            . Mojo::Util::md5_sum($asset->mtime) . '-'
                            . $type->{encoding} . '"';

                        if ($etag eq $if_none_match) {
                            $compressed_asset = $comp_asset;
                            $compression_type = $type;
                            last;
                        }
                    } else {
                        warn "Found compression type with encoding of $type->{encoding} "
                            . "in If-None-Match '$if_none_match', but asset at $compressed_asset_path does not exist, is a directory, or is unreadable.";
                    }
                } else {
                    warn
                        "Found expected compression encoding of '$expected_encoding' in If-None-Match '$if_none_match' for asset '"
                        . $asset->path
                        . q{', but encoding does not exist.};
                }
            } else {
                my $etag = '"' . Mojo::Util::md5_sum($asset->mtime) . '"';

                # return if If-None-Match matches the uncompressed asset
                return if $etag eq $if_none_match;
            }

        }
    }

    my $accept_encoding = $req_headers->accept_encoding;
    my @compression_possibilities
        = defined $accept_encoding && $accept_encoding ne ''
        ? grep { $accept_encoding =~ /$_->{encoding}/i } @compression_types
        : ();
    return unless @compression_possibilities;

    unless ($compressed_asset and $compression_type) {
        for my $type (@compression_possibilities) {
            my $path = $asset->path . '.' . $type->{ext};
            next unless -f -r $path;

            my $comp_asset = Mojo::Asset::File->new(path => $path);
            if ($comp_asset->size >= $asset->size) {
                warn 'Compressed asset '
                    . $comp_asset->path . ' is '
                    . $comp_asset->size
                    . ' bytes, and uncompressed asset '
                    . $asset->path . ' is '
                    . $asset->size
                    . ' bytes. Continuing search for compressed assets.';
                next;
            }

            ($compressed_asset, $compression_type) = ($comp_asset, $type);
            last;
        }
    }
    return unless $compressed_asset and $compression_type;

    my $res_headers = $c->res->headers;
    $res_headers->append(Vary => 'Accept-Encoding');
    $res_headers->content_encoding($compression_type->{encoding});

    # in case Mojolicious::Static::serve wasn't called first
    $c->app->types->content_type($c, {file => $asset->path});

    # set stash with asset for use in is_fresh before method modifier
    $c->stash($_stash_asset_key => $asset, $_stash_compression_type_key => $compression_type);

    $_[2] = $compressed_asset;
    $served_compressed_asset = 1;
};

before is_fresh => sub {
    my ($self, $c, $options) = @_;
    my ($asset, $compression_type) = @{$c->stash}{$_stash_asset_key, $_stash_compression_type_key};
    return unless $asset and $compression_type;

    my $mtime = $asset->mtime;
    my $etag  = Mojo::Util::md5_sum($mtime) . '-' . $compression_type->{encoding};

    @$options{qw/last_modified etag/} = ($mtime, $etag);
};

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Static::Role::Compressed - Role for Mojolicious::Static that
serves pre-compressed versions of static assets

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojolicious-Static-Role-Compressed"><img src="https://travis-ci.org/srchulo/Mojolicious-Static-Role-Compressed.svg?branch=master"></a>

=head1 SYNOPSIS

  # Defaults to serving br assets (with extension ".br"), then gzip (with extension ".gz"),
  # then falls back to the uncompressed asset. By default, this will not look for
  # compressed versions of PDF, PNG, GIF, JP(E)G, or WEBP files since these files
  # are already compressed.
  $app->static->with_roles('+Compressed');

  # Mojolicious::Lite
  app->static->with_roles('+Compressed');

  # or
  $app->static(Mojolicious::Static->new->with_roles('+Compressed'));

  # Don't use the defaults
  $app->static
      ->with_roles('+Compressed')
      ->compression_types(['br', {ext => 'gzip', encoding => 'gzip'}]) # default ext for gzip is 'gz'. This could also be done as ['br', 'gzip']
      ->should_serve_asset(sub { $_->path =~ /\.(html|js|css)$/i }); # only try to serve compressed html, js, and css assets. $_ contains a Mojo::Asset::File

  # Look for compressed versions of all assets
  $app->static
      ->with_roles('+Compressed')
      ->should_serve_asset(sub { 1 });

  # Or just pass in 1 to look for compressed versions of all assets (slightly faster)
  $app->static
      ->with_roles('+Compressed')
      ->should_serve_asset(1);

=head1 DESCRIPTION

L<Mojolicious::Static::Role::Compressed> is a role for L<Mojolicious::Static>
that provides the ability to serve pre-compressed versions of static asset.
L<Mojolicious::Static::Role::Compressed> does this by using the before method
modifier on L<Mojolicious::Static/serve_asset> and
L<Mojolicious::Static/is_fresh>. A static asset will be served when all of the
following conditions are met:

=over 4

=item *

The asset passed to L<Mojolicious::Static/serve_asset> is a
L<Mojo::Asset::File> (L<Mojo::Asset/is_file> returns C<1>).

=item *

It is determined that the asset should be served by L</should_serve_asset>
being a true scalar value or a subroutine that returns true for the given
L<Mojo::Asset::File>.

=item *

L<Mojo::Headers/accept_encoding> for the request contains at least one encoding
listed in L</compression_types>.

=item *

A compressed version of the asset is found that is smaller than the original
asset. Assets are expected to be located at the path of the original asset,
followed by a period and the extension: C</path/to/asset.css> ->
C</path/to/asset.css.gz>

=back

L<Mojolicious::Static::Role::Compressed> uses the same modified time as the
original asset when setting L<Mojo::Headers/last_modified> in the response, and
modifies the ETag (L<Mojo::Headers/etag>) in the response by appending
C<"-$encoding"> (i.e. "etag-gzip"), where the encoding is specified in
L</compression_types>. This is in line with
L<RFC-7232|https://tools.ietf.org/html/rfc7232#section-2.3.3>, which explicitly
states that ETags should be content-coding aware.

=head1 ATTRIBUTES

=head2 compression_types

  $app->static
      ->with_roles('+Compressed)
      ->compression_types(['br', {ext => 'gz', encoding => 'gzip'}]); # This is the default

Compression types accepts an arrayref made up of strings and/or hashrefs.
Strings will be used as both the file extension and the encoding type. The
encoding type is what is used and expected in request and response headers to
specify the encoding. Below is an example of this and the default for
L</compression_types>:

  ['br', {ext => 'gz', encoding => 'gzip'}]

This means that br is both the extension used when looking for compressed
assets, and the encoding used in headers. Internally, C<'br'> will be converted
to C<{ext => 'br', encoding => 'br'}>, and this is how it will appear if you
call L</compression_types> as a getter.

Assets are expected to be located at the path of the original asset, followed
by a period and the extension: C</path/to/asset.css> ->
C</path/to/asset.css.gz>

Compression types will be checked for in the order they are specified, with the
first one that matches all of the requirements in L</DESCRIPTION> being used.
L</compression_types> cannot be changed once L<Mojo::Static> begins serving
compressed assets (L<Mojo::Static/serve_asset> is called, either directly or
indirectly, such as by L<Mojo::Static/serve>, and we succeed in finding and
serving a compressed asset). If you want to change these when the app is
already running, you should create a new L<Mojolicious::Static> object and add
the role and your L</compression_types> again. I'm not sure why you would want
to change this once the app is already running and serving assets, and this may
cause assets that are being served in compressed chunks to be re-served as the
uncompressed asset or a different compressed asset.

C<ext> and C<encoding> must be unique across different compression types.

=head2 should_serve_asset

  $app->static
      ->with_roles('+Compressed)
      ->should_serve_asset(sub { $_->path !~ /\.(pdf|jpe?g|gif|png|webp)$/i }); # This is the default

  # subroutine returning 1 means try to serve compressed versions of all assets.
  $app->static
      ->with_roles('+Compressed)
      ->should_serve_asset(sub { 1 });

  # using 1 directly also tries to serve compressed versions of all assets and is slightly faster
  $app->static
      ->with_roles('+Compressed')
      ->should_serve_asset(1);

L</should_serve_asset> is a subroutine (or scalar) that determines whether or
not L<Mojolicious::Static::Role::Compressed> should attempt to serve a
compressed version of a L<Mojo::Asset::File>. If it is a subroutine, C<$_> is
set to the L<Mojo::Asset::File> that will be served. The default is to not look
for compressed versions of any assets whose L<Mojo::Asset::File/path> indicates
that it is a pdf, jpg, gif, png, or webp file, as these file types are already
compressed:

  sub { $_->path !~ /\.(pdf|jpe?g|gif|png|webp)$/i }) # default for should_serve_asset

To look for compressed versions of all assets, set L</should_serve_asset> to a
subroutine that always returns C<1>:

  $app->static
      ->with_roles('+Compressed)
      ->should_serve_asset(sub { 1 });

Or you can set L</should_serve_asset> to 1, which is slightly faster:

  $app->static
      ->with_roles('+Compressed')
      ->should_serve_asset(1);

Setting L</should_serve_asset> to a scalar that evaluates to false, such as
C<undef>, will cause a warning. If L</should_serve_asset> is a false scalar,
there is no point in loading L<Mojolicious::Static::Role::Compressed>.

=head1 RESERVED STASH KEYS

L<Mojolicious::Static::Role::Compressed> uses the stash keys
C<mojolicious_static_role_compressed.asset> and
C<mojolicious_static_role_compressed.compression_type> internally, so these
should not be used by elsewhere in the L<Mojolicious> app. There are no plans
for other stash keys, but other keys under
C<mojolicious_static_role_compressed.*> should be avoided when using this role.

=head1 AUTHOR

Adam Hopkins E<lt>srchulo@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2019- Adam Hopkins

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item *

L<Mojolicious::Static>

=item *

L<Mojolicious>

=item *

L<https://mojolicious.org>

=back

=cut
