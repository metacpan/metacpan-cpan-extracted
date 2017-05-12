package MyModule;

use 5.006;
use strict;
use warnings FATAL => 'all';
#use criticism 'brutal'; # use critic with a ~/.perlcriticrc
use Carp qw/croak/;
use Data::Dumper qw/Dumper/;

=head1 NAME

MyModule - test

=head1 VERSION

Version 0.01

=cut

#our $VERSION = '0.01';
#major-version.minor-revision.bugfix
use version; our $VERSION = qv('0.1.0');

=head1 SYNOPSIS


=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 instantiate

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{foo} = 'FOO';
    return $self;
}

=head2 function1

=cut

sub function1 {
  return 'function1 called';
}

=head2 function2

=cut

sub function2 {
  return 'function2 called';
}

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-self at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Self>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=cut

1; # End of Test::Self

__END__
use strict;
use warnings;

use MyModule;

my $ym = MyModule->new();
print $ym->{foo};
print $ym->function1;
print $ym->function2;
