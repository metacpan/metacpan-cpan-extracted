=head1 NAME

Synapse::CLI::Config::Type

=head1 SYNOPSIS

    my $type = Synapse::CLI::Config::Type->new ("Some::Package");
    my $res  = $type->some_class_method();

=head1 SUMMARY

This package is a proxy which allows manipulating package methods using an
object. It is used to be able to call class methods on the command line by
instantiating an object representing the class / package.

For instance:

    myapp-cli type sometype some_method


=head1 EXPORTS

none.


=head1 BUGS

Please report them to me. Patches always welcome...


=head1 AUTHOR

Jean-Michel Hiver, jhiver (at) synapse (dash) telecom (dot) com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
package Synapse::CLI::Config::Type;
use Synapse::CLI::Config;
use warnings;
use strict;

our $AUTOLOAD;


sub new {
    my $class = shift;
    if (ref $class) {
        return $class->{package}->new (@_);
    }
    else {
        my $type  = shift;
        my $package = $Synapse::CLI::Config::ALIAS->{$type} || $type;
        eval "use $package";
        return bless { type => $type, package => $package }, $class;
    }
}


sub can {
    my $self = shift;
    my $meth = shift;
    return $self->{package}->can ($meth);
}


sub AUTOLOAD {
    my $self    = shift;
    my $type    = $self->{type};
    my $meth    = $AUTOLOAD;
    $meth =~ s/.*:://;
    return $self->{package}->$meth (@_);
}


sub DESTROY {
}


1;
