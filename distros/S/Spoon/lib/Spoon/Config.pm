package Spoon::Config;
use Spoon::Base -Base;

const class_id => 'config';

sub all {
    return %$self;
}

sub default_configs { return }

sub new() {
    my $class = shift;
    my $self = bless {}, $class;
    my (@configs) = map {
        /\*/ ? (sort glob) : ($_)
    } @_ ? @_ : $self->default_configs;
    $self->add_config($self->default_config, 1);
    for my $config (@configs) {
        $self->rebless($self->add_config($config));
    }
    $self->init;
    return $self;
}

sub add_field {
    my ($field, $default) = @_;
    field $field => $default;
}

sub add_config {
    my $config = shift;
    my $hash = ref $config
    ? $config
    : $self->hash_from_file($config);
    for my $key (keys %$hash) {
        field $key;
        $self->{$key} = $hash->{$key};
    }
    return $hash;
}

sub rebless {
    my $hash = shift;
    if (defined (my $config_class = $hash->{config_class})) {
        eval qq{ require $config_class }; die $@ if $@;
        bless $self, $config_class;
    }
}

sub hash_from_file {
    my $config = shift;
    die "Invalid name for config file '$config'\n"
      unless $config =~ /\.(\w+)$/;
    my $extension = lc("$1"); # quotes fix 5.8.0 perl bug
    my $method = "parse_${extension}_file";
    -f $config ? $self->$method($config) : {};
}

sub parse_file {
    $self->parse_yaml_file(@_);
}

sub parse_yaml_file {
    my $file = shift;
    $self->parse_yaml(io($file)->utf8->all);
}

sub parse_yaml {
    my $yaml = shift;
    my $hash = {};
    my $latest_key = '';
    for (split /\n/, $yaml) {
        next if (/^#/);
        if (/^-\s*(.*)$/) {
            $hash->{$latest_key} = [] unless ref $hash->{$latest_key};
            push @{$hash->{$latest_key}}, $1;
        }
        elsif (/(.*?)\s*:\s+(.*?)\s*$/ or /(.*?):()\s*$/) {
            $hash->{$1} = $2;
            $latest_key = $1;
        }
    }
    return $hash;
}

sub default_config {
    +{
        $self->default_classes,
        plugin_classes => [$self->default_plugin_classes],
    }
}

sub default_classes {
    (
        cgi_class => 'Spoon::CGI',
        config_class => 'Spoon::Config',
        formatter_class => 'Spoon::Formatter',
        headers_class => 'Spoon::Headers',
        hooks_class => 'Spoon::Hooks',
        hub_class => 'Spoon::Hub',
        main_class => 'Spoon',
        registry_class => 'Spoon::Registry',
        template_class => 'Spoon::Template',
    )
}

sub default_plugin_classes { () }

__END__

=head1 NAME 

Spoon::Config - Spoon Configuration Base Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
