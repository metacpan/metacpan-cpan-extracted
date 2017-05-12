package SoggyOnion::Resource;
use warnings;
use strict;

our $VERSION = '0.04';

# make sure that plugins i expect to use are loaded
require SoggyOnion::Plugin::RSS;
require SoggyOnion::Plugin::ImageScraper;

sub new {
    my ( $self, $item ) = @_;

    # do some error checking
    unless ( ref $item eq 'HASH' ) {
        warn "\t\titems must be a hash (got '$item')\n";
        return;
    }
    if ( not( defined $item->{id} ) || $item->{id} =~ /\W/ ) {
        warn "\t\titems must have an alphanumeric-only 'id' key\n";
        return;
    }

    # if we have an 'rss' key, assume it's an rss feed
    if ( exists $item->{rss} ) {
        return SoggyOnion::Plugin::RSS->new($item);
    }

    # if we have an 'images' key, assume it's an image scraper
    if ( exists $item->{images} ) {
        return SoggyOnion::Plugin::ImageScraper->new($item);
    }

    # if we have a 'plugin' key, it's a module. try using it.
    elsif ( exists $item->{plugin} ) {

        # try requiring
        eval "require $item->{plugin}";
        if ($@) {
            warn "\t\t$@\n";
            return;
        }

        # try actually getting an object from it
        my $rval;
        eval { $rval = $item->{plugin}->new($item); };
        warn "\t\t$@\n" if $@;
        return $rval;
    }

    # augh, no handler at all!
    warn "\t\titem contained keys qw("
        . join( ' ', keys %$item )
        . ") but don't know how to handle it\n";
    return;
}

1;

__END__

=head1 NAME

SoggyOnion::Resource - determines which SoggyOnion::Plugin to use

=head1 SYNOPSIS

    my $item = {
        rss          => 'http://use.perl.org/useperl.rss',
        id           => 'use_perl',
        limit        => 10,
        descriptions => 'no',
        };
    my $resource = SoggyOnion::Resource->new($item);
    print $resource->content;

=head1 DESCRIPTION

To override how L<SoggyOnion> determines what plugin to use based on
what keys are in the item in the configuration, copy this module and add
a C<resourceclass> option in your F<config.yaml>, such as:

    ...
    templatedir:   '/path/to/templates'
    cachedir:      '/tmp/soggycache'
    resourceclass: 'My::Custom::ResourceHandler'
    ...

=head1 SEE ALSO

L<SoggyOnion::Plugin>, L<SoggyOnion>

=head1 AUTHOR

Ian Langworth, C<< <ian@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ian Langworth

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
