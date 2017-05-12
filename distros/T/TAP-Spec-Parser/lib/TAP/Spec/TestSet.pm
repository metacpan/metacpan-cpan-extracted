package TAP::Spec::TestSet;
BEGIN {
  $TAP::Spec::TestSet::AUTHORITY = 'cpan:ARODLAND';
}
{
  $TAP::Spec::TestSet::VERSION = '0.10';
}
# ABSTRACT: A set of related TAP tests
use Mouse;
use namespace::autoclean;

use TAP::Spec::Body ();
use TAP::Spec::Plan ();
use TAP::Spec::Header ();
use TAP::Spec::Footer ();


has 'body' => (
  is => 'rw',
  isa => 'TAP::Spec::Body',
  handles => {
    lines => 'lines',
    tests => 'tests',
    body_comments => 'comments',
  },
  required => 1,
);


has 'plan' => (
  is => 'rw',
  isa => 'TAP::Spec::Plan',
);


has version => (
    is          => 'rw',
    isa         => 'Int',
    lazy        => 1,
    default     => sub {
        my $self = shift;

        if( my $v = $self->header->version ) {
            return $v->version_number;
        }
        else {
            return 12;
        }
    }
);


has 'header' => (
  is => 'rw',
  isa => 'TAP::Spec::Header',
  handles => { 
    header_comments => 'comments',
  },
  required => 1,
);


has 'footer' => (
  is => 'rw',
  isa => 'TAP::Spec::Footer',
  handles => {
    footer_comments => 'comments',
  },
  required => 1,
);


sub as_tap {
  my ($self) = @_;

  return $self->plan->as_tap()   .
         $self->header->as_tap() .
         $self->body->as_tap()   .
         $self->footer->as_tap();
}


sub passed {
    my $self = shift;

    return '' unless $self->plan;
    my $expected = $self->plan->number_of_tests;

    my @tests = $self->tests;
    return '' unless @tests == $expected;

    my $count = 1;
    for my $test (@tests) {
        return '' unless $test->passed;
        return '' unless $test->number == $count++;
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

TAP::Spec::TestSet - A set of related TAP tests

=head1 VERSION

version 0.10

=head1 ATTRIBUTES

=head2 body

B<Required>: The testset body (contains the test results, as well as any
bail-outs, and any comment lines outside of the headers). Is a 
L<TAP::Spec::Body>.

=head2 plan

B<Required>: The test plan. Is a L<TAP::Spec::Plan>.

=head2 version

B<Computed>: The TAP spec version. If a version is present in the header,
it is used, otherwise version 12 is assumed.

=head2 header

B<Required>: The TAP header. Is a L<TAP::Spec::Header>.

=head2 footer

B<Required>: The TAP footer. Is a L<TAP::Spec::Footer>.

=head1 METHODS

=head2 $testset->as_tap

TAP representation.

=head2 $testset->passed

Whether the testset is considered to have passed. A testset passes if a plan
was found, and the number of tests executed matches the number of tests planned,
and all tests are passing.

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
