# NAME

Net::Groonga::HTTP - Client library for Groonga httpd.

# SYNOPSIS

    use Net::Groonga::HTTP;

    my $groonga = Net::Groonga::HTTP->new(
        end_point => 'http://127.0.0.1:10041/d/',
    );
    my $res = $groonga->status();
    use Data::Dumper; warn Dumper($res);



# DESCRIPTION

Net::Groonga::HTTP is a client library for Groonga http server.

Groonga is a fast full text search engine. Please look [http://groonga.org/](http://groonga.org/).

# CONSTRUCTOR

    Net::Groonga::HTT->new(%args);

You can create instance with following arguments:

- end\_point :Str

    API end point URL for Groonga httpd.

    Example:

        Net::Groonga::HTTP->new(end_point => 'http://127.0.0.1:10041/d/');

- ua : Furl

    Instance of Furl to access Groonga httpd.

    Example:

        Net::Groonga::HTTP->new(ua => Furl->new());

# METHODS

- `$groonga->call($function, %args)`

    Call a http server. Function name is `$function`. Pass the `%args`.

    This method returns instance of [Net::Groonga::HTTP::Response](http://search.cpan.org/perldoc?Net::Groonga::HTTP::Response).

- $groonga->load(%args)

        $groonga->load(
            table => 'Entry',
            values => \@values,
        );

    Load the data to database. This method encodes _values_ to JSON automatically, if it's arrayref.

- $groonga->select(%args)
- $groonga->status(%args)
- $groonga->select(%args)
- $groonga->delete(%args)
- $groonga->column\_create(%args)
- $groonga->dump(%args)

    You can use these methods if you are lazy.

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>
