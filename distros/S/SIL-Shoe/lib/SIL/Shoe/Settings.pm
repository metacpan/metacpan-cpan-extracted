package SIL::Shoe::Settings;

=head1 NAME

SIL::Shoe::Settings - Corresponds to a Shoebox Settings directory

=head1 SYNOPSIS

 $s = SIL::Shoe::Settings->new("c:/My Shoebox Settings");
 $t = $s->type("MDF");
 $l = $s->lang("Default");

=head1 DESCRIPTION

Creates a directory of all .typ and .lng files according to the names that
are stored within the files. Then provides the appropriate objects, read, when
asked.

The following methods are available:

=cut

use strict;
use Carp;
use SIL::Shoe::Type;
use SIL::Shoe::Lang;

=head2 SIL::Shoe::Settings->new("dir");

Reads the given directory building up lists of type and language files. For
each file, an appropriate stub object is read (new is called, but not read).
From this the internal directories are built.

=cut

sub new
{
    my ($class, $dir) = @_;
    my ($self, @test, $t, $s);

    opendir(DIR, "$dir") || croak "Can't open $dir as directory";

    @test = grep {m/^[^.]+\.typ$/oi} readdir(DIR);
    return undef unless (scalar @test > 0);
    foreach $t (@test)
    {
        $s = SIL::Shoe::Type->new("$dir/$t");
        $self->{' type'}{$s->{'name'}} = $s;
    }
    rewinddir(DIR);

    @test = grep {m/^[^.]+\.lng$/oi} readdir(DIR);
    foreach $t (@test)
    {
        $s = SIL::Shoe::Lang->new("$dir/$t");
        $self->{' lang'}{$s->{'name'}} = $s;
    }

    closedir(DIR);
    bless $self, $class;
}

=head2 $s->type($name);

Returns the type object associated with $name if it exists, or undef.

=cut

sub type
{
    my ($self, $name) = @_;
    my ($res) = $self->{' type'}{$name};

    $res->read if defined $res;
    $res;
}

=head2 $s->lang($name);

Returns the lang object associated with $name if it exists, or undef.

=cut

sub lang
{
    my ($self, $name) = @_;
    my ($res) = $self->{' lang'}{$name};

    $res->read if defined $res;
    $res;
}

1;

