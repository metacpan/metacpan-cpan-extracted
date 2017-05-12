#line 1
package Module::Install::Mousse;
use strict;
use warnings;

use Module::Install::Base;

use vars qw(@ISA);
BEGIN { @ISA = 'Module::Install::Base' }

sub use_mousse {
    my $self = shift;
    return unless $self->is_admin;
    my $module = shift
        or die "use_mousse requires the name of a target module";
    my $output_path = $module;
    $output_path =~ s/::/\//g;
    $output_path = "lib/$output_path.pm";
    require Mousse::Maker;
    Mousse::Maker::make_from_mousse($module, $output_path);
}

sub use_mousse_dev {
    my $self = shift;
    return unless $self->is_admin;
    my $module = shift
        or die "use_mousse_dev requires the name of a target module";
    my $output_path = $module;
    $output_path =~ s/::/\//g;
    $output_path = "lib/$output_path.pm";
    require Mousse::Maker;
    Mousse::Maker::make_from_mouse($module, $output_path);
}

1;

=encoding utf8

#line 82
