package Net::Lujoyglamour;

use warnings;
use strict;
use Carp;

# 1 == l 9==g Double luxury and glamour
use version; our $VERSION = qv('0.0.6.1.9'); 

use base qw/DBIx::Class::Schema Exporter/;

use String::Random qw(random_regex);
use Regexp::Common; # for %RE

our @EXPORT_OK = qw(is_valid);

our $valid_short_urls = '\w';
our $equivalent_pattern = '[A-Za-z0-9_]'; 
our $short_url_size= 16;

__PACKAGE__->load_namespaces();

sub create_new_short {
    my $schema = shift;
    my $long_url = shift || croak "What? No URL?\n";
    if ( $long_url !~ m{^http://} ) {
	$long_url = "http://$long_url";
    }
    if ( $long_url =~ m{($RE{'URI'}{'HTTP'}#?[/\w]*)} ) {
      $long_url = $1;
    } else {
	croak "Invalid URL $long_url" ;
    }
    my $want_short = shift;
    my $url_rs = $schema->resultset('Url');
    
    if ( $want_short ) { 
	my $is_there_long = $url_rs->single( { shortu => $want_short } );
	croak "Short URL '$want_short' already in use" if $is_there_long;
    }
    my $short_url = $url_rs->single( { longu => $long_url } );
    if ( !$short_url ) { # Doesn't exist, create
	my $new_pair;
	if ( $want_short ) {
	    croak "Invalid short URL $want_short" if !is_valid($want_short);
	    $short_url = $want_short;
	} else {
	    $short_url = $schema->generate_candidate_url;
	}
	$new_pair = $url_rs->new( { shortu => $short_url,
				     longu => $long_url } );
	$new_pair->insert;
    } else {
	$short_url = $short_url->short_url
    }
    if ( $short_url ne '' ) {
      return $short_url;
    } else {
      croak "Something along the way went wrong, no short URL obtained for $long_url";
    }
    
}

sub is_valid {
    my $string = shift;
    return $string =~ /^[$valid_short_urls]{1,$short_url_size}$/;
}

sub generate_candidate_url {
    my $schema = shift;
    my $candidate_url;
    my $url_rs = $schema->resultset('Url');
    my $i = 1;
    do {
	$candidate_url = random_regex($equivalent_pattern.'{1,'.$i.'}');	
    } while ( $url_rs->find( { shortu => $candidate_url } ) && ($i++ <= $short_url_size ) );
    if ( $i > $short_url_size ) { 
	croak "Url space exhausted!!";
    }
    if ( $candidate_url eq '' ) {
	croak "Couldn't generate a candidate URL!"
    }
    return $candidate_url;
}

sub get_long_for {
    my $schema = shift;
    my $short_url = shift;
    my $result =  $schema->resultset('Url')->single({shortu => $short_url});
    if ( defined $result ) {
	return $result->long_url;
    } else {
	return;
    }
}
    
"lujo and glamour all over"; # Magic true value required at end of module

__END__

=head1 NAME

Net::Lujoyglamour - Create short URLs with luxury and glamour

=head1 VERSION

This document describes Net::Lujoyglamour version 0.0.5.1.9

=head1 SYNOPSIS

    use Net::Lujoyglamour qw(is_valid);

    #Deploy database
    my $dsn = 'dbi:SQLite:dbname=:memory:';
    my $schema = Net::Lujoyglamour->connect($dsn);
    $schema->deploy({ add_drop_tables => 1});

    #Most straighforward way to use
    if ( is_valid( "shortie" ) {
        $schema->create_new_short( "very.long.url/like/this",
                                   "shortie" );
    }
    $schema->create_new_short( "even.longer.url/this/and/that" );

=head1 DESCRIPTION

Model/Control part of a framework intended for creating short
    URLs. Inherits from L<DBIx::Class>; adds functionality for
    creating a keeping a table of long/short URLs. Funky name comes
    from the novel C< lujoyglamour.net >, in Spanish, which I also
    wrote (and obtained a literary price), and you can check out at
    L<http://lujoyglamour.es> or buy at
    L<http://compra.lujoyglamour.net>. 

The module has been tested with SQLite and MySQL, and is in fact
    running using both. You just need to change the C<$dsn> for using
    either. It hasn't been tested using other databases; would be
    grateful if anybody tried/patched for these.

=head1 INTERFACE 
    
=head2 connect( $dsn[, $username] [, $password] [, \%attr] )

Actually, inherited from L<DBIx::Class>, but useful here too

=head2 deploy

Also inherited, used for creating the database from the schema
    description in the class

=head2 is_valid( $string )

Check for requested short URL validity; only alphanumeric characters
    are allowed 

=head2 generate_candidate_url

Generates a random URL with the character limitation set. It checks
    URLs with increasing size, until it finds one.

=head2 create_new_short ( $long_url[, $short_url] )

Creates and inserts into the database a new short URL, optionally
    using a requested short URL. 

=head2 get_long_for ( $short_url )

Returns the long URL that corresponds to the short one

=head1 DIAGNOSTICS

=over

=item C<< Url space exhausted!! >> 

No more URLs availables. You probably have a very successful URL shortener site. 
You already used up all available short addresses. Time to expand your
    database!

=item C<< Invalid short URL $want_short >>

The requested URL is invalid

=back


=head1 CONFIGURATION AND ENVIRONMENT

You need to have a database system ready and able. If there's none
    installed, SQLite will do nicely, but do check reading/writing
    permissions over the file. Use the C<app/lg-deploy> script,
    modified for your environment, to create the initial environment. 

There are some template and CGI examples under the C<app/> directory of the
    distribution. Check them for usage, or use your own. You only need
    to keep the filenames of the C<.html> files and copy them in the
    same directory as the CGI. A C<htaccess> file is also provided as
    an example; you will have to modify it with the actual file names
    you will be using. 

=head1 DEPENDENCIES

L<DBIx::Class>, L<String::Random>, L<Regexp::Common> and drivers for
    database system. If you want to use the provided WebApp, you will
    need L<CGI::Application> and corresponding drivers.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Other than the limited space available, for the time being there are
    none. 

Please report any bugs or feature requests to
C<bug-net-lujoyglamour@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

The module is used with a SQLite database at the site
    L<http://lugl.info/>, and with MySQL at L<http://l-g.me> (in
    Spanish). Any comments and suggestions are welcome. If you decide
    to run your URL shortener on this, please let me know.

Other URL shortening modules you might want to check out are
L<CGI::Shorten>, L<WWW::Shorten::MakeAShorterLink> and L<WWW::Shorten>, which is rather an interface for
available URL shortening services.

There is an example app at the aptly named C< app > directory,
    retrieve it from your CPAN directory or from the CPAN website.

This version includes the PDF of the novel lujoyglamour.net,
    distributed with a CC licence, in Spanish. Look under the C<t/>
    directory, and read it using your favorite PDF browser or ebook
    reader. If you publish a review, please trackback
    L<http://lujoyglamour.es> .

=head1 ACKNOWLEDGEMENTS

CPANTS tester Sebastian Woetzel helped me fix a bug in my tests
    scripts. 

=head1 AUTHOR

JJ Merelo  C<< <jj@merelo.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, 2010, JJ Merelo C<< <jj@merelo.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
