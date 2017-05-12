
# NAME

Plack::Middleware::WOVN - Translates PSGI application by using WOVN.io.

# SYNOPSYS

    use Plack::Builder;

    builder {
      'WOVN',
        settings => {
          user_token => 'token',
          secret_key => 'sectet',
        };
      $app;
    };

# DESCRIPTION

This is a Plack Middleware component for translating PSGI application by using WOVN.io.
Before using this middleware, you must sign up and configure WOVN.io.

This is a port of wovnjava (https://github.com/wovnio/wovnjava).

# SETTINGS

## user\_token

User token of your WOVN.io account. This value is required.

## secret\_key

This value will be used in the future. But this value is required.

## url\_pattern

URL rewriting pattern of translated page.

- path (default)

        original: http://example.com/

        translated: http://example.com/ja/

- subdomain

        original: http://example.com/

        translated: http://ja.exmple.com/

- query

        original: http://example.com/

        translated: http://example.com/?wovn=ja

## url\_pattern\_reg

This value is coufigured by url\_pattern. You don't have to configure this value.

## query

Filters query parameters when rewriting URL. Default values is \[\]. (Do not filter query)

## api\_url

URL of WOVN.io API. Default value is "https://api.wovn.io/v0/values".

## default\_lang

Default language of web application. Default value is "en".

## supported\_langs

This value will be used in the future. Default value is \["en"\].

## test\_mode

When "on" or "1" is set to "test\_mode", this middleware translates only the page whose url is "test\_url".
Default value is "0".

## test\_url

Default value is not set.

# LICENSE

MIT License

Copyright (c) 2016 Minimal Technologies, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

# AUTHOR

Masahiro Iuchi
