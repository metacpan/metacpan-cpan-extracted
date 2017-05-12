package My::MyModulePod;

use 5.006;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{foo} = 'FOO';
    return $self;
}

sub function1 {
  return 'function1 called';
}

sub function2 {
  return 'function2 called';
}

1;

__END__
=head1 NAME

My::MyModulePod - test

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

  use My::MyModulePod;
  my $mm = My::MyModulePod->new();
  print $mm->function1,"\n";

=cut

# perdoc does not parse this code bu perl-run-end does execute it
use My::MyModulePod;
my $mm = My::MyModulePod->new();
print "test synopsis\n";
print $mm->function1,"\n";

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 instantiate
  my $mm = My::MyModulePod->new();

=cut


=head2 function1

 provides useful funtion type access

 $mm->function1;

=cut

print "test method definition\n";
print $mm->function1,"\n";


=head2 function2

 provides useful funtion type access

 $mm->function1;

=cut

print $mm->function2,"\n";

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-self at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Self>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=cut

