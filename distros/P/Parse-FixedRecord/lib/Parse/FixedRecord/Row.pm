package Parse::FixedRecord::Row;
BEGIN {
  $Parse::FixedRecord::Row::AUTHORITY = 'cpan:OSFAMERON';
}
{
  $Parse::FixedRecord::Row::VERSION = '0.06';
}
# ABSTRACT: Row class for Parse::FixedRecord


use Moose;
use Parse::FixedRecord::Column;

use Moose::Util::TypeConstraints;
use DateTime::Format::Strptime;
use DateTime::Format::Duration;
use List::Util qw/max/;

use overload q("") => sub { $_[0]->output };

subtype 'Date' =>
    as class_type('DateTime');

coerce 'Date'
    => from 'Str'
        => via { 
            eval {
                my $f = DateTime::Format::Strptime->new( pattern => '%F' );
                my $d = $f->parse_datetime( $_ );
                $d->set_formatter($f);
                $d;
            }
            };

subtype 'Duration' =>
    as class_type('DateTime::Duration');

coerce 'Duration'
    => from 'Str'
        => via { 
            my $f = DateTime::Format::Duration->new( pattern => '%R' );
            my $d = $f->parse_duration( $_ );
            $d->{formatter} = $f;                      # direct access! Yuck!
            bless $d, 'DateTime::Duration::Formatted'; # rebless!
            return $d;
            };

sub parse {
    my ($class, $string) = @_;

    my @ranges = @{ $class->meta->fields };

    my $length = length($string);
    my $required_length = $class->meta->total_length;
    die "Invalid parse for class $class: input string has length $length, "
      . "but must have length $required_length"
        if $length < $required_length;

    my $pos = 0;
    my %data = map {
        if (ref) {
            # it's an attribute
            my $width = $_->width;
            my $name  = $_->name;
            my $value = substr($string, $pos, $width);
            $pos += $width;
            ($name => $value);
        } else {
            # it's a string
            my $width = length;
            my $found = substr($string, $pos, $width);
            die "Invalid parse on picture '$_' (got '$found' at position $pos)"
                unless $found eq $_;
            $pos += $width;
            ();
        }
        } @ranges;

    return $class->new( %data );
}

sub output {
    my ($self) = @_;

    my @ranges = @{ $self->meta->fields };

    my $string = join '', map {
        if (ref) {
            my $width = $_->width;
            sprintf "\%${width}s", $_->get_value($self);
        } else {
            $_
        }} @ranges;
    return $string;
}

package DateTime::Duration::Formatted;
BEGIN {
  $DateTime::Duration::Formatted::AUTHORITY = 'cpan:OSFAMERON';
}
{
  $DateTime::Duration::Formatted::VERSION = '0.06';
}
our @ISA = 'DateTime::Duration';

use overload q("") => sub {
    my ($self) = @_;
    my $f = $self->{formatter};
    return $f->format_duration_from_deltas($f->normalise($self));
    };

1;

__END__
=pod

=head1 NAME

Parse::FixedRecord::Row - Row class for Parse::FixedRecord

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This is the base class for fixed record parsers.
Provides the C<parse> implementation.

=head2 Methods

=head3 C<parse>

See L<Parse::FixedRecord> for usage;

=head3 C<output>

Provides stringified output.  This is overloaded, so you can just:

    print $obj;

to get an output (in the same format as declared/parsed).  This depends
on each individual parser type having well behaved String overloading!

=head2 Types

::Row declares C<Duration> and C<Date> types for you to use in your
parsers.

=head1 AUTHOR

osfameron <osfameron@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by osfameron.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

