package MooseX::Configuration::Trait::Object;
BEGIN {
  $MooseX::Configuration::Trait::Object::VERSION = '0.02';
}

use Moose::Role;

use autodie;
use namespace::autoclean;

use B;
use Config::INI::Reader;
use List::AllUtils qw( uniq );
use MooseX::Types -declare => ['MaybeFile'];
use MooseX::Types::Moose qw( HashRef Maybe Str );
use MooseX::Types::Path::Class qw( File );
use Path::Class::File;
use Scalar::Util qw( looks_like_number );
use Text::Autoformat qw( autoformat );

subtype MaybeFile,
    as Maybe[File];

coerce MaybeFile,
    from Str,
    via { Path::Class::File->new($_) };

has config_file => (
    is      => 'ro',
    isa     => MaybeFile,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_config_file',
    clearer => '_clear_config_file',
);

has _raw_config => (
    is      => 'ro',
    isa     => HashRef [ HashRef [Str] ],
    lazy    => 1,
    builder => '_build_raw_config',
);

sub _build_config_file { }

sub _build_raw_config {
    my $self = shift;

    my $file = $self->config_file()
        or return {};

    return Config::INI::Reader->read_file($file) || {};
}

sub _from_config {
    my $self    = shift;
    my $section = shift;
    my $key     = shift;

    my $hash = $self->_raw_config();

    for my $key ( $section, $key ) {
        $hash = $hash->{$key};

        return unless defined $hash && length $hash;
    }

    if ( ref $hash ) {
        die
            "Config for $section - $key did not resolve to a non-reference value";
    }

    return $hash;
}

sub write_config_file {
    my $self = shift;
    my %p    = @_;

    my $file = exists $p{file} ? $p{file} : $self->config_file();

    die 'Cannot write a configuration file without a config file'
        unless defined $file;

    my @sections;
    my %attrs_by_section;

    for my $attr (
        sort { $a->insertion_order() <=> $b->insertion_order() }
        grep { $_->can('config_section') } $self->meta()->get_all_attributes()
        ) {

        push @sections, $attr->config_section();
        push @{ $attrs_by_section{ $attr->config_section() } }, $attr;
    }

    my $content = q{};

    if ( $p{generated_by} ) {
        $content .= '; ' . $p{generated_by} . "\n\n";
    }

    for my $section ( uniq @sections ) {
        unless ( $section eq q{_} ) {
            $content .= '[' . $section . ']';
            $content .= "\n";
        }

        for my $attr ( @{ $attrs_by_section{$section} } ) {

            my $doc;
            if ( $attr->has_documentation() ) {
                $doc = autoformat( $attr->documentation() );
                $doc =~ s/\n\n+$/\n/;
                $doc =~ s/^/; /gm;
            }

            if ( $attr->is_required() ) {
                $doc .= "; This configuration key is required.\n";
            }

            if ( $attr->has_original_default() ) {
                my $def = $attr->original_default();
                if ( length $def ) {
                    $def
                        = looks_like_number($def)
                        ? $def
                        : B::perlstring($def);
                    $doc .= "; Defaults to $def\n";
                }
            }

            $content .= $doc if defined $doc;

            my $value
                = exists $p{values}{ $attr->name() }
                ? $p{values}{ $attr->name() }
                : $self->_from_config(
                $attr->config_section(),
                $attr->config_key(),
                );

            my $key = $attr->config_key();

            if ( defined $value && length $value ) {
                $content .= "$key = $value\n";
            }
            else {
                $content .= "; $key =\n";
            }

            $content .= "\n";
        }
    }

    my $fh;

    if ( ref $file eq 'GLOB' || ref(\$file) eq 'GLOB' ) {
        $fh = $file;
    }
    else {
        open $fh, '>', $file;
    }

    print {$fh} $content;
    close $fh;
}

1;
