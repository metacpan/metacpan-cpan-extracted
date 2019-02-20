# vim: ai et sw=4
use strict;
use warnings;
package Mojolicious::Plugin::YamlConfig;

use base 'Mojolicious::Plugin::JSONConfig';

our $VERSION = '0.2.2';

sub register {
    my ( $self, $app, $conf ) = @_;
    $conf ||= {};
    $conf->{ext} = 'yaml';
    $conf->{class} ||= $ENV{MOJO_YAML} || 'YAML::Tiny';
    $self->{class} = $conf->{class};
    my @supported = qw(YAML YAML::XS YAML::Tiny YAML::Old YAML::PP);
    unless ( grep { $conf->{class} eq $_ } @supported) {
        warn("$conf->{class} is not supported, use at your own risk");
    }
    return $self->SUPER::register( $app, $conf );
}

sub parse {
    my ($self, $content, $file, $conf, $app) = @_;

    my $class = $self->{class};
    eval "require $class; 1" || die($@);

    my ($config,$error);

    # Render
    $content = $self->render($content, $file, $conf, $app);

    my @broken = qw(YAML YAML::Old YAML::Tiny YAML::PP);
    unless (grep { $class eq $_ } @broken) {
        # they are broken *sigh*
        $content = Encode::encode('UTF-8', $content);
    }

    $config = eval $class.'::Load($content)';
    if($@) {
        $error = $@;
    }

    die qq/Couldn't parse config "$file": $error/ if !$config && $error;
    die qq/Invalid config "$file"./ if !$config || ref $config ne 'HASH';

    return $config;
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::YamlConfig - YAML Configuration Plugin

=head1 SYNOPSIS

    # myapp.yaml
    --
    foo: "bar"
    music_dir: "<%= app->home->rel_dir('music') %>"

    # Mojolicious
    $self->plugin('yaml_config');

    # Mojolicious::Lite
    plugin 'yaml_config';

    # Reads myapp.yaml by default and puts the parsed version into the stash
    my $config = $self->stash('config');

    # Everything can be customized with options
    plugin yaml_config => {
        file      => '/etc/myapp.conf',
        stash_key => 'conf',
        class     => 'YAML::XS'
    };

=head2 DESCRIPTION

Look at L<Mojolicious::Plugin::JSONConfig> and replace "JSONConfig" with "yaml_config"
and you should be fine. :)

=head2 LIMITATIONS

L<YAML::Tiny> is the default parser. It doesn't even try to implement the full
YAML spec. Currently you can use L<YAML::PP>, L<YAML::XS>, L<YAML::Old> and
L<YAML> via the C<class> option to parse the data with a more advanced YAML parser.

=head2 AUTHOR

Danijel Tasov <data@cpan.org>

=head2 SEE ALSO

L<Mojolicious>, L<Mojolicious::Plugin::JSONConfig>, L<Mojolicious::Guides>

