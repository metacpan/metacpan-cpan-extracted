package TX;

use 5.008008;
use strict;
use warnings;
use Text::Template::Library;
use File::Spec;
use Exporter 'import';
use Config qw/%Config/;
use Carp;

our @EXPORT_OK=qw(include);

our $VERSION='0.09';

our @attributes;
BEGIN {
  # define attributes and implement accessor methods
  @attributes=qw/path cache cachesize delimiters Ostack Vstack Lstack Fstack G
		 export_include auto_reload_templates package prepend output
		 binmode evalcache evalcachesize preserve_G/;
  for( my $i=0; $i<@attributes; $i++ ) {
    my $method_num=$i;
    ## no critic
    no strict 'refs';
    *{__PACKAGE__.'::'.$attributes[$method_num]}=
      sub : lvalue {$_[0]->[$method_num]};
    ## use critic
  }
}
sub attributes {@attributes}

our $TX;

sub new {
  my ($class, @param)=@_;
  $class=ref($class) || $class;

  my $I=bless []=>$class;

  $I->export_include=1;
  $I->prepend='';

  my (%public, %private, %ignored);
  foreach my $attr ($I->attributes) {
    if( $attr=~/^_/ ) {
      $private{$attr}=1;
    } else {
      $public{$attr}=1;
    }
  }
  my @initparam;
  while( my ($k, $v)=splice @param, 0, 2 ) {
    unless( exists $public{$k} ) {
      if( exists $private{$k} ) {
	$ignored{$k}=1;
      } else {
	push @initparam, $k, $v;
      }
      next;
    }
    $I->$k=$v;
  }

  @initparam=$I->init(@initparam);

  if( @initparam ) {
    my %o=@initparam;
    @ignored{keys %o}=();
  }

  if( keys %ignored ) {
    carp "the following parameters have been ignored: ".join(', ',
							     keys %ignored);
  }

  return $I;
}

sub init {
  my ($I, @param)=@_;

  if( defined $I->path ) {
    if( ref $I->path ne 'ARRAY' ) {
      $I->path=[split /\Q$Config{path_sep}\E/, $I->path];
    }
  } else {
    if( exists $ENV{TEMPLATE_PATH} ) {
      $I->path=[split /\Q$Config{path_sep}\E/, $ENV{TEMPLATE_PATH}];
    } else {
      $I->path=[];
      # default path is derived from the location of $0 and this module.
      # the filename component and last directory component of $0 are replaced
      # by 'templates'
      my ($vol, $dir, $filename)=File::Spec->splitpath($0);
      my @dirs;
      if( ref($I) ne __PACKAGE__ ) {
	($filename=ref($I))=~s!::!/!g; $filename.='.pm';
	if( exists $INC{$filename} ) {
	  ($vol, $dir, $filename)=File::Spec->splitpath($INC{$filename});
	  @dirs=File::Spec->splitdir($dir);
	  $filename=~s/\.pm$//;
	  push @dirs, $filename;
	  push @dirs, 'templates';
	  push @{$I->path},
	    File::Spec->catpath($vol, File::Spec->catdir(@dirs), '');
	}
      }

      ($filename=__PACKAGE__)=~s!::!/!g; $filename.='.pm';
      if( exists $INC{$filename} ) {
	($vol, $dir, $filename)=File::Spec->splitpath($INC{$filename});
	@dirs=File::Spec->splitdir($dir);
	$filename=~s/\.pm$//;
	push @dirs, $filename;
	push @dirs, 'templates';
	push @{$I->path},
	     File::Spec->catpath($vol, File::Spec->catdir(@dirs), '');
      }
    }
  }

  unless( defined $I->binmode ) {
    $I->binmode=$ENV{TEMPLATE_BINMODE};
  }

  $I->delimiters=$ENV{TEMPLATE_DELIMITERS} unless( defined $I->delimiters );

  if( defined $I->delimiters and ref $I->delimiters ne 'ARRAY' ) {
    my @l=split /\t+/, $I->delimiters, 2;
    @l==2 or @l=split /\s+/, $I->delimiters, 2;
    $I->delimiters=\@l if @l==2;
  }

  $I->cache={};
  if( defined $I->cachesize and $I->cachesize>0 ) {
    if( eval {require Tie::Cache::LRU} ) {
      tie %{$I->cache}, 'Tie::Cache::LRU', $I->cachesize;
    } else {
      warn "Cannot load Tie::Cache::LRU: $@";
    }
  }

  unless( defined $I->evalcache ) {
    $I->evalcache=$ENV{TEMPLATE_EVALCACHE};
  }

  if( $I->evalcache ) {
    $I->evalcache={} unless( ref($I->evalcache) eq 'HASH' );
    if( defined $I->evalcachesize and $I->evalcachesize>0 ) {
      if( eval {require Tie::Cache::LRU} ) {
	tie %{$I->evalcache}, 'Tie::Cache::LRU', $I->evalcachesize;
      } else {
	warn "Cannot load Tie::Cache::LRU: $@";
      }
    }
  }

  $I->Fstack=[];
  $I->Ostack=[];
  $I->Vstack=[];
  $I->Lstack=[];

  return @param;
}

sub clear_cache {
  my ($I, $re, $xor)=@_;

  local $_;
  if( @_>2 ) {
    # got both $re and $xor
    $re=qr/$re/ unless ref($re) eq 'Regexp';
    delete @{$I->cache}{grep( ($xor xor !$_=~$re), keys %{$I->cache} )};
  } elsif( @_>1 and ref($re) eq 'Regexp' ) {
    delete @{$I->cache}{grep( !$_=~$re, keys %{$I->cache} )};
  } elsif( @_>1 ) {
    $xor=$re=~s/^!//;
    $re=qr/$re/;
    delete @{$I->cache}{grep( ($xor xor !$_=~$re), keys %{$I->cache} )};
  } else {
    %{$I->cache}=();
  }
  return;
}

sub get_template {
  my ($I, $filename, $module)=@_;

  #use Data::Dumper; warn Dumper(\@_);

  if( ref $filename ) {
    my $template_string=$filename->{template};
    $filename=$filename->{filename};
    my $t=Text::Template::Library->new
      (
       TYPE=>'STRING', SOURCE=>$template_string,
       FILENAME=>$filename,
       ($I->delimiters ? (DELIMITERS=>$I->delimiters) : ()),
       BROKEN=>sub {
	 my %o=@_;
	 die $o{error} if ref $o{error};
	 $o{error}=~s/\s*\z//;
	 die "Template Error in $filename($o{lineno}): $o{error}\n";
       },
       PREPEND=>$I->prepend."\n;use strict; our (%V, %G, %L)\n",
       (defined $I->evalcache ? (EVALCACHE=>$I->evalcache) : ()),
      );
    die "Template Error: Cannot compile $filename\n" unless( $t->compile );
    $I->cache->{$filename}=[$t];
  } else {
    if( exists $I->cache->{$filename} and $I->auto_reload_templates ) {
      my ($path, $base);
      foreach my $p (@{$I->path}) {
	my $base=File::Spec->catfile($p, $filename);
	if( -f ($path=$base) && -r _ or
	    -f ($path=$base.".tmpl") && -r _ or
	    -f ($path=$base.".html") && -r _ ) {
	  my ($dev, $ino, $mtime)=(stat _)[0,1,9];
	  my $cachel=$I->cache->{$filename};
	  if( $cachel->[1]!=$dev or
	      $cachel->[2]!=$ino or
	      $cachel->[3]!=$mtime ) {
	    delete $I->cache->{$filename};
	  }
	  last;
	}
      }
    }
    unless( exists $I->cache->{$filename} ) {
      my $fh;
      my ($path, $base);
      foreach my $p (@{$I->path}) {
	my $base=File::Spec->catfile($p, $filename);
	my $mode=$I->binmode;
	if( defined $I->binmode ) {
	  $mode=~s/^:?/<:/;
	} else {
	  $mode='<';
	}
	if( open $fh, $mode, $path=$base or
	    open $fh, $mode, $path=$base.".tmpl" or
	    open $fh, $mode, $path=$base.".html" ) {
	  my $t=Text::Template::Library->new
	    (
	     TYPE=>'FILEHANDLE', SOURCE=>$fh,
	     FILENAME=>$filename,
	     ($I->delimiters ? (DELIMITERS=>$I->delimiters) : ()),
	     BROKEN=>sub {
	       my %o=@_;
	       die $o{error} if ref $o{error};
	       $o{error}=~s/\s*\z//;
	       die "Template Error in $path($o{lineno}): $o{error}\n";
	     },
	     PREPEND=>$I->prepend."\n;use strict; our (%V, %G, %L)\n",
	     (defined $I->evalcache ? (EVALCACHE=>$I->evalcache) : ()),
	    );
	  die "Template Error: Cannot compile $path\n" unless( $t->compile );
	  $I->cache->{$filename}=[$t, (stat $fh)[0,1,9]];
	  last;
	}
      }
    }
    die "Template Error: $filename not found in path ".
        join($Config{path_sep}, @{$I->path})."\n"
      unless( exists $I->cache->{$filename} );
  }

  if( defined $module and length $module ) {
    return $I->cache->{$filename}->[0]->module($module);
  } else {
    return $I->cache->{$filename}->[0];
  }
}

sub include {
  my $tmpl=shift;
  my $I;

  my $tx=$TX;

  if( eval {$tmpl->isa(__PACKAGE__)} ) {
    $I=$tmpl;
    $tmpl=shift;
  } elsif( $tx ) {
    $I=$tx;
  } else {
    $TX=$I=__PACKAGE__->new;
  }

  local $TX;
  $TX=$I;

  my ($filename, $tmp_filename, $module);
  if( ref($tmpl) ) {
    $filename=$tmpl;
    $module=$tmpl->{fragment};
  } else {
    ($tmp_filename, $module)=split /#/, $tmpl, 2;
    if( length $tmp_filename ) {
      $filename=$tmp_filename;
    } else {
      $filename=$I->Fstack->[0];
    }
  }
  unshift @{$I->Fstack}, $filename;

  my %opts;
  if( ref($_[0]) eq 'HASH' ) {
    %opts=%{shift()};
  }

  my $add_v='';
  $add_v=lc delete $opts{VMODE} if exists $opts{VMODE};
  my $keep_v=$add_v eq 'keep';
  $add_v=$add_v eq 'add';

  #use Data::Dumper; $Data::Dumper::Useqq=1; warn Dumper \%opts, $I->Ostack;
  unless( %opts ) {
    %opts=%{$I->Ostack->[0]} if( @{$I->Ostack} );
  }

  unless( exists $opts{OUTPUT} ) {
    $opts{OUTPUT}=(@{$I->Ostack}
		   ? $I->Ostack->[0]->{OUTPUT}
		   : defined $I->output ? $I->output : \*STDOUT);
  }

  unless( exists $opts{PACKAGE} ) {
    $opts{PACKAGE}=(@{$I->Ostack}
		    ? $I->Ostack->[0]->{PACKAGE}
		    : defined $I->package ? $I->package : __PACKAGE__.'::__');
  }
  #use Data::Dumper; $Data::Dumper::Useqq=1; warn Dumper \%opts;
  unshift @{$I->Ostack}, +{%opts};

  # allow to specify an arbitrary string as OUTPUT to indicate
  # the result is wanted as string.
  my $want_stringoutput;
  unless( ref($opts{OUTPUT}) ) {
    delete $opts{OUTPUT};
    $want_stringoutput=1;
  }

  if( $I->export_include ) {
    no strict 'refs';
    unless( defined &{$opts{PACKAGE}.'::include'} ) {
      *{$opts{PACKAGE}.'::include'}=\&include;
    }
  }

  my $vars;
  if( $keep_v ) {
    $vars=@{$I->Vstack} ? $I->Vstack->[0] : +{};
  } elsif( $add_v ) {
    $vars=+{%{$I->Vstack->[0]}};
    my %x=@_;
    @{$vars}{keys %x}=values %x;
  } else {			# new V
    $vars=+{@_};
  }
  unshift @{$I->Vstack}, $vars;

  if( !@{$I->Lstack} and
      !$I->preserve_G || ref($I->G) ne 'HASH' ) {
    $I->G={};
  }
  unshift @{$I->Lstack}, {};

  my $rc;
  eval {
    no strict 'refs';

    local *{$opts{PACKAGE}.'::V'}=$vars;
    local *{$opts{PACKAGE}.'::G'}=$I->G;
    local *{$opts{PACKAGE}.'::L'}=$I->Lstack->[0];
    if( $want_stringoutput ) {
      $rc=$I->get_template($filename, $module)->fill_in(%opts);
    } elsif( $I->get_template($filename, $module)->fill_in(%opts) ) {
      $rc='';
    } else {
      die "ERROR: Text::Template::Base::fill_in failed: $Text::Template::Base::ERROR\n";
    }
  };
  shift @{$I->Vstack};
  shift @{$I->Ostack};
  shift @{$I->Fstack};
  shift @{$I->Lstack};

  die $@ if( $@ );

  if( @{$I->Fstack} and !defined(wantarray) and length $rc ) {
    # inside a recursive call (called from a template) in void context
    # with non-empty output. Assume the template author has forgotten
    # to say "OUT include ..." but instead said "include ...". So we do
    # it for him.

    no strict 'refs';
    return &{$opts{PACKAGE}.'::OUT'}( $rc );
  }

  return $rc;
}

1;
__END__

=encoding utf8

=head1 NAME

TX - a simple template system based on Text::Template::Library

=head1 SYNOPSIS

 use TX;
 my $T=TX->new( delimiters=>[qw/<% %>/],
                path=>[qw!/path/to/dir1 /path/to/dir2 ...!],
                binmode=>':utf8',             # how to read template files
                cachesize=>$max_cached_templates,
                evalcache=>\%another_hash,
                evalcachesize=>$max_items_in_another_hash,
                export_include=>0,            # default is 1
                auto_reload_templates=>1,     # default is 0
                prepend=>'use warnings',      # default not set
                output=>sub {...},            # default undef
                package=>'My::Dummy',         # default TX::__
                );

 $T->include( 'template1', key=>'value', ...);
 $T->include( 'template1', {OUTPUT=>'', ...}, key=>'value', ...);

or

 use TX qw/include/;

 @ENV{qw/TEMPLATE_PATH TEMPLATE_BINMODE
         TEMPLATE_DELIMITERS TEMPLATE_EVALCACHE/}=
   ('/path/to/dir1:/path/to/dir2', ':utf8', "<%\t%>", 1);

 include( 'template1', {OUTPUT=>'', ...}, key=>'value', ...);

C<template1.tmpl> may contain:

 <% define mymacro %>
 ...
 <% /define %>

 call macro defined in the same template:
   <% include '#mymacro', key=>'value', ... %>

 call macro defined somewhere else:
   <% include 'library#libmacro1', key=>'value', ... %>

C<library.tmpl> may contain:

 <% define libmacro1 %>
 ...
 <% /define %>

 <% define libmacro2 %>
 ...
 <% /define %>

=head1 DESCRIPTION

C<Text::Template::Base> and C<Text::Template::Library> are good at processing
single templates. They lack the ability to manage sets of template files.
This module adds that functionality in a (what I think) user friendly manner.

The most important function of this module is C<include>. It actually processes
the template. C<include> can be called in 2 ways, as simple subroutine or as
object method. The second way introduces much more features and hence should
be prefered. If called as simple subroutine an internal object
is created and and initialized from environment variables.

=head2 The object oriented interface

All keys passed to the constructor C<new> are also usable as accessor methods,
e.g. C<$object-E<gt>output=sub {...};>. They methods can be used as Lvalues.

=over 4

=item B<TX-E<gt>new(key=E<gt>value, ...)>

creates a C<TX> object. Options are passed as key, value pairs.

=over 4

=item * C<delimiters>

Specify delimiters used in the templates. If omitted the environment
variable C<TEMPLATE_DELIMITERS> is used.

The value can be an array that contains 2 strings or a string. In the latter
case the string is splitted into 2 by the tabulator C<\t+> character. If that
fails C<\s+> is tried. If one of them produces a 2 element list it is used
as delimiters.

Example:

Those 3 are equivalent:

 delimiters => [qw/<% %>/]
 delimiters => "<%\t%>"
 delimiters => "<% %>"

as are those 2 (note the additional space characters):

 delimiters => ['<% ', ' %>']
 delimiters => "<% \t %>"

but those are not:

 delimiters => ['<% ', ' %>']
 delimiters => "<%  %>"

=item * C<path>

Specify a search path where to look for templates. The format corresponds
to that used for the C<PATH> variable on your system. If omitted the
environment variable C<TEMPLATE_PATH> is used.

As value is expected either an array or a string. In the latter case it is
split up by your local path separator (see L<Config/path_sep>).

Template files are searched in the order given by the path. Additionally to
each template name the file name extensions C<.tmpl> and C<.html> are
appended while looking for it in a given directory.

So, assume C<dir1:dir2> is passed as C<path> and the file C<dir2/template.tmpl>
exists. The the call

 include 'template', ...

will try C<dir1/template>, C<dir1/template.tmpl>, C<dir1/template.html>,
C<dir2/template> and then find C<dir2/template.tmpl>.

=item * C<binmode>

Specify a L<perlio> layer to read template files. If omitted the environment
variable TEMPLATE_BINMODE is used.

If your templates use UTF8 encoding pass C<utf8> or C<:utf8> here.

=item * C<cachesize>

A C<TX> object maintains a template cache to hold compiled templates and thus
to avoid reading them from disk each time. Internally it is implemented
as a hash with the template names as key. You can access that cache via
C<$object-E<gt>cache>.

If a cache size greater than zero is given the hash is tied to
C<Tie::Cache::LRU> to limit the number of cached templates.

=item * C<auto_reload_templates>

If set to true C<TX> tracks whether a cached template has changed after the
most recent read. For best performance try to avoid that feature.

=item * C<evalcache> and C<evalcachesize>

This cache corresponds to the C<EVALCACHE> parameter of C<Text::Template::Base>
objects. If C<evalcachesize> greater than zero is given it is tied to
C<Tie::Cache::LRU> to limit the number of cached compiled code fragments.

The value passed as C<evalcache> can be either a hash reference or a boolean.
In the latter case an anonymous hash is created if a true value is passed.

=item * C<prepend>

Almost corresponds to the C<Text::Template::Base> C<PREPEND> parameter. At
template compile time the string

 use strict; our (%V, %G, %L);

is appended to the current value. That means code fragments are always
evaluated in strict mode and the hashes C<%V>, C<%G> and C<%L> are declared.

=item * C<output>

Corresponds more or less to the C<Text::Template::Base> C<OUTPUT> parameter.

If omitted C<\*STDOUT> is used. So by default the output is directly sent
to STDOUT. If a scalar is assigned the output is returned as a string result
from C<include>. Also a function can be set. In that case each time a piece
of output is ready that function is called with the data is passed as C<$_[0]>.

The value specified here is only the default value. It can be overridden
by the C<%options> parameter to C<include>.

=item * C<package>

Corresponds to the C<Text::Template::Base> C<PACKAGE> parameter. If omitted
C<TX::__> is used. Code fragments in templates are evaluated in this package.

The value specified here is only the default value. It can be overridden
by the C<%options> parameter to C<include>.

=item * C<export_include>

This boolean value specifies whether or not to export the C<include> function
into the package given by the C<package> parameter or the package passed in
the C<%options> hash to C<include>. If true the template author can call

 include ...

otherwise it is necessary to use the fully specified name:

 TX::include ...

This option is true by default.

=item * C<preserve_G>

If set to a true value C<$template->G> is not initialized as an empty
hash on the toplevel C<include()> invocation.

=back

=item B<$object-E<gt>include($template, \%options, key=E<gt>value, ...)>

This method processes the template C<$template>. The template may be given
as a filename or the basename of a filename (filename without extension) or
as a hash reference.

In the former case the template is looked up in the template search path
unless it is already present in the template cache.

If a hash is passed in as template it is expected to have at least the
following entries, C<template> - the template string (that would be otherwise
read from the template file) and C<filename> - a name under which the template
can be cached. Make sure to use file names that may not occur in your
operating system, e.g. names starting with a C<\0> character.

Data is passed to the template as key, value pairs after the optional
C<\%options> parameter. These parameters are collected into a hash and
made accessible inside the template as C<%V>. So, a value passed by
a certain KEY is accessed from the template as C<$V{KEY}>.

Further, the 2 hashes C<%L> and C<%G> are available to pass data around.
C<%G> is a global hash in a certain meaning. Normally, it is initialized as
an empty hash by the outermost C<include> call, the one that is invoked from
your perl program in contrast to invocations from within templates. All
templates and template modules share the same C<%G>. When the outermost
C<include> call is done it is accessible as C<%{$object-E<gt>G}>. So if
you carry around large data structures, open filehandles or similar that
may cause undesireable side effects consider to C<undef> it after the call:

 $template->include(...);
 undef $template->G;            # G is an lvalue function

As said before C<%G> is normally initialized as an empty hash. But suppose
there is a set of templates that somehow belong together and want to carry
around data between toplevel calls. C<%G> is not usable in this case. But
if the C<preserve_G> object property is set and C<$template-E<gt>G> is set
to a hash reference before the outermost call C<%G> will not be reset as in:

 $template->G=\my %G;
 $G{'meaning of life'}=42;
 $template->preserve_G=1;
 $template->include(...);
 # $G{'meaning of life'} is still 42 if not
 # overwritten by the template

This way it can be used to pass data in and out of
a template and to carry data around between toplevel C<include> calls.

C<%L> is sort of local. Each time C<include> is called a new C<%L> hash is
created. For example:

 [% define m1 %]
   G=[% ++$G{g} %] L=[% ++$L{l} %]
 [% /define %]

 [% $G{g}=10; $L{l}=10; '' #init some hash members %]

 [% ++$G{g}         # will output 11 %]
 [% ++$L{l}         # will output 11 %]
 [% include '#m1'   # will output G=12 L=1 (a localized %L is used) %]
 [% ++$G{g}         # will output 13 %]
 [% ++$L{l}         # will output 12 %]

Code fragments are evaluated with C<use strict> in effect. The 3 hashes C<%V>,
C<%G> and C<%L> are declared with the C<our> keyword.

The optional C<\%options> hash reference is used to modify the current
C<include> operation. You can

=over 4

=item *

override the default output destination. For example
C<$object-E<gt>output> is set to a file handle. In a template you
want to include the output of another one but postprocess the string
a bit. Then you can do:

 my $string=include $template, {OUTPUT=>''}, ...;
 $string=~s/(\w+)/ucfirst $1/ge;
 OUT $string;

This makes sure that $string really receives the output of the template
evaluation no matter that the objects output destination is set to a file
handle.

=item *

override the evaluation package. Normally you'll set the evaluation
package as an object property or use the default package C<TX::__>.
Sometimes it may be handy to evaluate certain templates in another
package. Be aware that C<Text::Template::Base> installs a C<$OUT> variable
and a C<OUT> function in that package. If
C<$object-E<gt>export_include> is set (the default) this module installs
a C<include> function in the package.

=item *

modify the way the parameters are merged into the C<%V> hash. Normally a
C<local()>ized version containing only the currently passed parameters
is created.

The C<VMODE> option is used to modify that behavior. It is intended to be
used inside a template, not at top level.

=over 4

=item * keep

The current C<%V> hash is passed to the template. The remaining parameter list
is ignored. In this mode the callee can modify the caller's C<%V>.

=item * add

A new C<%V> is created as a clone from the caller's C<%V>. Then the parameter
list is incorporated into the new hash adding thus new keys and overriding
existing ones.

=back

=back

In case of an error C<include> throws an exception. If the error occures
in a template the template file name and line number are given along with
the error message. If a template throws an error object or any other reference
it is propagated unchanged.

=item B<$object-E<gt>G>

returns C<\%G> after a call to C<include>.

=item B<$object-E<gt>clear_cache>

=item B<$object-E<gt>clear_cache($string_or_regexp, $delete)>

=item B<$object-E<gt>clear_cache($string)>

Clears the template cache. If called without parameters the whole cache
is cleared.

If 2 parameters are given the first is interpreted as regexp. It may be
a string containing a regexp or a C<Regexp> object (the result of a
C<qr/.../>). If the second parameter is true all matching cache elements
are dropped otherwise all non-matching. That means in the latter case
matching cache elements are preserved.

If only one parameter is given and it is a C<Regexp> object all
non-matching cache elements are dropped.

If only one parameter is given and it is a string the first character of
the string value decides if the matching or non-matching cache elements
are to be removed. If it is a exclamation mark (C<!>) it is deleted from
the string. Then the string is interpreted as regular expression and
all matching cache elements are dropped. Otherwise the whole string
(including the first character) is interpreted as regular expression and
all non-matching cache elements are dropped.

=back

=head2 Functional Interface

If C<include> is called without the first parameter being a C<TX> object
or subclassed object of C<TX> the default object C<$TX::TX> is used.
C<$TX::TX> is initialized at the first call according to the environment
variables as explained above.

=head1 SUBCLASSING

C<TX> is internally represented a an array. The first few elements are
used to hold its properties. C<@TX::attributes> holds a list of property
names. If a subclass wants to add new properties it must not override
the existing ones. So, new attributes can be added this way:

  package My::TX;

  use strict;
  use warnings;

  use TX;
  @My::TX::ISA=qw/TX/;

  our @attributes;
  BEGIN {
    # define attributes and implement accessor methods
    @attributes=(TX::attributes(), qw/p1 p2 _p3/);
    for( my $i=TX::attributes(); $i<@attributes; $i++ ) {
      my $method_num=$i;
      ## no critic
      no strict 'refs';
      *{__PACKAGE__.'::'.$attributes[$method_num]}=
	sub : lvalue {$_[0]->[$method_num]};
      ## use critic
    }
  }
  sub attributes {@attributes}

Now, if a user calls C<< My::TX->new(p1=>..., _p3=>...) >> the inherited
constructor initializes C<< $self->p1 >> but prints a warning for C<_p3>.
C<_p3> begins with an underline and hence is treated as private. C<_p3>
will not be assinged.

Optionally you can also define an C<init()> method to initialize private
data and process left over parameters:

  package My::TX;
  sub {
    my ($I, %param)=@_;
    $I->_p3=some_processing(delete $param{p3});
    return $I->SUPER::init(%param);
  }

or slightly more effective:

  package My::TX;
  sub {
    my ($I, %param)=@_;
    $I->_p3=some_processing(delete $param{p3});
    @_=($I, %param);
    goto \&TX::init;
  }

The C<init()> method must delete the parameters it knows about from C<@_>
and return the rest. So, this is also valid:

  package My::TX;
  sub {
    my ($I, %param)=@_;
    $I->SUPER::init;
    $I->_p3=some_processing(delete $param{p3});
    return %param;
  }

Note, you must call C<TX::init> at some point.

=head1 SEE ALSO

L<Text::Template::Base>, L<Text::Template::Library>

=head1 AUTHOR

Torsten Foertsch, E<lt>torsten.foertsch@gmx.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2009 by Torsten Foertsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
