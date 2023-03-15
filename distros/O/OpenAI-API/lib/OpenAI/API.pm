package OpenAI::API;

use strict;
use warnings;

use Carp qw/croak/;

use Moo;
use strictures 2;
use namespace::clean;

with 'OpenAI::API::ConfigurationRole';
with 'OpenAI::API::UserAgentRole';
with 'OpenAI::API::RequestDispatcherRole';

our $VERSION = 0.27;

__END__

=head1 NAME

OpenAI::API - Perl interface to OpenAI API

=for readme plugin version

=head1 SYNOPSIS

    use OpenAI::API;
    use OpenAI::API::Request::Chat;

    my $config = OpenAI::API->new();    # uses OPENAI_API_KEY environment variable

    my $request = OpenAI::API::Request::Chat->new(
        model    => "gpt-3.5-turbo",
        messages => [
            { "role" => "system",    "content" => "You are a helpful assistant." },
            { "role" => "user",      "content" => "Who won the world series in 2020?" },
            { "role" => "assistant", "content" => "The Los Angeles Dodgers won the World Series in 2020." },
            { "role" => "user",      "content" => "Where was it played?" }
        ],
    );

    my $res = $request->send($config);

=head1 DESCRIPTION

OpenAI::API is a Perl module that provides an interface to the OpenAI API,
which allows you to generate text, translate languages, summarize text,
and perform other tasks using the language models developed by OpenAI.

To use the OpenAI::API module, you will need an API key, which you can obtain by
signing up for an account on the L<OpenAI website|https://platform.openai.com>.

=begin :readme

=head1 INSTALLATION

If you have cpanm, you only need one line:

    % cpanm OpenAI::API

Alternatively, if your CPAN shell is set up, you should just be able
to do:

    % cpan OpenAI::API

As a last resort, you can manually install it:

    perl Makefile.PL
    make
    make test
    make install

If your perl is system-managed, you can create a L<local::lib> in your
home directory to install modules to. For details, see the
L<local::lib documentation|https://metacpan.org/pod/local::lib>.

=head1 DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc OpenAI::API

=end :readme

=for readme stop

=head1 METHODS

=head2 new()

Creates a new OpenAI::API object.

=over 4

=item * api_key [optional]

Your API key. Default: C<$ENV{OPENAI_API_KEY}>.

Attention: never commit API keys to your repository. Use the C<OPENAI_API_KEY>
environment variable instead.

See: L<Best Practices for API Key Safety|https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety>.

=item * api_base [optional]

The api_base URL for the OpenAI API. Default: 'https://api.openai.com/v1/'.

=item * timeout [optional]

The timeout value, in seconds. Default: 60 seconds.

=back

=head1 RESOURCES

=over

=item * L<OpenAI::API::Request::Chat>

=item * L<OpenAI::API::Request::Completion>

=item * L<OpenAI::API::Request::Edit>

=item * L<OpenAI::API::Request::Embedding>

=item * L<OpenAI::API::Request::File::List>

=item * L<OpenAI::API::Request::File::Retrieve>

=item * L<OpenAI::API::Request::Image::Generation>

=item * L<OpenAI::API::Request::Model::List>

=item * L<OpenAI::API::Request::Model::Retrieve>

=item * L<OpenAI::API::Request::Moderation>

=back

=head1 SEE ALSO

L<OpenAI Reference Overview|https://platform.openai.com/docs/api-reference/overview>

=for readme start

=head1 AUTHOR

Nelson Ferraz E<lt>nferraz@gmail.comE<gt>

=head1 SUPPORT

This module is developed on
L<GitHub|https://github.com/nferraz/perl-openai-api>.

Send ideas, feedback, tasks, or bugs to
L<GitHub Issues|https://github.com/nferraz/perl-openai-api/issues>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, 2023 by Nelson Ferraz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.2 or,
at your option, any later version of Perl 5 you may have available.

=for readme stop

=cut
