package Template::Plugin::DtFormatter::RelativeDate::I18N::en;

=head1 NAME

Template::Plugin::DtFormatter::RelativeDate::I18N::en - return finder like relative date.

=cut

our $VERSION = '0.01';

use strict;
use warnings;
use utf8;

use base 'Template::Plugin::DtFormatter::RelativeDate::I18N';

our %Lexicon = (
    'yesterday' => 'Yesterday',
    'today'     => 'Today',
    'tomorrow'  => 'Tomorrow',
);

1;
