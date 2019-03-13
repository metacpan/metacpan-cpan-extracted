# PiFlash::Object - object functions for PiFlash classes
# by Ian Kluft

use strict;
use warnings;
use v5.14.0; # require 2011 or newer version of Perl

package PiFlash::Object;
$PiFlash::Object::VERSION = '0.3.1';
use autodie; # report errors instead of silently continuing ("die" actions are used as exceptions - caught & reported)
use Carp qw(confess);

# ABSTRACT:object functions for PiFlash classes


# new() - internal function to instantiate hook object
# this should only be called from add() with coderef/caller/origin parameters
sub new
{
        my $class = shift;
        my $params = shift;

		# instantiate an object of the class
        my $self = {};
        bless $self, $class;

        # initialize parameters
        foreach my $key (keys %$params) {
			$self->{$key} = $params->{$key};
        }

		# chack for missing required parameters
        my @missing;
        foreach my $required ($class->object_params()) {
			exists $self->{$required} or push @missing, $required;
        }
        if (@missing) {
			confess $class."->new() missing required parameters: ".join(" ", @missing);
        }

		# if init() class method exists, call it with any remaining parameters
		if ($class->can("init")) {
			$self->init(@_);
		}

        return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PiFlash::Object - object functions for PiFlash classes

=head1 VERSION

version 0.3.1

=head1 SYNOPSIS

 package PiFlash::Example;
 use parent 'PiFlash::Object';

 sub object_params
 (
	return qw(name type); # and any other required object parameter names
 }

 my $obj = PiFlash::Example->new( {name => "foo", type => "bar");

=head1 DESCRIPTION

 PiFlash::Object was written so that L<PiFlash::Hook> and L<PiFlash::Plugin> could inherit and share the same new() class method, rather than have similar and separate implementations. It isn't of interest to most PiFlash users.

 In order to use it, the class must define a class method called object_params() which returns a list of the required parameter names for each object of the class.

=head1 SEE ALSO

L<piflash>, L<PiFlash::Hook>, L<PiFlash::Plugin>

=head1 AUTHOR

Ian Kluft <cpan-dev@iankluft.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2019 by Ian Kluft.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
