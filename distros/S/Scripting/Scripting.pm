# $Source: /Users/clajac/cvsroot//Scripting/Scripting.pm,v $
# $Author: clajac $
# $Date: 2003/07/21 10:10:05 $
# $Revision: 1.11 $

package Scripting;

require 5.005_62;

use Scripting::Loader;
use Scripting::Security;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Scripting ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = "0.99";

sub dump_targets {
  Scripting::Expose->dump_targets;
}

sub init {
  my $pkg = shift;
  my %args = @_;

  die "Missing argument 'with'\n" unless(exists $args{with});

  if(exists $args{signfile}) {
    Scripting::Security->open($args{signfile});
  }

  Scripting::Loader->allow($args{allow});
  Scripting::Loader->load($args{with});
}

sub invoke {
  shift if $_[0] eq 'Scripting';
  Scripting::Event->invoke(@_);
}

# Preloaded methods go here.

1;
__END__
=pod

=head1 NAME

Scripting - Language independent framework for enabling application scripting.

=head1 SYNOPSIS

  package MyApp;
  use Scripting::Expose as => "Application";

  sub println : Function {
    print @_, "\n";
  }

  package main;
  use Scripting;

  Scripting->init( with => "scripts/", allow => "js", signed => "/var/db/AppFoo.sign.db");
  
  Scripting->invoke("Script-Foo");
  
=head1 DESCRIPTION

Scripting is a framwork for exposing bits and pieces of your Perl application to various scripting engines.

=head1 WHY?

Altho there are many languages that can be embedded and called from Perl, they all have different features and different APIs. The Scripting module unifies them into a single, sleek but yet powerfull API that hids all the differences from the programmer.

=head1 FEATURES

 - Simple attributes based API
 - Support for different script environments
 - Support for different languages
 - Signed scripts
 - Event system to invoke scripts

=head1 SIMPLE API

Scripting uses a attributes based API, if you don't know what that is, read L<perlsub>.

=head2 Script environments

In some applications, there might be a need to provide different kinds of APIs to scripts. These are referred to as script enviroments in this documentation. They are optional to use, and there is a global environment that is used if the target environment is ommited.

=head2 Defining packages

To make a package accessibly from scripts. Import B<Scripting::Expose> into your namespace by using the module. It's very important that this is done during compile-time, so using C<require Scripting::Expose> and call C<Scripting::Expose-E<gt>import> is not recommended.

In its simpliest form, it can look like this.

  package MyApp;
  use Scripting::Expose;

B<Scripting::Expose> will use the callers package name by default. However, in some cases this does not work because valid symbols in the Scripting module are only those that matches /^[A-Za-z][A-Za-z0-9_]*$/. Therefor, B<MyApp::Document> would not be supported. To provide another name, pass C<as =E<gt> 'Another_Name'> on usage.

  package MyApp::Document;
  use Scripting::Expose as => "Document";

This package will now become available to all script environments. If we only like to expose it to a single or multiple environments, we pass C<to =E<gt> "Foo"> or C<to =E<gt> [qw(Bar Baz)]>.

  package MyApp::Document;
  use Scripting::Expose as => "Document", to => "WordProc";

=head2 Attribute handlers

The four attribute handlers B<Function>, B<Constructor>, B<ClassMethod> and B<InstanceMethod> all uses the name of the symbol (with package removed) by default. If another name is preferred one can be supplied with C<as =E<gt> "Another_Name">

=head2 Exposing a function

  use Scripting::Expose;
  
  sub print_line : Function {
    print @_, "\n";
  }

=head2 Exposing a class that is instanciable

  package MyApp::Document;
  use Storable qw(store retrieve);

  use Scripting::Expose as => "Document";

  sub new : Constructor {
    my $self = bless {}, __PACKAGE__;
    return $self;
  }

  sub set_title : InstanceMethod(as => "setTitle") {
    my ($self, $title) = @_;
    $self->{title} = $title;
  }

  # more methods here

  sub save : InstanceMethod(as => 'saveDocument', Secure => 'arguments') {
    my $is_signed = pop;
    my ($self) = @_;

    return 0 unless($is_signed);
    store $self, $self->{path};
  }

  sub load : ClassMethod(as => 'loadDocument') {
    my ($pkg, $path) = @_;
    return retrieve($path);
  }

=head2 Script security

Scripting supports a basic mechanism for signing scripts. Signing is optional and only affects functions and methods that are exposed with the B<Secure> argument.

To "secure" a function or method, pass C<Secure =E<gt> "arguments"> to the attribute handler. This will tell Scripting to pass an extra argument to the subroutine when it is invoked. The value of the argument will be 1 (true) if the calling script is signed, and 0 (false) if it's not.

Signing a script is done by using the tool B<sign_script.pl> which is available in the tools directory in the module distribution. C<./sign_script -d /path/to/sign.database -f /path/to/script>.

All paths are stored as absolute paths, so if you move a signed script it must be resigned.

Issue C<./sign_script --help> for more options.

=head2 Initializing and loading scripts

Upon initialization, all scripts found in the supplied directory paths are loaded. To initialize Scripting, call C<Scripting-E<gt>init>.

=item Scripting-E<gt>init( with =E<gt> $dirs, allow =E<gt> $langs, signfile =E<gt> $db);

The argument B<with> is mandatory, the others are optional. 

B<allow> is either a scalar containg a whitespace separeted list of file extensions, for example "js tcl" or an array reference with each allowed file extension, for exmaple [qw(js tcl)].

B<signfile> is the path to the database with script signatures. If signfile is ommited, script signing is disabled.

B<with> is a scalar containg a path to the directory from which it should load the scripts. It is also possible to load from several paths by passing an array reference.

Loading scripts works in a special way. If the name of directory in which the script is found in is a environment, it will be loaded into that. Otherwize, the script will be loaded in the global environment. The name of the file without the extension becomes the name of the event that is used to invoke the script. This table should make it a bit clearer. 

  # Environment : Event name

  # _Global : test
  scripts/test.js

  # Foo : bar
  scripts/Foo/bar.js

=head2 Invoking scripts

To invoke a script call C<Scripting-E<gt>invoke($name_of_event)>. If the event doesn't exist, nothing there won't be an exception or error. Calling the invoke method with only one argument looks for the event in the global environment, to invoke a script in another environment, pass the name of the environment as the first argument. For example C<Scripting-E<gt>invoke(WordDoc => $name_of_event>. Future versions of Scripting may support an attribute handler to automaticlly invoke events upon a subroutine call.

=head1 FUTURE DEVELOPMENTS

 - More security options (don't run an unsigned script at all etc.)
 - More languages (Tcl, Java, C)
 - Function named based event invokation (have multiple event handlers in one script)
 - Things I can't think of right now

=head1 SEE ALSO

L<JavaScript>

http://developer.surfar.nu/Scripting/

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Copyright 2003 Claes Jacobsson

=head1 AUTHOR

Claes Jacobsson, claesjac@cpan.org

=cut
