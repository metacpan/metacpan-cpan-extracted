package Nephia::Plugin::View::MicroTemplate;
use 5.008005;
use strict;
use warnings;
use parent 'Nephia::Plugin';
use Text::MicroTemplate::File;
use Encode;

our $VERSION = "0.01";

sub new {
    my ($class, %opts) = @_;
    my $self = $class->SUPER::new(%opts);
    $self->app->{stash} = {};
    $self->app->{view} = Text::MicroTemplate::File->new(%opts);
    return $self;
}

sub exports { qw/ render / }

sub render {
    my ($self, $context) = @_;
    return sub ($;$) {
        my ($template, $args) = @_;
        my $content = $self->app->{view}->render_file($template, $args);
        Encode::encode_utf8($content);
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Nephia::Plugin::View::MicroTemplate - A plugin for Nephia that provides template mechanism

=head1 SYNOPSIS

    use Nephia plugins => [
        'View::MicroTemplate' => +{
            include_path => [ qw/ view / ],
        },
    ];
    
    app {
        [200, [], render('index.html', { name => 'myapp' })];
    };

=head1 DESCRIPTION

Nephia::Plugin::View::MicroTemplate provides render DSL for rendering template.

=head1 DSL

=head2 render $template_file [, $hashref];

Returns rendered content.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

