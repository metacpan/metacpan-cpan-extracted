use Test::More tests => 5;

BEGIN { require 'xt/utils.pl' }
BEGIN {
    use_ok( 'RT' );
    RT::LoadConfig();
    use_ok( 'RT::Extension::TicketFromMessageId' );
    use_ok( 'RT::Interface::Email::Filter::CheckMessageId' );
}

diag( "Testing RT::Extension::TicketFromMessageId
    $RT::Extension::TicketFromMessageId::VERSION" );

my $new_config = RT->can('Config') && RT->Config->can('Get');

my @plugins = $new_config
            ? RT->Config->Get('Plugins')
            : @RT::Plugins;

my @mail_plugins = $new_config
                 ? RT->Config->Get('MailPlugins')
                 : @RT::MailPlugins;

my $complain = 0;
ok((grep { $_ eq 'RT::Extension::TicketFromMessageId' } @plugins),
    "RT::Extension::TicketFromMessageId is in your config's \@Plugins") or $complain = 1;
ok((grep { $_ eq 'Filter::CheckMessageId' } @mail_plugins),
    "Filter::CheckMessageId is in your config's \@MailPlugins") or $complain = 1;

if ($complain) {
    diag "Please read through the entire INSTALL documentation for directions on how to set up your config for testing and using this plugin.";
}

