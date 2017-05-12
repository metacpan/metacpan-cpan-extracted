package RDF::AllegroGraph::Repository3;

use strict;
use warnings;

use base qw(RDF::AllegroGraph::Repository);

use Data::Dumper;
use feature "switch";

use JSON;
use URI::Escape qw/uri_escape_utf8/;

use HTTP::Request::Common;

=pod

=head1 NAME

RDF::AllegroGraph::Repository3 - AllegroGraph repository handle for AGv3

=cut

sub new {
    my $class = shift;
    my %options = @_;
    my $self = bless \%options, $class;
    $self->{path} = $self->{CATALOG}->{SERVER}->{ADDRESS} . '/catalogs' . $self->{CATALOG}->{NAME} . '/repositories/' . $self->{id};
    return $self;
}

sub id {
    my $self = shift;
    return $self->{CATALOG}->{NAME} . '/' . $self->{id};
}

sub disband {
    my $self = shift;
    my $requ = HTTP::Request->new (DELETE => $self->{path});
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request ($requ);
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
}

sub size {
    my $self = shift; 
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->get ($self->{path} . '/size');
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success; 
    return $resp->content;
}

sub add {
    _put_post_stmts ('POST', @_);
}

sub _put_post_stmts {
    my $method = shift;
    my $self   = shift;

    my @stmts;                                                                  # collect triples there
    my $n3;                                                                     # collect N3 stuff there
    my @files;                                                                  # collect file names here
    use Regexp::Common qw/URI/;

    foreach my $item (@_) {                                                     # walk through what we got
	if (ref($item) eq 'ARRAY') {                                            # a triple statement
	    push @stmts, $item;
	} elsif (ref ($item)) {
	    die "don't know what to do with it";
	} elsif ($item =~ /^$RE{URI}{HTTP}/) {
	    push @files, $item;
	} elsif ($item =~ /^$RE{URI}{FTP}/) {
	    push @files, $item;
	} elsif ($item =~ /^$RE{URI}{file}/) {
	    push @files, $item;
	} else {                                                                # scalar => N3
	    $n3 .= $item;
	}
    }

    my $ua = $self->{CATALOG}->{SERVER}->{ua};                                  # local handle

    if (@stmts) {                                                               # if we have something to say to the server
	given ($method) {
	    when ('POST') {
		my $resp  = $ua->post ($self->{path} . '/statements',
				       'Content-Type' => 'application/json', 'Content' => encode_json (\@stmts) );
		die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
	    }
	    when ('PUT') {
		my $requ = HTTP::Request->new (PUT => $self->{path} . '/statements',
					       [ 'Content-Type' => 'application/json' ], encode_json (\@stmts));
		my $resp = $ua->request ($requ);
		die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
	    }
	    when ('DELETE') {                                                     # DELETE
		# first bulk delete facts, i.e. where there are no wildcards
		my @facts      = grep { defined $_->[0]   &&   defined $_->[1] &&   defined $_->[2] } @stmts;
		my $requ = HTTP::Request->new (POST => $self->{path} . '/statements/delete',
					       [ 'Content-Type' => 'application/json' ], encode_json (\@facts));
		my $resp = $ua->request ($requ);
		die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;

		# the delete one by one those with wildcards
		my @wildcarded = grep { ! defined $_->[0] || ! defined $_->[1] || ! defined $_->[2] } @stmts;
		foreach my $w (@wildcarded) {
		    my $requ = HTTP::Request->new (DELETE => $self->{path} . '/statements' . '?' . _to_uri ($w) );
		    my $resp = $ua->request ($requ);
		    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
		}
	    }
	    default { die $method; }
	}
    }
    if ($n3) {                                                                  # if we have something to say to the server
	my $requ = HTTP::Request->new ($method => $self->{path} . '/statements', [ 'Content-Type' => 'text/plain' ], $n3);
	my $resp = $ua->request ($requ);
	die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
    }
    for my $file (@files) {                                                     # if we have something to say to the server
	use LWP::Simple;
	my $content = get ($file) or die "Could not open URL '$file'";
	my $mime;                                                               # lets guess the mime type
	given ($file) {                                                         # magic does not normally cope well with RDF/N3, so do it by extension
	    when (/\.n3$/)  { $mime = 'text/plain'; }                           # well, not really, since its text/n3
	    when (/\.nt$/)  { $mime = 'text/plain'; }
	    when (/\.xml$/) { $mime = 'application/rdf+xml'; }
	    when (/\.rdf$/) { $mime = 'application/rdf+xml'; }
	    default { die; }
	}

	my $requ = HTTP::Request->new ($method => $self->{path} . '/statements', [ 'Content-Type' => $mime ], $content);
	my $resp = $ua->request ($requ);
	die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;

	$method = 'POST';                                                        # whatever the first was, the others must add to it!
    }


}

sub _to_uri {
    my $w = shift;
    my @params;
    push @params, 'subj='.$w->[0] if $w->[0];
    push @params, 'pred='.$w->[1] if $w->[1];
    push @params, 'obj=' .$w->[2] if $w->[2];
    return join ('&', @params);   # TODO URI escape?
}

sub replace {
    _put_post_stmts ('PUT', @_);
}

sub delete {
    _put_post_stmts ('DELETE', @_);
}

sub match {
    my $self = shift;
    my @stmts;

    my $ua = $self->{CATALOG}->{SERVER}->{ua};
    foreach my $w (@_) {
	my $resp  = $ua->get ($self->{path} . '/statements' . '?' . _to_uri ($w));
	die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
	push @stmts, @{ from_json ($resp->content) };
    }
    return @stmts;
}

sub sparql {
    my $self = shift;
    my $query = shift;
    my %options = @_;
    $options{RETURN} ||= 'TUPLE_LIST';        # a good default

    my @params;
    push @params, 'queryLn=sparql';
    push @params, 'query='.uri_escape_utf8 ($query);
    
    my $resp  = $self->{CATALOG}->{SERVER}->{ua}->get ($self->{path} . '?' . join ('&', @params) );
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;

    my $json = from_json ($resp->content);
    given ($options{RETURN}) {
	when ('TUPLE_LIST') {
	    return @{ $json->{values} };
	}
	default { die };
    }
}

sub namespaces {
    my $self = shift;
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->get ($self->{path} . '/namespaces');
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
    return
	map { $_->{prefix} => $_->{namespace} }
	@{ from_json ($resp->content) };
}

sub namespace {
    my $self = shift;
    my $prefix = shift;

    my $uri = $self->{path} . '/namespaces/' . $prefix;
    if (scalar @_) {   # there was a second argument!
        if (my $nsuri = shift) {
	    my $requ = HTTP::Request->new ('PUT' => $uri, [ 'Content-Type' => 'text/plain' ], $nsuri);
	    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request ($requ);
	    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
	    return $nsuri;
	} else {
	    my $requ = HTTP::Request->new ('DELETE' => $uri);
	    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request ($requ);
	    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
	}
    } else {
	my $resp = $self->{CATALOG}->{SERVER}->{ua}->get ($uri);
	return undef if $resp->code == 404;
	die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
	return $resp->content =~ m/^"?(.*?)"?$/ && $1;
    }
}

sub geotypes {
    my $self = shift;
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->get ($self->{path} . '/geo/types');
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
    return  @{ from_json ($resp->content) };
}

sub cartesian {
    my $self = shift;

    my $url = new URI ($self->{path} . '/geo/types/cartesian');

    use Regexp::Common;
    if ($_[0] =~ /($RE{num}{real})x($RE{num}{real})(\+($RE{num}{real})\+($RE{num}{real}))?/) {
	shift;
	my ($W, $H, $X, $Y) = ($1, $2, $4||0, $5||0);
	my $stripW = shift;
	$url->query_form (stripWidth => $stripW, xmin => $X, xmax => $X+$W, ymin => $Y, ymax => $Y+$H);
    } else {
	my ($X1, $Y1, $X2, $Y2, $stripW) = @_;
	$url->query_form (stripWidth => $stripW, xmin => $X1, xmax => $X2, ymin => $Y1, ymax => $Y2);
    }

    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request (PUT $url);
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
    return $resp->content =~ m/^"?(.*?)"?$/ && $1;
}

sub inBox {
    my $self    = shift;
    my $geotype = shift;
    my $pred    = shift;
    my ($xmin, $ymin, $xmax, $ymax) = @_;
    my $options = $_[4];

    my $url = new URI ($self->{path} . '/geo/box');
    $url->query_form (type => $geotype,
		      predicate => $pred,
		      xmin => $xmin,
		      ymin => $ymin,
		      xmax => $xmax,
		      ymax => $ymax,
		      ($options && defined $options->{limit}
		        ? (limit => $options->{limit})
			   : ())
		      );
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request (GET $url);
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
    return @{ from_json ($resp->content) };
}

sub inCircle {
    my $self    = shift;
    my $geotype = shift;
    my $pred    = shift;
    my ($x, $y, $radius) = @_;
    my $options = $_[3];

    my $url = new URI ($self->{path} . '/geo/circle');
    $url->query_form (type      => $geotype,
		      predicate => $pred,
		      x         => $x,
		      y         => $y,
		      radius    => $radius,
		      ($options && defined $options->{limit}
		        ? (limit => $options->{limit})
			   : ())
		      );
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->request (GET $url);
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
    return @{ from_json ($resp->content) };
}


our $VERSION  = '0.04';

1;

__END__
