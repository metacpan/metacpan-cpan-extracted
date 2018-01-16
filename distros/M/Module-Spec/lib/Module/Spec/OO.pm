
package Module::Spec::OO;
$Module::Spec::OO::VERSION = '0.6.0';
use 5.012;
use warnings;

use Class::Method::Modifiers 1.05 ();    # install_modifier

my %CLASSES;

my @METHODS = qw(need_module try_module generate_code);

sub create_class {
    my ( $self, $version ) = @_;
    return $CLASSES{$version} if $CLASSES{$version};

    my $base  = "Module::Spec::V$version";
    my $class = "${base}::OO";

    my $e;
    {
        local $@;
        eval( my $code
              = "package $class; require $base; our \@ISA = qw($base);" );
        $e = "Evaling failed: $@\nTrying to eval:\n${code}" if $@;
    }

    # Allow certain functions in the base class to act as methods
    Class::Method::Modifiers::install_modifier(
        $class,
        around => @METHODS,
        sub {
            return $_[0]->( @_[ 2 .. $#_ ] );    # Discard invocant
        }
    );

    return $CLASSES{$version} = $class;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Spec::OO

=head1 VERSION

version 0.6.0

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
