package Net::Safari;

=head1 NAME

Net::Safari - Wrapper for Safari Online Books API

=head1 SYNOPSIS

  use Net::Safari
  
  my $ua = Net::Safari->new(token => 'YOUR_SAFARI_TOKEN');

  my $response = $ua->search();

  if($response->is_success()) {
      print $response->as_string();
  }
  else {
      print "Error:" . $response->message();
  }


=head1 DESCRIPTION

You can read more about Safari webservices here:
http://safari.oreilly.com/affiliates/?p=web_services

=cut


use strict;
use XML::Simple;
use LWP::UserAgent;
use URI::Escape;
use Class::Accessor;
use Class::Fields;
use Data::Dumper;
use Net::Safari::Response;

our $VERSION     = 0.02;

# hash of search operators and operator/term seperators
our %SEARCH_OPS = ( 
        CODE      => ' ',
        NOTE      => ' ',
        TITLE     => ' ',
        BOOKTITLE => ' LIKE ',
        CATEGORY  => '=',
        AUTHOR    => '=',
        ISBN      => ' LIKE ',
        PUBLDATE  => ' ',
        PUBLISHER => '=',
        );

use base qw(Class::Accessor Class::Fields);
use fields qw(token base_url ua);
Net::Safari->mk_accessors( Net::Safari->show_fields('Public') );

=head1 METHODS

=head2 new()

  $agent = Net::Safari->new( token => 'MY_SAFARI_TOKEN' );

Construct a Safari object. Token seems optional.

=cut

sub new
{
	my ($class, %args) = @_;

	my $self = bless ({}, ref ($class) || $class);

    $self->token($args{token});
    $self->base_url("http://my.safaribooksonline.com/xmlapi/");
    $self->ua( LWP::UserAgent->new( agent => "Net::Safari $VERSION", ) );

	return ($self);
}

=head1 SEARCH

=head2 BOOKTITLE
  
  $res = $ua->search( BOOKTITLE => 'samba' );

  Search book titles. This is currently broken in Safari. 
  See: http://safari.oreilly.com/xmlapi/?search=BOOKTITLE%20LIKE%20XML

=head2 TITLE

  $res = $ua->search( TITLE => 'samba' );

  Searches section titles. Will sometimes return book titles if it can't find
  any sections. I consider this a bug.
  
=head2 ISBN

  $res = $ua->search( ISBN  => '059600415X' );

  ISBN must be a complete ISBN, partial ISBN searches don't work.

=head2 CODE      

  $res = $ua->search( CODE => 'Test::More' );

  Search within code fragments. This is usually a lot more than programlistings. Code snippets that appear within a sentence are usually semanticly tagged as code. So you're just as likely to get text as you are to get program listings with this search.

=head2 NOTE      
  
  $res = $ua->search( NOTE => "web services" );

  The documentation says, "Finds matches within Tips and How-Tos." However the results seem to indicate hits in the content. 

=head2 CATEGORY  

  $res = $ua->search( CATEGORY => "itbooks.security" );

  Search within a category. The list of categories is here:
  http://safari.oreilly.com/affiliates/portals/safari/2004-07-30_Safari_Books_Category_Metadata_Abbreviations.doc

=head2 AUTHOR    

  $res = $ua->search( AUTHOR => 'Wall' );
  $res = $ua->search( AUTHOR => 'Wall, Larry' );
  $res = $ua->search( AUTHOR => 'Larry Wall' );

  Search by author.

=head2 PUBLDATE

  $res = $ua->search( PUBLDATE => '> 20041001' );
  $res = $ua->search( PUBLDATE => '< 20030101' );

  Search before or after a given publish date. The comparison operator, > or < is required.

=head2 PUBLISHER 

  $res = $ua->search( PUBLISHER => "O'Reilly" );

  Search by publisher.

=cut

sub search 
{
    my $self = shift;
    my %args = @_;

    my $token = $self->token || "";

    my $url = $self->base_url ."?";
    $url .= "token=$token&" if $token;
    $url .= "search=" . $self->_build_search_string(%args);

    my $saf_resp = $self->ua->get($url);
    my $response = Net::Safari::Response->new(xml => $saf_resp->content);

    return $response;
}

sub _build_search_clause {
    my $self     = shift;
    my $boolean  = shift;
    my $operator = shift;
    my $terms    = shift;

    return join ( ' $boolean ',
                  map { $operator . $self->_quote_search_term($_) }
                      @$terms
                 );
}

sub _build_search_string {
    my $self = shift;
    my %args = @_;

    my $search_string;
    my $terms;

    foreach my $op (keys(%SEARCH_OPS)) {
        next unless $args{$op};

        if ($args{$op} && ( ref($args{$op}) eq "ARRAY" )) {
            $terms = $args{$op};
        }
        else {
            $terms = [$args{$op}];
        }
        $search_string .= $self->_build_search_clause(   
                "OR",
                $op . $SEARCH_OPS{$op},
                $terms, 
                );
    }
    my $uri = uri_escape($search_string);
    return $uri;
}           

sub _quote_search_term {
    my $self = shift;
    my $term = shift;

    #$term =~ s/'//g;

    #$term = qq{"$term"} if $term =~ m/\s/;

    return $term;
} 
=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

  Tony Stubblebine
  cpan@tonystubblebine.com


=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO


=cut


1; 
__END__

