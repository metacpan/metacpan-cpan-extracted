use strict;
use warnings;

package MooseX::TypeArray::Error;
BEGIN {
  $MooseX::TypeArray::Error::VERSION = '0.1.0';
}

# ABSTRACT: Information container for validation failures from MooseX::TypeArrays' constraints

use Moose;
use Try::Tiny;

#use Class::Load;
use overload '""' => \&get_message;

#with 'StackTrace::Auto';


has 'name' => (
  isa      => 'Str',
  is       => 'rw',
  required => 1,
);


has 'value' => (
  is       => 'rw',
  required => 1,
);


has 'errors' => (
  isa      => 'HashRef',
  is       => 'rw',
  required => 1,
);


has 'message' => (
  isa       => 'CodeRef',
  is        => 'rw',
  predicate => 'has_message',
  traits    => ['Code'],
  handles   => { '_message' => 'execute', },
);


has '_stack_trace' => (
  is       => 'ro',
  isa      => 'CodeRef',
  builder  => '_build_stack_trace',
  init_arg => undef,
  required => 1,
  traits   => ['Code'],
  handles  => { 'stack_trace' => 'execute' },
);

sub _build_stack_trace {
  require Devel::StackTrace;
  my $found_mark = 0;

  # my $uplevel    = 6;
  my $trace = Devel::StackTrace->new(

    #    no_refs => 1,
    indent => 1,

    #    frame_filter => sub {
    #      my ($raw) = @_;
    #        if ($found_mark) {
    #         return 1 unless $uplevel;
    #        return !$uplevel--;
    #     }
    #     else {
    #       $found_mark = scalar $raw->{caller}->[3] =~ /new$/;
    #       return 0;
    #     }
    #   }
  );

  # this is to hide the guts of the stacktrace if you pass it to a dumper. Its far too bloaty.
  return sub { $trace };
}


sub get_message {
  my ($self) = @_;
  if ( $self->has_message ) {
    local $_ = $self->value;
    return $self->_message( $self, $_ );
  }
  my $value = $self->value;

  # Stolen liberally from Moose::Meta::TypeConstraint;

  # have to load it late like this, since it uses Moose itself
  my $can_partialdump = try {

    # versions prior to 0.14 had a potential infinite loop bug
    Class::MOP::load_class( 'Devel::PartialDump', { -version => 0.14 } );
    1;
  };
  if ($can_partialdump) {
    $value = Devel::PartialDump->new->dump($value);
  }
  else {
    $value = ( defined $value ? overload::StrVal($value) : 'undef' );
  }
  my @lines = ( 'Validation failed for \'' . $self->name . '\' with value ' . $value . ' :' );
  my $index = 0;
  push @lines, q{ -- };
  for my $suberror ( sort keys %{ $self->errors } ) {
    $index++;
    my $errorstr = q{} . $self->errors->{$suberror};
    push @lines, sprintf q{ %s. %s: }, $index, $suberror;
    ## no critic ( ProhibitComplexMappings )
    push @lines, map { ( my $x = $_ ) =~ s/\A/    /msx; $x } split /\n/msx, $errorstr;
  }
  push @lines, q{ -- };
  push @lines, $self->stack_trace->as_string;
  return join qq{\n}, @lines;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

MooseX::TypeArray::Error - Information container for validation failures from MooseX::TypeArrays' constraints

=head1 VERSION

version 0.1.0

=head1 METHODS

=head2 get_message

=head1 ATTRIBUTES

=head2 name

=head2 value

=head2 errors

=head2 message

=head1 PRIVATE ATTRIBUTES

=head2 _stack_trace

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

