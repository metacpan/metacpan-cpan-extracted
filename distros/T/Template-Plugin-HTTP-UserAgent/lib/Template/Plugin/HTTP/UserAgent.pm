package Template::Plugin::HTTP::UserAgent;
$Template::Plugin::HTTP::UserAgent::VERSION = '0.08';
# ABSTRACT: Template plugin for parsing HTTP User-Agent string

use 5.006;
use strict;
use warnings;
use parent 'Template::Plugin';
use HTML::ParseBrowser;

sub new
{
    my $class   = shift;
    my $context = shift;
    my $ua;

    if (@_ == 0 && !exists($ENV{HTTP_USER_AGENT})) {
        return $class->error('No User-Agent string given');
    }

    $ua = HTML::ParseBrowser->new(@_ > 0 ? shift : $ENV{HTTP_USER_AGENT});

    if (!defined($ua)) {
        return $class->error("Failed to instantiate HTML::ParseBrowser");
    }

    bless {
        UA => $ua,
    }, $class;
}

sub name      { return $_[0]->{UA}->name;       }
sub version   { return $_[0]->{UA}->v;          }
sub major     { return $_[0]->{UA}->major;      }
sub minor     { return $_[0]->{UA}->minor;      }
sub os        { return $_[0]->{UA}->os;         }
sub ua_string { return $_[0]->{UA}->user_agent; }

1;

__END__

=head1 NAME

Template::Plugin::HTTP::UserAgent - Template plugin for parsing HTTP User-Agent string

=head1 SYNOPSIS

  [% USE ua = HTTP::UserAgent %]
  [% IF ua.name == 'Internet Explorer' && ua.major <= 7 %]
    <p>I'm sorry Dave, I can't let you do that.</p>
  [% ELSE %]
    ... whew ...
  [% END %]

=head1 DESCRIPTION

Template::Plugin::HTTP::UserAgent is a plugin for the Template Toolkit
that is used to extract information from an HTTP User-Agent string.
The User-Agent string can either be passed to the constructor,
or the HTTP_USER_AGENT environment variable will be used, if set.

The first option is to pass the string to the constructor:

  [% USE ua = HTTP::UserAgent('Opera/9.64 (X11; Linux i686; U; da) Presto/2.1.1')

If you don't pass a string to the constructor,
it will check to see whether the HTTP_USER_AGENT environment variable is set,
and if so will use that.

  [% USE ua = HTTP::UserAgent %]

=head1 METHODS

The module supports the following methods.

=over 4

=item name

The name of the user agent (e.g. web browser, crawler).
In general this is the name that appears in the User-Agent string.
Internet Explorer identifies itself as 'MSIE' in the User-Agent string,
but this method returns 'Internet Explorer'.

=item version

The full version string.
For example the User-Agent string containing 'Camino/1.0rc1' will
return '1.0rc1' as the version string.

=item major

The major version number. For Safari 3.1.1, this method will return 3.

=item minor

The minor version number. For Iron 6.0.475.1, this method will return 0.

=item os

The string which identifies the operating system on which the User-Agent is running.

=item ua_string

The raw User-Agent string.

=back

At the moment Template::Plugin::HTTP::UserAgent uses
L<HTML::ParseBrowser> internally.
That module supports more methods for extracting information
from User-Agent strings than are provided here.
Some of those methods might be added in the future --
let me know if you want one or more of them.
Template::Plugin::HTTP::UserAgent might switch to using
a different module internally,
which is why I've started off with a generic set of methods initially.

=head1 SEE ALSO

L<Template::Plugin::MobileAgent> is a similar module,
but it uses L<HTTP::MobileAgent> under the hood,
which is particularly aimed at recognising user agent strings from Japanese mobile phones.

L<HTML::ParseBrowser> is the module used by Template::Plugin::HTTP::UserAgent to
do the actual parsing of the user agent string.

=head1 REPOSITORY

L<https://github.com/neilbowers/Template-Plugin-HTTP-UserAgent>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2012 Neil Bowers. All rights reserved.

This module is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

