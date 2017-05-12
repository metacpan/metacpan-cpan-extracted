package Parse::Path;

our $VERSION = '0.92'; # VERSION
# ABSTRACT: Parser for paths

#############################################################################
# Modules

use sanity;

use Scalar::Util qw( blessed );
use Module::Runtime qw( use_module );

use namespace::clean;
no warnings 'uninitialized';

#############################################################################
# Dispatcher

sub new {
   my $class = shift;
   my %opts;

   if (@_ == 1) {
      # XXX: Many of these forms are purposely undocumented and experimental
      my $arg = pop;
      if (blessed $arg) {
         if   ($arg->does('Parse::Path::Role::Path')) { return $arg->clone; }
         else                                         { $opts{path} = "$arg"; }
      }
      elsif (ref $arg eq 'ARRAY') { %opts = @$arg; }
      elsif (ref $arg eq 'HASH')  { %opts = %$arg; }
      else                        { $opts{path} = $arg; }
   }
   # NOTE: if @_ == 0, it gets passed to DZIL and fails with its own path attr error
   else { %opts = @_; }

   my $style = delete $opts{style} // 'DZIL';
   $style = "Parse::Path::$style" unless ($style =~ s/^\=//);  # NOTE: kill two birds with one stone

   # Load+create the path
   return use_module($style)->new(%opts);
}

42;

__END__

=pod

=encoding utf-8

=head1 NAME

Parse::Path - Parser for paths

=head1 SYNOPSIS

    use v5.10;
    use Parse::Path;
 
    my $path = Parse::Path->new(
       path  => 'gophers[0].food.count',
       style => 'DZIL',  # default
    );
 
    my $step = $path->shift;  # { key => 'count', ... }
    say $path->as_string;
    $path->push($path, '[2]');
 
    foreach my $p (@$path) {
       say sprintf('%-6s %s --> %s', @$p{qw(type step key)});
    }

=head1 DESCRIPTION

Parse::Path is, well, a parser for paths.  File paths, object paths, URLs...  A path is whatever string that can be translated into
hashE<sol>array keys.  Unlike modules like L<File::Spec> or L<File::Basename>, which are designed for interacting with file systems paths in
a portable manner, Parse::Path is designed for interacting with I<any> path, filesystem or otherwise, at the lowest level possible.

Paths are split out into steps.  Internally, these are stored as "step hashes".  However, there is some exposure to these hashes as
both input and output, so we'll describe them here:

    {
       type => 'HASH',       # must be either HASH or ARRAY
       key  => 'foo bar',    # as it would be represented as a key
       step => '"foo bar"',  # as it would be represented in a path
       pos  => 'X+1',        # used to determine depth
    }

For the purposes of this manual, a "step" is usually referring to a step hash, unless specified.

=head1 CONSTRUCTOR

    my $path = Parse::Path->new(
       path  => $path,   # required
       style => 'DZIL',  # default
    );

Creates a new path object.  Parse::Path is really just a dispatcher to other Parse::Path modules, but it serves as a common API for
all of them.

Accepts the following arguments:

=head2 path

    path => 'gophers[0].food.count'

String used to create path.  Can also be another Parse::Path object, a step, an array of step hashes, an array of paths, or whatever
makes sense.

This parameter is required.

=head2 style

    style => 'File::Unix'
    style => '=MyApp::Parse::Path::Foobar'

Class used to create the new path object.  With a C<<< = >>> prefix, it will use that as the full class.  Otherwise, the class will be
intepreted as C<<< Parse::Path::$class >>>.

Default is L<DZIL|Parse::Path::DZIL>.

=head2 auto_normalize

    auto_normalize => 1
 
    my $will_normalize = $path->auto_normalize;
    $path->auto_normalize(1);

If on, calls L</normalize> after any new step has been added (ie: L<new|/CONSTRUCTOR>, L</unshift>, L</push>, L</splice>).

Default is off.  This attribute is read-write.

=head2 auto_cleanup

    auto_cleanup => 1
 
    my $will_cleanup = $path->auto_cleanup;
    $path->auto_cleanup(1);

If on, calls L</cleanup> after any new step has been added (ie: L<new|/CONSTRUCTOR>, L</unshift>, L</push>, L</splice>).

Default is off.  This attribute is read-write.

=head1 METHODS

=head2 step_count

    my $count = $path->step_count;

Returns the number of steps in the path.  Unlike L</depth>, negative-seeking steps (like C<<< .. >>> for most file-based paths) will not lower
the step count.

=head2 depth

    my $depth = $path->depth;

Returns path depth.  In most cases, this is the number of steps to the path, a la L</step_count>.  However, relative paths might make
this lower, or even negative.  For example:

    my $path = Parse::Path->new(
       path => '../../../foo/bar.txt',
       path_style => 'File::Unix',
    );
 
    say $path->step_count;  # 5
    say $path->depth;       # -1

Despite the similarity to the pos value of a step hash, this method doesn't tell you whether it's relative or absolute.  Use
L</is_absolute> for that.

=head2 is_absolute

    my $is_absolute = $path->is_absolute;

Returns a true value if this path is absolute.  Hint: most paths are relative.  For example, if the following paths were
L<File::Unix|Parse::Path::File::Unix> paths:

    foo/bar.txt        # relative
    ../bar.txt         # relative
    bar.txt            # relative
    /home/foo/bar.txt  # absolute
    /home/../bar.txt   # absolute (even prior to cleanup)

=head2 as_string

    my $path_str = $path->as_string;

Returns the string form of the path.  This involves taking the individual step strings of the path and placing the delimiters in the
right place.

=head2 as_array

    my $step_hashes = $path->as_array;

Returns the full path as an arrayref of step hashes.  The steps are cloned for integrity.  If you want a simplier representation of
the path, consider L</as_string>.

=head2 shift

    my $step_hash = $path->shift;

Works just like the Perl version.  Removes a step from the beginning of the path and returns it.  The step is cloned for integrity.

=head2 pop

    my $step_hash = $path->pop;

Works just like the Perl version.  Removes a step from the end of the path and returns it.  The step is cloned for integrity.

=head2 unshift

    my $count = $path->unshift($step_or_path);

Works just like the Perl version.  Adds a step (or other path-like thingy) to the beginning of the path and returns the number of new
steps prepended.  Will also call L</cleanup> afterwards, if L</auto_cleanup> is enabled.

=head2 push

    my $count = $path->push($step_or_path);

Works just like the Perl version.  Adds a step (or other path-like thingy) to the end of the path and returns the number of new steps
appended.  Will also call L</cleanup> afterwards, if L</auto_cleanup> is enabled.

=head2 splice

    my @step_hashes = $path->splice($offset, $length, $step_or_path);
    my @step_hashes = $path->splice($offset, $length);
    my @step_hashes = $path->splice($offset);
 
    my $last_step_hash = $path->splice($offset);

Works just like the Perl version.  Removes elements designated by the offset and length, and replaces them with the new stepE<sol>path.
The steps are cloned for integrity.  Returns the steps removed in list context, or the last step removed in scalar context.  Will
also call L</cleanup> afterwards, if L</auto_cleanup> is enabled.

=head2 clear

    $path->clear;

Clears out the path.

Returns itself for chaining.

=head2 replace

    $path->replace;

Replaces the path with a new one.  Basically just sugar for L</clear> + L</push>.  Unlike the argument form of L</clone>, this retains the
same object and just replaces the internal path.

Returns the number of new steps created.

=head2 clone

    my $same_path    = $path->clone;
    my $similar_path = $path->clone($new_path);

Clones the path object and returns it.

Optionally takes another path (object or string or whatever) and puts that path into the clone.  This is handy if you want to use the
same options and class, but just want a different path.

=head2 normalize

    $path->normalize;

Normalizes the steps in the path.  This ensures that the keys of the step hash and the steps will be the same thing.  Or to put it
another way, this will make a "round trip" of string-to-path-to-string work commutatively.  For example, if the following paths were
L<DZIL|Parse::Path::DZIL> paths:

    '"Oh, but it can..." said the spider'.[0].value   # Before normalize
    "\"Oh, but it can...\" said the spider"[0].value  # After normalize
 
    a.b...c[0].""."".''      # Before normalize
    a.b.""."".c[0].""."".""  # After normalize

Returns itself for chaining.

=head2 cleanup

    $path->cleanup;

Cleans up the path.  Think of this in terms of C<<< cleanup >>> within L<Path::Class>.  This will remove unnecessary relative steps, and
try as best as possible to present an absolute path, or at least one that progresses in a sequential manner.  For example, if the
following paths were L<File::Unix|Parse::Path::File::Unix> paths:

    /foo/baz/../foo.txt   # /foo/foo.txt
    /foo//baz/./foo.txt   # /foo/baz/foo.txt
    ../../foo/../bar.txt  # ../../bar.txt
    ./command             # command

Returns itself for chaining.

=head1 UTILITY METHODS

These step conversion methods are available to use, but are somewhat internal, so they might be subject to change.  In most cases,
you can use the more public methods to achieve the same goals.

=head2 key2hash

    my $step_hash = $path->key2hash($key, $type, $pos);
    my $step_hash = $path->key2hash($key, $type);

Figures out the missing pieces of a keyE<sol>type pair, and returns a complete four-key step hash.  The L</normalize> method works by
throwing away the existing step and using this method.

Since pos translation works by using both step+delimiter, and C<<< key2hash >>> doesn't have access to the delimiter, it's more accurate to
pass the pos value than leave it out.

=head2 path_str2array

    my $path_array = $path->path_str2array($path_str);

Converts a path string into a path array (of step hashes).

=head2 shift_path_str

    my $step_hash = $self->shift_path_str(\$path_str);

Removes a step from the beginning of the path string, and returns a complete four-key step hash.  This is the workhorse for most of
Parse::Path's use cases.

=head2 blueprint

    my $data = $self->blueprint->{$blueprint_key};

Provides access to the blueprint for parsing the path style.  More informaton about what this hashref contains in the L<role
documentation|Parse::Path::Role::Path>.

Cloned for sanity.  Create your own Path class if you need to change the specs.

=head1 OVERLOADS

In addition to its standard methods, Parse::Path also has several L<overloads|overload> that are useful:

=head2 String Concatenation (.=)

    $path .= 'q.r.s[1]';
    $path .= [qw( q r s[1] )];

Modifies the path by calling L</push> on the RHS thing.

=head2 Numeric Comparisons

    $pathA <  $pathB
    $pathA <= $pathB
    $pathB >  $pathA
    $pathB >= $pathA
    $pathA == $pathA
    $pathA != $pathB
    $pathA <=> $pathB

Uses L</depth> for the numeric comparison.  Still works in cases of a non-path on one side.

=head2 String Comparisons

    $pathA lt $pathB
    $pathA le $pathB
    $pathB gt $pathA
    $pathB ge $pathA
    $pathA eq $pathA
    $pathA ne $pathB
    $pathA cmp $pathB

If both sides are P:P objects, each key of the path is compared separately until a difference is found.  This effectively bypasses
delimiters as an obstacle for path comparisons.  If a step is found to be an ARRAY type on both sides, a numeric comparison (C<<< <=> >>>) is
done.  Mismatched step types are allowed (and checked with C<<< cmp >>>), so sanity check your paths if this isn't desired.

If either side is a non-path, this will fallback to a simple path string comparison.

=head2 Other overloads

    !$path   # !$path->step_count  (ie: does the path contain anything?)
    "$path"  # $path->as_string
    0+$path  # $path->depth
    $$path   # $path->as_string
    @$path   # @{ $path->as_array }

These all work pretty much as you'd expect them to.

=head1 CONVERSION

Different path styles can be used with ease.  Convert Unix paths to Window paths?  No problem:

    my $unix_path = Parse::Path->new(
       path  => '/root/tmp/file.txt',
       style => 'File::Unix'
    );
 
    my $win_path  = Parse::Path->new(
       path   => $unix_path,
       style  => 'File::Win32',
    );
 
    $win_path->as_string;  # \root\tmp\file.txt
    $win_path->volume('C');
    $win_path->as_string;  # C:\root\tmp\file.txt
 
    $win_path->splice(-1, 1, '..\foobar.gif');
    $win_path->cleanup->as_string;  # C:\root\foobar.gif
 
    $unix_path->replace($win_path);
    $unix_path->as_string;  # /root/foobar.gif

=head1 CAVEATS

=head2 Absolute paths and step removal

Steps can be removed from the path as needed, but keep in mind that L</cleanup> doesn't get called methods like L</shift>, even if
L</auto_cleanup> is set.  This doesn't make a difference on absolute paths as the depth they are given is permanent.  Appending two
absolute paths may end up cancelling each other out:

    my $path = Parse::Path->new(
       path  => '/root/tmp/file.txt',
       style => 'File::Unix',
       auto_cleanup => 1,
    );
 
    $path->shift;  # remove the blank root
    $path->shift;  # now a dangling 'tmp/file.txt', tied to position 2
    $path->unshift('/home/bbyrd');
    $path->as_string;  # /home/tmp/file.txt

This problem can be sidestepped by using the string forms:

    $path->shift;
    $path->shift;  # tmp/file.txt
    $path->replace( [ '/home/bbyrd', $path->as_string ] );
    $path->as_string;  # /home/bbyrd/tmp/file.txt

This may be fixed in a later release.

=head2 Normalization of splits

While L</auto_normalize> controls normalization of steps, delimiter normalization is still automatic.  For example:

    my $path = Parse::Path->new(
       path  => 'foo//////bar.txt',
       style => 'File::Unix',
    );
    say $path->as_string;  # foo/bar.txt

This is because delimiters are not actually stored anywhere after parsing.  The L</as_string> method takes the hash steps and re-adds
the delimiters, per rules on the blueprint of the path class.  (See L<Parse::Path::Role::Path/delimiter_placement>.)

=head2 Sparse arrays and memory usage

Since arrays within paths are based on indexes, there's a potential security issue with large indexes causing abnormal memory usage
with certain modules that would use these paths.  In Perl, these two arrays would have drastically different memory footprints:

    my @small;
    $small[0] = 1;
 
    my @large;
    $large[999999] = 1;

This can be mitigated by making sure the Path style you use will limit the total digits for array indexes.  L<Parse::Path> handles
this on all of its paths, but it's something to be aware of if you create your own path classes.

=head1 SEE ALSO

L<Data::SplitSerializer> - Uses this module for path parsing

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Parse-Path/wiki>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Parse::Path/>.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and talk to this person for help: SineSwiper.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests via L<https://github.com/SineSwiper/Parse-Path/issues>.

=head1 AUTHOR

Brendan Byrd <bbyrd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
