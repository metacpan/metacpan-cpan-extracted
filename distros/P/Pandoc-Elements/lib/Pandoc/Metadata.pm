package Pandoc::Metadata;
use strict;
use warnings;
use 5.010001;

use Pandoc::Elements;
use Scalar::Util qw(blessed reftype);
use JSON::PP;
use Carp;
# # For Pandoc::Metadata::Error
# use Carp qw(shortmess longmess);

# packages and methods

{
    # key-value map of metadata fields
    package Pandoc::Document::Metadata;

    {
        no warnings 'once';
        *to_json = \&Pandoc::Document::Element::to_json;
    }

    sub TO_JSON {
        return { %{ $_[0] } }
    }

    sub value {
        my $map = { c => shift };
        Pandoc::Document::MetaMap::value( $map, @_ )
    }
}

{
    # metadata element parent class
    package Pandoc::Document::Meta;
    our @ISA = ('Pandoc::Document::Element');
    sub is_meta { 1 }
    sub value { shift->value(@_) }
}

# # For Pandoc::Metadata::Error
# {
#     package Pandoc::Metadata::Error;
#     use overload q[""] => 'shortmess', q[%{}] => 'data', fallback => 1;
#     use constant { SHORTMESS => 0, LONGMESS => 1, DATA => 2 };
#     sub new {
#         my($class, @values) = @_;   # CLASS, (MESSAGE, {DATA})
#         bless \@values => $class;
#     }
#     sub shortmess { shift->[SHORTMESS] }
#     sub longmess { shift->[LONGMESS] }
#     sub data { shift->[DATA] }
#     sub rethrow { die shift }
#     sub throw { shift->new( @_ )->rethrow }
# }

# helpers

my @token_keys = qw(last_pointer ref_token plain_key key empty pointer);

sub _pointer_token {
    state $valid_pointer_re = qr{\A (?: [^/] .* | (?: / [^/]* )* ) \z}msx;
    state $token_re = qr{
        \A
        (?<_last_pointer>
            (?<_ref_token>
                (?<_plain_key>
                    (?<_key> [^/] .* \z )    # plain "key"
                )
            |   / (?<_key> [^/]* ) # "/key"
            |     (?<_empty> \z )  # "" -- return current element
            )
            (?<_pointer> / .* \z | )
        )
        \z
    }msx;
    # set non-participating keys to undef
    state $defaults = { map {; "_$_" => undef } @token_keys };
    my %opts = @_;
    $opts{_pointer} //= $opts{_full_pointer} //= $opts{pointer} //= "";
    $opts{_pointer} =~ $valid_pointer_re // _bad_pointer( %opts, _error => 'pointer' );
    $opts{_pointer} =~ $token_re; # guaranteed to match since validation matched!
    my %match = %+;
    unless ( grep { defined $_ } @match{qw(_plain_key _empty)} ) {
        $match{_key} =~ s!\~1!/!g;
        $match{_key} =~ s!\~0!~!g;
    }
    return (%opts, %$defaults, %match);
}

sub _bad_pointer {
    state $params_for = do {
        my %params_map = (
            default => {
                msg     => 'Invalid or unknown pointer reference "%s"',
                in      => 1,
                _keys    => ['_ref_token'],
                pointer => '_last_pointer'
            },
            pointer => { msg => 'Invalid', in => 0, _keys => [], pointer => '_last_pointer', },
            container => { msg => 'No list or mapping "%s"', },
            key       => { msg => 'Node "%s" doesn\'t correspond to any key', },
            range => { msg => 'List index %s out of range', _keys => ['_key'], },
            index => { msg => 'Node "%s" not a valid list index', },
        );
        for my $key ( keys %params_map ) {
            for my $params ( $params_map{$key} ) {
                $params = { %{ $params_map{default} }, %$params };
                $params->{msg} .= ( $params->{in} ? q[ in] : "" );
                $params->{keys}
                  = [ @{ $params->{_keys} }, $params->{pointer}, '_full_pointer' ];
            }
        }
        \%params_map;
    };
    # # For Pandoc::Metadata::Error
    # state $data_keys = {
    #     ( map { ; $_ => $_ } qw[element strict boolean] ),
    #     ( map { ; $_ => "_$_" } @token_keys, qw[error] ),
    #     ( pointer => '_full_pointer', next_pointer => '_pointer' ),
    # };
    my ( %opts ) = @_;
    return undef unless $opts{strict};
    $opts{_error} //= 'default';
    my $params = $params_for->{ $opts{_error} };
    if ( $opts{_error} eq 'container' ) {
        %opts = _pointer_token( %opts );
    }
    my $msg = sprintf $params->{msg} . q[ (sub)pointer "%s" in pointer "%s"], @opts{ @{ $params->{keys} } };
    # # For Pandoc::Metadata::Error
    # my %data;
    # @data{ keys %$data_keys } = @opts{ values %$data_keys };
    # Pandoc::Metadata::Error->throw( shortmess($msg), longmess($msg), \%data );
    croak $msg;
}

# methods

sub _value_args {
    my $content = shift->{c};
    my ($pointer, %opts) = @_ % 2 ? @_ : (undef, @_);

    $opts{_pointer} = $pointer // $opts{_pointer} // $opts{pointer} // '';
    $opts{_full_pointer} //= $opts{_pointer};

    return ($content, %opts);
}

sub Pandoc::Document::MetaString::value {
    my ($content, %opts) = _value_args(@_);

    if ($opts{_pointer} ne '') {
        _bad_pointer(%opts, _error => 'container');
    } else {
        $content;
    }
}

sub Pandoc::Document::MetaBool::set_content {
    $_[0]->{c} = $_[1] && $_[1] ne 'false' && $_[1] ne 'FALSE' ? 1 : 0;
}

sub Pandoc::Document::MetaBool::TO_JSON {
    return {
        t => 'MetaBool',
        c => $_[0]->{c} ? JSON::true() : JSON::false(),
    };
}

sub Pandoc::Document::MetaBool::value {
    my ($content, %opts) = _value_args(@_);

    if ($opts{_pointer} ne '') {
        _bad_pointer(%opts, _error => 'container');
    } elsif (($opts{boolean} // '') eq 'JSON::PP') {
        $content ? JSON::true() : JSON::false();
    } else {
        $content ? 1 : 0;
    }
}

sub Pandoc::Document::MetaMap::value {
    my ($map, %opts) = _value_args(@_);
    %opts = _pointer_token(%opts);

    if (defined $opts{_empty}) {
        return { map { $_ => $map->{$_}->value(%opts) } keys %$map };
    } elsif (exists($map->{$opts{_key}})) {
        return $map->{$opts{_key}}->value(%opts);
    } else {
        _bad_pointer( %opts, _error => 'key');
    }
}

sub Pandoc::Document::MetaList::value {
    my ($content, %opts) = _value_args(@_);
    %opts = _pointer_token(%opts);
    if ( defined $opts{_empty} ) {
        return [ map { $_->value(%opts) } @$content ]
    } elsif ($opts{_key} =~ /^[1-9][0-9]*$|^0$/) {
        if ( $opts{_key} > $#$content ) {
            return _bad_pointer( %opts, _error => 'range' );
        }
        my $value = $content->[$opts{_key}];
        return defined($value) ? $value->value(%opts) : undef;
    } else {
        return _bad_pointer( %opts, _error => 'index' );
    }
}

sub Pandoc::Document::MetaInlines::value {
    my ($content, %opts) = _value_args(@_);

    if ($opts{_pointer} ne '') {
        _bad_pointer(%opts, _error => 'container');
    } elsif ($opts{element} // '' eq 'keep') {
        $content;
    } else {
        join '', map { $_->string } @$content;
    }
}

sub Pandoc::Document::MetaBlocks::string {
    join "\n\n", map { $_->string } @{$_[0]->content};
}

sub Pandoc::Document::MetaBlocks::value {
    my ($content, %opts) = _value_args(@_);

    if ($opts{_pointer} ne '') {
        _bad_pointer(%opts);
    } elsif ($opts{element} // '' eq 'keep') {
        $content;
    } else {
        $_[0]->string;
    }
}

1;
__END__

=head1 NAME

Pandoc::Metadata - pandoc document metadata

=head1 DESCRIPTION

Document metadata such as author, title, and date can be embedded in different
documents formats. Metadata can be provided in Pandoc markdown format with
L<metadata blocks|http://pandoc.org/MANUAL.html#metadata-blocks> at the top of
a markdown file or in YAML format like this:

  ---
  title: a title
  author:
    - first author
    - second author
  published: true
  ...

Pandoc supports document metadata build of strings (L</MetaString>), boolean
values (L</MetaBool>), lists (L</MetaList>), key-value maps (L</MetaMap>),
lists of inline elements (L</MetaInlines>) and lists of block elements
(L</MetaBlocks>). Simple strings and boolean values can also be specified via
pandoc command line option C<-M> or C<--metadata>:

  pandoc -M key=string
  pandoc -M key=false
  pandoc -M key=true
  pandoc -M key

Perl module L<Pandoc::Elements> exports functions to construct metadata
elements in the internal document model and the general helper function
C<metadata>.

=head1 COMMON METHODS

All Metadata Elements support L<common element methods|Pandoc::Elements/COMMON
METHODS> (C<name>, C<to_json>, C<string>, ...) and return true for method
C<is_meta>.

=head2 value( [ $key | $pointer ] [ %options ] )

Called without an argument this method returns an unblessed deep copy of the
metadata element. Plain keys at the root level (unless they start with C</>)
and JSON Pointer expressions (L<RFC 6901|http://tools.ietf.org/html/rfc6901>)
can be used to select subfields.  Note that JSON Pointer escapes slash as C<~1>
and character C<~> as C<~0>. URI Fragment syntax is not supported.

  $doc->value;                   # full metadata
  $doc->value("");               # full metadata, explicitly
  $doc->value('/author');        # author field
  $doc->value('author');         # author field, plain key
  $doc->value('/author/name');   # name subfield of author field
  $doc->value('/author/0');      # first author field
  $doc->value('/author/0/name'); # name subfield of first author field
  $doc->value('/~1~0');          # metadata field '/~'
  $doc->value('/');              # field with empty string as key

Returns C<undef> if the selected field does not exist.

As a debugging aid you can set option C<strict> to a true value.
In this case the method will C<croak> if an invalid pointer,
invalid array index, non-existing key or non-existing array index
is encountered.

Instances of MetaInlines and MetaBlocks are stringified by unless option
C<element> is set to C<keep>.

Setting option C<boolean> to C<JSON::PP> will return C<JSON::PP:true>
or C<JSON::PP::false> for L<MetaBool|/MetaBool> instances.

=head1 METADATA ELEMENTS

=head2 MetaString

A plain text string metadata value.

    MetaString $string
    metadata "$string"

=head2 MetaBool

A Boolean metadata value. The special values C<"false"> and
C<"FALSE"> are recognized as false in addition to normal false values (C<0>,
C<undef>, C<"">, ...).

    MetaBool $value
    metadata JSON::true()
    metadata JSON::false()

=head2 MetaList

A list of other metadata elements.

    MetaList [ @values ]
    metadata [ @values ]

=head2 MetaMap

A map of keys to other metadata elements.

    MetaMap { %map }
    metadata { %map }

=head2 MetaInlines

Container for a list of L<inlines|Pandoc::Elements/INLINE ELEMENTS> in
metadata.

    MetaInlines [ @inlines ]

=head2 MetaBlocks

Container for a list of L<blocks|Pandoc::Elements/BLOCK ELEMENTS> in metadata.

    MetaBlocks [ @blocks ]

The C<string> method concatenates all stringified content blocks separated by
empty lines.

=cut
