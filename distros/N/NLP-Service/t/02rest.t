use Test::More;
use YAML;
BEGIN {
    use_ok('NLP::Service');
}

# we need to laod the models before the Dancer::Test otherwise the path does not
# work for some reason.
can_ok( 'NLP::Service', 'load_models' );
my $count = NLP::Service::load_models;
is( $count, 4, 'Load models worked' );

# the below module should always be after the package being tested.
use Dancer::Test;

subtest 'GET/POST routes that should pass' => sub {
    my @ser    = qw(yml json xml);
    my %routes = (
        '/'              => undef,
        '/nlp/info'      => \@ser,
        '/nlp/models'    => \@ser,
        '/nlp/languages' => \@ser,
        '/nlp/relations' => \@ser,
    );
    my %modelroutes = (
        '/nlp/parse'                => \@ser,
        '/nlp/parse/en_pcfg'        => \@ser,
        '/nlp/parse/en_factored'    => \@ser,
        '/nlp/parse/en_pcfgwsj'     => \@ser,
        '/nlp/parse/en_factoredwsj' => \@ser,
    );
    my $check_request = sub {
        my ( $meth, $rte, $flag ) = @_;
        Carp::croak 'Invalid method' unless defined $meth;
        Carp::croak 'Invalid route'  unless defined $rte;
        $flag = 0 unless defined $flag;
        route_exists       [ $meth => $rte ], "$meth $rte exists";
        response_exists    [ $meth => $rte ], "$meth $rte response exists";
        response_status_is [ $meth => $rte ], 200,
          "$meth $rte responds with 200"
          if $flag;
    };
    foreach my $meth (qw/GET POST/) {
        foreach my $rte ( sort keys %routes ) {
            defined $routes{$rte}
              ? map { &$check_request( $meth, "$rte." . $_, 1 ) }
              @{ $routes{$rte} }
              : &$check_request( $meth, $rte );
        }
        foreach my $rte ( sort keys %modelroutes ) {
            defined $modelroutes{$rte}
              ? map { &$check_request( $meth, "$rte." . $_ ) }
              @{ $modelroutes{$rte} }
              : &$check_request( $meth, $rte );
        }
    }
    done_testing();
};

subtest 'GET/POST routes that should fail' => sub {
    my @routes = qw(
      /nlp/info
      /nlp/
      /robots.txt
    );
    map { route_doesnt_exist( [ GET => $_ ], "GET $_ does not exist." ) }
      @routes;
    map { route_doesnt_exist( [ POST => $_ ], "POST $_ does not exist." ) }
      @routes;
    my @modelroutes = qw(
      /nlp/parse/en_pcfg.yml
      /nlp/parse/en_pcfg1.yml
    );
    map { response_status_is( [ GET => $_ ], 500, "GET $_ responds with 500" ) }
      @modelroutes;
    map {
        response_status_is( [ POST => $_ ], 500, "POST $_ responds with 500" )
    } @modelroutes;
    done_testing();
};

subtest 'parse text using GET/POST' => sub {
    my @modelroutes = qw(
      /nlp/parse/en_pcfg.yml
      /nlp/parse/en_pcfgwsj.yml
      /nlp/parse/en_factored.yml
      /nlp/parse/en_factoredwsj.yml
    );
    my $params = { data => 'The quick brown fox jumped over a lazy dog.', };
    my $output = eval qq/[
    { relation => 'determiner', from => 'fox-4', to => 'The-1' },
    { relation => 'adjectival modifier', from => 'fox-4', to => 'quick-2' },
    { relation => 'adjectival modifier', from => 'fox-4', to => 'brown-3' },
    { relation => 'nominal subject', from => 'jumped-5', to => 'fox-4' },
    { relation => 'determiner', from => 'dog-9', to => 'a-7' },
    { relation => 'adjectival modifier', from => 'dog-9', to => 'lazy-8' },
    { relation => 'prep_collapsed', from => 'jumped-5', to => 'dog-9' },
    ]/;
    my $check_request = sub {
        my ( $meth, $rte, $code ) = @_;
        Carp::croak 'Invalid method' unless defined $meth;
        Carp::croak 'Invalid route'  unless defined $rte;
        $code = 200 unless defined $code;

        my $res = dancer_response( $meth => $rte, { params => $params } );
        isa_ok( $res, 'Dancer::Response' );
        is( $res->{status}, $code, "$meth $rte responds with $code" );
        my $content = $res->{content} or fail("No content received");
        if ( $code eq 200 ) {
            my $aref = YAML::Load($content) or eval $content;
            is_deeply( $aref, $output,
                "Response content looks good for $meth $rte" );
        } elsif ( $code eq 500 ) {
            like( $content, qr/error/, "Error: $content" );
        } elsif ( $code eq 404 ) {
            pass('Expected a 404 response');
        }
    };
    &$check_request( 'GET',  '/nlp/parse.yml', 200 );
    &$check_request( 'POST', '/nlp/parse.yml', 200 );
    map {
        &$check_request( 'POST', $_, 200 );
        &$check_request( 'GET',  $_, 200 );
    } @modelroutes;
    my @nonroutes = map { $_ if $_ =~ s/\./dummy\./g } @modelroutes;
    map {
        &$check_request( 'GET',  $_, 500 );
        &$check_request( 'POST', $_, 500 );
    } @nonroutes;
    &$check_request( 'GET',  '/nlp/parsedummy.yml', 404 );
    &$check_request( 'POST', '/nlp/parsedummy.yml', 404 );
    done_testing();
};
done_testing();
__END__
COPYRIGHT: 2011. Vikas Naresh Kumar.
AUTHOR: Vikas Naresh Kumar
DATE: 28th May 2011.
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
