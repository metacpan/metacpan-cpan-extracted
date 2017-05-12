
# (c) Sam Vilain, 2004.  All rights reserved.  This program is free
# software; you can redistribute it and/or modify it under the same
# terms as Perl itself

use strict;
use Tangram::Type::Scalar;
package Tangram::Type::Dump::Any;

=head1 NAME

Tangram::Type::Dump::Any - Intuitive DataBase InterFace

=head1 SYNOPSIS

  # ... in a nearby Tangram::Schema structure ...
  SomeClass =>
    { fields =>
      { idbif => {
            -options => { dumper => 'Data::Dumper',
                        },
            some_field => undef,
            some_property => undef,
            some_attribute => undef,
            each_one => undef,
            gets => undef,
            saved => undef,
        },
        string => {
            cheese => undef,
        },
      },
    };

=head1 DESCRIPTION

The B<idbif> mapping type collates multiple data members into a single
B<perl_dump> (see L<Tangram::Type::Dump::Perl>), B<storable> (see
L<Tangram::Type::Dump::Storable>) or B<yaml> (see L<Tangram::Type::Dump::YAML>) column.

For instance, with the schema definition in the example, all the
columns in the example would be serialised via Data::Dumper.

If you stored an object like this:

  $cheese = bless { cheese   => "gouda",
                    gets     => 6,
                    each_one => 9 }, "SomeClass";

You would see something in your database similar to:

  /^'--v------v--------v----------------------------'^\
  | id | type | cheese | idbif                        |
  >----o------o--------o------------------------------<
  |  1 |   42 |  gouda | { gets => 6, each_one => 9 } |
  \_,--^------^--------^----------------------------._/

(note: the actual output from your SQL Database client may differ from
the above)

So, if you're the sort of person who likes to set their attributes
with accessors, but doesn't like the overhead this places on the
RDBMS... then this may help.  Note: the real benefits of this mapping
type are for when you're storing more complex data structures than "6"
and "9" :-).

You may prefer to use the default dumping type, which is B<storable>.

=head2 LINKS TO OTHER OBJECTS

If Tangram encounters another object which B<is already in storage>
(ie, has been inserted via C<$storage-E<gt>insert($foo)>), then it
will store a "Memento".  This memento includes the object ID, which is
sensitive to schema changes (the ordering of classes in the schema).

If the class implements a C<px_freeze> and C<px_thaw> function, then
there will be a "Memento" that includes the class name of the object,
and the data that was returned by the class' C<px_freeze> method.  To
be reconstituted, it is called as:

  SomeClass->px_thaw(@data)

See L<Tangram::Type::Dump> for more details on the complicity API.

Please set RETVAL to be the thawed object.  (that is, return a single
scalar).

=head2 BUT, I REALLY, REALLY HATE SCHEMAS!

However, maybe you are one of those folk who don't like to declare
their attributes, instead peppering hashes willy nilly, then there is
another option.

Instead of explicitly listing the fields you want, if you don't
specify any fields at all, then it means save ALL remaining fields
into the column.  For convenience, C<-poof> is provided as a synonym
for C<-options>, so you can write:

    { fields =>
      { idbif => { -poof => # There goes another one!
                   {
                   },
                 }
      },
    }

[ You see, Tangram::Type::Dump::Any isn't actually an intuitive DB interface.
No, an intuitive DB interface is a user interface component, and that
title is reserved for Visual Tangram.  VT expects to pick up the title
with any luck by the end of the 21st century^W RSN!

I Don't Believe In Fairies is actually what it stands for.  It's a
completely arbitrary name; chosen for no reason at all, and certainly
not anything to do with L<Pixie>. ]

=cut

use Tangram::Type::Dump qw(flatten unflatten);

use vars qw(@ISA);
 @ISA = qw( Tangram::Type::String );
use Set::Object qw(reftype blessed);

$Tangram::Schema::TYPES{idbif} = Tangram::Type::Dump::Any->new;

# for the reschema for this particular attribute, we reschema all of
# the attributes mentioned to a single column
sub reschema {
    my ($self, $members, $class, $schema) = @_;

    # convert from short form
    #$members = $_[1] = { map { $_ => undef } @$members }
	#if (ref($members) eq 'ARRAY');

    my $options = {
		   col => $schema->{normalize}->("idbif", "colname"),
		   sql => $schema->{sql}{dumper_type},
		   dumper => $schema->{sql}{dumper},
		   members => [ ],
		  };

    for my $field (keys %$members) {

	if ($field eq "-options" or $field eq "-poof") {
	    my $def = $members->{$field};
	    ref $def or next;
	    # XXX - not reached by test suite
	    reftype $def eq "HASH"
		or die("reftype invalid in schema for -options idbif;"
		       ." hash expected, got $def");

	    while (my ($option, $value) = each %$def) {
		$options->{$option} = $value;
		if ($option eq "members"
		    and reftype $value ne "ARRAY") {
		    die("idbif -options.members must be an ARRAY ref;"
			." got $value");
		}
	    }
	} else {
	    push @{ $options->{members} }, $field;
	}
    }

    if (! @{ $options->{members} }) {
	$options->{save_all} = $schema->{classes}{$class};
    }

    $options->{dumper_wanted} = $options->{dumper};
    if (lc $options->{dumper} eq "yaml") {
	# XXX - not reached by test suite
	require 'YAML.pm';
	$options->{dumper} = sub {
	    local($^W)=0;
	    YAML::Dump(shift)
	    };
	$options->{loader} = sub {
	    my $stream = shift;
	    $stream =~ m/^\s*$/s && return undef;
	    $stream .= "\n";
	    my $result = eval {
		local($^W)=0;
		YAML::Load($stream);
	    };
	    if ( $@ ) {
		die "Error parsing this stream: >-\n$stream\n...; $@";
	    } else {
		return $result;
	    }
	};
    } elsif (lc $options->{dumper} eq "data::dumper") {
	require 'Data/Dumper.pm';
	$options->{dumper} = sub {
	    local($Data::Dumper::Purity) = 1;
	    local $Data::Dumper::Indent = 0;  # compact
	    local($Data::Dumper::Terse) = 1;
	    Data::Dumper::Dumper(shift)
	};
	$options->{loader} = sub { eval(shift) };

    } elsif (lc $options->{dumper} eq "storable") {
	# XXX - not reached by test suite
	require 'Storable.pm';
	$options->{dumper} = sub {
	    Storable::freeze(shift)
	};
	$options->{loader} = sub {
	    Storable::thaw(shift)
	};
    }

    %{$_[1]} = ( idbif => $options );

    return "idbif"; # poof!
}

sub get_importer
{
    my ($self, $context) = @_;
    return sub {
	my ($obj, $row, $context2) = @_;
	my $col = shift @$row;

	my $storage = $context2->{storage};
	#print STDERR "About to load: `$col'\n";
	defined(my $tmpobj = $self->{loader}->($storage->from_dbms("blob", $col))) or do {
	
	    warn "loader for IDBIF on ".ref($obj)."[".$storage->id($obj)."] returned no value from >-\n$col\n...";
	    return $obj;
	};
	#print STDERR "Got `$tmpobj'\n";
	Tangram::Type::Dump::unflatten($storage, $tmpobj);
	if ($self->{save_all}) {
	    for my $member (keys %$tmpobj) {
		$obj->{$member} = delete $tmpobj->{$member};
	    }
	} else {
	    for my $member (@{ $self->{members} }) {
		$obj->{$member} = delete $tmpobj->{$member}
		    if exists $tmpobj->{$member};
	    }
	}
	if (ref $tmpobj ne ref $obj and blessed $tmpobj) {
	    # XXX - not reached by test suite
	    bless $obj, ref $tmpobj;
	}
	%$tmpobj=();
	bless $tmpobj, "nothing";  # "unbless" :-)  skip DESTROY
    };
}

sub get_exporter
{
    #my ($self, $context) = @_;
    my $self = $_[0];
    my $field = $self->{name};

    return sub {
	my ($obj, $context2) = @_;
	my $tmpobj = bless { }, ref $obj;
	if ($self->{save_all}) {
	    %$tmpobj = %$obj;
	    while (my $member
		   = each %{ $self->{mt} ||=
				 $self->{save_all}{member_type} }) {
		delete $tmpobj->{$member};
	    }
	} else {
	    for my $member (@{ $self->{members} }) {
		$tmpobj->{$member} = $obj->{$member}
		    if exists $obj->{$member};
	    }
	}
	Tangram::Type::Dump::flatten($context2->{storage}, $tmpobj);
	my $text = $context2->{storage}->to_dbms
	    ("blob", $self->{dumper}->($tmpobj));

	print $Tangram::TRACE "IDBIF - storing: ".Data::Dumper::Dumper($tmpobj)
	    if $Tangram::TRACE and $Tangram::DEBUG_LEVEL > 2;

	Tangram::Type::Dump::unflatten($context2->{storage}, $tmpobj);
	%$tmpobj = ();
	bless $tmpobj, "nothing";
	return $text;
    };
}

# XXX - not tested by test suite
sub save {
  my ($self, $cols, $vals, $obj, $members, $storage) = @_;
  
  my $dbh = $storage->{db};
  
  foreach my $member (keys %$members) {
    my $memdef = $members->{$member};
    
    next if $memdef->{automatic};
    
    push @$cols, $memdef->{col};
    push @$vals, $dbh->quote(&{$memdef->{dumper}}($obj->{$member}));
  }
}

1;
