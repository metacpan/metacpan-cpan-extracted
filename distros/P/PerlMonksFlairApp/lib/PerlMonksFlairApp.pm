package PerlMonksFlairApp;
use Dancer ':syntax';
use WWW::Mechanize;
use HTML::TokeParser;
use GD;

set logger => 'file';
set log => info;

our $VERSION = '0.2';

get '/' => sub {
    return template 'index';
};
get qr{/([\w -.]+)\.jpg}  => sub {
    
    my ($req_username) = splat;
    info("User => $req_username");
    my $xp = 0;#experience
    my $wr = 0;#writeups
    my $lvl = "";#level
    my $agent = WWW::Mechanize->new();

    $agent->get("http://www.perlmonks.org/?node=$req_username&type=user");
#    debug $agent->{content}; # bah dummy. You're always looking at a logged out version of the page from code!
    my $stream = HTML::TokeParser->new(\$agent->{content});
    my $username = "-none-";

    if ($stream->get_tag('title')) {
	$username = $stream->get_trimmed_text;
    }
    #if the title is Super Search then username supplied is incorrect.

    while(my $tag = $stream->get_tag('td'))
    {
	# $tag will contain this array => [$tag, $attr, $attrseq, $text]
	if($stream->get_trimmed_text("/td") eq "Experience:") {
	    $stream->get_tag('td');
	    $xp = $stream->get_trimmed_text("/td");
	    #debug "Set xp";
	    $stream->get_tag("td");
	}
	if($stream->get_trimmed_text("/td") eq "Level:") {
	    $stream->get_tag('td');
	    $lvl = $stream->get_trimmed_text("/td");
	    #debug "set lvl";
	    $stream->get_tag("td");
	}
	if($stream->get_trimmed_text("/td") eq "Writeups:") {
	    $stream->get_tag('td');
	    $wr = $stream->get_trimmed_text("/td");
	    #debug "set witeups";
	    $stream->get_tag("td");
	}
    }
    $lvl =~ m/(\d+)/;
    my $l = $1;#just moved to another variable for feeling's sake.
    #debug "$username => Xp: $xp\n $wr level = $lvl L =$l";
#    my $to_print = "$username\nLevel: $lvl\nExperience: $xp";
    my $im = undef;
    
    eval {
	$im = newFromJpeg GD::Image(join('/', setting('public'), "/badges/$l.jpg")) ;
    };
    $im->trueColor(1);
    my $white = $im->colorResolve(255,255,255);
    my $black = $im->colorResolve(0,0,0);
    #debug "color is: $black";

    my $xp_color = $white;
    if($xp =~ /none/)
    {
	    $xp = 0;
    }
    if($xp >= 250 and $xp < 400)
    {
	$xp_color = $black;
    }
    $im->stringFT($black, join('/', setting('public'), '/Open_Sans/OpenSans-Bold.ttf'),10 , 0, 110,  40, $username);
    $im->stringFT($black, join('/', setting('public'), '/Open_Sans/OpenSans-Bold.ttf'), 9, 0, 110,  60, $lvl);
    $im->stringFT($xp_color, join('/', setting('public'), '/Open_Sans/OpenSans-Bold.ttf'), 9 , 0, 110,  75, "Experience ".$xp);
    #debug "Error opening image: $@" if $@;
    content_type 'image/jpeg';
    return $im->jpeg;
};

true;
__END__ #END of module

=head1 NAME
 
PerlMonksFlairApp  - www.perlmonksflair.com : Share flair badges from perlmonks.org 
 
=head1 CONCEPT
 
This project is a simple tribute to L<www.perlmonks.org> . It generates a badge 
according to the 30 fancy titles you get when you are a user on that site.

=head1 INSTALL INSTRUCTIONS

My username is C<gideondsouza>, as of today I happen to be a Pilgrim, Level 8. 
Here is my flair: L<http://www.perlmonksflair.com/gideondsouza.jpg>

Here is the site live  : L<www.perlmonksflair.com>
 
Once you install this module, all you need to do is :

    $ perl /path/to/module/bin/app.pl --port=1234
    $ #now you have the site running at localhost:1234

Open your browser and try C<http://localhost:1234/your_perlmonks_username.jpg> 
and you should see an appropriate flair badge. This is an example of running 
on the L<Dancer> standalone server. You could of course run it on a number 
of other servers including Apache and what not.

I used the nifty L<Dancer> web framework, do checkout L<Dancer2> for an even
niftier web framework. On the site live I 
use L<Varnish|https://www.varnish-cache.org/> to cache images and L<Starman> 
as my server. The front end is bootstrap if you still haven't seen the site :)
The whole thing runs on a L<CentOS|http://www.centos.org/> box.

=head1 AUTHOR
 
Gideon Israel Dsouza, C<< <gideon at cpan.org> >>, L<http://www.gideondsouza.com>
The artwork for this project was done by L<Jennifer Leigh Holt|http://jenniferleigh.ca/> 

=head1 SUPPORT and BUGS
 
Please file issues, comments, feedbacks and bugs into the github repository here:
L<https://github.com/gideondsouza/perlmonksflair/issues/new>. 
 
=head1 ACKNOWLEDGEMENTS
 
The artwork for this project was done by L<Jennifer Leigh Holt|http://jenniferleigh.ca/>
 
=head1 LICENSE AND COPYRIGHT
 
Copyright 2013 Gideon Israel Dsouza.
 
This project is open source here : L<https://github.com/gideondsouza/perlmonksflair>. 
 
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
 
See http://dev.perl.org/licenses/ for more information.
 
=cut
