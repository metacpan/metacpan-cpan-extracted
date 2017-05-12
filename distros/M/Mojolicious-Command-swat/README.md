# NAME

Mojolicious::Command::swat - Swat command

# SYNOPSIS

    Usage: APPLICATION swat [OPTIONS]

    Options:
      -f, --force   Override existed swat tests

# DESCRIPTION

[Mojolicious::Command::swat](https://metacpan.org/pod/Mojolicious::Command::swat) 

* Generates [swat](https://github.com/melezhik/swat) swat tests scaffolding for mojo application.

* This command walks through all available routes and generates a swat test for every one. 

# INSTALL

    cpanm Mojolicious::Command::swat

# EXAMPLE

## install mojo

    sudo cpanm Mojolicious

## bootstrap a mojo application

    mkdir myapp
    cd myapp
    mojo generate lite_app myapp.pl
    

## define http resources ( mojo routes )

    $ nano myapp.pl

    #!/usr/bin/env perl
    use Mojolicious::Lite;
    
    get '/' => sub {
      my $c = shift;
      $c->render(text => 'ROOT');
    };
    
    
    post '/hello' => sub {
      my $c = shift;
      $c->render(text => 'HELLO');
    };
    
    get '/hello/world' => sub {
      my $c = shift;
      $c->render(text => 'HELLO WORLD');
    };
    
    app->start;
    

    $ ./myapp.pl routes
    /             GET
    /hello        POST  hello
    /hello/world  GET   helloworld

## bootstrap swat tests

    $ ./myapp.pl swat
    generate swat route for / ...
    generate swat data for GET / ...
    generate swat route for /hello ...
    generate swat data for POST /hello ...
    generate swat route for /hello/world ...
    generate swat data for GET /hello/world ...

## specify swat [check lists](https://github.com/melezhik/swat#swat-check-lists)

This phase might be skipped as preliminary \`200 OK\` checks are already added on bootstrap phase. But you may define more. 

For complete documentation on \*how to write swat tests\*  please visit  https://github.com/melezhik/swat

    $ echo ROOT >> swat/get.txt
    $ echo HELLO >> swat/hello/post.txt
    $ echo HELLO WORLD >> swat/hello/world/get.txt

## start mojo application

    $ morbo ./myapp.pl
    Server available at http://127.0.0.1:3000

## run swat tests

    vagrant@Debian-jessie-amd64-netboot:~/projects/myapp$ swat swat/
    /home/vagrant/.swat/.cache/26576/prove/hello/world/00.GET.t ..
    ok 1 - GET http://127.0.0.1:3000/hello/world succeeded
    # response saved to /home/vagrant/.swat/.cache/26576/prove/an7LtP99Ju
    ok 2 - output match '200 OK'
    ok 3 - output match 'HELLO WORLD'
    1..3
    ok
    /home/vagrant/.swat/.cache/26576/prove/foo/bar/00.PUT.t ......
    ok 1 - PUT http://127.0.0.1:3000/foo/bar succeeded
    # response saved to /home/vagrant/.swat/.cache/26576/prove/L1JTyul6W5
    ok 2 - output match '200 OK'
    1..2
    ok
    /home/vagrant/.swat/.cache/26576/prove/00.GET.t ..............
    ok 1 - GET http://127.0.0.1:3000/ succeeded
    # response saved to /home/vagrant/.swat/.cache/26576/prove/YPnyXfYPXz
    ok 2 - output match '200 OK'
    ok 3 - output match 'ROOT'
    ok 4 - output match 'ROOT'
    1..4
    ok
    /home/vagrant/.swat/.cache/26576/prove/hello/00.POST.t .......
    ok 1 - POST http://127.0.0.1:3000/hello succeeded
    # response saved to /home/vagrant/.swat/.cache/26576/prove/baZKYm1hGD
    ok 2 - output match '200 OK'
    ok 3 - output match 'HELLO'
    1..3
    ok
    All tests successful.
    Files=4, Tests=12,  0 wallclock secs ( 0.03 usr  0.00 sys +  0.20 cusr  0.01 csys =  0.24 CPU)
    Result: PASS
    
# SEE ALSO

* [swat](https://github.com/melezhik/swat)
* [Mojolicious](https://metacpan.org/pod/Mojolicious)
