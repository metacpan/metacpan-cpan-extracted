package MongoDBx::Tiny::Util;
use strict;
use warnings;

=head1 NAME

MongoDBx::Tiny::Util - internal implementation

=cut

use Carp qw/carp confess/;
use Data::Dumper;
use Scalar::Util qw(blessed);

require Exporter;
our @ISA    = qw/Exporter/;
our @EXPORT = qw/DEBUG
		 util_class_is_ours
		 util_guess_class
		 util_class_attr
		 util_document_class
		 util_to_oid
		/;

# xxx
sub DEBUG { $ENV{MONGODBX_TINY_DEBUG} }

sub util_class_is_ours {
    my $class = shift;

    return unless $class;

    my ($tiny,$doc) = qw(MongoDBx::Tiny MongoDBx::Tiny::Document);

    return $tiny if eval { $class->isa($tiny) };
    return $doc  if eval { $class->isa($doc) };
    return;
}

sub util_guess_class {
    #
    # ($class,$stat) = util_guess_class($proto)
    #
    my $proto  = shift;
    my $caller = shift || (caller(1))[0];

    my $class;
    my $stat = {
	ours    => '',
	object  => '',
	caller  => '',
    };
    if (!ref $proto && ($stat->{ours} = util_class_is_ours($proto))) { 
	$class = $proto;     # via classname class->foo
    } elsif (blessed $proto && ($stat->{ours} = util_class_is_ours(ref $proto))) {
	$class = ref $proto; # via object
	$stat->{object} = ref $proto,
    } else {                 # direct
	$class = $caller;
	$stat->{caller} = $caller;
    }
    return ($class,$stat);
}

sub util_class_attr {
    my ($attr,$proto,@arg) = @_;
    confess "no " . $attr unless $attr;

    my ($class,$stat) = util_guess_class($proto,(caller(1))[0]);

    if ($stat->{caller}) {
	unshift @arg, $proto if $proto;
    }

    my $classdata = sprintf "%s::_%s",$class,$attr;

    my $val;
    {
	no strict 'refs';
	$val = ${"$classdata"};
    }

    if (@arg) {
	if (scalar @arg > 1) {
	    $val = \@arg;
	} else {
	    $val = $arg[0];
	}
	{
	    no strict 'refs';
	    ${"$classdata"} = $val;
	}
    }

    return $val;
}

sub util_document_class {
    # guess document class name from (collection name)
    # $d_class   = util_document_class($c_name,ref $self);
    my $c_name     = shift or confess q/no collecion name/;
    my $base_class = shift or confess q/no base_class/;

    $c_name = ucfirst $c_name;
    $c_name =~ s/_([a-z])/uc($1)/eg;
    my $class = sprintf "%s::%s",$base_class,$c_name;
    eval "require $class";
    if ($@ && ! DEBUG) {
    	confess "load fail : $class " . $@;
    }
    return $class;
}

sub util_to_oid {
    #
    # util_to_oid($document,'_id','foo_id','bar_id')
    #
    my $document = shift;
    my @oid_fields = @_;
    for (@oid_fields) {
	if (exists $document->{$_}) {
	    if (ref $document->{$_} eq 'MongoDB::OID') {
		#
	    } elsif( $document->{$_} =~ /\A[a-fA-F\d]{24}\z/) {
		$document->{$_} = MongoDB::OID->new(value => $document->{$_});
	    }
	}
    }
    return $document;
}

1;
__END__

=head1 AUTHOR

Naoto ISHIKAWA, C<< <toona at seesaa.co.jp> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Naoto ISHIKAWA.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
