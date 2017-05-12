# $Id: Simile.pm,v 1.5 2007/09/03 17:29:23 asc Exp $

use strict;

package Net::Flickr::Simile::Exhibit;
use base qw (Net::Flickr::API);

$Net::Flickr::Simile::VERSION = '0.1';

=head1 NAME

Net::Flickr::Simile - base class for Net::Flickr::Simile packages

=head1 SYNOPSIS

 There is no synopsis.

 There is only Net::Flickr::Simile::*.pm

=head2 Net::Flickr::Simile::Exhibit

 use Getopt::Std;
 use Config::Simple;
 use Net::Flickr::Simile::Exhibit;

 my %opts = ();
 getopts('c:j:h:t:', \%opts);

 my $cfg = Config::Simple->new($opts{'c'});

 my %args = ('exhibit_json' => $opts{'j'},
             'exhibit_html' => $opts{'h'},
             'tags' => $opts{'t'});

 my $fl = Net::Flickr::Simile::Exhibit->new($cfg);
 $fl->search(\%args);
 
 # So then you might do :
 # perl ./myscript -c /my/flickr.cfg -h ./mystuff.html -j ./mystuff.js -t kittens

=head1 DESCRIPTION

Base class for Net::Flickr::Simile packages

=head1 VERSION

0.1

=head1 AUTHOR

Aaron Straup Cope &lt;ascope@cpan.org&gt;

=head1 EXAMPLES

L<http://aaronland.info/perl/net/flickr/simile/exhibit.html>

L<http://aaronland.info/perl/net/flickr/simile/exhibit.js>

=head1 SEE ALSO

L<Net::Flickr::API>

L<http://simile.mit.edu/>

L<http://simile.mit.edu/exhibit>

=head1 BUGS

Please report all bugs via http://rt.cpan.org/

=head1 LICENSE

Copyright (c) 2007 Aaron Straup Cope. All Rights Reserved.

This is free software. You may redistribute it and/or
modify it under the same terms as Perl itself.

=cut

return 1;
