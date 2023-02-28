package Sietima::CmdLine;
use Moo;
use Sietima::Policy;
use Sietima::Types qw(SietimaObj);
use Types::Standard qw(HashRef);
use Sietima;
use App::Spec;
use Sietima::Runner;
use namespace::clean;

our $VERSION = '1.1.1'; # VERSION
# ABSTRACT: run Sietima as a command-line application


has sietima => (
    is => 'ro',
    required => 1,
    isa => SietimaObj,
);


has extra_spec => (
    is => 'ro',
    isa => HashRef,
    default => sub { +{} },
);


sub BUILDARGS($class,@args) {
    my $args = $class->next::method(@args);
    $args->{sietima} //= do {
        my $traits = delete $args->{traits} // [];
        my $constructor_args = delete $args->{args} // {};
        Sietima->with_traits($traits->@*)->new($constructor_args);
    };
    return $args;
}


has app_spec => (
    is => 'lazy',
    init_arg => undef,
);

sub _build_app_spec($self) {
    my $spec_data = $self->sietima->command_line_spec();

    return App::Spec->read({
        $spec_data->%*,
        $self->extra_spec->%*,

        # App::Spec 0.005 really wants a class name, even when we pass
        # a pre-build cmd object to the Runner
        class => ref($self->sietima),
    });
}


has runner => (
    is => 'lazy',
    init_arg => undef,
    handles => [qw(run)],
);

sub _build_runner($self) {
    return Sietima::Runner->new({
        spec => $self->app_spec,
        cmd => $self->sietima,
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::CmdLine - run Sietima as a command-line application

=head1 VERSION

version 1.1.1

=head1 SYNOPSIS

  use Sietima::CmdLine;

  Sietima::CmdLine->new({
    traits => [qw(SubjectTag)],
    args => {
      return_path => 'list@example.net',
      subject_tag => 'Test',
      subscribers => \@addresses,
  })->run;

=head1 DESCRIPTION

This class simplifies the creation of a L<< C<Sietima> >> object, and
uses L<< C<App::Spec> >> to provide a command-line interface to it.

=head1 ATTRIBUTES

=head2 C<sietima>

Required, an instance of L<< C<Sietima> >>. You can either construct
it yourself, or use the L<simplified building provided by the
constructor|/new>.

=head2 C<extra_spec>

Optional hashref. Used inside L<< /C<app_spec> >>. If you're not
familiar with L<< C<App::Spec> >>, you probably don't want to touch
this.

=head1 METHODS

=head2 C<new>

  my $cmdline = Sietima::CmdLine->new({
    sietima => Sietima->with_traits(qw(SubjectTag))->new({
      return_path => 'list@example.net',
      subject_tag => 'Test',
      subscribers => \@addresses,
    }),
  });

  my $cmdline = Sietima::CmdLine->new({
    traits => [qw(SubjectTag)],
    args => {
      return_path => 'list@example.net',
      subject_tag => 'Test',
      subscribers => \@addresses,
  });

The constructor. In alternative to passing a L<< C<Sietima> >>
instance, you can pass C<traits> and C<args>, and the instance will be
built for you. The two calls above are equivalent.

=head2 C<app_spec>

Returns an instance of L<< C<App::Spec> >>, built from the
specification returned by calling L<<
C<command_line_spec>|Sietima/command_line_spec >> on the L<<
/C<sietima> >> object, modified by the L<< /C<extra_spec> >>. This
method, and the C<extra_spec> attribute, are probably only interesting
to people who are doing weird extensions.

=head2 C<runner>

Returns an instance of L<< C<Sietima::Runner> >>, built from the L<<
/C<app_spec> >>.

=head2 C<run>

Delegates to the L<< /C<runner> >>'s L<< C<run>|App::Spec::Run/run >> method.

Parser the command line arguments from C<@ARGV> and executes the
appropriate action.

=for Pod::Coverage BUILDARGS

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
