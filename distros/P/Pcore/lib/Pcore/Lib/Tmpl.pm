package Pcore::Lib::Tmpl;

use Pcore -class, -export;
use Pcore::Lib::Scalar qw[is_ref];
use Text::Xslate qw[];

use overload '&{}' => sub ( $self, @ ) {
    sub { $self->render(@_) }
  },
  fallback => 1;

our $EXPORT = [qw[mark_raw unmark_raw]];

has _renderer    => ( required => 1 );    # InstanceOf ['Text::Xslate']
has _string_tmpl => ( required => 1 );    # HashRef

sub mark_raw : prototype($)   { return Text::Xslate::mark_raw @_ }
sub unmark_raw : prototype($) { return Text::Xslate::unmark_raw @_ }

# cache => 0 - don't use cache at all
#
# cache => 1:
# - file tmpl rebuilded and cached every time if original tmpl timestamp was changed, timestamp will checked on every render call;
# - string tmpl rebuilded and cached at first render call if not cached yet or cached tmpl has different check sum;
#
# cache => 2:
# - file tmpl builded and cached at first use only if not cached previously;
# - string tmpl same as cache => 1;
around new => sub ( $orig, $self, %args ) {
    my $string_tmpl_cache = {};

    my $path = [$string_tmpl_cache];    # virtual path

    if ( my $tmpl_storage = $ENV->{share}->get_location('tmpl') ) {
        push $path->@*, $tmpl_storage->@*;
    }

    my $args_def = {
        path        => $path,
        cache       => 1,
        cache_dir   => "$ENV->{TEMP_DIR}/.xslate",
        input_layer => ':encoding(UTF-8)',
        type        => 'html',                                                              # html, text}
        syntax      => 'Kolon',                                                             # Kolon, TTerse
        module      => [ 'Text::Xslate::Bridge::TT2Like', 'Text::Xslate::Bridge::Star' ],
        function    => { l10n => sub { return l10n( \@_ ) }, },
    };

    return bless {
        _renderer    => Text::Xslate->new( P->hash->merge( $args_def, \%args )->%* ),
        _string_tmpl => $string_tmpl_cache
    }, $self;
};

# name1 => $tmpl1, ...
sub add_tmpl ( $self, %args ) {
    for my $name ( keys %args ) {
        my $exists = exists $self->{_string_tmpl}->{$name};

        $self->{_string_tmpl}->{$name} = $args{$name};

        $self->{_renderer}->load_file($name) if $exists;
    }

    return;
}

sub reload_tmpl ( $self, @names ) {
    for (@names) { $self->{_renderer}->load_file($_) }

    return;
}

sub render ( $self, $tmpl, $params = undef ) {

    # anon. template
    if ( is_ref $tmpl ) {
        return \$self->{_renderer}->render_string( $tmpl->$*, $params );
    }

    # named template
    else {
        return \$self->{_renderer}->render( $tmpl, $params );
    }
}

1;
__END__
OLD VARS AND FILTERS, maybe needed to be reimplemented:

VARIABLES    => {
    ENV     => \%ENV,
    UUID    => sub { return P->uuid->str },
    TO_JSON => sub { return P->data->to_json(@_) },
    TO_XML  => sub {
        my $data = shift;
        my $args = shift;

        return P->data->to_xml($data, $args>%*);
    },
},
FILTERS => {
    b64                     => sub { return P->data->to_b64(@_) },
    b64_url                 => sub { return P->data->to_b64_url(@_) },
    hex                        => sub { return P->text->encode_hex(@_) },
    html                       => sub { return P->text->encode_html(@_) },
    html_attr                  => sub { return P->text->encode_html_attr(@_) },
    js_string                  => sub { return P->text->encode_js_string(@_) },
    uri                        => sub { return P->data->to_uri(@_) },                    # same as javascript encodeURIComponent function, used to encode dataurl or any other binary data as javascript string
    strftime_to_jquery_pattern => sub { return P->text->encode_strftime_jquery(@_) },
},
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::Tmpl - Text::Xslate wrapper

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
