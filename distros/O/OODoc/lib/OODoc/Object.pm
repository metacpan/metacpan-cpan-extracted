# This code is part of Perl distribution OODoc version 3.01.
# The POD got stripped from this file by OODoc version 3.01.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

package OODoc::Object;{
our $VERSION = '3.01';
}


use strict;
use warnings;

use Log::Report    'oodoc';

use List::Util     qw/first/;


use overload
    '=='   => sub {$_[0]->unique == $_[1]->unique},
    '!='   => sub {$_[0]->unique != $_[1]->unique},
    'bool' => sub {1};

#-------------

sub new(@)
{   my ($class, %args) = @_;
    my $self = (bless {}, $class)->init(\%args);

    if(my @missing = keys %args)
    {   error __xn"Unknown object attribute '{options}' for {pkg}", "Unknown object attributes for {pkg}: {options}",
            scalar @missing, options => \@missing, pkg => $class;
    }

    $self;
}

my $unique = 42;

sub init($)
{   my ($self, $args) = @_;

	# prefix with 'id', otherwise confusion between string and number
    $self->{OO_unique} = 'id' . $unique++;
    $self;
}

#-------------------------------------------

sub unique() { $_[0]->{OO_unique} }

#-------------------------------------------

my %packages;
my %manuals;

sub addManual($)
{   my ($self, $manual) = @_;

    ref $manual && $manual->isa('OODoc::Manual')
        or panic "manual definition requires manual object";

    push @{$packages{$manual->package}}, $manual;
    $manuals{$manual->name} = $manual;
    $self;
}


sub mainManual($)
{  my ($self, $name) = @_;
   first { $_ eq $_->package } $self->manualsForPackage($name);
}


sub manualsForPackage($)
{   my ($self, $name) = @_;
    @{$packages{$name || 'doc'} || []};
}


sub manuals() { values %manuals }


sub findManual($) { $manuals{ $_[1] } }


sub packageNames() { keys %packages }


my %index;
sub publish($)
{	my ($self, $args) = @_;
	$index{$self->unique} = +{ id => $self->unique };
}


sub publicationIndex() { \%index }
#-------------------------------------------

sub mkdirhier($)
{   my $thing = shift;
    my @dirs  = File::Spec->splitdir(shift);
    my $path  = $dirs[0] eq '' ? shift @dirs : '.';

    while(@dirs)
    {   $path = File::Spec->catdir($path, shift @dirs);
        -d $path || mkdir $path
            or fault __x"cannot create {dir}", dir => $path;
    }

    $thing;
}


sub filenameToPackage($)
{   my ($thing, $package) = @_;
    $package =~ s!^lib/!!r =~ s#/#::#gr =~ s/\.(?:pm|pod)$//gr;
}

1;
