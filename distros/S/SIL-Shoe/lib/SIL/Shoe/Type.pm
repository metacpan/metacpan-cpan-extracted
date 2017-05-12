package SIL::Shoe::Type;

=head1 NAME

SIL::Shoe::Type - Class for handling Database Type files.

=head1 SYNOPSIS

 require SIL::Shoe::Type;
 $s = SIL::Shoe::Type->new("mdf.typ");
 $s->read;
 $lang = $s->{'mrk'}{"le"}{'lang'};

=head1 DESCRIPTION

This class allows easy access to information held in a database type file.
Due to the complex structure of the type file, the true hierarchy is
restructured in order to make certain information more readily available.

Usually, information is available via the path of marker groups it is in.
But some of the layers of hierarchy are removed and some of the groups are
changed structurally. Thus instead of having to search an array of mkr fields
in the mkrset to find a marker of interest, the group has been restructured
to allow simply $s->{'mkr'}{"$mkrname"} to locate the appropriate associative
array.

The follow layers of hierarchy are simply deleted: DatabaseType, mkrset,
intprclst, drflst, mrflst, filset, expset. Most of these only occur at the
top level and rely on their not being subname clashes.

The following groups are structured as associative arrays based on the group
marker's value: mkr (as mkr) and fil (as fil) both available at the top level.

Finally, interlinear processes (intprc) form an ordered list. Thus each intprc
occurs within an array (referencable by $s->{'intprc'}[$x]) and its type is
stored as a sub field within the particular process' associative array, called
'type'.

All other groups simply form a new sub associative array into which all its
elements are placed. For multiply defined markers and groups, arrays are formed
as needed rather than the convential name mangling of SIL::Shoe::Data.

The following methods are available:

=cut

use SIL::Shoe::Control;
use strict;
use vars qw(@ISA);

@ISA = qw(SIL::Shoe::Control);

# tells what to do with various group type markers. First char ==
#   0   ->  delete group marker and do nothing. Has the effect of moving
#           the group contents up one level into the outer layer. OK
#           if no name clashes will occur.
#   h   ->  make a hash against the second parameter, then use the value
#           against the group marker to make another hash within that. Can't
#           have multiple identical values in this setup.
#   a   ->  make an array against the group name and then make a hash within
#           that which has an element named by the second parameter into which
#           goes the value against the group marker.
my (%groups) = (
        "mkrset" => ["0", ""],
        "mkr"    => ["h", "mkr"],
        "intprclst" => ["0", ""],
        "intprc" => ["a", "type"],
        "drflst" => ["0", ""],
        "mrflst" => ["0", ""],
        "expset" => ["0", ""],
        "filset" => ["0", ""],
        "fil"    => ["l", "fil"],
        "template" => ["l", ""],
        "DatabaseType" => ["0", ""]
          );

sub group
{
    my ($self, $name) = @_;
    return $groups{$name};
}

sub multiline
{
    my ($self, $name, $isgroup) = @_;
    return 0 if ($name eq "desc");
    return 1;
}

sub add_specials
{
    my ($self) = @_;
    my ($t);
    
    foreach $t (keys %{$self->{'mkr'}})
    {
        next unless defined ($self->{'mkr'}{$t}{'desc'});
        while ($self->{'mkr'}{$t}{'desc'} =~ m/\\(\S+)\s*([^\\]*)/ogsx)
        { $self->{'mkr'}{$t}{$1} = $2; }
    }
    while ($self->{'desc'} =~ m/\\(\S+)\s*([^\\]*)/ogsx)
    {
        if (ref $self->{$1})
        { push (@{$self->{$1}}, $2); }
        elsif ($self->{$1})
        { $self->{$1} = [$self->{$1}, $2]; }
        else
        { $self->{$1} = $2; }
    }
    $self;
}

1;

