package Test::Chado::Factory::FixtureLoader;
{
  $Test::Chado::Factory::FixtureLoader::VERSION = 'v4.1.1';
}

use strict;
use Module::Load qw/load/;
use Module::Path qw/module_path/;
use Module::Runtime qw/compose_module_name/;

sub get_instance {
    my ($class,$arg) = @_;
    die "need a type of fixture loader\n" if !$arg;
    
    $arg = ucfirst lc($arg);
    my $module = compose_module_name('Test::Chado::FixtureLoader',$arg);
    my $module_path = module_path($module);
    die "could not find $module\n" if not defined $module_path;

    load $module;
    return $module->new;
}

1;

__END__

=pod

=head1 NAME

Test::Chado::Factory::FixtureLoader

=head1 VERSION

version v4.1.1

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
