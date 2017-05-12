package Template::Plugin::Filter::VisualTruncate::UTF8;

use warnings;
use strict;

use base qw( Template::Plugin::Filter );

use Text::VisualWidth::UTF8;

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub width {
    shift;
    Text::VisualWidth::UTF8::width(@_);
}

sub trim {
    shift;
    my $before_flag = utf8::is_utf8($_[0]);
    my $truncated   = Text::VisualWidth::UTF8::trim(@_);
    my $after_flag  = utf8::is_utf8($truncated);

    unless ($before_flag == $after_flag) {
        if ($before_flag) {
            utf8::decode($truncated);
        }
        else {
            utf8::encode($truncated);
        }
    }

    $truncated;
}

1;
