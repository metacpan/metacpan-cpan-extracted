package Sub::Signatures;
$REVISION = '$Id: Signatures.pm,v 1.3 2004/12/05 21:19:33 ovid Exp $';
$VERSION  = '0.21';

use 5.006;
use strict;
use warnings;
use Filter::Simple;

my $CALLPACK;
my %SIG;

my %METHODS;

sub import {
    my $class = shift;
    my %props = map { $_ => 1 } @_;
    ($CALLPACK) = caller;
    $METHODS{$CALLPACK} = exists $props{methods} ? 1 : 0;
    if ( $ENV{SS_DEBUG} ) {
        require Data::Dumper;
        Data::Dumper->import;
        $Data::Dumper::Indent = 1;
    }
}

my $signature = sub {
    my ( $subname, $parameters ) = @_;
    if ( 'fallback' eq $parameters ) {
        return ( "_${subname}_fallback", '', 0 );
    }
    else {
        my @args =
          map { /\s*(\S*)\s*(\$\w+)/; [ $1 || 'SCALAR', $2 ] }
          split /(?:,|=>)/ => $parameters;
        my $count = @args;
        $parameters = join ', ' => map { $_->[1] } @args;
        return ( "__${subname}_$count", $parameters, scalar @args );
    }
};

my $make_subs = sub {
    while ( my ( $pack, $subs ) = each %SIG ) {
        while ( my ( $sub, $counts ) = each %$subs ) {
            my @build =
              sort { $a->[1] cmp $b->[1] }
              map { [ $_ => $counts->{$_} ] } keys %$counts;
            foreach my $item (@build) {
                my ( $count, $target ) = @$item;
                next if 0 <= index +( $subs->{$sub}{body} || '' ), $target;
                next if 'body' eq $count;
                $subs->{$sub}{body} ||= '';
                $subs->{$sub}{body} .= $target =~ /_fallback$/
                  ? "    goto \&$target;\n"
                  : "    goto \&$target if $count == \@_;\n";
            }
        }
    }
    print Dumper(%SIG) if $ENV{SS_DEBUG};
};

my $install_subs = sub {
    while ( my ( $pack, $subs ) = each %SIG ) {
        foreach my $sub ( keys %$subs ) {
            my $body = $subs->{$sub}{body};
            my $type = $METHODS{$pack} ? 'method' : 'sub';
            unless ( $body =~ /_fallback;/ ) {
                $body .= <<"                END_BODY";
    # if we got to here, there was no $type to dispatch to
    require Carp;
    shift if 'method' eq '$type';
    my \$types = join ', ' => map { ref \$_ || 'SCALAR' } \@_;
    Carp::croak "Could not find a $type matching your signature: $sub(\$types)";
                END_BODY
            }
            no warnings 'redefine';
            my $installed_sub = "package $pack;\nsub $sub {\n$body}";
            eval $installed_sub;
            warn
"Installing &${pack}::$sub\n----------\n$installed_sub\n----------\n"
              if !$@ && $ENV{SS_DEBUG};
            die
"Failed to install &${pack}::$sub\n----------\n$installed_sub\n----------\nReason:  $@"
              if $@;
        }
    }
};

# each regex can capture itself!
my $sub_name_re   = qr/([_[:alpha:]][[:word:]]*)/;
my $parameters_re = qr/\(([^)]+)\)/;
FILTER {
    warn "Calling package:  $CALLPACK ****" if $ENV{SS_DEBUG};
    while (/(sub\s+$sub_name_re?\s*$parameters_re[^{]*\{)/) {
        my ( $sub_with_sig, $oldname, $parameters ) = ( $1, $2, $3 );

        # the following line doesn't work.  For some reason, using prototypes
        # with this module causes an infinite while loop here.
        # I'm probably overlooking something really obvious.
        # next if $parameters =~ /^\s*[\\\$@%*;\[\]]*\s*$/; # ignore prototypes

        my ( $newname, $newparams, $count );
        if ($oldname) {

            # named sub
            ( $newname, $newparams, $count ) =
              $signature->( $oldname, $parameters );
            if (   exists $SIG{$CALLPACK}{$oldname}
                && exists $SIG{$CALLPACK}{$oldname}{$count} )
            {
                my $args = $newname;
                $args =~ s/^_\w+_//;
                $args =~ s/_/, /g;

                # how do I get the line number?
                die "$oldname($args) redefined in package '$CALLPACK'";
            }
            $SIG{$CALLPACK}{$oldname}{$count} = $newname;
        }
        else {

            # anonymous sub
            $newname   = '';
            $newparams = $parameters;
        }
        if ($newparams) {
            s/\Q$sub_with_sig\E/sub $newname \{ my ($newparams) = \@_;/;
        }
        else {
            s/\Q$sub_with_sig\E/sub $newname \{/;
        }
    }
    $make_subs->();
    $install_subs->();
    print $_ if $ENV{SS_DEBUG};
};

1;

__END__

=head1 NAME

Sub::Signatures - Use proper signatures for subroutines, including dispatching.

=head1 SYNOPSIS

  use Sub::Signatures;
  
  sub foo($bar) {
    print "$bar\n";
  }

  sub foo($bar, $baz) {
    print "$bar, $baz\n";
  }

  foo(1);     # prints 1
  foo(2,3);   # prints 2, 3
  foo(2,3,4); # fatal error

  sub bar($var) {
    print "$var\n";
  }

  sub bar(fallback) {
    my ($this, $that) = @_;
    print "fallback $this, $that\n";
  }
  
  bar(1);   # prints 1
  bar(2,3); # prints fallback 2, 3
  bar(2,3);

=head1 ABSTRACT

 Signature based method overloading in Perl.

=head1 DESCRIPTION

B<WARNING>:  Not backwards-compatible to Sub::Signatures 0.11.

One of the strongest complaints about Perl is its poor argument handling.
Simply passing everything in the C<@_> array is a serious limitation.  This
module aims to rectify that.

With this module, we an specify subroutine signatures and automatically 
dispatch on the number of arguments.

We often see things like this in Perl code:

 sub name {
   my $self = shift;
   $self->set_name(@_) if @_;
   return $self->{name};
 }

 sub set_name {
   my $self = shift;
   $self->{name} = shift;
   return $self;
 }

The intent here is to allow someone to do this:

  my $name = $person->name; # fetch the name
  $person->name('Ovid');    # set the name

Most modern programming languages have multi-method dispatching.   The intent
of C<Sub::Signatures> is to fix this problem painlessly by allowing signature
based method dispatch. 

Here's how it works:

  use Sub::Signatures qw/methods/;

  # ...

  sub name ($self) {
    return $self->{name};
  }

  sub name ($self, $name) { 
    $self->{name} = $name;
  }

Later:

  print $object->name;  # prints current name
  $object->name($name); # sets current name
  $object->name(qw/Publius Ovidius/); # fatal runtime error

B<NOTE>:  all arguments in signatures must be scalars.  Perl does not handle
flattening of hashes or arrays very gracefully.

=head2 Fallback

For a group of subroutines or methods with the same name but different
arguments, calling this subroutine with a different number of arguments from
those available in any signature will cause a fatal runtime error.  If this is
too restrictive, use a 'fallback' subroutine or method.

  sub name ($self) {
    return $self->{name};
  }

  sub name ($self, $name) { 
    $self->{name} = $name;
  }

  sub name(fallback) {
    my ($self, @args) = @_;
    $self->{name} = join ' ', @args;
  }

Later:

  print $object->name;  # prints current name
  $object->name($name); # sets current name
  $object->name(qw/Publius Ovidius/); # sets name to 'Publius Ovidius'
 
Note that forcing the programmer to explicitly label a subroutine as a
'fallback' ensures that even if that subroutine is not located near any of the
others with the same name, it's still clear to a maintenance programmer that
the subroutine may be overloaded.

=head2 Using Methods

The default behavior of C<Sub::Signatures> is to assume that signatures are on
subroutines.  If you use this with OO programming and have methods instead of
functions, you must specify C<methods> mode.  This is because we have to be
able to dispatch to a parent class if the method isn't found in the current
class.

 package ClassA;
 
 use Sub::Signatures qw/methods/;
 
 sub new($package, $properties) { 
    bless $properties => $package;
 }
 
 sub foo($class, $bar) {
     return sprintf "arrayref with %d elements" => scalar @$bar;
 }
 
 sub name($self) {
     return $self->{name};
 }

 sub name($self, $name) {
     $self->{name} = $name;
     return $self;
 }
 
 1;

=head2 Anonymous subroutines

While multi-dispatch doesn't make much sense in the context of anonymous
subroutines, we can still use subroutine signatures with them:

 sub foo($bar) {
   return sub ($this) { "$this $bar" }
 }

Also, though there is special handling for "methods", anonymous subroutines
can be safely mixed with methods.

=head1 FEATURES

Currently supported features:

=over 4

=item * Methods

 use Sub::Signatures 'methods';

Note that if you use 'methods', you cannot use signatures with subroutines
which are called in a non-Object-Oriented fashion.

 use Sub::Signatures 'methods';

 sub _reverse_text { # must not have signature
   my $text = shift;
   return scalar reverse $text;
 }

 sub new ($class) {
    bless {}, $class;
 }

 sub new ($class, $data) {
    die "Argument to new() must be a hashref'
      unless ref $data eq 'HASH';
    bless $data, $class;
 }
 
 sub name ($self) {
    return $self->{name};
 }

 sub name ($self, $name) {
    $self->{name} = $name;
 }
 
=item * Subroutines

 use Sub::Signatures;

 sub foo ($data) {
   ...
 }

 sub foo ($arg1, $arg2) {
   ...
 }

=item * Exporting

 use base 'Exporter';
 use Sub::Signatures;
 our @EXPORT_OK = qw/foo/;

 sub foo($bar) {...}

 sub foo($bar, $baz) {
     ...
 }

=item * No duplicate signatures

 use Sub::Signatures;
 sub foo($bar) {}
 sub foo($baz) {} # won't compile
 
=item * Inheritance

 use Sub::Signatures 'methods';

Specifying C<methods> allows C<Sub::Signatures> to call your method correctly
rather than call it as a subroutine.

=item * Anonymous subroutines

 my $thingy = sub ($foo, $bar) { ... };

Unlike named subs, the number of arguments is not checked, so this is
equivalent to:

 my $thingy = sub { my ($foo, $bar) = @_; ... };

=item * Useful error messages

The error messages bear some explaining.  If your code cannot find the correct
method to dispatch to, you'll see something like this:

 Could not find a sub matching your signature: foo(SCALAR, SCALAR) at ...

Or:

 Could not find a method matching your signature: foo(SCALAR) at ...

If used in method mode, the first argument to a method is actually a class or 
instance of a class, but this is B<not> in the argument list in the error
message because this seems counter-intuitive:

 $object->foo($bar);

It looks like there's really only one argument (even though we know better)
and for various reasons, the code is a bit cleaner when the error message is
handled this way.

=back

=head1 WHAT ABOUT TYPING?

The first version of this alpha allowed optional strong typing by letting
you specify the exact ref type each argument should be:

 sub foo (ARRAY $bar, HASH $baz, CGI $query) {
   ...
 }

Why did this go away?  There were several problems.  First, specifying the
exact data type meant that I<isa> relationships were ignored.  However, if we
were to check I<isa> relationships, this sometimes leads to problems with
ambiguous method resolution.

The real nail in the coffin was that C<CGI $query> parameter above.  What if
we actually have a C<CGI::Simple> object passed in instead?  It almost
completely conforms to the C<CGI> interface.  If it does what we want, the type
checking guarantees that that this method will fail for no good reason.

However, no argument checking is a bad thing.  What we're really interested in
is whether or not a given argument is capable of providing what we need, not
whether or not it's a given type.  This puts your author in a bind.  Objects
which are unrelated by inheritance but present the same behaviors are known as
I<allomorphic>.  

Allomorphism, despite the funny name, is something Perl programmers use all the
time without being aware of what it's called.  However, to add allomorphism
support to this module would complicate it quite a bit.  Thus, to keep things
as simple as possible, we restrict ourselves to dispatching on the number of
arguments.  Thus, you, the programmer, will still need to validate the
different types and/or capabilities of the arguments you pass in.

If you prefer, you can still list the data type before the argument:

  sub foo (ARRAY $bar) {...}

However, the C<ARRAY> will be discarded.  Think of it as documentation.

=head1 BUGS AND LIMITATIONS

For the most part this module I<just works>.  If you are having problems,
consult this list to see if it's covered here.

=over 4

=item * "sub foo {}"

Due to limitations with parsing Perl, this module does I<not> attempt to take
advantage of C<Filter::Simple>'s "FILTER_ONLY" functionality.  This means that
this module is a straightforward filter.  As a result, if you have text in
quoted areas which resembles "signified" subroutines, you may see strange
results.  Fortunately, this is very rare.

=item * Do not mix "signatured" subs with "non-signatured" of the same name

In other words, don't do this:

 sub foo($bar) { ... }
 sub foo { ... }

If you want something like that, name a L<Fallback> subroutine:

 sub foo($bar) { ... }
 sub foo(fallback) { ... }

However, you don't need signatures on all subs.  This is OK:

 sub foo($bar) { ... }
 sub baz { ... }

=item * Use caution when mixing functions and methods

Internally, functions and methods are handled quite differently.  If you use
this with a class, you probably do not want to use signatures with functions in
said class.  Things will usually work, but not always.  Error messages will be
misleading.

  package Foo;
  use Sub::Signatures qw/methods/;

  sub new($class) { bless {} => $class }

  sub _some_func($bar) { return scalar reverse $bar }

  sub some_method($self, $bar) { 
      $self->{bar} = _some_func($bar);
  }

  sub some_other_method($self, $bar, $baz) {
      # this fails with 
      # Could not find a method matching your signature: _some_func(SCALAR) at ...
      $self->{bar} = _some_func($bar, $baz);
  }

  1;

=item * One package per file.

Currently we cannot handle more than one package per file with this module.
It sometimes works with methods, but there are no guarantees.  When we can
parse Perl reliably, this may change :)

=item * Can only handle scalars and references in the arg list.

At the present time, the only variables allowed in signatures are those
that begin with a dollar sign:

 sub foo($bar, $baz) {...}; # good
 sub foo($bar, @baz) {...}; # not good

=item * Handle prototypes correctly

Don't try using prototypes with this module.  It currently tends to get caught
in an infinite loop if you do that, so don't do that.

 use Sub::Signatures;

 sub foo($$) {...} # don't do that

See C<t/90prototypes.t> and the code at the end if you want to fix this.

Of course, prototypes in Perl are widely considered to be broken anyway, so why
use them?

=back

=head1 HOW THIS WORKS

In a nutshell, each subroutine is renamed with a unique, signature-based name
and a sub with its original name figures out how to dispatch to it.  It loosely
works like this:

 package Some::Package;

 sub foo($bar) {
     return [$bar];
 }
 
 sub foo($bar, $baz) {
     return exists $baz->{$bar};
 }
 
In loose mode, this becomes:

 # note that only the number of arguments is checked

 package Some::Package;

 sub foo {
     goto &__foo_1 if 1 == @_;
     goto &__foo_2 if 2 == @_;
     # die with a useful error message unless we have a fallback subroutine
 }

 sub __foo_1 { my ($bar) = @_;
     return [$bar];
 }

 sub __foo_2 { my ($bar, $baz) = @_;
     return exists $baz->{$bar};
 }

There's a bit more magic involved when it comes to methods, particulary with
trying to call an inherited method if one is not found in the current package.
However, this should give you a rough idea of what's going on and also give you
fair warning that deliberately naming subs things like C<_subname_$digit> is a
bad thing.

=head1 EXPORT

None.

=head1 BETA CODE

This is beta code.  Many people understandably do not wish to use beta code
in production.  To get this code robust enough for production use, send me bug
reports.  Send me patches.  Send me requests.  Send me feedback.

Naturally, since this is beta code, the interface is probably stable.  I have
no intention of changing it unless I need to.  Hopefully I've not made any
boneheaded mistakes that necessitate this, but I will not guarantee that I am
not, in fact, boneheaded.

However, if you use this module, please let me know.  If things do change, I'd
like to give folks a heads up.

=head1 SEE ALSO

L<Filter::Simple>

Yes, this is based on a source filter.  If you can't stand that, don't use this
module.  However, before you ignore it, read 
L<http://use.perl.org/~Ovid/journal/22152>.

L<Attribute::Signature>

L<Perl6::Subs>

L<Perl6::Parameters>

=head1 AUTHOR

Curtis "Ovid" Poe, E<lt>moc tod oohay ta eop_divo_sitrucE<gt>

Reverse the name to email me.

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 by Curtis "Ovid" Poe

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
