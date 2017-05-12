package Template::Plugin::DateTime::Format;
$Template::Plugin::DateTime::Format::VERSION = '0.03';
# ABSTRACT: format DateTime objects from inside TT with DateTime::Format-style formatters

use 5.006;
use strict;
use warnings;
use DateTime;
use Class::Load;

use base 'Template::Plugin';

sub new {
    my ($class, $context, $formatter_class, $new_args, $format_args) = @_;
    Class::Load::load_class($formatter_class || die 'need class name');

    my @new_args = ref $new_args eq 'ARRAY' ? @$new_args : $new_args;
    { no warnings;
      $format_args = [ $format_args ] unless ref $format_args eq 'ARRAY';
    }

    bless {
	_CONTEXT    => $context,
        formatter   => $formatter_class->new(@new_args),
        format_args => $format_args,
    }, $class;
}

sub format {
    my ($self, $date) = @_;

    my $fmt = $self->{formatter};
    my @args = $self->{format_args};
    return $fmt->format_datetime($date, @args);
}

1;

__END__

=head1 NAME

Template::Plugin::DateTime::Format - format DateTime objects from inside TT with DateTime::Format-style formatters

=head1 SYNOPSIS

   [% USE f = DateTime::Format('DateTime::Format::Strptime', { pattern => "%T" }) %]
   [% f.format(datetime_object) %]

=head1 DESCRIPTION

Oftentimes, you have a L<DateTime|DateTime> object that you want to
render in your template.  However, the default rendering
(2008-01-01T01:23:45) is pretty ugly.  Formatting the DateTime with a
L<DateTime::Format|DateTime::Format> object is the usual solution, but
there's usually not a nice place to put the formatting code.

This plugin solves that problem.  You can create a formatter object
from within TT and then use that object to format DateTime objects.

=head2 CREATING AN OBJECT

Creating a formatter instance is done in the usual TT way:

  [% USE varname = DateTime::Format( ... args ... ) %]

This creates a new formatter and calls it C<varname>.

The constructor takes up to three arguments.  The first argument is
the name of the formatter class.  It is required, and the named class
must follow the DateTime::Format API.  An exception will be thrown if
the class cannot be loaded.

The second argument is a reference to pass
to the formatter's constructor.  If it is an array reference, the
array will be dereferenced before being passed to C<new> as C<@_>.
Otherwise, the single reference is passed to the constructor.

The third argument is optional and is the rest of C<@_> to pass to
C<format_datetime> after the DateTime object.  I don't know if this is
actually allowed by the API, but I figured it might come in handy.

=head2 FORMATTING DATES

Once you've created the object, invoke the C<format> method with the
DateTime object you'd like to format.  The result of
C<format_datetime> is returned.

=head1 METHODS

=head2 new

Called by TT to create a new formatter.

=head2 format($datetime)

Formats C<$datetime>.

=head1 REPOSITORY

L<https://github.com/neilbowers/Template-Plugin-DateTime-Format>

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008 Jonathan Rockway.

This module is free software.  You may redistribute it under the same
terms as perl itself.

