package t::Apps;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(%apps);

our %apps = (
    'Simple app' => 
    sub {
        return [ 200, ["My-First-Header" => 1, "My-Second-Header" => 2], [qw( foo bar )]];
    },

    'Delayed response' => 
    sub {
        return sub {
            my $responder = shift;

            $responder->( [ 200, ["My-First-Header" => 1, "My-Second-Header" => 2], [qw( foo bar )]] );
        }
    },

    'Streaming interface' => 
    sub {
        return sub {
            my $responder = shift;
            my $writer    = $responder->( [ 200, ["My-First-Header" => 1, "My-Second-Header" => 2] ] );

            $writer->write("foo");
            $writer->write("bar");
            $writer->close();
        }
    },

    'PerlIO filehandle' => 
    sub {
        my $content = "foobar";
        open my $fh, '<', \$content;

        return [ 200, ["My-First-Header" => 1, "My-Second-Header" => 2], $fh ];
    },

    'IO::Handle like object' => 
    sub {
        my @content = qw(foo bar);
        my $body = Plack::Util::inline_object(
            getline => sub { shift @content },
            close   => sub { @content = ()  },
        );

        return [ 200, ["My-First-Header" => 1, "My-Second-Header" => 2], $body ];
    },
);

1;
