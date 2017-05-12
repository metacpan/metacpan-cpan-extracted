package SoggyOnion::Plugin;
use warnings;
use strict;

our $VERSION = '0.04';

=head1 NAME

SoggyOnion::Plugin - how to extend SoggyOnion

=head1 SYNOPSIS

    # sample plugin that uses a file as its resource.
    # needs a 'filename' key in the item hash in the config
    package SoggyOnion::Plugin::File;
    
    sub init {
        my $self = shift;
        die "I have no filename" 
            unless exists $self->{filename};
    }
    
    sub mod_time {
        my $self = shift;
        return [ stat $self->{filename} ]->[9];
    }
    
    sub content {
        open( FH, "<$self->{filename}" ) or die $!
        my $data = join('', <FH>);
        close FH;
        return $data;
    }


=head1 DESCRIPTION

This is the base class for all SoggyOnion plugins. 

=head1 METHODS

=head2 new( $hashref )

Constructor that SoggyOnion gives a hash of information. Can be used for the
plugin's own stash.

=cut

sub new {
    my ( $class, $data ) = @_;
    warn "$class\::new() must be passed a hash ref" && return
        unless ref $data eq 'HASH';
    bless $data, $class;
    $data->init;
    return $data;
}

=head2 init()

This is called before we call mod_time and/or content. I use it to set the
useragent in LWP::Simple in a few modules.

=cut

sub init { }

=head2 id()

Return the ID is used for <DIV> tags and internal caching stuff. This is
a simple accessor that makes the code cleaner.

=cut

sub id {
    my $self = shift;
    return $self->{id};
}

=head2 mod_time()

The default mod_time method ensures that the resource is always refreshed
(cache is never used).

=cut

sub mod_time {time}

=head2 content()

Return XHTML content.

=cut

sub content {
    qq(<p class="error">This is the output of the default plugin class. Something strange has occurred.</p>\n)
}

=head1 SEE ALSO

L<SoggyOnion>

=head1 AUTHOR

Ian Langworth, C<< <ian@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ian Langworth

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

