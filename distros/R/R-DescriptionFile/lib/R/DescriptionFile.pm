package R::DescriptionFile;

# ABSTRACT: R package DESCRIPTION file parser

use strict;
use warnings;

use Path::Tiny;

our $VERSION = '0.002'; # VERSION

my @keys_deps      = qw(Depends Suggests);
my @keys_list_type = qw(
  Imports Enhances LinkingTo URL Additional_repositories
);
my @keys_logical = qw(
  LazyData LazyLoad KeepSource ByteCompile ZipData Biarch BuildVignettes
  NeedsCompilation
);

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub parse_file {
    my ( $proto, $file ) = @_;
    my $self = ref $proto ? $proto : $proto->new;
    my @lines = path($file)->lines_utf8( { chomp => 1 } );
    return $self->_parse_lines( \@lines );
}

sub parse_text {
    my ( $proto, $text ) = @_;
    my $self = ref $proto ? $proto : $proto->new;
    my @lines = split( /\n+/, $text );
    return $self->_parse_lines( \@lines );
}

sub _parse_lines {
    my ( $self, $lines ) = @_;

    my $line_idx = 0;

    my $get_line = sub {
        my $line = $lines->[ $line_idx++ ];
        while ( defined $line and $line =~ /^\s*$/ ) {
            $line = $lines->[ $line_idx++ ];
        }
        return $line;
    };

    my $curr_line = &$get_line();
    while ( defined $curr_line ) {
        my $next_line = &$get_line();
        if ( defined $next_line and $next_line =~ /^\s+(.*)/ ) {
            $curr_line .= $1;
            next;
        }

        $self->_parse_line( $curr_line, $line_idx );
        $curr_line = $next_line;
    }

    $self->_check_mandatory_fields;

    return $self;
}

sub _parse_line {
    my ( $self, $line, $line_idx ) = @_;

    my ( $key, $val ) = split( /:/, $line, 2 );
    unless ( defined $val ) {
        die "Invalid DESCRIPTION. Field not seen at line $line_idx: $line";
    }

    $key = _trim($key);
    $val = _trim($val);

    if ( grep { $key eq $_ } @keys_deps ) {
        my $deps      = _split_list($val);
        my %deps_hash = map {
            $_ =~ /([^\(]*)(?:\((.*)\))?/;
            my ( $pkg, $req ) = map { defined $_ ? _trim($_) : 0 } ( $1, $2 );
            ( $pkg => $req );
        } @$deps;
        $self->{$key} = \%deps_hash;
    }
    elsif ( grep { $key eq $_ } @keys_list_type ) {
        $self->{$key} = _split_list($val);
    }
    elsif ( grep { $key eq $_ } @keys_logical ) {
        $self->{$key} = !!( $val =~ /^(yes|true)$/ );
    }
    else {
        $self->{$key} = $val;
    }
}

sub _check_mandatory_fields {
    my ($self) = @_;

    my @missing_fields = grep { !exists $self->{$_} } qw(
      Package Version License Description Title
    );
    if ( !exists $self->{'Authors@R'} ) {
        push @missing_fields,
          grep { !exists $self->{$_} } qw(Author Maintainer);
    }
    @missing_fields = sort @missing_fields;

    if (@missing_fields) {
        die "Invalid DESRIPTION. Missing mandatory fields: "
          . join( ", ", @missing_fields );
    }
}

sub get {
    my ( $self, $key ) = @_;
    return $self->{$key};
}

## utlities

sub _trim {
    my ($s) = @_;
    $s =~ s/^\s+//s;
    $s =~ s/\s+$//s;
    return $s;
}

sub _split_list {
    my ( $s, $r_sep ) = @_;
    $r_sep ||= qr/,/;
    my @lst = map { _trim($_) } split( $r_sep, _trim($s) );
    return \@lst;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

R::DescriptionFile - R package DESCRIPTION file parser

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use R::DescriptionFile;

    my $desc1 = R::DescriptionFile->parse_file("DESCRIPTION");
    print $desc1->{'Description'};
    print $desc1->get('Depends');

    my $desc2 = R::DescriptionFile->parse_text($desc_file_text);

=head1 DESCRIPTION

This module provides a parser for R's C<DESCRIPTION> file which is shipped 
with a R package and contains meta data of the R package. 

C<parse_file()> or C<parse_text()> returns object of this module class. It's
a blessed hash, so fields of DESCRIPTION can be accessed via hash keys. There
is also a C<get> method which does the same thing. 

For dependency fields like C<Depends>, C<Suggests>, they would be parsed to
hashrefs of the form C<{ pkgname =E<gt> version_spec }>. For list fields like
C<LinkingTo>, C<URL>, they would be parsed to arrayrefs.

=head1 SEE ALSO

R DESCRIPTION file spec:
L<https://cran.r-project.org/doc/manuals/r-release/R-exts.html#The-DESCRIPTION-file>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
