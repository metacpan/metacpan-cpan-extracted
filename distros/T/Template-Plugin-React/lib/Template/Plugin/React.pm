# ABSTRACT: Renders FB React templates from Template Toolkit
use strict;
use warnings;
package Template::Plugin::React;

our $VERSION = '0.008';

use base qw(Template::Plugin);
use Template::Plugin;

use Template::Plugin::React::RESimple;
use JSON;
use Encode;

sub from_file {
    my ($fname) = @_;

    my $out = '';
    open my $fh, '<:encoding(UTF-8)', $fname or die $!;
    {
        local $/;
        $out = <$fh>;
    }
    close $fh;

    return $out;
}

sub new {
    my ($self, $context, @params) = @_;
    return $self;
}

sub load {
    my ($class, $context) = @_;
    my $constants = $context->config->{CONSTANTS};
    my $size      = $constants->{stacksize} || 32;

    my $ctx       = new Template::Plugin::React::RESimple::RESimple($size);
    my $prelude   = from_file $constants->{react_js};
    my $templates = $constants->{react_templates};

    bless {
        ctx       => $ctx,
        prelude   => $prelude,
        templates => $templates
    }, $class;
}

sub render {
    my ($self, $name, $data) = @_;

    my $json = to_json($data // {}, {utf8 => 1});
    my $built = from_file $self->{templates};

    my $res = $self->{ctx}->exec(qq|
(function() {

var console = {
    warn:  function(){},
    error: function(){}
};

var global = {};
$self->{prelude};
var React = global.React;

$built;
return React.renderComponentToString($name($json));

})();
    |);

    if($res) {
        return Encode::decode("utf8", $self->{ctx}->output());
    } else {
        die $self->{ctx}->output();
    }
}

1;
