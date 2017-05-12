use 5.008;
use strict;
use warnings;

package Sub::Block;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Moo;

use Carp qw(carp croak);
use Exporter::Tiny qw();
use Scalar::Util qw(blessed refaddr);
use Sub::Quote qw();

use namespace::clean;

{
	our @ISA    = 'Exporter::Tiny';
	our @EXPORT = 'block';
	sub _generate_block {
		my $class = shift;
		sub (&) { $class->new(@_) };
	}
}

use overload (
	q[&{}]  => sub { $_[0]{sub} },
	q[>>]   => sub { __PACKAGE__->sequence($_[2] ? @_[1,0] : @_[0,1]) },
);

has sub => (is => 'ro', required => 1);
has [qw/ map grep /] => (is => 'lazy');

my $deparse;
sub BUILDARGS
{
	my $class = shift;
	
	if (@_ == 1 and ref($_[0]) eq q(HASH))
	{
		return $_[0];
	}
	elsif (@_ == 1 and ref($_[0]) eq q(CODE))
	{
		require B::Deparse;
		require PadWalker;
		$deparse ||= 'B::Deparse'->new;
		
		my $coderef = shift;
		$class->_check_coderef($coderef);
		
		my $closures = PadWalker::closed_over($coderef);
		my $perlcode = $deparse->coderef2text($coderef);
		
		$perlcode =~ s/(?:\A\{)|(?:\}\z)//g;
		return +{ sub => Sub::Quote::quote_sub($perlcode, $closures) }
	}
	else
	{
		return +{ sub => scalar Sub::Quote::quote_sub(@_) };
	}
}

sub _check_coderef
{
	require B;
	my $class = shift;
	my ($coderef) = @_;
	
	local *B::OP::__Sub_Block_callback = sub
	{
		my $name = $_[0]->name;
		return if $name ne 'return' && $name ne 'wantarray';
		local $Carp::CarpLevel = $Carp::CarpLevel + 2;
		carp("Coderef $coderef appears to contain an explicit `$name` statement; not suitable for inlining");
	};
	
	B::svref_2object($coderef)->ROOT->B::walkoptree('__Sub_Block_callback');
}

sub execute
{
	my $self = shift;
	my $sub = $self->{sub};
	goto $sub;
}

sub code
{
	Sub::Quote::quoted_from_sub( $_[0]->{sub} )->[1];
}

sub closures
{
	Sub::Quote::quoted_from_sub( $_[0]->{sub} )->[2];
}

sub inlinify
{
	my $self = shift;
	Sub::Quote::inlinify($self->code, join(q[,], @_), '', 1);
}

sub sequence
{
	my $class = __PACKAGE__;
	$class = shift if !ref $_[0];
	
	my @subs = map { blessed($_) ? $_ : $class->new($_) } @_;
	
	my $code = '';
	my $vars = {};
	
	for my $sub (@subs)
	{
		my $sub_closures = $sub->closures;
		for my $k (sort keys %$sub_closures)
		{
			next if exists($vars->{$k}) && refaddr($vars->{$k})==refaddr($sub_closures->{$k});
			croak "Attempted to close over two variables named $k" if exists($vars->{$k});
			$vars->{$k} = $sub_closures->{$k};
		}
		$code .= "\@_ = do { ${\ $sub->code } };\n"
	}
	
	$code .= 'eval { wantarray ? @_ : $_[-1] };'."\n";
	
	return $class->new($code, $vars);
}

sub _build_from_template
{
	my $self = shift;
	my $code = sprintf($_[0], $self->code);
	ref($self)->new($code, $self->closures);
}

sub _build_map
{
	shift->_build_from_template('map { local @_ = ($_); %s } @_');
}

sub _build_grep
{
	shift->_build_from_template('grep { local @_ = ($_); %s } @_');
}

1;

__END__

=pod

=encoding utf-8

=for stopwords optree

=head1 NAME

Sub::Block - manipulate blocks of code to assemble them into subs

=head1 SYNOPSIS

   use Sub::Block;
   
   my $plus_one = block { $_[0] + 1 };
   print $plus_one->(7);   # 8

=head1 STATUS

This is all pretty experimental at the moment. Consider it to be a
proof-of-concept.

=head1 DESCRIPTION

Sub::Block allows you to create objects that are conceptually code blocks
that can be composed with other code blocks to create subs which, when
called, will run the code in the blocks without all of the overhead
associated with a normal sub call.

Another way to think about it is that it's a cleaner way of building
closures than stringy eval.

Assume for example that you have a coderef C<< $is_even >> which checks
whether a sub number is even, and you want to use C<grep> to find all the
even numbers in a list:

   my $is_even   = sub { $_[0] % 2 == 0 };
   my @even_nums = grep { $is_even->($_) } @list;

If @list is 10,000 items long, the C<< $is_even >> sub is called 10,000
times. Sub calls are relatively expensive in terms of CPU time, so it
would be good if we could inline the contents of C<< $is_even >> into
the C<grep> block, and thus avoid those 10,000 sub calls. With Sub::Block
this is possible!

   my $is_even   = block { $_[0] % 2 == 0 };
   my $grep_even = eval sprintf(
      'sub { grep { %s } @_ }',
      $is_even->inlininfy('$_'),
   );
   
   # Below this comment, only a single sub call happens!
   my @even_nums = $grep_even->(@list);

=head2 Constructors

=over

=item C<< new($coderef) >>

Creates a Sub::Block from an existing coderef.

=item C<< new($string, \%captures) >>

Creates a Sub::Block from a string of Perl code, plus a hashref of
variables to capture.

=item C<< block { BLOCK } >>

This is not a method, but an exported function that acts as a shortcut
for the constructor.

=back

=begin trustme

=item BUILDARGS

=end trustme

=head2 Methods

=over

=item C<< sub >>

Returns the code block as a normal coderef.

C<< &{} >> is overloaded so that C<< $block->(@args) >> works.

=item C<< execute(@args) >>

Executes the code block, with C<< @args >>.

=item C<< closures >>

Returns the variables closed over by the code block.

Note that Sub::Block is powered by L<Sub::Quote>, and closures don't really
work properly. See L<https://rt.cpan.org/Ticket/Display.html?id=87315>.

=item C<< code >>

Returns a string of Perl code for the code block.

=item C<< inlinify(@varnames) >>

Returns a string of Perl code for the code block, wrapped in a
C<< do{...} >> block with C<< @_ >> localized and the variables in
@varnames assigned to it. The following:

   my $plus_one = block { $_[0] + 1 };
   print $plus_one->inlinify('$foo');

Will print something like:

   do {
      local @_ = ($foo);
      $_[0] + 1
   };

=item C<< grep >>

A shortcut for the example earlier in this documentation:

   my $is_even   = block { $_[0] % 2 == 0 };
   my $grep_even = $is_even->grep;
   my @even_nums = $grep_even->execute(@list);

But C<< $grep_even >> is a Sub::Block, not a normal coderef

=item C<< map >>

Like C<grep>, but C<map>. :-)

=item C<< sequence(@others) >>

Given a list of other blocks (or coderefs, which will be converted into
code blocks) generates a new block which calls all of the blocks in
sequence, with the output of each being passed into the input of the
next.

   my $block1 = block { ... };
   my $block2 = block { ... };
   my $block3 = block { ... };
   
   # The following two are conceptually similar.
   
   my $seq1 = $block1->sequence($block2, $block3);
   
   my $seq2 = block {
      $block3->execute(
         $block2->execute(
            $block1->execute(@_)
         )
      );
   };

You can also use the overloaded C<<< >> >>> operator:

   my $seq3 = $block1 >> $block2 >> $block3;

Or it can be called as a class method:

   my $seq4 = Sub::Block->sequence($block1, $block2, $block3);

=back

=head1 CAVEATS

Sub::Block is affected by
L<https://rt.cpan.org/Ticket/Display.html?id=87315>.

The C<return>, C<wantarray> and C<caller> functions which rely on the sub
call stack will not see your code block when it's been inlined into an
outer sub. So C<return> will really return from the outer sub, not the
code block.

Sub::Block will issue a warning if it notices that you've used one of these
keywords in your code block, but it might not always notice. (It needs to
walk the optree to look for them.)

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Sub-Block>.

=head1 SEE ALSO

L<Sub::Quote>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

