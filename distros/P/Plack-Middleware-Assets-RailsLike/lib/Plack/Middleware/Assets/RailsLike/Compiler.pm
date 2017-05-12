package Plack::Middleware::Assets::RailsLike::Compiler;

use strict;
use warnings;
use Carp              ();
use CSS::LESSp        ();
use CSS::Minifier::XS ();
use Errno             ();
use File::Slurp;
use File::Spec::Functions qw(catdir catfile canonpath);
use JavaScript::Minifier::XS ();
use Text::Sass::XS qw(:const);

sub new {
    my $class = shift;
    my %args  = (
        minify      => 0,
        search_path => ['.'],
        @_
    );
    my $self = bless \%args, $class;

    $self->{sass_compiler} = Text::Sass::XS->new(
        output_style    => SASS_STYLE_COMPRESSED,
        source_comments => SASS_SOURCE_COMMENTS_NONE,
        include_paths   => $self->{search_path},
        image_path      => undef, # TBD require option?
    );

    return $self;
}

sub compile {
    my $self = shift;
    my %args = (
        manifest => undef,
        type     => 'js',
        @_
    );

    my $content = $args{manifest};

    if ( $args{type} eq 'css' ) {
        my $css_comment = qr!
            /\*
              .*?
              (?:\r?\n)
              ((?:\*= .+(?:\r?\n)){1,})
            \*/
        !x;
        $content =~ s{$css_comment}{$1}g;
    }

    my $parser = qr{
        ^
            (?://|\*)=
            \s+
            (require)           # commands
            \s+
            ([0-9a-zA-Z_\-./]+) # basename
            \s*
        $
    }xms;

    $content
        =~ s/$parser/my $cmd = "_cmd_$1"; $self->$cmd($2, $args{type})/ge;

    $content = $self->_minify( $content, $args{type} ) if $self->{minify};
    return $content;
}

sub _cmd_require {
    my $self = shift;
    my ( $file, $type ) = @_;

    my @search_path = @{ $self->{search_path} };
    my @type = $type eq 'js' ? qw(js) : qw(css scss sass less);

    for my $path (@search_path) {
        for my $type (@type) {
            my $filename = canonpath(
                catfile( $path, sprintf( '%s.%s', $file, $type ) ) );

            my $buff;
            read_file( $filename, buf_ref => \$buff, err_mode => sub { } );
            unless ($!) {

                my $content;
                if ( $type eq 'scss' ) {
                    $content = $self->{sass_compiler}->scss2css($buff);
                }
                elsif ( $type eq 'sass' ) {
                    $content = $self->{sass_compiler}->sass2css($buff);
                }
                elsif ( $type eq 'less' ) {
                    $content = join '', CSS::LESSp->parse($buff);
                }
                else {
                    $content = $buff;
                }

                chomp $content;
                return $content;
            }
            elsif ( $! == Errno::ENOENT ) {
                next;
            }
            else {
                Carp::carp("read_file '$filename' failed - $!");
                return;
            }
        }
    }

    Carp::carp( sprintf "requires '%s' failed - No such file in %s",
        $file, join( ', ', @search_path ) );
}

sub _minify {
    my $self = shift;
    my ( $content, $type ) = @_;
    if ( $type eq 'js' ) {
        $content = JavaScript::Minifier::XS::minify($content);
    }
    else {
        $content = CSS::Minifier::XS::minify($content);
    }
    return $content;
}

1;
