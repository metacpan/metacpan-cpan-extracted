# NAME

Plack::Middleware::GNUTerryPratchett - Adds automatically an X-Clacks-Overhead header.

# VERSION

version 0.01

# SYNOPSIS

    use Plack::Builder;

    my $app = builder {
      enable "Plack::Middleware::GNUTerryPratchett";
      sub {[ '200', ['Content-Type' => 'text/html'], ['hello world']] }
    };

# DESCRIPTION

Plack::Middleware::GNUTerryPratchett adds automatically an X-Clacks-Overhead header.

In Terry Pratchett's Discworld series, the clacks are a series of semaphore towers loosely based on the concept of the telegraph. Invented by an artificer named Robert Dearheart, the towers could send messages "at the speed of light" using standardized codes. Three of these codes are of particular import:

**G**: send the message on

**N**: do not log the message

**U**: turn the message around at the end of the line and send it back again
When Dearheart died, his name was inserted into the overhead of the clacks with a "GNU" in front of it to memorialize him forever (or for at least as long as the clacks are standing.)

For more information: [http://www.gnuterrypratchett.com/](http://www.gnuterrypratchett.com/)

# AUTHOR

Tiago Peczenyj <tiago.peczenyj@gmail.com>
