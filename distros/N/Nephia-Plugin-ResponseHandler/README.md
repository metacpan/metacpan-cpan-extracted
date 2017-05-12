# NAME

Nephia::Plugin::ResponseHandler - A plugin for Nephia that provides response-handling feature

# SYNOPSIS

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



# DESCRIPTION

Nephia::Plugin::ResponseHandler provides response-handling feature for Nephia app.

# DEFAULT WORKS

## When hashref passed

Basically, content-type becomes 'application/json; charset=UTF-8', and content-body becomes json-string that is transformed from passed hashref.

If 'template' attribute contains in hashref, content-type becomes 'text/html; charset=UTF-8', and content-body becomes string that is rendered with view plugin. (ex. Nephia::Plugin::View::MicroTemplate, Nephia::Plugin::View::Xslate, or other)

If 'template' and 'content\_type' contains in hashref, content-type becomes specified thing as 'content\_type' in hashref, and content-body becomes string that is rendered by view plugin.

## When arrayref passed

It expects three elements into arrayref, as response of PSGI.

## When scalar passed

Content-type becomes "text/html; charset=UTF-8", and content-body becomes passed scalar.

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
