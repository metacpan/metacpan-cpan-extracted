package Perlmazing;
use Perlmazing::Engine;
use Perlmazing::Engine::Exporter;
use Perlmazing::Feature;
use Win32::Symlinks;
use List::Util qw(
  reduce any all none notall first reductions
  max maxstr min minstr product sum sum0
  pairs unpairs pairkeys pairvalues pairfirst pairgrep pairmap
  uniq uniqint uniqnum uniqstr head tail zip mesh
);
our $VERSION = '2.0016';
our @found_symbols = Perlmazing::Engine->found_symbols;
our %EXPORT_TAGS = (
  all => \@found_symbols,
  default => [qw(pl dumped define time localtime gmtime mkdir rmdir sleep stat )],
  context => [qw(list_context no_void scalar_context void_context )],
  crypt => [qw(aes_decrypt aes_encrypt md5 md5_file )],
  error => [qw(carp cluck confess croak longmess shortmess )],
  file => [qw(abs2rel basename catdir catfile catpath copy cwd devnull dir dirname empty_dir fout move rel2abs slurp splitdir splitpath unix_path windows_path )],
  object => [qw(find_parent_classes flatten is_array is_blessed is_code is_filehandle is_format is_glob is_hash is_io is_lvalue is_ref is_regexp is_scalar is_vstring isa_array isa_code isa_filehandle isa_format isa_glob isa_hash isa_io isa_lvalue isa_ref isa_regexp isa_scalar isa_vstring unbless )],
  string => [qw(commify escape_html escape_quote escape_quotes escape_uri eval_string is_email_address is_empty is_integer is_number is_utf8 not_empty numeric replace_accented_characters to_number to_string to_utf8 trim truncate_text unescape_html unescape_uri )],
  time => [qw(get_time_from gmtime_hashref is_leap_year is_valid_date time_hashref timegm timelocal localtime_ts gmtime_ts)],
  variable => [qw(columnize in_array merge remove_duplicates shuffle sort_by_key sort_by_value taint tainted untaint)],
  number => [qw(avg ceil decimals is_integer min max)],
  list => [qw(all any avg columnize first head max maxstr mesh min minstr none notall pairfirst pairgrep pairkeys pairmap pairs pairvalues product reduce reductions shuffle sum sum0 tail uniq uniqint uniqnum uniqstr unpairs zip)],
);

# Renaming key for consistency. Leaving this as a backwards compatibility thing.
$EXPORT_TAGS{variables} = $EXPORT_TAGS{variable};

our @EXPORT = @{$EXPORT_TAGS{default}};

Perlmazing::Engine->precompile;

Perlmazing::Engine->preload(
  qw(
  
  )
);

no warnings 'redefine';
sub import {
  my $self = shift;
  my @call = caller;
  Perlmazing::Feature->import;
  warnings->import(FATAL => qw(closed unopened numeric recursion syntax uninitialized));
  $self->SUPER::import(@_);
}

1;

__END__

=head1 NAME

Perlmazing - A collection of helper functions powered by Perlmazing::Engine.

=head1 SYNOPSIS

This module is the first practical example of a module powered by L<Perlmazing::Engine>. It's a collection of helper functions
that are loaded only when actually used, making it extremely fast to load and efficient to run. This manual will show you
how to use this module and what its helper functions do, but you should look at L<Perlmazing::Engine> to understand how it's
being used and maybe look at the source code of this module to see how simple it was to implement L<Perlmazing::Engine> for
this example.

As an additional benefit, this module automatically C<use>s and C<import>s L<Perlmazing::Feature>, which basically will
enable C<strict> and C<warnings FATAL => qw(closed unopened numeric recursion syntax uninitialized)>, along with the most recent features your version of Perl can enable.

Currently, the maximum version features we enable here is 5.028, as some of the later versions of Perl have features that can cause unexpected compatibility problems.
You can set the value of $Perlmazing::Feature::VERSION to $] or to any other limit if you want.

How this module works at the end:

  use Perlmazing; # or use Perlmazing qw(function1 function2 ...);
  
  # First of all, Perlmazing::Feature is automatically imported,
  # so warnings and strict are automatically enabled and also
  # any features that your version of Perl can have (similar to
  # "use $]" (maxed to 5.028), if only that was a valid call)
  
  # Please read on the next section to learn about exported symbols.
    

=head1 EXPORT

In the case of this module, all documented functions are exported by default in versions previous to v2.
Beginning with v2, only 'pl', 'dumped', 'define' are default now. Also, any function that matches a CORE
function name (specifically: time, localtime, gmtime, mkdir, rmdir, sleep and stat).

These implicitly imported funcions are set in the export tag :default. If you don't want any of the default
functions imported, then you have two options:

  # Call Perlmazing without any imports eanbled:
  use Perlmazing qw();
  
  # Or call the default tag like this:
  use Perlmazing qw( !:default );
  
  # Which enables you to specify only certain functions from the default tag without the rest:
  use Perlmazing qw( pl time !:default );
  
  # Keep in mind that the order takes precedence. If you first say no to something and later yes, "no" will win.
  use Perlmazing qw( !:default pl time ); # Won't work as pl and time are part of :default

You have these export tags available for convenience (since version 2.008):

:default

  define, dumped, gmtime, localtime, mkdir, pl, rmdir, sleep, stat, time

:all

  _is_ref, _isa_ref, abs2rel, abs_path, aes_decrypt, aes_encrypt, basename, carp, catdir, catfile, catpath, cluck, commify, confess, copy, croak, cwd, define, devnull, dir, dirname, dumped, empty_dir, escape_html, escape_quote, escape_quotes, escape_uri, eval_string, find_parent_classes, fout, get_aes_cipher, get_time_from, gmtime, gmtime_hashref, in_array, is_array, is_blessed, is_code, is_email_address, is_empty, is_filehandle, is_format, is_glob, is_hash, is_io, is_leap_year, is_lvalue, is_number, is_ref, is_regexp, is_scalar, is_utf8, is_valid_date, is_vstring, isa_array, isa_code, isa_filehandle, isa_format, isa_glob, isa_hash, isa_io, isa_lvalue, isa_ref, isa_regexp, isa_scalar, isa_vstring, list_context, localtime, longmess, md5, md5_file, merge, mkdir, move, no_void, not_empty, numeric, pl, rel2abs, remove_duplicates, replace_accented_characters, rmdir, scalar_context, shortmess, shuffle, sleep, slurp, sort_by_key, sort_by_value, splitdir, splitpath, stat, taint, tainted, time, time_hashref, timegm, timelocal, to_number, to_string, to_utf8, trim, truncate_text, unescape_html, unescape_uri, untaint, unweaken, void_context, weaken

:context

  list_context, no_void, scalar_context, void_context

:crypt

  aes_decrypt, aes_encrypt, md5, md5_file

:error

  carp, cluck, confess, croak, longmess, shortmess

:file

  abs2rel, basename, catdir, catfile, catpath, copy, cwd, devnull, dir, dirname, empty_dir, fout, move, rel2abs, slurp, splitdir, splitpath, unix_path, windows_path

:object

  find_parent_classes, flatten, is_array, is_blessed, is_code, is_filehandle, is_format, is_glob, is_hash, is_io, is_lvalue, is_ref, is_regexp, is_scalar, is_vstring, isa_array, isa_code, isa_filehandle, isa_format, isa_glob, isa_hash, isa_io, isa_lvalue, isa_ref, isa_regexp, isa_scalar, isa_vstring, unbless

:string

  commify, escape_html, escape_quote, escape_quotes, escape_uri, eval_string, is_email_address, is_empty, is_integer, is_number, is_utf8, not_empty, numeric, replace_accented_characters, to_number, to_string, to_utf8, trim, truncate_text, unescape_html, unescape_uri

:time

  get_time_from, gmtime_hashref, gmtime_ts, is_leap_year, is_valid_date, localtime_ts, time_hashref, timegm, timelocal

:variable (with the alias :variables, kept for backwards compatibility)

  columnize, in_array, merge, remove_duplicates, shuffle, sort_by_key, sort_by_value, taint, tainted, untaint

:number
  avg, ceil, decimals, is_integer, min, max

:list
  all, any, avg, columnize, first, head, max, maxstr, mesh, min, minstr, none, notall, pairfirst, pairgrep, pairkeys, pairmap, pairs, pairvalues, product, reduce, reductions, shuffle, sum, sum0, tail, uniq, uniqint, uniqnum, uniqstr, unpairs, zip

All this doesn't mean you have to work like that in your own module when using L<Perlmazing::Engine>. It also doesn't mean
that those functions are actually loaded into memory, they are just available to the caller and will
be loaded and processed as soon as the caller actually calls one of them. Please read the documentation
of L<Perlmazing::Engine> to learn more about it.


=head1 FUNCTIONS

There are two types of functions in terms of behavior and this is something comming from L<Perlmazing::Engine>.
Basically, you get the regular type and the C<Listable> type. The regular type is simply any kind of subroutine,
and it can simply do whatever you code it to do.

In the other hand, C<Listable> functions are all meant to have the same behavior as described in
L<Perlmazing::Engine Listable functions|Perlmazing::Engine/LISTABLE FUNCTIONS> and this should be warranted by
L<Perlmazing::Engine>'s own code. These functions can, of course, do whatever you code them to do too, but they
are all meant to follow this behavior:

  # Assume 'my_sub' is a function of the type Listable:
  
  # Calling my_sub on an array will directly affect elements of @array:
  
  my_sub @array;
  
  # Calling my_sub on a list will *attempt* to directly affect the
  # elements of that list, failing on 'read only'/'constant' elements
  # like the elements in the following list:
  
  my_sub (1, 2, 3, 4, 5, 'string element');
  
  # Calling my_sub on an array or a list BUT with an assignment,
  # will *not* affect the original array or list, but assign an
  # affected copy:
  
  my @array_A = my_sub @array;
  my @array_B = my_sub (1, 2, 3, 4, 5, 'string_element');
  
  # Listable functions can be chained to achieve both behaviors
  # (assignment or direct effect) on a single call. Assume
  # 'my_sub2', 'my_sub3' and 'my_sub4' are also Listable functions:
  
  my_sub my_sub1 my_sub2 my_sub3 my_sub4 @array;
  my @array_C = my_sub my_sub1 my_sub2 my_sub3 my_sub4 (1, 2, 3, 4, 5, 'string element');
  
  # When a Listable function is assigned in scalar context, then only the
  # first element is assigned, not a list/array count.
  
  my $scalar = my_sub @array; # $scalar contains the first element of the resulting list
    
In the following list of functions, each function will be documented by describing what it does and
specifying C<Listable> functions, in which case you now know how you can use them to take advantage
of that.

  # Get list of current Perlmazing functions and its type:

  for my $i (@Perlmazing::EXPORT) {
    Perlmazing::Engine::_load_symbol('Perlmazing', $i);
    my $is_listable = "Perlmazing::Perlmazing::$i"->isa('Perlmazing::Listable') ? '(listable)' : '';
    pl "$i $is_listable";
  }


=head2 abs2rel

Same as L<File::Spec-E<gt>abs2rel()|File::Spec>. Just much more readable and easier/shorter to type.


=head2 aes_decrypt

C<aes_decrypt($encrypted_data, $key)>

Equivalent to MySQL's AES_DECRYPT function, 100% compatible with MySQL. Returns unencrypted data if successful.


=head2 aes_encrypt

C<aes_encrypt($plain_data, $key)>

Equivalent to MySQL's AES_ENCRYPT function, 100% compatible with MySQL. Returns encrypted (binary) data.


=head2 avg

C<avg(@numbers)>

It returns the average value of the numbers in a given list or array. If any of the values is not a number, it will become zero in the calculation of the average.


=head2 all

Same as L<List::Util::all|List::Util>.


=head2 any

Same as L<List::Util::any|List::Util>.


=head2 basename

I<Listable function>

Same as L<File::Basename::basename()|File::Basename>, but it is a listable function.

  use Perlmazing qw(basename);
  
  my @paths = ($path_to_file_1, $path_to_file_2, $path_to_file_3);
  
  # Alter all items in @paths to become just file names:
  basename @file_names;


=head2 carp

Same as L<Carp::carp()|Carp>.


=head2 catdir

Same as L<File::Spec-E<gt>catdir()|File::Spec>. Just much more readable and easier/shorter to type.


=head2 catfile

Same as L<File::Spec-E<gt>catfile()|File::Spec>. Just much more readable and easier/shorter to type.


=head2 catpath

Same as L<File::Spec-E<gt>catpath()|File::Spec>. Just much more readable and easier/shorter to type.


=head2 ceil

C<ceil($number)>

I<Listable function>

A way to round up a number (or a list of numbers). This is almost the same as L<POSIX::ceil()|POSIX>, except it's a listable function and it will keep non numeric values intact.


=head2 cluck

Same as L<Carp::cluck()|Carp>.


=head2 columnize

C<my @rows = columnize($number_of_columns, @list)>

This function sorts the elements in a given array or list as elements that follow their order vertically for a given number of columns.

For example, you could normally/easily follow the order horizontally:

  use Perlmazing;
  
  my @array = (1..9);
  my $number_of_columns = 3;
  
  while (@array) {
    my @row = splice @array, 0, $number_of_columns;
    pl "@row";
  }
  
  # This would print:
  #
  # 1 2 3
  # 4 5 6
  # 7 8 9
  
But with columnize, which requires a bit more complex logic, you can have this:

  use Perlmazing qw(columnize);
  
  my @array = (1..9);
  my $number_of_columns = 3;
  
  my @rows = columnize $number_of_columns, @array;
  
  for my $row (@rows) {
    pl "@$row";
  }
  
  # This would print:
  #
  # 1 4 7
  # 2 5 8
  # 3 6 9
  
The reason each "row" is an arrayref, is that this is the only way you can know whether the original array contained an C<undef> element, or the original array had ran out of elements by then.
Meaning, if you asked for 3 columns, and while getting your rows you start seeing arrayrefs of 2 elements instead of 3 elements, it's because the original list ended by then. For example, with a list that won't fit all places in a table:

  use Perlmazing qw(columnize);
  
  my @array = (1..7);
  my $number_of_columns = 3;
  
  my @rows = columnize $number_of_columns, @array;
  
  for my $row (@rows) {
    pl "@$row";
  }
  
  # This would print:
  #
  # 1 4 7
  # 2 5
  # 3 6

You can see how the second and third row couldn't have a value for the third column because the original list was 1..7 only and, when ordering vertically, this is the only way to fit places. Thanks to the arrayrefs, you can know if those places are empty because the original array had undefined elements (when the arrayref has the same amount of elements as requested columns), or those places are empty because by then the original array had no more elements in it (when the arrayref has one element less than the requested number of columns).

=head2 commify

C<my @result = commify(@values)>
C<commify(@values)>

I<Listable function>

This function will format any received number into a grouped by comma number. It uses the US format (e.g. 123,456.78). If you need a different locale, look at L<CLDR::Number>,
which is the module this function is using with a fixed locale - except C<commify> handles more cases than just numbers, contrary to L<CLDR::Number>.

In the received values, any existing grouping (even broken grouping) will be removed and changed into the right grouping. Also, decimal numbers will be left alone as
they are received (e.g. 1234.00 will become 1,234.00 and 1234.001230 will become 1,234.001230). This behavior is intentional to help with any numbers you may preformat
with C<sprintf>, like money values or any other values that you are puposedly setting to a specific number of decimals before applying grouping commas.

This is a listable function, so any of the following examples will work:

  use Perlmazing qw(commify);
  
  my @numbers = qw(
    123
    12345
    1234.56
    -90120
    Not_a_number
  );
  # More extreme cases:
  push @numbers, (
    '123,,456.01',
    '12,34,56',
    '12,,3,4,5.010',
    '123.456.789',
  );
  
  pl @numbers;
  # Output:
  # 123
  # 12345
  # 1234.56
  # -90120
  # Not_a_number
  # 123,,456.01
  # 12,34,56
  # 12,,3,4,5.010
  # 123.456.789
  
  pl commify @numbers;
  # Output:
  # 123
  # 12,345
  # 1,234.56
  # -90,120
  # Not_a_number
  # 123,456.01
  # 123,456
  # 12,345.010
  # 123.456.789
  
  my @copy = commify @numbers;
  pl @copy;
  # Output: Same as "pl commify @numbers". @numbers remains unchanged.
  
  # Directly affect the elements of @numbers
  commify @numbers;
  pl @numbers;
  # Output: Same as "pl commify @numbers", but this time all values in @numbers where changed.


=head2 confess

Same as L<Carp::confess()|Carp>.


=head2 copy

Same as L<File::Copy::Recursive::rcopy()|File::Copy::Recursive>. Copies a file using the native OS file-copy implementation. Not to be confused
with Perl's C<link>, which doesn't create an actual copy. It will recursively copy directories when passed as argument.


=head2 croak

Same as L<Carp::croak()|Carp>.


=head2 cwd 

Same as L<Cwd::cwd()>. Returns the current working directory.


=head2 define

I<Listable function>

Converts any undefined element into an empty string. Useful when purposely avoiding warnings on certain operations.

  use Perlmazing qw(define);
  my @array = (1, 2, 3, undef, undef, 6);
  
  define @array;
  # Now @array = (1, 2, 3, '', '', 6);
  
  sub my_sub {
    for my $i (define @_) {
      # None of the following will cause an 'undefined' warning:
      print "Received argument $i\n";
      $i =~ s/\d//;
      $i = 1 if $i eq 'abc';
    }
  }
    

=head2 decimals

C<my $decimals = decimals($number)>

Returns the decimals part of a given number. Example:

  use Perlmazing qw(decimals);
  
  my $number = 1.45;
  
  pl decimals $number;
  # Will print 0.45


=head2 devnull

Same as L<File::Spec-E<gt>devnull()|File::Spec>. Just much more readable and easier/shorter to type.


=head2 dir

C<dir>

C<dir($path)>

C<dir($path, $recursive)>

C<dir($path, $recursive, $callback)>

This function will return an array with the contents of the directory given in C<$path>. If C<$path> is omited,
then the current working directory is used. C<$recursive> is a boolean value, is optional and defaults to 0.
When true, then the contents of subdirectories are returned too. C<$callback> is also optional and must be a coderef.
If provided, then it will be called on each element found in real time. It receives the current element as argument.


=head2 dirname

I<Listable function>

Same as L<File::Basename::dirname()|File::Basename>, but it is a listable function.

  use Perlmazing qw(dirname);
  my @dirs = ($path_to_file_1, $path_to_file_2, $path_to_file_3);
  
  my @files = ($path_to_file_1, $path_to_file_2, $path_to_file_3);
  # Alter all in @files to become just directory names:
  dirname @files;

    

=head2 dumped

Same as L<Data::Dump::dump()|Data::Dump>. It will return a code dump of whatever you provide as argument.

For example:

  print dumped @array;
  print dumped \@array; # Maybe better
  print dumped \%hash;
  print dumped $some_object;


=head2 empty_dir

C<empty_dir($path)>

This is almost the same as L<File::Path::remove_tree()|File::Path>, except it will make the folder provided in C<$path>
empty without removing C<$path> too.


=head2 escape_html

I<Listable function>

This function will html-escape any characters that are special to HTML. For example, it will replace C<&> with C<&amp;> or
C<< < >> with C<&lt;>. It is a I<Listable function>.

Examples:

  use Perlmazing qw(escape_html);
  
  print escape_html $some_text;
    
  escape_html @array_A;
    
  my @array_B = escape_html @array_C;
    

=head2 escape_quote

C<escape_quote($value)>

C<escape_quote(@values)>

C<my @result = escape_quote(@values)>

I<Listable function>

This is a very simple function that escapes with a backslash any match of the symbol C<'>. Works as any other I<listable> function from this module.



=head2 escape_quotes

Exactly the Same as L<escape_quote|Perlmazing/escape_quote>, except it escapes the symbol C<"> instead of the symbol C<'>.


=head2 escape_uri

I<Listable function>

This function will uri-escape any characters that are special to an URI. For example, it will replace C<&> with C<%26> or
C<=> with C<%3D>. It is a I<Listable function>.

Examples:

  use Perlmazing qw(escape_uri);
  
  my $url = 'https://www.google.com.mx/search?q=';
  my $query = escape_uri 'how are &, < and > escaped in html';
  my $final_url = $url.$query;
  
  my @escaped_queries = escape_uri @queries;
  
  escape_uri @queries;

See also L<unescape_uri|Perlmazing/unescape_uri>.


=head2 eval_string

C<eval_string($string_with_perl_code)>

This function acts exactly like native C<eval> - except it shows you the file and line number on errors captured in C<$@>,
in addition to the regular uninformative and unhelpful C<...error at (eval n)> message that the native C<eval> sets.

=head2 find_parent_classes

C<find_parent_classes($object)>

This function will return an array containing all classes for which $object I<isa>, in order of precedence. It basically
walks through all namespaces found in its own C<@ISA>, and then recursively on each C<@ISA> for all found namespaces.

For example, the following code:

  use Perlmazing qw(find_parent_classes);
  use WWW::Mechanize;

  my $mec = WWW::Mechanize->new;
  my @classes = find_parent_classes $mec;
  
  say for @classes;

will print something like:

  WWW::Mechanize
  LWP::UserAgent
  LWP::MemberMixin
  UNIVERSAL

=head2 flatten

C<flatten(@array_with_nested_structures)>

This function makes a flat array out of a list or array containing scalars, arrayrefs, hashrefs, objects (even nested ones).

For example:

  use Perlmazing qw(flatten);
  
  my @list = ([ 1, [ 2, 3 ], [[[4]]], 5, [6], [[7]], [[8,9]], {10 => [11, 12], 13 => {14 => 15}});
  
  my @flat = flatten @list;
  
  # @flat is now = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)


=head2 fout

C<fout($filename, $data)>
C<fout($filename, $data, $binmode)>
C<fout($filename, $data, $encoding)>

This function is the opposite of L<slurp|Perlmazing/slurp>. It's just a fast, practical way to write content to a file. If the third argument equals 1, it means to write the file with binmode enabled. If the value of that third argument is true and different to 1, then it's taken as a valid encoding name to be used while writting to the file.

  use Perlmazing qw(fout);
  
  my $data = 'Some data';
  my $filename = 'file.txt';
  
  # This would write $data to $filename:
  fout $filename, $data;
  
  # This would do the same with binmode enabled:
  fout $filename, $data, 1;
  
  # This would do the same, but with utf8 encoding enabled:
  fout $filename, $data, 'utf8';


=head2 first

Same as L<List::Util::first|List::Util>.


=head2 get_time_from

C<get_time_from(year => $year, month => $month, day => $day)>

Same as L<Time::Precise::get_time_from()|Time::Precise/get_time_from>. Returns time in seconds including nanoseconds.


=head2 gmtime

Same as L<Time::Precise::gmtime()|Time::Precise/gmtime>. Returns time in seconds including nanoseconds.


=head2 gmtime_ts

Same as L<Time::Precise::gmtime_ts()|Time::Precise/gmtime_ts>. Works as C<gmtime>, except it returns a timestamp SQL style (e.g. C<2024-11-27 20:50:30>).


=head2 gmtime_hashref

Same as L<Time::Precise::gmtime_hashref()|Time::Precise/gmtime_hashref>. Returns a hashref with current datetime elements.


=head2 head

Same as L<List::Util::head|List::Util>.


=head2 in_array

C<in_array(@array, $something_to_find)>

This function will tell you if C<@array> contains an element identical to C<$something_to_find>. If found, it will return
the index number for that element. For effective boolean effect, it will return the string C<00> when the index is actually
C<0>. So, the following is a safe case:

  use Perlmazing qw(in_array);
  
  my @array = ('first', 'second', 'third');
    
  if (my $index = in_array @array, 'first') {
    print "Found $array[$index]";
  }


=head2 is_array

C<is_array($object)>

Returns true if C<$object> is a pure arrayref. See also L<isa_array|Perlmazing/isa_array>.


=head2 is_blessed

C<is_blessed($object)>

Same as L<Scalar::Util::blessed()|Scalar::Util>. Returns the name of the package C<$object> is a blessed into, if blessed.


=head2 is_code

C<is_code($object)>

Returns true if C<$object> is a pure coderef. See also L<isa_code|Perlmazing/isa_code>.


=head2 is_email_address

C<is_email_address($string)>

Formed by a very complex, fast, RFC compliant regex that effectively validates any email address. Returns true is valid.


=head2 is_empty

C<is_empty($value)>

Returns true if $value is equal en an empty string (C<''>) or $value is undefined.


=head2 is_filehandle

C<is_filehandle($value)>

Returns true if $value is a valid filehandle.


=head2 is_format

C<is_format($object)>

Returns true if C<$object> is a pure formatref. See also L<isa_format|Perlmazing/isa_format>.


=head2 is_glob

C<is_glob($object)>

Returns true if C<$object> is a pure globref. See also L<isa_glob|Perlmazing/isa_glob>.


=head2 is_hash

C<is_hash($object)>

Returns true if C<$object> is a pure hashref. See also L<isa_hash|Perlmazing/isa_hash>.


=head2 is_integer

C<is_integer($value)>

Returns true only is the provided value is a number and it's an integer (and not a floating point number).


=head2 is_io

C<is_io($object)>

Returns true if C<$object> is a pure ioref. See also L<isa_io|Perlmazing/isa_io>.


=head2 is_leap_year

C<is_leap_year($year)>

Same as L<Time::Precise::is_leap_year()|Time::Precise/is_leap_year>. Returns true if C<$year> is a leap year.


=head2 is_lvalue

C<is_lvalue($object)>

Returns true if C<$object> is a pure lvalueref. See also L<isa_lvalue|Perlmazing/isa_lvalue>.


=head2 is_number

C<is_number($value)>

Returns true if $value can be interpreted as a number. It is intended to work with any kind of expresion that Perl
would take as a number if it was actual code, meaning that if it is a valid numeric expresion (whatever format) to
Perl, then this function should return true too.


=head2 is_ref

C<is_ref($object)>

Returns true if C<$object> is a pure refref. See also L<isa_ref|Perlmazing/isa_ref>.


=head2 is_regexp

C<is_regexp($object)>

Returns true if C<$object> is a pure regexpref. See also L<isa_regexp|Perlmazing/isa_regexp>.


=head2 is_scalar

C<is_scalar($object)>

Returns true if C<$object> is a pure scalarref. See also L<isa_scalar|Perlmazing/isa_scalar>.


=head2 is_utf8

C<is_utf8($string)>

Returns true if C<$string> has valid UTF8 encodings. Basically, if C<Encode::decode('utf8', $str, Encode::FB_CROAK)> doesn't
throw an error and only if the resulting value is different from $string, it will return true.


=head2 is_valid_date

C<is_valid_date($year, $month, $day)>

Same as L<Time::Precise::is_valid_date()|Time::Precise/is_valid_date>. Returns true if the values passed for C<$year>, C<$month> and C<$day> form together a valid date.


=head2 is_vstring

C<is_vstring($object)>

Returns true if C<$object> is a pure vstringref. See also L<isa_vstring|Perlmazing/isa_vstring>.


=head2 isa_array

C<isa_array($object)>

Works just like L<is_array|Perlmazing/is_array>, except it will return true even if the reference is not pure
(e.g. it's blessed into something).


=head2 isa_code

C<isa_code($object)>

Works just like L<is_code|Perlmazing/is_code>, except it will return true even if the reference is not pure
(e.g. it's blessed into something).


=head2 isa_filehandle

C<isa_filehandle($object)>

Works just like L<is_filehandle|Perlmazing/is_filehandle>, except it will return true even if the reference is not pure
(e.g. it's blessed into something).


=head2 isa_format

C<isa_format($object)>

Works just like L<is_format|Perlmazing/is_format>, except it will return true even if the reference is not pure
(e.g. it's blessed into something).


=head2 isa_glob

C<isa_glob($object)>

Works just like L<is_glob|Perlmazing/is_glob>, except it will return true even if the reference is not pure
(e.g. it's blessed into something).


=head2 isa_hash

C<isa_hash($object)>

Works just like L<is_hash|Perlmazing/is_hash>, except it will return true even if the reference is not pure
(e.g. it's blessed into something).


=head2 isa_io

C<isa_io($object)>

Works just like L<is_io|Perlmazing/is_io>, except it will return true even if the reference is not pure
(e.g. it's blessed into something).


=head2 isa_lvalue

C<isa_lvalue($object)>

Works just like L<is_lvalue|Perlmazing/is_lvalue>, except it will return true even if the reference is not pure
(e.g. it's blessed into something).


=head2 isa_ref

C<isa_ref($object)>

Works just like L<is_ref|Perlmazing/is_ref>, except it will return true even if the reference is not pure
(e.g. it's blessed into something).


=head2 isa_regexp

C<isa_regexp($object)>

Works just like L<is_regexp|Perlmazing/is_regexp>, except it will return true even if the reference is not pure
(e.g. it's blessed into something).


=head2 isa_scalar

C<isa_scalar($object)>

Works just like L<is_scalar|Perlmazing/is_scalar>, except it will return true even if the reference is not pure
(e.g. it's blessed into something).


=head2 isa_vstring

C<isa_vstring($object)>

Works just like L<is_vstring|Perlmazing/is_vstring>, except it will return true even if the reference is not pure
(e.g. it's blessed into something).


=head2 list_context

C<list_context()>

This function is meant to be called inside of a subroutine. It will return true if the subroutine was called in list context.
See also L<void_context|Perlmazing/void_context> and L<scalar_context|Perlmazing/scalar_context>.


=head2 localtime

Same as L<Time::Precise::localtime()|Time::Precise/localtime>. Works as the core C<localtime>, except it returns nanoseconds
and full year too.


=head2 localtime_ts

Same as L<Time::Precise::localtime_ts()|Time::Precise/localtime_ts>. Works as C<localtime>, except it returns a timestamp SQL style (e.g. C<2024-11-27 20:50:30>).


=head2 longmess

Same as L<Carp::longmess()|Carp>.


=head2 max

Same as L<List::Util::max|List::Util>.


=head2 maxstr

Same as L<List::Util::maxstr|List::Util>.


=head2 md5

C<md5($value)>

C<md5(@values)>

C<my @result = md5(@values)>

I<Listable function>

This function returns the I<md5> representation (in hexadecimal) of the passed value(s). It will work as any other I<Listable>
function from this module.


=head2 md5_file

C<md5_file($path_to_file)>

C<md5_file($file_handle)>

This function will take a C<$path_to_file> or directly a C<$file_handle>, read the contents of the file in binary mode and
return the I<md5> representation (in hexadecimal) of that file's contents.


=head2 merge

C<merge(%hash, key1 => $value1, key2 => $value2, ...)>

This function is to a hash what C<push> is to an array. It will allow you to add as many keys as you want to an existing hash
without having to create an splice or having to use the name of the hash for each assignment. If keys are repeated or existent,
the last used one will be the one remaining. For example:

  use Perlmazing qw(merge);
  
  my %hash = (
    name        => 'Francisco',
    lastname    => 'Zarabozo',
    age         => 'Unknown',
    email       => undef,
  );
  
  merge %hash, (
    age     => 20,
    age     => 30,
    age     => 40,
    email   => 'zarabozo@cpan.org',
    gender  => 'male',
    pet     => 'dog',
  );
  
  # Now %hash contains the following:
  
  %hash = (
    age         => 40, # Last one used
    email       => 'zarabozo@cpan.org',
    gender      => 'male',
    lastname    => 'Zarabozo',
    name        => 'Francisco',
    pet         => 'dog',
  );


=head2 mesh

Same as L<List::Util::mesh|List::Util>.


=head2 min

Same as L<List::Util::min|List::Util>.


=head2 minstr

Same as L<List::Util::minstr|List::Util>.


=head2 mkdir

Works just like Perl's core C<mkdir>, except it will use L<File::Path::make_path()|File::Path> to create any missing directories in the requested path. It will return a list with the directories that were actually created.


=head2 move

Same as L<File::Copy::Recursive::rmove()|File::Copy::Recursive>. Moves a file using the native OS file-copy implementation. It will recursively move directories when passed as argument.


=head2 none

Same as L<List::Util::none|List::Util>.


=head2 notall

Same as L<List::Util::notall|List::Util>.


=head2 no_void

This function is meant to be called from inside a subroutine. The purpose of it is to break the execution of that subroutine and immediatly return with a warning if that subroutine was called in void context. This is useful
when a certain function will do some time or memory consuming operations in order to return the result of those operations, which would be all for nothing if that function was called in void context. For example:

  use Perlmazing qw(no_void);
  
  # This will execute and will take a second to return
  my $result = some_function();
  say "Result is $result";
  
  # Don't even bother, this will return immediatly without executing anything. Also a warning is issued:
  # Useless call to main::some_function in void context at file.pl line 9.
  some_function();
  
  sub some_function {
    no_void;
    sleep 1; # Some time consuming operation;
    return time;
  }


=head2 not_empty 

C<not_empty($var)>

This is just an idiomatic way to test if a scalar value is something other than C<undef> or an empty string (''). It avoids warnings when using an undefined value in C<eq ''>. You would use it like this:

  use Perlmazing qw(not_empty);
  
  my $values = {
    undefined   => undef,
    empty       => '',
    filled      => 'Hello!';
  }
  
  for my $key (keys %$values) {
    if (not_empty $values->{$key}) {
      say "Key $key conatins $values->{$key}";
    }
  }
  
  # Only key 'filled' will get to say "Key filled contains Hello!"


=head2 numeric

C<sort numeric @something>

This function is written to be used in conjuntion with C<sort>. It will sort values numerically when that's possible, numbers before strings and strings before undefined values. Example:

  use Perlmazing qw(numeric);
  
  my @values = qw(
    3
    8
    2
    0
    1
    3
    7
    5
    bee
    4
    ark
    9
    code
    6
    20
    10
    123string
    100
    1000
    1001
    001000
  );
  
  @values = sort numeric @values;
  
  # Now @values looks like this:
  # 0, 1, 2, 3, 3, 4, 5, 6, 7, 8, 9, 10, 20, 100, 123string, 1000, 001000, 1001, ark, bee, code
  
  # Without 'numeric' it would have been sorted like this:
  # 0, 001000, 1, 10, 100, 1000, 1001, 123string, 2, 20, 3, 3, 4, 5, 6, 7, 8, 9, ark, bee, code
    
This sort order will also work for mixed cases between numeric and non-numeric cases. For example:
    
  use Perlmazing qw(numeric);
  
  my @values = qw(
    book_1_page_3
    book_1_page_1
    book_1_page_2
    book_1_page_03
    book_1_page_01
    book_1_page_02
    book_01_page_3
    book_01_page_1
    book_01_page_2
    book_10_page_3
    book_10_page_3z
    book_10_page_3a
    book_10_page_3k
    book_010_page_1
    book_0010_page_2
  );
  
  @values = sort numeric @values;
  
  # Now @values looks like this:
  # book_01_page_1
  # book_1_page_01
  # book_1_page_1
  # book_01_page_2
  # book_1_page_02
  # book_1_page_2
  # book_01_page_3
  # book_1_page_03
  # book_1_page_3
  # book_010_page_1
  # book_0010_page_2
  # book_10_page_3
  # book_10_page_3a
  # book_10_page_3k
  # book_10_page_3z
  
  # Without 'numeric' it would have been sorted like this:
  # book_0010_page_2
  # book_010_page_1
  # book_01_page_1
  # book_01_page_2
  # book_01_page_3
  # book_10_page_3
  # book_10_page_3a
  # book_10_page_3k
  # book_10_page_3z
  # book_1_page_01
  # book_1_page_02
  # book_1_page_03
  # book_1_page_1
  # book_1_page_2
  # book_1_page_3


=head2 pairs

Same as L<List::Util::pairs|List::Util>.


=head2 pairkeys

Same as L<List::Util::pairkeys|List::Util>.


=head2 pairvalues

Same as L<List::Util::pairvalues|List::Util>.


=head2 pairfirst

Same as L<List::Util::pairfirst|List::Util>.


=head2 pairgrep

Same as L<List::Util::pairgrep|List::Util>.


=head2 pairmap

Same as L<List::Util::pairmap|List::Util>.


=head2 pl

C<pl "something">

C<pl "more", "something else">

C<pl @anything>

This function's name is short for "print lines". It was written way before core C<say> was announced and released. It was kept because it's not precisely the same as C<say> and I still find it much more useful.

It will print on separate lines everything that it receives as an argument - EXCEPT if you are assigning the return value of it to something else: in that case it will not print anything and will return
a string containing what it would have printed. If assigning in list context, then an element for each line including a trailing "\n" on each one.

Examples:

  use Perlmazing;
  
  my @arr = (1..10);
  
  pl "Hello world!";
  # prints a "Hello world!" followed by a "\n"
  
  pl @arr;
  # Will print this:
  # 1
  # 2
  # 3
  # 4
  # 5
  # 6
  # 7
  # 8
  # 9
  # 10
  
  my $r = pl @arr;
  # Same, but it will ASSIGN to $r the output instead of printing it
  
  my @r = pl @arr;
  # An element in @r is created for each line that would be printed, including a trailing "\n" in each element


=head2 product

Same as L<List::Util::product|List::Util>.


=head2 reduce

Same as L<List::Util::reduce|List::Util>.


=head2 reductions

Same as L<List::Util::reductions|List::Util>.


=head2 rel2abs

Same as L<File::Spec-E<gt>rel2abs()|File::Spec>. Just much more readable and easier/shorter to type.


=head2 remove_duplicates

C<remove_duplicates(@array)>

A very useful function that will remove dumplicate entries from an array. The behavior and return value will be different according to whether it was called in void, scalar or list context. Look at these examples:

  use Perlmazing qw(remove_duplicates);
  
  my @values = qw(
    1 2 3 4 5 6 7
        3 4 5 6 7 8 9
            5 6 7 8 9 10 11
        3 4 5 6 7 8 9
    1 2 3 4 5 6 7
  );
  
  # Try scalar context:
  my $scalar = remove_duplicates @values;
  # $scalar now contains the number of found duplicates (24) and nothing else is affected.
  
  # Try list context:
  my @list = remove_duplicates @values;
  # Now @list contains a copy of @values WITHOUT duplicates (so it's now 1..11). @values remains untouched.
  
  # Try void context:
  remove_duplicates @values;
  # You guessed. @values now has no duplicates (so it's now 1..11).

This function requires an array as argument, and not a list, because of its ability to replace an array in-place when called in void context like in the last example. It also gives you the number of duplicate elements in scalar context, like in the corresponding example. But, if you don't need in-place replacement, or you don't need the amount of duplicate elements, or you want to pass a list as argument, then you should use L<uniq|Perlmazing/uniq> instead, which as a given bonus, is written in C and has better performance.


=head2 replace_accented_characters

C<replace_accented_characters($value)>

C<replace_accented_characters(@values)>

C<my @result = replace_accented_characters(@values)>

I<Listable function>

This function replaces any accented character (such as accented vowels in spanish) with it's closest representation in standard english alphabeth. For example, the character C<E<aacute>> is replaced with a simple C<a>,
or the character C<E<uuml>> is replaced with a simple C<u>. It works as any other I<listable> function from this module.


=head2 rmdir

Works like core C<rmdir>, except it will remove the requested dir even if it's not empty. Symlinks are just removed, without parsing and deleting their contents, as it should be.


=head2 scalar_context

This function is meant to be used from inside a subroutine. It will return true if the function was called in scalar context. Example:

  use Perlmazing qw(scalar_context);
  
  sub my_function {
    my @array;
    # do something with @array...
    return $array[0] if scalar_context;
    return @array;
  }


=head2 shortmess

Same as L<Carp::shortmess()|Carp>.


=head2 shuffle

Same as L<List::Util::shuffle()|List::Util>.


=head2 sleep

Same as core C<sleep>, except it will accept fractions and behave accordingly. Example:

  use Perlmazing;
  
  # Sleep a quarter of a second:
  sleep 0.25;
  
  # Sleep a second and a half:
  sleep 1.5;


=head2 slurp

C<my $content = slurp($path_to_file)>

C<my $content = slurp($path_to_file, $encoding)>

C<my $content = slurp($path_to_file, $boolean_force_binary_read)>

C<my @content_lines = slurp($path_to_file)>

This function will efficiently read and return the content of a file. Example:

  use Perlmazing qw(slurp);
  
  my $data = slurp 'some/file.txt';
  
  # Or, if you'd like to have each line as an element of an array:
  my @data = slurp 'some/file.txt';
  
  # Or, you can specify a valid encoding name to be used to read the file:
  my $data = slurp 'some/file.txt', 'utf8';

It will use binmode on (detected-as) binary files only. If the second argument is 1, then binmode will be used no matter what type of file is being read. It must be 1 to force binary reading; any other true value will be taken as a specific encoding name to be used while reading the file (e.g. 'utf8').

See also L<fout|Perlmazing/fout> for writting to a file.


=head2 sort_by_key

C<sort_by_key(%hash)>

C<sort_by_key($hashref)>

This is a useful function that sorts its argument (a hash or a hashref) by key. The reason it's not a simple keyword like the case of L<numeric|Perlmazing/numeric> is the
difficulty of knowing if core C<sort> is passing a key or a value in C<$a> and C<$b>.

This function will send a warning (and do nothing) if called in void context. The reason for this is that a regular hash cannot be sorted (or remain sorted after sorting it).
Otherwise it will return a series of key-value pairs if called in list context, or an arrayref if called in scalar context. The following is an example of using it in list context:

  use Perlmazing qw(sort_by_key);
  
  my @sorted = sort_by_key %ENV;
  for (my $i = 0; $i < @sorted; $i += 2) {
      say "$sorted[$i]: $sorted[$i + 1]";
  }


=head2 sort_by_value

This is the same as the previously explained L<sort_by_key|Perlmazing/sort_by_key> function, except it will sort its argument by value instead of by key.


=head2 splitdir

Same as L<File::Spec-E<gt>splitdir()|File::Spec>. Just much more readable and easier/shorter to type.


=head2 splitpath

Same as L<File::Spec-E<gt>splitpath()|File::Spec>. Just much more readable and easier/shorter to type.


=head2 stat

Same as Perl's core L<stat>, except that, when assigned to a scalar, you get an object you can call methods on. If stringified, it will have the same value as what you would get originally with stat assigning a scalar. The names of those methods are unchanged in respect to the Perldoc's definitions. Valid methods are:

  dev
  ino
  mode
  nlink
  uid
  gid
  rdev
  size
  atime
  mtime
  ctime
  blksize
  blocks

Example:

  use Perlmazing;
  
  my $s = stat 'some_file.log';
  
  # As an interpolated value:
  pl "Last modified time was $s->{mtime}";
  
  # As a method:
  pl "Last modified time was ".$s->mtime;


=head2 sum

Same as L<List::Util::sum|List::Util>.


=head2 sum0

Same as L<List::Util::sum0|List::Util>.


=head2 tail

Same as L<List::Util::tail|List::Util>.


=head2 taint

C<taint($value)>

C<taint(@values)>

C<my @result = taint(@values)>

I<Listable function>

Same as L<Taint::Util::taint()|Taint::Util> - except that it is a I<listable> function and it will behave like any other I<listable> function from this module.


=head2 tainted

Same as L<Taint::Util::tainted()|Taint::Util>.


=head2 time

Same as core C<time>, except it will include decimals for nanoseconds.


=head2 time_hashref

C<time_hashref()>

C<time_hashref($some_time_in_seconds)>

This function will return a hashref the current local time if no argument is passed, or the time corresponding to its argument in seconds (e.g. the return value of core C<time()>).

The following is an example of a hashref returned by this function:

  {
    day          => 16,
    hour         => 20,
    is_leap_year => 1,
    isdst        => 0,
    minute       => 16,
    month        => "02",
    second       => "31.8393230",
    wday         => 2,
    yday         => 46,
    year         => 2016,
  }


=head2 timegm

Same as L<Time::Local::timegm()|Time::Local>, except it will include nanoseconds in its return value.


=head2 timelocal

Same as L<Time::Local::timelocal()|Time::Local>, except it will include nanoseconds in its return value.


=head2 to_number

C<to_number($value)>

C<to_number(@values)>

C<my @result = to_number(@values)>

I<Listable function>

It makes any valid numeric value that is currently treated as string, a valid number. It works with any value that, if it wasn't treated as string, Perl would see as a number (e.g. 123_456), but that when treated as string, fails to to something like $value +=0. The value becomes a real numeric representation. It becomes zero when the value has no numeric interpretation. It is a I<listable> function and will behave like any other
I<listable> function from this module.

Note: Octal formated numbers will become decimal, because of the way this function treats strings that should become numbers.


=head2 to_string

C<to_string($value)>

C<to_string(@values)>

C<my @result = to_string(@values)>

I<Listable function>

It will simply treat any provided value as a string, making its last use to be seen as string by Perl (e.g. 123 will become "123"). Has no real effect on strings. It is a I<listable> function and will behave like any other
I<listable> function from this module.


=head2 to_utf8

C<to_utf8($value)>

C<to_utf8(@values)>

C<my @result = to_utf8(@values)>

I<Listable function>

This is short for C<Encode::encode('utf8', $_[0]) if defined $_[0] and not is_utf8 $_[0]>, using L<Encode::encode()|Encode>. It is a I<listable> function and will behave like any other
I<listable> function from this module.


=head2 trim

C<trim($value)>

C<trim(@values)>

C<my @result = trim(@values)>

I<Listable function>

A very usefull function to remove any whitespace from the beginning or the ending of a string. It is a I<listable> function (which makes it even more useful) and will act like any other I<listable> function from this module. Example:

  use Perlmazing qw(trim);
  
  my @lines = slurp $some_file;
  trim @lines;
  
  # Now each element of @lines is trimmed.


=head2 unbless

C<unbless($value)>

C<unbless(@values)>

C<my @result = unbless(@values)>

I<Listable function>

This removes the blessing to any blessed references found in the arguments. It's the same as using L<Data::Structure::Util::unbless|Data::Structure::Util>, except this is a listable function.


=head2 uniq

Same as L<List::Util::uniq|List::Util>.


=head2 uniqint

Same as L<List::Util::uniqint|List::Util>.


=head2 uniqnum

Same as L<List::Util::uniqnum|List::Util>.


=head2 uniqstr

Same as L<List::Util::uniqstr|List::Util>.


=head2 unpairs

Same as L<List::Util::unpairs|List::Util>.


=head2 truncate_text

C<truncate_text($string, $length)>
C<truncate_text($string, $length, '...')>
C<truncate_text($string, $length, '...', '...')>

This is I<almost> the same as C<substr($string, 0, $length)>, except this function will try not to cut words in the middle. Instead, it will look for the longest possible substring (according to C<$length>) where no word is cut in half.
If that's not possible (e.g. there's no space between position 0 and C<$length>), then the string will be cut.

The second and third arguments, if present, are strings to append to the truncated result. If only the second argument is provided, it will add that string ('...' in this case) ONLY if the truncation had to cut a word. If the fourth argument is present, it will add that string ('...' also in this case) ONLY if there was a truncation, no matter if a word got cut in half.

The only exception to appending the strings in the third or fourth arguments to the truncated string, is when the whole string's length will end up being as large (or shorter) than the length of the truncated string plus the appended strings, because in such case, it's better to have the original string than a truncated one with the same length including those appends.

See the following examples for further clarification:

  use Perlmazing qw(truncate_text);
  
  my $string = 'This is an awesome string for testing.';
  
  say truncate_text $string, 1;
  # T
  
  say truncate_text $string, 2;
  # Th
  
  say truncate_text $string, 2, '...';
  # Th...
  
  say truncate_text $string, 3;
  # Thi
  
  say truncate_text $string, 3, '...';
  # Thi...
  
  say truncate_text $string, 4;
  # This
  
  say truncate_text $string, 4, '...';
  # This
  
  say truncate_text $string, 5;
  # This
  
  say truncate_text $string, 5, '...';
  # This
  
  say truncate_text $string, 6;
  # This
  
  say truncate_text $string, 6, '...', '...';
  # This...
  
  say truncate_text $string, 7;
  # This is
  
  say truncate_text $string, 7, '...';
  # This is
  
  say truncate_text $string, 7, '...', '...';
  # This is...
  
  say truncate_text $string, 8;
  # This is
  
  say truncate_text $string, 9;
  # This is
  
  say truncate_text $string, 10;
  # This is an
  
  say truncate_text $string, 11;
  # This is an
  
  say truncate_text $string, 12;
  # This is an
  
  say truncate_text $string, 13;
  # This is an
  
  say truncate_text $string, 14;
  # This is an
  
  say truncate_text $string, 15;
  # This is an
  
  say truncate_text $string, 16;
  # This is an
  
  say truncate_text $string, 17;
  # This is an
  
  say truncate_text $string, 18;
  # This is an awesome
  
  # In the next example, even when 36 is shorter than the
  # string's length (38), nothing will get appended because
  # by appending '...', the total length would be higher:
  
  say truncate_text $string, 36, '...', '...';
  # This is an awesome string for testing.
  
  # ...and so on.
    

=head2 unescape_html

C<unescape_html($value)>

C<unescape_html(@values)>

C<my @result = unescape_html(@values)>

I<Listable function>

This is the I<undo> function for L<escape_html|Perlmazing/escape_html>. It is a I<listable> function and it will behave like any other I<listable> function from this module.


=head2 unescape_uri

C<unescape_uri($value)>

C<unescape_uri(@values)>

C<my @result = unescape_uri(@values)>

I<Listable function>

This is the I<undo> function for L<escape_uri|Perlmazing/escape_uri>. It is a I<listable> function and it will behave like any other I<listable> function from this module.


=head2 unix_path

C<unix_path($value)>

C<unix_path(@values)>

C<my @result = unix_path(@values)>

I<Listable function>

This function converts any path to a Unix path representation. It's short for C<File::Spec::Unix-E<gt>catdir(File::Spec-E<gt>splitdir($path))>.

See also L<windows_path|Perlmazing/windows_path>.


=head2 untaint

C<untaint($value)>

C<untaint(@values)>

C<my @result = untaint(@values)>

I<Listable function>

This is the I<undo> function for L<taint|Perlmazing/taint>. It is a I<listable> function and it will behave like any other I<listable> function from this module.


=head2 void_context 

This function is meant to be called from inside a subroutine. It will return true if the function was called in void context. For example:

  use Perlmazing qw(void_context);
  
  # Will do nothing:
  my_function();
  
  # Will return '1':
  my $r = my_function();
  
  # Will return (1..10):
  my @list = my_function();
  
  sub my_function {
    return if void_context; # Don't do anything if there's nothing using the return value
    return 1 if scalar_context;
    return (1..10) if list_context;
  }


=head2 windows_path

C<windows_path($value)>

C<windows_path(@values)>

C<my @result = windows_path(@values)>

I<Listable function>

This function converts any path to a Windows path representation. It's short for C<File::Spec::Win32-E<gt>catdir(File::Spec-E<gt>splitdir($path))>.

See also L<unix_path|Perlmazing/unix_path>.


=head2 zip

Same as L<List::Util::zip|List::Util>.


=head1 AUTHOR

Francisco Zarabozo, C<< <zarabozo at cpan.org> >>. Please take a look at the modules mentioned on many on the functions of this POD
to see the author/credits for those modules.


=head1 BUGS

Please report any bugs or feature requests to C<bug-perlmazing at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perlmazing>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Perlmazing


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perlmazing>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2015-2024 Francisco Zarabozo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut
