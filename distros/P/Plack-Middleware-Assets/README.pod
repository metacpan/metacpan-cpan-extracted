package Plack::Middleware::Assets;

# ABSTRACT: Concatenate and minify JavaScript and CSS files
use strict;
use warnings;

use base 'Plack::Middleware';
use Plack::Util::Accessor
    qw( separator filter content minify files key mtime type type_class expires extension );

use Digest::MD5 qw(md5_hex);
use HTTP::Date  ();
use Class::Load ();

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    # set defaults
    $self->separator(1) unless ( defined $self->separator );
    $self->minify(1)    unless ( defined $self->minify );
    $self->filter(1)    unless ( defined $self->filter );
    $self->_build_content;
    return $self;
}

sub _build_content {
    my $self = shift;
    local $/;

    my $type = $self->type
        || (
          ( grep {/\.css$/} @{ $self->files } ) ? 'css'
        : ( grep {/\.js$/} @{ $self->files } )  ? 'js'
        : 'plain'
        );
    $self->type($type);
    my $class = __PACKAGE__ . "::Type::$type";
    eval { Class::Load::load_class($class) }
        or die "$class could not be loaded: $@";
    $self->type_class($class);

    my $separator = $self->separator;

    # use default comment format unless format was specified
    $separator = $class->separator
        if $separator && $separator !~ /%s/;

    $self->content(
        join(
            "\n",
            map {
                open my $fh, '<', $_ or die "$_: $!";
                ( $separator ? sprintf( $separator, $_ ) : '' ) . <$fh>
                } @{ $self->files }
        )
    );

    $self->content( $self->_transform('filter') ) if $self->filter;
    $self->content( $self->_transform('minify') ) if $self->minify;

    $self->key( md5_hex( $self->content ) );
    my @mtime = map { ( stat($_) )[9] } @{ $self->files };
    $self->mtime( ( reverse( sort(@mtime) ) )[0] );
}

sub _transform {
    my ( $self, $transform ) = @_;
    return $self->content
        if ( $transform ne 'minify'
        && $ENV{PLACK_ENV}
        && $ENV{PLACK_ENV} eq 'development' );
    no strict 'refs';
    my $run = $self->$transform;
    my $method;
    if ( ref $run eq 'CODE' ) {
        $method = $run;
    }
    elsif ( $run && $self->type_class->can($transform) ) {
        $method = $self->type_class . "::$transform";
    }
    return $self->content unless ($method);

    local $_ = $self->content;
    return $method->($_);
}

sub serve {
    my $self = shift;
    my $type = $self->type;

    return [
        200,
        [   'Content-Type'   => $self->type_class->content_type,
            'Content-Length' => length( $self->content ),
            'Last-Modified'  => HTTP::Date::time2str( $self->mtime ),
            'Expires' =>
                HTTP::Date::time2str( time + ( $self->expires || 2592000 ) ),
        ],
        [ $self->content ]
    ];
}

sub call {
    my $self = shift;
    my $env  = shift;

    if ( $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development' ) {
        my @mtime = map { ( stat($_) )[9] } @{ $self->files };
        $self->_build_content
            if ( $self->mtime < ( reverse( sort(@mtime) ) )[0] );
    }

    $env->{'psgix.assets'} ||= [];
    my $extension = $self->extension || $self->type_class->extension;
    my $url = '/_asset/' . $self->key . '.' . $extension;
    push( @{ $env->{'psgix.assets'} }, $url );
    return $self->serve if $env->{PATH_INFO} eq $url;
    return $self->app->($env);
}

package Plack::Middleware::Assets::Type::plain;
use strict;
use warnings;

sub content_type {'text/plain'}
sub separator    { }
sub extension    {'txt'}

package Plack::Middleware::Assets::Type::css;
use strict;
use warnings;
use base 'Plack::Middleware::Assets::Type::plain';
use CSS::Minifier::XS qw(minify);

sub content_type {'text/css'}
sub separator    {"/* %s */\n"}
sub extension    {'css'}

package Plack::Middleware::Assets::Type::js;
use strict;
use warnings;
use base 'Plack::Middleware::Assets::Type::plain';
use JavaScript::Minifier::XS qw(minify);

sub content_type {'application/javascript'}
sub separator    {"/* %s */\n"}
sub extension    {'js'}

1;

__END__

=head1 SYNOPSIS

  # in app.psgi
  use Plack::Builder;

  builder {
    enable Assets => ( files => [<static/js/*.js>] );
    enable Assets => (
        files  => [<static/css/*.css>],
        minify => 0
    );
    $app;
  };


  # or customize your assets as desired:

  builder {

    # concatenate sass files and transform them into css
    enable Assets => (
        files  => [<static/sass/*.sass>],
        type   => 'css',
        filter => sub { Text::Sass->new->sass2css(shift) },
        minify => 0
    );

    # pass a coderef for a custom minifier
    enable Assets => (
        files  => [<static/any/*.txt>],
        filter => sub {uc},
        minify => sub { s/ +/\t/g; $_ }
    );

    # concatenate any arbitrary content type
    enable Assets => (
        files => [<static/less/*.less>],
        type  => 'less'
    );

    $app;
  };



  
  # since this module ships only with the types css and js,
  # you have to implement the less type yourself:
  
  package Plack::Middleware::Assets::Type::less;
  use base 'Plack::Middleware::Assets::Type::css';
  use CSS::Minifier::XS qw(minify);
  use CSS::LESSp ();
  sub filter { CSS::LESSp->parse(@_) }

  # $env->{'psgix.assets'}->[0] points at the first asset.

=head1 DESCRIPTION

Plack::Middleware::Assets concatenates JavaScript and CSS files
and minifies them.

A C<md5> digest is generated and used as the unique url to the
asset.  For instance, if the first C<psgix.assets> is
C<static/js/*.js>, then the unique C<md5> url can be used in a
single HTML C<script> element for all js files.

The C<Last-Modified> header is set to the C<mtime> of the most
recently changed file.

The C<Expires> header is set to one month in advance. Set
L</expires> to change the time of expiry.

The concatented and minified content is cached in memory.

=head1 DEVELOPMENT MODE

 $ plackup app.psgi
 
 $ starman -E development app.psgi

In development mode the minification is disabled and the
concatenated content is regenerated if there were any changes
to the files.

=head1 CONFIGURATIONS

=over 4

=item separator

By default files are prepended with C</* filename */\n>
before being concatenated.

Set this to false to disable these comments.

If set to a string containing a C<%s>
it will be passed to C<sprintf> with the file name.

    separator => "# %s\n"

=item files

Files to concatenate.

=item filter

A coderef that can process/transform the content.

The current content will be passed in as C<$_[0]>
and also available via C<$_> for convenience.

This will be called before it is minified (if C<minify> is enabled).

=item minify

Value to indicate whether to minify or not. Defaults to C<1>.
This can also be a coderef which works the same as L</filter>.

=item type

Type of the asset.
Predefined types include C<css> and C<js>. Additional types can be implemented
by creating a new class in the C<Plack::Middleware::Assets::Type> namespace.
See the L</SYNOPSIS> for an example.

An attempt to guess the correct value is made from the file extensions
but this can be set explicitly if you are using non-standard file extensions.

=item expires

Time in seconds from now (i.e. C<time>) until the resource expires.

=item extension

File extension that is appended to the asset's URI.

=back

=head1 TODO

Allow to concatenate documents from URLs, such that you can have a
L<Plack::Middleware::File::Sass> that converts SASS files to CSS and
concatenate those with other CSS files. Also concatenate content from
CDNs that host common JavaScript libraries.

=head1 SEE ALSO

L<Catalyst::Plugin::Assets>

Inspired by L<Plack::Middleware::JSConcat>
