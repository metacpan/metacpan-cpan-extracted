package Mojolicious::Command::swat;

our $VERSION = '0.0.5';

use Mojo::Base 'Mojolicious::Command';

use re 'regexp_pattern';
use Getopt::Long qw(GetOptionsFromArray);
use File::Path qw(make_path);

has description => 'Generates swat tests scaffolding for mojo application';
has usage => sub { shift->extract_usage };

sub run {

    my ($self, @args) = @_;

    GetOptionsFromArray \@args, 'f|force' => \my $force;

    mkdir 'swat';

    my $hostname_file = 'swat/host';

    open(my $fh, '>', $hostname_file) or die "Could not open file $hostname_file: $!";
    print $fh "http://127.0.0.1:3000";
    close $fh;
    
 
    my $rows = [];

    _walk($_, 0, $rows, 0) for @{$self->app->routes->children};

    ROUTE: for my $i (@$rows){

        my $http_method = $i->[1];
        my $route  = $i->[0];

        unless ($http_method=~/GET|POST|DELETE|PUT/i){
            print "sorry, swat does not support $http_method methods yet \n";
            next ROUTE;
        }

        my $filename = "swat/$route/";
        
        if (-e $filename and !$force){

            print "skip route $route - swat test already exist, use --force to override existed routes \n";
            next ROUTE;

        } else {

            print "generate swat route for $route ... \n";
            make_path("swat/$route");
    
            print "generate swat data for $http_method $route ... \n";
    
            $filename.=lc($http_method); $filename.=".txt";
            open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
            print $fh "200 OK\n";
            close $fh;
        }

    }

}

sub _walk {

    my ($route, $depth, $rows, $verbose) = @_;

    # Pattern
    my $prefix = '';
    if (my $i = $depth * 2) { $prefix .= ' ' x $i . '+' }
    push @$rows, my $row = [$prefix . ($route->pattern->unparsed || '/')];

    # Flags
    my @flags;
    push @flags, @{$route->over || []} ? 'C' : '.';
    push @flags, (my $partial = $route->partial) ? 'D' : '.';
    push @flags, $route->inline       ? 'U' : '.';
    push @flags, $route->is_websocket ? 'W' : '.';
    push @$row, join('', @flags) if $verbose;

    # Methods
    my $via = $route->via;
    push @$row, !$via ? '*' : uc join ',', @$via;

    # Name
    my $name = $route->name;
    push @$row, $route->has_custom_name ? qq{"$name"} : $name;

    # Regex (verbose)
    my $pattern = $route->pattern;
    $pattern->match('/', $route->is_endpoint && !$partial);
    my $regex  = (regexp_pattern $pattern->regex)[0];
    my $format = (regexp_pattern($pattern->format_regex))[0];
    push @$row, $regex, $format ? $format : '' if $verbose;

    $depth++;
    _walk($_, $depth, $rows, $verbose) for @{$route->children};
    $depth--;
}

1;

__END__

=encoding utf8


=head1 NAME

Mojolicious::Command::swat - Swat command


=head1 SYNOPSIS

    Usage: APPLICATION swat [OPTIONS]
    
    Options:
      -f, --force   Override existed swat tests


=head1 DESCRIPTION

L<Mojolicious::Command::swat|https://metacpan.org/pod/Mojolicious::Command::swat> 

=over

=item *

Generates L<swat|https://github.com/melezhik/swat> swat tests scaffolding for mojo application.



=item *

This command walks through all available routes and generates a swat test for every one. 



=back


=head1 INSTALL

    cpanm Mojolicious::Command::swat


=head1 EXAMPLE


=head2 install mojo

    sudo cpanm Mojolicious


=head2 bootstrap a mojo application

    mkdir myapp
    cd myapp
    mojo generate lite_app myapp.pl


=head2 define http resources ( mojo routes )

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


=head2 bootstrap swat tests

    $ ./myapp.pl swat
    generate swat route for / ...
    generate swat data for GET / ...
    generate swat route for /hello ...
    generate swat data for POST /hello ...
    generate swat route for /hello/world ...
    generate swat data for GET /hello/world ...


=head2 specify swat L<check lists|https://github.com/melezhik/swat#swat-check-lists>

This phase might be skipped as preliminary `200 OK` checks are already added on bootstrap phase. But you may define more. 

For complete documentation on *how to write swat tests*  please visit  https://github.com/melezhik/swat

    $ echo ROOT >> swat/get.txt
    $ echo HELLO >> swat/hello/post.txt
    $ echo HELLO WORLD >> swat/hello/world/get.txt


=head2 start mojo application

    $ morbo ./myapp.pl
    Server available at http://127.0.0.1:3000


=head2 run swat tests

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


=head1 SEE ALSO

=over

=item *

L<swat|https://github.com/melezhik/swat>


=item *

L<Mojolicious|https://metacpan.org/pod/Mojolicious>


=back
