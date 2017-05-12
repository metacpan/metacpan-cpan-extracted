#!/usr/bin/perl

# This example demonstrates how one can fetch request information

package MyWebsite::InfoDump;

use strict;
use warnings;
use TUWF ':html';


TUWF::register(
  qr/info/       => \&info,
  qr{info/forms} => \&forms,
);


sub info {
  my $self = shift;

  my $tr = sub { Tr; td shift; td shift; end };

  html;
   head;
    style type => 'text/css';
     txt 'thead td { font-weight: bold }';
     txt 'td { border: 1px outset; padding: 3px }';
    end;
   end;
   body;
    h1 'TUWF Info Dump';
    p;
     txt 'You can use ';
     a href => '/info/forms', 'these forms';
     txt ' to generate some interesting GET/POST data.';
    end;

    h2 'GET Parameters';
    table;
     thead; Tr; td 'Name'; td 'Value'; end; end;
     $tr->($_, join "\n---\n", $self->reqGet($_)) for ($self->reqGet());
    end;

    h2 'POST Parameters';
    table;
     thead; Tr; td 'Name'; td 'Value'; end; end;
     $tr->($_, join "\n---\n", $self->reqPost($_)) for ($self->reqPost());
    end;

    h2 'Uploaded files';
    table;
     thead; Tr; td 'Name'; td 'File size - File name - Mime type'; end; end;
     $tr->($_, length($self->reqUploadRaw($_)).' - '.$self->reqPOST($_).' - '.$self->reqUploadMIME($_)) for ($self->reqUploadMIME());
    end;

    h2 'HTTP Headers';
    table;
     thead; Tr; td 'Header'; td 'Value'; end; end;
     $tr->($_, $self->reqHeader($_)) for ($self->reqHeader());
    end;

    h2 'HTTP Cookies';
    table;
     thead; Tr; td 'Cookie'; td 'Value'; end; end;
     $tr->($_, $self->reqCookie($_)) for ($self->reqCookie());
    end;

    h2 'Misc. request functions';
    table;
     thead; Tr; td 'Function'; td 'Return value'; end; end;
     $tr->($_, eval "\$self->$_;") for(qw{
       reqMethod() reqPath() reqBaseURI() reqURI() reqHost() reqIP()
     });
    end;
  end;
}


sub forms {
  html;
   body;
    h1 'Forms for generating some input for /info';
    a href => '/info', 'Back to /info';

    h2 'GET';
    form method => 'GET', action => '/info';
     for (0..5) {
       input type => 'checkbox', name => 'checkthing', value => $_, id => "checkthing_$_", $_%2 ? (checked => 'checked') : ();
       label for => "checkthing_$_", "checkthing $_";
     }
     br;
     label for => 'textfield', 'Text field: ';
     input type => 'text', name => 'textfield', id => 'textfield', value => 'Hello Text Field!';
     br;
     input type => 'submit';
    end;

    h2 'POST (urlencoded)';
    form method => 'POST', action => '/info';
     for (0..5) {
       input type => 'checkbox', name => 'checkbox', value => $_, id => "checkbox_$_", $_%2 ? (checked => 'checked') : ();
       label for => "checkbox_$_", "checkbox $_";
     }
     br;
     label for => 'text', 'Text: ';
     use utf8;
     input type => 'text', name => 'text', id => 'text', value => 'こんにちは';
     br;
     input type => 'submit';
    end;

    h2 'POST (multipart)';
    form method => 'POST', action => '/info', enctype => 'multipart/form-data';
     for (0..5) {
       input type => 'checkbox', name => 'check', value => $_, id => "check_$_", $_%2 ? (checked => 'checked') : ();
       label for => "check_$_", "check $_";
     }
     br;
     label for => 'file1', 'File 1: '; input type => 'file', name => 'file1', id => 'file1';
     br;
     label for => 'file2', 'File 2: '; input type => 'file', name => 'file2', id => 'file2';
     br;
     input type => 'submit';
    end;

   end;
  end;
}


1;

