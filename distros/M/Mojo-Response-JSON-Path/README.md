# Mojo::JSON::Path - use JSON::Path for searching JSON responses

## SYNOPSIS

    use Mojo::JSON::Path;
    use Mojo::UserAgent;
    
    my $ua = Mojo::UserAgent->new;
    
    my $url = Mojo::URL->new("http://localhost:3000");
    
    $url->query({ ids => $id });
    
    my $json = $tx->res->json('$.entities');

## DESCRIPTION

This module allows the use of an optional JSON Path expression to extract a specific value from a Mojo::Message via JSON::Path. 

## FUNCTIONS

None

## SEE ALSO

- Mojo::Message
- Mojo::JSON::Pointer
- JSON::Path

## AUTHORS

Simone Cesano <scesano@cpan.org>

## COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Simone Cesano.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

