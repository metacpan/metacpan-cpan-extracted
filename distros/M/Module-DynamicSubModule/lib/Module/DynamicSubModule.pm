package Module::DynamicSubModule;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.01';

# Preloaded methods go here.

$Module::DynamicSubModule::isDebugMode = 1;

use vars qw|$AUTOLOAD|;

sub new($$$@){
    shift;
    my $sBaseName = shift;
    my $sName = shift;
    return {} if(!defined $sName or $sName eq '');
    return if $sName eq 'DESTROY';
    my $sClassName = $sBaseName.'::'.ucfirst($sName);
    eval "require $sClassName";
    if(!$@){
	no strict 'refs';
	return $sClassName->new(@_);
    }else{
	print STDERR $@ if $Module::DynamicSubModule::isDebugMode;
	return if !defined $sName;
	shift while scalar(@_) > 0 and !defined $_[0];
	return if scalar(@_)%2==0;
	my %hE = ($sName,@_);
	return bless \%hE,$sBaseName;
    }
}
sub AUTOLOAD{
    my $oS = shift;
    my $sAlgoName = substr($AUTOLOAD,rindex($AUTOLOAD,'::')+2);
    return if $sAlgoName eq 'DESTROY';
    $oS->new($sAlgoName,@_);
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Module::DynamicSubModule - Call new modules like calling subroutines!

=head1 SYNOPSIS

  package Sample;
  @ISA = qw|Module::DynamicSubModule|;

  use Module::DynamicSubModule;
  
  sub new(@){
     shift;
     return Module::DynamicSubModule->new('Sample',shift,@_);
  }
  
  # There are Sample, Sample::Module1 installed.
  
  use Sample;
  
  $base = Sample->new;  # makes Sample instance.
  
  $sub = Sample->new('Module1');  # makes Sample::Module1 instance.
  $sub = Sample->Module1;         # makes Sample::Module1 instance.

=head1 DESCRIPTION

Usually, if you want to use module A::B, you first need to import A::B. And usually, instance of A::B will be created by below.

  use A::B;
  
  $instance = A::B->new;

By using Module::DynamicSubModule, you only need to import A. If you want to create instance of A::B, you only need to type either shown below.

  use A;
  
  $instance = A->new('B');
  $instance = A->B;

The name of submodule can be given as a first parameter of subroutine new, or as a subroutine name.

=head2 RULES

Hacks used in this module are very tricky, and also a little bit fragile. The rules written below will may help you decrease complicated bugs. These are recommended.

=over 4

=item Use capitalized alphabets in first character of your submodule's name. For example, "Test" and "Bytes" are good. "lame" and "millibytes" are not good.

=item Use uncapitalized alphabets in first character of your subroutine's name.

=item Use hashes for giving parameters to subroutine new. For example, if you want to give parameters %PARAM to subroutine new of A::B, type A->("B",%PARAM) or A->B(%PARAM).

=back 4

=head2 WHAT WILL HAPPEN IF THERE ARE NO MODULE NAMED A::B INSTALLED?

If A::B was not installed, but was called, it warns about it. Next, it looks up subroutines defined in A, named B. If it exists, it will be called with srguments. Else, nothing will happen. Subroutine new defined in A will return an undefined value, so some "subroutine called on an undefined value" errors may occur.

=head2 IF YOU TYPE "A->B;", WILL A::B->new BE CALLED, OR A->B?

Unfortuneately, A::B->new will be called. This problem will never occur if you follow the rules.

=head2 I DON'T WANT ANY STUPID WARNINGS SHOWN BECAUSE OF THIS MODULE!

Even if you follow the rules, still some warnings may occur with any errors. The reason is easy, all parameters for subroutine new should have even numbers of arguments(if you follow the rules), but if the caller only wanted to call the subroutine WITHOUT any subroutines, the first given argument will be used to try as an submodule name. As a result, this logical error makes bunches of errors. This may make some people frustrated.

So, I made a boolean flag to dispose all the errors. Use it like this.

  $Module::DynamicSubModule::isDebugMode = 0;

By using this, all the errors will be disposed. So, all the stupid errors will never come up to you again.

But don't forget, the errors occured in submodules will also be disposed. Even compile errors. I will recommend to stand this flag while developing.

=head1 SEE ALSO

L<Digest>

=head1 AUTHOR

Izumi Kawashima, E<lt>xor@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Izumi Kawashima

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
