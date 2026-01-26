use strict;
use warnings;
use DDP;

my $app = sub {
    my $env = shift;

    if ($env->{REQUEST_METHOD} eq 'POST' && $env->{PATH_INFO} eq '/submit') {
        my $request_body = '';
        if (exists $env->{'psgi.input'}) {
            my $input = $env->{'psgi.input'};
            while (my $line = <$input>) {
                $request_body .= $line;
            }
        }

        return [
            200,
            ['Content-Type' => 'text/plain'],
            ["Received POST data:\n$request_body"],
        ];
    }

    p $env;

    return [
        201,
        ['Content-Type' => 'text/html'],
        [<<'END_HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Plack::Handler::H2 Test</title>
</head>
<body>
    <h1>Hello from Plack::Handler::H2!</h1>
    <p>This is a test response served over HTTP/2.</p>
    <form method="post" action="/submit" enctype="multipart/form-data">
        <label for="name">Name:</label>
        <input type="text" id="name" name="name"><br><br>
        <label for="email">Email:</label>
        <input type="email" id="email" name="email"><br><br>
        <label for="upload">Upload a file:</label>
        <input type="file" name="upload"><br><br>
        <input type="submit" value="Submit">
    </form>
</body>
</html>
END_HTML
        ],
    ];
};