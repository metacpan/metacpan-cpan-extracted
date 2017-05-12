package Perl::Tags::PPI;

use strict; use warnings;

use base qw(Perl::Tags);

use PPI;

our $VERSION = '0.32';

sub ppi_all {
    my ( $self, $file ) = @_;

    my $doc = PPI::Document->new($file) || return;

    $doc->index_locations;

    return map { $self->_tagify( $_, "$file" ) }
      @{ $doc->find(sub { $_[1]->isa("PPI::Statement") }) || [] }
}

sub get_tags_for_file {
    my ( $self, $file, @parsers ) = @_;

    my @tags = $self->ppi_all( $file );

    return @tags;
}

sub _tagify {
    my ( $self, $thing, $file ) = @_;

    my $class = $thing->class;

    my ( $first_line ) = split /\n/, $thing;

    if ( my ( $subtype ) = ( $class =~ /^PPI::Statement::(.*)$/ ) ) {

        my $method = "_tagify_" . lc($subtype);

        if ( $self->can($method) ) {
            return $self->$method( $thing, $file, $first_line );
        }
    }

    return $self->_tagify_statement($thing, $file, $first_line);
}

# catch all
sub _tagify_statement {
    my ( $self, $thing, $file, $first_line ) = @_;

    return;
}

sub _tagify_sub {
    my ( $self, $thing, $file, $line ) = @_;

    return Perl::Tags::Tag::Sub->new(
        name    => $thing->name,
        file    => $file,
        line    => $line,
        linenum => $thing->location->[0],
        pkg     => $thing->guess_package
    );
}

sub _tagify_variable {
    my ( $self, $thing, $file, $line ) = @_;
    return map {
        Perl::Tags::Tag::Var->new(
            name    => $_,
            file    => $file,
            line    => $line,
            linenum => $thing->location->[0],
          )
    } $thing->variables;
}

sub _tagify_package {
    my ( $self, $thing, $file, $line ) = @_;

    return Perl::Tags::Tag::Package->new(
        name    => $thing->namespace,
        file    => $file,
        line    => $line,
        linenum => $thing->location->[0],
    );
}

sub _tagify_include {
    my ( $self, $thing, $file ) = @_;

    if ( my $module = $thing->module ) {
        return Perl::Tags::Tag::Recurse->new(
            name    => $module,
            line    => "dummy",
        );
    }

    return;
}

sub PPI::Statement::Sub::guess_package {
    my ($self) = @_;

    my $temp = $self;
    my $package;

    while (1) {
        $temp = $temp->sprevious_sibling
          or last;

        if ( $temp->class eq 'PPI::Statement::Package' ) {
            $package = $temp;
            last;
        }
    }

    return $package;
}

=head1 NAME

Perl::Tags::PPI - use PPI to parse 

=head1 DESCRIPTION

This is a drop-in replacement for the basic L<Perl::Tags> parser.  Please see that module's
perldoc, and test C<t/04_ppi.t> for details.

(Doc patches very welcome!)

=head1 AUTHOR

 (c) Wolverian 2006

Modifications by nothingmuch

=cut

1;
