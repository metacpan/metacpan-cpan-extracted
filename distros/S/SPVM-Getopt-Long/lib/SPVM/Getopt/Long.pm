package SPVM::Getopt::Long;

our $VERSION = "0.003";

1;

=head1 Name

SPVM::Getopt::Long - Parsing Command Line Options

=head1 Description

Getopt::Long class in L<SPVM> has methods to parse command line options.

=head1 Usage

  use Getopt::Long;
  use Hash;
  
  # Default values
  my $values_h = Hash->new({
    file => "file.dat",
    length => 24,
    verbose => 0,
    numbers => new int[0],
  });
  
  my $spec_strings = [
    "file|f=s",
    "length|l=i",
    "verbose|v",
    "numbers|n=i",
  ];
  
  my $comand_args = CommandLineInfo->ARGV;
  
  my $command_args_ref = [$comand_args];
  
  Getopt::Long->GetOptionsFromArray($command_args_ref, $values_h, $spec_strings);
  
  $command_args = $command_args_ref->[0];
  
  my $file = $values_h->get_string("file");
  
  my $length = $values_h->get_int("length");
  
  my $verbose = $values_h->get_int("verbose");
  
  my $numbers = (int[])$values_h->get("numbers");

=head1 Class Methods

=head2 GetOptionsFromArray

C<static method GetOptionsFromArray : void ($args_ref : string[][], $values_h : L<Hash|SPVM::Hash>, $spec_strings : string[]);>

Parses command line options of $args_ref at index 0 according to the option specifiction $spec_strings.

Arguments starting with C<--> or C<-> is interpreted as the start of an option name.

Option names must be composed of C<0-9a-zA-Z_>.

If the option name contains C<=>, the string after C<=> is the option value, otherwise its next argument is the option value.

A new command line arguments that parsed command line arguments are removed is created and  set to $args_ref at index 0.

Option Specification Syntax (defined by yacc syntax):

  spec_string
    : option_names
    | option_names '=' type
  
  options_names
    : options_names '|' option_name
    | option_name
  
  option_name
    : \w+
  
  type
    : 's'
    | 'i'
    | 'f'

Multiple option names are available using C<|>. The first name of C<option_names> is the primary option name.

The type C<s> means the string type.

The type C<i> means the integer type.

The type C<f> means the floating point type.

If a type is not given, the type is the bool type.

If the type is string, the type of $values_h must be the string, string[], or undef type.

If the type is integer, the type of $values_h must be the Int, int[], or undef type.

If the type is floating point, the type of $values_h must be the Double, double[], or undef type.

If the type is bool, the type of $values_h must be the Int, int[], or undef type.

If the type of the value of $values_h is an array, the parsed value is pushed at the end of the value of $values_h with the primary option name.

If the type of of $values_h is not an array, the parsed value is set to the value of $values_h with the primary option name.

Option Specifiction Examples:
  
  "type=s"
  
  "length=i"
  
  "timeout=f"
  
  "length|l"

Command Line Arguments Examples:

  perl test.pl type=big --length=3 --verbose -l=6 --timeout=0.5 --numbers 3 --numbers 5

Note:

The case of option names is not ignored. C<--foo> is different from C<--FOO>.

Abbreviated names and full names are different. C<--foo> is different from C<--fo>.

The differnt order of options is differnt each other. C<--foo arg1 --bar arg2 arg3> is different from C<--foo --bar arg1 arg2 arg3>.

The C<--name=value> syntax is available. C<--foo=value> is the same as C<--foo value>.

Exceptions:

$values_h must be defined. Otherwise an exception is thrown.

If the type is not available, an exception is thrown.

$values_h must be defined. Otherwise an exception is thrown.

The option name "$name" must be given once. Otherwise an exception is thrown.

If the option specification "$spec_string" is invalid, an exception is thrown.

Each argument must be defined. Otherwise an exception is thrown.

A bool type option cannot have the value. If so, an exception is thrown.

Options other than thg bool type must must have its value. Otherwise an exception is thrown. Otherwise an exception is thrown.

The type of the option value which type is string must be the string, string[], or undef type. Otherwise an exception is thrown.

The type of the option value which type is bool must be the Int, int[], or undef type. Otherwise an exception is thrown.

The type of the option value which type is integer must be the Int, int[], or undef type. Otherwise an exception is thrown.

The type of the option value which type is floating point must be Double, double[], or undef type. Otherwise an exception is thrown.

If the option is not available, an exception is thrown.

If the option is an invalid format, an exception is thrown.

=head1 Repository

L<SPVM::Getopt::Long - Github|https://github.com/yuki-kimoto/SPVM-Getopt-Long>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

