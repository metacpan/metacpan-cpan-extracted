package Orze::Sources;

use strict;
use warnings;

use Carp;

=head1 NAME

Orze::Sources - Superclass of all Orze::Sources::

=head1 SYNOPSIS

  package Orze::Sources::Foo;

  use strict;
  use warnings;
  use base qw( Orze::Sources );
  use Text::Foo;

  sub process {
      # do some cool stuff
  }

=head1 METHODS

=cut

=head2 new

Create the source object, using the C<$page> tree and the C<$variables>
hash.

=cut

sub new {
    my ($name, $page, $var) = @_;

    my $self = {};
    bless $self, $name;

    $self->{name} = $name;
    $self->{page} = $page;
    $self->{var}  = $var;

    return $self;
}

=head2 evaluate

Do the evaluation. You need to subclass it !

=cut

sub evaluate {
    croak "You really should subclass this package !!!!";
}

=head2 cleanpath

Delete C<..> and add C<data/> prefix to paths used in driver modules.

It's not really intended to be safe, only to help to enforce to only use data in C<data/>.

=cut

sub cleanpath {
    my ($self, $file) = @_;

    my $outputdir = $self->{page}->att('outputdir');
    my $path = $self->{page}->att('path');

    $file =~ s!\.\./!!g;
    $file =~ s!^/!!;
    $file = "data/" . $outputdir . $path . $file;

    return $file;
}

=head2 warning

Display a warning message during the processing, giving information on
the current page, the current source and the current variable.

=cut

sub warning {
    my ($self, @message) = @_;

    my $name = $self->{name};
    my $path = $self->{page}->att('path');
    my $page_name = $self->{page}->att('name');
    my $var_name = $self->{var}->att('name');

    warn
        $name . " warning for " .
        $path . $page_name . "->" . $var_name . ": ",
        @message, "\n";
}

=head2 file

If there an attribute C<file> in the variable, use it. Otherwise, use the name of page.

If there is an argument, use it as a suffix.

=cut

sub file {
    my $self = shift;
    my $suffix = shift;

    my $page = $self->{page};
    my $var  = $self->{var};

    my $file;
    if (defined($var->att('file'))) {
        $file = $self->cleanpath($var->att('file'));
    }
    else {
        if (defined($page->att('name'))) {
            $file = $self->cleanpath($page->att('name'));
            if (defined($suffix)) {
                $file = $file . "." . $suffix;
            }
        }
    }
    return $file;
}

1;
