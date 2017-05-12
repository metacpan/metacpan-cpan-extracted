use inc::Module::Install;

# Define metadata
name            'Net-POP3-PerMsgHandler';
all_from        'lib/Net/POP3/PerMsgHandler.pm';

# Specific dependencies
build_requires  'Test::More'                          => '0.42';
requires        'Net::POP3'                           => 0;
requires        'Params::Validate'                    => 0;
requires        'Scalar::Defer'                       => 0;
requires        'Class::Accessor::Fast';
recommends      'Email::MIME'                         => 0;
recommends      'Email::MIME::Attachment::Stripper'   => 0;
recommends      'Mail::Message'                       => 0;
recommends      'Mail::Message::Attachment::Stripper' => 0;

auto_install;
WriteAll;
