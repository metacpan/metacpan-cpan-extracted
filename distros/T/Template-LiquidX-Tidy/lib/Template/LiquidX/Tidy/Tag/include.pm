package Template::LiquidX::Tidy::Tag::include;

use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.01';

use base 'Template::Liquid::Tag';

#sub conditional_tag { }
sub import { Template::Liquid::register_tag('include') }
sub new ($class, $args) {
    bless $args => $class
}

1;

=head1 NAME

Template::LiquidX::Tidy::Tag::include - This is a DUMMY tag to support include

=head1 SYNOPSIS

You cannot use this tag for actual include work!

It is only enough to support indentation of Liquid C<include> in Template::LiquidX::Tidy.

=cut

