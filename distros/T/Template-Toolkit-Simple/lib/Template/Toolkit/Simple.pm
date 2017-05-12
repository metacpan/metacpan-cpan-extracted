use strict; use warnings;
package Template::Toolkit::Simple;
our $VERSION = '0.31';

use Encode;
use Getopt::Long;
use Template;
use Template::Constants qw( :debug );
use YAML::XS;

use base 'Exporter';
our @EXPORT = qw(tt);

sub tt {
    return Template::Toolkit::Simple->new();
}

my $default = {
    data => undef,
    config => undef,
    output => undef,

    encoding => 'utf8',
    include_path => undef,
    eval_perl => 0,
    start_tag => quotemeta('[' . '%'),
    end_tag => quotemeta('%' . ']'),
    tag_style => 'template',
    pre_chomp => 0,
    post_chomp => 0,
    trim => 0,
    interpolate => 0,
    anycase => 0,
    delimiter => ':',
    absolute => 0,
    relative => 0,
    strict => 0,
    default => undef,
    blocks => undef,
    auto_reset => 1,
    recursion => 0,
    pre_process => undef,
    post_process => undef,
    process_template => undef,
    error_template => undef,
    output_path => undef,
    debug => 0,
    cache_size => undef,
    compile_ext => undef,
    compile_dir => undef,
};

my $abbreviations = {
    data => 'd',
    include_path => 'path|i',
    output => 'o',
    config => 'c',
};

sub new {
    my $class = shift;
    return bless shift || {%$default}, $class;
}

sub field {
    my ($name, $value) = @_;
    return sub {
        my $self = shift;
        $self->{$name} = @_ ? shift : $value;
        return $self;
    };
}

{
    for my $name (keys %$default) {
        next if $name =~ /^(data|config)/;
        my $value = $default->{$name};
        if (defined $value) {
            $value = 1 - $value if $value =~/^[01]$/;
            $value = [] if $name eq 'include_path';
        }
        no strict 'refs';
        *{__PACKAGE__ . '::' . $name} = field($name, $value);
    }
}

{
    no warnings 'once';
    *path = \&include_path;
}

sub render {
    my $self = shift;
    my $template = shift
      or die "render method requires a template name";
    if ($template =~ qr{//}) {
        my $path;
        ($path, $template) = split '//', $template, 2;
        $self->include_path($path);
    }
    $self->data(shift(@_)) if @_;
    $self->output(shift(@_)) if @_;

    if ($self->{output}) {
        $self->process($template, $self->{data}, $self->{output})
            or $self->croak;
        return '';
    }

    my $output = '';
    $self->process($template, $self->{data}, \$output)
        or $self->croak;
    return Encode::encode_utf8($output);
}

sub usage {
    return <<'...'
Usage:

    tt-render --path=path/to/templates/ --data=data.yaml foo.tt2

...
}

sub croak {
    my $self = shift;
    require Carp;
    my $error = $self->{tt}->error;
    chomp $error;
    Carp::croak($error . "\n");
};

sub process {
    my $self = shift;

    $self->{tt} = Template->new(
        ENCODING            => $self->{encoding},
        INCLUDE_PATH        => $self->{include_path},
        EVAL_PERL           => $self->{eval_perl},
        START_TAG           => $self->{start_tag},
        END_TAG             => $self->{end_tag},
        PRE_CHOMP           => $self->{pre_chomp},
        POST_CHOMP          => $self->{post_chomp},
        TRIM                => $self->{trim},
        INTERPOLATE         => $self->{interpolate},
        ANYCASE             => $self->{anycase},
        DELIMITER           => $self->{delimiter},
        ABSOLUTE            => $self->{absolute},
        STRICT              => $self->{strict},
        DEFAULT             => $self->{default},
        BLOCKS              => $self->{blocks},
        AUTO_RESET          => $self->{auto_reset},
        RECURSION           => $self->{recursion},
        PRE_PROCESS         => $self->{pre_process},
        POST_PROCESS        => $self->{post_process},
        PROCESS_TEMPLATE    => $self->{process_template},
        ERROR_TEMPLATE      => $self->{error_template},
        OUTPUT_PATH         => $self->{output_path},
        DEBUG               =>
            ($self->{debug} && DEBUG_ALL ^ DEBUG_CALLER ^ DEBUG_CONTEXT),
        CACHE_SIZE          => $self->{cache_size},
        COMPILE_EXT         => $self->{compile_ext},
        COMPILE_DIR         => $self->{compile_dir},
    );

    return $self->{tt}->process(@_);
}

sub data {
    my $self = shift;
    $self->{data} = $self->_file_to_hash(@_);
    return $self;
}

sub config {
    my $self = shift;
    $self = {
        %$self,
        $self->_file_to_hash(@_)
    };
    return $self;
}

sub _file_to_hash {
    my $self = shift;
    my $file_name = shift;
    return
        (ref($file_name) eq 'HASH')
        ? $file_name
        : ($file_name =~ /\.(?:yaml|yml)$/i)
        ? $self->_load_yaml($file_name)
        : ($file_name =~ /\.json$/i)
        ? $self->_load_json($file_name)
        : ($file_name =~ /\.xml$/i)
        ? $self->_load_xml($file_name)
        : die "Expected '$file_name' to end with .yaml, .json or .xml";
}

sub _load_yaml {
    my $self = shift;
    YAML::XS::LoadFile(shift);
}

sub _load_json {
    my $self = shift;
    require JSON::XS;
    my $json = do { local $/; open my $json, '<', shift; <$json> };
    JSON::XS::decode_json($json);
}

sub _load_xml {
    my $self = shift;
    require XML::Simple;
    XML::Simple::XMLin(shift);
}

sub _run_command {
    my $class = shift;
    my $self = $class->new($default);
    local @ARGV = @_;
    my $template = pop or do {
        print STDERR $self->usage();
        return;
    };
    my $setter = sub {
        my ($name, $value) = @_;
        my $method = lc($name);
        $method =~ s/-/_/g;
        $value = quotemeta($value)
            if $method =~ /_tag$/;
        $self->$method($value);
    };
    GetOptions(
        map {
            my $option = $_;
            my $option2 = $option;
            $option .= "|$option2" if $option2 =~ s/_/-/g;
            $option .= "|$abbreviations->{$_}"
                if defined $abbreviations->{$_};
            $option .= ((not defined $default->{$_} or $option =~/\-tag$/) ? '=s' : '');
            ($option, $setter);
        } keys %$default
    );

    print STDOUT $self->render($template);
}

1;
