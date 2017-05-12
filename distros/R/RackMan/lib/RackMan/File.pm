package RackMan::File;

use File::Basename;
use File::Path;
use Moose;
use Path::Class;
use RackMan;
use namespace::autoclean;


has name => (
    is => "rw",
    isa => "Str",
);

has path => (
    is => "rw",
    isa => "Str",
);

has content => (
    is => "rw",
    isa => "Str",
);


#
# fullpath()
# --------
sub fullpath {
    my $self = shift;
    my $file = file(grep length, $self->path, $self->name);
    return "$file"
}


#
# add_content()
# -----------
sub add_content {
    my $self = shift;
    $self->content( join "", $self->content || "", @_ );
}


#
# read()
# ----
sub read {
    my $self = shift;
    my $file = file($self->path, $self->name);
    my $fh   = $file->open("<")
        or RackMan->error("can't read '$file': $!");
    {
        local $/;   # slurp mode
        $self->content($fh->getline);
    }
    $fh->close;
}


#
# write()
# -----
sub write {
    my $self = shift;
    my $file = file($self->path, $self->name);
    mkpath dirname("$file");
    my $fh   = $file->open(">")
        or RackMan->error("can't write '$file': $!");
    $fh->print($self->content);
    $fh->close;
}


__PACKAGE__->meta->make_immutable

__END__

=pod

=head1 NAME

RackMan::File - Generic class to represent a file

=head1 SYNOPSIS

    use RackMan::File;

    my $file = RackMan::File->new(name => "lipsum.txt");
    $file->add_content("Lorem ipsum dolor sit amet");
    $file->write;


=head1 DESCRIPTION

This module is a Moose-based class to represent a file.


=head1 METHODS

=head2 new

Create and return a new object


=head2 add_content

Append content


=head2 fullpath

Return the full path of the file


=head2 read

Read the file from disk in memory


=head2 write

Write the content of the file on disk


=head1 ATTRIBUTES

=head2 name

String, name of the file


=head2 path

String, path to the file


=head2 content

String, content of the file


=head1 AUTHOR

Sebastien Aperghis-Tramoni

=cut

