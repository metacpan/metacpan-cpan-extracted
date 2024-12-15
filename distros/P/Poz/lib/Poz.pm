package Poz;
use 5.032;
use strict;
use warnings;
use Poz::Builder;
use Exporter 'import';
use Carp;

our $VERSION = "0.02";

our @EXPORT_OK = qw/z/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

$Carp::Internal{'Poz'}++;
$Carp::Internal{'Poz::Builder'}++;
$Carp::Internal{'Poz::Types'}++;
$Carp::Internal{'Poz::Types::scalar'}++;
$Carp::Internal{'Poz::Types::string'}++;
$Carp::Internal{'Poz::Types::number'}++;
$Carp::Internal{'Poz::Types::object'}++;
$Carp::Internal{'Poz::Types::array'}++;

sub z {
    return Poz::Builder->new;
}

1;
__END__

=encoding utf-8

=head1 NAME

Poz - A simple, composable, and extensible data validation library for Perl.

=head1 SYNOPSIS

    use Poz qw/z/;
    use Data::UUID;
    use Time::Piece;
    my $bookSchema = z->object({
        id         => z->string->uuid->default(sub { Data::UUID->new->create_str }),   
        title      => z->string,
        author     => z->string->default("Anonymous"),
        published  => z->date,
        created_at => z->date->default(sub { Time::Piece::localtime()->strftime('%Y-%m-%d') }),
        updated_at => z->date->default(sub { Time::Piece::localtime()->strftime('%Y-%m-%d') }),
    })->as("My::Book");

    my $book = $bookSchema->parse({
        title     => "Spidering Hacks",
        author    => "Kevin Hemenway",
        published => "2003-10-01",
    }) or die "Invalid book data";
    $book->isa("My::Book"); # true

    my ($otherBook, $err) = $bookSchema->safe_parse({
        title => "Eric Sink on the Business of Software",
        author => "Eric Sink",
        published => "2006-0i-01",
    });
    $otherBook; # undef
    $err; # [{key => "", error => "Not a date"}]

=head1 DESCRIPTION

Poz is a simple, composable, and extensible data validation library for Perl. It is inspired heavily from Zod L<https://zod.dev/> in TypeScript.

=head1 EXPORTS

=head2 z

    use Poz qw/z/;
    my $builder = z;

Returns a new instance of Poz::Builder.

=head1 METHODS

=head2 z->object($schema)

    my $schema = z->object({
        id         => z->string->uuid->default(sub { Data::UUID->new->create_str }),   
        title      => z->string,
        author     => z->string->default("Anonymous"),
        published  => z->date,
        created_at => z->date->default(sub { Time::Piece::localtime()->strftime('%Y-%m-%d') }),
        updated_at => z->date->default(sub { Time::Piece::localtime()->strftime('%Y-%m-%d') }),
    })->as("My::Book");

Creates a new schema object.

=head2 z->string

    my $schema = z->string;

Creates a new string schema object.

=head2 z->number

    my $schema = z->number;

Creates a new number schema object.

=head2 z->date

    my $schema = z->date;

Creates a new date schema object.

=head2 z->object

    my $schema = z->object($schema);

Creates a new object schema object.

=head2 z->array

    my $schema = z->array($schema);

Creates a new array schema object.

=head2 z->enum

    my $schema = z->enum(@values);

Creates a new enum schema object.

=head1 SEE ALSO

L<Zod|https://zod.dev/>
L<Poz::Builder>
L<Poz::Types>
L<Poz::Types::string>
L<Poz::Types::number>
L<Poz::Types::object>
L<Poz::Types::array>
L<Poz::Types::enum>

=head1 HOW TO CONTRIBUTE

If you want to contribute to Poz, you can follow the steps below:

=over 4

=item 1. Prepare: Install cpanm and Minilla

    $ curl -L https://cpanmin.us | perl - --sudo App::cpanminus
    $ cpanm Minilla

=item 2. Fork: Please fork the repository on GitHub.

The Repository on GitHub: L<https://github.com/ytnobody/p5-Poz>

=item 3. Clone: Clone the repository.

    $ git clone

=item 4. Branch: Create a feature branch from the main branch.

    $ git checkout -b feature-branch main

=item 5. Code: Write your code and tests, then build.

    $ minil build

=item 6. Test: Run the tests.

    $ minil test

=item 7. Commit: Commit your changes.

    $ git commit -am "Add some feature"

=item 8. Push: Push to your branch.
    
    $ git push origin feature-branch

=item 9. Pull Request: Create a new Pull Request on GitHub.

=back

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

