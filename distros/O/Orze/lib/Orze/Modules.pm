package Orze::Modules;

=head1 NAME

Orze::Modules - Dynamically load Orze modules

=head1 SYNOPSIS

  use Orze::Modules;
  
  $toto = loadSource('Toto');
  # $toto equals Orze::Sources::Toto
  
  $tata = loadDrivers('Tata');
  # $tata equals Orze::Drivers::Tata

=cut

use strict;
use warnings;

=head2 EXPORTS

loadSource and loadDriver

=cut

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION     = 1.00;
    @ISA         = qw(Exporter);
    @EXPORT      = qw(loadSource loadDriver);
}
our @EXPORT;

=head1 METHODS

=head2 loadSource

Load a source module.

=cut

sub loadSource {
    my $name = shift;
    return load("Sources", $name);
}

=head2 loadDriver

Load a driver module.

=cut

sub loadDriver {
    my $name = shift;
    return load("Drivers", $name);
}

=head2 load

C<load('Foo', 'Bar')> load the module Orze::Foo::Bar.

=cut

sub load {
    my $module = join("::", "Orze", @_);
    my $module_path = $module . ".pm";
    $module_path =~ s!::!/!g;
    require $module_path;
    return $module;
}

