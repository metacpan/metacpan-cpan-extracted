package Template::LiquidX::Tidy::Tag::post_url;

use strict;
use warnings;
use experimental 'signatures';

use base 'Template::Liquid::Tag';
#sub conditional_tag { }
sub import { Template::Liquid::register_tag('post_url') }
sub new ($class, $args) {
    bless $args => $class
}

1;

=head1 NAME

Template::LiquidX::Tidy::Tag::post_url - This is a DUMMY tag to support post_url

=head1 SYNOPSIS

You cannot use this tag for actual post URL dereferencing!

It is only enough to support indentation of Liquid C<post_url> in Template::LiquidX::Tidy.

=cut

