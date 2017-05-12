package Search::Elasticsearch::Role::API;
$Search::Elasticsearch::Role::API::VERSION = '5.02';
use Moo::Role;
requires 'api_version';
requires 'api';

use Search::Elasticsearch::Util qw(throw);
use namespace::clean;

our %Handler = (
    string => sub {"$_[0]"},
    list   => sub {
        ref $_[0] eq 'ARRAY'
            ? join( ',', @{ shift() } )
            : shift();
    },
    boolean => sub {
        $_[0] && !( $_[0] eq 'false' || $_[0] eq \0 ) ? 'true' : 'false';
    },
    enum => sub {
        ref $_[0] eq 'ARRAY'
            ? join( ',', @{ shift() } )
            : shift();
    },
    number => sub { 0 + $_[0] },
    time   => sub {"$_[0]"}
);

#===================================
sub _qs_init {
#===================================
    my $class = shift;
    my $API   = shift;
    for my $spec ( keys %$API ) {
        my $qs = $API->{$spec}{qs};
        for my $param ( keys %$qs ) {
            my $handler = $Handler{ $qs->{$param} }
                or throw( "Internal",
                      "Unknown type <"
                    . $qs->{$param}
                    . "> for param <$param> in API <$spec>" );
            $qs->{$param} = $handler;
        }
    }
}

1;

# ABSTRACT: Provides common functionality for API implementations

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Role::API - Provides common functionality for API implementations

=head1 VERSION

version 5.02

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
