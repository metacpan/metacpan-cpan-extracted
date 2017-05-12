package MooseX::DeclareX;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$MooseX::DeclareX::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::VERSION   = '0.009';
}

use constant DEFAULT_KEYWORDS => [qw(class role exception)];
use constant DEFAULT_PLUGINS  => [qw(build guard std_constants)];

use Class::Load 0 qw(load_class);
use Data::OptList 0;
use MooseX::Declare 0;
use TryCatch 0;

sub import
{
	my ($class, %args) = @_;
	my $caller = caller(0);

	# Simplified interface for a couple of standard plugins
	foreach my $awesome (qw/ types imports /)
	{
		if (my $ness = delete $args{$awesome})
		{
			$args{plugins} ||= DEFAULT_PLUGINS;
			push @{ $args{plugins} }, $awesome, $ness;
		}
	}

	$_->setup_for($caller, %args, provided_by => $class) for __PACKAGE__->_keywords(\%args);
	
	strict->import;
	warnings->import;
	TryCatch->import({ into => $caller });
}

sub _keywords
{
	my ($class, $args) = @_;
	my @return;
	
	my $kinds = Data::OptList::mkopt( $args->{keywords} || DEFAULT_KEYWORDS );
	foreach my $pair (@$kinds)
	{
		my ($class, $opts) = @$pair;
		$opts //= {};
		
		load_class(
			my $module = join '::' => qw[MooseX DeclareX Keyword], $class
		);
		
		my $kw = $module->new( $opts->{init} ? $opts->{init} : (identifier => $class) );
		push @return, $kw;
		
		my $plugins = Data::OptList::mkopt(
			$opts->{plugins} || $args->{plugins} || DEFAULT_PLUGINS,
		);
		
		foreach my $pair2 (@$plugins)
		{
			no warnings;
			my ($class2, $opts2) = @$pair2;
			next if $class2 =~ qr(
				method | before | after | around | override | augment
				| with | is | clean | dirty | mutable | try | catch
			)x;
			use warnings;
			
			my $module2 = join '::' => (qw[MooseX DeclareX Plugin], $class2);
			$module2 =~ s/Plugin::concrete$/Plugin::abstract/;
			load_class $module2;
			
			$module2->plugin_setup($kw, $opts2);
		}
	}
	
	return @return;
}

"Would you like some tea with that sugar?"

__END__

=head1 NAME

MooseX::DeclareX - more sugar for MooseX::Declare

=head1 SYNOPSIS

  use 5.010;
  use MooseX::DeclareX
    keywords => [qw(class exception)],
    plugins  => [qw(guard build preprocess std_constants)],
    types    => [ -Moose ];
  
  class Banana;
  
  exception BananaError
  {
    has origin => (
      is       => read_write,
      isa      => Object,
      required => true,
    );
  }
  
  class Monkey
  {
    has name => (
      is       => read_write,
      isa      => Str,
    );
    
    build name {
      state $i = 1;
      return "Anonymous $i";
    }  
    
    has bananas => (
      is       => read_write,
      isa      => ArrayRef[ Object ],
      traits   => ['Array'],
      handles  => {
        give_banana  => 'push',
        eat_banana   => 'shift',
        lose_bananas => 'clear',
        got_bananas  => 'count',
      },
    );
    
    build bananas {
      return [];
    }
    
    guard eat_banana {
      $self->got_bananas or BananaError->throw(
        origin  => $self,
        message => "We have no bananas today!",
      );
    }
    
    after lose_bananas {
      $self->screech("Oh no!");
    }

    method screech (@strings) {
      my $name = $self->name;
      say "$name: $_" for @strings;
    }  
  }
  
  class Monkey::Loud extends Monkey
  {
    preprocess screech (@strings) {
      return map { uc($_) } @strings;
    }
  }
  
  try {
    my $bobo = Monkey::Loud->new;
    $bobo->give_banana( Banana->new );
    $bobo->lose_bananas;
    $bobo->give_banana( Banana->new );
    $bobo->eat_banana;
    $bobo->eat_banana;
  }
  catch (BananaError $e) {
    warn sprintf("%s: %s\n", ref $e, $e->message);
  }

=head1 STATUS

This is very experimental stuff. B<< YOU HAVE BEEN WARNED! >>

=head1 DESCRIPTION

MooseX::DeclareX takes the declarative sugar of L<MooseX::Declare> to the
next level. Some people already consider MooseX::Declare to be pretty insane.
If you're one of those people, then you're not going to like this...

=head2 Keywords

=over

=item C<class>, C<role>, C<extends>, C<with>, C<< is dirty >>, C<< is mutable >>, C<clean>.

Inherited from L<MooseX::Declare>.

=item C<method>, C<around>, C<before>, C<after>, C<override>, C<augment>

Inherited from L<MooseX::Method::Signatures>.

=item C<try>, C<catch>

Inherited from L<TryCatch>.

=item C<exception>

C<< exception Foo >> is sugar for C<< class Foo extends Throwable::Error >>.
That is, it creates a class which is a subclass of L<Throwable::Error>.

=item C<build>

This is some sugar for creating builder methods. The following two examples
are roughly equivalent:

  build fullname {
    join q( ), $self->firstname, $self->surname;
  }

  sub _build_fullname {
    my $self = shift;
    join q( ), $self->firstname, $self->surname;
  }

However, C<build> also performs a little housekeeping for you. If an attribute
does not exist with the same name as the builder, it will create one for you
(which will be read-only, with type constraint "Any" unless C<build> can detect
a more specific type constraint from the method's return signature). If the
attribute already exists but does not have a builder set, then it will set it.

=item C<guard>

Simplifies a common usage pattern for C<around>. A guard protects a method,
preventing it from being called unless a condition evaluates to true.

  class Doorway
  {
    method enter ($person)
    {
      ...
    }
  }
  
  class Doorway::Protected
  {
    has password => (is => 'ro', isa => 'Str');
    
    guard enter ($person)
    {
      $person->knows( $self->password )
    }
  }

=item C<preprocess>

Another simplification for a common usage pattern for C<around>. Acts much
like C<before>, but B<can> modify the parameters seen by the base method.
In fact, it must return the processed parameters as a list.

  class Speaker
  {
    method speak (@words) {
      say for @words;
    }
  }
  
  class Speaker::Loud
  {
    preprocess speak {
      return map { uc($_) } @_
    }
  }

=item C<postprocess>

Like C<preprocess> but instead acts on the method's return value.

=item C<read_only>, C<read_write>, C<true>, C<false>

Useful constants when defining Moose attributes. These are enabled by the
std_constants plugin.

=back

=head2 Export

You should indicate which features you are using:

  use MooseX::DeclareX
    keywords => [qw(class role exception)],
    plugins  => [qw(guard build)];

What is the distinction between keywords and plugins? Keywords are the words
that declare class-like things. Plugins are the other bits, and only work
B<inside> the class-like declarations.

Things inherited from MooseX::Declare and MooseX::Method::Signatures do not
need to be indicated; they are always loaded. Things inherited from TryCatch
do not need to be indicated; they are available outside class declarations
too.

If you don't specify a list of keywords, then the default list is:

  [qw(class role exception)]

If you don't specify a list of plugins, then the default list is:

  [qw(build guard std_constants)]

That is, there are certain pieces of functionality which are not available
by default - they need to be loaded explicitly! 

=head2 MooseX::Types

You can inject a bunch of MooseX::Types keywords into all classes quite
easily:

  use MooseX::DeclareX
    keywords => [qw(class role exception)],
    plugins  => [qw(build std_constants)],
    types    => [
      -Moose,                 # use MooseX::Types::Moose -all
      -URI => [qw(FileUri)],  # use MooseX::Types::URI qw(FileUri)
      'Foo::Types',           # use Foo::Types -all
    ];

As per the example, any module which does not include an arrayref of import
parameters, gets "-all". A leading hyphen is interpreted as an abbreviation
for "MooseX::Types::".

=head2 Additional Import Syntactic Sugar

You can specify a list of additional modules that will always be imported
"inside" your class/role definitions.

  use MooseX::DeclareX
    keywords => [qw(class role exception)],
    plugins  => [qw(build guard std_constants)],
    imports  => [
      'MooseX::ClassAttribute',
      'Path::Class'      => [qw( file dir )],
      'Perl6::Junction'  => [qw( any all none )],
      'List::Util'       => [qw( first reduce )],
    ];

In fact, this is just a minor generalisation of the MooseX::Types feature.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-DeclareX>.

=head1 SEE ALSO

L<MooseX::Declare>, L<MooseX::Method::Signatures>, L<TryCatch>,
L<Throwable::Error>, L<MooseX::Types>.

Additional keywords and plugins are available on CPAN:
L<MooseX::DeclareX::Plugin::abstract>,
L<MooseX::DeclareX::Privacy>,
L<MooseX::DeclareX::Keyword::interface>,
L<MooseX::DeclareX::Plugin::singleton>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

