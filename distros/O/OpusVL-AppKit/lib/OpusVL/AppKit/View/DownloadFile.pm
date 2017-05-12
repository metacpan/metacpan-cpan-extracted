package OpusVL::AppKit::View::DownloadFile;

use Moose;

use namespace::autoclean;

BEGIN { extends 'Catalyst::View::Download'; }

sub process
{
    my $self    = shift;
    my $c       = shift;
    my $args    = shift;

    $c->res->content_type( $args->{content_type} );
    $c->res->header( 'Content-Disposition' => 'filename='.$args->{header}.';' );
    $c->res->body( $args->{body} );
    $c->detach;
}

##
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::View::DownloadFile

=head1 VERSION

version 2.29

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
