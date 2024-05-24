#
# This file is part of StorageDisplay
#
# This software is copyright (c) 2014-2023 by Vincent Danjean.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package StorageDisplay::Data::Elem;
# ABSTRACT: Handle something that will be displayed and can be linked
# from/to as a tree for StorageDisplay

our $VERSION = '2.06'; # VERSION

use Moose;
use namespace::sweep;

use StorageDisplay::Role;
use Object::ID;
use Carp;

with (
    "StorageDisplay::Role::Iterable"
    => {
	iterable => "StorageDisplay::Data::Elem",
	name => "Recursive",
    },
    "StorageDisplay::Role::Style::Base::Elem"
    );

has 'consume' => (
    is       => 'ro',
    isa      => 'ArrayRef[StorageDisplay::Block]',
    traits   => [ 'Array' ],
    default  => sub { return []; },
    lazy     => 1,
    handles  => {
	'consumeBlock' => 'push',
            'consumedBlocks' => 'elements',
    }
    );

has 'provide' => (
    is       => 'ro',
    isa      => 'ArrayRef[StorageDisplay::Block]',
    traits   => [ 'Array' ],
    default  => sub { return []; },
    lazy     => 1,
    handles  => {
	'provideBlock' => 'push',
            'allProvidedBlocks' => 'elements',
    },
    init_arg => undef,
    );

around 'provideBlock' => sub {
      my $orig = shift;
      my $self = shift;

      for my $b (@_) {
          $b->providedBy($self);
      }
      #print STDERR "INFO ", $self->name, " : provides ", map { $_->name } (@_);
      #print STDERR "\n";
      return $self->$orig(@_);
};

#sub BUILD {
#    my $self = shift;
#    my $args = shift;
#
#    print STDERR "INFO: ", $self->name, " : consumes ",
#	join(', ', map { $_->name } ($self->consumedBlocks)), "\n";
#    return $self;
#}

sub has_parent {
    my $self = shift;
    return $self->nb_parents == 1;
}

sub parent {
    my $self = shift;
    if ($self->nb_parents != 1) {
	croak "Unkown parent requested for ".$self->label;
    }
    return ($self->parents)[0];
};

has 'label' => (
    is => 'rw',
    isa => 'Str',
    required => 0,
    default => "NO LABEL",
    );

sub disp_size {
    my $self = shift;
    my $size = shift;
    my $unit = 'B';
    my $d=2;
    #print STDERR "\n\ninit size=$size\n";
    {
        use bigrat;
        my $divide = 1;
        if ($size >= 1024) { $unit = 'kiB'; }
        if ($size >= 1048576) { $unit = 'MiB'; $divide *= 1024; }
        if ($size >= 1073741824) { $unit = 'GiB'; $divide *= 1024; }
        if ($size >= 1099511627776) { $unit = 'TiB'; $divide *= 1024; }
        if ($size >= 1125899906842624) { $unit = 'PiB'; $divide *= 1024; }
        if ($size >= 1152921504606846976) { $unit = 'EiB'; $divide *= 1024; }

        if ($unit eq 'B') {
            return "$size B";
        } else {
            $size /= $divide;
        }
        $size = $size * 1000 / 1024;
        if ($size >= 10000) { $d = 1;}
        if ($size >= 100000) { $d = 0;}
        #print STDERR "size=$size ", ref($size), "\n";
        $size=int($size/10**(3-$d)+0.5)*10**(3-$d);
        #print STDERR "size=$size ", ref($size), "\n";
        $size = $size->numify();
    }
    return sprintf("%.$d"."f $unit", $size/1000);
}

sub statecolor {
    my $self = shift;
    my $state = shift;

    if ($state eq "free") {
        return "green";
    } elsif ($state eq "ok") {
        return "green";
    } elsif ($state eq "used") {
        return "yellow";
    } elsif ($state eq "busy") {
        return "pink";
    } elsif ($state eq "unused") {
        return "white";
    } elsif ($state eq "unknown") {
        return "lightgrey";
    } elsif ($state eq "special") {
        return "mediumorchid1";
    } elsif ($state eq "warning") {
        return "orange";
    } elsif ($state eq "error") {
        return "red";
    } else {
        return "red";
    }
}

sub dname {
    my $self = shift;
    return $self->name;
}

has 'linkkind' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
    lazy => 1,
    default => sub {
	my $self = shift;
	my $kind = ref($self);
	$kind =~ s/^StorageDisplay::Data:://;
	if ($self->has_parent) {
	    my $pkind = ref($self->parent);
	    $pkind =~ s/^StorageDisplay::Data:://;
	    $kind =~ s/^$pkind//;
	}
	return $kind;
    },
);

sub rawlinkname {
    my $self = shift;
    return $self->fullname;
}

sub linkname {
    my $self = shift;
    return '"'.$self->rawlinkname.'"';
}

sub newElem {
    my $self = shift;
    my $baseclass = shift;

    my $class = 'StorageDisplay::Data::'.$baseclass;
    return $class->new(@_);
}

sub newChild {
    my $self = shift;

    my $child = $self->newElem(@_);
    $self->addChild($child);

    return $child;
}

sub pushDotText {
    my $self = shift;
    my $text = shift;
    my $t = shift // "\t";

    my @pushed = map { $t.$_ } @_;
    push @{$text}, @pushed;
}

sub dotSubNodes {
    my $self = shift;
    my $t = shift // "\t";
    my @text=();
    my $it = $self->iterator(recurse => 0);
    while (defined(my $e=$it->next)) {
        push @text, $e->dotNode($t);
    }
    return @text;
}

sub dotLinks {
    my $self = shift;
    return ();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

StorageDisplay::Data::Elem - Handle something that will be displayed and can be linked

=head1 VERSION

version 2.06

=head1 AUTHOR

Vincent Danjean <Vincent.Danjean@ens-lyon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Vincent Danjean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
