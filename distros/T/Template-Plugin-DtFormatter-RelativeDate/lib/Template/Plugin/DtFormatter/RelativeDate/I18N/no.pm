package Template::Plugin::DtFormatter::RelativeDate::I18N::no;

=head1 NAME

Template::Plugin::DtFormatter::RelativeDate::I18N::no - return finder like relative date.

=cut

our $VERSION = '0.01';

use strict;
use warnings;
use utf8;

use base 'Template::Plugin::DtFormatter::RelativeDate::I18N';

our %Lexicon = (
    'yesterday' => 'I går',
    'today'     => 'I dag',
    'tomorrow'  => 'I morgen',
);

1;

=head1 AUTHOR

Marcus Ramberg C<marcus@nordaaker.com>

=cut
