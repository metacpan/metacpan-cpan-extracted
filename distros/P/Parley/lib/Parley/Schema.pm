package Parley::Schema;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;
use Parley::Version;  our $VERSION = $Parley::VERSION;

use base 'DBIx::Class::Schema';

# explicitly load Parley::Schema classes
__PACKAGE__->load_classes(
    [
        'AdminAction',
        'Authentication',
        'EmailQueue',
        'ForumModerator',
        'Forum',
        'IpBan',
        'IpBanType',
        'LogAdminAction',
        'PasswordReset',
        'Person',
        'Post',
        'Preference',
        'PreferenceTimeString',
        'RegistrationAuthentication',
        'Role',
        'Session',
        'TermsAgreed',
        'Terms',
        'Thread',
        'ThreadView',
        'UserRole',
    ]
);

# XXX doesn't play at all well with postgres
#__PACKAGE__->load_components(qw/+DBIx::Class::Schema::Versioned/);

1;
