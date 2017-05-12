use strict;
use warnings;
package Plack::App::DAIA::Validator;
#ABSTRACT: DAIA validator and converter
our $VERSION = '0.55'; #VERSION
use CGI qw(:standard);
use Encode;
use File::ShareDir qw(dist_dir);
use File::Spec::Functions qw(catfile);

use parent 'Plack::App::DAIA';
use Plack::Util::Accessor qw(xsd xslt warnings);

our $HAS_LIBXML = 0;

our ($FORMATS);
BEGIN {
    my %f = DAIA->formats;
    $FORMATS = { map { $_ => $_ } keys %f };
    $FORMATS->{html}     = 'DAIA/HTML';
    $FORMATS->{json}     = 'DAIA/JSON';
    $FORMATS->{xml}      = 'DAIA/XML';
    $FORMATS->{rdfjson}  = 'DAIA/RDF (JSON)';
    $FORMATS->{turtle}   = 'DAIA/RDF (Turtle)'   if $FORMATS->{turtle};
    $FORMATS->{ntriples} = 'DAIA/RDF (NTriples)' if $FORMATS->{ntriples};
    $FORMATS->{rdfxml}   = 'DAIA/RDF (RDF/XML)'  if $FORMATS->{rdfxml};
    foreach (qw(dot svg)) {
        $FORMATS->{$_} = "DAIA/RDF graph ($_)" if $FORMATS->{$_};
    }
}

sub init {
    my $self = shift;
    if ($self->xsd) {
        ## no critic
        eval "use XML::LibXML";
        $HAS_LIBXML = !$@;
    }
}

sub call {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);

    # serve parts of the XSLT client
    my $res = $self->call_client($req);
    return $res if $res;

    my $msg = "";
    my $error = "";
    my $url  = $req->param('url') || '';
    my $data = $req->param('data') || '';
    #eval{ $data = Encode::decode_utf8( $data ); }; # icoming raw data is UTF-8

    my $eurl = $url; # url_encode
    $eurl =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;

    my $xsd = $self->xsd;

    my $informat  = lc($req->param('in') || '');
    my $outformat = lc($req->param('out') || $req->param('format') || 'html');

    my $callback  = $req->param('callback') || "";
    $callback = "" unless $callback =~ /^[a-z][a-z0-9._\[\]]*$/i;

    my @daiaobjs;

    # parse DAIA
    if ( $data ) {
        @daiaobjs = eval { DAIA->parse( data => $data, format => $informat ) };
    } elsif( $url ) {
        @daiaobjs = eval { DAIA->parse( file => $url, format => $informat ) };
    }
    if ($@) {
        $error = $@;
        $error =~ s/DAIA::([A-Z]+::)?[a-z_]+\(\):| at .* line.*//ig;
    }

    my $daia;
    if (@daiaobjs > 1) {
        $error = "Found multiple DAIA elements (".(scalar @daiaobjs)."), but expected one";
    } elsif (@daiaobjs) {
        $daia = shift @daiaobjs;
    }

    if ( $FORMATS->{$outformat} and $outformat ne 'html' ) {
        $daia = DAIA::Response->new() unless $daia;
        $daia->addMessage( $error, errno => 500, lang => 'en' ) if $error;
        return $self->as_psgi( 200, $daia, $outformat, $req->param('callback') );
    } elsif ( $outformat ne 'html' ) {
        $error = "Unknown output format - using HTML instead";
    }

    # HTML output
    $error = "<div class='error'>".escapeHTML($error)."!</div>" if $error;
    if ( $url and not $data ) {
        $msg = "Data was fetched from URL " . a({href=>$url},escapeHTML($url));
        $msg .= " (" . a({href=>'#result'}, "result...") . ")" if $daia;
        $msg =  div({class=>'msg'},$msg);
#        $msg .= div({class=>'msg'},"Use ".
#                    a({href=>url()."?url=$eurl"},'this URL') .
#                    " to to directly pass the URL to this script.");
    }

    my $html = <<HTML;
<html>
<head>
  <title>DAIA Validator</title>
  <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
  <style>
    body { font-family: arial, sans-serif;}
    h1, p { margin: 0; text-align: center; }
    h2 { margin-top: 2px; border-bottom: 1px dotted #666;}
    form { margin: 1em; border: 1px solid #333; }
    fieldset { border: 1px solid #fff; }
    label, .error, .msg { font-weight: bold; }
    .submit, .error { font-size: 120%; }
    .error { color: #A00; margin: 1em; }
    .ok { color: #0A0; margin: 1em; }
    .msg { color: #0A0; margin: 1em; }
    .footer { font-size: small; margin: 1em; }
    #result { border: 1px dotted #666; margin: 1em; padding: 0.5em; }
  </style>
</head>
<body>
<h1 id='top'>DAIA Validator/Converter</h1>
<p>Convert and Validate <a href="http://purl.org/NET/DAIA">DAIA response format</a></p>
<form method="post" accept-charset="utf-8" action="">
HTML

    $html .= $msg . $error .
     fieldset(label('Input: ',
            popup_menu('in',['','json','xml'],'',
                       {''=>'Guess','json'=>'DAIA/JSON','xml'=>'DAIA/XML'})
      )).
      fieldset('either', label('URL: ', textfield(-name=>'url', -size=>70, -value => $url)),
        'or', label('Data:'),
        textarea( -name=>'data', -rows=>20, -cols=>80, -value => $data),
      ).
      fieldset(
        label('Output: ',
            popup_menu('out',
                [ sort { $FORMATS->{$a} cmp $FORMATS->{$b} } keys %$FORMATS ],
                $outformat, $FORMATS )
        ), '&#xA0;',
        label('JSONP Callback: ', textfield(-name=>'callback',-value=>$callback))
      ).
      fieldset('<input type="submit" value="Convert" class="submit" />')
    ;
    my $has_graphviz = grep /^(svg|dot)$/, keys %$FORMATS;
    if ( $has_graphviz && $url && !$data) {
       $html .= "<fieldset>See RDF graph <a href=\"?url=$eurl&format=svg\">as SVG</a></fieldset>";
    }
    $html .= '</form>';

    if ($daia) {
      if ( $informat eq 'xml' or DAIA::guess($data) eq 'xml' ) {
        # TODO: move this into module DAIA (validate option when parsing)
        my ($schema, $parser);
        if ($xsd) {
            if (!$HAS_LIBXML) {
                $error = "XML::LibXML not found - validating skipped";
            } else {
                $parser = XML::LibXML->new;
                $schema = eval {
                    XML::LibXML::Schema->new(
                        location => catfile(dist_dir('Plack-App-DAIA'),'daia.xsd')
                    );
                };
                if ($schema) {
                    my $doc = $parser->parse_string( $data );
                    eval { $schema->validate($doc) };
                    $error = "DAIA/XML not valid but parseable: " . $@ if $@;
                } else {
                    $error = "Could not load XML Schema - validating skipped";
                }
            }
        }
        if ( $error ) {
          $html .= "<p class='error'>".escapeHTML($error)."</p>";
        } else {
          $html .= "<p class='ok'>DAIA/XML valid according to ".a({href=>$xsd},"this XML Schema")."</p>";
        }
      } else {
         $html .= p("validation is rather lax so the input may be invalid - but it was parseable");
      }
      $html .= "<div id='result'>";
      my ($pjson, $pxml, $pttl) = ("","","");
      if (!$data && $url) {
        $pjson = $pxml = $pttl = "?callback=$callback&url=$eurl";
        $pjson = " (<a href='$pjson&format=json'>get via proxy</a>)";
        $pxml  = " (<a href='$pxml&format=xml'>get via proxy</a>)";
        #$pttl  = " (<a href='$pttl&format=turtle'>get via proxy</a>)";
      }
      $html .= "<h2 id='json'>Result in DAIA/JSON$pjson <a href='#top'>&#x2191;</a> <a href='#xml'>&#x2193;</a></h2>";
      $html .= pre(escapeHTML( encode('utf8',$daia->json( $callback ) )));
      $html .= "<h2 id='xml'>Result in DAIA/XML$pxml <a href='#json'>&#x2191;</a></h2>";
      $html .= pre(escapeHTML( encode('utf8',$daia->xml( xmlns => 1 ) )));
      if ($FORMATS->{turtle}) {
        $html .= "<h2 id='ttl'>Result in DAIA/RDF (Turtle) <a href='#json'>&#x2191;</a></h2>";
        my $ttl = $daia->serialize('turtle');
        $html .= pre(escapeHTML( encode('utf8', $ttl )));
      }
      $html .= "</div>";
    }

    $html .= "<div class='footer'>Based on ";
    $html .= join ' and ', map {
        "<a href='http://search.cpan.org/perldoc?$_'>$_</a> " . ($_->VERSION || '');
    } qw(Plack::App::DAIA::Validator DAIA);
    $html .= <<HTML;
. Visit the <a href="http://github.com/gbv/daia/">DAIA project at github</a> for sources and details.
</div></body>
HTML

    return [ 200, [ 'Content-Type' => 'text/html; charset=utf-8' ], [ $html ] ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::DAIA::Validator - DAIA validator and converter

=head1 VERSION

version 0.55

=head1 SYNOPSIS

    use Plack::Builder;
    use Plack::App::DAIA::Validator;

    builder {
        enable 'JSONP';
        Plack::App::DAIA::Validator->new(
            xsd      => $location_of_daia_xsd,
            warnings => 1
        );
    };

=head1 DESCRIPTION

This module provides a simple L<DAIA> validator and converter as PSGI web
application.

To support fetching from DAIA Servers via HTTPS you might need to install
L<LWP::Protocol::https> version 6.02 or higher.

=head1 CONFIGURATION

See L<Plack::App::DAIA> for documentation of options C<xslt>, C<warnings>, and
C<xsd>. L<XML::LibXML> must be installed if C<xsd> is set to validate DAIA/XML.

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
