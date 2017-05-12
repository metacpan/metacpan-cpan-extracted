# NAME

Net::Server::Mail::SMTP::Prefork - Prefork SMTP Server

# SYNOPSIS

    use Net::Server::Mail::SMTP::Prefork;

    my $server = Net::Server::Mail::SMTP::Prefork->new(
        host => 'localhost',
        port => 2500,
        max_workers => 20,
    );
    $server->set_callback('RCPT' => sub { return (1) });
    $server->set_callback('DATA' => sub { return (1, 250, 'message queued') });
    $server->run;

# DESCRIPTION

Net::Server::Mail::SMTP::Prefork is preforking SMTP server.

# LICENSE

Copyright (C) uchico.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

uchico <memememomo@gmail.com>
