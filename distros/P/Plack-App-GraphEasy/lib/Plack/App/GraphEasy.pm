package Plack::App::GraphEasy;
use strict;
use warnings;
use parent qw/Plack::Component/;
use Graph::Easy;
use Graph::Easy::Parser;
use Plack::Request;
use HTTP::Status qw//;
use Plack::Util::Accessor qw/
    stderr
    timeout
/;

our $VERSION = '0.01';

our $FORM_HTML = <<'_HTML_';
<html>
<head>
<meta charset="utf-8">
<title>GraphEasy</title>
</head>
<body>
Manual: <a href="http://bloodgate.com/perl/graph/manual/" target="_blank">http://bloodgate.com/perl/graph/manual/</a>
<br>
<textarea name="txt" id="txt" style="width:80%%;height:70px;"></textarea>
<br>
<input type="button" name="send" value="Send" id="btn"> <input type="reset" value="reset" id="reset_btn">
<div id="result">
<pre id="graph" style="font-family:"monospace";"></pre>
</div>
<script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>
<script>
$(document).ready(function(){
  $("#btn").click(function(){
    var text = $('#txt').val();
    $.ajax({
      type: 'post',
      url: '%s',
      data: {
        'text': text
      },
      cache: false,
      async: false,
      dataType: 'html',
      timeout: 10000,
      success: function(data) {
        $('#graph').text(data);
      },
      error : function(xhr, text, error) {
        $('#graph').text(xhr.status+': '+text);
      }
    });
  });
  $("#reset_btn").click(function(){
    $('#txt').val('');
    $('#graph').text('');
  });
});
</script>
</body>
</html>
_HTML_

sub call {
    my ($self, $env) = @_;

    my $req    = Plack::Request->new($env);
    my $method = $req->method;

    if ($method eq 'GET') {
        return $self->_put_form($req);
    }
    elsif ($method eq 'POST') {
        return $self->_put_graph($req);
    }

    return $self->_return_status(404);
}

sub _put_form {
    my ($self, $req) = @_;

    my $content = sprintf(
        $FORM_HTML,
        $req->path,
    );

    return $self->_return_success($content, 'text/html; charset=UTF-8');
}

sub _put_graph {
    my ($self, $req) = @_;

    my $input_text = $req->param('text')
        or return $self->_return_success('no text');
    $input_text =~ s/^[\s\t\r\n]+//g;
    $input_text =~ s/[\s\t\r\n]+$//g;

    if ($input_text !~ m![\]\}]$!) {
        return $self->_return_success('wrong text');
    }

    my $parser = Graph::Easy::Parser->new;
    my $graph  = $parser->from_text($input_text);
    if (!$graph) {
        return $self->_return_status(500, "Error: something wrong");
    }
    if ($parser->error) {
        return $self->_return_success("Error: ". $parser->error);
    }

    $graph->timeout($self->timeout || 10);

    my $result;
    eval {
        $result = $graph->as_ascii;
    };
    if (my $e = $@) {
        if ($e =~ m!layout did not finish in time!) {
            return $self->_return_success("timeout");
        }
        return $self->_return_status(500, "Error: $e");
    }

    return $self->_return_success($result);
}

sub _return_success {
    my ($self, $msg, $content_type) = @_;

    return [
        200,
        [
            'Content-Type'   => $content_type || 'text/plain',
            'Content-Length' => length $msg
        ],
        [$msg]
    ];
}

sub _return_status {
    my $self        = shift;
    my $status_code = shift || 500;
    my $err         = shift || '';

    my $msg = HTTP::Status::status_message($status_code);

    if ($self->stderr) {
        print STDERR "$msg\n$err\n";
    }

    return [
        $status_code,
        [
            'Content-Type' => 'text/plain',
            'Content-Length' => length $msg
        ],
        [$msg]
    ];
}

1;

__END__

=encoding UTF-8

=head1 NAME

Plack::App::GraphEasy - The ASCII Graph Application


=head1 SYNOPSIS

.psgi

    use Plack::Builder;
    use Plack::App::GraphEasy;

    builder {
        mount '/' => Plack::App::GraphEasy->new->to_app;
    };

or CLI one liner

    plackup -MPlack::App::GraphEasy -e 'Plack::App::GraphEasy->new->to_app'

Then you can access to 'GET /'.

=head1 DESCRIPTION

Plack::App::GraphEasy gives the web interface of L<Graph::Easy> which is ASCII graph generator.

input:

    [ A ] -> [ B ] -> [ C ]

output:

    +---+     +---+     +---+
    | A | --> | B | --> | C |
    +---+     +---+     +---+

see more detail: L<http://bloodgate.com/perl/graph/manual/>


=head1 METHOD

=head2 call

graph app


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/Plack-App-GraphEasy"><img src="https://secure.travis-ci.org/bayashi/Plack-App-GraphEasy.png"/></a> <a href="https://coveralls.io/r/bayashi/Plack-App-GraphEasy"><img src="https://coveralls.io/repos/bayashi/Plack-App-GraphEasy/badge.png?branch=master"/></a>

=end html

Plack::App::GraphEasy is hosted on github: L<http://github.com/bayashi/Plack-App-GraphEasy>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Graph::Easy>

L<graph-easy>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
