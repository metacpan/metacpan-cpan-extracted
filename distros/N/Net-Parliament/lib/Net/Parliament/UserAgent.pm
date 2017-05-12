package Net::Parliament::UserAgent;
use Moose;
extends 'LWP::UserAgent';
use IO::All;
use Digest::MD5 qw/md5_hex/;
use File::Path qw/mkpath/;
use Fatal qw/mkpath/;

=head1 NAME

Net::Parliament::UserAgent - a caching user agent

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module will cache GET requests to disk.  It otherwise
behaves the same as LWP::UserAgent.

=cut

has 'cache_dir' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_cache_dir {
    my $self = shift;
    my $dir  = "cache";

    if (!-d $dir) {
        mkpath($dir);
    }
    return $dir;
}

around 'get' => sub {
    my $orig = shift;
    my $self = shift;
    my $url  = shift;

    my $file = $self->_url_to_file($url);
    if (-e $file) {
        print "Returning $url from $file\n";
        return io($file)->all();
    }

    my $resp = $orig->($self, $url);
    my $html = $resp->content;
    io($file)->print($html);
    print "Saved $url to $file\n";

    return $html;
};

sub _url_to_file {
    my $self = shift;
    my $cd   = $self->cache_dir;
    return join '/', $cd, md5_hex(shift);
}

=head1 AUTHOR

Luke Closs, C<< <cpan at 5thplane.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-parliament at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Parliament>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Parliament::UserAgent

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Parliament>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Parliament>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Parliament>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Parliament/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to parl.gc.ca for the parts of their site in XML format.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
