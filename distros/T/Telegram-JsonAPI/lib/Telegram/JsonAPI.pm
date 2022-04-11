package Telegram::JsonAPI;

use 5.018;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    td_create_client_id
    td_send
    td_receive
    td_execute

    td_start_log
    td_stop_log
    td_poll_log
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '1.02';

require XSLoader;
XSLoader::load('Telegram::JsonAPI', $VERSION);

1;
__END__

=head1 NAME

Telegram::JsonAPI - Telegram TDLib's JSON API

=head1 SYNOPSIS

  use Telegram::JsonAPI qw(:all);

  td_start_log();

  my $res = td_execute('{"@type": "setLogVerbosityLevel", "new_verbosity_level": 1, "@extra": 1.01234}');
  # got $res = '{"@type":"ok","@extra":1.01234}';

  td_poll_log(sub {
    my($verbosity, $msg) = @_;
    print "got log ($verbosity) $msg\n";
  });
  # this will clear all the buffered log once.

  my $client_id = td_create_client_id();
  td_send($client_id, '{"@type": "getAuthorizationState", "@extra": 1.01234}');
  # start loggin progress

  while(1) {
    my $msg = decode_json(td_receive(.1));
    # Wait for a JSON message for at most 0.1 second.
    # There will be a `@client_id` field, which contains $client_id.
    # If you have more than one client id simutaneously, you can distinguish them by this field.
    given( $msg->{'@type'} ) {
      when('updateAuthorizationState') {
        ...
      }
      ...
    }
  }

  td_stop_log();

=head1 DESCRIPTION

This module integrated L<Telegram|https://telegram.org/>'s TDLib L<JSON API|https://core.telegram.org/tdlib/docs/td__json__client_8h.html>.
which is used to implement Telegram client app. The difference between an app and a bot is that an app will act as an normal user.
And you need to authenticate it with a phone number.

=head2 EXPORT

None by default.

With tag C<:all>, there are

=over 4

=item $client_id = td_create_client_id()

Returns an opaque identifier of a new TDLib instance. The TDLib instance will not send updates until the first request is sent to it.

=item td_send($client_id, $json_request)

Sends request to the TDLib client.

=item $json_message = td_receive($timeout)

Receives incoming updates and request responses.

=item $json_message = td_execute($json_request)

Synchronously executes a TDLib request. A request can be executed synchronously, only if it is documented with "Can be called synchronously".

=item td_start_log($max_verbosity_level=1024, $buffer_size=1048576)

Start to keep log messages and prepare a buffer for them. They will be first stored in a buffer. Then use C<td_poll_log()> to take them out.

=item td_stop_log()

Stop keeping log messages and wipe out the log buffer.

=item td_poll_log($cb->($verbosity, $message))

Fetch and clear the buffered log messages.

=back

=head1 EXAMPLES

This is a short example which implemented user authentication and send a text message.

  use strict;
  use warnings;
  use feature qw(say switch);
  no warnings qw(experimental::smartmatch);

  use Telegram::JsonAPI qw(:all);
  use JSON::XS::ByteString qw(encode_json decode_json);

  td_start_log();

  my $client_id = td_create_client_id;

  td_send($client_id, encode_json({'@type' => 'getAuthorizationState', '@extra' => \1.01234}));

  while(1) {
    td_poll_log sub { say "got log: @_"; };
    my $msg = td_receive(1);
    if( defined $msg ) {
      say "recv: $msg";
      $msg = decode_json($msg);
      given($msg->{'@type'}) {
        when('updateAuthorizationState') {
          given( $msg->{authorization_state}{'@type'} ) {
            when('authorizationStateWaitTdlibParameters') {
              td_send($cid, encode_json({
                '@type' => 'setTdlibParameters',
                parameters => {
                  database_directory => 'tdlib', # path for TDLib to store session data
                  use_message_database => 1,
                  use_secret_chats => 1,
                  api_id => $api_id,     # $api_id and $api_hash could be retrieved from
                  api_hash => $api_hash, #   https://my.telegram.org/apps
                  system_language_code => 'en',
                  device_model => 'Desktop',
                  application_version => '1.0',
                  enable_storage_optimizer => 1,
                },
              }));
            }
            when('authorizationStateWaitEncryptionKey') {
              td_send($cid, encode_json({
                '@type' => 'checkDatabaseEncryptionKey',
                encryption_key => '',
              }));
            }
            when('authorizationStateWaitPhoneNumber') {
              say 'Please enter your phone number:';
              my $phone = <STDIN>;
              $phone =~ s/\s//g;
              td_send($cid, encode_json({
                '@type' => 'setAuthenticationPhoneNumber',
                phone_number => $phone,
              }));
            }
            when('authorizationStateWaitCode') {
              say 'Please enter the authentication code you received:';
              my $code = <STDIN>;
              $code =~ s/\s//g;
              td_send($cid, encode_json({
                '@type' => 'checkAuthenticationCode',
                code => $code,
              }));
            }
            when('authorizationStateWaitRegistration') {
              say 'Please enter your first name:';
              my $first_name = <STDIN>;
              $first_name =~ s/^\s+|\s+$//g;
              say 'Please enter your last name:';
              my $last_name = <STDIN>;
              $last_name =~ s/^\s+|\s+$//g;
              td_send($cid, encode_json({
                '@type' => 'registerUser',
                first_name => $first_name,
                last_name => $last_name,
              }));
            }
            when('authorizationStateWaitPassword') {
              say 'Please enter your password:';
              my $password = <STDIN>;
              chomp $password;
              td_send($cid, encode_json({
                '@type' => 'checkAuthenticationPassword',
                password => $password,
              }));
            }
            when('authorizationStateReady') {
              td_send($client_id, encode_json({
                '@type' => 'sendMessage',
                chat_id => $chat_id, # beside the chat list, you can also retrive the chat id from any incoming messages
                input_message_content => {
                  '@type' => 'inputMessageText',
                  text => {
                    '@type' => 'formattedText',
                    text => "Hello, every one.",
                  },
                },
              }));
            }
          }
        }
      }
    }
  }

=head1 INSTALL

This module needs C<libtdjson>. Hopefully your can install it from your OS package manager.
Or you can get it from L<https://github.com/tdlib/td> and build it on your own.

=head1 SEE ALSO

=over 4

=item github

L<https://github.com/CindyLinz/Perl-Telegram-JsonAPI>

=item Getting started with TDLib

L<https://core.telegram.org/tdlib/getting-started>

=item TDLib api list

What to put in the JSON requests and got from the JSON responses.

L<https://core.telegram.org/tdlib/docs/td__api_8h.html>

=back

=head1 AUTHOR

Cindy Wang (CindyLinz) E<lt>cindy@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by CindyLinz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
