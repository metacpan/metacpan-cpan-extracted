package Spreadsheet::Template::Generator;
our $AUTHORITY = 'cpan:DOY';
$Spreadsheet::Template::Generator::VERSION = '0.05';
use Moose;
# ABSTRACT: create new templates from existing spreadsheets

use Class::Load 'load_class';
use JSON;



has parser_class => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Spreadsheet::Template::Generator::Parser::XLSX',
);


has parser_options => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has parser => (
    is   => 'ro',
    does => 'Spreadsheet::Template::Generator::Parser',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $class = $self->parser_class;
        load_class($class);
        return $class->new(
            %{ $self->parser_options }
        );
    },
);


sub generate {
    my $self = shift;
    my ($filename) = @_;
    my $data = $self->parser->parse($filename);
    return JSON->new->pretty->canonical->encode($data);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Spreadsheet::Template::Generator - create new templates from existing spreadsheets

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  use Spreadsheet::Template::Generator;

  my $generator = Spreadsheet::Template::Generator->new;
  open my $fh, '>:encoding(utf8)', 'out.json';
  $fh->print($generator->generate($filename));

=head1 DESCRIPTION

This module is used to create new templates from existing spreadsheets. You can
then modify this output to be suitable to use as input for
L<Spreadsheet::Template> by, for instance, adding in L<Text::Xslate> directives
to use your actual data, rather than the hardcoded data in the original
spreadsheet.

=head1 ATTRIBUTES

=head2 parser_class

The class to use for parsing the spreadsheet. Defaults to
L<Spreadsheet::Template::Generator::Parser::XLSX>.

=head2 parser_options

Options to pass to the parser constructor. Defaults to an empty hashref.

=head1 METHODS

=head2 generate($filename)

Returns a string containing the JSON representation of the data contained in
the spreadsheet file C<$filename>. This representation is documented in
L<Spreadsheet::Template>.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
