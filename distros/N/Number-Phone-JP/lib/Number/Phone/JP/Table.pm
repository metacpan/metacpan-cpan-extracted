package Number::Phone::JP::Table;

use strict;
use warnings;

our $VERSION = '0.20180202';

require Number::Phone::JP::Table::Class1;
require Number::Phone::JP::Table::Class2;
require Number::Phone::JP::Table::Freedial;
require Number::Phone::JP::Table::Home;
require Number::Phone::JP::Table::Ipphone;
require Number::Phone::JP::Table::Mobile;
require Number::Phone::JP::Table::Pager;
require Number::Phone::JP::Table::Phs;
require Number::Phone::JP::Table::Q2;
require Number::Phone::JP::Table::United;
require Number::Phone::JP::Table::Fmc;
require Number::Phone::JP::Table::M2m;

no warnings 'once';

our %TEL_TABLE = (
    %Number::Phone::JP::Table::Class1::TEL_TABLE,
    %Number::Phone::JP::Table::Class2::TEL_TABLE,
    %Number::Phone::JP::Table::Freedial::TEL_TABLE,
    %Number::Phone::JP::Table::Home::TEL_TABLE,
    %Number::Phone::JP::Table::Ipphone::TEL_TABLE,
    %Number::Phone::JP::Table::Mobile::TEL_TABLE,
    %Number::Phone::JP::Table::Pager::TEL_TABLE,
    %Number::Phone::JP::Table::Phs::TEL_TABLE,
    %Number::Phone::JP::Table::Q2::TEL_TABLE,
    %Number::Phone::JP::Table::United::TEL_TABLE,
    %Number::Phone::JP::Table::Fmc::TEL_TABLE,
);

# prefixes of both pager and m2m are duplicated with each other
$TEL_TABLE{'20'} = '(?:' .
    $TEL_TABLE{'20'} .
        '|' .
    $Number::Phone::JP::Table::M2m::TEL_TABLE{'20'} .
')';

sub import {
    my $class = shift;
    my $pkg = caller(0);
    no strict 'refs';
    %{"$pkg\::TEL_TABLE"} = %TEL_TABLE;
}

1;
__END__

=head1 NAME

Number::Phone::JP::Table - Regex table for all of the Japanese telephone numbers

=head1 SYNOPSIS

B<DO NOT USE THIS MODULE DIRECTLY>

=head1 DESCRIPTION

This module defines all of the Japanese telephone numbers table to use
by Number::Phone::JP.

=head1 AUTHOR

Koichi Taniguchi (a.k.a. nipotan) E<lt>taniguchi@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Number::Phone::JP>,
http://www.soumu.go.jp/main_sosiki/joho_tsusin/top/tel_number/number_shitei.html

=cut
