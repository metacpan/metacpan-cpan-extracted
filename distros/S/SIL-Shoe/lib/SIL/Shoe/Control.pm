package SIL::Shoe::Control;

=head1 NAME

SIL::Shoe::Control - Abstract superclass for SF Control files in Shoebox

=head1 DETAILS

This class parses a control file based on a parsing model passed by the
subclass. It handles groups and all the vagueries currently encountered in
Shoebox control files.

The following methods are available:

=cut

use strict;
use Carp;
use Symbol;

=head2 SIL::Shoe::Control->new("filename")

This creates a new type object, but only reads the name of the database type.
This allows SIL::Shoe::Settings to read all the type files without filling up
memory. The settings file is only fully read when $s->read is called.

=cut

sub new
{
    my ($class, $file) = @_;
    my ($self, $fh);

    $fh = Symbol->gensym();
    if (not open ($fh, "$file")) {
        croak("Unable to open $file");
        return undef;
    }

    $self->{' INFILE'} = $fh;
    $self->{' fname'} = $file;
    open($fh, "$file") and ($_ = <$fh>);
    s/^\xEF\xBB\xBF//o;        # BOM in UTF8
    chomp;
    if (m/^\\\+(\S+)\s+(.*?)\s*$/o)
    { $self->{'name'} = $2; }
    else
    { croak("Malformed database type file ($file)"); }
    close ($fh);
    bless $self, $class;
}

=head2 $s->read

This reads the type file into memory and readjusts everything to make stuff
easier to find.

=cut

sub read
{
    my ($self) = @_;

    return $self if $self->{' read'};
    
    open ($self->{' INFILE'}, $self->{' fname'})
        || &croak("Unable to re-open $self->{' fname'}");

    $self->parse($self->{' INFILE'});
    close ($self->{' INFILE'});
    $self->{' read'} = 1;
    return $self;
}

sub parse
{
    my ($self, $fh) = @_;
    my ($target, $name, $val, $curr_mark, $info, $new, $inlines, $multiline);
    my ($temp);

    $target = $self;
    while (<$fh>)
    {
#        chomp;
        s/\s+$//o;
        s/^\xEF\xBB\xBF//o;
        next unless $_ ne "";
        if (m/^\\\-(.*?)\s*$/oi)
        {
            $inlines = 0;
            if ($1 ne pop(@{$self->{' hiern'}}))      # ') for editor
            { &croak("Synchronisation error in $self->{' fname'} at $_"); }
            else
            {
                $target = pop(@{$self->{' hier'}});
                return $self if $#{$self->{' hier'}} < 0;
            }
        }           # ( /* for editor
        elsif (m/^\\\+(\S+)\s*(.*?)\s*$/oi)
        {
            $name = $1;
            $val = $2;
            $info = $self->group($name);
            $multiline = $self->multiline($name, 1);
            push(@{$self->{' hiern'}}, $name);
            push(@{$self->{' hier'}}, $target);
            if (defined $info)
            {
                if ($info->[0] eq "h")
                {
                    $new = {};
                    $target->{$info->[1]}{$val} = $new;
                    $target = $new;
                } elsif ($info->[0] eq "a")
                {
                    if (!defined $target->{$name})
                    { $target->{$name} = []; }
                    $new = { "$info->[1]" => $val };
                    push (@{$target->{$name}}, $new);
                    $target = $new;
                } elsif ($info->[0] eq "l")
                {
                    $inlines = 1;
                    $new = [];
                    $temp = $info->[1] ne "" ? $val : $name;
                    $target->{$temp} = $new;
                    $target = $new;
                    push (@{$target}, $val) if ($info->[1] eq "" && $val ne "")
                }
            } else
            {
                $new = {};
                if (defined $target->{$name})
                {
                    if (ref $target->{$name} ne "ARRAY")
                    { $target->{$name} = [$target->{$name}]; }
                    push (@{$target->{$name}}, $new);
                } else
                { $target->{$name} = $new; }
                $target = $new;
            }
            undef $curr_mark;
        }           # ( /* for editor
        elsif (!$inlines && m/^\\(\S+)\s*(.*?)\s*$/oi)
        {
            $name = $1;
            $val = $2;
            $multiline = $self->multiline($name, 0);
            if (defined $target->{$name})
            {
                if (!ref $target->{$name})
                { $target->{$name} = [$target->{$name}]; }
                push (@{$target->{$name}}, $val);
                $curr_mark = \$target->{$name}[-1];
            } else
            {
                $target->{$name} = $val;
                $curr_mark = \$target->{$name};
            }
        } elsif (!$inlines && defined $curr_mark)
        {
#            s/^\s+//oig;
            $$curr_mark .= ($multiline || m/^\s\s/o ? "\n" : " ") if ($$curr_mark ne "");
            $$curr_mark .= $_;
        } elsif ($inlines)
        { push (@{$target}, $_); }
        else
        {
            s/^\s+//og;
            $target->{' '} .= ($multiline ? "\n" : " ") if ($target->{' '} ne "");
            $target->{' '} .= $_;
        }
    }
    $self;
}

=head2 $self->group()

Subclasses should provide this method to return details of how to parse a
particular group instruction. The return value is an array reference with two
elements: Type and parameter, according to the following format.

 tells what to do with various group type markers. First char ==
   0   ->  delete group marker and do nothing. Has the effect of moving
           the group contents up one level into the outer layer. OK
           if no name clashes will occur.
   h   ->  make a hash against the second parameter, then use the value
           against the group marker to make another hash within that. Can't
           have multiple identical values in this setup.
   a   ->  make an array against the group name and then make a hash within
           that which has an element named by the second parameter into which
           goes the value against the group marker.
   l   ->  the contents of the group are strictly held in lines and not
           processed as markers. If the second parameter is present then the
           value of the marker identifies the list within an associative array
           named by the parameter. If not, then the list is stored according to
           the marker name, and the value, if present is stored as part of the
           list.

=head2 $self->multiline()

Returns whether this marker takes multiline or wrapped line data.

=cut

1;

