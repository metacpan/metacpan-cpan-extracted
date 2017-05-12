package Template::Plugin::DtFormatter::RelativeDate::I18N::ja;

=head1 NAME

Template::Plugin::DtFormatter::RelativeDate::I18N::ja - return finder like relative date.

=cut

our $VERSION = '0.01';

use strict;
use warnings;
use utf8;

use base 'Template::Plugin::DtFormatter::RelativeDate::I18N';

our %Lexicon = (
    'yesterday' => '昨日',
    'today'     => '今日',
    'tomorrow'  => '明日',
);

1;
