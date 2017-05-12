package Nephia::Plugin::ResponseHandler;
use 5.008005;
use strict;
use warnings;
use parent 'Nephia::Plugin';
use Nephia::Response;

our $VERSION = "0.02";

sub new {
    my ($class, %opts) = @_;
    my $self = $class->SUPER::new(%opts);
    $self->app->{response_handler} = $opts{handler};
    $self->app->{response_handler}{HASH}   ||= $self->can('_hash_handler');
    $self->app->{response_handler}{ARRAY}  ||= $self->can('_array_handler');
    $self->app->{response_handler}{SCALAR} ||= $self->can('_scalar_handler');
    my $app = $self->app;
    $app->action_chain->after('Core', ResponseHandler => $self->can('_response_handler'));
    return $self;
}

sub _response_handler {
    my ($app, $context) = @_;
    my $res = $context->get('res');
    my $type = ref($res) || 'SCALAR';
    if ($app->{response_handler}{$type}) {
        $app->{response_handler}{$type}->($app, $context);
    }
    return $context;
}

sub _hash_handler {
    my ($app, $context) = @_;
    my $res = $context->get('res');
    if ($res->{template}) {
        my $template = delete($res->{template});
        my $content_type = delete($res->{content_type}) || 'text/html; charset=UTF-8';
        my $res_obj = Nephia::Response->new(
            200, 
            ['Content-Type' => $content_type], 
            $app->dsl('render')->($template, $res)
        ); 
        $context->set('res' => $res_obj);
        return $res_obj;
    }
    else {
        return $app->dsl('json_res')->($res)
    }
}

sub _array_handler {
    my ($app, $context) = @_;
    my $res = $context->get('res');
    $context->set('res' => Nephia::Response->new(@$res));
}

sub _scalar_handler {
    my ($app, $context) = @_;
    my $res = $context->get('res');
    $context->set('res' => Nephia::Response->new(200, ['Content-Type' => 'text/html; charset=UTF-8'], $res));
}

1;
__END__

=encoding utf-8

=head1 NAME

Nephia::Plugin::ResponseHandler - A plugin for Nephia that provides response-handling feature

=head1 SYNOPSIS

    use Nephia plugins => [
        'JSON',
        'View::MicroTemplate' => {...},
        'ResponseHandler'
    ];
    ### now you can as following ...
    app {
        my $type = param('type');
        $type eq 'json' ? +{foo => 'bar'} :
        $type eq 'html' ? +{foo => 'bar', template => 'index.html'} :
        $type eq 'js'   ? +{foo => 'bar', template => 'hoge.js', content_type => 'text/javascript'} :
        $type eq 'str'  ? 'foo = bar' :
                          [200, ['Content-Type' => 'text/html'], 'foo = bar'] 
        ;
    };
    
    ### or you may sepcify your original handler
    use Nephia plugins => [
        'ResponseHandler' => {
            HASH   => \&hash_handler,
            ARRAY  => \&array_handler,
            SCALAR => \&scalar_handler,
        },
    ];
    sub hash_handler {
        my ($app, $context) = @_;
        my $res = $context->get('res');
        ### here make some changes to $res
        $context->set(res => $res);
    }
    sub array_handler {
        ...
    }
    sub scalar_handler {
        ...
    }


=head1 DESCRIPTION

Nephia::Plugin::ResponseHandler provides response-handling feature for Nephia app.

=head1 DEFAULT WORKS

=head2 When hashref passed

Basically, content-type becomes 'application/json; charset=UTF-8', and content-body becomes json-string that is transformed from passed hashref.

If 'template' attribute contains in hashref, content-type becomes 'text/html; charset=UTF-8', and content-body becomes string that is rendered with view plugin. (ex. Nephia::Plugin::View::MicroTemplate, Nephia::Plugin::View::Xslate, or other)

If 'template' and 'content_type' contains in hashref, content-type becomes specified thing as 'content_type' in hashref, and content-body becomes string that is rendered by view plugin.

=head2 When arrayref passed

It expects three elements into arrayref, as response of PSGI.

=head2 When scalar passed

Content-type becomes "text/html; charset=UTF-8", and content-body becomes passed scalar.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

