use strict;
use warnings;

use File::Basename qw(dirname);

BEGIN {
    unshift @INC, dirname(__FILE__) . '/../lib';
}

use Plack::App::EventSource;
use Plack::Builder;

builder {
    mount '/events' => Plack::App::EventSource->new(
        handler_cb => sub {
            my ($conn, $env) = @_;

            my $i = 0;
            while ($i < 10) {
                $conn->push($i++);

                sleep 1;
            }

            $conn->close;
        }
    )->to_app;

    mount '/' => sub {
        my $env = shift;

        return [200, ['Content-Type' => 'text/html; charset=UTF-8'], [<<'END']];
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>EventSource example app</title>
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <script>
      var es = new EventSource("/events");
      var listener = function (event) {
        var div = document.createElement("div");
        if (event.type === "message") {
            div.appendChild(document.createTextNode(event.data));
        }
        document.body.appendChild(div);
      };
      es.addEventListener("open", listener);
      es.addEventListener("message", listener);
      es.addEventListener("error", listener);
    </script>
</head>
<body>
</body>
</html>
END
    };
};
