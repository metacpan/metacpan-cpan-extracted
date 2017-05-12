package Template::Plugin::Filter::VisualTruncate::EUC_JP;

use warnings;
use strict;

use base qw( Template::Plugin::Filter );

use Text::VisualWidth::EUC_JP;

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub width {
    shift;
    Text::VisualWidth::EUC_JP::width(@_);
}

sub trim {
    shift;
    Text::VisualWidth::EUC_JP::trim(@_);
}

1;
