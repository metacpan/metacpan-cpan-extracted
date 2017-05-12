package SOOT::Struct;
use strict;
use warnings;
use File::Basename qw();
use Carp 'croak';

require SOOT;

sub new {
  my $class = shift;
  my %args = @_;
  
  if (not defined $args{name}) {
    croak("New struct needs a 'name'");
  }

  my $self = bless({
    name => $args{name},
    fields => [],
  } => $class);

  if (defined $args{fields}) {
    $self->add_fields(
      ref($args{fields}) eq 'ARRAY'
      ? @{$args{fields}}
      : $args{fields}
    );
  }
  return $self;
}

sub code {
  my $self = shift;
  my $code = "class $self->{name} : public TObject {\n\tpublic:\n";
  my $fields = [@{$self->{fields}}];
  while (@$fields) {
    my $fieldname = shift @$fields;
    my $type = shift @$fields;
    $type =~ s/;?\s*$//;
    if ($type =~ s/(\[\d+\])\s*$//) {
      $fieldname .= $1;
    }
    $code .= "\t$type\t$fieldname;\n";
  }
  $code .= "\tClassDef($self->{name}, 1);\n};\n";
  return $code;
}

# TODO Should this happen in ./.SOOTTemporaries or somesuch?
sub compile {
  my $self = shift;
  my $code = $self->code;
  my $ccname = $self->cc_name;
  my $fh;
  if (-f $ccname) {
    open $fh, '+<', $ccname
      or die "Could not open C++ file '$ccname' for reading/writing: $!";
    my $cmpcode = do {local $/; <$fh>};
    if ($code eq $cmpcode) {
      undef $fh;
    }
    else {
      seek $fh, 0, 0;
      truncate $fh, 0;
    }
  }
  else {
    open $fh, '>', $ccname
      or die "Could not open C++ file '$ccname' for writing: $!";
  }
  print $fh $code if defined $fh;
  close $fh if defined $fh;
  $SOOT::gROOT->ProcessLine(".L $ccname+");
  SOOT->UpdateClasses(); # FIXME maybe just generate the stub for the new class?
}

sub cc_name {
  my $self = shift;
  my $ccname = "soottmp_" . File::Basename::basename($0);
  $ccname =~ s/\.[^.]*$//;
  $ccname .= "_" . $self->{name} . ".cc";
  $ccname =~ s/([^\.\w])//g;  
  return $ccname;
}


sub add_fields {
  my $self = shift;
  return if not @_ or not defined $_[0];
  if (@_ == 1) {
    my $code = shift;
    $code =~ s/^[^{]*{//;
    $code =~ s/}.*$//;
    my @statements = split /;/, $code;
    foreach (@statements) {
      next if /^\s*$/;
      s/\n/ /g;
      if (not m{^\s*
                (\w+[\s*\*]*) # type
                \s+
                (\w+) # name
                ((?:\[\d+\])?) # ary?
                \s*$
               }x) {
        croak("Invalid field declaration: '$_'");
      }
      my $type = $1;
      my $name = $2;
      my $arystuff = $3;
      $type =~ s/\s+//g;
      $type .= $arystuff if defined $arystuff;
      push @{$self->{fields}}, $name, $type;
    }
  }
  else {
    while (@_) {
      my $name = shift;
      my $type = shift;
      $name =~ s/\s+//g;
      $type =~ s/\s+//g;
      push @{$self->{fields}}, $name, $type;
    }
  }
}

1;
__END__

=head1 NAME

SOOT::Struct - Perl interface to generate new C-level struct types

=head1 SYNOPSIS

  use SOOT::Struct;
  my $struct = SOOT::Struct->new(
    name   => 'person_t',
    fields => [
      'name' => 'Char_t[20]',
      'age'  => 'UInt_t',
    ],
  );
  
  print $struct->code;
  # prints the C-code necessary for compilation
  
  $struct->compile;
  # writes the code to a temporary file and compiles it with CInt/ACLiC
  
  my $person = person_t->new;
  $person->name("Steffen"); # stores in struct via SOOT
  print $person->name(), "\n"; # fetches via SOOT

=head1 DESCRIPTION

This package provides a (limited) object oriented interface
to creating new C-level structs that are known to ROOT and available
as Perl classes.

All struct members will be available as Perl methods (see SYNOPSIS above).
The Perl methods return the value of the struct member when called
without arguments and set the value of the member if called with
an argument. For array-like members, you need to pass a reference
to a Perl array. The one exception are arrays of type C<Char_t[]>
which are special cased to be converted to/from perl strings.
For example, given a member C<'Int_t[3] foo'>, you can set it with

  $struct->foo([1, 2, 3]);

If you added a fourth element to the array, it would be ignored. If you
pass in less elements that the struct allows for, the remaining elements
will be padded with zeroes.

The necessary type conversions are only implemented for basic types
and only for up to one level of arrays. Storing/accessing matrices
does not work.

The generated code looks something like this:

  class $yourstructname : public TObject {
    public:
    $yourfirsttype $yourfirstfield;
    ...
    ClassDef($yourstructname, 1);
  };

=head1 METHODS

=head2 new

Creates a new dynamic struct type. Required named argument:
The C<name> of the new struct type.

Optionally takes a named argument 'C<fields>'. C<fields>
can have the same forms as C<add_fields()> accepts.

=head2 add_fields

Adds more fields to the end of the struct. Can be used in one of two
forms. It accepts a single
string as argument which is parsed as a simple struct definition (just data
members). Anything up to the first C<{> and after the last C<}>
is ignored.

Alternatively, you may provide key/value pairs that indicate field names
and their types respectively. Note that with this syntax, the number of
items in a static array is part of the type:

  $struct->add_fields(foo => 'Int_t[20]');

whereas you would normally write in a C struct declaration:

  Int_t foo[20];

If that bothers you, use the first variant of C<add_fields()>.

=head2 code

Returns the code that is to be compiled with ROOT's ACLiC.

=head2 compile

Generates the C code, writes it to a file determined by the
program name and the name of the struct and compiles it with ACLiC,
so that the struct becomes available to SOOT/Perl.

=head1 SEE ALSO

L<SOOT>

L<http://root.cern.ch>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011 by Steffen Mueller

SOOT, the Perl-ROOT wrapper, is free software; you can redistribute it and/or modify
it under the same terms as ROOT itself, that is, the GNU Lesser General Public License.
A copy of the full license text is available from the distribution as the F<LICENSE> file.

=cut

