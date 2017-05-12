# NAME

Puncheur - a web application framework

# SYNOPSIS

    package MyApp;
    use parent 'Puncheur';
    use Puncheur::Dispatcher::Lite;
    use Data::Section::Simple ();
    __PACKAGE__->setting(
        template_dir => [Data::Section::Simple::get_data_section],
    );
    any '/' => sub {
        my $c = shift;
        $c->render('index.tx');
    };
    1;
    __DATA__
    @@ index.tx
    <h1>It Works!</h1>

And in your console,

    % plackup -MMyApp -e 'MyApp->new->to_psgi'

# DESCRIPTION

Puncheur is a web application framework.

**THE SOFTWARE IS ALPHA QUALITY. API MAY CHANGE WITHOUT NOTICE.**

# INTERFACE

## Constructor

### new

    my $app = MyApp->new(%opt);

- view
- config
- dispatcher
- template\_dir
- asset\_dir
- app\_name

# LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masayuki Matsuki <y.songmu@gmail.com>
